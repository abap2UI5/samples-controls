// u:Currency over the NESTED transactionAmount/size + currency record inside
// each row: the deep relative paths have to resolve at runtime, which is what
// the human live check confirmed (app 196 covers the flat-array form)
export default async (page, expect) => {
  const table = page.locator('.sapMListTbl');
  await expect(table, 'the Flight row').toContainText('Flight');
  await expect(table, 'the EUR transaction amount').toContainText('560.67');
  await expect(table, 'the nested currency code').toContainText('USD');
  await expect(table, 'the five-decimal exchange rate').toContainText('0.85654');
  const n = await page.locator('.sapUiUfdCurrency').count();
  if (n < 4) throw new Error(`expected a u:Currency per row, got ${n}`);
};
