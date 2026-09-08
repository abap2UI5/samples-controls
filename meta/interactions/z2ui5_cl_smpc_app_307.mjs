// CalendarMultipleDaySelection: clicking a day round-trips the WHOLE
// selectedDates aggregation in one marshalled arg and fills the List. Two days
// are picked, because one proves nothing about the array route — the 31-slot
// per-index wire this replaced carried the first day just as well. "Remove All
// Selected Dates" then has to clear BOTH sides — the model AND the aggregation
// the control writes itself, which is what the removeAllSelectedDates
// follow-up action does (abap2UI5 #2535; before it the days stayed highlighted)
import { waitForCount, waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const day = page.locator('.sapUiCalItem').first();
  if (!(await day.count())) throw new Error('the Calendar rendered no day cells');
  // the day cell carries no clickable layout box headless, so a day is
  // picked the keyboard way — focus the cell, press Enter
  await page.evaluate(() => document.querySelectorAll('.sapUiCalItem')[0].focus());
  await page.keyboard.press('Enter');
  await waitForCount(page, '.sapUiCalItemSel', 1, 'the clicked day was not selected');
  await waitForCount(page, '.sapMSLI', 1, 'the selected day did not reach the List');
  await waitForIdle(page);

  /* THE SECOND DAY HAS TO BE IN THE MONTH THE CALENDAR IS SHOWING, and which
     month that is moves under the leg. A sap.ui.unified.Calendar renders one
     month at a time (42 cells: the six-week grid around it), and the response
     to the first pick re-renders it around the day just selected - so the DOM
     order changes and `.sapUiCalItem[1]` is no longer the neighbour of
     `[0]`. Measured before this: cell 0 selected 2026-08-30, the grid came
     back on August, cell 1 was then 2026-07-27, and picking it re-rendered the
     grid on JULY - where 08-30 does not exist. Two dates in the model, two
     rows in the List, and one highlighted cell, for ever.
     So the neighbour is found in the CURRENT grid, next to the day that is
     actually selected, and inside the same month. */
  const second = await page.evaluate(`(() => {
    const cells = [...document.querySelectorAll('.sapUiCalItem')];
    const at = cells.findIndex((c) => c.classList.contains('sapUiCalItemSel'));
    if (at < 0) return null;
    const month = (c) => (c.getAttribute('data-sap-day') || '').slice(0, 6);
    const next = cells.slice(at + 1).find((c) => month(c) === month(cells[at]))
              || cells.slice(0, at).reverse().find((c) => month(c) === month(cells[at]));
    if (!next) return null;
    next.focus();
    return next.getAttribute('data-sap-day');
  })()`);
  if (!second) throw new Error('the calendar shows no second day in the month it selected the first one in');
  await page.keyboard.press('Enter');
  await waitForCount(page, '.sapUiCalItemSel', 2, `the second day ${second} was not selected alongside the first`);
  await waitForCount(page, '.sapMSLI', 2,
    'the second day never reached the List — the marshalled DateRange array did not travel whole');
  await page.getByRole('button', { name: 'Remove All Selected Dates', exact: true }).first().click();
  await expect(page.locator('.sapMList'), 'the List after Remove All').toContainText('No Dates Selected');
  await expect(page.locator('.sapUiCalItemSel'), "the calendar's highlighting after removeAllSelectedDates")
    .toHaveCountBelow(1);
};
