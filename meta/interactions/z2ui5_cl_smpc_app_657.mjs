// app 657 — sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableFilePreview
//
// The view is app 659's plus a declared upload:FilePreviewDialog
// (showCarouselArrows, maxFileSizeforPreview 50) that the plugin's
// previewDialog association names. So the LIVE_TEST legs are 659's - the
// plugin calls by id with a live Context (openFilePreview / renameItem /
// download), selectionChange driving the toolbar flags, the itemRenamed wire,
// the vetoed beforeUploadStarts, search and the Remove MessageBox - and the
// preview leg additionally asserts that the Link's openFilePreview ran through
// THAT dialog (its id, its two settings, the pressed row as preview item)
// rather than a default one the plugin would create without the association.
import { responsiveTableLegs } from './z2ui5_cl_smpc_app_659.mjs';

export default async (page, expect) => {
  await responsiveTableLegs(page, expect, { previewDialog: 'FilePreviewDialog' });
  expect(await page.evaluate(() => Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .filter((c) => c.isA('sap.m.upload.FilePreviewDialog')).length), 'FilePreviewDialog instances (no default one beside the declared)').toBe(1);
};
