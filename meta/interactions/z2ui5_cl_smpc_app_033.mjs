// LinkEmphasized: the emphasized Link in the first column and the Currency
// composite binding over PRICE TYPE p — the human visual pass was about the
// formatted price per currency, so that is what is read off the rendered rows
export default async (page, expect) => {
  const table = page.locator('.sapMListTbl');
  await expect(table, 'the products table').toContainText('HT-1000');
  const emph = page.locator('a.sapMLnk.sapMLnkEmphasized');
  if (!(await emph.count())) throw new Error('no emphasized Link rendered in the product column');
  // 956.00 EUR is HT-1000's price: the Currency type over the packed PRICE
  await expect(table, 'the formatted Currency price').toContainText('956.00');
  const rows = await page.locator('.sapMListTbl .sapMListTblRow').count();
  if (rows < 100) throw new Error(`expected the sorted product rows to render, got ${rows}`);
};
