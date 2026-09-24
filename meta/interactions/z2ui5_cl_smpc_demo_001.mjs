// Demo app "Manage Products" (the Worklist tutorial). Rebuilt 1:1 on
// 2026-09-24 after a side-by-side comparison with the demo kit; what this
// module walks, in the order a user would:
//   - the table comes back SORTED BY ProductName, as the original's list
//     binding sorts it, with the i18n key the original's bundle lacks as the
//     name column header, and the four quick-filter counts;
//   - the quick filter and the search reach the backend and come back with the
//     rows they leave; the search is case-sensitive, as the mock server's
//     substringof is, and a real search swaps the no-data text for good;
//   - the two mass actions: without a selection the error MessageBox (the
//     original's missing i18n key, TableSelectProduct), with one the toast;
//     a selection a quick filter hides is remembered but not acted on;
//   - the object page of a discontinued product carries the status, a
//     product that is not discontinued does not - `visible` was once a STATIC
//     value decided at startup; a posted comment lands in the feed with the
//     medium date;
//   - the browser Back button walks the pushed hash back to the worklist;
//   - an unknown hash shows the not-found page and an unknown or removed
//     product the object-not-found page, each with its way back;
//   - a reload of a product URL starts on that product's page, and its
//     share menu e-mails the original's subject and body.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const names = (page) => page.evaluate(`(() => {
  const t = Object.values(sap.ui.require("sap/ui/core/Element").registry.all())
    .find((c) => c.getMetadata().getName() === "sap.m.Table");
  return t.getItems().map((i) => i.getCells()[0].getTitle());
})()`);

/** the page the App shows, by its id suffix - the router target on show */
const onPage = (page, target, msg) => waitForUi5(page, (p) => {
  // abap2UI5's own root App ends in --app as well: this one holds the worklist
  const app = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.App'
    && c.getPages().some((p2) => /--worklist$/.test(p2.getId())));
  return !!app && !!app.getCurrentPage() && app.getCurrentPage().getId().endsWith(`--${p}`);
}, msg, target);

/** selects or deselects one worklist row through the control - the two-way
 * bound `selected` carries it to the backend on the next round-trip */
const select = (page, name, on) => page.evaluate(({ n, s }) => {
  const t = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getMetadata().getName() === 'sap.m.Table');
  t.getItems().find((i) => i.getCells()[0].getTitle() === n).setSelected(s);
}, { n: name, s: on });

const search = async (page, text) => {
  const field = page.locator('input[type="search"]').first();
  await field.fill(text);
  await field.press('Enter');
  await waitForIdle(page);
};

const closeBox = async (page, expect, text, msg) => {
  const box = page.locator('.sapMMessageBox');
  await expect(box, msg).toContainText(text);
  await box.locator('button', { hasText: 'Close' }).first().click();
  await waitForIdle(page);
};

export default async (page, expect) => {
  await waitForIdle(page);

  // the original's sorter: ProductName ascending, not the mock's row order
  const rows = await names(page);
  const sorted = [...rows].sort((a, b) => a.localeCompare(b, 'en'));
  if (rows.length !== 14 || rows.join('|') !== sorted.join('|')) {
    throw new Error(`the worklist is not the 14 products sorted by ProductName: ${rows.slice(0, 4).join(', ')}`);
  }
  await waitForUi5(page, () => {
    const all = ui5All();
    const title = all.find((c) => /--tableHeader$/.test(c.getId()));
    const col = all.find((c) => /--nameColumnTitle$/.test(c.getId()));
    // the bar's own items - the IconTabBar keeps internal filter clones too
    const bar = all.find((c) => /--iconTabBar$/.test(c.getId()));
    const counts = bar.getItems().filter((f) => f.isA('sap.m.IconTabFilter')).map((f) => f.getCount());
    return title.getText() === 'Products (14)' && col.getText() === 'TableNameColumnTitle'
      && counts.join('|') === '14|11|3|0';
  }, 'the table title, the name column header or the four quick-filter counts are not the original\'s');

  // the quick filter round-trips: "Shortage" is UnitsInStock between 1 and 10,
  // which the mock leaves three products in
  await page.getByText('Shortage', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const title = ui5All().find((c) => /--tableHeader$/.test(c.getId()));
    return t.getItems().length === 3 && title.getText() === 'Products (3)';
  }, 'the Shortage quick filter did not leave the three products the mock has in that band');

  // back to all products, then search - case-sensitive, as the mock server
  await page.getByText('Products', { exact: true }).first().click();
  await waitForIdle(page);
  await search(page, 'cha');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const title = ui5All().find((c) => /--tableHeader$/.test(c.getId()));
    return t.getItems().length === 0 && title.getText() === 'ProductsPlural'
      && t.getNoDataText() === 'No matching ProductsPlural found';
  }, 'the search for "cha" found rows - the mock server\'s substringof is case-sensitive');
  await search(page, 'Cha');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems().length === 2 && t.getItems().every((i) => /^Cha/.test(i.getCells()[0].getTitle()));
  }, 'the search for "Cha" did not leave Chai and Chang');
  await search(page, '');
  await waitForUi5(page, () => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table').getItems().length === 14,
    'clearing the search did not bring the 14 products back');

  // Order without a selection: the error MessageBox with the missing key
  await page.getByText('Order', { exact: true }).first().click();
  await waitForIdle(page);
  await closeBox(page, expect, 'TableSelectProduct', 'the no-selection MessageBox of Order');

  // Order with Chai selected: stock + 10, the toast, the selection stays
  await select(page, 'Chai', true);
  await page.getByText('Order', { exact: true }).first().click();
  await waitForIdle(page);
  await expect(page.locator('.sapMMessageToast').last(), 'the reorder toast').toContainText('Product stock level updated');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const chai = t.getItems().find((i) => i.getCells()[0].getTitle() === 'Chai');
    return chai.getCells()[4].getNumber() === '49.00' && chai.getSelected() === true;
  }, 'Order did not add 10 to the stock of the selected Chai, or dropped its selection');

  // a selection a quick filter hides: remembered, but not acted on
  await page.getByText('Shortage', { exact: true }).first().click();
  await waitForIdle(page);
  await page.getByText('Remove', { exact: true }).first().click();
  await waitForIdle(page);
  await closeBox(page, expect, 'TableSelectProduct', 'Remove acted on a row the quick filter hides');
  await page.getByText('Products', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems().length === 14 && t.getItems().find((i) => i.getCells()[0].getTitle() === 'Chai').getSelected() === true;
  }, 'the selection of Chai was lost behind the quick filter');

  // Remove Alice Mutton: the row, the title and the count go down by one
  await select(page, 'Chai', false);
  await select(page, 'Alice Mutton', true);
  await page.getByText('Remove', { exact: true }).first().click();
  await waitForIdle(page);
  await expect(page.locator('.sapMMessageToast').last(), 'the remove toast').toContainText('Product removed');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const title = ui5All().find((c) => /--tableHeader$/.test(c.getId()));
    return t.getItems().length === 13 && title.getText() === 'Products (13)'
      && !t.getItems().some((i) => i.getCells()[0].getTitle() === 'Alice Mutton');
  }, 'Remove did not take Alice Mutton out of the table and its title');

  // the object page of a DISCONTINUED product (Chang) carries the status
  await page.getByText('Chang', { exact: true }).first().click();
  await waitForIdle(page);
  await onPage(page, 'object', 'pressing Chang did not open the object page');
  if (!/Products\/2$/.test(await page.evaluate(() => window.location.hash))) {
    throw new Error('opening Chang did not push the hash Products/2');
  }
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.ObjectStatus'
    && c.getText() === 'Discontinued' && c.getVisible() === true)
    && ui5All().some((c) => c.getMetadata().getName() === 'sap.m.ProgressIndicator' && c.getDisplayValue() === '81'),
  'the Discontinued status stayed hidden on a discontinued product, or the stock bar is not the raw UnitsInStock');

  // a comment: the FeedInput posts, the feed lists it with the medium date
  const input = await page.evaluate(() => Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getMetadata().getName() === 'sap.m.FeedInput').getId());
  await page.locator(`[id="${input}"] textarea`).fill('Great tea');
  await page.locator(`[id="${input}-button"]`).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    // the list's items - the binding template is a FeedListItem as well
    const items = ui5All().find((c) => /--idCommentsList$/.test(c.getId())).getItems();
    return items.length === 1 && items[0].getText() === 'Great tea' && items[0].getInfo() === 'Comment'
      && /^[A-Z][a-z]{2} \d{1,2}, \d{4}, \d{1,2}:\d{2}:\d{2} [AP]M$/.test(items[0].getTimestamp());
  }, 'the posted comment is not in the feed as Comment with a medium date');

  // the browser Back button: the router's hashChanged, back on the worklist
  await page.goBack();
  await waitForIdle(page);
  await onPage(page, 'worklist', 'the browser Back button did not lead back to the worklist');

  // and the status is GONE again on a product that is not discontinued; the
  // comment belongs to Chang only
  await page.getByText('Chai', { exact: true }).first().click();
  await waitForIdle(page);
  await onPage(page, 'object', 'pressing Chai did not open the object page');
  await waitForUi5(page, () => ui5All().every((c) => c.getMetadata().getName() !== 'sap.m.ObjectStatus'
    || c.getText() !== 'Discontinued' || c.getVisible() === false)
    && ui5All().find((c) => /--idCommentsList$/.test(c.getId())).getItems().length === 0,
  'the Discontinued status stayed visible on a product that is not discontinued, or Chang\'s comment shows');
  await page.goBack();
  await waitForIdle(page);
  await onPage(page, 'worklist', 'the browser Back button did not lead back to the worklist');

  // an unknown hash: the bypassed target, and its way back
  await page.evaluate(() => { window.location.hash = '#/somethingInvalid'; });
  await waitForIdle(page);
  await onPage(page, 'notFound', 'an unknown hash did not show the not-found page');
  await expect(page.locator('body'), 'the not-found page').toContainText('The requested resource was not found');
  await page.getByText('Show Manage Products', { exact: true }).first().click();
  await waitForIdle(page);
  await onPage(page, 'worklist', 'Show Manage Products did not lead back to the worklist');

  // a product the stock does not hold (any more): the object-not-found page
  await page.evaluate(() => { window.location.hash = '#/Products/15'; });
  await waitForIdle(page);
  await onPage(page, 'objectNotFound', 'the removed product did not show the object-not-found page');
  await expect(page.locator('body'), 'the object-not-found page').toContainText('This Product is not available');
  await page.locator('[id$="--linkObject"]').click();
  await waitForIdle(page);
  await onPage(page, 'worklist', 'Show Manage Products did not lead back to the worklist');

  // a deep link: a reload of a product's URL starts on its object page (the
  // router's initialize( ) - the App opens on it)
  await page.evaluate(() => { window.location.hash = '#/Products/2'; });
  await waitForIdle(page);
  await onPage(page, 'object', 'a typed product hash did not open the object page');
  await page.reload();
  await waitForIdle(page);
  await onPage(page, 'object', 'a reload of a product URL did not start on the object page');
  await expect(page.locator('body'), 'the reloaded object page').toContainText('New Orleans Cajun Delights');

  // the share menu's e-mail: URLHelper.triggerEmail with the original's texts
  // (caught here, so no mail client opens)
  await page.evaluate(() => {
    const helper = sap.ui.require('sap/m/library').URLHelper;
    window.__mail = null;
    helper.triggerEmail = (to, subject, body) => { window.__mail = { to, subject, body }; };
    Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => /--shareEmailObject$/.test(c.getId())).firePress();
  });
  await waitForIdle(page);
  const mail = await page.evaluate(() => window.__mail);
  if (!mail || mail.subject !== 'Email subject including object identifier PLEASE REPLACE ACCORDING TO YOUR USE CASE 2'
    || !/^Email body PLEASE REPLACE ACCORDING TO YOUR USE CASE Chang \(id: 2\) http.*Products\/2$/.test(mail.body)) {
    throw new Error(`the share e-mail is not the original's: ${JSON.stringify(mail)}`);
  }
};
