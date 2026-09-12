// sap.m.Table: the ToggleButton's two-way `pressed` drives the infoToolbar's
// visible expression (pressed TWICE — a flag that latches passes one press);
// the ComboBox's two-way selectedKey drives the popinLayout expression; and
// the bound rows carry the NAME sorter. None of these round-trips.
//
// NOT driven: the sticky CheckBoxes. STICKY_SELECT carries
// `${$parameters>/selected}`, a BOOLEAN t_arg the transpiled runtime delivers
// as the string 'true' where `= abap_true` cannot match, so every tick takes
// the DELETE branch here while a real system INSERTs — that leg stays with
// the human live check
import { waitForUi5, ui5All, revealInOverflow } from '../../scripts/lib-e2e.mjs';

// runs in the PAGE (stringified), so the wanted flag travels as the arg
const infoVisible = (want) => {
  const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table' && c.getDomRef());
  return !!t && !!t.getInfoToolbar() && t.getInfoToolbar().getVisible() === want;
};

export default async (page, expect) => {
  const table = page.locator('.sapMListTbl');
  await expect(table, 'the products rows').toContainText('Notebook Basic 15');
  await expect(page.locator('body'), 'the info toolbar text').toContainText('Wide range of available products');
  // the NAME sorter: the first rendered row is the alphabetically first name
  await waitForUi5(page, () => {
    const rows = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.ColumnListItem' && c.getBindingContext() && c.getDomRef());
    if (rows.length < 100) return false;
    const names = rows.map((r) => r.getBindingContext().getProperty('NAME'));
    return names.every((n, i) => i === 0 || names[i - 1].localeCompare(n) <= 0);
  }, 'the rows did not render in NAME order');
  const toggle = page.getByRole('button', { name: 'Hide/Show InfoToolbar' }).first();
  await revealInOverflow(page, toggle);
  await toggle.click();
  await waitForUi5(page, infoVisible, 'pressing the ToggleButton did not hide the infoToolbar through the !pressed expression', false);
  await revealInOverflow(page, toggle);
  await toggle.click();
  await waitForUi5(page, infoVisible, 'pressing the ToggleButton again did not show the infoToolbar', true);
  // the popin layout ComboBox: typing a matching item text commits its key
  const combo = page.locator('[id$="idPopinLayout-inner"]').first();
  await revealInOverflow(page, combo);
  await combo.fill('Grid Small');
  await combo.press('Enter');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table' && c.getDomRef());
    return !!t && t.getPopinLayout() === 'GridSmall';
  }, 'picking Grid Small did not reach the Table popinLayout through the expression binding');
};
