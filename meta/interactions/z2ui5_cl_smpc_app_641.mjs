import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';
export default async (page, expect) => {
  page.on('pageerror', (e) => console.log('PAGEERR', String(e.message)));
  page.on('request', (r) => { if (r.method() === 'POST') console.log('POST', r.postData()?.match(/T_EVENT_ARG.*/)?.[0]); });
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange'), 'ddr');
  console.log('THEMED?', await page.evaluate(() => [...document.styleSheets].map((s) => s.href).filter(Boolean).join(',')));
  await page.getByRole('button', { name: 'Open Dynamic Date Range', exact: true }).first().click();
  await page.waitForTimeout(1500);
  console.log('OPEN', await page.evaluate(() => {
    const ddr = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange');
    return [ddr._oPopup && ddr._oPopup.isOpen(), document.querySelector('.sapMPopover')?.innerText.slice(0, 300)];
  }));
};
