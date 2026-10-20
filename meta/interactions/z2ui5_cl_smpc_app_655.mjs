// sap.m.plugins.UploadSetwithTable - MultiplePluginInstances: three tables,
// three plugins. Closes the LIVE_TEST: each table's selectionChange (its id
// plus getSelectedContexts().length) driving ITS Download flag only; the plugin
// calls by id through control_by_id with a live Context - download on the
// second plugin, openFilePreview on the third - each landing on its own plugin
// instance; the vetoed beforeUploadStarts with $event.oSource.data('itemsPath')
// filing the backend row into the right array; the remove MessageBox (which,
// as in the original, clears the first table's selection) and the search that
// filters the first table.
import { waitForIdle, revealInOverflow, waitForPopup } from '../../scripts/lib-e2e.mjs';

const TABLES = ['table-uploadSet', 'table-uploadSet-instance2', 'table-uploadSet-instance3'];

// per table: live rows (filtered ones drop out), model rows, its Download flag
const state = (page) => page.evaluate((ids) => {
  const all = Object.values(sap.ui.require('sap/ui/core/Element').registry.all()).filter((c) => !c.bIsDestroyed);
  const live = (c) => c.getDomRef() && document.body.contains(c.getDomRef());
  const en = (s) => { const b = all.find((c) => c.getId().endsWith(`--${s}`)); return b ? b.getEnabled() : null; };
  const btns = ['downloadSelectedButton', 'downloadSelectedButton-instance2', 'downloadSelectedButton-instance3'];
  return ids.map((id, i) => {
    const t = all.find((c) => c.getId().endsWith(`--${id}`) && live(c));
    return {
      rows: t.getItems().filter((r) => r.getBindingContext()).map((r) => r.getBindingContext().getProperty('FILENAME')),
      model: t.getModel().getProperty(t.getBinding('items').getPath()).map((r) => ({ name: r.FILENAME, size: r.FILESIZE })),
      dl: en(btns[i]),
    };
  });
}, TABLES);

async function until(page, pred, msg) {
  const deadline = Date.now() + 15000;
  let s;
  for (;;) {
    s = await state(page);
    if (pred(s)) return s;
    if (Date.now() > deadline) throw new Error(`${msg} - last state ${JSON.stringify(s.map((t) => ({ rows: t.rows, dl: t.dl }))).slice(0, 500)}`);
    await page.waitForTimeout(250);
  }
}

const selectRow = async (page, table, i) => {
  await page.locator(`[id$="--${table}-${i}-selectMulti"]`).first().click();
  await waitForIdle(page);
};

// a popup the module closed must really be gone before the page is driven again
// (title null: no dialog at all may stay open)
async function waitForClosed(page, title) {
  await page.waitForFunction((t) => !Object.values(sap.ui.require('sap/ui/core/Element').registry.all())
    .some((c) => !c.bIsDestroyed && c.isA('sap.m.Dialog') && c.isOpen() && (t === null || c.getTitle() === t)),
  title, { timeout: 10000 }).catch(() => { throw new Error(`the ${title === null ? 'preview' : `"${title}"`} dialog never closed`); });
}

