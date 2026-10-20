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
  // the frontend logs a failed view rebuild and carries on with an empty page
  const rebuildErrors = [];
  page.on('console', (m) => { const d = /duplicate id '([^']+)'/.exec(m.text()); if (d) rebuildErrors.push(d[1].replace(/^.*--/, '')); });
  const rebuildsFailed = () => (rebuildErrors.length ? ` (rebuild died: duplicate id ${rebuildErrors[0]})` : '');
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
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.table.columnmenu.QuickSortItem') && !c.bIsDestroyed
    && c.getKey() === 'city_col' && c.getLabel() === 'City' && c.getSortOrder() === 'None'),
    'the column menu\'s beforeOpen round-trip never filled the QuickSort item with the City column');
  // the QuickSort's own "sort descending" button (icon-only, located through the registry)
  const desc = await page.evaluate(() => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const b = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.isA('sap.m.Button') && live(c) && c.getIcon() === 'sap-icon://sort-descending');
    return b && b.getId();
  });
  expect(!!desc, 'the QuickSort "sort descending" button in the open column menu').toBeTruthy();
  await page.locator(`[id="${desc}"]`).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    if (!t) return false;
    const city = t.getColumns().find((c) => c.data('p13nKey') === 'city_col');
    const cities = t.getItems().filter((i) => i.isA('sap.m.ColumnListItem')).map((i) => i.getCells()[2].getText());
    return city.getSortIndicator() === 'Descending' && cities[cities.length - 1] === 'Heidelberg' && cities[0] === 'Walldorf'
      && t.getColumns().filter((c) => c.getSortIndicator() !== 'None').length === 1;
  }, 'the quick sort "descending" on City did not re-sort the rows (Heidelberg last) with only City carrying the sort indicator');

  // quick group from the same menu: its Switch, toggled by keyboard
  await waitForIdle(page);
  const cityHeader2 = await page.evaluate(() => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const col = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.isA('sap.m.Column') && live(c) && c.data('p13nKey') === 'city_col');
    return col && col.getId();
  });
  await page.locator(`[id="${cityHeader2}"]`).click();
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.table.columnmenu.QuickSortItem') && !c.bIsDestroyed
    && c.getKey() === 'city_col' && c.getSortOrder() === 'Descending'),
    'the re-opened column menu did not show City as sorted descending (beforeOpen round-trip)');
  const groupSwitch = await page.evaluate(() => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const sw = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).find((c) => c.isA('sap.m.Switch') && live(c));
    return sw && sw.getId();
  });
  expect(!!groupSwitch, 'the QuickGroup switch in the open column menu').toBeTruthy();
  await page.evaluate((id) => document.getElementById(id).focus(), groupSwitch);
  await page.keyboard.press('Space');
  await waitForIdle(page);
  /* KNOWN PORT DEFECT (2026-10-20): this is the third view rebuild since the
     popup was last opened, and it dies on "adding element with duplicate id
     '...mainView2--columnsPanel'". sap.m.p13n.Popup moves its panels into an
     internal Container that only the Dialog created by open( ) owns - exit( )
     destroys that Dialog, never the Container - so a view whose popup was
     never opened leaks its panels, and the framework's alternating view id
     (mainView / mainView2) collides with them two rebuilds later: the app is
     left with an empty page. Two quick sorts without opening Settings are
     enough. Not weakened here - the leg stays red until the port stops it. */
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    if (!t) return false;
    const heads = t.getItems().filter((i) => i.isA('sap.m.GroupHeaderListItem')).map((i) => i.getTitle());
    return heads.length === 2 && /Walldorf/.test(heads[0]) && /Heidelberg/.test(heads[1]);
  }, `quick group on City did not group the rows${rebuildsFailed()}`);
};
