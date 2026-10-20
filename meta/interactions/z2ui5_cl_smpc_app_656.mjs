// sap.m.plugins.UploadSetwithTable - ResponsiveTableFileDialogs. Closes the
// LIVE_TEST: the plugin calls by id through control_by_id with a live binding
// Context as the event arg (download, renameItem, openFilePreview), the
// selectionChange paths driving the toolbar flags, the itemRenamed wire writing
// the new name, the remove MessageBox, the binding_call search - and this
// variant's point, the vetoed beforeUploadStarts queuing the file into the
// FileUpload dialog (Browse through fileSelectionHandler, the per-file document
// type, the pending-file removal, Add filing it under the chosen type).
import { waitForIdle, revealInOverflow, waitForPopup } from '../../scripts/lib-e2e.mjs';

// the table's live rows (filtered ones drop out), the model rows and the four flags
const state = (page) => page.evaluate(() => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed);
  const live = (c) => c.getDomRef() && document.body.contains(c.getDomRef());
  const t = all.find((c) => c.getId().endsWith('--table-uploadSet') && live(c));
  const p = all.find((c) => c.getId().endsWith('--uploadSetPlugin'));
  const up = all.find((c) => c.isA('sap.m.Dialog') && c.isOpen() && c.getTitle() === 'Add Document by Upload');
  const en = (s) => { const b = all.find((c) => c.getId().endsWith(`--${s}`)); return b ? b.getEnabled() : null; };
  return {
    rows: t.getItems().filter((i) => i.getBindingContext()).map((i) => i.getBindingContext().getProperty('FILENAME')),
    model: t.getModel().getProperty(t.getBinding('items').getPath()).map((r) => ({ name: r.FILENAME, size: r.FILESIZE, type: r.DOCUMENTTYPE })),
    // the FileUpload popup carries its own copy of the model
    pending: ((up && up.getModel().getProperty('/T_SELECTEDITEMS')) || []).map((r) => ({ name: r.FILENAME, type: r.FILECATEGORYSELECTED })),
    add: !!(up && up.getModel().getProperty('/ADD_ENABLED')),
    dl: en('downloadSelectedButton'), rm: en('removeDocumentButton'), rn: en('renameButton'), ed: en('editUrlButton'),
  };
});

