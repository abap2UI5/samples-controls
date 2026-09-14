// Demo app "Browse Orders" (the master-detail showcase). What the render gate
// cannot see:
//   - selecting an order opens the second column and the URL follows;
//   - the ViewSettingsDialog's confirm must reach the backend: the info bar
//     appears with the filter's own text and the list regroups. The bar's
//     `visible` was a STATIC value written into the XML, so the label updated
//     and the bar it sits in stayed hidden (found 2026-09-14);
//   - the grouping is a client-side sorter on the list binding, which a view
//     rebuild loses - the group headers must be there after the round-trip.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForIdle(page);
  await expect(page.locator('body'), 'the order list').toContainText('Order 7991');

  // the list is the original's: OrderID descending
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    const ids = l.getItems().map((i) => Number(i.getTitle().replace('Order ', '')));
    return ids.length === 10 && ids.every((v, i) => i === 0 || ids[i - 1] > v);
  }, 'the order list is not sorted by OrderID descending');

  // an order opens the detail column, and the hash carries the deep link
  await page.getByText('Order 3115', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && c.getLayout() === 'TwoColumnsMidExpanded'), 'selecting an order did not open the mid column');
  if (!/#\/Orders\/3115$/.test(page.url())) throw new Error(`the hash does not name the order: ${page.url()}`);
  // the line items and the order total the backend computes
  await expect(page.locator('body'), 'the detail column').toContainText('Line Items (5)');

  // the ViewSettingsDialog: filter by "Only Shipped Orders" and group by order
  // period, the two halves of one confirm
  await page.locator('[id$="--filterButton"]').first().click();
  await page.waitForSelector('.sapMDialog', { timeout: 30000 })
    .catch(() => { throw new Error('the filter button did not open the ViewSettingsDialog'); });
  // the dialog's own ids, and the item TEXTS where UI5 generates the list item
  // id (`__item11`) rather than taking the ViewSettingsItem's
  await page.locator('[id$="--filterItems-list-item"]').first().click();
  await page.getByText('Only Shipped Orders', { exact: true }).first().click();
  // back to the dialog root, then over to the group page and pick a grouping
  await page.locator('[id$="--viewSettingsDialog-backbutton"]').first().click();
  await page.locator('[id$="--viewSettingsDialog-groupbutton"]').first().click();
  await page.getByText('Group by Order Period', { exact: true }).first().click();
  await page.locator('[id$="--viewSettingsDialog-acceptbutton"]').first().click();
  await waitForIdle(page);

  // the info bar is VISIBLE and carries the filter's text
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Toolbar'
    && /--filterBar$/.test(c.getId()) && c.getVisible() === true),
  'the filter info bar stayed hidden after the filter was confirmed - is `visible` a static value again?');
  await expect(page.locator('body'), 'the info bar').toContainText('Filtered by Only Shipped Orders');

  // and the grouping survived the view rebuild that the same round-trip did
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    return l.getItems().some((i) => i.getMetadata().getName() === 'sap.m.GroupHeaderListItem'
      && /^Ordered in \w+ \d{4}$/.test(i.getTitle()));
  }, 'the grouping did not survive the round-trip - no "Ordered in <month> <year>" header in the list');
};
