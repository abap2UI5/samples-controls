// Pre-transpile patch: make sure the open-abap `CALL TRANSFORMATION id` writer
// XML-escapes character data.
//
// Runs against a checkout of https://github.com/open-abap/open-abap-core
// (the transpiler lib the browser build and the Node e2e backend both stand
// on), before `abap_transpile` reads it — the config points at the patched
// folder instead of cloning the lib itself.
//
// Why: KERNEL_CALL_TRANSFORMATION's LCL_DATA_TO_XML used to build the result
// XML by plain string concatenation and write every element value RAW:
//
//     rv_xml = rv_xml && |<{ iv_name }>| && <ref> && |</{ iv_name }>|.
//
// So an app data field holding a `<` (the overview app's generation notes:
// "... are <= 1.71", "<strong>", the deprecated-control `<del>` markup) landed
// unescaped in the draft XML that Z2UI5_CL_UI5_APP_CONT=>DB_SAVE persists. On the
// next request DB_LOAD parses that XML back with the transpiled CL_IXML, whose
// parser saw the stray `<` as the start of a tag, failed its tag regex and
// died in `ASSERT ls_match-offset = 0` — an ASSERT is not catchable in the JS
// runtime, so the whole roundtrip 500s and the frontend showed
// "Network error: ASSERTION_FAILED". On a real ABAP server asXML escapes the
// value and the same app works, which is why this only ever bit the
// transpiled builds. This script lives under web/ci/ for historical reasons -
// it was written for the GitHub Pages demo, which was removed 2026-08-19 - and
// STAYS at this path because abap2UI5/mcp-server executes it by name, which
// scripts/check-mcp-contract.mjs enforces. Consumers now: scripts/e2e-build.mjs
// (`npm run e2e`) and mcp-server's incremental build.
//
// UPSTREAM SHIPPED BOTH EDITS. open-abap/open-abap-core#1193 merged 2026-09-15
// as c4bb873: LCL_DATA_TO_XML now routes every elementary value through its own
// `escape_text`, and LCL_ESCAPE=>UNESCAPE_VALUE resolves `&amp;` last. So on a
// current clone this script has nothing to do, and it says so instead of
// editing.
//
// It is NOT deleted, for two reasons. The path is a contract
// (check-mcp-contract.mjs), and — the substantive one — `e2e-build` REUSES its
// open-abap-core clone across builds ("delete it to pick up a newer
// open-abap-core", E2E.md). A checkout predating #1193 is therefore still a
// thing a machine can be holding, and on one of those the two edits below are
// exactly as load-bearing as they were. So each edit is guarded by a check for
// the upstream form and applied only when it is absent:
//   1. escape `&`, `<`, `>` in element character data on write (only when the
//      value carries one of them, so every other value serializes byte-identical
//      to before);
//   2. unescape `&amp;` LAST on read (CL_IXML replaced it first, so a value
//      that literally contains `&lt;` came back as `<`).
// Neither the upstream form nor the anchor present means a shape nobody here
// has seen — that still throws.
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const WRITE_FILE = "src/kernel/call_transformation/kernel_call_transformation.clas.locals_imp.abap";
const READ_FILE = "src/ixml/cl_ixml.clas.locals_imp.abap";

// --- 1. escape on write (LCL_DATA_TO_XML->RUN, kind_elem branch) -------------
const WRITE_ANCHOR = `        IF lo_type->type_kind = cl_abap_typedescr=>typekind_string AND <ref> IS INITIAL.
          rv_xml = rv_xml && |<{ iv_name }/>|.
        ELSE.
          rv_xml = rv_xml &&
            |<{ iv_name }>| &&
            <ref> &&
            |</{ iv_name }>|.
        ENDIF.`;

const WRITE_PATCH = `        IF lo_type->type_kind = cl_abap_typedescr=>typekind_string AND <ref> IS INITIAL.
          rv_xml = rv_xml && |<{ iv_name }/>|.
        ELSE.
* Patch for the transpiled abap2UI5 builds (web/ci/patch_open_abap_xml.mjs):
* XML-escape character data. Without it a data value containing "<" (or "&")
* produces XML that CL_IXML cannot parse back - the draft roundtrip then dies
* in an uncatchable ASSERT ("Network error: ASSERTION_FAILED").
          lv_escaped = <ref>.
          IF lv_escaped CA '&<>'.
            REPLACE ALL OCCURRENCES OF '&' IN lv_escaped WITH '&amp;'.
            REPLACE ALL OCCURRENCES OF '<' IN lv_escaped WITH '&lt;'.
            REPLACE ALL OCCURRENCES OF '>' IN lv_escaped WITH '&gt;'.
            rv_xml = rv_xml &&
              |<{ iv_name }>| &&
              lv_escaped &&
              |</{ iv_name }>|.
          ELSE.
            rv_xml = rv_xml &&
              |<{ iv_name }>| &&
              <ref> &&
              |</{ iv_name }>|.
          ENDIF.
        ENDIF.`;

