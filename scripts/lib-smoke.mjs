/*
 * lib-smoke — the boot-noise contract of the e2e smoke gate, importable.
 *
 * Page-error (real JS exception) messages that are environment noise, not
 * port defects. Resource 404/500s are handled separately by response URL (a
 * localhost:3000 backend asset failing is real; an unbundled-UI5 resource we
 * didn't serve is benign) — the console "Failed to load resource" line
 * carries no URL, so it is ignored in favour of response tracking.
 *
 * This is the single source of the list: e2e-smoke.mjs consumes it here, and
 * the MCP server imports this file from its resolved ai-demokit checkout
 * so its run_app tool judges boots by the same rules as the nightly gate.
 */
export const BENIGN = [
  /library-preload/i, /messagebundle/i, /i18n/i, /themes?\/|library(\.css|-parameters)/i,
  /theming\.Parameters|\.properties/i, /failed to load (javascript )?resource/i,
  /Core\.applyTheme|sap\.ui\.getCore/i, /favicon/i, /deprecat/i, /sap-ui-cachebuster/i,
  /ERR_TUNNEL_CONNECTION_FAILED/i,
];

export const benign = (s) => BENIGN.some((re) => re.test(s));

/* The GET page's CSP, relaxed for a SOURCE-ONLY UI5.
 *
 * The smoke serves UI5 from the @openui5 npm packages, which carry sources and
 * no library-preload bundles, so the ui5loader fetches modules synchronously
 * and evals them. abap2UI5#2778 (2026-09-22) took 'unsafe-eval' out of the
 * default CSP - rightly: UI5 from the CDN runs without it - and from then on
 * every app died at boot on `Failed to execute 'sap/ui/core/Core.js': Refused
 * to evaluate a string as JavaScript`, which is the harness, not a port.
 *
 * So the harness adds 'unsafe-eval' to script-src, and only here - the same
 * relaxation abap2UI5's own node/tests/e2e/fixtures.js applies to its offline
 * run. A page that already carries it (a pin before #2778) is returned as is. */
export function allowEvalForSourceUi5(html) {
  return html.replace(/(script-src\s)([^;"]*)/, (m, head, rest) =>
    (/'unsafe-eval'/.test(rest) ? m : `${head}'unsafe-eval' ${rest}`));
}
