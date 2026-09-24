// Demo app "Team Calendar". Rebuilt 1:1 on 2026-09-24 after a side-by-side
// comparison with the original; what this module walks, in the order the
// original's own OPA journey (test/integration/MainJourney.js) does:
//   - startup: the team's PlanningCalendar ALONE in the layout (the original
//     swaps one calendar fragment in, never both), four rows, the month view
//     of the model, and a Select of "Team" plus one item per person, keyed by
//     the person's index as _populateSelect( ) keys them;
//   - "Create" toasts the original's text; the legend button toggles the
//     legend popover without a round-trip;
//   - the date and the view the user reaches travel across every switch:
//     startDateChange is kept, and viewChange puts the calendar back on the
//     kept date (the view is rebuilt for it);
//   - a member picked in the Select, or a row clicked, opens that person's
//     SinglePlanningCalendar on the kept view (selectedView is an association
//     set through the calendar's modelContextChange) with the person's rows;
//   - and "Team" brings the PlanningCalendar back on the view picked last.
//
// Found 2026-09-14: the team calendar's `visible` was a STATIC value written
// into the XML, so the single calendar appeared BELOW a team calendar that
// would not go away. There is no `visible` any more - a switch rebuilds the
// view with the one calendar - so the checks below ask that the other one is
// GONE, not hidden.
import { UI5_ALL_SRC, revealInOverflow, waitForIdle, waitForUi5 } from '../../scripts/lib-e2e.mjs';

/** run fn once in the page, with ui5All( ) in scope */
const act = (page, fn, arg) => page.evaluate(`(() => { ${UI5_ALL_SRC} return (${fn.toString()})(${JSON.stringify(arg ?? null)}); })()`);

/* the one calendar on show: `pc` / `spc`, and the other one must not exist.
 * `want` carries what to compare - every key is optional */
const calendar = (page, want, msg) => waitForUi5(page, (w) => {
  const all = ui5All();
  const pc = all.find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
  const spc = all.find((c) => c.getMetadata().getName() === 'sap.m.SinglePlanningCalendar');
  const cal = w.kind === 'pc' ? pc : spc;
  if (!cal || (w.kind === 'pc' ? spc : pc)) return false;
  const sel = all.find((c) => c.getMetadata().getName() === 'sap.m.Select' && /TeamSelector$/.test(c.getId()));
  if (!sel) return false;
  if (w.member !== undefined && sel.getSelectedKey() !== w.member) return false;
  if (w.start !== undefined && cal.getStartDate().getTime() !== w.start) return false;
  if (w.kind === 'pc') {
    if (w.view !== undefined && cal.getViewKey() !== w.view) return false;
    if (w.rows !== undefined && cal.getRows().length !== w.rows) return false;
  } else {
    const view = all.find((c) => c.getId() === cal.getSelectedView());
    if (w.view !== undefined && (!view || view.getKey() !== w.view)) return false;
    if (w.rows !== undefined && cal.getAppointments().length !== w.rows) return false;
  }
  return true;
}, msg, want);

/* a user's pick in the calendar header's view switch: the SegmentedButton's
 * selectionChange, which is what both calendars listen to. Returns the start
 * date the calendar holds right after it re-aligned itself to the new view -
 * the date the original's viewChangeHandler puts it back on */
const switchView = (page, kind, key) => act(page, ({ k, v }) => {
  const cal = ui5All().find((c) => c.getMetadata().getName() === (k === 'pc' ? 'sap.m.PlanningCalendar' : 'sap.m.SinglePlanningCalendar'));
  const seg = cal._getHeader()._getOrCreateViewSwitch();
  const item = seg.getItems().find((i) => i.getKey() === v);
  seg.setSelectedKey(v);
  seg.fireSelectionChange({ item });
  return cal.getStartDate().getTime();
}, { k: kind, v: key });

/* pick an entry of the "Calendar for:" Select. The calendar's toolbar is an
 * OverflowToolbar and unthemed it folds the Select, Create and the legend
 * button into "Additional Options" at any viewport - they have no DOM node at
 * all until it is opened (measured 2026-09-14 and 2026-09-24). `.sapMSltPicker:visible` is the OPEN
 * picker, and only it: the CLOSED Select renders its items inline as well */
const pick = async (page, selectId, text) => {
  const sel = page.locator(`[id$="--${selectId}"]`);
  await revealInOverflow(page, sel);
  await sel.first().click();
  await page.locator('.sapMSltPicker:visible').getByText(text, { exact: true }).first().click();
  await waitForIdle(page);
};