export default async (page, expect) => {
  await waitForIdle(page);
  const start = await until(page, (s) => s.every((t) => t.rows.length === 3), 'the three tables never rendered three rows each');
  expect(start.map((t) => t.rows[0]), 'the first row of each table')
    .toEqual(['Invoice summary.doc', 'Document.txt', 'Test Video.mp4']);
  expect(start.map((t) => t.dl), 'no Download enabled without a selection').toEqual([false, false, false]);

  /* ---- selectionChange: each table drives its own Download flag ---------- */
  await selectRow(page, TABLES[1], 0);
  await until(page, (s) => !s[0].dl && s[1].dl && !s[2].dl, 'selecting in table 2 did not enable exactly its Download');
  await selectRow(page, TABLES[0], 0);
  await until(page, (s) => s[0].dl && s[1].dl && !s[2].dl, 'selecting in table 1 did not enable its Download');

  /* ---- download on the SECOND plugin with table 2's live Context --------- */
  await page.route('**/UploadSetwithTableSampleFiles/**', (r) => r.fulfill({ status: 200, contentType: 'text/plain', body: 'e2e' }));
  await page.evaluate(() => {
    const P = sap.ui.require('sap/m/plugins/UploadSetwithTable').prototype;
    window.__calls = [];
    if (!P.__e2eWrapped) {
      P.__e2eWrapped = true;
      for (const m of ['download', 'openFilePreview']) {
        const orig = P[m];
        P[m] = function (ctx) {
          window.__calls.push({ m, plugin: this.getId().replace(/^.*--/, ''),
            ctx: !!(ctx && ctx.isA && ctx.isA('sap.ui.model.Context')), path: ctx && ctx.getPath && ctx.getPath() });
          return orig.apply(this, arguments);
        };
      }
    }
  });
  const dl2 = page.locator('[id$="--downloadSelectedButton-instance2"]');
  await revealInOverflow(page, dl2);
  const [req] = await Promise.all([
    page.waitForRequest((r) => r.url().includes('UploadSetwithTableSampleFiles'), { timeout: 10000 })
      .catch(() => { throw new Error('download( ) never fetched table 2\'s selected document'); }),
    dl2.first().click(),
  ]);
  expect(req.url(), 'the fetched document').toBe('https://sdk.openui5.org/test-resources/sap/m/UploadSetwithTableSampleFiles/Document.txt');
  expect(await page.evaluate(() => window.__calls), 'the download call')
    .toEqual([{ m: 'download', plugin: 'uploadSetPlugin-instance2', ctx: true, path: '/T_ITEMSINSTANCE2/0' }]);

  /* ---- openFilePreview on the THIRD plugin from its Link's Context ------- */
  await page.locator('[id$="--table-uploadSet-instance3"] .sapMLnk', { hasText: 'Test Video.mp4' }).first().click();
  const preview = await waitForPopup(page, 'Test Video.mp4');
  await expect(preview, 'the FilePreviewDialog').toContainText('Test Video.mp4');
  const calls = await page.evaluate(() => window.__calls);
  expect(calls[calls.length - 1], 'the preview call')
    .toEqual({ m: 'openFilePreview', plugin: 'uploadSetPlugin-instance3', ctx: true, path: '/T_ITEMSINSTANCE3/0' });
  await preview.getByRole('button', { name: 'Close', exact: true }).click();
  await waitForClosed(page, null);

  /* ---- upload through plugin 2: itemsPath files the row into ITS array --- */
  const body = Buffer.from('e2e upload payload');
  await page.locator('input[type=file][id$="--uploadSetPlugin-instance2-uploader-fu"]').setInputFiles({
    name: 'e2e-upload.txt', mimeType: 'text/plain', buffer: body,
  });
  await expect(page.locator('.sapMMessageToast'), 'the upload toast').toContainText('Document Added');
  const up = await until(page, (s) => s[1].model.length === 4 && s[1].rows.includes('e2e-upload.txt'),
    'the vetoed upload never added the row to table 2');
  expect(up[1].model[0], 'the unshifted row carries name and size').toEqual({ name: 'e2e-upload.txt', size: body.length });
  expect([up[0].model.length, up[2].model.length], 'tables 1 and 3 untouched').toEqual([3, 3]);

  /* ---- remove in table 1 via the decline button + MessageBox ------------- */
  const idx = up[0].rows.indexOf('Business Plan Topics.xls');
  await page.locator(`[id$="--table-uploadSet-${idx}"] button`).last().click();
  const box = await waitForPopup(page, 'Are you sure you want to remove the document Business Plan Topics.xls');
  await box.getByRole('button', { name: 'Remove', exact: true }).click();
  await until(page, (s) => s[0].model.length === 2 && !s[0].rows.includes('Business Plan Topics.xls'),
    'Remove never dropped Business Plan Topics.xls');
  await until(page, (s) => !s[0].dl && s[1].dl, 'the removal did not clear table 1\'s Download flag (only)');

  /* ---- search: the binding_call filter on the FIRST table ---------------- */
  await page.locator('.sapMSF input').first().fill('Invoice');
  await until(page, (s) => s[0].rows.length === 1 && s[0].rows[0] === 'Invoice summary.doc', 'the search never filtered table 1');
  await page.locator('.sapMSF input').first().fill('');
  await until(page, (s) => s[0].rows.length === 2, 'clearing the search did not bring table 1 back');
};
