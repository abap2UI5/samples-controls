// IconTabBarStretchContent: the bound Products list with counters inside the
// first filter, the device> expression on `expanded` (!phone -> true on the
// desktop harness), and switching to the Attachments tab shows its content
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMITB, .sapMITBContainer'), 'the bound Products list in the first tab').toContainText('Notebook Basic 15');
  await waitForUi5(page, () => {
    const itb = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.IconTabBar' && c.getDomRef());
    return !!itb && itb.getExpanded() === true && itb.getStretchContentHeight() === true;
  }, 'the IconTabBar did not resolve the device> expression to expanded on desktop');
  const counters = await page.locator('.sapMLIBCounter').count();
  if (counters < 100) throw new Error(`expected a counter per product row, got ${counters}`);
  await page.locator('.sapMITBFilter').filter({ hasText: 'Attachments' }).first().click();
  await expect(page.locator('.sapMITBContainerContent, .sapMITBContent'), 'the Attachments tab content').toContainText('Attachments go here ...');
  await waitForUi5(page, () => {
    const itb = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.IconTabBar' && c.getDomRef());
    return !!itb && itb.getSelectedKey() === 'attachments';
  }, 'selecting the Attachments tab did not move selectedKey');
};
