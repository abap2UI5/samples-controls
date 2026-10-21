// IllustratedMessageSessionTimeout: Open Dialog arms a backend START_TIMER
// COUNTER_TICK (1000 ms) that re-arms itself per tick; every tick pushes
// /iSecondsLeft and /bIsExpiring into the still-open popup. Proved here: the
// description counts down 3-2-1-0 in that order, the dialog then switches to
// the expired state (title, Sign In + Close visible, Continue Working gone),
// Close destroys it, and Continue Working on a fresh dialog closes it and
// stops the counter (no later tick reopens or changes anything); the global
// busy overlay is never painted during the countdown.
import { waitForUi5, waitForIdle, waitForPopup, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

const readDialog = `(() => { ${UI5_ALL_SRC}
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const dlg = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Dialog' && !c.bIsDestroyed && c.isOpen());
  if (!dlg) return null;
  const im = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.IllustratedMessage' && live(c));
  const btns = dlg.getButtons().filter((b) => !b.bIsDestroyed).map((b) => b.getVisible() ? b.getText() : null).filter(Boolean);
  return { title: im && im.getTitle(), description: im && im.getDescription(), buttons: btns };
})()`;

export default async (page, expect) => {
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Open Dialog', exact: true }).click();
  await waitForPopup(page, 'Session Info');

  // sample the description every 100 ms until the expired state (or 15 s)
  const seen = await page.evaluate(async (src) => {
    const read = () => (0, eval)(src);
    const out = [];
    const t0 = Date.now();
    while (Date.now() - t0 < 15000) {
      const d = read();
      const bi = document.getElementById('sapUiBusyIndicator');
      if (bi && bi.offsetParent !== null) out.push('BUSY');
      const s = d ? `${d.title} | ${d.description}` : 'closed';
      if (out[out.length - 1] !== s) out.push(s);
      if (d && /has expired/.test(d.title || '')) break;
      await new Promise((r) => setTimeout(r, 100));
    }
    return out;
  }, readDialog);
  const counts = seen.map((s) => (s.match(/signed out in (\d+) seconds/) || [])[1]).filter(Boolean);
  // 3-2-1, then straight to expired: like the original's _decrementCounter,
  // the tick that reaches 0 sets iSecondsLeft 0 AND bIsExpiring false in one
  // go, so "0 seconds" is never on screen there either
  await expect(counts, `the description counted down 3-2-1 (saw ${JSON.stringify(seen)})`).toEqual(['3', '2', '1']);
  await expect(seen[seen.length - 1], 'the dialog switched to the expired state')
    .toBe('Your session has expired. | Sign in to pick up where you left off.');

  // no visible busy overlay between ticks: a plain START_TIMER tick calls
  // BusyIndicator.show( ) with UI5's default 1000 ms delay, so a tick that
  // answers inside a second never paints it (it IS raised once per tick -
  // 4 show( ) calls for open + 3 ticks, measured 2026-10-20)
  await expect(seen.includes('BUSY'), `the busy overlay showed during the countdown (${JSON.stringify(seen)})`).toBe(false);
  const expired = await page.evaluate(readDialog);
  await expect(expired && expired.buttons, 'the expired dialog shows Sign In and Close, not Continue Working').toEqual(['Sign In', 'Close']);
  await waitForIdle(page);

  // Close (DIALOG_CLOSE) destroys the popup
  await page.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForUi5(page, () => !ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Dialog' && !c.bIsDestroyed && c.isOpen()),
    'Close in the expired dialog did not destroy the Session Info dialog');
  await waitForIdle(page);

  // a fresh dialog, then Continue Working while it is counting: closes it and
  // the pending/next tick must not bring anything back
  await page.getByRole('button', { name: 'Open Dialog', exact: true }).click();
  await waitForPopup(page, 'Session Info');
  const fresh = await page.evaluate(readDialog);
  await expect(fresh && fresh.title, 'a reopened dialog starts in the expiring state again').toBe('Your session will expire soon.');
  await expect(fresh && fresh.buttons, 'the expiring dialog shows only Continue Working').toEqual(['Continue Working']);
  await page.getByRole('button', { name: 'Continue Working', exact: true }).click();
  await waitForUi5(page, () => !ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Dialog' && !c.bIsDestroyed && c.isOpen()),
    'Continue Working did not close the Session Info dialog');
  await page.waitForTimeout(4000);
  await expect(await page.evaluate(readDialog), 'no tick reopened the dialog after Continue Working').toBe(null);
};
