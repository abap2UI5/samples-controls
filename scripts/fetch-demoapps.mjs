#!/usr/bin/env node
/*
 * fetch-demoapps — snapshot what the demo kit says about its DEMO APPS.
 *
 * The demo kit has two kinds of content, and this repository used to know only
 * one of them. A SAMPLE shows one control (`sap.m.sample.CheckBoxTriState`) and
 * is what `ui5/descriptions.json` describes; a DEMO APP is a whole application
 * (Shopping Cart, Manage Products, Shop Administration Tool) with routing, its
 * own model layer and several views. The demo apps page lists them:
 *
 *   https://sdk.openui5.org/demoapps
 *
 * and its data is in the same files the sample descriptions come from — one
 * per library, under a different key:
 *
 *   src/<lib>/test/<lib path>/demokit/docuindex.json
 *       -> demo.links[] = { text, desc, category, ref, config, teaser }
 *
 * Same snapshot argument as fetch-descriptions: a CI run and a rebuild batch
 * must both work without a 43k-file OpenUI5 checkout, and an upstream text
 * change must show up as a diff somebody reads rather than silently rewrite
 * class files.
 *
 *   node scripts/fetch-demoapps.mjs --openui5 <path to an openui5 checkout>
 *
 * The `ports` and `skipped` blocks in the output are NOT touched by this
 * script: they are this repository's own - `ports` maps a `src/04` class to
 * the app it rebuilds (the join key generate-summary / generate-origin /
 * generate-samples-md read, the same role `written` plays in
 * ui5/descriptions.json), and `skipped` records, per app, why it is NOT
 * rebuilt. A demo app that is neither is simply not done yet.
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execFileSync } from 'child_process';
import { isSkippedDir } from './lib/src-tree.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(ROOT, 'ui5', 'demoapps.json');

const i = process.argv.indexOf('--openui5');
const CHECKOUT = i > -1 ? process.argv[i + 1] : null;
if (!CHECKOUT || !fs.existsSync(CHECKOUT)) {
  console.error('usage: node scripts/fetch-demoapps.mjs --openui5 <path to an openui5 checkout>');
  console.error('\n  git clone --depth 1 https://github.com/SAP/openui5 /tmp/openui5');
  process.exit(2);
}

/** every src/<lib>/test/**\/demokit/docuindex.json under the checkout */
function docuindexes(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    if (isSkippedDir(name)) continue;
    if (fs.statSync(full).isDirectory()) {
      if (name === 'node_modules' || name === '.git') continue;
      docuindexes(full, out);
    } else if (name === 'docuindex.json' && path.basename(dir) === 'demokit') {
      out.push(full);
    }
  }
  return out;
}

/* The app's identity is its FOLDER, not its title: a title is prose upstream
 * may reword ("Browse Orders" over the `orderbrowser` folder), while the
 * folder is the thing this repository archives and rebuilds against. Read it
 * out of the `config` path, which every non-external app carries:
 *
 *   test-resources/sap/m/demokit/cart/demoapp.json   ->  sap.m/cart
 *   test-resources/sap/m/demokit/tutorial/worklist/…  ->  sap.m/tutorial/worklist
 */
function identify(config) {
  const m = /^test-resources\/(.+?)\/demokit\/(.+)\/demoapp\.json$/.exec(String(config || ''));
  if (!m) return null;
  const library = m[1].split('/').join('.');
  return { key: `${library}/${m[2]}`, library, source: `src/${library}/test/${m[1]}/demokit/${m[2]}` };
}

const apps = {};
const files = docuindexes(path.join(CHECKOUT, 'src')).sort();
for (const file of files) {
  let doc;
  try { doc = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { continue; }
  for (const link of doc.demo?.links || []) {
    const id = identify(link.config);
    /* An app hosted outside the OpenUI5 repository (the three SAP-samples
     * ones) has nothing here to rebuild against: either it carries no folder
     * at all, or the folder holds a `demoapp.json` that is one external URL.
     * The `ref` is what tells them apart — it leaves the SDK. Keep them in
     * the snapshot so the list is the demo kit's list, marked for what they
     * are. */
    if (!id || /^https?:/.test(String(link.ref || ''))) {
      const key = String(link.text || '').toLowerCase().replace(/[^a-z0-9]+/g, '-');
      if (key) apps[key] = { name: link.text || '', description: link.desc || '', category: link.category || '', external: true, ref: link.ref || '' };
      continue;
    }
    apps[id.key] = {
      name: link.text || '',
      description: link.desc || '',
      category: link.category || '',
      library: id.library,
      source: id.source,
      ref: link.ref || '',
    };
  }
}

const previous = fs.existsSync(OUT) ? JSON.parse(fs.readFileSync(OUT, 'utf8')) : {};

const git = (...args) => execFileSync('git', ['-C', CHECKOUT, ...args], { encoding: 'utf8' }).trim();
const version = (() => {
  try { return JSON.parse(fs.readFileSync(path.join(CHECKOUT, 'package.json'), 'utf8')).version; }
  catch { return ''; }
})();

const out = {
  source: {
    repo: 'https://github.com/SAP/openui5',
    commit: git('rev-parse', 'HEAD'),
    committed: git('log', '-1', '--format=%cs'),
    version,
    from: 'src/*/test/**/demokit/docuindex.json -> demo.links[]',
    page: 'https://sdk.openui5.org/demoapps',
    libraries: [...new Set(Object.values(apps).map((a) => a.library).filter(Boolean))].length,
    /* docuindex.json files walked. A SPARSE checkout scans fewer than the ~10
     * the demo kit ships, which is fine while the ones it misses carry no
     * `demo` block - verified across the full tree on 2026-09-13: sap.m and
     * sap.tnt are the only two libraries that list demo apps at all. */
    scanned: files.length,
    licence: 'Apache-2.0 (OpenUI5). Held verbatim, like the sample sources under ui5/<lib>/<Sample>/.',
  },
  apps: Object.fromEntries(Object.keys(apps).sort().map((k) => [k, apps[k]])),
  ports: previous.ports || {},
  skipped: previous.skipped || {},
};

fs.writeFileSync(OUT, `${JSON.stringify(out, null, 2)}\n`);
const external = Object.values(out.apps).filter((a) => a.external).length;
console.log(`demoapps: ${Object.keys(apps).length} app(s) from ${files.length} docuindex file(s), ${external} hosted outside OpenUI5`);
console.log(`  openui5 ${out.source.version} @ ${out.source.commit.slice(0, 12)} (${out.source.committed})`);
console.log(`  rebuilt here: ${Object.keys(out.ports).length}, deliberately not rebuilt: ${Object.keys(out.skipped).length}`);
console.log(`  -> ui5/demoapps.json`);
