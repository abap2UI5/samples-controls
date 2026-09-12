// ObjectStatus: the active "Product status: Damaged" press -> STATUS_PRESSED
// round trip -> the controller-built "Error description" Dialog as a
// popup_display fragment, closed by its OK button's popup_close
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'a static status').toContainText('Product Shipped');
  const n = await page.locator('.sapMObjStatus').count();
  if (n < 40) throw new Error(`expected the sample's ObjectStatus grid to render, got ${n}`);
  await waitForIdle(page);
  const active = page.locator('.sapMObjStatusActive').filter({ hasText: 'Damaged' }).first();
  await expect(active, 'the active Damaged status').toBeVisible();
  await active.locator('.sapMObjStatusText').first().click();
  const dialog = page.locator('.sapMDialog');
  await expect(dialog, 'the STATUS_PRESSED Dialog').toContainText('Product was damaged along transportation.');
  await expect(dialog, 'the Dialog title').toContainText('Error description');
  await dialog.getByRole('button', { name: 'OK', exact: true }).first().click();
  await page.locator('.sapMDialog').waitFor({ state: 'hidden', timeout: 10000 })
    .catch(() => { throw new Error('the OK button\'s popup_close never closed the Dialog'); });
};
