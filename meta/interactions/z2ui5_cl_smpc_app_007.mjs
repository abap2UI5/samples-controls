// CheckBoxTriState: the parent CheckBox's selected / partiallySelected are
// EXPRESSION BINDINGS over the three two-way bound children (c1 || c2 || c3,
// !(c1 && c2 && c3)), so clicking a child re-evaluates the parent with no
// round trip. Seeded true/false/true -> the parent starts partial; ticking
// German -> all three true -> partial off; unticking all three -> selected off.
//
// NOT driven: the parent's own select wire. PARENT_CLICKED carries
// `${$parameters>/selected}`, a BOOLEAN t_arg the transpiled runtime hands
// the backend as the string 'true' where an abap_bool assignment cannot take
// it (the app-099/421 divergence) — a real system normalizes it, the harness
// does not, so that leg stays with the human live check
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

// runs in the PAGE (stringified), so the wanted pair travels as the arg
const parent = ({ sel, partial }) => {
  const p = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.CheckBox' && c.getText() === 'select / deselect all' && c.getDomRef());
  return !!p && p.getSelected() === sel && p.getPartiallySelected() === partial;
};
const tick = (page, text) => page.locator('.sapMCb').filter({ hasText: new RegExp(`^${text}$`) }).first().click();

export default async (page, expect) => {
  await expect(page.locator('body'), 'the question').toContainText('Which languages(s) do you speak?');
  await waitForUi5(page, parent, 'the parent did not boot selected+partial from the seeded true/false/true', { sel: true, partial: true });
  await tick(page, 'German');
  await waitForUi5(page, parent, 'ticking German did not clear the parent\'s partiallySelected expression', { sel: true, partial: false });
  await tick(page, 'English');
  await tick(page, 'German');
  await tick(page, 'French');
  await waitForUi5(page, parent, 'unticking all three did not clear the parent\'s selected expression', { sel: false, partial: true });
};
