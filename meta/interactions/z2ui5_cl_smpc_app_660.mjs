// app 660 — sap.m.sample.UploadSetwithTablePlugin.TreeTableSimple
//
// The LIVE_TEST asks for (a) the plugin calls by id (uploadSetPlugin) through
// control_by_id's unlisted-method path - openFilePreview with the template
// Link's binding Context, renameItem and download with
// getContextByIndex(getSelectedIndices()[0]) - each handing a live Context
// through untouched; (b) rowSelectionChange transporting the rows binding's
// selected context paths (nested ones like /T_ITEMS/0/ITEMS/0) and the
// itemRenamed wire reading the renamed item's binding path; (c) the vetoed
// beforeUploadStarts with the file's size. The legs below drive each through
// a real gesture and assert its effect: the bound toolbar flags (files vs a
// folder), the Context the plugin received and what it resolved it to, the
// rename written into a NESTED node, the preview dialog on the pressed row,
// the Remove MessageBox dropping a row, and the picked file's new row.
import { waitForUi5, waitForIdle, waitForPopup, revealInOverflow, dispatchMouse, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

const TABLE = `ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed
  && c.getDomRef() && document.body.contains(c.getDomRef()))`;
// the shown rows' file names, top to bottom
const shown = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
  return t.getRows().map((r) => r.getBindingContext() && r.getBindingContext().getProperty('FILENAME')).filter(Boolean); })()`);
const model = (page, path) => page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
  return t.getModel().getProperty(${JSON.stringify(path)}); })()`);
