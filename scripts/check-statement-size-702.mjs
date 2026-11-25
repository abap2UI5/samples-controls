#!/usr/bin/env node
/* check-statement-size-702: the kernel's statement-length limit, judged on the
 * DOWNPORTED tree. Run it after `npm run downport` (abap-702, auto-downport);
 * on main it would judge statements the downport has not split yet.
 *
 * Why a second rule beside `statement-too-long` in pattern-lint.mjs: that one
 * counts raw source characters on main against a budget of 75,000. A 7.40
 * system refused app 487 on the 702 branch with "The length of the current
 * statement is greater than the allowed maximum length of 28 kilobytes"
 * (#3048) - at 53,273 raw characters, while app 412 at 42,483 raw characters
 * imported fine from the same pull. What separates them is what the kernel
 * keeps of a statement: indentation, line breaks and comments do not count,
 * literal text does. 487 was mostly literal text (40,261 condensed), 412
 * mostly indentation (20,433 condensed). So this rule condenses first -
 * comments dropped, every whitespace run outside a literal reduced to one
 * blank - and holds the result to BUDGET.
 *
 * The data points (702 branch, 7.40, 2026-11-25): 40,261 FAILED; 20,433 and
 * everything below it PASSED. 28 KB is 28,672; BUDGET stays a little under
 * it, since the kernel's exact measure is not known. Raise it only with a
 * live data point. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { statements } from './lib/abap-statements.mjs';

export const BUDGET = 28000;

const BT = String.fromCharCode(96);

/** comments out, whitespace outside literals and templates down to one blank */
export function condense(text) {
  const src = text.split('\n').filter((l) => !l.startsWith('*')).join('\n');
  let out = '';
  let gap = false;
  for (let i = 0; i < src.length;) {
    const c = src[i];
    if (c === BT || c === "'" || c === '|') {
      let j = i + 1;
      while (j < src.length) {
        if (src[j] === c) {
          if (c !== '|' && src[j + 1] === c) { j += 2; continue; }
          break;
        }
        j++;
      }
      if (gap && out) out += ' ';
      gap = false;
      out += src.slice(i, j + 1);
      i = j + 1;
      continue;
    }
    if (c === '"') {
      while (i < src.length && src[i] !== '\n') i++;
      continue;
    }
    if (/\s/.test(c)) { gap = true; i++; continue; }
    if (gap && out) out += ' ';
    gap = false;
    out += c;
    i++;
  }
  return out;
}

function* abapFiles(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { if (e.name !== 'zz_dev') yield* abapFiles(p); }
    else if (p.endsWith('.abap')) yield p;
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const root = path.resolve(process.argv[2] || path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'src'));
  let failed = 0;
  for (const file of abapFiles(root)) {
    const content = fs.readFileSync(file, 'utf8');
    for (const s of statements(content)) {
      const size = condense(s.text).length;
      if (size <= BUDGET) continue;
      const line = content.slice(0, s.start + (s.text.length - s.text.trimStart().length)).split('\n').length;
      console.error(`${path.relative(process.cwd(), file)}:${line}: statement of ${size} characters without whitespace and comments - a 7.40 kernel refuses it above 28 KB (#3048); split it: loop a repeated subtree over a sub-handle, or move long text into plain assignments`);
      failed++;
    }
  }
  if (failed) process.exit(1);
  console.log(`check-statement-size-702: every statement under ${BUDGET} characters`);
}
