// Wizard: the footer Cancel goes through a backend round-trip that opens a
// MessageBox (message_box_display with a YES/NO onclose action), and — since
// 2026-08-28 — the Edit links of the review page, which are the port's
// backToPage legs.
//
// Those legs were SILENT NO-OPS until the A2UI5_PIN bump to 2567ee10: the
// frontend did not list backToPage, so it took the unlisted-method path and
// handed sap.m.NavContainer the RAW ABAP literal, while `_pageStack` holds
// runtime-prefixed ids. UI5 answered "Cannot navigate backToPage(...) because
// target page was not found among the previous pages." and left the review page
// up — no wrong target, no exception, nothing to catch. So the assertion is on
// the NavContainer's CURRENT page, which is the only thing that separates a
// working back-navigation from a dead one.
import { waitForUi5, ui5All, waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the first wizard step').toContainText('Product Type');
  /* Before the FIRST press too, not only between the later ones: while a
     roundtrip is in flight the global busy indicator covers the page, and
     Playwright's actionability check then waits out its full timeout on a
     button that is perfectly visible and perfectly unclickable - which is what
     "locator.click: Timeout 30000ms exceeded" was. */
  await waitForIdle(page);
  const cancel = page.getByRole('button', { name: 'Cancel', exact: true }).first();
  await expect(cancel, 'the wizard Cancel button').toBeVisibleEnabled();
  await cancel.click();
  await expect(page.locator('.sapMDialog'), 'the cancel MessageBox')
    .toContainText('Are you sure you want to cancel your report?');
  await waitForIdle(page);
  /* The MessageBox's own buttons, and UI5 writes their labels: "Yes" and "No"
     (__mbox-btn-0 / __mbox-btn-1), not the raw action names the backend queues.
     `{ name: 'NO', exact: true }` is case-SENSITIVE in Playwright, so it matched
     nothing and spent the full actionability timeout on a button that was right
     there. Anchored and case-insensitive: it fits either spelling. */
  await page.getByRole('button', { name: /^no$/i }).first().click();

  /* The step-2 validation follows what is TYPED, not what was last committed.
     Reported from a system 2026-09-22: deleting characters left the field blue
     while the name was below six characters. sap.m.Input.oninput writes the
     typed text into the `value` property - and so through the two-way binding
     into the model this port's handler reads - only `if
     (this.getValueLiveUpdate())`, while liveChange fires either way. Without
     the attribute the wire round-tripped per keystroke against the value of
     the last `change` (blur or Enter), and DELETING is where that shows worst:
     the model keeps the longer committed name and the ValueState never
     follows. So this leg never blurs - a blur would commit the value and hide
     exactly the defect - and asserts the state after a deletion. */
  await waitForIdle(page);
  /* The wizard's own nextStep( ), not its button: the button's label is
     `WIZARD_STEP + (progress + 1)` - "Step 2" here, not "Next Step" - so a
     name locator is a guess about progress AND locale. That guess is what
     made the first version of this leg fail with a 30s click timeout. Same
     idiom the complete leg below already uses. */
  await page.evaluate(() => {
    const reg = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    reg.find((c) => !c.bIsDestroyed && c.getId().endsWith('CreateProductWizard')).nextStep();
  });
  await waitForIdle(page);   // step 2's activate wire round-trips
  const nameInput = page.locator("[id$='ProductName'] input").first();
  await expect(nameInput, 'the step-2 Name input').toBeVisibleEnabled();
  await nameInput.click();
  await nameInput.pressSequentially('Notebook');          // 8 chars -> valid
  await waitForIdle(page);
  await nameInput.press('Backspace');                     // 7
  await nameInput.press('Backspace');                     // 6 - still valid
  await nameInput.press('Backspace');                     // 5 - now INVALID
  await waitForIdle(page);
  /* Read the DOM value and the `value` PROPERTY separately. They are the same
     thing only under valueLiveUpdate, and their gap IS the defect: oninput
     always writes the DOM, the property (and through it the bound model the
     handler reads) only under the attribute. Reporting both makes a failure
     here say which of the two went wrong instead of guessing. */
  const state = await page.evaluate(() => {
    const reg = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const inp = reg.find((c) => !c.bIsDestroyed && c.getId().endsWith('ProductName'));
    return inp ? { state: inp.getValueState(), typed: inp.getDOMValue(), prop: inp.getValue() } : null;
  });
  if (!state) throw new Error('the ProductName input was not in the control registry');
  if (state.typed.length >= 6) {
    throw new Error(`the deletions never reached the field: the DOM holds "${state.typed}"`);
  }
  if (state.state !== 'Error') {
    throw new Error(
      `deleting to "${state.typed}" (${state.typed.length} chars) left valueState=${state.state}, `
      + `expected Error. The value property holds "${state.prop}" - if that is the LONGER, `
      + 'committed name, the port validated the last blur instead of what is typed '
      + '(valueLiveUpdate missing on the Input)',
    );
  }

  // complete the wizard: the `to` leg, which always worked
  await waitForIdle(page);
  await page.evaluate(() => {
    const reg = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    reg.find((c) => c.getId().endsWith('CreateProductWizard')).fireComplete();
  });
  await waitForUi5(page, () => {
    const nav = ui5All().find((c) => !c.bIsDestroyed && c.getMetadata().getName() === 'sap.m.NavContainer');
    const cur = nav && nav.getCurrentPage();
    return Boolean(cur && cur.getId().endsWith('wizardReviewPage'));
  }, 'the wizard-complete `to` never reached the review page');

  // an Edit link: backToPage the content page, then goToStep. The goToStep
  // alone would pass on a dead back-navigation, so the PAGE is what is asserted
  await waitForIdle(page);
  /* NOT getByRole('link'): a sap.m.Link with no href renders a bare <a>, and an
     <a> without href has no link role - so the locator resolved to nothing and
     the leg spent its whole timeout waiting for an element that was on screen,
     27x17px, visible and hit-testable the entire time. Playwright's call log
     said so ("waiting for getByRole(...)") and the leg had thrown that line
     away. The real element, clicked for real. */
  await page.locator('a.sapMLnk').filter({ hasText: /^Edit$/ }).first().click();
  await waitForUi5(page, () => {
    const nav = ui5All().find((c) => !c.bIsDestroyed && c.getMetadata().getName() === 'sap.m.NavContainer');
    const cur = nav && nav.getCurrentPage();
    const wiz = ui5All().find((c) => !c.bIsDestroyed && c.getId().endsWith('CreateProductWizard'));
    return Boolean(cur && cur.getId().endsWith('wizardContentPage')
      && wiz && String(wiz.getCurrentStep()).endsWith('ProductTypeStep'));
  }, 'the Edit link never came back to the wizard content page — backToPage is a no-op again');
};
