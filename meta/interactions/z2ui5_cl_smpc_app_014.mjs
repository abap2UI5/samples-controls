// CustomListItem: the row Link's press carries ${PRODUCTPICURL} to LINK_PRESS,
// whose answer is the controller-built image Dialog as a popup_display
// fragment; its Close button is a popup_close frontend action.
// The Link has no href, so it renders a bare <a> with no link ROLE — locate
// it as a.sapMLnk (the app-101 lesson)
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const list = page.locator('.sapMList');
  await expect(list, 'the bound product rows').toContainText('Notebook Basic 15');
  await expect(list, 'the bound product id').toContainText('HT-1000');
  await waitForIdle(page);
  await page.locator('a.sapMLnk').filter({ hasText: /^Notebook Basic 15$/ }).first().click();
  const dialog = page.locator('.sapMDialog');
  await expect(dialog.getByRole('button', { name: 'Close', exact: true }).first(), 'the image Dialog\'s Close button').toBeVisibleEnabled();
  const img = await dialog.locator('img, .sapMImg').count();
  if (!img) throw new Error('the LINK_PRESS Dialog rendered no Image');
  await dialog.getByRole('button', { name: 'Close', exact: true }).first().click();
  await page.locator('.sapMDialog').waitFor({ state: 'hidden', timeout: 10000 })
    .catch(() => { throw new Error('the Close button\'s popup_close never closed the Dialog'); });
};
