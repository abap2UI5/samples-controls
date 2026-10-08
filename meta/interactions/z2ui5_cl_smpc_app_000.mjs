// The overview app (not a numbered port, but the demo's front door). Its info
// button is the app's only backend round-trip, so this one click covers the
// whole draft save -> reload path: it is where the 2026-07-31
// `Network error: ASSERTION_FAILED` regression showed up (open-abap wrote the
// draft XML with unescaped `<`, see pr/open-abap-xml-escaping). The popover
// content also proves the server-side row lookup (only ${CLASS} travels).
// The src/04 demo apps open from a "Demo apps (n)" button in the subheader, in
// a dialog of their own (#258, 2026-10-07 - they had been a table above the
// ports): every row rendered with its class and a start URL, its Open button
// wired, and the dialog's Close button closing it again without a round-trip.
import { waitForUi5, waitForIdle, revealInOverflow, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  // addressed by its tooltip: the label carries the count, and on a narrow
  // viewport the subheader toolbar moves the button into its overflow
  const demoBtn = page.locator('button[title^="The UI5 demo apps"]').first();
  await revealInOverflow(page, demoBtn);
  await expect(demoBtn, 'the subheader\'s Demo apps button').toBeVisibleEnabled();
  await expect(demoBtn, 'the subheader\'s Demo apps button').toContainText('Demo apps (');
  await demoBtn.click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const d = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Dialog' && c.isOpen() && /demo apps/.test(c.getTitle()));
    const t = d && d.getContent().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    const rows = t && t.getDomRef() ? t.getItems() : [];
    return rows.length >= 5 && rows.every((r) => /^z2ui5_cl_smpc_demo_00\d$/.test(r.getCells()[3].getText())
      && /\?app_start=Z2UI5_CL_SMPC_DEMO_00\d$/.test(r.getBindingContext().getProperty('START_URL'))
      && r.getCells()[4].hasListeners('press'));
  }, 'the Demo apps dialog did not list the src/04 apps, each with a start URL and a wired Open button');
  await page.locator('.sapMDialog button').filter({ hasText: /^Close$/ }).first().click();
  await waitForUi5(page, () => !ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Dialog' && c.isOpen()),
    'the Demo apps dialog\'s Close button did not close it');

  const btn = page.locator('button[title^="Generation notes"]').first();
  await expect(btn, 'a row\'s generation-notes button').toBeVisibleEnabled();
  await btn.click();
  // by its title, not the bare class: once the Demo apps button was reached
  // through the subheader's overflow, that toolbar's own (closed, hidden)
  // sap.m.Popover is in the DOM first, and a bare .sapMPopover waits on it
  const notes = page.locator('.sapMPopover').filter({ hasText: 'Generation notes' }).first();
  await notes.waitFor({ state: 'visible', timeout: 60000 })
    .catch(() => { throw new Error('the generation-notes popover never opened (round-trip failed?)'); });
  await expect(notes, 'the generation-notes popover').toContainText('Generation notes');
};
