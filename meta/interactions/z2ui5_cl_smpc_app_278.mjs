// MessageBox: every button round-trips to message_box_display. Confirm opens
// the confirm box (closed with its own Cancel); "Warning with two actions"
// opens a box whose onclose action carries the pressed action back as
// ACTION_SELECTED -> the "Action selected: OK" toast
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Confirm', exact: true }).first().click();
  const box = page.locator('.sapMMessageBox, .sapMDialog');
  await expect(box, 'the confirm MessageBox').toContainText('Approve purchase order 12345?');
  await box.getByRole('button', { name: /^cancel$/i }).first().click();
  await page.locator('.sapMDialog').waitFor({ state: 'hidden', timeout: 10000 })
    .catch(() => { throw new Error('the confirm MessageBox did not close on Cancel'); });
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Warning with two actions', exact: true }).first().click();
  await expect(box, 'the two-action warning box').toContainText('The quantity you have reported exceeds the quantity planned.');
  await box.getByRole('button', { name: /^ok$/i }).first().click();
  await expect(page.locator('.sapMMessageToast').last(), 'the onclose ACTION_SELECTED toast').toContainText('Action selected: OK');
};
