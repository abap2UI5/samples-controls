// GenericTag: a static preview grid — KPI tags with an ObjectNumber, a
// valueState Error tag, the situation tags and the ariaLabelledBy one
export default async (page, expect) => {
  const tags = page.locator('.sapMGenericTag');
  const n = await tags.count();
  if (n < 10) throw new Error(`expected the sample's GenericTags to render, got ${n}`);
  await expect(tags, 'a KPI tag with its ObjectNumber').toContainText('3.5M');
  await expect(tags, 'the percent KPI tag').toContainText('96');
  await expect(tags, 'a situation tag').toContainText('Shortage Expected');
  await expect(page.locator('body'), 'the label heading').toContainText('Generic Tag with label');
  const err = await page.locator('.sapMGenericTagErrorIcon, .sapMGenericTag.sapMGenericTagError').count();
  if (!err) throw new Error('no GenericTag rendered with the Error valueState icon');
};
