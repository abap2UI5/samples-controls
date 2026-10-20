// sap.m.plugins.UploadSetwithTable - GridTableSimple (sap.ui.table.Table).
// Closes the LIVE_TEST: rowSelectionChange carrying getSelectedIndices( ) and
// driving the toolbar flags, the plugin calls by id through control_by_id with
// a live Context resolved by index (download, renameItem) or taken from the
// template Link (openFilePreview), the itemRenamed wire writing the new name,
// the vetoed beforeUploadStarts (the backend plays the mock server) and the
// remove MessageBox.
import { waitForIdle, revealInOverflow, waitForPopup, dispatchMouse } from '../../scripts/lib-e2e.mjs';

// the table's live rows (filtered ones drop out), the model rows and the four flags
const state = (page) => page.evaluate(() => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed);
  const live = (c) => c.getDomRef() && document.body.contains(c.getDomRef());
  const t = all.find((c) => c.getId().endsWith('--table-uploadSet') && live(c));
  const p = all.find((c) => c.getId().endsWith('--uploadSetPlugin'));
  const en = (s) => { const b = all.find((c) => c.getId().endsWith(`--${s}`)); return b ? b.getEnabled() : null; };
  return {
    rows: t.getRows().filter((r) => r.getBindingContext()).map((r) => r.getBindingContext().getProperty('FILENAME')),
    sel: t.getSelectedIndices(),
    model: t.getModel().getProperty(t.getBinding('rows').getPath()).map((r) => ({ name: r.FILENAME, size: r.FILESIZE })),
    dl: en('downloadSelectedButton'), rm: en('removeDocumentButton'), rn: en('renameButton'), ed: en('editUrlButton'),
  };
});

async function until(page, pred, msg) {
  const deadline = Date.now() + 15000;
  let s;
  for (;;) {
    s = await state(page);
    if (pred(s)) return s;
    if (Date.now() > deadline) throw new Error(`${msg} - last state ${JSON.stringify(s).slice(0, 400)}`);
    await page.waitForTimeout(250);
  }
}

// the row selector sits under the data cells: a real click is intercepted, the
// mousedown/mouseup/click sequence is what sap.ui.table's pointer extension acts on
const selectRow = async (page, i) => {
  await dispatchMouse(page.locator(`[id$="--table-uploadSet-rowsel${i}"]`).first());
  await waitForIdle(page);
};

// the rename dialog the plugin builds itself: type, read the input's value state
async function renameInput(page, value) {
  const dlg = await waitForPopup(page, 'Rename Document');
  const input = dlg.locator('input').first();
  await input.fill(value);
  return page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const d = all.find((c) => !c.bIsDestroyed && c.isA('sap.m.Dialog') && c.isOpen() && c.getTitle() === 'Rename Document');
    return d.getContent()[1].getValueState();
  });
}

// a popup the module closed must really be gone before the page is driven again
// (title null: no dialog at all may stay open)
async function waitForClosed(page, title) {
  await page.waitForFunction((t) => !Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .some((c) => !c.bIsDestroyed && c.isA('sap.m.Dialog') && c.isOpen() && (t === null || c.getTitle() === t)),
  title, { timeout: 10000 }).catch(() => { throw new Error(`the ${title === null ? 'preview' : `"${title}"`} dialog never closed`); });
}

async function openRename(page) {
  const rn = page.getByRole('button', { name: 'Rename', exact: true });
  await revealInOverflow(page, rn);
  await rn.first().click();
  return waitForPopup(page, 'Rename Document');
}

