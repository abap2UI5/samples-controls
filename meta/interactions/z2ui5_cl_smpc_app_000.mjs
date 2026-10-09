// The overview app (not a numbered port, but the demo's front door). Its
// generation-notes button is a backend round-trip on the ports table, so this
// one click covers the whole draft save -> reload path: it is where the 2026-07-31
// `Network error: ASSERTION_FAILED` regression showed up (open-abap wrote the
// draft XML with unescaped `<`, see pr/open-abap-xml-escaping). The popover
// content also proves the server-side row lookup (only ${CLASS} travels).
// The src/04 demo apps sit behind a subheader button since #259 (2026-10-08):
// its DEMO_APPS round-trip opens a dialog whose table renders every app with
// its class, a start URL and a wired Open button. Until 2026-10-09 this module
// still looked for the table the ports page used to carry above the ports, so
// the overview read red in every run while the app was right.
import { waitForUi5, ui5All, revealInOverflow } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const demoBtn = page.getByRole('button', { name: /^Demo apps \(\d+\)$/ });
  await revealInOverflow(page, demoBtn);
  await demoBtn.first().click();
  await waitForUi5(page, () => {
    const d = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Dialog' && /UI5 demo apps/.test(c.getTitle())
      && !c.bIsDestroyed && c.isOpen());
    const t = d && d.getContent().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const rows = t && t.getDomRef() ? t.getItems() : [];
    return rows.length >= 5 && rows.every((r) => /^z2ui5_cl_smpc_demo_00\d$/.test(r.getCells()[3].getText())
      && /\?app_start=Z2UI5_CL_SMPC_DEMO_00\d$/.test(r.getBindingContext().getProperty('START_URL'))
      && r.getCells()[4].hasListeners('press'));
  }, 'the Demo apps dialog did not render the src/04 apps, each with a start URL and a wired Open button');
  // Close is frontend-only (popup_close) - the dialog has to be gone before
  // the ports table's buttons take a click again
  await page.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForUi5(page, () => !ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Dialog'
    && !c.bIsDestroyed && c.isOpen()), 'the Demo apps dialog did not close on its Close button');
  const btn = page.locator('button[title^="Generation notes"]').first();
  await expect(btn, 'a row\'s generation-notes button').toBeVisibleEnabled();
  await btn.click();
  // the subheader's overflow popover (opened above to reach the Demo apps
  // button) stays in the DOM, hidden, ahead of this one - so the popover is
  // located by its own title, not as "the first .sapMPopover"
  const notes = page.locator('.sapMPopover').filter({ hasText: 'Generation notes' });
  await notes.first().waitFor({ state: 'visible', timeout: 60000 })
    .catch(() => { throw new Error('the generation-notes popover never opened (round-trip failed?)'); });
  await expect(notes.first(), 'the generation-notes popover').toContainText('Generation notes');
};
