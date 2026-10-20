// sap.m.plugins.UploadSetwithTable - FileNameValidationSample. Closes the
// LIVE_TEST: the plugin calls by id through control_by_id with a live binding
// Context as the event arg (renameItem, openFilePreview, download), the
// selectionChange paths driving the toolbar flags, the itemRenamed wire, the
// vetoed beforeUploadStarts (the backend plays the mock server), the remove
// MessageBox, the binding_call search - and (d) setFileNameValidationConfig
// reached with a JSON object, which the plugin's rename dialog then validates
// against.
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
    config: p ? p.getFileNameValidationConfig() : null,
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

async function openRename(page) {
  const rn = page.getByRole('button', { name: 'Rename', exact: true });
  await revealInOverflow(page, rn);
  await rn.first().click();
  return waitForPopup(page, 'Rename Document');
}

export default async (page, expect) => {
  await waitForIdle(page);
  const start = await until(page, (s) => s.rows.length === 6, 'the six documents never rendered');
  expect(start.dl, 'Download disabled with no selection').toBe(false);
  expect(start.config, 'the view literal fileNameValidationConfig').toEqual({ mode: 'override', characters: '@$#' });

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

  /* ---- renameItem( <live Context> ) + the view's literal validation config */
  await openRename(page);
  expect(await renameInput(page, 'bad@name'), "'@' under the literal override '@$#'").toBe('Error');
  expect(await renameInput(page, 'okname'), 'a clean name').toBe('None');
  await page.keyboard.press('Escape');
  await waitForIdle(page);

  /* ---- (d) Configure -> setFileNameValidationConfig with a JSON object ---- */
  const chars = page.locator('[id$="--charInput-inner"]');
  // real keystrokes: the wire carries check_queue_last, so the last one wins
  const L=[]; page.on('request', (r) => { if (r.method()==='POST') L.push('REQ '+(r.postData()||'').slice(0,400)); });
  page.on('response', async (r) => { if (r.request().method()==='POST') { try { const t = await r.text(); const i=t.indexOf('CHARACTERS"'); L.push('RESP '+t.slice(Math.max(0,i-50), i+80)); } catch {} } });
  await chars.click();
  await chars.press('Control+a');
  await chars.pressSequentially('xyz');
  await waitForIdle(page);
  await page.waitForTimeout(1500); console.log(L.join('\n')); console.log('before', await chars.inputValue());
  await page.getByRole('button', { name: 'Configure', exact: true }).click();
  await expect(page.locator('.sapMMessageToast'), 'the Configure toast')
    .toContainText('Configuration mode: override, Characters: xyz');
  await until(page, (s) => s.config && s.config.characters === 'xyz',
    'Configure never reached setFileNameValidationConfig');
  expect((await state(page)).config, 'the applied config object').toEqual({ mode: 'override', characters: 'xyz' });
  // the plugin's rename dialog now validates against the NEW set
  await openRename(page);
  expect(await renameInput(page, 'bad@name'), "'@' is allowed once override is 'xyz'").toBe('None');
  expect(await renameInput(page, 'xname'), "'x' is restricted once override is 'xyz'").toBe('Error');

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
  await page.keyboard.press('Escape');
  await waitForIdle(page);

  /* ---- upload: beforeUploadStarts vetoed, the backend adds the row -------- */
  const body = Buffer.from('e2e upload payload');
  await page.locator('input[type=file][id$="uploadSetPlugin-uploader-fu"]').setInputFiles({
    name: 'e2e-upload.txt', mimeType: 'text/plain', buffer: body,
  });
  await expect(page.locator('.sapMMessageToast'), 'the upload toast').toContainText('Document Added');
  const up = await until(page, (s) => s.model.length === 7 && s.rows.includes('e2e-upload.txt'),
    'the vetoed upload never added the backend row');
  expect(up.model[0], 'the unshifted row carries name and size').toEqual({ name: 'e2e-upload.txt', size: body.length });

  /* ---- remove via the row's decline button + MessageBox ------------------- */
  const idx = up.rows.indexOf('Instructions.pdf');
  await page.locator(`[id$="table-uploadSet-${idx}"] button`).last().click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Instructions.pdf');
  await box.getByRole('button', { name: 'Remove', exact: true }).click();
  await until(page, (s) => s.model.length === 6 && !s.rows.includes('Instructions.pdf'),
    'Remove never dropped Instructions.pdf');
  await until(page, (s) => !s.dl && !s.rm, 'the removal did not reset the toolbar flags');

  /* ---- search: the binding_call filter on FILENAME ------------------------ */
  await page.locator('.sapMSF input').first().fill('e2e');
  await until(page, (s) => s.rows.length === 1 && s.rows[0] === 'e2e-upload.txt', 'the search never filtered the rows');
  await page.locator('.sapMSF input').first().fill('');
  await until(page, (s) => s.rows.length === 6, 'clearing the search did not bring the rows back');
};
