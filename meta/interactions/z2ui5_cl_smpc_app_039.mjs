// MultiComboBoxGrouping: the items binding carries a sorter with group:true
// over SUPPLIERNAME, so the opened picker must show GroupHeaderListItems
// named after the suppliers. The picker is opened with F4 on the focused input
// (the arrow icon has no box unthemed). A JSONModel's default sizeLimit is
// 100, so the sorted list stops inside the U suppliers — 11 groups, Alpha
// Printers first — exactly as the original renders it
export default async (page, expect) => {
  const input = page.locator('.sapMMultiComboBox input').first();
  await expect(input, 'the MultiComboBox input').toBeVisibleEnabled();
  await input.focus();
  await page.keyboard.press('F4');
  const groups = page.locator('.sapMGHLI');
  await expect(groups, 'the first supplier group header in the picker').toContainText('Alpha Printers');
  await expect(groups, 'a later supplier group header').toContainText('Ultrasonic United');
  const n = await groups.count();
  if (n < 10) throw new Error(`expected the supplier group headers from the group sorter, got ${n}`);
  const texts = await groups.allInnerTexts();
  const sorted = texts.every((t, i) => i === 0 || texts[i - 1].localeCompare(t) <= 0);
  if (!sorted) throw new Error(`the group headers are not in SUPPLIERNAME order: ${texts.join(' | ')}`);
  await expect(page.locator('.sapMPopover .sapMLIB'), 'a grouped product item under Alpha Printers').toContainText('Laser Professional Eco');
};
