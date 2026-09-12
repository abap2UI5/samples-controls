// FeedContent press -> client-composed MESSAGE_TOAST (control_global, no
// round trip): the first tile is clicked and the toast text asserted; the
// second carries the same wire plus a value
export default async (page, expect) => {
  const tile = page.locator('.sapMFC').first();
  await expect(tile, 'the first FeedContent').toBeVisibleEnabled();
  await expect(page.locator('.sapMFC'), 'the value of the second FeedContent').toContainText('999');
  await tile.click();
  await expect(page.locator('.sapMMessageToast').last(), 'the FeedContent press toast').toContainText('The feed content is pressed.');
};
