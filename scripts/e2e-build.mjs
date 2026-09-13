#!/usr/bin/env node
/*
 * e2e-build — assemble the transpiled abap2UI5 backend that serves the PORTS.
 *
 * The view-gates render gate reconstructs a view statically; this build runs the REAL app:
 * the abap2UI5 framework (which includes z2ui5_cl_ui5_view_builder in
 * src/02/) + the ai-demokit ports
 * are transpiled to JS by @abaplint/transpiler and served by the framework's
 * express shim (node/srv/express.mjs -> ZCL_SICF -> z2ui5_cl_http_handler),
 * i.e. the same open-abap runtime the framework's own e2e uses. An app is then
 * started in a browser via ?app_start=<class> (see e2e-smoke.mjs).
 *
 * The abap2UI5 checkout supplies the transpiler + express + runtime libs;
 * resolved by lib-a2ui5.mjs (A2UI5_HOME override, then the in-repo .abap2UI5
 * clone that `npm run node:setup` writes, then ../abap2UI5, then
 * /home/user/abap2UI5). The
 * framework must have its node_modules installed. The framework SOURCE is never
 * mutated — a COPY is downported in node/downport (its normal build dir), the
 * transpiler writes node/output, and express serves that.
 *
 * The transpiler cannot take the framework's modern ABAP directly (e.g.
 * COND ... LET ...), so the copy is downported to v702 first, exactly like the
 * framework's own `npm run auto_downport` — but on the copy, so the working
 * tree stays clean.
 */
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { resolveA2UI5 } from './lib-a2ui5.mjs';
import { isSkippedDir } from './lib/src-tree.mjs';
import { patchFollowUpAction } from '../web/ci/patch_follow_up_action.mjs';
import { patchOpenAbapXml } from '../web/ci/patch_open_abap_xml.mjs';

const AIDEMOKIT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

const A2 = resolveA2UI5();
if (!A2) {
  throw new Error('abap2UI5 checkout not found — run `npm run node:setup` (clones it into .abap2UI5) or set A2UI5_HOME to a checkout with node_modules installed');
}
const sh = (cmd, opts = {}) => execSync(cmd, { cwd: A2, stdio: 'inherit', ...opts });
// abaplint --fix exits non-zero while issues remain (expected during iterative
// downport); run it for its side effect and ignore the status
const fix = (cmd) => { try { execSync(cmd, { cwd: A2, stdio: ['ignore', 'ignore', 'ignore'] }); } catch { /* remaining issues are fixed across passes */ } };

// classes that don't transpile (excluded from the served backend, logged so the
// skip is never silent). Add a port here only with a reason if the transpiler
// chokes on it. The overview app IS served — it is the local front door,
// listing every port with a ?app_start= launch link (open
// ?app_start=z2ui5_cl_smpc_app_000). It is not a numbered port, so
// e2e-smoke never picks it up.
const EXCLUDE = new Set([]);

