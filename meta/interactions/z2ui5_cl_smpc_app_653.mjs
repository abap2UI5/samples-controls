// sap.m.plugins.UploadSetwithTable - FilePreviewCustomPageContent. Closes the
// LIVE_TEST: the plugin calls by id through control_by_id with a live binding
// Context as the event arg (download, renameItem, openFilePreview - the latter
// into the view's own FilePreviewDialog via the previewDialog association), the
// selectionChange paths driving the toolbar flags, the arg-less itemRenamed
// toast, the vetoed beforeUploadStarts (the backend plays the mock server), the
// remove MessageBox and the binding_call search.
import { waitForIdle, revealInOverflow, waitForPopup } from '../../scripts/lib-e2e.mjs';

// the table's live rows (filtered ones drop out), the model rows and the four flags
const state = (page) => page.evaluate(() => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed);
  const live = (c) => c.getDomRef() && document.body.contains(c.getDomRef());
  const t = all.find((c) => c.getId().endsWith('--table-uploadSet') && live(c));
  const p = all.find((c) => c.getId().endsWith('--uploadSetPlugin'));
  const en = (s) => { const b = all.find((c) => c.getId().endsWith(`--${s}`)); return b ? b.getEnabled() : null; };
  return {
    rows: t.getItems().filter((i) => i.getBindingContext()).map((i) => i.getBindingContext().getProperty('FILENAME')),
    model: t.getModel().getProperty(t.getBinding('items').getPath()).map((r) => ({ name: r.FILENAME, size: r.FILESIZE })),
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

const selectRow = async (page, i) => {
  await page.locator(`[id$="table-uploadSet-${i}-selectMulti"]`).first().click();
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
  const start = await until(page, (s) => s.rows.length === 7, 'the seven documents never rendered');
  expect(start.rows[0], 'row 0').toBe('Instructions.pdf');
  expect(start.dl, 'Download disabled with no selection').toBe(false);

  /* ---- selectionChange -> the two bound flags ---------------------------- */
  await selectRow(page, 0);
  await until(page, (s) => s.dl && s.rm && s.rn && s.ed, 'selecting one row never enabled Download/Remove/Rename/Edit URL');
  await selectRow(page, 1);
  await until(page, (s) => s.dl && !s.rm && !s.rn && !s.ed, 'two selected rows did not leave only Download enabled');
  await selectRow(page, 1);
  await until(page, (s) => s.dl && s.rm && s.rn, 'deselecting back to one row did not re-enable the single-row buttons');

  /* ---- download( <live Context>, true ) through control_by_id ------------ */
  const docUrl = 'https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Instructions.pdf';
  await page.route('**/UploadSetwithTableSampleFiles/**', (r) => r.fulfill({ status: 200, contentType: 'application/pdf', body: 'e2e' }));
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

  /* ---- renameItem( <live Context> ) -> itemRenamed (toast only) ---------- */
  await openRename(page);
  expect(await renameInput(page, 'bad/name'), "'/' is in the default restricted set").toBe('Error');
  expect(await renameInput(page, 'Renamed'), 'the new name').toBe('None');
  await page.getByRole('button', { name: 'Apply', exact: true }).click();
  await expect(page.locator('.sapMMessageToast'), 'the rename toast').toContainText('Document Renamed.');
  await waitForClosed(page, 'Rename Document');
  await waitForIdle(page);
  // this variant's onDocumentRenamedSuccess does not write the model - as in the original
  expect((await state(page)).model[0].name, 'row 0 keeps its name in the model').toBe('Instructions.pdf');

  /* ---- openFilePreview( <the Link's live Context> ) into the view's dialog */
  await page.locator('[id*="table-uploadSet-2"] .sapMLnk', { hasText: 'Test Image.png' }).first().click();
  const preview = await waitForPopup(page, 'Test Image.png');
  await expect(preview, 'the FilePreviewDialog').toContainText('Test Image.png');
  // the plugin previews through the view's dialog (the previewDialog association)
  const pv = await page.evaluate(() => {
    const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed);
    const p = all.find((c) => c.getId().endsWith('--uploadSetPlugin'));
    const d = sap.ui.require('sap/ui/core/Element').getElementById(p.getPreviewDialog());
    return { id: d && d.getId(), item: d && d._previewItem && d._previewItem.getFileName() };
  });
  if (!/--FilePreviewDialog$/.test(pv.id || '') || pv.item !== 'Test Image.png') {
    throw new Error(`the preview did not go through the view's FilePreviewDialog with Test Image.png: ${JSON.stringify(pv)}`);
  }
  await preview.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForClosed(page, null);

  /* ---- upload: beforeUploadStarts vetoed, the backend adds the row -------- */
  const body = Buffer.from('e2e upload payload');
  await page.locator('input[type=file][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'e2e-upload.txt', mimeType: 'text/plain', buffer: body,
  });
  await expect(page.locator('.sapMMessageToast'), 'the upload toast').toContainText('Document Added');
  const up = await until(page, (s) => s.model.length === 8 && s.rows.includes('e2e-upload.txt'),
    'the vetoed upload never added the backend row');
  expect(up.model[0], 'the unshifted row carries name and size').toEqual({ name: 'e2e-upload.txt', size: body.length });

  /* ---- remove via the row's decline button + MessageBox ------------------- */
  const idx = up.rows.indexOf('Document.txt');
  await page.locator(`[id$="table-uploadSet-${idx}"] button`).last().click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Document.txt');
  await box.getByRole('button', { name: 'Remove', exact: true }).click();
  await until(page, (s) => s.model.length === 7 && !s.rows.includes('Document.txt'),
    'Remove never dropped Document.txt');
  await until(page, (s) => !s.dl && !s.rm, 'the removal did not reset the toolbar flags');

  /* ---- search: the binding_call filter on FILENAME ------------------------ */
  await page.locator('.sapMSF input').first().fill('zip');
  await until(page, (s) => s.rows.length === 1 && s.rows[0] === 'Sample Zip File.zip', 'the search never filtered the rows');
  await page.locator('.sapMSF input').first().fill('');
  await until(page, (s) => s.rows.length === 7, 'clearing the search did not bring the rows back');
};
