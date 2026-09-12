// TokenizerBasic: ADD appends a Token from the two-way bound Input (committed
// with Enter — fill() alone leaves the model on the old value) and toasts;
// tokenDelete carries the token key through `$event.getParameter('tokens')[0].getKey()`
// and DELETE removes it by key. The token's delete icon has no box unthemed,
// so the token is focused and Delete pressed — the Tokenizer's own onsapdelete
import { waitForUi5, ui5All, waitForIdle } from '../../scripts/lib-e2e.mjs';

const tokensOf = (idSuffix) => ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Tokenizer' && c.getId().endsWith(idSuffix) && !c.bIsDestroyed && c.getDomRef());

export default async (page, expect) => {
  await expect(page.locator('body'), 'the disabled tokenizer label').toContainText('Disabled tokenizer');
  const seeded = await page.evaluate(`(() => { const ui5All = () => Object.values(sap.ui.require("sap/ui/core/Element").registry.all());
    const t = (${tokensOf.toString()})('tokenizer'); return t ? t.getTokens().length : -1; })()`);
  if (seeded < 1) throw new Error(`the bound tokens never reached the Tokenizer (${seeded})`);
  await waitForIdle(page);
  const input = page.locator('[id$="tokenInput-inner"]').first();
  await expect(input, 'the token text Input').toBeVisibleEnabled();
  await input.fill('e2e token');
  await input.press('Enter');
  await page.waitForTimeout(500);
  await waitForIdle(page);
  await page.getByRole('button', { name: 'Add Token', exact: true }).first().click();
  await expect(page.locator('.sapMMessageToast').last(), 'the ADD toast').toContainText('Token added: e2e token');
  await waitForUi5(page, (n) => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Tokenizer' && c.getId().endsWith('tokenizer') && !c.bIsDestroyed && c.getDomRef());
    return !!t && t.getTokens().length === n + 1 && t.getTokens().some((k) => k.getText() === 'e2e token');
  }, 'the ADD round trip never appended the token to the bound aggregation', seeded);
  // the input is cleared server-side
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.Input' && c.getId().endsWith('tokenInput') && c.getValue() === ''),
    'the ADD round trip did not clear the bound input value');
  await waitForIdle(page);
  // delete the new token: focus it and press Delete
  const token = page.locator('[id$="tokenizer"] .sapMToken').filter({ hasText: 'e2e token' }).first();
  await expect(token, 'the added token').toBeVisible();
  await token.click();
  await page.keyboard.press('Delete');
  await expect(page.locator('.sapMMessageToast').last(), 'the DELETE toast').toContainText('Token deleted: e2e token');
  await waitForUi5(page, (n) => {
    const t = ui5All().find((c) => c.getMetadata().getName() === 'sap.m.Tokenizer' && c.getId().endsWith('tokenizer') && !c.bIsDestroyed && c.getDomRef());
    return !!t && t.getTokens().length === n && !t.getTokens().some((k) => k.getText() === 'e2e token');
  }, 'the DELETE round trip never removed the token by key', seeded);
};
