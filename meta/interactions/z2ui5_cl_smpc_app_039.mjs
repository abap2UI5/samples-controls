// MultiComboBoxGrouping: the items binding carries a sorter with group:true
// over SUPPLIERNAME, so the opened picker must show GroupHeaderListItems
// named after the suppliers. The picker is opened with F4 on the focused input
// (the arrow icon has no box unthemed)
export default async (page, expect) => {
  const input = page.locator('.sapMMultiComboBox input').first();
  await expect(input, 'the MultiComboBox input').toBeVisibleEnabled();
  await input.focus();
  await page.keyboard.press('F4');
  const groups = page.locator('.sapMGHLI');
  await expect(groups, 'a supplier group header in the picker').toContainText('Very Best Screens');
  const n = await groups.count();
  if (n < 5) throw new Error(`expected the supplier group headers from the group sorter, got ${n}`);
  await expect(page.locator('.sapMSelectList, .sapMList'), 'a grouped product item').toContainText('Notebook Basic 15');
};
