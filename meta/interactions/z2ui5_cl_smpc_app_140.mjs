// BlockLayoutCustomBackground: six rows / seven cells, six of them with a
// backgroundColorSet bound to the same field as the Select's selectedKey —
// picking another set repaints every bound cell with no round trip (the
// renderer's sapUiBlockLayoutCellColor<set><shade> class)
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

const cellsAre = (set) => () => {
  const cells = ui5All().filter((c) => c.getMetadata().getName() === 'sap.ui.layout.BlockLayoutCell' && c.getBackgroundColorShade());
  return cells.length === 6 && cells.every((c) => c.getBackgroundColorSet() === set);
};

export default async (page, expect) => {
  await expect(page.locator('body'), 'the first cell title').toContainText('Cells with Custom Color (Shade A)');
  const rows = await page.locator('.sapUiBlockLayoutRow').count();
  const cells = await page.locator('.sapUiBlockLayoutCell').count();
  if (rows !== 6 || cells !== 7) throw new Error(`expected 6 rows / 7 cells, got ${rows} / ${cells}`);
  await waitForUi5(page, cellsAre('ColorSet5'), 'the cells did not boot with the seeded ColorSet5');
  if (!(await page.locator('.sapUiBlockLayoutCellColor5A').count())) throw new Error('the seeded ColorSet5/ShadeA class did not reach the DOM');
  await page.locator('.sapMSlt').first().click();
  await page.locator('.sapMSltPicker').getByText('ColorSet2', { exact: true }).first().click();
  await waitForUi5(page, cellsAre('ColorSet2'), 'picking ColorSet2 did not reach the six bound cells');
  await page.locator('.sapUiBlockLayoutCellColor2A').first().waitFor({ state: 'attached', timeout: 10000 })
    .catch(() => { throw new Error('the cells were not re-rendered with the ColorSet2 class'); });
};
