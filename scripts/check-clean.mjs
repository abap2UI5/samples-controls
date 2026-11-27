#!/usr/bin/env node
/*
 * check-clean — the "regenerate, then compare with what is committed" gate.
 *
 *   node scripts/check-clean.mjs <path>...     (npm run check:clean)
 *
 * It was `git diff --exit-code -- <paths>`, which sees TRACKED files only: a
 * generated file that was deleted and regenerated under another name, or a
 * generator that writes a file nobody committed, is untracked, and the gate
 * passed with the change sitting outside the commit. `git status --porcelain`
 * reports modified, deleted and untracked files alike, so that is what decides
 * here; the diff is printed only to show what changed.
 *
 * Exit 0 clean, 1 anything differs, 2 usage or git error.
 */
import { spawnSync } from 'child_process';

const paths = process.argv.slice(2);
if (paths.length === 0) {
  console.error('usage: node scripts/check-clean.mjs <path>...');
  process.exit(2);
}

const status = spawnSync('git', ['status', '--porcelain', '--untracked-files=all', '--', ...paths],
  { encoding: 'utf8' });
if (status.status !== 0) {
  process.stderr.write(status.stderr || 'git status failed\n');
  process.exit(2);
}
if (status.stdout.trim() === '') process.exit(0);

console.error('check-clean: these generated files differ from the committed ones '
  + '(regenerate and commit them):\n' + status.stdout);
spawnSync('git', ['--no-pager', 'diff', '--', ...paths], { stdio: 'inherit' });
process.exit(1);
