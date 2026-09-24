// Demo app "Bulletin Board" (the Testing tutorial). Rebuilt 1:1 on 2026-09-24
// after a side-by-side comparison; what this module walks, in the order a user
// would:
//   - the worklist: sorted by Title, growing (20 of 23 rows), the header
//     counting the rows - "Posts (23)", and the plain "Posts" when a search
//     leaves the table empty, the way onUpdateFinished falls back;
//   - the search is the mock server's substringof: case-sensitive, so "Bike"
//     finds the three bikes where "bike" finds nothing;
//   - the flag is a two-way bound row field (the original's FlaggedType over
//     the TwoWay OData model), so a toggle survives the next round-trip - and
//     a search that hides the row and a search that brings it back;
//   - the e-mail share action runs URLHelper.triggerEmail in the browser with
//     the original's subject and body (redirect stubbed: a headless browser
//     has nothing to hand a mailto: to);
//   - a post opens on the App's second page with its header, the tab bar
//     expanded on a desktop and the Timestamp as the JS Date's toString( ),
//     as the untyped OData binding shows it; the Back button returns to the
//     worklist, which kept its search.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const search = async (page, query) => {
  const field = page.locator('input[type="search"]').first();
  await field.fill(query);
  await field.press('Enter');
  await waitForIdle(page);
};

export default async (page, expect) => {
  await waitForIdle(page);

  // the original's sorter is Title ascending, the table grows by 20, and the
  // header counts all rows
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const titles = t.getItems().map((i) => i.getCells()[0].getTitle());
    const g = t.getGrowingInfo();
    return titles.length === 20 && g && g.total === 23
      && titles.every((v, i) => i === 0 || titles[i - 1] < v);
  }, 'the posts are not sorted by Title, or the table does not grow 20 of 23');
  await expect(page.locator('body'), 'the table header').toContainText('Posts (23)');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const boat = t.getItems().find((i) => i.getCells()[0].getTitle() === 'Cheap Boat');
    const n = boat && boat.getCells()[2];
    return n && n.getNumber() === '26263.00' && n.getUnit() === 'USD' && n.getState() === 'Error';
  }, 'the price of "Cheap Boat" is not 26263.00 USD in the Error band (numberUnit/priceState)');

  // flag the first post, then force a round-trip: the flag must still be set
  const flag = page.locator('button[title="Mark this post as flagged"]').first();
  await flag.click();
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems()[0].getCells()[3].getPressed() === true;
  }, 'the flag button did not take the press');
  await search(page, 'Bike');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const rows = t.getItems();
    return rows.length === 3 && rows[0].getCells()[0].getTitle() === "29'er Mountain Bike (red)"
      && rows[0].getCells()[3].getPressed() === true;
  }, 'the flag did not survive the search round-trip, or "Bike" did not leave the three bikes');

  // the mock server's substringof is case-sensitive: "bike" matches no title,
  // and an empty result reads "Posts", not "Posts (0)"
  await search(page, 'bike');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const label = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Label' && /--tableHeader$/.test(c.getId()));
    return t.getItems().length === 0 && label.getText() === 'Posts';
  }, '"bike" must find nothing (case-sensitive substringof) and the header must fall back to "Posts"');

  // the flag of a row a search hid is still there when the row comes back
  await search(page, '');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const rows = t.getItems();
    return rows.length === 20 && rows[0].getCells()[0].getTitle() === "29'er Mountain Bike (red)"
      && rows[0].getCells()[3].getPressed() === true;
  }, 'the flag was lost while a search hid its row');
  await expect(page.locator('body'), 'the table header').toContainText('Posts (23)');

  // the share action: URLHelper.triggerEmail(null, subject, message) in the
  // browser - its redirect is stubbed, so the mailto: URL can be read back
  await page.evaluate(() => {
    const helper = sap.ui.require('sap/m/library').URLHelper;
    helper.redirect = (url) => { window.__demo005Mail = url; };
  });
  // sap.m.semantic puts the action into the page's share menu, as there: the
  // share button (icon `action`) opens it first
  const emailButton = () => page.evaluate(() => Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.isA('sap.m.Button') && c.getIcon() === 'sap-icon://email' && c.getDomRef())?.getId());
  let shareId = await emailButton();
  if (!shareId) {
    const menuId = await page.evaluate(() => Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getMetadata().getName() === 'sap.m.Button' && c.getIcon() === 'sap-icon://action' && c.getDomRef())?.getId());
    if (menuId) {
      await page.locator(`[id="${menuId}"]`).click();
      await page.waitForTimeout(800);
      shareId = await emailButton();
    }
  }
  if (!shareId) throw new Error('the worklist has no Send Email button (semantic:SendEmailAction)');
  await page.locator(`[id="${shareId}"]`).click();
  await page.waitForFunction(() => typeof window.__demo005Mail === 'string', undefined, { timeout: 15000 })
    .catch(() => { throw new Error('the share action did not call URLHelper.triggerEmail'); });
  const mail = decodeURIComponent(await page.evaluate(() => window.__demo005Mail));
  if (!mail.startsWith('mailto:?subject=<Email subject PLEASE REPLACE ACCORDING TO YOUR USE CASE>&body=<Email body PLEASE REPLACE ACCORDING TO YOUR USE CASE> http')) {
    throw new Error(`the share mail is not the original's subject and body: ${mail.slice(0, 160)}`);
  }

  // a post opens on the App's second page, with the tabs the tutorial ends on
  await search(page, 'Boat');
  await page.getByText('Cheap Boat', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const app = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.App' && c.getPages().some((p) => /--postPage$/.test(p.getId())));
    const h = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.ObjectHeader');
    const bar = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.IconTabBar');
    return /--postPage$/.test(app.getCurrentPage().getId()) && h.getTitle() === 'Cheap Boat'
      && h.getNumber() === '26263.00' && h.getNumberUnit() === 'USD' && bar.getExpanded() === true;
  }, 'pressing a post did not open the post page with its header and the expanded tab bar');
  await expect(page.locator('body'), 'the post page').toContainText('Posted At');
  await waitForUi5(page, () => {
    const expected = new Date('2015-08-14T14:08:33Z').toString();
    return ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Text' && c.getText() === expected);
  }, 'the Timestamp does not read as the JS Date of the post (Date.toString( ), as the untyped OData binding shows it)');

  // Back returns to the worklist, which kept its search
  await page.locator('[id$="--postPage-navButton"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const app = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.App' && c.getPages().some((p) => /--postPage$/.test(p.getId())));
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return /--worklistPage$/.test(app.getCurrentPage().getId()) && t.getItems().length === 1;
  }, 'Back did not return to the worklist with its search kept');
};
