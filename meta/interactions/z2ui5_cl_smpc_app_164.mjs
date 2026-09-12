// sap.ui.table RowModes: the 123-row set reaches the rows binding, and the
// footer SegmentedButton's selectedKey shares the rowMode field with the
// Table's rowMode — picking Auto has to switch the table's row mode with no
// round trip. At the smoke's viewport the footer OverflowToolbar folds the
// SegmentedButton into its "Additional Options" popover, where it renders as
// a Select (the app-247 lesson) — so the mode is picked from that Select's
// picker
import { waitForUi5, ui5All, revealInOverflow } from '../../scripts/lib-e2e.mjs';

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
  const select = page.locator('[id$="rowMode-select"]').first();
  await revealInOverflow(page, select);
  await select.click();
  await page.locator('.sapMSltPicker').getByText('Auto', { exact: true }).first().click();
  await waitForUi5(page, modeIs, 'picking Auto did not switch the Table rowMode through the shared bound field', 'Auto');
};
