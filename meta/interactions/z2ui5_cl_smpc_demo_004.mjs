// Demo app "Shopping Cart" - the demo kit's showcase, and the app with the most
// state: the original's router with its three FlexibleColumnLayout columns,
// ten pages, a cart in the browser's local storage, a filter dialog, a product
// comparison and a branching checkout wizard with its summary. Rebuilt 1:1 on
// 2026-09-24 after a side-by-side comparison; what this module walks, in the
// order a user would:
//   - the search swaps the two home lists and filters case-sensitively, as the
//     mock server's substringof does; lists come back sorted by Name;
//   - a product opens in the mid column with its category in the begin column;
//   - adding to the cart round-trips, toasts the original's text and totals;
//     the cart buttons of every page follow the layout they are derived from;
//   - the welcome page is the original's BlockLayout of tiles, two promoted;
//   - an out-of-stock product asks first (Confirmation, OK / Cancel);
//   - Save for Later and "Add to Shopping Cart" move rows between the lists;
//   - the cart survives a reload (local storage);
//   - the checkout wizard branches on the payment type, its card step is the
//     original's required MaskInputs and MM/YYYY DatePicker, a failing field
//     turns red and counts in the footer's message button, the step's Next
//     button shows only once it passes, and a payment change past the payment
//     step asks first.
import { UI5_ALL_SRC, waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

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

/** the id of a control found in the page, for a Playwright locator */
const controlId = (page, src) => page.evaluate(`${UI5_ALL_SRC} (${src})()`);

export default async (page, expect) => {
  await waitForIdle(page);

  // the home page: the categories, sorted by CategoryName, and no search list
  const cats = await list(page, 'categoryList', (i) => i.getTitle());
  if (!cats || cats.items.length !== 16) throw new Error(`the category list has ${cats ? cats.items.length : 'no'} rows, not the mock's 16`);
  if (!sorted(cats.items)) throw new Error(`the categories are not sorted by CategoryName: ${cats.items.slice(0, 4).join(', ')}`);
  if (cats.visible !== true) throw new Error('the category list is hidden while nothing is searched');
  if ((await list(page, 'productList', (i) => i.getTitle())).visible !== false) {
    throw new Error('the search-result list is visible while the search field is empty');
  }

  /* the search runs on every keystroke (liveChange) and SWAPS the two lists.
   * The mock server's substringof is case-sensitive, so "Notebook" finds the
   * notebooks where "notebook" would not. The text travels as the event's
   * argument - the field is not bound, so no response can overwrite it */
  const field = page.locator('[id$="--searchField-I"]');
  await field.fill('Notebook');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--productList$/.test(c.getId()));
    const titles = l.getItems().map((i) => i.getTitle());
    return l.getVisible() === true && titles.length > 0 && titles.every((t) => t.includes('Notebook'))
      && titles.every((t, i) => i === 0 || titles[i - 1].localeCompare(t, 'en') <= 0);
  }, 'typing "Notebook" did not show the sorted notebooks in place of the categories');
  if ((await list(page, 'categoryList', (i) => i.getTitle())).visible !== false) {
    throw new Error('the category list stayed visible behind the search results - _search( ) hides it');
  }
  await field.fill('');
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
  await page.locator('[id$="--categoryProductList"]').getByText('Astro Laptop 1516', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const h = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.ObjectHeader');
    // the price formatter of the original: "." between the thousands, "," before them
    return h && h.getTitle() === 'Astro Laptop 1516' && h.getNumber() === '989,00' && h.getNumberUnit() === 'EUR';
  }, 'the product page did not come up with the product and its formatted price');

  /* add it to the cart: a round-trip, the original's toast, the row in the
   * cart and a total. The FOOTER button of the product page, by id. */
  await page.locator('[id$="--page-product"] .sapMPageFooter button').first().click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the add-to-cart toast').toContainText('Product "Astro Laptop 1516" added to your shopping cart');
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    return l.getItems().length === 1 && l.getItems()[0].getTitle() === 'Astro Laptop 1516';
  }, 'the product never reached the cart');

  /* the cart button of the product page opens the cart column - the
   * productCart route - and every cart ToggleButton follows, because each
   * derives `pressed` from the bound layout as the original binds it */
  await page.locator('[id$="--page-product"] button[title="Show Shopping Cart"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const fcl = ui5All().find((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout');
    const toggles = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.ToggleButton'
      && c.getTooltip() === 'Show Shopping Cart');
    return fcl.getLayout() === 'ThreeColumnsMidExpanded' && toggles.length === 3 && toggles.every((t) => t.getPressed() === true);
  }, 'opening the cart did not press every cart button - is `pressed` a flag of its own again?');
  await expect(page.locator('[id$="--totalPriceText"]'), 'the cart total').toContainText('Total: 989,00 EUR');

  /* back to the categories (Category.onBack): the begin column shows Home and
   * the mid column the welcome page again - the original's BlockLayout of
   * tiles, two promoted items drawn out of five, a four-page carousel */
  await page.locator('[id$="--page-category-navButton"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const cells = ui5All().filter((c) => c.getMetadata().getName() === 'sap.ui.layout.BlockLayoutCell'
      && /--promotedRow-/.test(c.getId()));
    const carousel = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Carousel');
    return cells.length === 2 && !!carousel && carousel.getPages().length === 4;
  }, 'the welcome page is not the original arrangement - two promoted tiles and a four-page carousel');

  // a second product from the promoted panel; the cart sorts by Name
  await page.locator('[id$="--promotedRow"] button[title="Add to Shopping Cart"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    const names = l.getItems().map((i) => i.getTitle());
    return names.length === 2 && names[0].localeCompare(names[1], 'en') <= 0;
  }, 'the cart is not sorted by Name - the original sorts both cart lists');

  /* an OUT-OF-STOCK product asks first, as the original's cart.addToCart
   * does: a confirmation box with OK and Cancel, and only OK orders. "Play
   * Movie" in the viewed panel is status O in the mock. Cancel here, so the
   * cart keeps the two rows the steps below count on */
  const outOfStockAdd = await controlId(page, `() => {
    const cell = ui5All().find((c) => c.getMetadata().getName() === 'sap.ui.layout.BlockLayoutCell'
      && /--viewedRow-/.test(c.getId()) && c.getDomRef() && c.getDomRef().textContent.includes('Play Movie'));
    const b = cell && cell.findAggregatedObjects(true, (o) => o.isA('sap.m.Button') && o.getTooltip() === 'Add to Shopping Cart')[0];
    return b ? b.getId() : null;
  }`);
  if (!outOfStockAdd) throw new Error('the viewed panel has no Play Movie tile with an add-to-cart button');
  await page.locator(`[id="${outOfStockAdd}"]`).click();
  await waitForIdle(page);
  const box = page.locator('.sapMMessageBox');
  await expect(box, 'the out-of-stock confirmation').toContainText('This product is currently out of stock, but you can order it');
  await expect(box, 'the out-of-stock confirmation title').toContainText('Confirmation');
  await box.getByRole('button', { name: 'Cancel' }).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    return l.getItems().length === 2 && !l.getItems().some((i) => i.getTitle() === 'Play Movie');
  }, 'Cancel on the out-of-stock box still put the product into the cart');

  // Save for Later moves the row between the two cart lists, and back
  await page.locator('[id$="--entryList"]').getByText('Save for Later', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = (s) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
    return l('entryList').getItems().length === 1 && l('saveForLaterList').getItems().length === 1;
  }, 'Save for Later did not move the row into the saved list');
  await page.locator('[id$="--saveForLaterList"]').getByText('Add to Shopping Cart', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = (s) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && c.getId().endsWith(`--${s}`));
    return l('entryList').getItems().length === 2 && l('saveForLaterList').getItems().length === 0;
  }, '"Add to Shopping Cart" did not put the row back');

  /* THE CART SURVIVES A RESTART - the browser's local storage, read back into
   * the Storage control's two-way bound value. The ROWS, not just the count */
  await page.reload({ waitUntil: 'domcontentloaded' });
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--entryList$/.test(c.getId()));
    const items = l ? l.getItems() : [];
    return items.length === 2 && items.some((i) => i.getTitle() === 'Astro Laptop 1516')
      && items.every((i) => i.getTitle() && i.getNumber() && i.getFirstStatus() && i.getFirstStatus().getText());
  }, 'the cart did not survive a reload with its rows and their fields');

  /* the checkout: the cart opens from the welcome page's cart button, and
   * Proceed shows the wizard alone in the begin column (OneColumn) */
  await page.locator('[id$="--page-welcome"] button[title="Show Shopping Cart"]').first().click();
  await waitForIdle(page);
  await page.locator('[id$="--proceedButton"]').first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const fcl = ui5All().find((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout');
    return fcl.getLayout() === 'OneColumn';
  }, 'Proceed did not show the checkout alone, as the checkout route does');

  /* the payment step's next step is an ASSOCIATION, set from the backend and
   * re-issued on every render - the DEFAULT too, or a user who accepts Credit
   * Card could not leave the step */
  const branch = (want, msg) => waitForUi5(page, (expected) => {
    const w = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Wizard');
    const step = w.getSteps().find((s) => /--paymentTypeStep$/.test(s.getId()));
    return new RegExp(`--${expected}$`).test(String(step.getNextStep()));
  }, msg, want);
  await branch('creditCardStep', 'the wizard opened with no branch on the payment step');
  await page.locator('[id$="--contentsStep-nextButton"]').click();
  await waitForIdle(page);
  await page.locator('[id$="--paymentTypeStep"]').getByText('Bank Transfer', { exact: true }).first().click();
  await waitForIdle(page);
  await branch('bankAccountStep', 'picking Bank Transfer did not move the wizard branch to the bank-account step');
  await page.locator('[id$="--paymentTypeStep"]').getByText('Credit Card', { exact: true }).first().click();
  await waitForIdle(page);
  await branch('creditCardStep', 'picking Credit Card again did not move the branch back to the card step');

  /* the card step is REQUIRED input: validated="false" until every field
   * passes its type, so its Next button stays hidden; a changed field that
   * fails turns red with the type's message and lands in the message model
   * the footer button counts */
  await page.locator('[id$="--paymentTypeStep-nextButton"]').click();
  await waitForIdle(page);
  const cardStep = (valid, msg) => waitForUi5(page, (want) => {
    const s = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.WizardStep' && /--creditCardStep$/.test(c.getId()));
    return s && s.getValidated() === want;
  }, msg, valid);
  await cardStep(false, 'the credit card step opened validated - its four inputs are required');
  await waitForUi5(page, () => {
    const masks = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.MaskInput').map((m) => m.getMask());
    const dp = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.DatePicker' && /--creditCardExpirationDate$/.test(c.getId()));
    return masks.includes('CCCC-CCCC-CCCC-CCCC') && masks.includes('CCC')
      && dp && dp.getValueFormat() === 'MM/YYYY' && dp.getDisplayFormat() === 'MM/YYYY' && dp.getRequired() === true;
  }, 'the card step does not carry the original inputs - two MaskInputs and a required MM/YYYY DatePicker');

  const cardInput = (suffix) => page.locator(`[id$="--${suffix}-inner"]`);
  await cardInput('creditCardHolderName').fill('A1');
  await cardInput('creditCardHolderName').press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const i = ui5All().find((c) => /--creditCardHolderName$/.test(c.getId()));
    const b = ui5All().find((c) => /--showPopoverButton$/.test(c.getId()));
    return i.getValueState() === 'Error'
      && i.getValueStateText() === 'Enter a value with at least 3 characters. Enter a valid value.'
      && b && b.getText() === '1';
  }, 'a too short, non-letter card holder did not turn red with the StringType messages and one message');

  // each Enter is a change event and a round-trip; the next field waits for it
  await cardInput('creditCardHolderName').fill('Jane Doe');
  await cardInput('creditCardHolderName').press('Enter');
  await waitForIdle(page);
  await cardInput('creditCardNumber').click();
  await cardInput('creditCardNumber').pressSequentially('4111111111111111');
  await cardInput('creditCardNumber').press('Enter');
  await waitForIdle(page);
  await cardInput('creditCardSecurityNumber').click();
  await cardInput('creditCardSecurityNumber').pressSequentially('123');
  await cardInput('creditCardSecurityNumber').press('Enter');
  await waitForIdle(page);
  await cardInput('creditCardExpirationDate').fill('12/2027');
  await cardInput('creditCardExpirationDate').press('Enter');
  await waitForIdle(page);
  await cardStep(true, 'four valid card fields did not validate the step - its Next button stays hidden');
  await waitForUi5(page, () => ui5All()
    .filter((c) => /--creditCard(HolderName|Number|SecurityNumber|ExpirationDate)$/.test(c.getId()))
    .every((c) => c.getValueState() === 'None'), 'a valid card field kept its error state');

  /* past the payment step, a new payment type would throw that progress
   * away, so it asks first - the original's _setDiscardableProperty. No
   * keeps the progress and puts the old payment type back */
  await page.locator('[id$="--paymentTypeStep"]').getByText('Bank Transfer', { exact: true }).first().click();
  await waitForIdle(page);
  const warning = page.locator('.sapMMessageBox');
  await expect(warning, 'the discard warning').toContainText('Are you sure you want to change the payment type? This will discard your progress.');
  await warning.getByRole('button', { name: 'No' }).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const b = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.SegmentedButton' && /--paymentMethodSelection$/.test(c.getId()));
    return b && b.getSelectedKey() === 'Credit Card';
  }, 'No on the discard warning did not put Credit Card back');
  await branch('creditCardStep', 'No on the discard warning moved the branch anyway');
  await cardStep(true, 'No on the discard warning threw the card step progress away');

  /* on to the summary: the invoice step is required input too, the delivery
   * type the last step, whose button is the original's "Order Summary" */
  await page.locator('[id$="--creditCardStep-nextButton"]').click();
  await waitForIdle(page);
  for (const [suffix, value] of [['invoiceAddressAddress', 'Main Street 5'], ['invoiceAddressCity', 'Walldorf'],
    ['invoiceAddressZip', '69190'], ['invoiceAddressCountry', 'Germany']]) {
    await cardInput(suffix).fill(value);
    await cardInput(suffix).press('Enter');
    await waitForIdle(page);
  }
  await waitForUi5(page, () => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.WizardStep'
    && /--invoiceStep$/.test(c.getId())).getValidated() === true, 'four valid invoice fields did not validate the invoice step');
  await page.locator('[id$="--invoiceStep-nextButton"]').click();
  await waitForIdle(page);
  await expect(page.locator('[id$="--deliveryTypeStep-nextButton"]'), 'the finish button').toContainText('Order Summary');
  await page.locator('[id$="--deliveryTypeStep-nextButton"]').click();
  await waitForIdle(page);

  /* the summary: one section per step - the card payment, the invoice
   * address, "Same as invoice address" for the shipping - and Submit asks
   * before it orders */
  const summary = page.locator('[id$="--summaryPage"]');
  await expect(summary, 'the summary page').toContainText('Credit Card Payment');
  await expect(summary, 'the card holder in the summary').toContainText('Jane Doe');
  await expect(summary, 'the invoice address in the summary').toContainText('Main Street 5');
  await expect(summary, 'the shipping address section').toContainText('Same as invoice address');
  await page.locator('[id$="--submitOrder"]').click();
  await waitForIdle(page);
  const submit = page.locator('.sapMMessageBox');
  await expect(submit, 'the submit confirmation').toContainText('Are you sure you want to submit your order?');
  await submit.getByRole('button', { name: 'Yes' }).click();
  await waitForIdle(page);
  await expect(page.locator('[id$="--orderCompletedPage"]'), 'the order confirmation').toContainText('Thank you for your order!');
  await waitForUi5(page, () => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List'
    && /--entryList$/.test(c.getId())).getItems().length === 0, 'the submitted order left the cart filled');

  // Return to Shop: two columns, the catalogue in the begin column
  await page.locator('[id$="--returnToShopButton"]').click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().find((c) => c.getMetadata().getName() === 'sap.f.FlexibleColumnLayout')
    .getLayout() === 'TwoColumnsMidExpanded', 'Return to Shop did not go back to two columns');

  /* the product comparison: "Compare" on two products of a category shows
   * both side by side in the mid column - the first alone shows the how-to
   * placeholder beside it */
  await page.getByText('Laptops', { exact: true }).first().click();
  await waitForIdle(page);
  const compare = page.locator('[id$="--categoryProductList"]').getByText('Compare', { exact: true });
  await compare.nth(0).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const p = (id) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Panel' && c.getVisible()
      && c.getDomRef() && c.getDomRef().textContent.includes(id));
    return !!p('How to Compare Products');
  }, 'one compared product did not show the how-to placeholder beside it');
  await compare.nth(1).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const panels = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.Panel'
      && /--comparisonContainer$/.test(c.getParent() && c.getParent().getId()) && c.getVisible());
    return panels.length === 2 && panels.every((p) => /HT-\d+/.test(p.getDomRef() ? p.getDomRef().textContent : ''));
  }, 'two compared products did not show side by side');

  // the comparison's Add to Cart, then the cart's Edit mode and its confirmed delete
  await page.locator('[id$="--comparisonContainer"] button').filter({ hasText: 'Add to Cart' }).first().click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the comparison add-to-cart toast').toContainText('added to your shopping cart');
  await page.locator('[id$="--page-comparison"] button[title="Show Shopping Cart"]').first().click();
  await waitForIdle(page);
  await page.locator('[id$="--editButton"]').click();
  await waitForIdle(page);
  await expect(page.locator('[id$="--page-cart"]'), 'the Edit mode title').toContainText('Edit Cart');
  await page.locator('[id$="--entryList"] [id$="-imgDel"]').first().click();
  await waitForIdle(page);
  const del = page.locator('.sapMMessageBox');
  await expect(del, 'the delete confirmation').toContainText('Do you want to remove this entry from your cart?');
  await del.getByRole('button', { name: 'Delete' }).click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the removal toast').toContainText('removed from cart');
  await waitForUi5(page, () => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List'
    && /--entryList$/.test(c.getId())).getItems().length === 0, 'the confirmed delete left the row in the cart');

  /* the category filter dialog: Availability > Out of Stock narrows the list
   * and the info toolbar names the filter */
  await page.locator('[id$="--masterListFilterButton"]').click();
  await page.waitForTimeout(800);
  const dialog = page.locator('.sapMVSD');
  await dialog.getByText('Availability', { exact: true }).first().click();
  await page.waitForTimeout(600);
  await dialog.getByText('Out of Stock', { exact: true }).first().click();
  await dialog.getByRole('button', { name: 'OK' }).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const l = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.List' && /--categoryProductList$/.test(c.getId()));
    const bar = ui5All().find((c) => /--categoryInfoToolbarTitle$/.test(c.getId()));
    return l.getItems().length > 0 && l.getItems().every((i) => i.getFirstStatus().getText() === 'Out of Stock')
      && bar && bar.getText() === 'Filtered by Availability';
  }, 'the Out of Stock filter did not narrow the list and name itself in the info toolbar');
};
