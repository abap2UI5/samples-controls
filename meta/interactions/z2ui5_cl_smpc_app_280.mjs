// valueLiveUpdate off: the liveChange round-trip fills GET_VALUE while the
// TextArea's OWN model field (and with it the second Text) must NOT follow
// yet — that gap is the sample's point, so both legs are asserted. Typed
// with NO delay on purpose: the wire carries check_queue_last, so the last
// keystroke fired during a round-trip is kept and GET_VALUE ends on the
// typed value — until 2026-09-19 it was dropped and this module had to pace
// the keys 700ms apart (measured 2026-08-02 — see the port's sidecar NOTE).
//
// The wire also carries check_no_busy, and THAT is what the first typing leg
// below asserts. It is the half no value assertion can see: the port ends on
// the typed value either way, so this module was green while a full-screen
// busy overlay flashed over the field on every keystroke from the second
// character on. The demo kit original raises nothing at all - its liveChange
// handler is client-side - so any raise here is a deviation from the sample.
import { watchBusyOverlay, busyOverlayCount, waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const ta = page.locator('textarea').first();
  await expect(ta, 'the TextArea').toBeVisibleEnabled();
  await waitForIdle(page);
  await watchBusyOverlay(page);
  await ta.click();
  await ta.pressSequentially('abc');
  expect(await busyOverlayCount(page), 'busy-overlay raises while typing (check_no_busy keeps it down)')
    .toBe(0);
  await expect(page.locator("[id$='getValue']"), 'the liveChange round-trip filling GET_VALUE').toContainText('abc');
  // two nodes end in the id — the SimpleForm's grid wrapper and the Text itself
  const lagging = await page.locator("[id$='getProperty']").last().innerText();
  if (lagging.includes('abc')) throw new Error('model.getProperty() already followed although valueLiveUpdate is off');
  // flip the Switch: valueLiveUpdate is two-way bound, so the model now follows too
  await page.locator('.sapMSwtCont').first().click();
  await ta.click();
  await ta.pressSequentially('de');
  await expect(page.locator("[id$='getProperty']"), 'the model field once valueLiveUpdate is on').toContainText('abc');
};