// the local variable the patch above needs, declared with RUN's other DATA
const DATA_ANCHOR = `    DATA lv_ref   TYPE REF TO data.

    FIELD-SYMBOLS <any>   TYPE any.`;
const DATA_PATCH = `    DATA lv_ref   TYPE REF TO data.
    DATA lv_escaped TYPE string.

    FIELD-SYMBOLS <any>   TYPE any.`;

// --- 2. unescape "&amp;" last on read (LCL_ESCAPE=>UNESCAPE_VALUE) ----------
const READ_ANCHOR = `    REPLACE ALL OCCURRENCES OF '&amp;' IN rv_value WITH '&'.
    REPLACE ALL OCCURRENCES OF '&lt;' IN rv_value WITH '<'.
    REPLACE ALL OCCURRENCES OF '&gt;' IN rv_value WITH '>'.
    REPLACE ALL OCCURRENCES OF '&quot;' IN rv_value WITH '"'.
    REPLACE ALL OCCURRENCES OF '&apos;' IN rv_value WITH |'|.`;

const READ_PATCH = `    REPLACE ALL OCCURRENCES OF '&lt;' IN rv_value WITH '<'.
    REPLACE ALL OCCURRENCES OF '&gt;' IN rv_value WITH '>'.
    REPLACE ALL OCCURRENCES OF '&quot;' IN rv_value WITH '"'.
    REPLACE ALL OCCURRENCES OF '&apos;' IN rv_value WITH |'|.
* Patched (web/ci/patch_open_abap_xml.mjs): "&amp;" must be unescaped LAST,
* otherwise a value that literally contains "&lt;" comes back as "<".
    REPLACE ALL OCCURRENCES OF '&amp;' IN rv_value WITH '&'.`;

/* Does the checkout already do this itself? Written against what #1193 left
 * behind rather than against a SHA, because the clone carries no pin to read
 * and a later refactor upstream should still count as "escaped". */
const AMP = "REPLACE ALL OCCURRENCES OF '&amp;' IN rv_value WITH '&'.";
const LT = "REPLACE ALL OCCURRENCES OF '&lt;' IN rv_value WITH '<'.";

// the writer escapes when RUN hands the value to a helper instead of
// concatenating it raw
const writeIsCorrect = (src) => src.includes("escape_text(") && src.includes("METHOD escape_text.");
// the reader is right when "&amp;" is resolved after the other entities, so an
// "&amp;lt;" is not resolved twice
const readIsCorrect = (src) => {
  const amp = src.indexOf(AMP);
  const lt = src.indexOf(LT);
  return amp !== -1 && lt !== -1 && amp > lt;
};

function patch(file, edits, { isCorrect, what }) {
  if (!existsSync(file)) {
    throw new Error(`patch_open_abap_xml: ${file} not found - is the open-abap-core clone complete?`);
  }
  let src = readFileSync(file, "utf8");
  // `isCorrect` is about the FILE, not about who made it so: a checkout this
  // script patched on an earlier build satisfies the read-side check too, and
  // reporting that as "upstream" would be a lie the next reader acts on
  if (isCorrect(src)) return `${what}: already correct, nothing to patch`;
  let changed = false;
  for (const [anchor, replacement, note] of edits) {
    if (src.includes(replacement)) continue; // already patched (re-runnable)
    if (!src.includes(anchor)) {
      throw new Error(
        `patch_open_abap_xml: anchor not found in ${file} (${note}) and the checkout does not `
        + "carry the upstream fix either - open-abap-core changed, review the patch",
      );
    }
    src = src.replace(anchor, replacement);
    changed = true;
  }
  if (changed) writeFileSync(file, src);
  return changed
    ? `${what}: patched (checkout predates open-abap-core#1193)`
    : `${what}: already patched`;
}

export function patchOpenAbapXml(root) {
  const write = patch(join(root, WRITE_FILE), [
    [DATA_ANCHOR, DATA_PATCH, "LCL_DATA_TO_XML->RUN declarations"],
    [WRITE_ANCHOR, WRITE_PATCH, "LCL_DATA_TO_XML->RUN kind_elem branch"],
  ], { isCorrect: writeIsCorrect, what: "escape on write" });

  const read = patch(join(root, READ_FILE), [
    [READ_ANCHOR, READ_PATCH, "LCL_ESCAPE=>UNESCAPE_VALUE"],
  ], { isCorrect: readIsCorrect, what: "unescape order on read" });

  console.log(`patch_open_abap_xml: ${root}\n  ${write}\n  ${read}`);
}

// CLI: node patch_open_abap_xml.mjs [path-to-open-abap-core]
if (process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1])) {
  patchOpenAbapXml(process.argv[2] || fileURLToPath(new URL("../open-abap-core", import.meta.url)));
}
