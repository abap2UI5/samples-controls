// p13n.Container in a Dialog and a ResponsivePopover: "Add custom view" is a
// backend row plus a view rebuild, and the follow-up action queued behind it
// must re-open d1/p1 on the REBUILT view - with the fourth view in it
import { waitForIdle, waitForUi5, waitForPopup } from '../../scripts/lib-e2e.mjs';

// open popup with this id, its p13n.Container carrying n views (live control
// only). n counts the Container's own "$default" navigation view, which list
// layout adds in front of the three static ones - and so does the original's
// addCustomView, which names the new view "View " + getViews().length: the
// last view must be View <n-1> / key view<n-1>, so the first added one is
// "View 4" / view4, never a second "View 3"
const openWithViews = (want) => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const pop = ui5All().find((c) => c.getId().endsWith('--' + want.pop) && !c.bIsDestroyed && c.isOpen && c.isOpen());
  const cont = ui5All().find((c) => c.getId().endsWith('--' + want.cont) && live(c));
  const last = cont && cont.getViews()[want.n - 1];
  return !!pop && !!cont && cont.getViews().length === want.n
    && last.getText() === `View ${want.n - 1}` && last.getKey() === `view${want.n - 1}`;
};

export default async (page, expect) => {
  await waitForIdle(page);
  // Dialog (the default choice)
  await page.getByRole('button', { name: 'Show P13nContainer used in Popup' }).click();
  await waitForPopup(page, 'My custom p13n Dialog');
  await waitForUi5(page, openWithViews, 'the Dialog did not open with its three static views',
    { pop: 'd1', cont: 'P13nContainer', n: 4 });
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Add custom view' }).first().click();
  await waitForIdle(page);
  await waitForUi5(page, openWithViews,
    'Add custom view (dialog) did not come back as an OPEN d1 whose container carries a fourth view "View 4" (key view4)',
    { pop: 'd1', cont: 'P13nContainer', n: 5 });
  await page.getByRole('button', { name: 'Close Dialog' }).click();
  await waitForUi5(page, () => !ui5All().some((c) => c.getId().endsWith('--d1') && !c.bIsDestroyed && c.isOpen()),
    'Close Dialog did not close d1');

  // Popover: pick it in the two-way bound RadioButtonGroup, then open
  await page.getByRole('radio', { name: 'Popover' }).click();
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Show P13nContainer used in Popup' }).click();
  await waitForPopup(page, 'My custom p13n Popover');
  await waitForUi5(page, openWithViews, 'the two-way bound "Popover" choice did not open p1',
    { pop: 'p1', cont: 'P13nContainerPopover', n: 4 });
  await waitForIdle(page);
  await (await waitForPopup(page, 'My custom p13n Popover')).getByRole('button', { name: 'Add custom view' }).click();
  await waitForIdle(page);
  await waitForUi5(page, openWithViews,
    'Add custom view (popover) did not come back as an OPEN p1 whose container carries a fourth view "View 4" (key view4)',
    { pop: 'p1', cont: 'P13nContainerPopover', n: 5 });
};
