// Demo app "Manage Products" (the Worklist tutorial). Three things the render
// gate cannot see, all found by running the app on 2026-09-14:
//   - the table must come back SORTED BY ProductName, as the original's list
//     binding sorts it (the port kept the mock's ProductID order);
//   - the quick filter and the search must reach the backend and come back with
//     the rows they leave;
//   - the "Discontinued" ObjectStatus of the object page must appear for a
//     discontinued product. Its `visible` was a STATIC value written into the
//     XML at render time, and object_show( ) renders nothing - so the status
//     was decided once, at startup, for a product nobody had opened yet.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const names = (page) => page.evaluate(`(() => {
  const t = Object.values(sap.ui.require("sap/ui/core/Element").registry.all())
    .find((c) => c.getMetadata().getName() === "sap.m.Table");
  return t.getItems().map((i) => i.getCells()[0].getTitle());
})()`);

export default async (page, expect) => {
  await waitForIdle(page);

  // the original's sorter: ProductName ascending, not the mock's row order
  const rows = await names(page);
  const sorted = [...rows].sort((a, b) => a.localeCompare(b, 'en'));
  if (rows.join('|') !== sorted.join('|')) {
    throw new Error(`the worklist is not sorted by ProductName: ${rows.slice(0, 4).join(', ')}`);
  }

  // the quick filter round-trips: "Shortage" is UnitsInStock between 1 and 10,
  // which the mock leaves three products in
  await page.getByText('Shortage', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems().length === 3;
  }, 'the Shortage quick filter did not leave the three products the mock has in that band');

  // back to all products, then search
  await page.getByText('Products', { exact: true }).first().click();
  await waitForIdle(page);
  const search = page.locator('input[type="search"]').first();
  await search.fill('cha');
  await search.press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Table');
    return t.getItems().length === 2 && t.getItems().every((i) => /^Cha/.test(i.getCells()[0].getTitle()));
  }, 'the search for "cha" did not leave Chai and Chang');
  await search.fill('');
  await search.press('Enter');
  await waitForIdle(page);

  // the object page of a DISCONTINUED product (Chang) carries the status
  await page.getByText('Chang', { exact: true }).first().click();
  await waitForIdle(page);
  await expect(page.locator('body'), 'the object page of Chang').toContainText('Chang');
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.ObjectStatus'
    && c.getText() === 'Discontinued' && c.getVisible() === true),
  'the Discontinued status stayed hidden on a discontinued product - is `visible` a static value again?');

  // and it is GONE again on a product that is not discontinued: the same flag,
  // the other way round, which a static value cannot do either
  await page.getByText('Show Manage Products', { exact: true }).first().click();
  await waitForIdle(page);
  await page.getByText('Chai', { exact: true }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().every((c) => c.getMetadata().getName() !== 'sap.m.ObjectStatus'
    || c.getText() !== 'Discontinued' || c.getVisible() === false),
  'the Discontinued status stayed visible on a product that is not discontinued');
};