const enabled = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC}
  const b = (s) => { const c = ui5All().find((x) => x.getId().endsWith('--' + s) && !x.bIsDestroyed); return c ? c.getEnabled() : null; };
  return { download: b('downloadSelectedButton'), single: b('renameButton') }; })()`);

// the row selector of the row SHOWING `name`: it sits under the data cells,
// so only a dispatched mouse sequence reaches it (e2e-debugging guide)
async function toggleRow(page, name) {
  const i = (await shown(page)).indexOf(name);
  if (i < 0) throw new Error(`no row shows "${name}"`);
  await dispatchMouse(page.locator(`[id$="--table-uploadSet-rowsel${i}"]`).first());
}
async function flagsBecome(page, want, msg) {
  await waitForUi5(page, (w) => {
    const b = (s) => { const c = ui5All().find((x) => x.getId().endsWith('--' + s) && !x.bIsDestroyed); return c && c.getEnabled(); };
    return b('downloadSelectedButton') === w.download && b('renameButton') === w.single;
  }, msg, want);
  await waitForIdle(page);
}
async function pressToolbar(page, id) {
  const btn = page.locator(`[id$="--${id}"]`).first();
  await revealInOverflow(page, btn);
  await btn.click();
}

export default async (page, expect) => {
  const uploads = [];
  page.on('request', (r) => { if (/\/uploadFiles/.test(r.url())) uploads.push(r.url()); });
  await waitForIdle(page);
  expect(await shown(page), 'the five top-level nodes').toEqual(
    ['Documents', 'Test Video.mp4', 'Sample Zip File.zip', 'Attachments', 'Transmission.vds']);

  // expand Documents: its file and its Invoices folder come in under it
  await dispatchMouse(page.locator('[id$="--table-uploadSet-rows-row0-treeicon"]').first());
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    return t && t.getRows()[1].getBindingContext() && t.getRows()[1].getBindingContext().getPath() === '/T_ITEMS/0/ITEMS/0';
  }, 'expanding Documents never showed its nested Document.txt');
  expect(await shown(page), 'Documents expanded').toEqual(
    ['Documents', 'Document.txt', 'Invoices', 'Test Video.mp4', 'Sample Zip File.zip', 'Attachments', 'Transmission.vds']);

  // ------------------------------------------------------------- selection
  // the nested file alone: Download and the single-file buttons
  expect(await enabled(page), 'flags before any selection').toEqual({ download: false, single: false });
  await toggleRow(page, 'Document.txt');
  await flagsBecome(page, { download: true, single: true },
    'selecting the nested Document.txt never enabled Download and Rename - rowSelectionChange did not deliver /T_ITEMS/0/ITEMS/0 as a file');
  // plus a folder: both off, as onSelectionChange decides
  await toggleRow(page, 'Invoices');
  await flagsBecome(page, { download: false, single: false }, 'selecting the Invoices folder as well never disabled the buttons');
  await toggleRow(page, 'Invoices');
  await flagsBecome(page, { download: true, single: true }, 'deselecting the folder never re-enabled the buttons');

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
    p._initiateFileDownload = function (item, ask) { window.__usp.dl.push({ name: item.getFileName(), ask });
      return dl.apply(this, arguments); };
  })()`);
  const calls = () => page.evaluate(() => window.__usp);

  // -------------------------------------------------------------- download
  await pressToolbar(page, 'downloadSelectedButton');
  await page.waitForFunction(() => window.__usp.dl.length > 0, undefined, { timeout: 10000 }).catch(() => {});
  const d = await calls();
  expect(d.calls.find((c) => c.m === 'download'), 'download( ) got the selected nested row\'s Context and true')
    .toEqual({ m: 'download', ctx: true, path: '/T_ITEMS/0/ITEMS/0', rest: [true] });
  expect(d.dl[0] && d.dl[0].name, 'the plugin resolved it to its upload item and started the download').toBe('Document.txt');

  // ---------------------------------------------------------------- rename
  await pressToolbar(page, 'renameButton');
  const dlg = await waitForPopup(page, 'Rename Document');
  expect((await calls()).calls.find((c) => c.m === 'renameItem'), 'renameItem( ) got the selected row\'s Context')
    .toEqual({ m: 'renameItem', ctx: true, path: '/T_ITEMS/0/ITEMS/0', rest: [] });
  await dlg.locator('input').first().fill('Notes');
  await dlg.getByRole('button', { name: 'Apply' }).click();
  await expect(page.locator('body'), 'the itemRenamed toast').toContainText('Document Renamed.');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    return t && t.getModel().getProperty('/T_ITEMS/0/ITEMS/0/FILENAME') === 'Notes.txt';
  }, 'the itemRenamed wire never wrote "Notes.txt" into the nested node /T_ITEMS/0/ITEMS/0');
  await waitForIdle(page);

  // --------------------------------------------------------------- preview
  await page.locator('.sapMLnk', { hasText: 'Test Video.mp4' }).first().click();
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.upload.FilePreviewDialog') && c._previewItem
    && c._previewItem.getFileName() === 'Test Video.mp4'),
  'pressing the file-name Link never opened the plugin\'s FilePreviewDialog on that row');
  expect((await calls()).calls.find((c) => c.m === 'openFilePreview'), 'openFilePreview( ) got the template Link\'s own Context')
    .toEqual({ m: 'openFilePreview', ctx: true, path: '/T_ITEMS/1', rest: [] });
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.Dialog') && c.isOpen() && c.getDomRef()
    && /Test Video/.test(c.getDomRef().textContent)), 'the preview dialog never opened on screen');
  await page.keyboard.press('Escape');
  await waitForUi5(page, () => !ui5All().some((c) => c.isA('sap.m.Dialog') && c.isOpen()), 'the preview dialog never closed');
  await waitForIdle(page);

  // ---------------------------------------------------------------- remove
  const declineId = await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
    const r = t.getRows().find((x) => x.getBindingContext() && x.getBindingContext().getProperty('FILENAME') === 'Transmission.vds');
    return r ? r.getCells()[r.getCells().length - 1].getId() : null; })()`);
  if (!declineId) throw new Error('the Transmission.vds row has no remove button');
  await page.locator(`[id="${declineId}"]`).click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Transmission.vds');
  await box.getByRole('button', { name: 'Remove' }).click();
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    const top = t && t.getModel().getProperty('/T_ITEMS');
    return top && top.length === 4 && !top.some((x) => x.FILENAME === 'Transmission.vds');
  }, 'confirming Remove never dropped Transmission.vds');
  await waitForIdle(page);

  // ---------------------------------------------------------------- upload
  await page.locator('input[type="file"][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'probe.txt', mimeType: 'text/plain', buffer: Buffer.alloc(1536, 'a') });
  await expect(page.locator('body'), 'the upload toast').toContainText('Document Added');
  await waitForUi5(page, () => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    const top = t && t.getModel().getProperty('/T_ITEMS');
    if (!top || top.length !== 5) return false;
    const r = top[0];
    return r.FILENAME === 'probe.txt' && r.MEDIATYPE === 'text/plain' && r.FILESIZE === 1536
      && r.FILESIZE_UNITS === '1.50 KB' && r.UPLOADSTATE === 'Complete';
  }, 'the picked file never became the new first node (probe.txt, text/plain, 1536 bytes = 1.50 KB, Complete)');
  expect(await model(page, '/T_ITEMS/0/FILENAME'), 'the new first node').toBe('probe.txt');
  await page.waitForTimeout(500);
  expect(uploads, 'requests to /uploadFiles (the veto must stop the XHR)').toEqual([]);
};
