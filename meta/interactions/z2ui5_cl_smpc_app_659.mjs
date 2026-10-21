// app 659 — sap.m.sample.UploadSetwithTablePlugin.ResponsiveTableSimple
//
// The LIVE_TEST asks for what only a running app shows: (a) the plugin calls
// by id (uploadSetPlugin) through control_by_id's unlisted-method path -
// openFilePreview with the Link's binding Context, renameItem and download
// with the table's first selected Context - each handing a live Context
// object through untouched; (b) selectionChange transporting the selected
// contexts' paths (the toolbar flags follow) and the itemRenamed wire reading
// the renamed item's binding path; (c) the vetoed beforeUploadStarts with the
// file's size. Plus the roundtrip-free search (binding_call filter) and the
// Remove MessageBox. Each leg asserts the EFFECT: a bound enabled flag, the
// filtered rows, an opened plugin dialog, a model row that changed.
import { waitForUi5, waitForIdle, waitForPopup, revealInOverflow, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

// the live table, never the outgoing one a round-trip is tearing down
const TABLE = `ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed
  && c.getDomRef() && document.body.contains(c.getDomRef()))`;
const names = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
  return t ? t.getItems().map((i) => i.getBindingContext().getProperty('FILENAME')) : null; })()`);
const enabled = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC}
  const b = (s) => { const c = ui5All().find((x) => x.getId().endsWith('--' + s) && !x.bIsDestroyed); return c ? c.getEnabled() : null; };
  return { download: b('downloadSelectedButton'), remove: b('removeDocumentButton'), rename: b('renameButton'), edit: b('editUrlButton') }; })()`);

