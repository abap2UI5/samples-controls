// ComparisonPattern: the binding_call filter narrows the table to Laptops,
// selecting two rows (the two-way bound `selected` + SELECTION round trip)
// makes the Compare button visible with its count, COMPARE builds the
// comparison and navigates the NavContainer `to` the DynamicPage while
// hash_set writes #/Page2; browser Back then round-trips HASH_CHANGED and the
// NavContainer comes `back` — the 2026-08-31 routing wire
import { waitForUi5, ui5All, waitForIdle } from '../../scripts/lib-e2e.mjs';

const onPage = (suffix) => () => {
  const nav = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.App' && !c.bIsDestroyed && c.getDomRef());
  const cur = nav && nav.getCurrentPage();
  return !!cur && cur.getId().endsWith(suffix);
};

export default async (page, expect) => {
  await expect(page.locator('.sapMListTbl'), 'the Laptops rows').toContainText('Notebook Basic 15');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table' && c.getId().endsWith('idProductsTable') && c.getDomRef());
    const b = t && t.getBinding('items');
    return !!b && b.aFilters && b.aFilters.length > 0 && t.getItems().length > 0
      && t.getItems().every((i) => i.getBindingContext().getProperty('CATEGORY') === 'Laptops');
  }, 'the binding_call filter never narrowed the table to Laptops');
  await waitForIdle(page);
  const boxes = page.locator('.sapMListTbl .sapMListTblRow .sapMCb');
  if ((await boxes.count()) < 2) throw new Error('the MultiSelect table rendered no row checkboxes');
  await boxes.nth(0).click();
  await waitForIdle(page);
  await boxes.nth(1).click();
  const compare = page.getByRole('button', { name: /^Compare \(2\)$/ }).first();
  await expect(compare, 'the Compare (2) button the SELECTION round trip makes visible').toBeVisibleEnabled();
  await waitForIdle(page);
  await compare.click();
  await waitForUi5(page, onPage('page-comparison'), 'COMPARE never navigated the App to the comparison page');
  await expect(page.locator('.sapFDynamicPage'), 'the comparison page title').toContainText('Second Page');
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Carousel' && c.getId().endsWith('carousel-expanded') && c.getPages().length === 2),
    'the comparison Carousel did not fill with the two selected products');
  await page.waitForFunction(() => location.hash.includes('/Page2'), undefined, { timeout: 10000 })
    .catch(() => { throw new Error('hash_set never wrote #/Page2 into the URL'); });
  await waitForIdle(page);
  await page.goBack();
  await waitForUi5(page, () => {
    const nav = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.App' && !c.bIsDestroyed && c.getDomRef());
    const cur = nav && nav.getCurrentPage();
    return !!cur && !cur.getId().endsWith('page-comparison');
  }, 'browser Back (HASH_CHANGED) never brought the NavContainer back to the first page');
};
