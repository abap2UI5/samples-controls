/*
 * The `src/04` demo-app package — one reader, used by every generator that has
 * to tell a demo app from a port (AGENTS §3).
 *
 * A PORT rebuilds one demo kit SAMPLE and carries a meta/<class>.json sidecar;
 * the whole port machinery (structural_diff, data_fidelity, coverage, the
 * overview app) is driven by that sidecar. A DEMO APP rebuilds a whole demo kit
 * APPLICATION — several views, routing, a model layer — of which there are
 * eight in OpenUI5, so it has no sample id, no single control and nothing for
 * the coverage tables to count. It is therefore sidecar-less by construction,
 * exactly like the src/03 collection, and what would have gone into a sidecar
 * lives in the `ports` block of ui5/demoapps.json: which app a class rebuilds
 * and how far it is verified.
 *
 * Path shape is the discriminator, as everywhere else in this repository:
 * `src/<cc>/<ll>/x.clas.abap` is a port (two numeric levels), `src/04/x.clas.abap`
 * is a demo app (one), so no script needs a list of class names.
 */
import fs from 'fs';
import path from 'path';

/** the package the demo apps live in */
export const DEMO_FOLDER = 'src/04';

/** is this repo-relative path a demo-app class? */
export function isDemoApp(rel) {
  return /^src\/04\/[^/]+\.clas\.abap$/.test(String(rel || '').split(path.sep).join('/'));
}

/**
 * The committed snapshot plus the two blocks this repository owns: `ports`
 * (class -> the app it rebuilds, and how far it is verified) and `skipped`
 * (app -> why it is deliberately NOT rebuilt). An app in neither is simply
 * not done yet.
 */
export function loadDemoApps(root) {
  const file = path.join(root, 'ui5', 'demoapps.json');
  if (!fs.existsSync(file)) return { source: {}, apps: {}, ports: {}, skipped: {} };
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  return {
    source: data.source || {},
    apps: data.apps || {},
    ports: data.ports || {},
    skipped: data.skipped || {},
  };
}

/**
 * Everything known about the demo app a class rebuilds: the upstream record
 * (name, description, category, source folder) merged with this repository's
 * own entry (the app key, the verification status). `null` when the class is
 * not mapped — which is a problem for the caller to report, never a skip: an
 * unmapped class in src/04 means somebody added an app and did not say which.
 */
export function demoAppOf(root, cls) {
  const { apps, ports } = loadDemoApps(root);
  const entry = ports[cls];
  if (!entry || !apps[entry.app]) return null;
  return { key: entry.app, status: entry.status || '', ...apps[entry.app] };
}
