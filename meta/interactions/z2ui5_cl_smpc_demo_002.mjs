// Demo app "Browse Orders" (the master-detail showcase). What the render gate
// cannot see:
//   - selecting an order opens the second column, marks the row, and the URL
//     follows the original's router: #/Orders/<id>/?tab=shipping, a tab switch
//     rewrites the query;
//   - the full screen action toggles the layout and restores the one before;
//   - the ViewSettingsDialog's confirm must reach the backend: the info bar
//     appears with the filter's own text and the list regroups. The bar's
//     `visible` was a STATIC value written into the XML once, so the label
//     updated and the bar it sits in stayed hidden (found 2026-09-14);
//   - the grouping is a client-side sorter on the list binding over the row
//     JSON's group objects: the headers must read as the original's group
//     functions write them AND stand in date order, not in the alphabetical
//     order a sorter on the header text would give;
//   - the search is the mock server's case-sensitive substringof on the
//     order's CustomerName, and the empty list says so;
//   - the close action, an unknown order (DetailObjectNotFound) and an
//     unknown hash (NotFound, and its Back button).
// The share action and the phone link hand off to mailto:/tel:, which kills
// input for the whole headless tab (e2e-debugging) - only their wiring is
// asserted, they are never pressed.
import { waitForIdle, waitForUi5, dispatchMouse, revealInOverflow } from '../../scripts/lib-e2e.mjs';

const fclIs = (layout) => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
  && c.getLayout() === layout);

// an icon-only semantic action - an OverflowToolbarButton the unthemed harness
// may fold into the title's overflow or leave without a box
async function pressAction(page, id) {
  const button = page.locator(`[id$="--${id}-button"]`);
  try {
    await revealInOverflow(page, button);
    await button.first().click({ timeout: 5000 });
  } catch {
    await dispatchMouse(button.first());
  }
}

// an icon-only control: a real click where the unthemed harness gives it a
// box, the dispatched gesture where it does not
async function pressIcon(locator) {
  try {
    await locator.first().click({ timeout: 5000 });
  } catch {
    await dispatchMouse(locator.first());
  }
}

