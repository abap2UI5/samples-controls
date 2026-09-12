// ToolbarShrinkable: the three Toolbars' width is an expression over the
// two-way bound slider value ({= value + '%'}) — one ArrowLeft on the slider
// (step 20, seeded 100) has to bring all three to 80% with no round trip.
// The handle has no box unthemed, so it is focused through the DOM
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the first MessageStrip').toContainText('Toolbar items are shrinkable');
  await waitForUi5(page, () => {
    const tbs = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.Toolbar' && /toolbar[123]$/.test(c.getId()));
    return tbs.length === 3 && tbs.every((t) => t.getWidth() === '100%');
  }, 'the three toolbars did not boot at the seeded 100% width');
  const handle = page.locator('.sapMSliderHandle').first();
  if (!(await handle.count())) throw new Error('the Slider rendered no handle');
  await page.evaluate(() => document.querySelector('.sapMSliderHandle').focus());
  await page.keyboard.press('ArrowLeft');
  await waitForUi5(page, () => {
    const tbs = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.Toolbar' && /toolbar[123]$/.test(c.getId()));
    return tbs.length === 3 && tbs.every((t) => t.getWidth() === '80%');
  }, 'the slider step did not move the three toolbar widths to 80% through the expression binding');
};
