// Tree over the nested-table hierarchy: the root nodes render, and expanding
// Node1 (its expander icon has no box unthemed, so the whole mouse sequence is
// dispatched) reveals the depth-2 node the nested `nodes` table carries
import { dispatchMouse, waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  // a sap.m.Tree renders with the List's sapMList class, not a sapMTree one
  const tree = page.locator('.sapMList');
  await expect(tree, 'the root Node1').toContainText('Node1');
  await expect(tree, 'the root Node2').toContainText('Node2');
  const before = await page.locator('.sapMTreeItemBase').count();
  if (before !== 2) throw new Error(`expected two collapsed root nodes, got ${before}`);
  await dispatchMouse(page.locator('.sapMTreeItemBaseExpander').first());
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.StandardTreeItem'
    && c.getTitle() === 'Node1-1' && c.getDomRef()), 'expanding Node1 never rendered its child Node1-1');
};
