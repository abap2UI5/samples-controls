// MultiInput: (1) the bound suggestionItems with their NAME sorter — typing
// "Notebook" opens suggestions and picking the first adds it as a token;
// (2) the z2ui5.cc.MultiInputExt companion installs the original's validator
// on multiInput1, so free text committed with Enter becomes a token there.
// Tokens are counted off the controls' aggregations (the Tokenizer collapses
// them visually)
import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';

const tokens = (suffix) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.MultiInput' && c.getId().endsWith(suffix) && c.getDomRef());

export default async (page, expect) => {
  await expect(page.locator('body'), 'the label').toContainText('MultiInput with pre-selected tokens');
  await waitForUi5(page, () => {
    const m = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.MultiInput' && c.getId().endsWith('multiInput1') && c.getDomRef());
    return !!m && m.getTokens().length === 6;
  }, 'multiInput1 did not render its six pre-set tokens');
  // the validator installed by MultiInputExt
  const m1 = page.locator('[id$="multiInput1-inner"]').first();
  await m1.fill('e2e token');
  await m1.press('Enter');
  await waitForUi5(page, () => {
    const m = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.MultiInput' && c.getId().endsWith('multiInput1') && c.getDomRef());
    return !!m && m.getTokens().length === 7 && m.getTokens().some((t) => t.getText() === 'e2e token');
  }, 'the MultiInputExt validator did not turn the typed text into a token on multiInput1');
  // the bound suggestions
  const m0 = page.locator('[id$="multiInput-inner"]').first();
  await m0.click();
  await m0.pressSequentially('Notebook', { delay: 60 });
  await expect(page.locator('.sapMInputBaseSuggestions, .sapMPopover, .sapMSuggestionsPopover, .sapMDialog'), 'the suggestion popup').toContainText('Notebook Basic 15');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await waitForUi5(page, () => {
    const m = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.MultiInput' && c.getId().endsWith('multiInput') && c.getDomRef());
    return !!m && m.getTokens().length === 1 && /^Notebook/.test(m.getTokens()[0].getText());
  }, 'picking a suggestion did not add it as a token on multiInput');
};
