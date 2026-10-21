// p13n.Engine on a sap.ui.table.Table: the Settings button seeds the Columns
// and Sort panels with setP13nData and opens the p13n.Popup; on OK the close
// wire hands back both panels' getP13nData( true ) and the backend rebuilds
// the columns (order, visibility) and the rows' sorter. Then the table's own
// columnResize, sort and columnMove events, each carrying the column's
// .data('p13nKey'), driven from the column header the way a user does.
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const P13N_ROW = ([panel, name]) => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
  // the RENDERED panel - a never-opened popup's panels outlive their view
  const p = all.find((c) => c.getId().endsWith('--' + panel) && !c.bIsDestroyed && c.getDomRef());
  const row = p && p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL).getProperty('name') === name);
  return row ? row.getId() : null;
};
// the DOM id of the live table's header cell for the column with this p13nKey
const HEADER = (key) => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const t = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getId().endsWith('--persoTable') && live(c));
  const col = t && t.getColumns().find((c) => c.data('p13nKey') === key);
  const cell = col && document.querySelector(`.sapUiTableHeaderCell[data-sap-ui-colid="${col.getId()}"]`);
  return cell ? cell.id : null;
};

export default async (page, expect) => {
  const rebuildErrors = [];
  page.on('console', (m) => { const d = /duplicate id '([^']+)'/.exec(m.text()); if (d) rebuildErrors.push(d[1].replace(/^.*--/, '')); });
  const rebuildsFailed = () => (rebuildErrors.length ? ` (rebuild died: duplicate id ${rebuildErrors[0]})` : '');
  const focusHeader = async (key) => {
    const id = await page.evaluate(HEADER, key);
    expect(!!id, `a rendered header cell for ${key}`).toBeTruthy();
    await page.evaluate((id) => document.getElementById(id).focus(), id);
    return id;
  };

  await waitForIdle(page);
  // the toolbar's icon-only settings button (no tooltip, so no accessible name)
  const settingsId = await page.evaluate(() => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const b = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.isA('sap.m.Button') && c.getIcon() === 'sap-icon://action-settings' && !c.bIsDestroyed
        && c.getParent() && c.getParent().isA('sap.m.OverflowToolbar'));
    return b && b.getId();
  });
  const settings = page.locator(`[id="${settingsId}"]`);
  if (!(await settings.count())) {
    // folded into the toolbar's overflow: open it with its own button (focus + Enter;
    // a pointer click lands on the table's extension area and never reaches it)
    const tb = await page.evaluate((id) => sap.ui.require('sap/ui/core/Element').getElementById(id).getParent().getId(), settingsId);
    await page.evaluate((tb) => document.getElementById(`${tb}-overflowButton`).focus(), tb);
    await page.keyboard.press('Enter');
    await settings.waitFor({ state: 'attached', timeout: 5000 });
  }
  await page.evaluate((id) => document.getElementById(id).focus(), settingsId);
  await page.keyboard.press('Enter');
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--p13nPopup-dialog') && !c.bIsDestroyed && c.isOpen()),
    'the Settings button did not open the p13n.Popup');
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('--gridColumnsPanel') && !c.bIsDestroyed);
    const d = p && p.getP13nData();
    return !!d && d.length === 4 && d[3].name === 'size_col' && d[3].visible === false;
  }, 'the Settings press never handed the Columns panel its setP13nData state');

  // Columns: tick Size (focus its row, Space); Sort: First Name ascending
  const size = await page.evaluate(P13N_ROW, ['gridColumnsPanel', 'size_col']);
  await page.evaluate((id) => document.getElementById(id).focus(), size);
  await page.keyboard.press('Space');
  await page.evaluate(() => {
    const p = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getId().endsWith('--gridSortPanel') && !c.bIsDestroyed);
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
    const cols = t.getColumns().filter((c) => c.getVisible()).map((c) => c.getLabel().getText());
    const first = t.getBinding('rows').getContexts(0, 5).map((x) => x.getProperty('FIRSTNAME'));
    return cols.join() === 'First Name,Last Name,City,Size' && first.join() === 'John,Maria,Peter,Petra,Thomas'
      && t.getColumns()[0].getSortOrder() === 'Ascending';
  }, 'closing the p13n.Popup with OK did not show the Size column and sort the rows by First Name');

  // columnResize: Shift+ArrowLeft on the Last Name header (no rebuild - the
  // backend keeps the width for the next one)
  await waitForIdle(page);
  await focusHeader('lastName_col');
  await page.keyboard.press('Shift+ArrowLeft');
  await waitForIdle(page);

  // sort: the City header's column menu, its "sort descending" quick action
  await focusHeader('city_col');
  await page.keyboard.press('Enter');
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.Button') && !c.bIsDestroyed && c.getDomRef()
    && c.getIcon() === 'sap-icon://sort-descending'), 'the City column menu did not offer a sort-descending action');
  const desc = await page.evaluate(() => Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.isA('sap.m.Button') && !c.bIsDestroyed && c.getDomRef() && c.getIcon() === 'sap-icon://sort-descending').getId());
  await page.locator(`[id="${desc}"]`).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    if (!t) return false;
    const byKey = (k) => t.getColumns().find((c) => c.data('p13nKey') === k);
    const cities = t.getBinding('rows').getContexts(0, 5).map((x) => x.getProperty('CITY'));
    return byKey('city_col').getSortOrder() === 'Descending' && byKey('firstName_col').getSortOrder() === 'None'
      && cities[4] === 'Heidelberg' && byKey('lastName_col').getWidth() !== '11rem';
  }, `sorting City descending from the column menu did not re-sort the rows, or the earlier columnResize width was lost${rebuildsFailed()}`);

  // columnMove: Ctrl+ArrowLeft on the City header (prevented, moved by the backend)
  await waitForIdle(page);
  await focusHeader('city_col');
  const [moveReq] = await Promise.all([
    page.waitForRequest((r) => r.method() === 'POST' && /"EVENT":"COLUMN_MOVE"/.test(r.postData() || ''), { timeout: 10000 }),
    page.keyboard.press('Control+ArrowLeft'),
  ]);
  // the wire itself: the moved column's p13nKey and its new position
  expect(JSON.parse(moveReq.postData()).value.S_FRONT.T_EVENT_ARG, 'the columnMove arguments').toEqual(['city_col', 1]);
  await waitForIdle(page);
  // the third view rebuild since the popup was last opened
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    return !!t && t.getColumns().filter((c) => c.getVisible()).map((c) => c.data('p13nKey')).join()
      === 'firstName_col,city_col,lastName_col,size_col';
  }, `moving City one to the left did not re-order the columns${rebuildsFailed()}`);

  // the popup lives only while it is open (a POPUP-slot fragment the close
  // handler destroys), so no panel outlives it - a p13n.Popup declared in the
  // view leaked its never-opened panels, and two rebuilds later the
  // alternating view id collided with them
  await waitForUi5(page, () => !ui5All().some((c) => !c.bIsDestroyed && ['gridColumnsPanel', 'gridSortPanel'].some((p) => c.getId().endsWith('--' + p))),
    'a p13n panel outlived its closed popup (the view-declared Popup leak)');
};
