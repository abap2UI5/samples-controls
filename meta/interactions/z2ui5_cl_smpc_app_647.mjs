// p13n.Engine on a GridList: the Settings button seeds the SelectionPanel with
// setP13nData and opens the p13n.Popup; on OK the close wire hands back
// getP13nData( true ) and the backend re-orders and hides the list items
import { waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

// the id of the SelectionPanel row whose p13n entry carries this name
const panelRow = (page, panel, name) => page.evaluate(([panel, name]) => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
  const p = all.find((c) => c.getId().endsWith('--' + panel) && !c.bIsDestroyed);
  const row = p && p._oListControl.getItems().find((i) => i.getBindingContext(p.P13N_MODEL).getProperty('name') === name);
  return row ? row.getId() : null;
}, [panel, name]);

export default async (page, expect) => {
  await waitForIdle(page);
  await page.getByRole('button', { name: /settings/i }).first().click();
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--p13nPopup-dialog') && !c.bIsDestroyed && c.isOpen()),
    'the Settings button did not open the p13n.Popup');
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('--itemsPanel') && !c.bIsDestroyed);
    const d = p && p.getP13nData();
    return !!d && d.length === 5 && d.every((e) => e.visible === true) && d[4].label === 'John Williams';
  }, 'the Settings press never handed the SelectionPanel its setP13nData state');

  // John Williams to the top (focus the row, Ctrl+Home - the panel's own
  // move-to-top shortcut), Petra Maier unticked (focus, Space)
  const john = await panelRow(page, 'itemsPanel', 'person5');
  expect(!!john, 'a "John Williams" row in the panel').toBeTruthy();
  await page.evaluate((id) => document.getElementById(id).focus(), john);
  await page.keyboard.press('Control+Home');
  const petra = await panelRow(page, 'itemsPanel', 'person2');
  await page.evaluate((id) => document.getElementById(id).focus(), petra);
  await page.keyboard.press('Space');
  await waitForUi5(page, () => {
    const p = ui5All().find((c) => c.getId().endsWith('--itemsPanel') && !c.bIsDestroyed);
    const d = p.getP13nData(true).map((e) => e.name);
    return d.join() === 'person5,person1,person3,person4';
  }, 'the panel did not take the move-to-top and the untick');

  await page.locator('[id$="--p13nPopup-confirmBtn"]').click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const l = ui5All().find((c) => c.getId().endsWith('--persoList') && live(c));
    if (!l) return false;
    const names = l.getItems().filter(live).map((i) => i.getDomRef().textContent);
    return names.length === 4 && /John/.test(names[0]) && /Williams/.test(names[0]) && !names.some((n) => /Petra/.test(n));
  }, 'closing the p13n.Popup with OK did not lead the GridList with John Williams and drop Petra Maier');
};
