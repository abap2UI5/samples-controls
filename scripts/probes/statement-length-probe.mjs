#!/usr/bin/env node
/*
 * Statement-length probe — the worksheet for an activation test.
 *
 * What the defect looks like: a port whose whole view chain, or whose whole
 * mock table, is ONE ABAP statement of tens of thousands of characters. ABAP
 * has a maximum statement length the kernel enforces at activation, and it
 * is written down nowhere anyone here can read: abaplint does not model it,
 * the transpiler does not model it, the render gate reconstructs the view
 * from the source without ever compiling it. So a port that crosses the
 * limit is green in every gate and fails the first time a human pulls it
 * into a system - which is how the overview app's catalogue failed (a
 * ~226,000-character VALUE #( ), since chunked; regenerate-artefacts guide).
 *
 * What is known: ~226,000 fails; app 012's model_init at ~72,000 passes
 * (status `checked`, live-verified). Nothing between the two has been tried.
 * pattern-lint's `statement-too-long` gates at STATEMENT_BUDGET, just above
 * the largest live-verified statement; THIS probe lists everything a
 * maintainer with a real system should activate to move that number - the
 * biggest statements first, with the class, the method, the size in
 * characters and lines, and the sidecar status, so a `checked` row reads as
 * evidence and a `generated` one as a candidate.
 *
 * A hit is not a defect: it is a statement nobody has measured. What settles
 * it is an activation on a real system, and the result belongs in the
 * STATEMENT_BUDGET comment in scripts/pattern-lint.mjs.
 *
 * Keyed off meta/*.json so it covers every port by construction; the overview
 * app (no sidecar) is excluded - its catalogue is chunked by the emitter at
 * CHUNK_CHARS 3000 and is prose about the ports, not a port.
 *
 * Run:  node scripts/probes/statement-length-probe.mjs [--over <chars>] [--json]
 *       --over   the threshold, default 20000
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { statements, methodAt, lineAt } from '../lib/abap-statements.mjs';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const META = path.join(ROOT, 'meta');

const args = process.argv.slice(2);
const over = args.includes('--over') ? Number(args[args.indexOf('--over') + 1]) : 20000;
const asJson = args.includes('--json');

const rows = [];
for (const f of fs.readdirSync(META).sort()) {
  if (!f.endsWith('.json')) continue;
  const m = JSON.parse(fs.readFileSync(path.join(META, f), 'utf8'));
  if (!m.file || !fs.existsSync(path.join(ROOT, m.file))) continue;
  const src = fs.readFileSync(path.join(ROOT, m.file), 'utf8');
  for (const s of statements(src)) {
    const text = s.text.trim();
    if (text.length <= over) continue;
    const at = s.start + (s.text.length - s.text.trimStart().length);
    rows.push({
      class: m.class,
      method: methodAt(src, at) || '(outside a method)',
      line: lineAt(src, at),
      chars: text.length,
      lines: text.split('\n').length,
      status: m.status,
    });
  }
}
rows.sort((a, b) => b.chars - a.chars);

if (asJson) {
  console.log(JSON.stringify({ over, rows }, null, 1));
} else {
  console.log(`statements over ${over.toLocaleString('en')} characters: ${rows.length} in ${new Set(rows.map((r) => r.class)).size} ports\n`);
  console.log(`${'class'.padEnd(24)} ${'method'.padEnd(14)} ${'line'.padStart(6)} ${'chars'.padStart(8)} ${'lines'.padStart(6)}  status`);
  for (const r of rows) {
    console.log(`${r.class.padEnd(24)} ${r.method.padEnd(14)} ${String(r.line).padStart(6)} ${String(r.chars).padStart(8)} ${String(r.lines).padStart(6)}  ${r.status}`);
  }
  const verified = rows.filter((r) => r.status === 'checked');
  console.log(`\nlargest live-verified (status checked): ${verified.length ? `${verified[0].class} ${verified[0].method} ${verified[0].chars.toLocaleString('en')} characters` : 'none over the threshold'}`);
  console.log('largest known to FAIL: ~226,000 (the overview catalogue before it was chunked)');
  console.log('a new data point goes into STATEMENT_BUDGET in scripts/pattern-lint.mjs');
}
