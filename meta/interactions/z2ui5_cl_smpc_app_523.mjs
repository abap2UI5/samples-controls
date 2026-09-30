// the MultiSelect product table, the CellSelector and CopyProvider dependents,
// the three flags, and the copy itself: the CopyProvider's extractData is the
// framework's clipboard module (core:require), and the declared Copy button
// runs copySelectionData through a control_by_id frontend action
import { waitForUi5, ui5All, revealInOverflow, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.plugins.CellSelector'),
    'the CellSelector dependent never reached the table');
  await waitForUi5(page, () => ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.ColumnListItem' && c.getDomRef()).length > 0,
    'the product rows never rendered');
  // the two seeded flags reach their CheckBox, the third boots unchecked
  await waitForUi5(page, () => {
    const sel = ui5All().filter((c) => c.getMetadata().getName() === 'sap.m.CheckBox' && c.getText()).map((c) => [c.getText(), c.getSelected()]);
    return sel.length === 3 && sel.every(([t, s]) => (t === 'Sparse' ? s === false : s === true));
  }, 'the three copy flags never reached their CheckBoxes');

  // the plugin was created, which it refuses without extractData - and the
  // callback is the module's, reading the column's app:bindings / app:template
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.plugins.CopyProvider'
    && typeof c.getExtractData() === 'function'), 'the CopyProvider never got its extractData callback');
  const cell = await page.evaluate(`(() => { ${UI5_ALL_SRC}
    const cp = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.plugins.CopyProvider');
    const table = cp.getParent();
    const ctx = table.getItems()[0].getBindingContext();
    const col = table.getColumns()[0];
    return { got: cp.getExtractData()(ctx, col, true), id: ctx.getProperty('PRODUCTID'), name: ctx.getProperty('NAME') };
  })()`);
  expect(cell.got.text, 'extractData copies the Product column as its two app:bindings fields').toEqual([cell.id, cell.name]);
  expect(cell.id, 'the first row carries a product id').toBeTruthy();

  // select the first row, catch the plugin's copy event (and cancel it, so
  // the headless clipboard is never asked), then press the declared button
  await page.evaluate(`(() => { ${UI5_ALL_SRC}
    const cp = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.plugins.CopyProvider');
    const table = cp.getParent();
    table.setSelectedItem(table.getItems()[0], true);
    window.__copied = null;
    cp.attachCopy((e) => { window.__copied = e.getParameter('data'); e.preventDefault(); });
  })()`);
  const btn = page.getByRole('button', { name: 'Copy', exact: true });
  await revealInOverflow(page, btn);
  await btn.first().click();
  await page.waitForFunction('window.__copied !== null', undefined, { timeout: 15000 })
    .catch(() => { throw new Error('the Copy button never reached copySelectionData on the CopyProvider'); });
  const copied = await page.evaluate('window.__copied');
  expect(copied.length, 'one selected row is copied').toBe(1);
  expect(copied[0].slice(0, 2), 'the copied row starts with the Product column\'s two fields').toEqual([cell.id, cell.name]);
};
