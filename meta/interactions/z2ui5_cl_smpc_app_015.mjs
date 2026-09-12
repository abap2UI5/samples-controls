// CustomTreeItem: the nested tree binds through `items` with a path object,
// each row an icon Button (client MESSAGE_TOAST, no round trip) and an Input
// bound to {TEXT}. The root Inputs must carry the node texts; the button is
// icon-only and may measure zero unthemed, so its press is dispatched
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMTree').first(), 'the Tree').toBeVisible();
  await waitForUi5(page, () => {
    const inputs = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.Input' && c.getBindingContext() && c.getDomRef());
    const v = inputs.map((i) => i.getValue());
    return v.includes('Node1') && v.includes('Node2');
  }, 'the root nodes\' Inputs never showed the bound TEXT');
  const btn = page.locator('.sapMTreeItemBase .sapMBtn').first();
  if (!(await btn.count())) throw new Error('no row Button rendered in the CustomTreeItem');
  await btn.dispatchEvent('click');
  await expect(page.locator('.sapMMessageToast').last(), 'the row button\'s client toast').toContainText('Button pressed');
};
