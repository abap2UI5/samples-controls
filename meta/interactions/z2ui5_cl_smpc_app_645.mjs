// p13n.Engine: the Settings button sends setP13nData and opens the p13n.Popup;
// its close wire hands the panels' getP13nData( true ) back and the backend
// re-orders/shows the columns and sorts the rows. Then the column menu: its
// beforeOpen round-trip fills the QuickSort item, and a quick sort re-sorts.
import { waitForIdle, waitForUi5, revealInOverflow } from '../../scripts/lib-e2e.mjs';

// the rendered table's visible column headers and its rows' first cells, in order
const tableState = () => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
  if (!t) return null;
  const cols = t.getColumns().filter((c) => c.getVisible()).map((c) => {
    const h = c.getHeader();
    return h && h.getText ? h.getText() : '';
  });
  const rows = t.getItems().filter((i) => i.isA('sap.m.ColumnListItem')).map((i) => i.getCells().map((x) => x.getText()));
  return { cols, rows, sort: t.getColumns().map((c) => c.getSortIndicator()) };
};

export default async (page, expect) => {
  const state = () => page.evaluate(`(() => { const ui5All = () => Object.values(sap.ui.require("sap/ui/core/Element").registry.all()); return (${tableState.toString()})(); })()`);
  await waitForIdle(page);
  const before = await state();
  expect(before.cols, 'the initial visible columns').toEqual(['First Name', 'Last Name', 'City']);

  // Settings -> setP13nData + open
  const settings = page.getByRole('button', { name: 'Settings' });
  await revealInOverflow(page, settings);
  await settings.click();
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--p13nPopup-dialog') && !c.bIsDestroyed && c.isOpen()),
    'the Settings button did not open the p13n.Popup');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('--columnsPanel') && !c.bIsDestroyed);
    const d = p && p.getP13nData();
    return !!d && d.length === 4 && d[3].name === 'size_col' && d[3].visible === false;
  }, 'the Settings press never handed the Columns panel its setP13nData state');

  // Columns: tick "Size" the way a user does - focus its row, press Space
  const sizeRow = await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const p = all.find((c) => c.getId().endsWith('--columnsPanel') && !c.bIsDestroyed);
    const row = p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL).getProperty('name') === 'size_col');
    return row && row.getId();
  });
  expect(!!sizeRow, 'a "Size" row in the Columns panel').toBeTruthy();
  await page.evaluate((id) => document.getElementById(id).focus(), sizeRow);
  await page.keyboard.press('Space');
  // Sort: the SortPanel's state as its rows would leave it - First Name ascending
  await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const p = all.find((c) => c.getId().endsWith('--sortPanel') && !c.bIsDestroyed);
    const d = p.getP13nData();
    d.forEach((e) => { e.sorted = e.name === 'firstName_col'; e.descending = false; });
    d.sort((a, b) => (b.sorted ? 1 : 0) - (a.sorted ? 1 : 0));
    p.setP13nData(d);
  });
  await page.locator('[id$="--p13nPopup-confirmBtn"]').click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    if (!t) return false;
    const cols = t.getColumns().filter((c) => c.getVisible()).map((c) => (c.getHeader() || {}).getText?.());
    const first = t.getItems().filter((i) => i.isA('sap.m.ColumnListItem')).map((i) => i.getCells()[0].getText());
    return cols.join() === 'First Name,Last Name,City,Size' && first.join() === 'John,Maria,Peter,Petra,Thomas';
  }, 'closing the p13n.Popup with OK did not show the Size column and sort the rows by First Name');

  // the column menu: beforeOpen round-trips the column's p13nKey, the backend
  // fills the QuickSort/QuickGroup items while the menu is already open
  await waitForIdle(page);
  const cityHeader = await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const col = all.find((c) => c.isA('sap.m.Column') && live(c) && c.data('p13nKey') === 'city_col');
    return col && col.getId();
  });
  await page.locator(`[id="${cityHeader}"]`).click();
  await waitForIdle(page);
  console.log('DBG', await page.evaluate(() => JSON.stringify(Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed && (c.isA('sap.m.table.columnmenu.QuickSortItem') || c.isA('sap.m.table.columnmenu.Menu') || (c.isA('sap.m.Button') && c.getDomRef() && /Ascending|Descending/i.test(c.getText()+c.getTooltip()+c.getIcon())) )).map((c) => [c.getMetadata().getName(), c.getId(), c.getKey ? c.getKey() : '', c.isOpen ? c.isOpen() : '', c.getText ? c.getText() : '', c.getIcon ? c.getIcon() : '']))));
};