async function toggleRow(page, i) {
  const id = await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
    const r = t && t.getItems()[${i}]; return r ? r.getMultiSelectControl(true).getId() : null; })()`);
  if (!id) throw new Error(`row ${i} has no multi-select checkbox`);
  await page.locator(`[id="${id}"]`).click();
}

async function pressToolbar(page, id) {
  const btn = page.locator(`[id$="--${id}"]`).first();
  await revealInOverflow(page, btn);
  await btn.click();
}

// Shared with 657 (ResponsiveTableFilePreview) and 658 (ProgressIndicator),
// whose views are this one plus a declared FilePreviewDialog, resp. an
// uploadCompleted wire instead of the vetoed beforeUploadStarts:
//   previewDialog - the id suffix of the view's own FilePreviewDialog, which
//                   the plugin must reuse instead of creating a default one
//   upload        - async (page, expect) => {...} replacing the upload leg
export async function responsiveTableLegs(page, expect, { previewDialog = null, upload = null } = {}) {
  // a POST to the sample's /uploadFiles would mean the veto did not take
  const uploads = [];
  page.on('request', (r) => { if (/\/uploadFiles/.test(r.url())) uploads.push(r.url()); });
  await waitForIdle(page);
  expect(await names(page), 'the nine documents.json rows').toEqual([
    'Invoice summary.doc', 'Business Plan Topics.xls', 'Instructions.pdf', 'Document.txt', 'Test Image.png',
    'Test Attachment.gif', 'Test Video.mp4', 'Sample Zip File.zip', 'Transmission.vds']);

  // ---------------------------------------------------------------- search
  // liveChange -> binding_call filter FILENAME Contains ${$source>/value}
  const search = page.locator('.sapMSF input[type="search"]').first();
  await search.click();
  await search.pressSequentially('Test');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    const n = t && t.getItems().map((i) => i.getBindingContext().getProperty('FILENAME'));
    return n && n.length === 3 && n.every((x) => x.includes('Test'));
  }, 'typing "Test" into the SearchField never filtered the table to its three Test rows');
  await search.fill('');
  await search.press('Enter');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    return t && t.getItems().length === 9;
  }, 'clearing the SearchField never brought the nine rows back');
  await waitForIdle(page);

  // ------------------------------------------------------------- selection
  expect(await enabled(page), 'the toolbar flags before any selection')
    .toEqual({ download: false, remove: false, rename: false, edit: false });
  await toggleRow(page, 0);
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--renameButton') && !c.bIsDestroyed && c.getEnabled()),
    'selecting one row never enabled Rename - the selectionChange wire did not deliver its context path');
  expect(await enabled(page), 'one row selected').toEqual({ download: true, remove: true, rename: true, edit: true });
  await waitForIdle(page);
  await toggleRow(page, 1);
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--renameButton') && !c.bIsDestroyed && !c.getEnabled()),
    'a second selected row never disabled Rename');
  expect(await enabled(page), 'two rows selected').toEqual({ download: true, remove: false, rename: false, edit: false });
  await waitForIdle(page);
  await toggleRow(page, 1);
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--renameButton') && !c.bIsDestroyed && c.getEnabled()),
    'deselecting the second row never re-enabled Rename');
  await waitForIdle(page);

  // spy on the plugin: what control_by_id hands it must be the live Context
  await page.evaluate(`(() => { ${UI5_ALL_SRC}
    const p = ui5All().find((c) => c.getId().endsWith('--uploadSetPlugin'));
    window.__usp = { calls: [], dl: [] };
    for (const m of ['download', 'renameItem', 'openFilePreview']) {
      const orig = p[m];
      p[m] = function (...a) {
        window.__usp.calls.push({ m, ctx: !!(a[0] && a[0].isA && a[0].isA('sap.ui.model.Context')),
          path: a[0] && a[0].getPath ? a[0].getPath() : String(a[0]), rest: a.slice(1) });
        return orig.apply(this, a);
      };
    }
    const dl = p._initiateFileDownload;
    p._initiateFileDownload = function (item, ask) { window.__usp.dl.push({ name: item.getFileName(), url: item.getUrl(), ask });
      return dl.apply(this, arguments); };
  })()`);
  const calls = () => page.evaluate(() => window.__usp);

  // -------------------------------------------------------------- download
  await pressToolbar(page, 'downloadSelectedButton');
  await page.waitForFunction(() => window.__usp.dl.length > 0, undefined, { timeout: 10000 }).catch(() => {});
  const d = await calls();
  expect(d.calls.find((c) => c.m === 'download'), 'download( ) reached the plugin with the first selected Context and true')
    .toEqual({ m: 'download', ctx: true, path: '/T_ITEMS/0', rest: [true] });
  expect(d.dl[0] && d.dl[0].name, 'the plugin resolved the Context to its upload item and started the download')
    .toBe('Invoice summary.doc');

  // ---------------------------------------------------------------- rename
  await pressToolbar(page, 'renameButton');
  const dlg = await waitForPopup(page, 'Rename Document');
  expect((await calls()).calls.find((c) => c.m === 'renameItem'), 'renameItem( ) got the selected row\'s Context')
    .toEqual({ m: 'renameItem', ctx: true, path: '/T_ITEMS/0', rest: [] });
  const input = dlg.locator('input').first();
  await input.fill('Renamed summary');
  await dlg.getByRole('button', { name: 'Apply' }).click();
  await expect(page.locator('body'), 'the itemRenamed toast').toContainText('Document Renamed.');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    return t && t.getItems()[0].getBindingContext().getProperty('FILENAME') === 'Renamed summary.doc';
  }, 'the itemRenamed wire never wrote "Renamed summary.doc" into row /T_ITEMS/0 of the backend model');
  await waitForIdle(page);

  // --------------------------------------------------------------- preview
  await page.locator('.sapMLnk', { hasText: 'Business Plan Topics.xls' }).first().click();
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.upload.FilePreviewDialog') && c._previewItem
    && c._previewItem.getFileName() === 'Business Plan Topics.xls'),
  'pressing the file-name Link never opened the plugin\'s FilePreviewDialog on that row');
  if (previewDialog) {
    const used = await page.evaluate(`(() => { ${UI5_ALL_SRC}
      const p = ui5All().find((c) => c.getId().endsWith('--uploadSetPlugin'));
      const d = sap.ui.require('sap/ui/core/Element').getElementById(p.getPreviewDialog());
      return d ? { id: d.getId().split('--').pop(), arrows: d.getShowCarouselArrows(), max: d.getMaxFileSizeforPreview(),
        item: d._previewItem && d._previewItem.getFileName() } : null; })()`);
    expect(used, 'the preview ran through the view\'s declared FilePreviewDialog')
      .toEqual({ id: previewDialog, arrows: true, max: 50, item: 'Business Plan Topics.xls' });
  }
  expect((await calls()).calls.find((c) => c.m === 'openFilePreview'), 'openFilePreview( ) got the Link\'s own Context')
    .toEqual({ m: 'openFilePreview', ctx: true, path: '/T_ITEMS/1', rest: [] });
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.Dialog') && c.isOpen() && c.getDomRef()
    && /Business Plan Topics/.test(c.getDomRef().textContent)), 'the preview dialog never opened on screen');
  await page.keyboard.press('Escape');
  await waitForUi5(page, () => !ui5All().some((c) => c.isA('sap.m.Dialog') && c.isOpen()), 'the preview dialog never closed');
  await waitForIdle(page);

  // ---------------------------------------------------------------- remove
  // the row's decline button -> REMOVE_ROW with its path -> MessageBox.warning
  const declineId = await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
    return t.getItems()[0].getCells()[6].getId(); })()`);
  await page.locator(`[id="${declineId}"]`).click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Renamed summary.doc');
  await box.getByRole('button', { name: 'Remove' }).click();
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    return t && t.getItems().length === 8 && t.getItems()[0].getBindingContext().getProperty('FILENAME') === 'Business Plan Topics.xls';
  }, 'confirming Remove never dropped the renamed row');
  await waitForUi5(page, () => ui5All().some((c) => c.getId().endsWith('--downloadSelectedButton') && !c.bIsDestroyed && !c.getEnabled()),
    'the removal never reset the toolbar flags');
  expect(await enabled(page), 'after removal').toEqual({ download: false, remove: false, rename: false, edit: false });
  await waitForIdle(page);

  // ---------------------------------------------------------------- upload
  if (upload) { await upload(page, expect); return; }
  // a real file pick on the plugin's FileUploader: beforeUploadStarts is
  // vetoed (no XHR) and the backend unshifts the mock server's row
  await page.locator('input[type="file"][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'probe.txt', mimeType: 'text/plain', buffer: Buffer.alloc(1536, 'a') });
  await expect(page.locator('body'), 'the upload toast').toContainText('Document Added');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    if (!t || t.getItems().length !== 9) return false;
    const r = t.getItems()[0].getBindingContext().getObject();
    return r.FILENAME === 'probe.txt' && r.MEDIATYPE === 'text/plain' && r.FILESIZE === 1536
      && r.FILESIZE_UNITS === '1.50 KB' && r.UPLOADSTATE === 'Complete';
  }, 'the picked file never became the new first row (probe.txt, text/plain, 1536 bytes = 1.50 KB, Complete)');
  await page.waitForTimeout(500);
  expect(uploads, 'requests to /uploadFiles (the veto must stop the XHR)').toEqual([]);
};

export default (page, expect) => responsiveTableLegs(page, expect);
