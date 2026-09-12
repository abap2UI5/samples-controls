// DatePickerHidden: three anchors (two Buttons, a Link) open ONE hideInput
// DatePicker through a round-trip-free control_by_id openBy carrying
// $event.oSource.sId, and its change toasts the picked value.
//
// The openBy gesture itself is NOT driven here: with hideInput the calendar
// opens and then loops in Popover.onfocusin headless (the focus restore
// bounces off the hidden input — see meta/interactions/README.md, "still
// open"), so the pick and the toast stay with the human live check. What is
// re-proved: the three anchors render, the hidden picker exists with
// hideInput and a change listener, and every anchor carries a press listener
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the title').toContainText('Open Date Picker by Another Control');
  await expect(page.getByRole('button', { name: 'Open Date Picker', exact: true }).first(), 'the text anchor button').toBeVisibleEnabled();
  await expect(page.locator('a.sapMLnk').filter({ hasText: 'Open Date Picker' }).first(), 'the Link anchor').toBeVisible();
  await waitForUi5(page, () => {
    const dp = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.DatePicker' && c.getId().endsWith('HiddenDP'));
    const anchors = ui5All().filter((c) => ['sap.m.Button', 'sap.m.Link'].includes(c.getMetadata().getName()) && c.getDomRef() && c.getAriaHasPopup && c.getAriaHasPopup() === 'Dialog');
    return !!dp && dp.getHideInput() === true && dp.hasListeners('change')
      && anchors.length === 3 && anchors.every((a) => a.hasListeners('press'));
  }, 'the hidden DatePicker with its change wire and the three press-wired anchors did not all render');
};
