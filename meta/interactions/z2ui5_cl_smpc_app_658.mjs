// app 658 — sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableProgressIndicator
//
// The view is app 659's with one difference the LIVE_TEST names: no vetoed
// beforeUploadStarts - the upload really goes out as a POST to /uploadFiles,
// and the uploadCompleted wire transports ${$parameters>/item}.getFileName( ),
// getUrl( ), getFileSize( ) and ${$parameters>/status}; the backend adds the
// row (id<n>, no media type) and toasts 'Document Added' on a 201 only. The
// sample's mock server is switched off, so the harness plays it: the upload
// is answered 201 by a page route, and the row plus the toast must follow.
// Every other leg - the plugin calls by id with a live Context, selection
// flags, rename, preview, search, Remove MessageBox - is 659's.
import { responsiveTableLegs } from './z2ui5_cl_smpc_app_659.mjs';
import { waitForUi5, waitForIdle } from '../../scripts/lib-e2e.mjs';

const FILE = 'input[type="file"][id$="uploadSetPlugin-uploader-fu"]';

async function upload(page, expect) {
  let posted = 0;
  await page.route('**/uploadFiles', (route) => { posted += 1; return route.fulfill({ status: 201, body: '' }); });
  await page.locator(FILE).setInputFiles({ name: 'probe.txt', mimeType: 'text/plain', buffer: Buffer.alloc(1536, 'a') });
  await expect(page.locator('body'), 'the 201 upload toast').toContainText('Document Added');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    if (!t || t.getItems().length !== 9) return false;
    const r = t.getItems()[0].getBindingContext().getObject();
    return r.FILENAME === 'probe.txt' && r.ID === 'id1' && r.FILESIZE === 1536 && r.FILESIZE_UNITS === '1.50 KB'
      && r.UPLOADSTATE === 'Complete' && !r.MEDIATYPE;
  }, 'the completed upload never became the new first row (probe.txt, id1, 1536 bytes = 1.50 KB, Complete, no media type)');
  expect(posted, 'POSTs to /uploadFiles (the upload must really go out)').toBe(1);
  await page.unroute('**/uploadFiles');
  await waitForIdle(page);
}

export default (page, expect) => responsiveTableLegs(page, expect, { upload });
