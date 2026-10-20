// p13n.Popup: the open/change wires carry the panels' getP13nData( ) as
// JSON.stringify expressions through the event source - toggling a column in
// the SelectionPanel the way the UI does (focus the row, Space) must land in
// the backend and come back as the CodeEditor's JSON
import { FRONTEND_STATE, waitForIdle, waitForUi5, waitForPopup } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForIdle(page);
  page.on('console', (m) => console.log('CON', m.type(), m.text().slice(0, 400)));
  page.on('pageerror', (e) => console.log('PERR', String(e).slice(0, 400)));
  console.log('XML', (await page.evaluate(`JSON.stringify(${FRONTEND_STATE}.oResponse)`) || '').match(/columnsPanel.{0,700}/)?.[0]);
  page.on('request', (r) => { if (r.method() === 'POST') console.log('REQ', (r.postData() || '').slice(0, 600)); });
  page.on('response', async (r) => { if (r.request().method() === 'POST') { const t = await r.text().catch(() => ''); console.log('RES', r.status(), t.slice(0, 1500)); } });
  await page.getByRole('button', { name: 'Show p13n.Popup' }).click();
  await waitForPopup(page, 'My Custom View Settings');
  await waitForIdle(page);
  // the seeded setP13nData arrived: City visible, Country/Region not
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('columnsPanel') && !c.bIsDestroyed);
    const d = p && p.getP13nData();
    return d && d.length === 3 && d[0].visible === true && d[1].visible === false;
  }, 'the columns panel never received the setP13nData seed');
  // tick "Country" in the panel's own list: focus its row and press Space
  const rowId = await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const p = all.find((c) => c.getId().endsWith('columnsPanel') && !c.bIsDestroyed);
    const it = p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL || 'p13n')?.getProperty('name') === 'key2')
      || p._oListControl.getItems()[1];
    return it.getId();
  });
  await page.evaluate((id) => document.getElementById(id).focus(), rowId);
  await page.keyboard.press('Space');
  await waitForIdle(page);
  console.log('DBG', await page.evaluate(() => { const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const p = all.find((c) => c.getId().endsWith('columnsPanel') && !c.bIsDestroyed);
    const e = all.filter((c) => c.getId().endsWith('p13nEditor'));
    return JSON.stringify({ busy: (0), lst: [p.hasListeners('change'), all.find((c)=>c.getId().endsWith('p13nPopup')).hasListeners('open')], act: document.activeElement && document.activeElement.id, data: p && p.getP13nData(), ed: e.map((x) => [x.bIsDestroyed, x.getValue()]), items: p._oListControl.getItems().map((i)=>[i.getId(), i.getSelected()]) }); }));
  await waitForUi5(page, () => {
    const e = ui5All().find((c) => c.getId().endsWith('p13nEditor') && !c.bIsDestroyed && c.getDomRef());
    if (!e) return false;
    try {
      const j = JSON.parse(e.getValue());
      const c = j.columns.find((x) => x.name === 'key2');
      return c && c.visible === true && j.sort[0].sorted === true && j.group[0].grouped === true;
    } catch (x) { return false; }
  }, 'ticking Country in the Columns panel never came back as the CodeEditor JSON (columns.key2.visible = true)');
};
