// Demo app "Bulletin Board" (the Testing tutorial). Two things worth running:
//   - the table title. The original's onUpdateFinished takes the COUNTED title
//     only when the table has rows and falls back to the plain one when it is
//     empty; the port counted unconditionally and an empty search read
//     "Posts (0)" (found 2026-09-14).
//   - the flag. It is an ordinary two-way bound row field here, where the
//     original has a custom `flagged` model type, so a toggle has to survive
//     the next round-trip - which is the whole claim that wire makes.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const search = async (page, query) => {
  const field = page.locator('input[type="search"]').first();
  await field.fill(query);
  await field.press('Enter');
  await waitForIdle(page);
};

export default async (page, expect) => {
  await waitForIdle(page);

  // the original's sorter is Title ascending, and the header counts the rows
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const titles = t.getItems().map((i) => i.getCells()[0].getTitle());
    return titles.length > 1 && titles.every((v, i) => i === 0 || titles[i - 1].localeCompare(v, 'en') <= 0);
  }, 'the posts are not sorted by Title');
  await expect(page.locator('body'), 'the table header').toContainText('Posts (23)');

  // flag the first post, then force a round-trip: the flag must still be set
  const flag = page.locator('button[title="Mark this post as flagged"]').first();
  await flag.click();
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems()[0].getCells()[3].getPressed() === true;
  }, 'the flag button did not take the press');
  await search(page, 'bike');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const rows = t.getItems();
    return rows.length === 3 && rows[0].getCells()[0].getTitle() === "29'er Mountain Bike (red)"
      && rows[0].getCells()[3].getPressed() === true;
  }, 'the flag did not survive the search round-trip, or the search did not leave the three bikes');

  // a search that matches nothing: the title falls back to the uncounted one
  await search(page, 'zzzz');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const label = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Label' && /--tableHeader$/.test(c.getId()));
    return t.getItems().length === 0 && label.getText() === 'Posts';
  }, 'an empty result must read "Posts", the way onUpdateFinished falls back when the table has no rows');

  // and a post opens, with the two tabs the tutorial ends on
  await search(page, '');
  await page.getByText('Cheap Boat', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const nav = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.NavContainer');
    const h = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.ObjectHeader');
    return /page-post$/.test(nav.getCurrentPage().getId()) && h.getTitle() === 'Cheap Boat' && h.getNumber() === '26263.00';
  }, 'pressing a post did not open the post page with its header');
  await expect(page.locator('body'), 'the post page').toContainText('Posted At');
};
