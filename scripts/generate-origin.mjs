#!/usr/bin/env node
/*
 * generate-origin — give every port the one line that says where it came from
 * and how far it is verified.
 *
 * `" @keywords` answers "which words find this port", `" @summary` answers
 * "is this the one I want". What neither says is the third thing a reader IN
 * THE SYSTEM asks of a port: which demo kit sample is this a rebuild of, and
 * has a human ever seen it run. Both facts exist - in meta/<class>.json, the
 * sidecar - and the sidecar is exactly what does not reach the system:
 * abapGit pulls src/, and the class file is all a developer in ADT, a search
 * engine or an agent reading GitHub raw gets (AGENTS.md, "Metadata: what goes
 * on the class"). Only 15 of 637 ports named their original anywhere in the
 * source; 208 of them are machine-written and never run, and the source said
 * nothing about that either.
 *
 * So a third generated line, under the two:
 *
 *   " @origin sap.m.sample.ActionListItem - https://sdk.openui5.org/entity/sap.m.ActionListItem/sample/sap.m.sample.ActionListItem (status: checked)
 *
 * the demo kit sample, the URL of its page in the demo kit - the same page
 * api.md links - and the sidecar's status: `checked` (a human watched it run),
 * `reviewed` (read against the original, not run), `generated` (machine-
 * written, not yet reviewed). A plain `"` comment, like the two above it:
 * not ABAP Doc, so the pattern-lint rule against `"!` in a port is untouched
 * and SLIN/ATC see nothing. Nothing here is invented - every word comes out
 * of the sidecar, and `--check` holds the line to it, so a port whose status
 * moves in meta/ without a regeneration turns this gate red rather than
 * lying in the class.
 *
 * Ports only: the SAPUI5-only collection in src/03 has no sidecar, no demo
 * kit original and its own ABAP Doc naming the control, and the generated
 * overview app writes its own header (scripts/generate-overview.mjs).
 *
 *   node scripts/generate-origin.mjs          write the lines
 *   node scripts/generate-origin.mjs --check  fail if a line is missing or
 *                                             out of date (CI runs this)
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { walkFiles } from './lib/src-tree.mjs';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const CHECK = process.argv.includes('--check');

/* The demo kit page of a sample: the entity's page, opened on that sample -
 * the same address api.md and the overview app send a reader to. */
const DEMOKIT = process.env.DEMOKIT || 'https://sdk.openui5.org';
const pageOf = (entity, sample) => `${DEMOKIT}/entity/${entity}/sample/${sample}`;

/* The generated overview app is owned by generate-overview.mjs, which writes
 * its whole header. */
const GENERATED = 'z2ui5_cl_smpc_app_000';

const STATUSES = new Set(['checked', 'reviewed', 'generated']);

const problems = [];
let write = 0;
let already = 0;
let skipped = 0;

for (const file of walkFiles(path.join(ROOT, 'src'), '.clas.abap')) {
  const cls = path.basename(file, '.clas.abap');
  if (cls === GENERATED) continue;
  const source = fs.readFileSync(file, 'utf8');
  if (!/INTERFACES\s+z2ui5_if_app\s*\./i.test(source)) continue;

  const metaPath = path.join(ROOT, 'meta', `${cls}.json`);
  if (!fs.existsSync(metaPath)) { skipped += 1; continue; }   // the src/03 collection
  const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8'));

  if (!meta.sample || !meta.entity || !STATUSES.has(meta.status)) {
    problems.push(`${cls}: the sidecar names no sample, no entity or no known status - nothing to write an @origin line from`);
    continue;
  }
  const line = `" @origin ${meta.sample} - ${pageOf(meta.entity, meta.sample)} (status: ${meta.status})`;
  if (line.length > 255) {
    problems.push(`${cls}: the @origin line would be ${line.length} characters, over abaplint's 255`);
    continue;
  }
  const have = (source.match(/^" @origin .*$/m) || [null])[0];

  if (have === line) { already += 1; continue; }
  if (CHECK) {
    problems.push(have
      ? `${cls}: the @origin line is out of date — run \`npm run origin\``
      : `${cls}: no \`" @origin\` line — run \`npm run origin\``);
    continue;
  }
  /* Under the summary line, so the three header lines stand in one order in
   * every port: what finds it, what it shows, where it came from. */
  fs.writeFileSync(file, have
    ? source.replace(/^" @origin .*$/m, line)
    : (/^" @summary .*$/m.test(source)
      ? source.replace(/^(" @summary .*)$/m, `$1\n${line}`)
      : (/^" @keywords .*$/m.test(source)
        ? source.replace(/^(" @keywords .*)$/m, `$1\n${line}`)
        : `${line}\n${source}`)));
  write += 1;
}

console.log(CHECK
  ? `origin: ${already} port(s) name their demo kit sample and their status; ${skipped} collection class(es) carry no sidecar and no line`
  : `origin: ${write} written, ${already} already current, ${skipped} collection class(es) skipped`);

if (problems.length) {
  console.error(`\n${problems.length} problem(s):`);
  for (const p of problems.slice(0, 10)) console.error(`  ${p}`);
  if (problems.length > 10) console.error(`  … and ${problems.length - 10} more`);
  console.error('\nThe line is read off meta/<class>.json - fix the sidecar, then run the generator.');
  process.exit(1);
}
