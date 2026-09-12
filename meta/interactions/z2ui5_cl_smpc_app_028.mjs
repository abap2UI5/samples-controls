// GenericTileAsKPITile: the injected tileLayout float rule and the tile press
// (a client-composed MESSAGE_TOAST on every tile) — the first tile is clicked
export default async (page, expect) => {
  const tile = page.locator('.sapMGT').first();
  await expect(tile, 'the first GenericTile').toBeVisibleEnabled();
  await expect(page.locator('.sapMGT'), 'the KPI tile header').toContainText('Country-Specific Profit Margin');
  const float = await page.evaluate(() => {
    const el = document.querySelector('.sapMGT.tileLayout');
    return el ? getComputedStyle(el).float : null;
  });
  if (float !== 'left') throw new Error(`the injected .tileLayout rule did not apply — float is ${float}`);
  await tile.click();
  await expect(page.locator('.sapMMessageToast').last(), 'the tile press toast').toContainText('The tile is pressed.');
};
