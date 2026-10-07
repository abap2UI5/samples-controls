// ProgressIndicator + RatingIndicator header facets
//
// The RatingIndicator is asserted through the CONTROL, not through Playwright's
// visibility: its stars are absolutely positioned by the theme CSS this harness
// does not serve, so the rendered box measures 80x0 and `toBeVisible` reads a
// correct port as "not visible" (red every nightly 2026-10-04..07, measured
// 2026-10-07 - the control was in the DOM with aria-valuenow 4 of 5).
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMPI').first(), 'the header ProgressIndicator').toContainText('42%');
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.RatingIndicator'
    && !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef())
    && c.getValue() === 4 && c.getMaxValue() === 5 && c.getEnabled()),
  'the header RatingIndicator never rendered with its value 4 of 5');
  await expect(page.locator('.sapUxAPObjectPageSection').first(), 'the goals section').toContainText('Evangelize the UI framework');
};
