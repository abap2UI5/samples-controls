// PDFViewerPopup: an Image press -> SHOW_PDF round trip -> the bound
// pdf_source is set AND a control_by_id `open` follow-up opens the popup-mode
// PDFViewer (a Dialog titled "My Custom Title"). The source is read off the
// control (the browser has no PDF plugin to render it — the Dialog then
// shows "The PDF file could not be loaded", which is UI5's own text and still
// proves the open). The image comes from the demokit host, which the harness
// does not serve, but the <img> keeps a 134x18 box and takes a real click
// (a dispatched click does NOT reach the Image press — measured 2026-09-12)
import { waitForUi5, ui5All, waitForIdle } from '../../scripts/lib-e2e.mjs';

export default async (page, expect) => {
  await expect(page.locator('.sapMCrsl').first(), 'the Carousel').toBeVisible();
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.PDFViewer' && c.getSource() === ''),
    'the PDFViewer dependent did not boot with an empty bound source');
  await waitForIdle(page);
  const img = page.locator('[id$="image1"]').first();
  if (!(await img.count())) throw new Error('image1 did not render');
  await img.click();
  await waitForUi5(page, () => ui5All().some((c) => c.getMetadata().getName() === 'sap.m.PDFViewer' && /sample1\.pdf$/.test(c.getSource())),
    'the SHOW_PDF round trip never set the bound pdf_source to sample1.pdf');
  await expect(page.locator('.sapMDialog'), 'the PDFViewer popup Dialog').toContainText('My Custom Title');
};
