// Demo app "Team Calendar". The one thing the render gate cannot see is the
// SWAP: the original loads one calendar fragment per selection into a layout,
// this rebuild keeps both alive and hides one. Picking a team member must
// therefore HIDE the PlanningCalendar and show the SinglePlanningCalendar with
// that member's appointments - and picking "Team" must put it back.
//
// Found 2026-09-14: the team calendar's `visible` was a STATIC value written
// into the XML at render time, and member_select( ) renders nothing, so the
// single calendar appeared BELOW a team calendar that would not go away. Only
// the negated half was a live binding, which is why the way back looked right.
import { revealInOverflow, waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

/* Both calendars sit in a VBox of their own, and it is the BOX that carries the
 * bound `visible` - so the assertion has to walk up to it. `want` is
 * `<pc>/<spc>/<appointments of the single one>`, with `-` for "do not care". */
const swapped = (page, want, msg) => waitForUi5(page, (expected) => {
  const box = (c) => { for (let p = c && c.getParent(); p; p = p.getParent()) if (p.getMetadata().getName() === 'sap.m.VBox') return p; return null; };
  const pc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
  const spc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.SinglePlanningCalendar');
  if (!pc || !spc) return false;
  const is = [String(box(pc) && box(pc).getVisible()), String(box(spc) && box(spc).getVisible()), String(spc.getAppointments().length)];
  return expected.split('/').every((w, i) => w === '-' || w === is[i]);
}, msg, want);

export default async (page, expect) => {
  await waitForIdle(page);

  // the team and its four rows, with the appointments the mock gives them
  await waitForUi5(page, () => {
    const pc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
    return pc && pc.getRows().length === 4 && pc.getRows()[0].getAppointments().length === 12;
  }, 'the PlanningCalendar did not come up with the four team rows and their appointments');
  await swapped(page, 'true/false/-', 'the team calendar is not the only one on show at startup');

  /* pick a member: the team calendar goes, the single one comes with her rows.
   * The calendar's toolbarContent is an OverflowToolbar and at this viewport it
   * folds the Select, Create and the legend button into "Additional Options" -
   * they have no DOM node at all until it is opened (measured 2026-09-14). */
  await revealInOverflow(page, page.locator('[id$="--PlanningCalendarTeamSelector"]'));
  await page.locator('[id$="--PlanningCalendarTeamSelector"]').first().click();
  /* `.sapMSltPicker:visible` - the OPEN picker, and only it. Two reasons, both
   * measured here: the CLOSED Select renders its five items inline as well, so
   * a plain text locator picks a list nothing is listening to; and each of the
   * two selectors keeps its own picker popover once opened, so after the first
   * pick `.sapMSltPicker` alone has two matches and `.first()` is the closed
   * one - a 30s timeout that reads like a dead control. */
  await page.locator('.sapMSltPicker:visible').getByText('Elena Petrova', { exact: true }).first().click();
  await waitForIdle(page);
  await swapped(page, 'false/true/13',
    'picking a member left the team calendar on screen (a static `visible` again?) or the single calendar without her 13 appointments');

  // and back to the team
  await revealInOverflow(page, page.locator('[id$="--SinglePlanningCalendarTeamSelector"]'));
  await page.locator('[id$="--SinglePlanningCalendarTeamSelector"]').first().click();
  await page.locator('.sapMSltPicker:visible').getByText('Team', { exact: true }).first().click();
  await waitForIdle(page);
  await swapped(page, 'true/false/-', 'selecting "Team" did not bring the team calendar back');

  // the legend popover: a round-trip that builds a fragment and opens it BY the
  // button that fired it (the anchor is looked up by the button's own id, not
  // by the view-prefixed one - see the class)
  await revealInOverflow(page, page.locator('[id$="--PlanningCalendarLegendButton"]'));
  await page.locator('[id$="--PlanningCalendarLegendButton"]').first().click();
  await page.waitForSelector('.sapMPopover', { timeout: 30000 })
    .catch(() => { throw new Error('the legend button opened no popover'); });
  await expect(page.locator('.sapMPopover'), 'the calendar legend').toContainText('Team meeting');
};
