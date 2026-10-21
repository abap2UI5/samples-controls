// p13n.Engine with two controllers: the Columns and the Rows button each send
// setP13nData and open their own p13n.Popup; each close wire hands back its
// panel's getP13nData( true ) and the backend hides/re-orders columns or rows
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

const P13N_ROW = ([panel, name]) => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
  // the RENDERED panel - a never-opened popup's panels outlive their view
  const p = all.find((c) => c.getId().endsWith('--' + panel) && !c.bIsDestroyed && c.getDomRef());
  const row = p && p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL).getProperty('name') === name);
  return row ? row.getId() : null;
};
// a header-toolbar button by icon - [its id, its toolbar's id]; it may sit
// folded in the toolbar's overflow, so it is not required to be rendered
const TOOLBAR_BUTTON = (icon) => {
  const b = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.isA('sap.m.Button') && !c.bIsDestroyed && c.getIcon() === icon
      && c.getParent() && c.getParent().isA('sap.m.OverflowToolbar') && !c.getParent().bIsDestroyed);
  return b ? [b.getId(), b.getParent().getId()] : null;
};
// the live table: visible column headers and visible rows' first cells
const TABLE = () => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const t = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getId().endsWith('--persoTable') && live(c));
  if (!t) return null;
  return {
    cols: t.getColumns().filter((c) => c.getVisible()).map((c) => (c.getHeader() || {}).getText?.()),
    rows: t.getItems().filter((i) => i.getVisible()).map((i) => i.data('p13nKey')),
  };
};

export default async (page, expect) => {
  const rebuildErrors = [];
  page.on('console', (m) => { const d = /duplicate id '([^']+)'/.exec(m.text()); if (d) rebuildErrors.push(d[1].replace(/^.*--/, '')); });
  const rebuildsFailed = () => (rebuildErrors.length ? ` (rebuild died: duplicate id ${rebuildErrors[0]})` : '');
  const table = () => page.evaluate(TABLE);
  const openAndTick = async (icon, popup, panel, name) => {
    await waitForIdle(page);
    const found = await page.evaluate(TOOLBAR_BUTTON, icon);
    expect(!!found, `the toolbar button ${icon}${rebuildsFailed()}`).toBeTruthy();
    const [btn, tb] = found;
    if (!(await page.locator(`[id="${btn}"]`).count())) {
      // folded into the overflow: open it with its own button (focus + Enter)
      await page.evaluate((tb) => document.getElementById(`${tb}-overflowButton`).focus(), tb);
      await page.keyboard.press('Enter');
      await page.locator(`[id="${btn}"]`).waitFor({ state: 'visible', timeout: 5000 });
    }
    await page.locator(`[id="${btn}"]`).click();
    await waitForUi5(page, (popup) => ui5All().some((c) => c.getId().endsWith(`--${popup}-dialog`) && !c.bIsDestroyed && c.isOpen()),
      `${icon} did not open ${popup}`, popup);
    await waitForIdle(page);
    const row = await page.evaluate(P13N_ROW, [panel, name]);
    expect(!!row, `a ${name} row in ${panel} (seeded by setP13nData)`).toBeTruthy();
    await page.evaluate((id) => document.getElementById(id).focus(), row);
    await page.keyboard.press('Space');
    await page.locator(`[id$="--${popup}-confirmBtn"]`).click();
    await waitForIdle(page);
  };

  expect(await table(), 'the initial table').toEqual({
    cols: ['ID', 'First Name', 'Last Name', 'City'], rows: ['P1', 'P2', 'P3', 'P4', 'P5'] });

  // Columns popup: untick "City"
  await openAndTick('sap-icon://action-settings', 'columnsPopup', 'tableColumnsPanel', 'city_col');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef()));
    return !!t && t.getColumns().filter((c) => c.getVisible()).map((c) => c.data('p13nKey')).join() === 'id_col,firstName_col,lastName_col';
  }, `OK in the Columns popup did not hide the City column${rebuildsFailed()}`);

  // Rows popup: untick "Petra Maier"
  // the second view rebuild, with the Rows popup never opened before
  await openAndTick('sap-icon://add-employee', 'rowsPopup', 'rowsPanel', 'P2');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef()));
    return !!t && t.getItems().filter((i) => i.getVisible()).map((i) => i.data('p13nKey')).join() === 'P1,P3,P4,P5';
  }, `OK in the Rows popup did not hide Petra Maier's row${rebuildsFailed()}`);

  // the popup lives only while it is open (a POPUP-slot fragment the close
  // handler destroys), so no panel outlives it - a p13n.Popup declared in the
  // view leaked its never-opened panels, and two rebuilds later the
  // alternating view id collided with them
  await waitForUi5(page, () => !ui5All().some((c) => !c.bIsDestroyed && ['tableColumnsPanel', 'rowsPanel'].some((p) => c.getId().endsWith('--' + p))),
    'a p13n panel outlived its closed popup (the view-declared Popup leak)');
};
