// Demo app "Shopping Cart" - the demo kit's showcase, and the app with the most
// state: three columns, seven pages, a cart in the browser's local storage and a
// branching checkout wizard. What the render gate cannot see, all of it found by
// running the app on 2026-09-14:
//   - the search must SWAP the two home lists, as Home.controller._search( )
//     does with setVisible on both. The result list's `visible` was a static
//     value, so the rows arrived in a list nobody could see while the category
//     list stayed put;
//   - the lists must come back sorted by Name / CategoryName, the way the
//     original's list bindings sort them;
//   - the two cart ToggleButtons both derive `pressed` from the layout, so the
//     one on the page the user is NOT on agrees with the column that is open;
//   - adding to the cart round-trips through the backend and the total follows.
// Plus, from the 2026-09-22 side-by-side against the original: the welcome page
// is the original's BlockLayout-and-Grid arrangement, not three flat lists, and
// its promoted panel shows TWO of the five Promoted rows the way
// `_selectPromotedItems( )` does.
import { revealInOverflow, waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

/** a list of the app, by its own id suffix — every page here has several */
const list = (page, suffix, pick) => page.evaluate(({ s, src }) => {
  const all = []; sap.ui.core.Element.registry.forEach((c) => all.push(c));
  const l = all.find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
  if (!l) return null;
  // eslint-disable-next-line no-new-func
  const f = new Function('item', `return (${src})(item);`);
  return { visible: l.getVisible(), items: l.getItems().map((i) => f(i)) };
}, { s: suffix, src: pick.toString() });

const sorted = (a) => a.length > 1 && a.every((v, i) => i === 0 || a[i - 1].localeCompare(v, 'en') <= 0);

export default async (page, expect) => {
  await waitForIdle(page);

  // the home page: the categories, sorted by CategoryName as the original sorts
  // them, and no search-result list yet
  const cats = await list(page, 'categoryList', (i) => i.getTitle());
  if (!cats || cats.items.length !== 16) throw new Error(`the category list has ${cats ? cats.items.length : 'no'} rows, not the mock's 16`);
  if (!sorted(cats.items)) throw new Error(`the categories are not sorted by CategoryName: ${cats.items.slice(0, 4).join(', ')}`);
  if (cats.visible !== true) throw new Error('the category list is hidden while nothing is searched');
  if ((await list(page, 'productList', (i) => i.getTitle())).visible !== false) {
    throw new Error('the search-result list is visible while the search field is empty');
  }

  // a search SWAPS the two lists and the hits come back sorted by Name
  const field = page.locator('input[type="search"]').first();
  await field.fill('notebook');
  await field.press('Enter');
  await waitForIdle(page);
  const hits = await list(page, 'productList', (i) => i.getTitle());
  if (hits.visible !== true) {
    throw new Error('the search results stayed INVISIBLE - is `visible` a static value again? (the rows did arrive)');
  }
  if (!hits.items.length || !sorted(hits.items)) throw new Error(`the search hits are not sorted by Name: ${hits.items.slice(0, 3).join(', ')}`);
  if ((await list(page, 'categoryList', (i) => i.getTitle())).visible !== false) {
    throw new Error('the category list stayed visible behind the search results - _search( ) hides it');
  }
  // and back again when the field is cleared
  await field.fill('');
  await field.press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const all = ui5All();
    const l = (s) => all.find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
    return l('categoryList').getVisible() === true && l('productList').getVisible() === false;
  }, 'clearing the search did not put the category list back');

  // a category opens its products, sorted by Name, and a product its page
  await page.getByText('Laptops', { exact: true }).first().click();
  await waitForIdle(page);
  const products = await list(page, 'categoryProductList', (i) => i.getTitle());
  if (!products.items.length || !sorted(products.items)) {
    throw new Error(`the category's products are not sorted by Name: ${products.items.slice(0, 3).join(', ')}`);
  }
  await page.getByText('Astro Laptop 1516', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const h = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.ObjectHeader');
    // the price formatter of the original: "." between the thousands, "," before them
    return h && h.getTitle() === 'Astro Laptop 1516' && h.getNumber() === '989,00' && h.getNumberUnit() === 'EUR';
  }, 'the product page did not come up with the product and its formatted price');

  /* add it to the cart: a round-trip, a toast, the row in the cart and a total.
   * The FOOTER button of the product page, by id: a NavContainer keeps the pages
   * it is not showing in the DOM, and the welcome page carries an add-to-cart
   * button on every tile - ten of them, all reported visible, so a loose
   * locator adds a promoted product instead of the one on screen. */
  await page.locator('[id$="--page-product"] .sapMPageFooter button').first().click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the add-to-cart toast').toContainText('has been added to your shopping cart');
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    return l.getItems().length === 1 && l.getItems()[0].getTitle() === 'Astro Laptop 1516';
  }, 'the product never reached the cart');
  await expect(page.locator('body'), 'the cart total').toContainText('Total: 989,00 EUR');

  /* the cart button of the OTHER page: `pressed` is an expression over the bound
   * layout in both, as the original binds it, so opening the cart column must
   * press both. A flag of its own left the second one behind. */
  const toggle = page.locator('button[title="Show Shopping Cart"]').first();
  await toggle.click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const fcl = ui5All().find((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout');
    /* by TOOLTIP, not by type: an OverflowToolbar builds its own "Additional
     * Options" ToggleButton, so this page carries more than the two cart ones */
    const toggles = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.ToggleButton'
      && c.getTooltip() === 'Show Shopping Cart');
    return fcl.getLayout() === 'ThreeColumnsMidExpanded' && toggles.length === 2 && toggles.every((t) => t.getPressed() === true);
  }, 'opening the cart column did not press BOTH cart buttons - is `pressed` a flag of its own again?');

  /* the welcome page is the original's arrangement: the carousel, and one
   * BlockLayout CELL per featured product rather than a flat list row. The
   * promoted panel carries TWO of the five Promoted rows, as
   * `Welcome.controller._selectPromotedItems( )` does. */
  await waitForUi5(page, () => {
    const cells = ui5All().filter((c) => c.getMetadata().getName() === 'sap.ui.layout.BlockLayoutCell'
      && /--promotedRow-/.test(c.getId()));
    const carousel = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Carousel');
    return cells.length === 2 && !!carousel && carousel.getPages().length === 4;
  }, 'the welcome page is not the original arrangement - two promoted tiles and a four-page carousel');

  /* a second product, from the welcome page's promoted panel: the cart sorts by
   * Name, so it lands in front of the laptop rather than after it. The tile's
   * add-to-cart is the original's icon-only Emphasized Button, so it is located
   * by its tooltip rather than by a row text. */
  await page.locator('[id$="--promotedRow"] button[title="Add to Shopping Cart"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    const names = l.getItems().map((i) => i.getTitle());
    return names.length === 2 && names[0].localeCompare(names[1], 'en') <= 0;
  }, 'the cart is not sorted by Name - the original sorts both cart lists');

  // Save for Later moves the row between the two cart lists, and back
  await page.locator('[id$="--entryList"]').getByText('Save for Later', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = (s) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
    return l('entryList').getItems().length === 1 && l('savedList').getItems().length === 1;
  }, 'Save for Later did not move the row into the saved list');
  await page.locator('[id$="--savedList"]').getByText('Move to Cart', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = (s) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
    return l('entryList').getItems().length === 2 && l('savedList').getItems().length === 0;
  }, 'Move to Cart did not put the row back');

  /* THE CART SURVIVES A RESTART, which is the whole point of putting it in the
   * browser's local storage - and the one thing about this app that only a
   * SECOND page load can show. The z2ui5:Storage control reads the key back
   * into its two-way bound `value`, so the restore is the framework's model
   * write-back and not a parse: if the binding ever stopped carrying the value
   * home, cart_restore( ) would assign two empty tables and the cart would
   * come back empty - silently, with every static gate still green. */
  await page.reload({ waitUntil: 'domcontentloaded' });
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    return l && l.getItems().length === 2;
  }, 'the cart did not survive a reload - the stored value never reached s_storage-value');
  // the ROWS, not just the count: to_abap( iv_corresponding ) has to have filled
  // the fields the view renders, not merely created two rows
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    const items = l.getItems();
    return items.some((i) => i.getTitle() === 'Astro Laptop 1516')
      && items.every((i) => i.getTitle() && i.getNumber());
  }, 'the restored cart rows came back without their fields - the write-back did not map the components');

  /* the checkout wizard. The payment step's next step is an ASSOCIATION, which
   * no binding carries: it is set from the backend and re-issued on every
   * render. Two things to prove, and the first one is why this is here at all -
   * the DEFAULT has to be branched, because a user who accepts Credit Card
   * never fires a selection change and could otherwise not leave the step. */
  // the cart's footer is an OverflowToolbar, and Proceed folds into it here
  await revealInOverflow(page, page.locator('[id$="--proceedButton"]'));
  await page.locator('[id$="--proceedButton"]').first().click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the wizard').toContainText('Items');
  const branch = (want, msg) => waitForUi5(page, (expected) => {
    const w = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Wizard');
    const step = w.getSteps().find((s) => /--paymentTypeStep$/.test(s.getId()));
    return new RegExp(`--${expected}$`).test(String(step.getNextStep()));
  }, msg, want);
  await branch('creditCardStep',
    'the wizard opened with no branch on the payment step - the default payment type must be branched, or the step cannot be left');

  // and picking another payment type moves the branch with it
  await page.locator('[id$="--paymentTypeStep"]').getByText('Bank Transfer', { exact: true }).first().click();
  await waitForIdle(page);
  await branch('bankAccountStep', 'picking Bank Transfer did not move the wizard branch to the bank-account step');
};
