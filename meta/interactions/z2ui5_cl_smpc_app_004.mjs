// BusyDialog: OPEN_DIALOG -> popup_display of the BusyDialog fragment plus a
// START_TIMER(3000) follow-up; TIMER_FINISHED -> control_by_id close on the
// popup view; the dialog's close event -> DIALOG_CLOSED -> the completion
// toast. The whole chain is one press and a wait: the dialog must APPEAR with
// its title and then GO AWAY on its own, followed by the toast.
//
// Only the timer path is driven. The Cancel path's toast word rides on
// `${$parameters>/cancelPressed}`, a BOOLEAN event arg that the transpiled
// runtime hands the backend as the string 'true' where `= abap_true` cannot
// match (the app-108 divergence) — so a correct port reads "completed" here
// on cancel while a real system reads "cancelled". That half stays with the
// human live check.
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForIdle(page);
  const btn = page.getByRole('button', { name: 'Show Busy Dialog', exact: true }).first();
  await expect(btn, 'the "Show Busy Dialog" button').toBeVisibleEnabled();
  await btn.click();
  const dialog = page.locator('.sapMBusyDialog');
  await expect(dialog, 'the popup_display BusyDialog').toContainText('Loading Data');
  await expect(dialog, 'the BusyDialog text').toContainText('now loading the data from a far away server');
  // the 3000ms timer round-trips TIMER_FINISHED, which closes it via control_by_id
  await page.locator('.sapMBusyDialog').waitFor({ state: 'detached', timeout: 15000 })
    .catch(() => { throw new Error('the START_TIMER -> TIMER_FINISHED -> control_by_id close chain never closed the BusyDialog'); });
  await expect(page.locator('.sapMMessageToast').last(), 'the DIALOG_CLOSED completion toast').toContainText('The operation has been completed');
};
