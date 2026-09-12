// CarouselWithControls: five pages (a VerticalLayout, two Images, a Text and
// a ScrollContainer holding the bound List), and the Carousel really scrolls
// — ArrowRight on the focused carousel moves the active page, no wire
// involved. The bound list is read off the registry (it sits on a page the
// carousel has not shown yet), the Title off the DOM
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the Title').toContainText('Carousel with Different Controls');
  await waitForUi5(page, () => {
    const c = ui5All().find((x) => x.getMetadata().getName() === 'sap.m.Carousel' && x.getDomRef());
    return !!c && c.getPages().length === 5;
  }, 'the Carousel did not render its five pages');
  await waitForUi5(page, () => {
    const l = ui5All().find((x) => x.getMetadata().getName() === 'sap.m.List' && x.getHeaderText() === 'Some List Content 1');
    return !!l && l.getItems().length >= 100 && l.getItems().some((i) => i.getTitle() === 'Notebook Basic 15');
  }, 'the bound product list on the fourth page never filled from the model');
  const first = await page.evaluate(() => {
    const c = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).find((x) => x.getMetadata().getName() === 'sap.m.Carousel');
    c.getDomRef().focus();
    return c.getActivePage();
  });
  await page.keyboard.press('ArrowRight');
  await waitForUi5(page, (prev) => {
    const c = ui5All().find((x) => x.getMetadata().getName() === 'sap.m.Carousel' && x.getDomRef());
    return !!c && c.getActivePage() !== prev && c.getActivePage() === c.getPages()[1].getId();
  }, 'ArrowRight did not scroll the Carousel to its second page', first);
};
