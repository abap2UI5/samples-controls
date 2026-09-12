// DisplayListItem: the List is element-bound to /T_SUPPLIERS/0 (the
// original's binding="{/SupplierCollection/0}"), so every value is a RELATIVE
// binding resolved through that context against the serialized model — the
// four name/value rows carrying the seeded supplier is the whole proof
export default async (page, expect) => {
  const list = page.locator('.sapMList');
  await expect(list, 'the Address list').toContainText('Address');
  await expect(list, 'the element-bound Name row').toContainText('Red Point Stores');
  await expect(list, 'the composite Street row').toContainText('Main St 1618');
  await expect(list, 'the composite City row').toContainText('31415 Maintown');
  await expect(list, 'the Country row').toContainText('Germany');
  const n = await page.locator('.sapMDLI').count();
  if (n !== 4) throw new Error(`expected four DisplayListItems, got ${n}`);
};
