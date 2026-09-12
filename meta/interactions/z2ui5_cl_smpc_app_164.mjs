// sap.ui.table RowModes: the 123-row set reaches the rows binding, and the
// footer SegmentedButton's selectedKey shares the rowMode field with the
// Table's rowMode — picking Auto has to switch the table's row mode with no
// round trip. The items are icon-only (a zero box unthemed), so the press is
// dispatched
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

// runs in the PAGE (stringified), so the wanted mode travels as the arg
const modeIs = (want) => {
  const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.ui.table.Table' && c.getDomRef());
  if (!t) return false;
  const m = t.getRowMode();
  const name = typeof m === 'string' ? m : (m && m.getMetadata().getName().split('.').pop());
  return name === want;
};

export default async (page, expect) => {
  await expect(page.locator('.sapUiTable'), 'the table title').toContainText('Products');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.ui.table.Table' && c.getDomRef());
    const b = t && t.getBinding('rows');
    return !!b && b.getLength() === 123;
  }, 'the rows binding never carried the 123-row set');
  await waitForUi5(page, modeIs, 'the table did not boot in the seeded Fixed row mode', 'Fixed');
  const item = page.locator('[id$="rowMode"] li, [id$="rowMode"] .sapMSegBBtn').filter({ has: page.locator('[title="Auto"], [aria-label="Auto"]') }).first();
  const auto = (await item.count()) ? item : page.locator('[id$="rowMode"] .sapMSegBBtn').nth(1);
  await auto.dispatchEvent('click');
  await waitForUi5(page, modeIs, 'picking Auto did not switch the Table rowMode through the shared bound field', 'Auto');
};