function main() {
  console.log(`e2e-build: abap2UI5 at ${A2}`);
  const downport = path.join(A2, 'node/downport');
  const output = path.join(A2, 'node/output');
  fs.rmSync(downport, { recursive: true, force: true });
  fs.rmSync(output, { recursive: true, force: true });
  fs.mkdirSync(downport, { recursive: true });

  // 1. framework src (modern copy) + the express shim handler + transpile setup
  //    src/99 is historical only (see the framework's AGENTS.md) - so it is
  //    dropped from the copy, EXCEPT what the served backend still references:
  //    the exit-interface rename (abap2UI5#2647) kept the superseded
  //    z2ui5_if_exit alive as a compatibility member of z2ui5_cl_ui5_user_exit
  //    (and its test double), so dropping it fails the transpile validate for
  //    every port ("Implemented interface Z2UI5_IF_EXIT not found")
  fs.cpSync(path.join(A2, 'src'), downport, { recursive: true });
  for (const keep of fs.readdirSync(path.join(A2, 'src/99'))) {
    if (/^z2ui5_if_exit\.intf\./.test(keep)) fs.copyFileSync(path.join(A2, 'src/99', keep), path.join(downport, keep));
  }
  fs.rmSync(path.join(downport, '99'), { recursive: true, force: true });
  for (const f of fs.readdirSync(path.join(A2, 'node/srv'))) {
    if (f.endsWith('.abap')) fs.copyFileSync(path.join(A2, 'node/srv', f), path.join(downport, f));
  }

  // 2. ai-demokit ports (both .abap and .clas.xml) — z2ui5_cl_ui5_view_builder
  //    ships with the framework src (abap2UI5 src/02/), copied in step 1
  let ports = 0;
  for (const f of walk(path.join(AIDEMOKIT, 'src'))) {
    if (!/\.(abap|xml)$/.test(f)) continue;
    const base = path.basename(f);
    const cls = base.replace(/\.(clas|intf)\..*$/, '');
    if (EXCLUDE.has(cls)) continue;
    fs.copyFileSync(f, path.join(downport, base));
    if (/^z2ui5_cl_smpc_app_\d+\.clas\.abap$/.test(base)) ports++;
  }
  console.log(`e2e-build: copied ${ports} ports + framework into node/downport`);
  if (EXCLUDE.size) console.log(`e2e-build: excluded (not served): ${[...EXCLUDE].join(', ')}`);

  // 2b. rewire the view-wired follow_up_action( ) calls ON THE COPY. The
  //     transpiler does not model `IS SUPPLIED` for a RETURNING parameter, so
  //     the branch that returns the roundtrip-free wire is dead and every
  //     handler written into a view attribute comes out empty.
  //     web/ci/patch_follow_up_action.mjs is the single source and carries the
  //     full analysis; it sits under web/ because it was written for the Pages
  //     demo, which was removed 2026-08-19 — this is now its only consumer.
  patchFollowUpAction(downport);

  // 3. downport the copy to v702 (in place, on the copy) — abaplint --fix, a few
  //    passes to settle, then the framework's two sed fixups
  // the config's `files` glob is relative to the config file's directory, so
  // the config sits at the abap2UI5 root and points at /node/downport. Use the
  // framework's FULL 702 rule set (check_syntax:true + definitions_top etc.) —
  // downport can only split inline DATA(x) into a top DATA + assignment when it
  // can resolve the type, so a minimal config produces broken JS (undefined
  // vars). Base it on .github/abaplint/abap_702.jsonc, override only `files`.
  const base = JSON.parse(fs.readFileSync(path.join(A2, '.github/abaplint/abap_702.jsonc'), 'utf8'));
  base.global = { files: '/node/downport/**/*.*' };
  const cfg = path.join(A2, 'e2e-downport.jsonc');
  fs.writeFileSync(cfg, JSON.stringify(base, null, 2));
  // No downport shim any more: abaplint outlines a component-level table
  // expression with `READ TABLE ... ASSIGNING` from 2.120.51 on
  // (abaplint/abaplint#4276), so the row reference that
  // `client->_bind( tab / tab_index )` matches the bound cell by survives the
  // downport of this corpus. It did not before, and every cell-binding port
  // booted into BINDING_ERROR_TAB_CELL_LEVEL here while being correct on a
  // system - which is what abap2UI5's node/setup/patch-abaplint-downport.mjs
  // patched into the installed bundle until that release. This build uses the
  // framework checkout's abaplint install, so it picks the fix up from there.

  // The framework's RUNTIME shim is still needed: this is the
  // install the transpiled backend runs on, and the framework applies this
  // script before every one of its own transpiled runs (auto_transpile, unit,
  // express). Without it a dynamic `ASSIGN obj->( name )` cannot reach a
  // PRIVATE attribute - a private ABAP attribute is a JavaScript `#field` in
  // the transpiled class, which no name lookup sees - and the asXML heap
  // writer of CALL TRANSFORMATION id reaches EVERY attribute of a
  // serializable object that way. sy-subrc is 4, the writer's ASSERT dies,
  // and every roundtrip of an app holding such an object answers HTTP 500
  // with `ASSERTION_FAILED @ lcl_heap.add_object`, naming neither the class
  // nor the attribute. A real system serializes private attributes fine, so
  // nothing else catches it: not ABAP, not abaplint, not the transpiler.
  //
  // Six ports paid for the gap - 049, 121, 241, 291, 299, 308, every one of
  // them binding with `omit_initial_paths`, which makes the client hand in
  // lcl_initial_paths_filter and its private mt_names. The nightly reported
  // them for over a week as an assert that names nothing, and the weekly pin
  // bump then read as "the framework broke six ports" (#181) when the
  // framework had shipped the shim for it in #2707 and this build was simply
  // not running it.
  //
  // Guarded: a pin older than #2707 has no such script, and there the build
  // is what it always was.
  const runtimeShim = path.join(A2, 'node/setup/patch-abaplint-runtime-assign.mjs');
  if (fs.existsSync(runtimeShim)) {
    execSync(`node ${runtimeShim}`, { stdio: 'inherit' });
  } else {
    console.log(`e2e-build: no patch-abaplint-runtime-assign.mjs at this pin - a serializable class with a PRIVATE attribute will 500 on its first roundtrip`);
  }
  console.log('e2e-build: downporting the copy to v702 …');
  for (let i = 0; i < 3; i++) fix(`npx abaplint e2e-downport.jsonc --fix`);
  // the framework's two fixups, done in Node so they are portable (BSD/macOS sed
  // differs from GNU sed on -i and \+): the transpiler can't emit
  // `RAISE EXCEPTION TYPE cx_sy_itab_line_not_found`, so map it to `ASSERT 1 = 0`;
  // then strip trailing whitespace the downport may leave behind.
  for (const f of walk(downport)) {
    if (!f.endsWith('.abap')) continue;
    const fixed = fs.readFileSync(f, 'utf8')
      .replace(/ RAISE EXCEPTION TYPE cx_sy_itab_line_not_found/g, ' ASSERT 1 = 0')
      .replace(/[ \t]+$/gm, '');
    fs.writeFileSync(f, fixed);
  }
  fs.rmSync(cfg, { force: true });

  // 4. transpile the downported copy with the framework's own config — but
  //    against a LOCAL, patched open-abap-core: upstream's
  //    `CALL TRANSFORMATION id ... RESULT XML` writes character data
  //    unescaped, so any app whose model carries a `<` (the overview's
  //    generation notes) produces a draft that CL_IXML cannot parse back and
  //    the next roundtrip dies in an uncatchable ASSERT
  //    ("Network error: ASSERTION_FAILED"). web/ci/patch_open_abap_xml.mjs is
  //    the single source; it must keep that path because abap2UI5/mcp-server
  //    executes it by name (scripts/check-mcp-contract.mjs enforces it).
  const lib = path.join(A2, 'node/open-abap-core');
  if (!fs.existsSync(path.join(lib, 'src'))) {
    fs.rmSync(lib, { recursive: true, force: true });
    console.log('e2e-build: cloning open-abap-core …');
    sh(`git clone --quiet --depth=1 https://github.com/open-abap/open-abap-core ${lib}`);
  }
  patchOpenAbapXml(lib);

  const tcfg = JSON.parse(fs.readFileSync(path.join(A2, 'node/setup/abap_transpile.json'), 'utf8'));
  tcfg.libs = tcfg.libs.map((l) => (l.url?.includes('open-abap-core') ? { folder: '/node/open-abap-core' } : l));
  const tcfgPath = path.join(A2, 'e2e-transpile.json');
  fs.writeFileSync(tcfgPath, JSON.stringify(tcfg, null, 2));

  console.log('e2e-build: transpiling → node/output …');
  sh(`npx abap_transpile ./e2e-transpile.json`);
  fs.rmSync(tcfgPath, { force: true });

  const built = fs.readdirSync(output).filter((f) => /^z2ui5_cl_smpc_app_\d+\.clas\.mjs$/.test(f)).length;
  console.log(`e2e-build: done — ${built} ports transpiled into node/output`);
}

function* walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (isSkippedDir(e.name)) continue;
    if (e.isDirectory()) yield* walk(p);
    else yield p;
  }
}

main();
