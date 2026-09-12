// Feed: the FeedInput post round-trips ${$parameters>/value} and the backend
// INSERTs a new entry at INDEX 1 with a server-composed timestamp; the
// FeedListItem senderPress round-trips ${$source>/sender} into a toast
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  const list = page.locator('.sapMList');
  await expect(list, 'the seeded feed').toContainText('Alexandrina Victoria');
  const before = await page.locator('.sapMFeedListItem').count();
  if (before < 1) throw new Error('no FeedListItem rendered from the seeded entries');
  await waitForIdle(page);
  // senderPress: the sender is a sap.m.Link inside the item
  await page.locator('.sapMFeedListItem a.sapMLnk').filter({ hasText: 'Alexandrina Victoria' }).first().click();
  await expect(page.locator('.sapMMessageToast').last(), 'the senderPress toast').toContainText('Clicked on Link: Alexandrina Victoria');
  await waitForIdle(page);
  // post: type and press the FeedInput's post button
  const ta = page.locator('.sapMFeedIn textarea').first();
  await expect(ta, 'the FeedInput TextArea').toBeVisibleEnabled();
  await ta.fill('e2e feed entry');
  const post = page.locator('.sapMFeedIn .sapMBtn').first();
  if (!(await post.count())) throw new Error('the FeedInput rendered no post button');
  // the post button keeps a 57x22 box unthemed; a dispatched click does NOT
  // reach its press (measured 2026-09-12), a real one does
  await post.click();
  await expect(list.locator('.sapMFeedListItem').first(), 'the posted entry inserted at the top').toContainText('e2e feed entry');
  await expect(list.locator('.sapMFeedListItem').first(), 'the posted entry\'s Reply info').toContainText('Reply');
  const after = await page.locator('.sapMFeedListItem').count();
  if (after !== before + 1) throw new Error(`the POST round trip should add one entry: ${before} -> ${after}`);
};
