// SegmentedButton: SB1's selectedKey is two-way bound and selectionChange
// round-trips — the backend maps the key to the item text and answers with a
// toast plus the bound preview Text (the original's getSelectedItem())
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the selectionChange label').toContainText('Fire selectionChange event');
  await waitForIdle(page);
  const two = page.locator('[id$="SB1"] .sapMSegBBtn').filter({ hasText: /^Two$/ }).first();
  await expect(two, 'the "Two" segment').toBeVisibleEnabled();
  await two.click();
  await expect(page.locator('.sapMMessageToast').last(), 'the selectionChange toast').toContainText("oEvent.getParameter('item').getText(): 'Two' selected");
  await expect(page.locator('[id$="selectedItemPreview"]'), 'the bound preview text').toContainText('getSelectedItem(): Two');
};
