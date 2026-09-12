// ImageModeBackground: four Background-mode Images sized by a device> model
// expression ({= phone ? '5em' : '10em' }) and a container colour from the
// injected style — read the resolved width off the controls and the computed
// background off the DOM
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'a caption').toContainText('Repeating background');
  await waitForUi5(page, () => {
    const imgs = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.Image' && c.getMode() === 'Background');
    return imgs.length === 4 && imgs.every((i) => i.getHeight() === '10em');
  }, 'the four Background images did not resolve the device> expression to 10em');
  const bg = await page.evaluate(() => {
    const el = document.querySelector('.imageContainer');
    return el ? getComputedStyle(el).backgroundColor : null;
  });
  if (bg !== 'rgb(169, 234, 255)') throw new Error(`the injected .imageContainer rule did not apply — got ${bg}`);
};