async function until(page, pred, msg) {
  const deadline = Date.now() + 15000;
  let s;
  for (;;) {
    s = await state(page);
    if (pred(s)) return s;
    if (Date.now() > deadline) throw new Error(`${msg} - last state ${JSON.stringify({ ...s, rows: s.rows.length, model: s.model.length }).slice(0, 500)}`);
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
  const start = await until(page, (s) => s.rows.length === 9, 'the nine documents never rendered');
  expect(start.dl, 'Download disabled with no selection').toBe(false);

  /* ---- selectionChange -> the two bound flags ---------------------------- */
  await selectRow(page, 0);
  await until(page, (s) => s.dl && s.rm && s.rn && s.ed, 'selecting one row never enabled Download/Remove/Rename/Edit URL');
  await selectRow(page, 1);
  await until(page, (s) => s.dl && !s.rm && !s.rn && !s.ed, 'two selected rows did not leave only Download enabled');
  await selectRow(page, 1);
  await until(page, (s) => s.dl && s.rm && s.rn, 'deselecting back to one row did not re-enable the single-row buttons');

  /* ---- download( <live Context>, true ) through control_by_id ------------ */
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

  /* ---- renameItem( <live Context> ) + the plugin's default restricted set */
  await openRename(page);
  expect(await renameInput(page, 'bad/name'), "'/' is in the default restricted set").toBe('Error');
  /* ---- itemRenamed -> the backend writes the new name into the row -------- */
  expect(await renameInput(page, 'Renamed'), 'the new name').toBe('None');
  await page.getByRole('button', { name: 'Apply', exact: true }).click();
  await expect(page.locator('.sapMMessageToast'), 'the rename toast').toContainText('Document Renamed.');
  await until(page, (s) => s.model[0].name === 'Renamed.doc' && s.rows[0] === 'Renamed.doc',
    'itemRenamed never wrote Renamed.doc into row 0');

  /* ---- openFilePreview( <the Link's live Context> ) ----------------------- */
  await page.locator('[id*="table-uploadSet-0"] .sapMLnk', { hasText: 'Renamed.doc' }).first().click();
  const preview = await waitForPopup(page, 'Renamed.doc');
  await expect(preview, 'the FilePreviewDialog').toContainText('Renamed.doc');
  await preview.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForClosed(page, null);

  /* ---- upload: beforeUploadStarts vetoed -> the FileUpload dialog -------- */
  const one = Buffer.from('e2e upload one');
  await page.locator('input[type=file][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'e2e-one.txt', mimeType: 'text/plain', buffer: one,
  });
  let dlg = await waitForPopup(page, 'Add Document by Upload');
  await expect(dlg, 'the picked file waits in the dialog').toContainText('e2e-one.txt');
  await until(page, (s) => s.pending.length === 1 && s.pending[0].type === 'Invoice' && s.add,
    'the queued file never got its preset type / the Add button');
  // Browse -> the plugin's fileSelectionHandler opens the file dialog again
  const [chooser] = await Promise.all([
    page.waitForEvent('filechooser', { timeout: 10000 })
      .catch(() => { throw new Error('Browse never reached fileSelectionHandler (no file chooser opened)'); }),
    dlg.getByRole('button', { name: 'Browse', exact: true }).click(),
  ]);
  await chooser.setFiles({ name: 'e2e-two.txt', mimeType: 'text/plain', buffer: Buffer.from('two') });
  await until(page, (s) => s.pending.length === 2 && s.pending[1].name === 'e2e-two.txt',
    'the second file never joined the dialog');
  // handleRemove - the second file leaves the dialog
  dlg = await waitForPopup(page, 'Add Document by Upload');
  await dlg.locator('tr', { hasText: 'e2e-two.txt' }).locator('button').last().click();
  await until(page, (s) => s.pending.length === 1 && s.pending[0].name === 'e2e-one.txt',
    'the decline button never removed the queued file');
  // the document type ComboBox, two-way bound, with its selectionChange wire
  dlg = await waitForPopup(page, 'Add Document by Upload');
  const combo = dlg.locator('.sapMComboBox input').first();
  // real keystrokes: the type-ahead picks the item, Enter commits the selection
  await combo.click();
  await combo.press('Control+a');
  await combo.pressSequentially('Legal');
  await combo.press('Enter');
  await waitForIdle(page);
  await until(page, (s) => s.pending[0].type === 'Legal Document' && s.add, 'the chosen type never reached the queued file');
  await dlg.getByRole('button', { name: 'Add', exact: true }).click();
  await expect(page.locator('.sapMMessageToast'), 'the upload toast').toContainText('Document Added');
  const up = await until(page, (s) => s.model.length === 10 && s.rows.includes('e2e-one.txt'),
    'Add never filed the queued document');
  expect(up.model[0], 'the unshifted row carries name, size and the chosen type')
    .toEqual({ name: 'e2e-one.txt', size: one.length, type: 'Legal Document' });
  await waitForClosed(page, 'Add Document by Upload');

  /* ---- remove via the row's decline button + MessageBox ------------------- */
  const idx = up.rows.indexOf('Instructions.pdf');
  await page.locator(`[id$="table-uploadSet-${idx}"] button`).last().click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Instructions.pdf');
  await box.getByRole('button', { name: 'Remove', exact: true }).click();
  await until(page, (s) => s.model.length === 9 && !s.rows.includes('Instructions.pdf'),
    'Remove never dropped Instructions.pdf');
  await until(page, (s) => !s.dl && !s.rm, 'the removal did not reset the toolbar flags');

  /* ---- search: the binding_call filter on FILENAME ------------------------ */
  await page.locator('.sapMSF input').first().fill('e2e');
  await until(page, (s) => s.rows.length === 1 && s.rows[0] === 'e2e-one.txt', 'the search never filtered the rows');
  await page.locator('.sapMSF input').first().fill('');
  await until(page, (s) => s.rows.length === 9, 'clearing the search did not bring the rows back');
};
