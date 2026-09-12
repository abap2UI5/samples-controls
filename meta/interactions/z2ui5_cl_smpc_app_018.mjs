// DateTimePicker: every picker's change carries $event.oSource.sId, the value
// and valid to CHANGE, which counts the events and writes the bound
// text_result the original handleChange set imperatively. A value typed into
// DTP1 and committed with Enter must produce "Change - Event 1: DateTimePicker
// …DTP1:" on the Text; the seeded DTP2 value must render through its
// DateTime type. The valueState half rides on the BOOLEAN valid arg (see
// app 017's note) and stays with the human check
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the panel header').toContainText('When DateTimePicker change events are fired');
  const dtp2 = await page.locator('[id$="DTP2-inner"]').first().inputValue();
  if (!/2016/.test(dtp2)) throw new Error(`DTP2 did not render its seeded 2016-02-18 value through the DateTime type, got "${dtp2}"`);
  await waitForIdle(page);
  const inner = page.locator('[id$="DTP1-inner"]').first();
  await expect(inner, 'the DTP1 input').toBeVisibleEnabled();
  await inner.fill('Feb 18, 2016, 10:32:30 AM');
  await inner.press('Enter');
  const text = page.locator('[id$="textResult"]');
  await expect(text, 'the bound change text').toContainText('Change - Event 1: DateTimePicker');
  await expect(text, 'the bound change text naming DTP1').toContainText('DTP1:');
};
