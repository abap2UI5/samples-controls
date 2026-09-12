// DraftIndicator: the controller's showDraftSaving/showDraftSaved/clearDraftState
// became a bound `state` — each button round-trips and the enum lands on the
// control. Read the property off the (rendered) DraftIndicator after each
// press; the Saving label is asserted in the DOM too, since Saving is the one
// state the control keeps visible until the next transition
import { waitForUi5, ui5All, waitForIdle } from '../../scripts/lib-e2e.mjs';

// runs in the PAGE (stringified), so the wanted state travels as the arg
const state = (want) => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.DraftIndicator'
  && !c.bIsDestroyed && c.getDomRef() && c.getState() === want);

export default async (page, expect) => {
  await waitForUi5(page, state, 'the DraftIndicator did not boot in its seeded Clear state', 'Clear');
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Set Saving Draft state', exact: true }).first().click();
  await waitForUi5(page, state, 'the SET_SAVING_DRAFT round trip never set state Saving', 'Saving');
  // the Saving label is the bundle's DRAFT_INDICATOR_SAVING_DRAFT text
  // ("Updating draft..." on this UI5), shown for ~1.5s - assert the word only
  await expect(page.locator('.sapMDraftIndicator'), 'the Saving label').toContainText(/draft/i);
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Set Draft Saved state', exact: true }).first().click();
  await waitForUi5(page, state, 'the SHOW_DRAFT_SAVED round trip never set state Saved', 'Saved');
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Clear Draft state', exact: true }).first().click();
  await waitForUi5(page, state, 'the CLEAR_DRAFT_STATE round trip never set state Clear', 'Clear');
};
