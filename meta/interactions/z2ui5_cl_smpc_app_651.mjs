// VariantManagement on a bound VariantItem template: Save As (the save event's
// name + boolean flags create a backend row and the defaultKey), Manage (rename
// and delete in the dialog: the deleted keys arrive as a JSON array, the rename
// is written back through the two-way bound item and must survive the next
// round-trip), then select from the "my Favorites" popover (key round-trip,
// two-way selectedKey)
import { waitForIdle, waitForUi5, revealInOverflow } from '../../scripts/lib-e2e.mjs';

// the live VariantManagement's state: selected/default key, modified, items
const VM = () => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const vm = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getId().endsWith('--vm') && c.isA('sap.m.VariantManagement') && live(c));
  if (!vm) return null;
  return {
    selected: vm.getSelectedKey(), def: vm.getDefaultKey(), modified: vm.getModified(),
    items: vm.getItems().map((i) => `${i.getKey()}=${i.getTitle()}`),
  };
};

export default async (page, expect) => {
  const vm = () => page.evaluate(VM);
  const openVm = async () => {
    await waitForIdle(page);
    // the icon-only trigger measures 0x0 unthemed: press it by keyboard
    await page.evaluate(() => document.querySelector('[id$="--vm-trigger"]').focus());
    await page.keyboard.press('Enter');
    await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--vm-popover') && !c.bIsDestroyed && c.isOpen()),
      'the variant trigger did not open the "my Favorites" popover');
  };
  // the panel's OverflowToolbar folds its button away - reveal and press together
  const toggleModified = async () => {
    await waitForIdle(page);
    const btn = page.getByRole('button', { name: 'Toggle Modify View' });
    await revealInOverflow(page, btn);
    await btn.click();
  };
  const toast = (text) => waitForUi5(page, (t) => [...document.querySelectorAll('.sapMMessageToast')].some((e) => e.textContent.includes(t)),
    `no "${text}" toast`, text);

  await waitForIdle(page);
  expect(await vm(), 'the initial variant state').toEqual({
    selected: '2', def: '2', modified: false, items: ['Standard=Entry1', '2=Entry2', '3=Entry3', '4=Entry4'] });

  // Toggle Modify View, then Save As "MyView" as the default
  await toggleModified();
  await waitForIdle(page);
  expect((await vm()).modified, 'the modified flag after Toggle Modify View').toBe(true);
  await openVm();
  await page.locator('[id$="--vm-saveas"]').click();
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--vm-savedialog') && !c.bIsDestroyed && c.isOpen()),
    'Save As did not open the save dialog');
  const name = page.locator('[id$="--vm-name-inner"]');
  await name.fill('MyView');
  await page.locator('.sapMCb[id$="--vm-default"]').click();
  await page.locator('[id$="--vm-variantsave"]').click();
  await waitForIdle(page);
  await toast("New view 'MyView' created");
  await waitForUi5(page, () => {
    const vm = ui5All().find((c) => c.getId().endsWith('--vm') && c.isA('sap.m.VariantManagement') && !c.bIsDestroyed && c.getDomRef());
    const mine = vm && vm.getItems().find((i) => i.getTitle() === 'MyView');
    return !!mine && /^key_/.test(mine.getKey()) && vm.getDefaultKey() === mine.getKey() && vm.getModified() === false
      && mine.getAuthor() === 'sample' && mine.getSharing() === 'Private';
  }, 'Save As "MyView" (default) did not come back as a backend row with key_..., the defaultKey and modified reset');

  // Manage: rename Entry2, delete Entry3, Save
  await openVm();
  await page.locator('[id$="--vm-manage"]').click();
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--vm-managementdialog') && !c.bIsDestroyed && c.isOpen()),
    'Manage did not open the management dialog');
  const rows = await page.evaluate(() => {
    const vm = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getId().endsWith('--vm') && c.isA('sap.m.VariantManagement') && !c.bIsDestroyed && c.getDomRef());
    const keys = vm.getItems().map((i) => i.getKey());
    return { e2: keys.indexOf('2'), e3: keys.indexOf('3') };
  });
  const rename = page.locator(`[id$="--vm-manage-input-${rows.e2}-inner"]`);
  await rename.fill('Renamed2');
  await rename.press('Tab');
  await page.locator(`[id$="--vm-manage-del-${rows.e3}"]`).click();
  await page.locator('[id$="--vm-managementsave"]').click();
  await waitForIdle(page);
  // one more round-trip: what the backend now holds comes back as the model
  await toggleModified();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const vm = ui5All().find((c) => c.getId().endsWith('--vm') && c.isA('sap.m.VariantManagement') && !c.bIsDestroyed && c.getDomRef());
    if (!vm) return false;
    const m = vm.getModel().getProperty('/T_ITEMS');
    return !m.some((i) => i.KEY === '3') && m.find((i) => i.KEY === '2').TITLE === 'Renamed2' && m.length === 4;
  }, 'Manage did not delete Entry3 in the backend (deleted keys) and keep the Entry2 rename (two-way write-back)');
  /* (2026-10-20) this leg was red on the transpiled backend before the port
     replaced translate( from = `[]"` to = `` ): the abaplint runtime builds an
     unescaped [...] regex class from FROM, so `["3"]` came out unchanged and
     no key was deleted. Measured green against a patched transpiled backend;
     it reads green here once the backend is rebuilt from the fixed class. */

  // select "Entry1" (Standard) from the popover
  /* KNOWN DEFECT on UI5 1.152 (2026-10-20): the popover list is EMPTY. From
     this release on VariantManagement filters that list (bound to its own
     $mVariants ManagedObjectModel, properties `visible`/`favorite`) with the
     paths of the app's items TEMPLATE (_resolveTemplatePath: `VISIBLE`,
     `FAVORITE`), which the ManagedObjectModel does not know - every item is
     filtered out, so no view can be selected. The original declares static
     VariantItems and never meets it; the port's bound template does. */
  await openVm();
  const entry1 = await page.evaluate(() => {
    const list = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getId().endsWith('--vm-list') && !c.bIsDestroyed);
    const it = list && list.getItems().find((i) => i.getText() === 'Entry1');
    return it && it.getDomRef() ? it.getId() : null;
  });
  expect(!!entry1, 'an "Entry1" item rendered in the "my Favorites" popover list').toBeTruthy();
  await page.locator(`[id="${entry1}"]`).click();
  await waitForIdle(page);
  await toast('Selected Key: Standard');
  await waitForUi5(page, () => {
    const vm = ui5All().find((c) => c.getId().endsWith('--vm') && c.isA('sap.m.VariantManagement') && !c.bIsDestroyed && c.getDomRef());
    return !!vm && vm.getSelectedKey() === 'Standard' && vm.getModel().getProperty('/SELECTEDKEY') === 'Standard'
      && vm.getModified() === false;
  }, 'selecting Entry1 did not write selectedKey Standard back to the model');
};
