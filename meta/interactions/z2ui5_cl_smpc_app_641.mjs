// DynamicDateRangeHidden: three anchors (two Buttons, a Link) open ONE
// hideInput DynamicDateRange through a round-trip-free control_by_id openBy
// carrying $event.oSource.sId; its change round-trips the operator, the value
// count and values[0]/[1] as `<value> + ''`, and ABAP composes the toast.
//
// Booted THEMED (sidecar e2e_smoke.theme): unthemed, the opened popover's
// focus restore bounces off the hidden input and Popover.onfocusin recurses
// until the stack overflows - the original's own openBy(getDomRef()) does the
// same headless, so it is the harness (the 016 class), not the port.
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

const isOpen = () => {
  const ddr = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange');
  return !!ddr && !!ddr._oPopup && ddr._oPopup.isOpen();
};

export default async (page, expect) => {
  await waitForUi5(page, () => {
    const ddr = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange' && c.getId().endsWith('HiddenDDR'));
    const anchors = ui5All().filter((c) => ['sap.m.Button', 'sap.m.Link'].includes(c.getMetadata().getName())
      && c.getDomRef() && c.getAriaHasPopup && c.getAriaHasPopup() === 'Dialog');
    return !!ddr && ddr.getHideInput() === true && anchors.length === 3;
  }, 'the hidden DynamicDateRange and its three anchors did not all render');

  // the text Button opens the hidden picker anchored to itself (openBy, no round trip)
  await page.getByRole('button', { name: 'Open Dynamic Date Range', exact: true }).first().click();
  await waitForUi5(page, isOpen, 'the Button anchor never opened the hidden DynamicDateRange (control_by_id openBy)');

  // a real pick: "Today" applies at once, fires change, and ABAP composes the toast
  await page.locator('.sapMPopover li').filter({ hasText: /^\s*Today\s*$/ }).first().click();
  await expect(page.locator('.sapMMessageToast').last(), 'the ABAP-composed toast for the Today pick')
    .toContainText('Operator: TODAY');

  // the Link opens it too
  await page.locator('a.sapMLnk').filter({ hasText: 'Open Dynamic Date Range' }).first().click();
  await waitForUi5(page, isOpen, 'the Link anchor never opened the hidden DynamicDateRange (control_by_id openBy)');

  // a two-value selection, committed like the popover's Apply: both Dates reach the toast as their toString
  await page.evaluate(() => {
    const ddr = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange');
    const value = { operator: 'DATERANGE', values: [new Date(2021, 5, 1), new Date(2021, 5, 30)] };
    ddr.setValue(value);
    ddr.fireChange({ value, valid: true });
  });
  const toast = page.locator('.sapMMessageToast').filter({ hasText: 'DATERANGE' }).last();
  await expect(toast, 'the DATERANGE toast operator').toContainText('Operator: DATERANGE');
  await expect(toast, 'the DATERANGE toast first value').toContainText('Value 1: Tue Jun 01 2021');
  await expect(toast, 'the DATERANGE toast second value').toContainText('Value 2: Wed Jun 30 2021');
};
