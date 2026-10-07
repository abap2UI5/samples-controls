// The overview app (not a numbered port, but the demo's front door). Its info
// button is the app's only backend round-trip, so this one click covers the
// whole draft save -> reload path: it is where the 2026-07-31
// `Network error: ASSERTION_FAILED` regression showed up (open-abap wrote the
// draft XML with unescaped `<`, see pr/open-abap-xml-escaping). The popover
// content also proves the server-side row lookup (only ${CLASS} travels).
// The src/04 demo apps have a table of their own above the ports: every row
// rendered with its class and a start URL, and its Open button wired.
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table' && /demo apps/.test(c.getHeaderText()));
    const rows = t && t.getDomRef() ? t.getItems() : [];
    return rows.length >= 5 && rows.every((r) => /^z2ui5_cl_smpc_demo_00\d$/.test(r.getCells()[3].getText())
      && /\?app_start=Z2UI5_CL_SMPC_DEMO_00\d$/.test(r.getBindingContext().getProperty('START_URL'))
      && r.getCells()[4].hasListeners('press'));
  }, 'the demo-app table did not render the src/04 apps, each with a start URL and a wired Open button');
  const btn = page.locator('button[title^="Generation notes"]').first();
  await expect(btn, 'a row\'s generation-notes button').toBeVisibleEnabled();
  await btn.click();
  await page.waitForSelector('.sapMPopover', { timeout: 60000 })
    .catch(() => { throw new Error('the generation-notes popover never opened (round-trip failed?)'); });
  await expect(page.locator('.sapMPopover'), 'the generation-notes popover').toContainText('Generation notes');
};
