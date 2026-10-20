// app 661 — sap.m.sample.UploadSetwithTablePlugin.TreeTableWithFolderHierarchy
//
// The LIVE_TEST asks for (a) the two-handler Rename press (.eB(RENAME);
// .eF(control_by_id renameItem)) with its argument - the first selected
// context, or null for a folder - and openFilePreview with the Link's binding
// Context, both through control_by_id's unlisted-method path; (b)
// rowSelectionChange transporting the selected context paths and the
// itemRenamed wire reading the item's binding path; (c) the vetoed
// beforeUploadStarts with the file's size; (d) DOWNLOAD_B64_FILE with an
// https test-resources URL and clearSelection after a navigation. Around
// those, the backend-ported controller: folder navigation (Link and
// Breadcrumbs), Add Folder, Rename Folder, row delete and Remove All. Every
// leg drives a real gesture and asserts the effect on the bound rows, flags,
// breadcrumbs or the plugin call.
import { waitForUi5, waitForIdle, waitForPopup, revealInOverflow, dispatchMouse, UI5_ALL_SRC } from '../../scripts/lib-e2e.mjs';

const TABLE = `ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed
  && c.getDomRef() && document.body.contains(c.getDomRef()))`;
const shown = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
  return t.getRows().map((r) => r.getBindingContext() && r.getBindingContext().getProperty('FILENAME')).filter(Boolean); })()`);
const flags = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC}
  const b = (s) => { const c = ui5All().find((x) => x.getId().endsWith('--' + s) && !x.bIsDestroyed); return c ? c.getEnabled() : null; };
  return { download: b('downloadSelectedButton'), rename: b('renameButton'), removeAll: b('removeAllButton') }; })()`);
const crumbs = (page) => page.evaluate(`(() => { ${UI5_ALL_SRC}
  const b = ui5All().find((c) => c.getId().endsWith('--breadcrumbs') && !c.bIsDestroyed);
  return { links: b.getLinks().map((l) => l.getText()), current: b.getCurrentLocationText() }; })()`);

async function rowsBecome(page, want, msg) {
  await waitForUi5(page, (w) => {
    const t = ui5All().find((c) => c.getId().endsWith('--table-uploadSet') && !c.bIsDestroyed && c.getDomRef());
    const n = t && t.getRows().map((r) => r.getBindingContext() && r.getBindingContext().getProperty('FILENAME')).filter(Boolean);
    return n && JSON.stringify(n) === JSON.stringify(w);
  }, `${msg} - wanted rows ${JSON.stringify(want)}`, want);
  await waitForIdle(page);
}
// the row selector of the row SHOWING `name` sits under the data cells, so
// only a dispatched mouse sequence reaches it (e2e-debugging guide)
async function toggleRow(page, name) {
  const i = (await shown(page)).indexOf(name);
  if (i < 0) throw new Error(`no row shows "${name}"`);
  await dispatchMouse(page.locator(`[id$="--table-uploadSet-rowsel${i}"]`).first());
}
async function flagsBecome(page, want, msg) {
  await waitForUi5(page, (w) => {
    const b = (s) => { const c = ui5All().find((x) => x.getId().endsWith('--' + s) && !x.bIsDestroyed); return c && c.getEnabled(); };
    return b('downloadSelectedButton') === w.download && b('renameButton') === w.rename && b('removeAllButton') === w.removeAll;
  }, `${msg} - wanted ${JSON.stringify(want)}`, want);
  await waitForIdle(page);
}
async function press(page, id) {
  const btn = page.locator(`[id$="--${id}"]`).first();
  await revealInOverflow(page, btn);
  await btn.click();
}
async function pressLink(page, text) {
  await page.locator('.sapUiTableCell .sapMLnk', { hasText: text }).first().click();
}
const toast = (page, text, label) => page.waitForFunction((t) => [...document.querySelectorAll('.sapMMessageToast')]
  .some((e) => e.textContent.includes(t)), text, { timeout: 10000 }).catch(() => { throw new Error(`no toast "${text}" (${label})`); });

