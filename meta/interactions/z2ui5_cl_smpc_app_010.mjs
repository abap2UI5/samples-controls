// TableTest: a Navigation row press -> MESSAGE_DIALOG_PRESS round trip ->
// popup_display of the controller-built message Dialog ("Success"), and its
// OK button's popup_close frontend action takes it down again
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const row = page.locator('.sapMListTbl .sapMListTblRow').first();
  await expect(row, 'the first product row').toBeVisibleEnabled();
  await expect(page.locator('.sapMListTbl'), 'the sorted product rows').toContainText('Notebook Basic 15');
  await waitForIdle(page);
  await row.click();
  const dialog = page.locator('.sapMDialog');
  await expect(dialog, 'the popup_display message Dialog').toContainText('Success');
  await expect(dialog, 'the Dialog title').toContainText('Message');
  await dialog.getByRole('button', { name: 'OK', exact: true }).first().click();
  await page.locator('.sapMDialog').waitFor({ state: 'hidden', timeout: 10000 })
    .catch(() => { throw new Error('the OK button\'s popup_close never closed the Dialog'); });
};
