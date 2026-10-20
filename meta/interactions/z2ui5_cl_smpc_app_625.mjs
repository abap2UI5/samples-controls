// AvatarActiveState: the Avatar press round-trip toggles the two-way bound
// `active` flag and follows up with control_by_id userMenu openBy myAvatar /
// close; a list item press closes the menu; the Popover's afterClose
// (POPOVER_CLOSE) resets the flag when the menu is dismissed any other way.
//
// Every leg asserts BOTH halves of the wire on the RENDERED controls - the
// Avatar's bound active property (only the backend writes it) and the
// Popover's open state (only the follow-up action changes it) - read off the
// controls that are still in the document (the outgoing view stays in the
// registry while a round-trip rebuilds it).
import { waitForUi5, waitForIdle, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

const state = () => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const av = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Avatar' && c.getId().endsWith('myAvatar') && live(c));
  const pop = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Popover' && c.getId().endsWith('userMenu') && !c.bIsDestroyed);
  return { active: av ? av.getActive() : null, open: pop ? pop.isOpen() : null };
};

async function waitState(page, want, msg) {
  await waitForUi5(page, (w) => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const av = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Avatar' && c.getId().endsWith('myAvatar') && live(c));
    const pop = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Popover' && c.getId().endsWith('userMenu') && !c.bIsDestroyed);
    if (!av || !pop) return false;
    const os = pop.oPopup && pop.oPopup.getOpenState();
    // a popup that is OPENING/CLOSING is not settled yet
    if (os === 'OPENING' || os === 'CLOSING') return false;
    return av.getActive() === w.active && pop.isOpen() === w.open;
  }, msg, want);
  await waitForIdle(page);
}

async function pressAvatar(page) {
  // the Avatar is an <span role=button>; focus + Enter goes through its own
  // press handling even where the unthemed box would refuse a click
  await page.evaluate(() => {
    const el = [...document.querySelectorAll('[id$="myAvatar"]')].find((e) => document.body.contains(e));
    el.focus();
  });
  await page.keyboard.press('Enter');
}

export default async (page, expect) => {
  // the unthemed Avatar measures 0x0 (no sapFAvatar CSS, and its image comes
  // from sdk.openui5.org, which the harness 404s) - require it in the DOM
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Avatar' && c.getId().endsWith('myAvatar') && c.getDomRef() && c.hasListeners('press')),
    'the press-wired Avatar myAvatar did not render');
  await waitForIdle(page);
  await expect(await page.evaluate(`(() => { ${UI5_ALL_SRC} return (${state.toString()})(); })()`), 'the initial state (inactive, menu closed)')
    .toEqual({ active: false, open: false });

  // 1st press: AVATAR_PRESS -> active = true + openBy myAvatar
  await pressAvatar(page);
  await waitState(page, { active: true, open: true }, 'the first Avatar press did not set the bound active flag and open the user menu by the Avatar');
  await expect(page.locator('.sapMPopover').filter({ hasText: 'Recent Activities' }).first(), 'the open user menu').toBeVisible();

  // the menu is opened BY the Avatar (openBy myAvatar), not centred
  const opener = await page.evaluate(() => {
    const pop = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
      .find((c) => c.getMetadata().getName() === 'sap.m.Popover' && c.getId().endsWith('userMenu') && !c.bIsDestroyed);
    const o = pop && pop._oOpenBy;
    return o ? (o.id || o.getId?.() || '') : '';
  });
  await expect(/myAvatar/.test(opener), `the user menu's opener is the Avatar (got "${opener}")`).toBeTruthy();

  // 2nd press while open: AVATAR_PRESS -> active = false + close
  await pressAvatar(page);
  await waitState(page, { active: false, open: false }, 'the second Avatar press did not reset the active flag and close the user menu');
  // and it STAYS closed - no autoclose/press race reopening it
  await page.waitForTimeout(800);
  await waitState(page, { active: false, open: false }, 'the user menu reopened (or the flag flipped back) after the second Avatar press');

  // list item press: LIST_ITEM_PRESS -> active = false + close (afterClose round-trip follows)
  await pressAvatar(page);
  await waitState(page, { active: true, open: true }, 'the third Avatar press did not reopen the user menu');
  await page.locator('.sapMPopover li').filter({ hasText: 'Settings' }).first().click();
  await waitState(page, { active: false, open: false }, 'pressing the Settings list item did not close the user menu and reset the active flag');

  // afterClose alone: dismiss with Escape - no app event but POPOVER_CLOSE resets the flag
  await pressAvatar(page);
  await waitState(page, { active: true, open: true }, 'the fourth Avatar press did not reopen the user menu');
  await page.keyboard.press('Escape');
  await waitState(page, { active: false, open: false }, 'closing the user menu with Escape did not reach afterClose (POPOVER_CLOSE) to reset the active flag');
};

