// GenericTag → Card popover fragment (the 170/238 class, 238's own wire)
import { waitForPopup } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const tag = page.locator('.sapMGenericTag').first();
  await expect(tag, 'the GenericTag').toBeVisibleEnabled();
  await tag.click();
  // this popover's box measures empty headless (content overflows it), so
  // it is found as an OPEN popover showing the card's text, not by playwright
  // visibility - and not as "the first .sapMPopover" either
  await waitForPopup(page, 'Sales Revenue');
};
