// EngineCustomFilters: the improvised filter Dialog's MultiInputs. Picking a
// suggestion creates a Token, whose tokenUpdate wire carries addedTokens as a
// JSON array; the backend writes it into the bound tokens aggregation, and OK
// rebuilds the table's items binding with the EQ filters
import { waitForIdle, waitForUi5, waitForPopup, revealInOverflow } from '../../scripts/lib-e2e.mjs';

const ROWS = () => {
  const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
  const t = Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .find((c) => c.getId().endsWith('--persoTable') && live(c));
  return t ? t.getItems().map((i) => i.getCells()[0].getText() + '/' + i.getCells()[2].getText()) : null;
};

export default async (page, expect) => {
  await waitForIdle(page);
  expect((await page.evaluate(ROWS)).length, 'the unfiltered table rows').toBe(14);
  const settings = page.getByRole('button', { name: 'Settings' });
  await revealInOverflow(page, settings);
  await settings.click();
  await waitForPopup(page, 'Custom Filter Settings');
  await waitForIdle(page);

  // City: type "Berl", take the suggestion - a Token, round-tripped as addedTokens
  const city = page.locator('[id$="--cityFilter-inner"]');
  await city.click();
  await city.pressSequentially('Berl', { delay: 50 });
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--cityFilter') && !c.bIsDestroyed
    && c._getSuggestionsPopover && c._getSuggestionsPopover() && c._getSuggestionsPopover().isOpen()),
    'typing "Berl" into the City MultiInput opened no suggestions');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const mi = ui5All().find((c) => c.getId().endsWith('--cityFilter') && live(c));
    return !!mi && mi.getTokens().map((t) => t.getText()).join() === 'Berlin'
      && !!mi.getBinding('tokens') && mi.getBinding('tokens').getLength() === 1;
  }, 'the suggestion-created "Berlin" token did not come back through the bound tokens aggregation');

  await (await waitForPopup(page, 'Custom Filter Settings')).getByRole('button', { name: 'OK' }).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    if (!t) return false;
    const rows = t.getItems().map((i) => i.getCells()[2].getText());
    return rows.length === 4 && rows.every((c) => c === 'Berlin');
  }, 'OK in the filter dialog did not filter the table down to the four Berlin rows');

  // re-open: the dialog is seeded with the Berlin condition; remove the token
  // by keyboard (Backspace selects it, a second Backspace deletes it) - the
  // removedTokens half of the wire - and OK lifts the filter again
  await waitForIdle(page);
  const settings2 = page.getByRole('button', { name: 'Settings' });
  await revealInOverflow(page, settings2);
  await settings2.click();
  await waitForPopup(page, 'Custom Filter Settings');
  await waitForIdle(page);
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--cityFilter') && !c.bIsDestroyed && c.getDomRef()
    && c.getTokens().map((t) => t.getText()).join() === 'Berlin'), 'the re-opened dialog was not seeded with the Berlin token');
  await page.locator('[id$="--cityFilter-inner"]').click();
  await page.keyboard.press('Backspace');
  await page.keyboard.press('Backspace');
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const mi = ui5All().find((c) => c.getId().endsWith('--cityFilter') && live(c));
    return !!mi && mi.getTokens().length === 0 && mi.getBinding('tokens').getLength() === 0;
  }, 'deleting the Berlin token did not empty the bound tokens aggregation (removedTokens)');
  await (await waitForPopup(page, 'Custom Filter Settings')).getByRole('button', { name: 'OK' }).click();
  await waitForIdle(page);
  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const t = ui5All().find((c) => c.getId().endsWith('--persoTable') && live(c));
    return !!t && t.getItems().length === 14;
  }, 'OK after removing the token did not lift the filter (14 rows)');
};
