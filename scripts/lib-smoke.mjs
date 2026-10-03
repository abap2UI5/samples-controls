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
import crypto from 'crypto';

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
 * no library-preload bundles, so two things the CDN build never needs happen
 * in the browser, and the framework's default CSP refuses both:
 *
 *   1. the ui5loader fetches modules synchronously and evals them.
 *      abap2UI5#2778 (2026-09-22) took 'unsafe-eval' out of the default CSP -
 *      rightly: UI5 from the CDN runs without it - and from then on every app
 *      died at boot on `Failed to execute 'sap/ui/core/Core.js': Refused to
 *      evaluate a string as JavaScript`.
 *   2. the tree's sap-ui-core.js is the DEV bootstrap, which document.write()s
 *      two INLINE scripts of its own (DEV_BOOTSTRAP_INLINE below; the built
 *      bundle the CDN serves runs the same two calls inside itself).
 *      abap2UI5#2790 (2026-09-25) dropped 'unsafe-inline' from script-src and
 *      allows exactly one inline script, the page's own, by its SHA-256. The
 *      two dev-bootstrap scripts were refused, UI5 never booted, and EVERY
 *      app timed out in the 60 s boot wait with nothing but
 *      `page.waitForFunction: Timeout 60000ms exceeded` - every nightly from
 *      2026-09-26 on (cancelled at the job timeout, ~20 ports into each
 *      shard) and every e2e-pr run against a pin from #2790 on.
 *
 * Both are the harness, not a port. So the harness adds 'unsafe-eval' and the
 * two dev-bootstrap hashes to script-src, and only here - the same relaxation
 * abap2UI5's own node/tests/e2e/fixtures.js applies to its offline run
 * (DEV_BOOTSTRAP_HASHES there). A real system loads UI5 from the CDN and
 * needs neither.
 *
 * The hashes are added only when inline script is NOT already open: a pin
 * before #2790 carries 'unsafe-inline' and no hash, and a hash source next to
 * it would make the browser IGNORE 'unsafe-inline' - the page's own
 * onInitComponent script, which that pin does not hash, would then be the
 * one refused. A token the policy already names is not added twice. */
export const DEV_BOOTSTRAP_INLINE = [
  'sap.ui.requireSync("sap/ui/core/Core");',
  'sap.ui.getCore().boot && sap.ui.getCore().boot();',
];
export const DEV_BOOTSTRAP_HASHES = DEV_BOOTSTRAP_INLINE.map(
  (script) => `'sha256-${crypto.createHash('sha256').update(script, 'utf8').digest('base64')}'`,
);

export function allowEvalForSourceUi5(html) {
  return html.replace(/(script-src\s)([^;"]*)/, (m, head, rest) => {
    const inlineOpen = /'unsafe-inline'/.test(rest) && !/'(?:sha(?:256|384|512)-|nonce-)/.test(rest);
    const add = ["'unsafe-eval'", ...(inlineOpen ? [] : DEV_BOOTSTRAP_HASHES)]
      .filter((token) => !rest.includes(token));
    return add.length ? `${head}${add.join(' ')} ${rest}` : m;
  });
}
