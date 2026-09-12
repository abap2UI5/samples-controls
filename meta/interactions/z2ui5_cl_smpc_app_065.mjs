// MessagePopoverMessageHandling: Save -> SAVE round trip authors four
// messages into t_messages, the z2ui5.cc.MessageManager reconciles them into
// the message> model (read FIRST, the app-529 lesson: an unfed model renders
// no button at all), the footer button shows the count and the openBy
// follow-up opens the MessagePopover with the grouped items
import { waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('body'), 'the personal form').toContainText('Personal website');
  await waitForIdle(page);
  const save = page.getByRole('button', { name: 'Save', exact: true }).first();
  await expect(save, 'the Save button').toBeVisibleEnabled();
  await save.click();
  await page.waitForFunction(() => {
    const Messaging = sap.ui.require('sap/ui/core/Messaging');
    const model = Messaging ? Messaging.getMessageModel() : sap.ui.getCore().getMessageManager().getMessageModel();
    const data = model && model.getData();
    return Array.isArray(data) && data.length >= 4;
  }, undefined, { timeout: 15000 }).catch(() => {
    throw new Error('the message> model never carried the four SAVE messages — the z2ui5.cc.MessageManager bridge did not feed it');
  });
  const messages = await page.evaluate(() => {
    const Messaging = sap.ui.require('sap/ui/core/Messaging');
    const model = Messaging ? Messaging.getMessageModel() : sap.ui.getCore().getMessageManager().getMessageModel();
    return model.getData().map((m) => `${m.getType()}:${m.getMessage()}`);
  });
  for (const want of ['Error:A mandatory field is required', 'Error:Enter a number with no decimal places', 'Error:Enter a valid value', 'Warning:The value should not exceed 40']) {
    if (!messages.includes(want)) throw new Error(`the message> model carries ${JSON.stringify(messages)}, missing "${want}"`);
  }
  await expect(page.locator('[id$="messagePopoverBtn"]'), 'the footer button showing the message count').toContainText('4');
  const pop = page.locator('.sapMMsgPopover, .sapMPopover');
  await expect(pop, 'the MessagePopover opened by the openBy follow-up').toContainText('A mandatory field is required');
  await expect(pop, 'a group header computed in the backend').toContainText('Personal, Contact');
};