export default async (page, expect) => {
  const uploads = [];
  page.on('request', (r) => { if (/uploadFiles/.test(r.url())) uploads.push(r.url()); });
  await waitForIdle(page);
  const ROOT = ['My Documents', 'Document.txt', 'Business Plan Topics.xls', 'sample-zip-file.zip', 'Temporary Files'];
  expect(await shown(page), 'the root of documents.json').toEqual(ROOT);
  expect(await crumbs(page), 'the root breadcrumbs').toEqual({ links: [], current: 'Attachments' });

  // spy on the plugin and on the anchor DOWNLOAD_B64_FILE clicks
  await page.evaluate(`(() => { ${UI5_ALL_SRC}
    const p = ui5All().find((c) => c.getId().endsWith('--uploadPlugin'));
    window.__usp = { calls: [], anchors: [] };
    for (const m of ['renameItem', 'openFilePreview']) {
      const orig = p[m];
      p[m] = function (...a) {
        window.__usp.calls.push({ m, ctx: !!(a[0] && a[0].isA && a[0].isA('sap.ui.model.Context')),
          path: a[0] && a[0].getPath ? a[0].getPath() : String(a[0]) });
        return orig.apply(this, a);
      };
    }
    // the anchor is recorded, not followed: its href is a CROSS-origin https
    // URL, where Chromium ignores the download attribute and would navigate
    // the tab away from the app under test
    const click = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function () {
      if (this.hasAttribute('download')) { window.__usp.anchors.push({ href: this.href, download: this.download,
        attached: document.body.contains(this) }); return; }
      return click.apply(this, arguments);
    };
  })()`);
  const spy = () => page.evaluate(() => window.__usp);

  // ------------------------------------------------------------- selection
  expect(await flags(page), 'flags before any selection').toEqual({ download: false, rename: false, removeAll: false });
  await toggleRow(page, 'Document.txt');
  await flagsBecome(page, { download: true, rename: true, removeAll: false },
    'selecting the file Document.txt never enabled Download and Rename - rowSelectionChange did not deliver its path');
  await toggleRow(page, 'Temporary Files');
  await flagsBecome(page, { download: false, rename: false, removeAll: false }, 'a file plus a folder never disabled Download and Rename');
  await toggleRow(page, 'Temporary Files');
  await flagsBecome(page, { download: true, rename: true, removeAll: false }, 'deselecting the folder never re-enabled them');

  // -------------------------------------------------------------- download
  await press(page, 'downloadSelectedButton');
  await toast(page, 'Download initiated for 1 file(s)', 'onDownloadFiles');
  expect((await spy()).anchors, 'the DOWNLOAD_B64_FILE anchor').toEqual([{
    href: 'https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt',
    download: 'Document.txt', attached: true }]);
  await waitForIdle(page);

  // ----------------------------------------------------------- rename file
  // two handlers on one press: the backend RENAME (a file: nothing to do)
  // and the plugin's renameItem with the selected Context
  await press(page, 'renameButton');
  const dlg = await waitForPopup(page, 'Rename Document');
  expect((await spy()).calls.filter((c) => c.m === 'renameItem'), 'renameItem( ) got the selected file\'s Context')
    .toEqual([{ m: 'renameItem', ctx: true, path: '/T_ITEMS/1' }]);
  await dlg.locator('input').first().fill('Readme');
  await dlg.getByRole('button', { name: 'Apply' }).click();
  await toast(page, 'File renamed successfully', 'itemRenamed');
  await rowsBecome(page, ['My Documents', 'Readme.txt', 'Business Plan Topics.xls', 'sample-zip-file.zip', 'Temporary Files'],
    'the itemRenamed wire never wrote Readme.txt into the node at /T_ITEMS/1');

  // --------------------------------------------------------- rename folder
  // select exactly the folder (whatever the rebuilt rows kept selected)
  await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE}; window.__sel = t.getSelectedIndices(); })()`);
  for (const i of await page.evaluate(() => window.__sel)) {
    await dispatchMouse(page.locator(`[id$="--table-uploadSet-rowsel${i}"]`).first());
    await waitForIdle(page);
  }
  await toggleRow(page, 'Temporary Files');
  await flagsBecome(page, { download: false, rename: true, removeAll: false }, 'selecting only the folder never enabled Rename alone');
  await press(page, 'renameButton');
  const rf = await waitForPopup(page, 'Rename Folder');
  const renames = (await spy()).calls.filter((c) => c.m === 'renameItem');
  expect(renames[renames.length - 1], 'the second handler handed renameItem null for a folder')
    .toEqual({ m: 'renameItem', ctx: false, path: 'null' });
  await rf.locator('input').first().fill('Scratch');
  await rf.locator('input').first().press('Tab');
  await rf.getByRole('button', { name: 'OK' }).click();
  await toast(page, 'Folder renamed successfully', 'RENAME_FOLDER_OK');
  await rowsBecome(page, ['My Documents', 'Readme.txt', 'Business Plan Topics.xls', 'sample-zip-file.zip', 'Scratch'],
    'the Rename Folder dialog never renamed Temporary Files to Scratch');

  // --------------------------------------------------------------- preview
  await pressLink(page, 'Business Plan Topics.xls');
  await waitForUi5(page, () => ui5All().some((c) => c.isA('sap.m.upload.FilePreviewDialog') && c._previewItem
    && c._previewItem.getFileName() === 'Business Plan Topics.xls'),
  'pressing the file Link never opened the plugin\'s FilePreviewDialog on that row');
  expect((await spy()).calls.filter((c) => c.m === 'openFilePreview'), 'openFilePreview( ) got the Link\'s own Context')
    .toEqual([{ m: 'openFilePreview', ctx: true, path: '/T_ITEMS/2' }]);
  await page.keyboard.press('Escape');
  await waitForUi5(page, () => !ui5All().some((c) => c.isA('sap.m.Dialog') && c.isOpen()), 'the preview dialog never closed');
  await waitForIdle(page);

  // ------------------------------------------- navigate in + Remove All
  // a folder Link opens the folder: rows, breadcrumbs, and clearSelection
  await pressLink(page, 'Scratch');
  await rowsBecome(page, ['Notes.txt'], 'the Scratch folder Link never opened the folder');
  expect(await crumbs(page), 'breadcrumbs inside Scratch').toEqual({ links: ['Attachments'], current: 'Scratch' });
  expect(await page.evaluate(`(() => { ${UI5_ALL_SRC} return ${TABLE}.getSelectedIndices(); })()`),
    'the TreeTable selection after the navigation (clearSelection)').toEqual([]);
  expect(await flags(page), 'flags after the navigation').toEqual({ download: false, rename: false, removeAll: false });
  await toggleRow(page, 'Notes.txt');
  await flagsBecome(page, { download: true, rename: true, removeAll: true }, 'selecting every item of the folder never enabled Remove All');
  await press(page, 'removeAllButton');
  const all = await waitForPopup(page, 'Delete All Items');
  await expect(all, 'the Remove All confirm').toContainText('Are you sure you want to delete ALL 1 item(s) in this folder?');
  await all.getByRole('button', { name: 'OK' }).click();
  await toast(page, '1 item(s) deleted successfully', 'deleteAllSelectedItems');
  await rowsBecome(page, [], 'Remove All never emptied the folder');

  // ------------------------------------------------- breadcrumb back home
  await page.setViewportSize({ width: 2400, height: 900 }); await page.waitForTimeout(1500);
  console.log(await page.evaluate(`(() => { ${UI5_ALL_SRC}
    const b = ui5All().find((c) => c.getId().endsWith('--breadcrumbs') && !c.bIsDestroyed);
    const d = b.getDomRef(); const tb = b.getParent();
    return JSON.stringify({ dom: !!d, html: d && d.outerHTML.slice(0, 600), parent: tb.getMetadata().getName(), vis: b.getVisible(),
      w: tb.getDomRef().offsetWidth, tbContent: tb.getContent().map((c) => c.getMetadata().getName() + ':' + !!c.getDomRef() + ':' + (c.getDomRef() ? c.getDomRef().offsetWidth : '-')),
      sel: [...document.querySelectorAll('.sapMBreadcrumbs')].length }); })()`));
  const crumb = page.locator('.sapMBreadcrumbs .sapMLnk', { hasText: 'Attachments' }).first();
  await revealInOverflow(page, crumb);
  await crumb.click();
  await rowsBecome(page, ['My Documents', 'Readme.txt', 'Business Plan Topics.xls', 'sample-zip-file.zip', 'Scratch'],
    'the Attachments breadcrumb never brought the root back');
  expect(await crumbs(page), 'breadcrumbs back at the root').toEqual({ links: [], current: 'Attachments' });

  // ------------------------------------------ one level deeper and back
  await pressLink(page, 'My Documents');
  await rowsBecome(page, ['Images', 'Reports', 'Third Quarter Results.ppt'], 'the My Documents Link never opened the folder');
  await pressLink(page, 'Images');
  await rowsBecome(page, ['Animation.gif', 'Screenshots'], 'the Images Link never opened the folder');
  expect(await crumbs(page), 'breadcrumbs inside Images').toEqual({ links: ['Attachments', 'My Documents'], current: 'Images' });
  const md = page.locator('.sapMBreadcrumbs .sapMLnk', { hasText: 'My Documents' }).first();
  await revealInOverflow(page, md);
  await md.click();
  await rowsBecome(page, ['Images', 'Reports', 'Third Quarter Results.ppt'], 'the My Documents breadcrumb never went one level up');

  // ------------------------------------------------------------ add folder
  await press(page, 'addFolderButton');
  const cf = await waitForPopup(page, 'Create New Folder');
  await cf.locator('input').first().fill('Drafts');
  await cf.locator('input').first().press('Tab');
  await cf.getByRole('button', { name: 'Create' }).click();
  await toast(page, 'New folder created: Drafts', 'createFolderWithName');
  await rowsBecome(page, ['Drafts', 'Images', 'Reports', 'Third Quarter Results.ppt'], 'Add Folder never unshifted Drafts into the open folder');

  // ------------------------------------------------------------ row delete
  const declineId = await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
    const r = t.getRows().find((x) => x.getBindingContext() && x.getBindingContext().getProperty('FILENAME') === 'Third Quarter Results.ppt');
    return r ? r.getCells()[r.getCells().length - 1].getId() : null; })()`);
  if (!declineId) throw new Error('the Third Quarter Results.ppt row has no delete button');
  await page.locator(`[id="${declineId}"]`).click();
  const del = await waitForPopup(page, 'Delete File');
  await expect(del, 'the delete confirm').toContainText("Are you sure you want to delete the file 'Third Quarter Results.ppt'?");
  await del.getByRole('button', { name: 'OK' }).click();
  await toast(page, "File 'Third Quarter Results.ppt' deleted successfully", 'onRemoveItemHandler');
  await rowsBecome(page, ['Drafts', 'Images', 'Reports'], 'confirming the delete never dropped the file');

  // ---------------------------------------------------------------- upload
  // filed into the OPEN folder behind its folders; no XHR (vetoed)
  await page.locator('input[type="file"][id$="uploadPlugin-uploader-fu"]').setInputFiles({
    name: 'probe.txt', mimeType: 'text/plain', buffer: Buffer.alloc(1536, 'a') });
  await toast(page, 'Upload completed successfully.', 'beforeUploadStarts');
  await rowsBecome(page, ['Drafts', 'Images', 'Reports', 'probe.txt'], 'the picked file never landed behind the folders of My Documents');
  const row = await page.evaluate(`(() => { ${UI5_ALL_SRC} const t = ${TABLE};
    const o = t.getModel().getProperty('/T_ITEMS/3'); return { n: o.FILENAME, m: o.MIMETYPE, s: o.SIZE, u: o.SIZE_UNITS, st: o.UPLOADSTATE, by: o.UPLOADEDBY }; })()`);
  expect(row, 'the uploaded node').toEqual({ n: 'probe.txt', m: 'text/plain', s: 1536, u: '1.50 KB', st: 'Complete', by: 'Current User' });
  await page.waitForTimeout(500);
  expect(uploads, 'requests to uploadFiles (the veto must stop the XHR)').toEqual([]);
};
