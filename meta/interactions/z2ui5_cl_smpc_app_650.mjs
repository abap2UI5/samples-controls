// p13n.Popup: the open/change wires carry the panels' getP13nData( ) through
// the event source - toggling a column in the SelectionPanel the way the UI
// does (focus the row, Space) must land in the backend and come back as the
// CodeEditor's JSON.
//
// KNOWN PORT DEFECT (2026-10-20): red on purpose. The wires wrap the data in
// JSON.stringify( ), and an XML event-handler expression has no JSON global -
// EventHandlerResolver hands the parser only $controller/$event, so UI5 logs
// "Unsupported global identifier 'JSON'" and the handler dies with
// "Cannot read properties of undefined (reading 'stringify')": no POPUP_OPEN
// and no *_CHANGE round-trip ever leaves the browser. Passing
// $event.oSource.getP13nData() as it is (the frontend sends an array
// argument as JSON) makes this module pass - measured against a patched
// transpiled backend.
import { waitForIdle, waitForUi5, waitForPopup } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await waitForIdle(page);
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
    const it = p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL).getProperty('name') === 'key2');
    return it ? it.getId() : null;
  });
  expect(!!rowId, 'a "Country" row in the Columns panel').toBeTruthy();
  await page.evaluate((id) => document.getElementById(id).focus(), rowId);
  await page.keyboard.press('Space');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('columnsPanel') && !c.bIsDestroyed);
    return p.getP13nData()[1].visible === true;
  }, 'Space on the Country row did not tick it in the panel');
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