export default async (page, expect) => {
  await waitForIdle(page);
  const start = await until(page, (s) => s.rows.length === 9, 'the nine documents never rendered');
  expect(start.rows[0], 'row 0').toBe('Invoice summary.doc');
  expect(start.dl, 'Download disabled with no selection').toBe(false);

  /* ---- rowSelectionChange (getSelectedIndices) -> the two bound flags ---- */
  await selectRow(page, 0);
  await until(page, (s) => s.dl && s.rm && s.rn && s.ed, 'selecting one row never enabled Download/Remove/Rename/Edit URL');
  await selectRow(page, 1);
  await until(page, (s) => s.sel.length === 2 && s.dl && !s.rm && !s.rn && !s.ed, 'two selected rows did not leave only Download enabled');
  await selectRow(page, 1);
  await until(page, (s) => s.sel.length === 1 && s.dl && s.rm && s.rn, 'deselecting back to one row did not re-enable the single-row buttons');

  /* ---- download( getContextByIndex( <selected index> ), true ) ----------- */
  const docUrl = 'https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Business%20Plan%20Agenda.doc';
  await page.route('**/UploadSetwithTableSampleFiles/**', (r) => r.fulfill({ status: 200, contentType: 'application/msword', body: 'e2e' }));
  await page.evaluate(() => {
    const P = sap.ui.require('sap/m/plugins/UploadSetwithTable').prototype;
    window.__dl = [];
    if (!P.__e2eDl) {
      P.__e2eDl = P.download;
      P.download = function (ctx, ask) {
        window.__dl.push({ ctx: !!(ctx && ctx.isA && ctx.isA('sap.ui.model.Context')), path: ctx && ctx.getPath && ctx.getPath(), ask });
        return P.__e2eDl.apply(this, arguments);
      };
    }
  });
  const dlBtn = page.getByRole('button', { name: 'Download', exact: true });
  await revealInOverflow(page, dlBtn);
  const [req] = await Promise.all([
    page.waitForRequest((r) => r.url().includes('UploadSetwithTableSampleFiles'), { timeout: 10000 })
      .catch(() => { throw new Error('download( ) never fetched the selected row\'s document URL'); }),
    dlBtn.first().click(),
  ]);
  const dl = await page.evaluate(() => window.__dl);
  expect(dl.length, 'plugin.download calls').toBe(1);
  expect(dl[0], 'download got the live Context of row 0 and bAskForLocation').toEqual({ ctx: true, path: dl[0].path, ask: true });
  if (!/\/0$/.test(dl[0].path)) throw new Error(`download was handed ${dl[0].path}, not the selected row 0`);
  expect(req.url(), 'the fetched document').toBe(docUrl);

  /* ---- renameItem -> itemRenamed writes the new name into the row ------- */
  await openRename(page);
  expect(await renameInput(page, 'bad/name'), "'/' is in the default restricted set").toBe('Error');
  expect(await renameInput(page, 'Renamed'), 'the new name').toBe('None');
  await page.getByRole('button', { name: 'Apply', exact: true }).click();
  await expect(page.locator('.sapMMessageToast'), 'the rename toast').toContainText('Document Renamed.');
  await until(page, (s) => s.model[0].name === 'Renamed.doc' && s.rows[0] === 'Renamed.doc',
    'itemRenamed never wrote Renamed.doc into row 0');

  /* ---- openFilePreview( <the template Link's live Context> ) ------------- */
  await page.locator('[id$="--table-uploadSet"] .sapMLnk', { hasText: 'Renamed.doc' }).first().click();
  const preview = await waitForPopup(page, 'Renamed.doc');
  await expect(preview, 'the FilePreviewDialog').toContainText('Renamed.doc');
  await preview.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForClosed(page, null);

  /* ---- upload: beforeUploadStarts vetoed, the backend adds the row -------- */
  // the veto is the point: the plugin must never POST to its uploadUrl
  const uploadPosts = [];
  page.on('request', (r) => { if (r.url().includes('/uploadFiles')) uploadPosts.push(r.url()); });
  const body = Buffer.from('e2e upload payload');
  await page.locator('input[type=file][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'e2e-upload.txt', mimeType: 'text/plain', buffer: body,
  });
  await expect(page.locator('.sapMMessageToast'), 'the upload toast').toContainText('Document Added');
  const up = await until(page, (s) => s.model.length === 10 && s.rows.includes('e2e-upload.txt'),
    'the vetoed upload never added the backend row');
  expect(up.model[0], 'the unshifted row carries name and size').toEqual({ name: 'e2e-upload.txt', size: body.length });

  expect(uploadPosts.length, 'requests to /uploadFiles (the vetoed upload)').toBe(0);

  /* ---- remove via the row's decline button + MessageBox ------------------- */
  const btn = await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all());
    const b = all.find((c) => !c.bIsDestroyed && c.isA('sap.m.Button') && c.getIcon() === 'sap-icon://decline' && c.getDomRef()
      && c.getBindingContext() && c.getBindingContext().getProperty('FILENAME') === 'Instructions.pdf');
    return b ? b.getId() : null;
  });
  if (!btn) throw new Error('the Instructions.pdf row rendered no decline button');
  await page.locator(`[id="${btn}"]`).click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Instructions.pdf');
  await box.getByRole('button', { name: 'Remove', exact: true }).click();
  await until(page, (s) => s.model.length === 9 && !s.rows.includes('Instructions.pdf'),
    'Remove never dropped Instructions.pdf');
};
