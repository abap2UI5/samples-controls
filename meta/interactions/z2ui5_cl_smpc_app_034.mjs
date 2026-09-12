// ListCounter: display-only — the bound Products list with a counter per row.
// Read the COUNTER off the first rendered row and require it to be the very
// QUANTITY the model carries for that row (an unbound counter renders empty)
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMList'), 'the Products list').toContainText('Products');
  await waitForUi5(page, () => {
    const rows = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.StandardListItem'
      && c.getBindingContext() && !c.bIsDestroyed && c.getDomRef());
    if (rows.length < 100) return false; // the JSONModel sizeLimit caps a 123-row binding at 100
    const first = rows[0];
    const q = first.getBindingContext().getProperty('QUANTITY');
    return String(first.getCounter()) === String(q) && Number(q) > 0;
  }, 'the rendered rows never carried their bound QUANTITY counters');
  const counters = await page.locator('.sapMLIBCounter').count();
  if (counters < 100) throw new Error(`expected a counter per row, got ${counters}`);
};
