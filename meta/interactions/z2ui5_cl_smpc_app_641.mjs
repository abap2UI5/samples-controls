import { waitForUi5, ui5All } from '../../scripts/lib-e2e.mjs';
export default async (page, expect) => {
  page.on('pageerror', (e) => console.log('PAGEERR', String(e.stack).split('\n').slice(0, 14).join('\n')));
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange'), 'ddr');
  await page.evaluate(() => {
    const reg = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const ddr = reg.find((c) => c.getMetadata().getName() === 'sap.m.DynamicDateRange');
    const b = reg.find((c) => c.getMetadata().getName() === 'sap.m.Button' && c.getText() === 'Open Dynamic Date Range');
    ddr.openBy(b.getDomRef());
  });
  await page.waitForTimeout(2000);
};
