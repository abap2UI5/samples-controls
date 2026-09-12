// DateRangeSelection: the change event carries $event.oSource.sId plus the
// from/to/valid parameters to CHANGE, which writes the bound event_text
// ("Id: … From: … To: …") the original set imperatively. A range is typed
// into DRS1 (its DateInterval type over two Date parts with a yyyy/MM/dd
// pattern) and committed with Enter; the Text must then name DRS1 and the
// From date.
//
// NOT asserted: the bound valueState. It follows `${$parameters>/valid}`, a
// BOOLEAN t_arg the transpiled runtime delivers as the string 'true' where
// `valid = abap_true` cannot match — so the harness paints Error on a valid
// range while a real system paints None. That half stays with the human check
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the event Text label').toContainText('Change event');
  await waitForIdle(page);
  const inner = page.locator('[id$="DRS1-inner"]').first();
  await expect(inner, 'the DRS1 input').toBeVisibleEnabled();
  const seeded = await inner.inputValue();
  if (!/2014\/02\/02/.test(seeded)) throw new Error(`DRS1 did not render the seeded 2014-02-02 start through its DateInterval type, got "${seeded}"`);
  await inner.fill('2014/03/01 - 2014/03/10');
  await inner.press('Enter');
  const text = page.locator('[id$="TextEvent"]');
  await expect(text, 'the bound event text naming the source').toContainText('DRS1');
  await expect(text, 'the bound event text carrying the from date').toContainText('From:');
  const full = await text.innerText();
  if (!/From:\s*\S/.test(full) || /From:\s*\n?\s*To:/.test(full)) throw new Error(`the CHANGE round trip did not carry the from date: ${JSON.stringify(full)}`);
};
