/*
 * lib-a2ui5 — locate the abap2UI5 checkout the Node backend builds and serves.
 *
 * Preference order:
 *   1. A2UI5_HOME            explicit override
 *   2. <repo>/.abap2UI5      the in-repo clone that `npm run node:setup` writes
 *   3. <repo>/../abap2UI5    a sibling checkout
 * The first candidate that actually contains the express shim wins.
 *
 * A2UI5_PIN (repo root) holds the framework commit the reproducible paths
 * build against: node-setup checks the in-repo clone out at that SHA. The pin
 * moves via .github/workflows/bump-a2ui5.yaml; the nightly e2e stays on main
 * tip as the upstream canary.
 */
import { execFileSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

export const REPO_ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
export const IN_REPO_A2UI5 = path.join(REPO_ROOT, '.abap2UI5');

export function resolveA2UI5() {
  const cands = [
    process.env.A2UI5_HOME,
    IN_REPO_A2UI5,
    path.join(REPO_ROOT, '..', 'abap2UI5'),
  ];
  for (const c of cands) {
    if (c && fs.existsSync(path.join(c, 'node/srv/express.mjs'))) return path.resolve(c);
  }
  return null;
}

/** The pinned abap2UI5 commit (A2UI5_PIN at the repo root), or null. */
export function readA2UI5Pin() {
  try {
    const sha = fs.readFileSync(path.join(REPO_ROOT, 'A2UI5_PIN'), 'utf8').trim();
    return /^[0-9a-f]{40}$/.test(sha) ? sha : null;
  } catch {
    return null;
  }
}

/* The files e2e-build writes into the checkout's root for the length of a build
 * and removes at its end (both git-ignored there). Present at the START of a
 * build, they mean another build is running against the same checkout - or one
 * died half-way. Either way the two would share node/downport and node/output. */
export const BUILD_LOCK_FILES = ['e2e-downport.jsonc', 'e2e-transpile.json'];

/**
 * Why building in this checkout right now may be a mistake, as sentences; empty
 * when nothing is wrong. Two signals, both cheap and both measured on the
 * checkout itself rather than guessed from a process list:
 *   - an e2e-build lock file (BUILD_LOCK_FILES) - a build in flight or a crash;
 *   - uncommitted changes (`git status --porcelain`): the build transpiles the
 *     checkout's src/ as it stands, so the backend is then NOT the pin, and a
 *     dirty tree is also what a concurrent framework `npm run verify` /
 *     `abaplint --fix` leaves while it runs (E2E.md: 86 files rewritten to
 *     their v702 form on 2026-08-06).
 * Not a git checkout (an extracted backend tarball): only the lock is judged.
 */
export function checkoutWarnings(dir) {
  const out = [];
  const locks = BUILD_LOCK_FILES.filter((f) => fs.existsSync(path.join(dir, f)));
  if (locks.length) {
    out.push(`${locks.join(' and ')} ${locks.length > 1 ? 'are' : 'is'} present - another e2e-build is running against this checkout, or one died before cleaning up`);
  }
  const git = (...args) => execFileSync('git', ['-C', dir, ...args], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
  let status;
  try {
    // only the checkout's OWN repository: a directory without one inside
    // another work tree would otherwise answer with the outer tree's state
    if (fs.realpathSync(git('rev-parse', '--show-toplevel').trim()) !== fs.realpathSync(dir)) return out;
    status = git('status', '--porcelain');
  } catch {
    return out;
  }
  const dirty = status.split('\n').filter(Boolean)
    .filter((l) => !BUILD_LOCK_FILES.includes(l.slice(3).trim()));
  if (dirty.length) {
    out.push(`the checkout has ${dirty.length} uncommitted change(s) (${dirty.slice(0, 3).map((l) => l.slice(3)).join(', ')}${dirty.length > 3 ? ', …' : ''}) - the backend will be built from them, not from a commit, and a framework \`npm run verify\` or \`abaplint --fix\` may be rewriting them right now`);
  }
  return out;
}
