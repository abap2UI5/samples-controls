// ScrollContainer: the Image width is a device> expression (50em phone /
// 100em otherwise) replacing the original's controller — the resolved value is
// read off the control, and the container really is a vertical scroller
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMScrollCont').first(), 'the ScrollContainer').toBeVisible();
  const vertical = await page.locator('.sapMScrollContV').count();
  if (!vertical) throw new Error('the ScrollContainer did not render as a vertical scroller');
  await waitForUi5(page, () => {
    const img = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Image' && c.getDomRef());
    return !!img && img.getWidth() === '100em';
  }, 'the Image width never resolved the device> expression to 100em');
};
