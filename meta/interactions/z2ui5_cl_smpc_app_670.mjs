// HeroBannerIntegrationCard: two sap.ui.integration Cards in the HeroBanner's
// startContent and endContent slots load their manifests by absolute URL
// from sdk.openui5.org and render their List content.
//
// HARNESS: e2e-smoke routes every sdk.openui5.org request to the local UI5
// package sources and answers 404 for anything it cannot resolve there - and
// /test-resources/... is never resolvable (resolveLocal( ) only maps
// /resources/), so on the default boot both Cards get a 404 manifest and
// render empty (header null, "CardCard"; measured 2026-10-20). The claim
// under test IS the cross-origin fetch from the live demo kit, so this module
// lets exactly those two manifest URLs through to the network (a route
// registered later wins over the harness' catch-all) and reloads the app.
// Serving the archived ui5/ copies instead would prove the Card wiring but
// not the fetch. Needs network access to sdk.openui5.org, like a themed boot.
import { waitForUi5 } from '../../scripts/lib-e2e.mjs';

const MANIFEST = /\/test-resources\/sap\/f\/demokit\/sample\/HeroBannerIntegrationCard\/(start|end)ContentManifest\.json$/;

export default async (page, expect) => {
  const fetched = [];
  page.on('response', (r) => {
    const u = new URL(r.url());
    if (u.hostname === 'sdk.openui5.org' && MANIFEST.test(u.pathname)) fetched.push(`${r.status()} ${u.pathname.split('/').pop()}`);
  });
  await page.route((u) => u.hostname === 'sdk.openui5.org' && MANIFEST.test(u.pathname), (route) => route.continue());
  await page.reload({ waitUntil: 'domcontentloaded' });

  await waitForUi5(page, () => {
    const live = (c) => !c.bIsDestroyed && c.getDomRef() && document.body.contains(c.getDomRef());
    const banner = ui5All().find((c) => c.getMetadata().getName() === 'sap.f.HeroBanner' && live(c));
    if (!banner) return false;
    const title = (card) => {
      const h = card && !card.bIsDestroyed && card.getCardHeader && card.getCardHeader();
      return h ? h.getTitle() : null;
    };
    const start = banner.getStartContent()[0];
    const end = banner.getEndContent()[0];
    return title(start) === 'Pending Approvals' && title(end) === 'Upcoming Events'
      && /Expense Report Q2/.test(start.getDomRef()?.innerText || '')
      && /Team Meeting/.test(end.getDomRef()?.innerText || '');
  }, 'the HeroBanner Cards did not render their manifests\' headers (Pending Approvals in startContent, Upcoming Events in endContent) and List content');

  await expect(fetched.sort(), 'both manifests were fetched cross-origin from sdk.openui5.org with HTTP 200')
    .toEqual(['200 endContentManifest.json', '200 startContentManifest.json']);
  await expect(page.locator('body'), 'the start card header on screen').toContainText('Pending Approvals');
  await expect(page.locator('body'), 'the end card header on screen').toContainText('Upcoming Events');
};
