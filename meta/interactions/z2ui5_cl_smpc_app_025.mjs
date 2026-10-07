// FeedListItem: senderPress -> PRESSED round trip -> "Pressed on <author>";
// the bound actions aggregation and the delete action carrying the row index
// through `${$parameters>/item}.getParent().indexOfItem(...)` -> the entry
// is DELETEd from the collection and "Item deleted" toasts
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const list = page.locator('.sapMList');
  await expect(list, 'the seeded feed entries').toContainText('Feed Entries');
  const items = page.locator('.sapMFeedListItem');
  const before = await items.count();
  if (before < 2) throw new Error(`expected the seeded entries to render, got ${before}`);
  // the sender Link renders its text plus a trailing colon
  const firstSender = (await items.first().locator('a.sapMLnk').first().innerText()).replace(/:\s*$/, '').trim();
  await waitForIdle(page);
  await items.first().locator('a.sapMLnk').first().click();
  await expect(page.locator('.sapMMessageToast').last(), 'the senderPress toast').toContainText(`Pressed on ${firstSender}`);
  await waitForIdle(page);
  // the actions: an overflow BUTTON per item opens the action sheet — target
  // the <button>, not its full-width wrapper div (a click at the wrapper's
  // centre lands on nothing)
  const actionBtn = items.first().locator('button[id$="-actionButton"]').first();
  if (!(await actionBtn.count())) throw new Error('the first FeedListItem rendered no actions button for its bound actions');
  await actionBtn.click();
  // the overflow opens an ActionSheet of Buttons on older UI5 and an sap.m.Menu
  // of menuitems on the current one (measured on 1.152, 2026-10-07: the popover
  // read "Delete Share Edit" and held no <button> at all) - accept either
  const sheet = page.locator('.sapMActionSheet, .sapMPopover, .sapMDialog');
  const del = sheet.getByRole('button', { name: 'Delete', exact: true })
    .or(sheet.getByRole('menuitem', { name: 'Delete', exact: true })).first();
  await expect(del, 'the Delete action from the bound actions').toBeVisibleEnabled();
  await del.click();
  await expect(page.locator('.sapMMessageToast').last(), 'the delete toast').toContainText('Item deleted');
  await expect(page.locator('.sapMFeedListItem'), 'the entries after the delete').toHaveCountBelow(before);
};