export default async (page, expect) => {
  await waitForIdle(page);
  await expect(page.locator('body'), 'the order list').toContainText('Order 7991');

  // the list is the original's: OrderID descending, counted in the title
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    const ids = l.getItems().map((i) => Number(i.getTitle().replace('Order ', '')));
    const title = ui5All().find((c) => /--masterHeaderTitle$/.test(c.getId()));
    return ids.length === 10 && ids.every((v, i) => i === 0 || ids[i - 1] > v) && title.getText() === 'Orders (10)';
  }, 'the order list is not sorted by OrderID descending, or its title is not "Orders (10)"');

  // an order opens the detail column, the row is marked, and the hash carries
  // the object route with the tab the original rewrites it to
  await page.getByText('Order 3115', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && c.getLayout() === 'TwoColumnsMidExpanded'), 'selecting an order did not open the mid column');
  await page.waitForFunction(() => /#\/Orders\/3115\/\?tab=shipping$/.test(window.location.href), undefined, { timeout: 10000 })
    .catch(async () => { throw new Error(`the hash does not name the order and its tab: ${page.url()}`); });
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    return l.getSelectedItem() && l.getSelectedItem().getTitle() === 'Order 3115';
  }, 'the order on show is not the selected row of the master list');
  // the line items, the ship-to address and the order total
  await expect(page.locator('body'), 'the detail column').toContainText('Line Items (5)');
  await expect(page.locator('body'), 'the shipping tab').toContainText('1A Paket- und Lieferservice');

  // the processor tab: its form, and the query follows in place
  await pressIcon(page.locator('[id$="--iconTabFilterProcessor"]'));
  await waitForIdle(page);
  await expect(page.locator('body'), 'the processor tab').toContainText('Andrew Fuller');
  await page.waitForFunction(() => /\?tab=processor$/.test(window.location.href), undefined, { timeout: 10000 })
    .catch(async () => { throw new Error(`a tab switch did not rewrite the query: ${page.url()}`); });
  // the share and phone hand-offs are wired (never pressed - see the header)
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.semantic.SendEmailAction'
    && c.hasListeners('press'))
    && ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Link' && c.getText() === '01781234598'
      && c.hasListeners('press')), 'the share action or the processor\'s phone link is not wired');

  // full screen and back: toggleFullScreen restores the layout it left
  await pressAction(page, 'enterFullScreen');
  await waitForIdle(page);
  await waitForUi5(page, fclIs, 'the full screen action did not switch to MidColumnFullScreen', 'MidColumnFullScreen');
  await pressAction(page, 'exitFullScreen');
  await waitForIdle(page);
  await waitForUi5(page, fclIs, 'leaving full screen did not restore TwoColumnsMidExpanded', 'TwoColumnsMidExpanded');

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

  // the group headers: the original's texts, in date order (ascending)
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    const heads = l.getItems().filter((i) => i.getMetadata().getName() === 'sap.m.GroupHeaderListItem')
      .map((i) => i.getTitle());
    return heads.join('|') === 'Ordered in September 2016|Ordered in October 2016|Ordered in November 2016|Ordered in December 2016';
  }, 'the grouping did not draw the four "Ordered in <month> 2016" headers in date order');

  // the search: the mock server's case-sensitive substringof on CustomerName
  const search = page.locator('[id$="--searchField-I"]').first();
  await search.fill('Alfreds');
  await search.press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    const rows = l.getItems().filter((i) => i.getMetadata().getName() === 'sap.m.ObjectListItem').map((i) => i.getTitle());
    return rows.join('|') === 'Order 6368|Order 7311';
  }, 'searching "Alfreds" did not leave the two orders of Alfreds Futterkiste, grouped by order date');
  await search.fill('alfreds');
  await search.press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    return l.getItems().length === 0 && l.getNoDataText() === 'No matching order found';
  }, 'the lower-case search found something, or the empty list does not say "No matching order found"');
  await search.fill('');
  await search.press('Enter');
  await waitForIdle(page);

  // the close action: one column, no selection, the master route
  await pressAction(page, 'closeColumn');
  await waitForIdle(page);
  await waitForUi5(page, fclIs, 'the close action did not return to OneColumn', 'OneColumn');
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId()));
    return !l.getSelectedItem();
  }, 'the master list kept its selection after the detail was closed');

  // an order the service does not have: the DetailObjectNotFound target
  await page.evaluate(() => { window.location.hash = '#/Orders/4711'; });
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && c.getLayout() === 'TwoColumnsMidExpanded' && /--detailObjectNotFoundPage$/.test(c.getCurrentMidColumnPage().getId())),
  'an unknown order did not show the DetailObjectNotFound page in the mid column');
  await expect(page.locator('body'), 'the object-not-found page').toContainText('This order is not available');

  // an unknown hash: the bypassed NotFound target, and its Back button
  await page.evaluate(() => { window.location.hash = '#/somethingInvalid'; });
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && c.getLayout() === 'OneColumn' && /--notFoundPage$/.test(c.getCurrentBeginColumnPage().getId())),
  'an unknown hash did not show the NotFound page in one column');
  await expect(page.locator('body'), 'the not-found page').toContainText('The requested resource was not found');
  await page.locator('[id$="--notFoundPage-navButton"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && /--page$/.test(c.getCurrentBeginColumnPage().getId())),
  'the Back button of the NotFound page did not lead back to the order list');

  // a cold deep link without ?tab=: the router's initialize( ) matches it, the
  // object opens, and the query is rewritten IN PLACE - not appended to it
  await page.goto(page.url().replace(/#.*$/, '#/Orders/7918'));
  await waitForIdle(page);
  await page.waitForFunction(() => /#\/Orders\/7918\/\?tab=shipping$/.test(window.location.href), undefined, { timeout: 15000 })
    .catch(async () => { throw new Error(`a deep link was not rewritten to its tab: ${page.url()}`); });
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout'
    && c.getLayout() === 'TwoColumnsMidExpanded' && /--detailPage$/.test(c.getCurrentMidColumnPage().getId()))
    && ui5All().some((c) => c.getMetadata().getName() === 'sap.m.List' && /--list$/.test(c.getId())
      && c.getSelectedItem() && c.getSelectedItem().getTitle() === 'Order 7918'),
  'a deep link to order 7918 did not open its detail with the row selected');
  await expect(page.locator('body'), 'the deep-linked order').toContainText('Line Items (4)');
};
