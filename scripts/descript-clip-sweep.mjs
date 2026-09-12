#!/usr/bin/env node
/*
 * descript-clip-sweep — one-off: re-cut the abapGit DESCRIPTs that were
 * clipped mid-word at 60 characters.
 *
 * `<DESCRIPT>` holds 60 characters (AGENTS.md, "Metadata"). 27 sidecars
 * carried a description of EXACTLY 60 that ended in half a word -
 * `sap.m.Input - This example shows different input value state`,
 * `sap.m.CheckBox - In this sample, the CheckBox reflects the s` - the
 * remains of a longer sentence cut by a slice that did not know what a word
 * is (2026-09-12). Nothing here knows the rest of that sentence either; what
 * it can do is cut at the last whole word and say that something was cut,
 * which is what scripts/lib/clip.mjs `clipAtWord` does and what
 * scripts/scaffold.mjs should call when it writes a DESCRIPT.
 *
 * What is left alone: a 60-character DESCRIPT that IS the scaffolder's
 * default `<library> - <sample name>` in full (app 365,
 * `sap.ui.table - TreeTable.HierarchyMaintenanceJSONTreeBinding`, is exactly
 * 60 and complete) - a sample name is one token and has no word boundary to
 * cut at, and it is not clipped. Idempotent: a re-run finds nothing to do.
 *
 * Run:  node scripts/descript-clip-sweep.mjs [--check]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { walkFiles } from './lib/src-tree.mjs';
import { clipAtWord } from './lib/clip.mjs';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const CHECK = process.argv.includes('--check');
const MAX = 60;

const unescapeXml = (s) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');
const escapeXml = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');

let touched = 0;
let kept = 0;
for (const xml of walkFiles(path.join(ROOT, 'src'), '.clas.xml')) {
  const raw = fs.readFileSync(xml, 'utf8');
  const m = raw.match(/<DESCRIPT>([^<]*)<\/DESCRIPT>/);
  if (!m) continue;
  const desc = unescapeXml(m[1]);
  if (desc.length < MAX) continue;
  // already cut and marked - a clipped text that lands on exactly MAX again
  // must not be cut a second time on the next run
  if (desc.endsWith('...')) { kept += 1; continue; }

  const cls = path.basename(xml, '.clas.xml');
  const metaPath = path.join(ROOT, 'meta', `${cls}.json`);
  const meta = fs.existsSync(metaPath) ? JSON.parse(fs.readFileSync(metaPath, 'utf8')) : null;
  const sampleName = meta?.sample ? meta.sample.replace(/^(.*?)\.sample\./, '') : null;
  const lib = meta?.sample ? meta.sample.replace(/\.sample\..*$/, '') : null;
  if (sampleName && desc === `${lib} - ${sampleName}`) { kept += 1; continue; }

  /* A DESCRIPT of exactly MAX characters is, by construction, the HEAD of a
   * longer text - a slice stopped here, not the author - so the helper is
   * handed one character more than the field holds: that is what tells it
   * the text does not fit and makes it cut at the last whole word. */
  const clipped = clipAtWord(`${desc} `, MAX);
  if (clipped === desc) { kept += 1; continue; }
  console.log(`${CHECK ? 'would clip' : 'clipped'} ${path.relative(ROOT, xml)}\n  ${JSON.stringify(desc)}\n  ${JSON.stringify(clipped)}`);
  if (!CHECK) fs.writeFileSync(xml, raw.replace(m[0], `<DESCRIPT>${escapeXml(clipped)}</DESCRIPT>`));
  touched += 1;
}
console.log(`\ndescript-clip-sweep: ${touched} DESCRIPT(s) ${CHECK ? 'to clip' : 'clipped'}, ${kept} at ${MAX} characters left as they are (complete)`);
process.exit(CHECK && touched ? 1 : 0);
