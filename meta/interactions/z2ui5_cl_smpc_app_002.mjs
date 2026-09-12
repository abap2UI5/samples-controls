// Page: header (title + nav button + Share action), subHeader SearchField,
// content and a footer OverflowToolbar with four buttons — a static port, so
// the assertion is that every one of the five page areas really rendered
export default async (page, expect) => {
  await expect(page.locator('.sapMPageHeader'), 'the page title').toContainText('Title');
  await expect(page.getByRole('button', { name: 'Share', exact: true }).first(), 'the Share header action').toBeVisibleEnabled();
  await expect(page.locator('.sapMPageSubHeader .sapMSF').first(), 'the subHeader SearchField').toBeVisible();
  await expect(page.locator('.sapMPage'), 'the lorem ipsum content').toContainText('Lorem ipsum dolor st amet');
  for (const text of ['Accept', 'Reject', 'Edit', 'Delete']) {
    await expect(page.locator('.sapMPageFooter').getByRole('button', { name: text, exact: true }).first(), `the footer "${text}" button`).toBeVisibleEnabled();
  }
  // the nav button: showNavButton renders the back button in the header
  const nav = await page.locator('.sapMPageHeader .sapMBtn').count();
  if (nav < 2) throw new Error(`the header should carry the nav button and the Share action, got ${nav} button(s)`);
};
