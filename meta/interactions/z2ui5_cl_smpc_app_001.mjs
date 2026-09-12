// ActionListItem: a static list with five action rows and no wire at all —
// the human check was "starts and renders like the original". What can be
// re-proved headless is exactly that: the list header and all five
// ActionListItems reach the DOM as .sapMALI rows with their texts.
export default async (page, expect) => {
  await expect(page.locator('.sapMList'), 'the Actions list header').toContainText('Actions');
  const rows = page.locator('.sapMALI');
  const n = await rows.count();
  if (n !== 5) throw new Error(`expected the five ActionListItems to render, got ${n}`);
  for (const text of ['Reject', 'Accept', 'Email', 'Forward', 'Delete']) {
    await expect(rows, `the "${text}" action row`).toContainText(text);
  }
};