export default async (page, expect) => {
  await waitForIdle(page);

  // startup: the team, its four rows with the mock's appointments, the month
  // view the model names, "Team" selected, and no single calendar anywhere
  await calendar(page, { kind: 'pc', view: 'OneMonth', rows: 4, member: 'Team' },
    'the PlanningCalendar did not come up alone, on the month view, with the four team rows');
  await waitForUi5(page, () => {
    const pc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
    const sel = ui5All().find((c) => /--PlanningCalendarTeamSelector$/.test(c.getId()));
    const items = sel.getItems().map((i) => `${i.getKey()}:${i.getText()}`).join('|');
    return pc.getRows()[0].getAppointments().length === 12 && pc.getRows()[3].getIntervalHeaders().length === 4
      && items === 'Team:Team|0:John Miller|1:Donna Moore|2:Elena Petrova|3:John Li';
  }, 'the rows lack their appointments / interval headers, or the Select is not "Team" plus the four people keyed by index');

  // "Create" - appointmentCreate's toast
  const create = page.locator('[id$="--PlanningCalendarCreateAppointmentButton"]');
  await revealInOverflow(page, create);
  await create.first().click();
  await expect(page.locator('.sapMMessageToast'), 'the Create toast').toContainText('Creating new appointment...');
  await waitForIdle(page);

  /* the legend: openLegend toggles its ResponsivePopover by the button, in the
   * browser. Unthemed, the header's toolbar folds EVERYTHING into its overflow
   * at any viewport (the ToolbarSpacer and the SegmentedButton each measure
   * the full toolbar width), and the legend opened from inside that popover is
   * its CHILD popup: the overflow closes on the button's press
   * (_closeOnInteraction) and UI5 closes the child with it - measured
   * 2026-09-24, beforeOpen then an immediate close from Popup.closePopup. The
   * original does exactly the same when its button sits in the overflow; on a
   * themed toolbar with room it does not. So the overflow is held open for
   * this one step, and the app's wire is what opens and closes the legend. */
  const legend = page.locator('[id$="--PlanningCalendarLegendButton"]');
  await revealInOverflow(page, legend);
  const held = await act(page, () => {
    const tb = ui5All().find((c) => c.isA('sap.m.OverflowToolbar') && /--PlanningCalendar-Header-ActionsToolbar$/.test(c.getId()));
    const ap = tb && tb._getPopover && tb._getPopover();
    if (!ap || !ap.isOpen()) return false;
    window.__a2ui5HeldClose = ap.close;
    ap.close = function () { return this; };
    return true;
  });
  // open, with the model's five appointment items ... The button sits in the
  // held-open overflow popover: visible and the element under the pointer, but
  // Playwright's stability wait on that popover can stall (measured 2026-09-24:
  // only when another app ran before in the same browser) - so the click skips
  // the actionability wait and lands on the button itself
  await legend.first().click({ force: true });
  await waitForUi5(page, () => {
    const pop = ui5All().find((c) => /--legendPopover$/.test(c.getId()));
    const leg = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendarLegend');
    return pop && pop.isOpen() && pop.getTitle() === 'Calendar Legend' && leg
      && leg.getAppointmentItems().map((i) => i.getText()).join('|') === 'Team meeting|Personal|Discussions|Out of office|Private meeting';
  }, 'the legend button opened no "Calendar Legend" popover with the five appointment types');
  // ... and closed by the same button (openLegend: isOpen ? close : openBy)
  await legend.first().click({ force: true });
  await waitForUi5(page, () => !ui5All().find((c) => /--legendPopover$/.test(c.getId())).isOpen(),
    'a second press of the legend button did not close the legend (openLegend toggles)');
  if (held) {
    await act(page, () => {
      const tb = ui5All().find((c) => c.isA('sap.m.OverflowToolbar') && /--PlanningCalendar-Header-ActionsToolbar$/.test(c.getId()));
      const ap = tb._getPopover();
      ap.close = window.__a2ui5HeldClose;
      ap.close();
    });
  }
  await waitForIdle(page);

  /* startDateChangeHandler: the arrow moves on a month and the date is kept -
   * the round-trip must not put the calendar back on the model's October */
  const next = await act(page, () => {
    const pc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
    pc._getHeader()._oNextBtn.firePress();
    return pc.getStartDate().getTime();
  });
  await waitForIdle(page);
  await calendar(page, { kind: 'pc', view: 'OneMonth', start: next },
    'the start date the arrow reached did not survive the startDateChange round-trip');

  /* viewChangeHandler: the week view, back on the kept date - the calendar is
   * REBUILT for it, so the date it shows now is the date the backend kept */
  const week = await switchView(page, 'pc', 'Week');
  await waitForIdle(page);
  await calendar(page, { kind: 'pc', view: 'Week', start: week, rows: 4 },
    'after a view switch the rebuilt team calendar is not on the week view and the kept start date');

  // a member from the Select: the SinglePlanningCalendar alone, her 13 rows,
  // the view and the date the team calendar was on
  await pick(page, 'PlanningCalendarTeamSelector', 'Elena Petrova');
  await calendar(page, { kind: 'spc', member: '2', view: 'Week', start: week, rows: 13 },
    'picking Elena Petrova did not show her SinglePlanningCalendar alone, with her 13 appointments, on the kept week and date');
  // its fragment binds the appointments' text and icon to paths the rows do
  // not have - so they show neither, as in the demo kit
  await waitForUi5(page, () => {
    const spc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.SinglePlanningCalendar');
    return spc.getAppointments().every((a) => !a.getText() && !a.getIcon());
  }, 'the single calendar\'s appointments show a text or an icon the original does not');

  // the view switch of the single calendar is kept too
  await switchView(page, 'spc', 'Day');
  await waitForIdle(page);
  await calendar(page, { kind: 'spc', member: '2', view: 'Day', rows: 13 },
    'the day view picked in the single calendar did not survive the rebuild');

  // "Team" brings the team calendar back, on the view picked last
  await pick(page, 'SinglePlanningCalendarTeamSelector', 'Team');
  await calendar(page, { kind: 'pc', member: 'Team', view: 'Day', rows: 4 },
    'selecting "Team" did not bring the team calendar back alone, on the day view');

  // rowSelectionHandler: a row opens that person's calendar - John Li, index 3
  await act(page, () => {
    const pc = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.PlanningCalendar');
    pc.fireRowSelectionChange({ rows: [pc.getRows()[3]] });
  });
  await waitForIdle(page);
  await calendar(page, { kind: 'spc', member: '3', view: 'Day', rows: 13 },
    'selecting the row of John Li did not open his SinglePlanningCalendar on the day view');
};
