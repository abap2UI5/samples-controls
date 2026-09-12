// ObjectHeader element-bound to the one-record structure s_product: the
// title, the Currency composite number, and the three attribute texts all
// resolve RELATIVELY through that binding context (the human note's point)
export default async (page, expect) => {
  const oh = page.locator('.sapMOH');
  await expect(oh, 'the bound title').toContainText('Notebook Basic 15');
  await expect(oh, 'the Currency composite number').toContainText('956.00');
  await expect(oh, 'the number unit').toContainText('EUR');
  await expect(oh, 'the weight attribute').toContainText('4.2 KG');
  await expect(oh, 'the dimensions attribute').toContainText('30 x 18 x 3 cm');
  await expect(oh, 'the description attribute').toContainText('2,80 GHz quad core');
  await expect(oh, 'the Error status').toContainText('Some Damaged');
  await expect(oh, 'the Success status').toContainText('In Stock');
};
