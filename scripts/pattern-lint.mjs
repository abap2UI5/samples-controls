#!/usr/bin/env node
/*
 * pattern-lint — deterministic gate against re-learning old mistakes.
 *
 * Every rule here encodes a lesson that already bit us once (AGENTS.md §10 /
 * CAPABILITIES.md): once a mistake is understood, it becomes a rule so it can
 * never be merged again — regardless of whether the generator repeats it.
 *
 * SCOPE (since 2026-08-04): only CORPUS-POLICY rules live here — method
 * order, formatting, sidecar conventions, and lessons no generic linter can
 * know. Everything generic moved into @abap2ui5/linter, where every consumer
 * sees it and view-gates gates it for this corpus: popover-display-val,
 * uncurated-formatter, hardcoded-binding-path, obsolete-binder
 * (obsolete-bind-edit), event-arg-unresolved (event-arg-bare-brace),
 * unescaped/collapsed-brace-in-style, invalid-frontend-action
 * (control-by-id-empty-view-slot), binding-type-mismatch
 * (numeric-bound-as-string), relative-binding-without-context
 * (relative-bind-on-root-field), duplicate-for-iterator, ui5-internal-access
 * (private-mproperties) and commercial-ui5-host.
 *
 * The 2026-08-30 round took three more, and one of them is worth reading twice:
 *   redundant-init-display  -> the linter's rule of the same name, in its
 *                              lifecycle family, where it belongs: the fact it
 *                              rests on (check_on_init implies
 *                              check_on_navigated) is a framework fact, not a
 *                              corpus convention.
 *   redundant-conv-i        -> the linter, scope boundaries and all. abap-check
 *                              had it filed as "the finished rule sitting in
 *                              the wrong repository", which it was.
 *   unguarded-date-formatter-> RETIRED, not promoted. The framework closed the
 *                              defect at the source: Formatter.DateCreateObject
 *                              returns null for a falsy input now, and
 *                              isNoAbapDate rejects anything that is not eight
 *                              digits, so the empty-seed case can no longer
 *                              produce an Invalid Date and a rule for it would
 *                              report correct code. What IS still live is the
 *                              TYPE mismatch — an ABAP `TYPE d` reaches the
 *                              model as `20240101`, which new Date( ) does not
 *                              parse either — and the linter carries that as
 *                              abap-date-formatter-mismatch.
 *
 * The 2026-09-12 round promoted five more into the linter - unbound-public-
 * attribute, default-key-table, abapdoc-html-tag, event-arg-default-index and
 * client-handle-capture (abap2UI5/linter commit 7174bae, unreleased at the
 * time of writing) - and taught event-without-handler the single-branch IF
 * dispatcher form that dead-event-wire existed to know. All six rules STAY
 * here until the linter release carrying them reaches package-lock.json and
 * view_gates gates them; the bump PR deletes them from this file in the same
 * change (one rule set, two enforcement points is the drift this header
 * warns against, and a week of it is the price of not gating on a release).
 * Two of the promoted rules found what the copies here missed: the path
 * regex of unbound-public-attribute matched inside a comment (apps 557/607),
 * and client-handle-capture never saw the plain assignment form.
 *
 * Do NOT re-add a rule here that the linter can express — one rule set, two enforcement
 * points was exactly how the editor and CI drifted apart before.
 *
 * The 2026-09-12 round added five, every one of them corpus policy and none
 * of them a fact about abap2UI5 views:
 *   statement-too-long        -> a statement budget the kernel enforces and
 *                                nobody offline can measure (see the constant)
 *   unrolled-chain-repetition -> the same chain line dozens of times in one
 *                                method: a subtree that wanted a binding
 *   types-layout              -> one of the two TYPES layouts the corpus had
 *                                mixed (140 vs 167 classes), now the two-line one
 *   hungarian-prefix          -> §8's "prefix only t_ and s_", enforced
 *   line-headroom             -> a line within 15 characters of abaplint's 255
 * and promoted the three layout rules (no-blank-before-end, blank-between-ends,
 * param-continuation-align) from warn to error: their 382 findings were cleared
 * the day before, and a warning nobody fails on is how they had accumulated.
 *
 * Levels: 'error' rules fail the run (exit 1) unless the exact file is listed
 * in BASELINE (a known, still-open backlog finding — see STATUS.md); 'warn'
 * rules are reported but never fail. When a baselined finding is fixed, its
 * BASELINE entry must be removed in the same change (stale entries are
 * reported).
 *
 * Run:  node scripts/pattern-lint.mjs
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { walkFiles } from './lib/src-tree.mjs';
import { statements, methodAt } from './lib/abap-statements.mjs';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const SRC = path.join(ROOT, 'src');

/* statement-too-long: the budget, in characters of source, for ONE statement.
 *
 * UNMEASURED. ABAP's maximum statement length is enforced by the kernel at
 * activation and is written down nowhere anyone here can read; the linters
 * do not model it, the transpiler does not model it, and a port that crosses
 * it looks fine in every gate until a human pulls it into a system. The two
 * data points the repository has (regenerate-artefacts guide, 2026-08):
 *   ~226,000  a single VALUE #( ) FAILED on a real system - the overview
 *             app's catalogue, since chunked at CHUNK_CHARS 3000 in
 *             scripts/lib/overview-emit.mjs
 *    73,997   app 012's model_init PASSES - status `checked`, live-verified;
 *             app 033's 63,234-character one likewise
 * So the budget sits just above the largest LIVE-VERIFIED statement, and
 * what it fails is exactly what nothing has ever seen activate: a port whose
 * whole view chain is one statement (app 599 at ~182,000 characters, app 592
 * at ~83,000 on 2026-09-12 - the unroll sweep is bringing them down). Raise
 * it only with a new live data point, never to let a port through;
 * scripts/probes/statement-length-probe.mjs lists what an activation test
 * has to cover. */
const STATEMENT_BUDGET = 75000;

/* unrolled-chain-repetition: how often the same chain line (backtick literals
 * replaced by a placeholder) may recur inside ONE method before it reads as an
 * unrolled loop - a bound aggregation with one template, or a helper per
 * subtree, is what a repeated subtree wants. 40 is the 2026-09-12 first cut;
 * `)->end(` lines are not counted, they carry no content. */
const REPEAT_BUDGET = 40;

/* line-headroom: abaplint holds a line to 255 characters (`line_length`), and
 * a padded VALUE #( ) row that sits within 15 of it breaks on the next field
 * that grows by a word. Code lines only: the generated `" @summary` /
 * `" @origin` header comments are clipped to 255 by their own generators
 * (`clipAtWord`, generate-summary / generate-origin) and nothing grows them. */
const LINE_HEADROOM = 240;

/* hungarian-prefix: the SAP-classic prefixes AGENTS §8 retired ("prefix only
 * tables t_ and structures s_"). `is_` / `es_` are judged on PARAMETERS only:
 * `DATA(is_selected)` is a boolean's English name, not a prefix. */
const HUNGARIAN = '(?:lv|lt|ls|iv|ev|rv|cv|it|et)_\\w+';
const HUNGARIAN_PARAM = '(?:lv|lt|ls|iv|ev|rv|cv|it|et|is|es)_\\w+';

// known, still-open findings (tracked in STATUS.md) — 'rule-id|repo-relative-file'
// empty since 2026-07-28: the six dead-event-wire entries of the review sweep
// (138/143/145/146/148/150) were reworked, so the rule now stands on its own
const BASELINE = new Set([]);

const lineOf = (content, idx) => content.slice(0, idx).split('\n').length;

// the backtick, and the VALUE #( ) row/cell shapes ragged-value-table judges -
// built once here; they used to be rebuilt for every file the rule visited
const BT = String.fromCharCode(96);
const VALUE_ROW = new RegExp('^(\\s*)\\(((?: [a-z_0-9]+ = (?:' + BT + '[^' + BT + ']*' + BT + '|[^\\s()]+))+) \\)(.*)$');
const VALUE_CELL = new RegExp('([a-z_0-9]+) = (' + BT + '[^' + BT + ']*' + BT + '|[^\\s()]+)', 'g');

const RULES = [
  {
    id: 'event-arg-default-index',
    level: 'error',
    doc: 'get_event_arg( 1 ) spells out the default — simplest notation is get_event_arg( ); only pass an index for position 2+ (AGENTS §8)',
    find: grepLines(/get_event_arg\(\s*1\s*\)/),
  },
  {
    id: 'main-not-first',
    level: 'error',
    doc: 'z2ui5_if_app~main must be the FIRST method in the implementation; the rest follow in call order from main (AGENTS §5)',
    portsOnly: true,
    find(content) {
      const impl = content.split(/^CLASS \w+ IMPLEMENTATION\.$/m)[1] || '';
      const first = impl.match(/^  METHOD (\S+)\./m);
      if (first && first[1] !== 'z2ui5_if_app~main') {
        return [{ line: lineOf(content, content.indexOf(first[0])), text: `first method is ${first[1]}` }];
      }
      return [];
    },
  },
  {
    id: 'model-init-last',
    level: 'error',
    doc: 'model_init holds the mock-data VALUE #( ) block and must be the LAST method in the implementation so it never interrupts the reading flow of the dispatcher/view/event methods above it (AGENTS §5)',
    portsOnly: true,
    find(content) {
      const impl = content.split(/^CLASS \w+ IMPLEMENTATION\.$/m)[1] || '';
      const names = [...impl.matchAll(/^  METHOD (\S+)\./gm)].map((x) => x[1]);
      const mi = names.indexOf('model_init');
      if (mi !== -1 && mi !== names.length - 1) {
        return [{ line: lineOf(content, content.indexOf('  METHOD model_init.')),
                  text: `model_init is followed by ${names.slice(mi + 1).join(', ')}` }];
      }
      return [];
    },
  },
  {
    id: 'abapdoc-html-tag',
    level: 'error',
    doc: 'raw <tag> inside ABAP Doc ("!) — ABAP Doc is parsed as HTML; write it plain — AGENTS §8/§10',
    find: grepLines(/^"!.*<[a-zA-Z][^ >]*>/),
  },
  {
    id: 'header-in-port',
    level: 'error',
    doc: 'port classes carry no ABAP Doc header — sample/entity/status/checked/deviations live in meta/<class>.json (AGENTS §5)',
    portsOnly: true,
    find: grepLines(/^"!/),
  },
  {
    id: 'client-handle-capture',
    level: 'error',
    doc: 'client handle strings (_event, _bind, _event_client, ...) are written inline at each control, never captured in a variable - even when repeated, even in expression bindings (human decision 2026-07-17, apps 005/053/007)',
    find: grepLines(/DATA\(\w+\)\s*=\s*client->_\w+\(/),
  },
  {
    id: 'default-key-table',
    level: 'error',
    doc: 'bare `TYPE TABLE OF` gives an implicit default key — declare it explicitly as `TYPE STANDARD TABLE OF ... WITH EMPTY KEY` (AGENTS §8; slipped the abaplint defaultKey gate, which only catches explicit DEFAULT KEY, in app 034)',
    find: grepLines(/\bTYPE\s+TABLE\s+OF\b/),
  },
  {
    id: 'clear-statement',
    level: 'error',
    portsOnly: true,
    doc: 'reset with `x = VALUE #( ).`, never CLEAR (AGENTS §8) - the sentence stood unenforced while 70 CLEARs in 43 ports accumulated (swept 2026-09-11)',
    find: grepLines(/^\s*CLEAR\b/),
  },
  {
    id: 'unbound-public-attribute',
    level: 'error',
    portsOnly: true,
    doc: 'a PUBLIC DATA that no binding reaches (_bind( ), b = , a {/NAME} path) belongs in PROTECTED: the round-trip model scan walks every public instance attribute and the draft persists it, so a helper/backup kept public only costs (port-a-sample "Class layout"; 38 such attributes in 23 ports were moved 2026-09-11). A linter candidate - the fact it rests on is a framework fact',
    find(content) {
      const [def, impl = ''] = content.split(/^CLASS \w+ IMPLEMENTATION\.$/m);
      const pub = (def.match(/PUBLIC SECTION\.([\s\S]*?)(PROTECTED SECTION\.|PRIVATE SECTION\.|ENDCLASS)/) || [])[1] || '';
      const out = [];
      for (const m of pub.matchAll(/^\s*DATA\s+(\w+)\s/gm)) {
        const n = m[1];
        if (n.toLowerCase() === 'client') continue;
        // the binding forms: an argument of a _bind*( ) call (one level of
        // nested parentheses, for _bind( val = x ... )), a boolean a( b = x ),
        // or the attribute named as a model path anywhere in the class
        const bindCall = new RegExp(`_bind(_\\w+)?\\(([^()]|\\([^()]*\\))*\\b${n}\\b`, 'i');
        const bBool = new RegExp(`\\bb\\s*=\\s*${n}\\b`, 'i');
        const pathStr = new RegExp(`[{/]${n}[}/\\s'\`]|/${n}$`, 'i');
        if (bindCall.test(impl) || bBool.test(impl) || pathStr.test(content)) continue;
        out.push({ line: lineOf(content, content.indexOf(m[0])), text: `${n} is public but never bound` });
      }
      return out;
    },
  },
  {
    id: 'param-continuation-align',
    level: 'error',
    doc: 'a t_arg continuation line must start in the same column as the val parameter above it — human-taught alignment fix, 2026-07-16 (apps 007/008)',
    find(content) {
      const out = [];
      const lines = content.split('\n');
      lines.forEach((l, i) => {
        const m = l.match(/^(\s+)t_arg =/);
        if (!m || i === 0) return;
        const vm = lines[i - 1].match(/^(.*?)\bval\s+=/);
        if (vm && m[1].length !== vm[1].length) {
          out.push({ line: i + 1, text: `t_arg at col ${m[1].length + 1}, val at col ${vm[1].length + 1}` });
        }
      });
      return out;
    },
  },
  {
    id: 'blank-between-ends',
    level: 'error',
    doc: 'blank line between two )->end( lines — §5 formatting: none after an end or between ends (a blank before the next ele/tag sibling block is fine)',
    find(content) {
      const out = [];
      for (const m of content.matchAll(/->end\(\s*\n[ \t]*\n[ \t]*\)->end\(/g)) {
        out.push({ line: lineOf(content, m.index), text: 'blank line separating two ends' });
      }
      return out;
    },
  },
  {
    id: 'no-blank-before-end',
    level: 'error',
    doc: 'a )->end( must be preceded by a blank line (or another end) — §5 formatting: a blank before every end',
    find(content) {
      const out = [];
      const lines = content.split('\n');
      lines.forEach((l, i) => {
        if (!/->end\(\s*\)?\.?\s*$/.test(l)) return;
        const prev = lines[i - 1] ?? '';
        if (prev.trim() !== '' && !/->end\(/.test(prev)) {
          out.push({ line: i + 1, text: `preceded by: ${prev.trim().slice(0, 60)}` });
        }
      });
      return out;
    },
  },
  {
    id: 'dead-event-wire',
    level: 'error',
    doc: 'client->_event( … ) wired in the view but the class has no on_event/check_on_event dispatcher — the event fires a round-trip that no branch handles (dead wire; the 2026-07-27 review sweep found 8 such ports in the b05-b07 stress batches). Either dispatch it or drop the wire for a bindable property.',
    find(content) {
      const out = [];
      if (!/INTERFACES\s+z2ui5_if_app/i.test(content)) return out; // ports only
      if (!/->_event\(/.test(content)) return out;
      if (/on_event/.test(content)) return out; // matches check_on_event too
      /* A class may also dispatch inline, straight off the event name — the
       * samples style, which the src/03 SAPUI5 collection is written in
       * (AGENTS §3). Both shapes are a dispatcher, so the wire is not dead:
       *   CASE client->get_event( ).  WHEN `X`.        two or more events
       *   IF client->get_event( ) = `X`.               exactly one
       * The IF form is not a style choice — abaplint's `short_case` requires
       * it from a single-branch CASE (2026-08-16), so a one-event class can
       * no longer be written with WHEN at all. Ports still have to use
       * on_event, which the method-order rules below enforce for them.
       * `get( )-event` is the pre-2026-08-16 spelling of `get_event( )` and
       * is matched too: the corpus no longer contains it, but a hand-written
       * class or an older branch may. */
      const EVENT_READ = /get_event\(\s*\)|get\(\s*\)-event/;
      if (EVENT_READ.test(content) && /\bWHEN\b/.test(content)) return out;
      if (new RegExp('IF\\s+[^\\n]*(?:' + EVENT_READ.source + ')\\s*=').test(content)) return out;
      const m = content.match(/->_event\(/);
      out.push({ line: lineOf(content, m.index), text: '_event( ) wired but no on_event/check_on_event dispatcher and no CASE or IF on get_event( )' });
      return out;
    },
  },
  {
    // A mock table is read as a table, so its columns have to line up.
    // scripts/json-to-abap.mjs emits the padded form; this catches a
    // hand-written or hand-edited block that drifted. Only tables whose rows
    // carry the SAME field list are judged — where one row has a field the
    // next does not (an optional key, a nested child table) there is no column
    // to align. A block that would break the 255-character limit once padded
    // is wrapped by hand instead and is left alone here.
    id: 'ragged-value-table',
    level: 'error',
    doc: 'VALUE #( ) rows with the same field list are padded into columns, the last cell of a row unpadded (AGENTS §5); node scripts/json-to-abap.mjs emits that form',
    find(content) {
      const parse = (l) => {
        const m = l.match(VALUE_ROW);
        if (!m) return null;
        const cells = [...m[2].matchAll(VALUE_CELL)].map((c) => [c[1], c[2]]);
        return cells.length ? { indent: m[1], cells, suffix: m[3] } : null;
      };
      const L = content.split('\n');
      const out = [];
      let blk = [];
      const flush = () => {
        if (blk.length >= 3) {
          const rows = blk.map((i) => parse(L[i]));
          const keys = rows[0].cells.map((c) => c[0]).join('|');
          if (rows.every((r) => r.cells.map((c) => c[0]).join('|') === keys)) {
            const w = rows[0].cells.map((_, j) =>
              Math.max(...rows.map((r) => (r.cells[j][0] + ' = ' + r.cells[j][1]).length)));
            const built = rows.map((r) => r.indent + '( ' + r.cells
              .map(([k, v], j) => (j === r.cells.length - 1 ? k + ' = ' + v : (k + ' = ' + v).padEnd(w[j])))
              .join(' ') + ' )' + r.suffix);
            if (built.every((b) => b.length <= 255) && built.some((b, i) => b !== L[blk[i]])) {
              out.push({ line: blk[0] + 1, text: `${blk.length} rows of ${rows[0].cells.length} fields are not column-aligned` });
            }
          }
        }
        blk = [];
      };
      for (let i = 0; i < L.length; i++) { if (parse(L[i])) blk.push(i); else flush(); }
      flush();
      return out;
    },
  },
  {
    // Two parameters are not a reason for two lines. Outside the view chain,
    // which has its own layout, a statement that fits the budget is written on
    // one line — popover_display was split in all 35 of its call sites while
    // popup_display, its shorter sibling, was split in none of 43.
    // A wrapped t_arg list is deliberately exempt: it stays wrapped.
    id: 'stacked-short-call',
    level: 'error',
    doc: 'a statement outside the view chain that fits in 120 characters is written on ONE line (AGENTS §5)',
    find(content) {
      const BUDGET = 120;
      const balanced = (s) => {
        let par = 0, bt = 0, pipe = 0;
        for (const ch of s) {
          if (ch === BT) bt++;
          else if (ch === '|') pipe++;
          else if (bt % 2 === 0 && pipe % 2 === 0) { if (ch === '(') par++; else if (ch === ')') par--; }
        }
        return par === 0 && bt % 2 === 0 && pipe % 2 === 0;
      };
      const squeeze = (s) => {
        let o = '', bt = false, pipe = false;
        for (const ch of s) {
          if (ch === BT) bt = !bt; else if (ch === '|') pipe = !pipe;
          if (ch === ' ' && !bt && !pipe && o.endsWith(' ')) continue;
          o += ch;
        }
        return o;
      };
      const forbidden = (l) => {
        const s = l.trim();
        if (!s || s.startsWith('"') || s.startsWith('*')) return true;
        if (l.includes('"')) return true;
        if (l.includes(')->') || l.includes('->a(') || l.includes('->ele(') || l.includes('->tag(')) return true;
        if (l.includes('t_arg')) return true;
        // the SECTIONS of a classic or RAP statement carry meaning stacked
        if (/\b(EXPORTING|IMPORTING|CHANGING|EXCEPTIONS|RECEIVING|TABLES|FAILED|REPORTED|MAPPED|RESPONSE|ENTITIES|ENTITY)\b/.test(l)) return true;
        // a string template split with && is a deliberate break for a long
        // literal - joined, abaplint then demands reduce_string_templates
        if (/&&\s*$/.test(l) || /^\s*&&/.test(l)) return true;
        if (/^\s*\( [a-z_0-9]+ = /.test(l)) return true;
        if (l.includes('VALUE #( (')) return true;
        return false;
      };
      const L = content.split('\n');
      const out = [];
      for (let i = 0; i < L.length; i++) {
        const a = L[i];
        const t = a.trim();
        if (forbidden(a) || t.endsWith('.') || !t.includes('(')) continue;
        for (const span of [2, 3]) {
          if (i + span > L.length) break;
          const block = L.slice(i, i + span);
          if (block.some(forbidden)) continue;
          if (block.slice(0, -1).some((l) => l.trim().endsWith('.'))) continue;
          if (!block[span - 1].trim().endsWith('.')) continue;
          const text = squeeze(block.map((l) => l.trim()).join(' '));
          if (!balanced(text)) continue;
          const line = ' '.repeat(a.length - a.trimStart().length) + text;
          if (line.length > BUDGET) continue;
          out.push({ line: i + 1, text: `${span} lines, ${line.length} characters on one — ${line.trim().slice(0, 70)}` });
          i += span - 1;
          break;
        }
      }
      return out;
    },
  },
  {
    id: 'statement-too-long',
    level: 'error',
    doc: `a single ABAP statement over ${STATEMENT_BUDGET} characters — the kernel's limit is unmeasured, the largest live-verified statement is ~74k (see STATEMENT_BUDGET); split it: a VALUE #( BASE … ) append, a bound aggregation with one template, a helper per subtree`,
    find(content) {
      const out = [];
      for (const s of statements(content)) {
        const text = s.text.trim();
        if (text.length <= STATEMENT_BUDGET) continue;
        const at = s.start + (s.text.length - s.text.trimStart().length);
        out.push({ line: lineOf(content, at),
                   text: `${methodAt(content, at) || 'outside a method'}: ${text.length} characters, ${text.split('\n').length} lines` });
      }
      return out;
    },
  },
  {
    id: 'unrolled-chain-repetition',
    level: 'warn',
    doc: `the same chain line (literals ignored) more than ${REPEAT_BUDGET} times in one method reads as an unrolled loop — bind the repeated subtree to a table with one template, or build it in a helper (AGENTS §8)`,
    find(content) {
      const out = [];
      let method = null;
      let counts = new Map();
      const flush = () => {
        for (const [key, e] of counts) {
          if (e.n > REPEAT_BUDGET) out.push({ line: e.first, text: `${method}: ${e.n} x ${key.slice(0, 70)}` });
        }
        counts = new Map();
      };
      content.split('\n').forEach((l, i) => {
        const m = l.match(/^\s*METHOD\s+(\S+?)\s*\.\s*$/);
        if (m) { method = m[1]; return; }
        if (/^\s*ENDMETHOD\s*\./.test(l)) { flush(); method = null; return; }
        if (!method || !l.includes(')->') || /\)->end\(/.test(l)) return;
        const key = l.trim().replace(/`(?:``|[^`])*`/g, '`~`');
        const e = counts.get(key) || { n: 0, first: i + 1 };
        e.n += 1;
        counts.set(key, e);
      });
      return out;
    },
  },
  {
    // The corpus carried both layouts for a structure type - 140 classes with
    // `TYPES:` alone on its line and `BEGIN OF` on the next, 167 with the two
    // on one line, three mixing them (2026-09-12). One layout, the two-line
    // one, which is what the style sweep and the three emitters now write.
    id: 'types-layout',
    level: 'error',
    doc: 'a structure type opens on two lines — `TYPES:` alone, then `BEGIN OF ty_s_x,` on the next (AGENTS §8); `TYPES: BEGIN OF` on one line is the other layout the corpus mixed until 2026-09-12',
    find: grepLines(/^\s*TYPES:?\s+BEGIN OF\b/),
  },
  {
    id: 'hungarian-prefix',
    level: 'error',
    doc: 'locals and parameters carry no Hungarian prefix — only tables are t_ and structures s_ (AGENTS §8); lv_/lt_/ls_/iv_/ev_/rv_/cv_/it_/et_ (and is_/es_ on a parameter) are the SAP-classic prefixes the guide retired',
    find(content) {
      const out = [];
      const seen = new Set();
      const hit = (idx, name) => {
        const key = `${idx}|${name}`;
        if (seen.has(key)) return;
        seen.add(key);
        out.push({ line: lineOf(content, idx), text: name });
      };
      // declarations: DATA(x) / FINAL(x) / DATA x / DATA: x / FOR x IN
      const DECL = new RegExp(`\\b(?:DATA|FINAL)\\(\\s*(${HUNGARIAN})\\s*\\)|^\\s*DATA:?\\s+(${HUNGARIAN})\\b|\\bFOR\\s+(${HUNGARIAN})\\s+IN\\b`, 'gmi');
      for (const m of content.matchAll(DECL)) hit(m.index, m[1] || m[2] || m[3]);
      // parameters: every `name TYPE` / `VALUE(name)` inside a METHODS statement
      const PARAM = new RegExp(`\\b!?(${HUNGARIAN_PARAM})\\s+(?:TYPE|LIKE)\\b|\\bVALUE\\(\\s*(${HUNGARIAN_PARAM})\\s*\\)`, 'gi');
      for (const m of content.matchAll(/^\s*(?:CLASS-)?METHODS\s+[\s\S]*?\.[ \t]*$/gm)) {
        for (const p of m[0].matchAll(PARAM)) hit(m.index + p.index, p[1] || p[2]);
      }
      return out;
    },
  },
  {
    id: 'line-headroom',
    level: 'warn',
    doc: `a line over ${LINE_HEADROOM} characters sits within ${255 - LINE_HEADROOM} of abaplint's 255 hard limit — re-wrap the padded VALUE row at the same field boundary in EVERY row (AGENTS §8; app 571 is the reference)`,
    find(content) {
      const out = [];
      content.split('\n').forEach((l, i) => {
        if (l.length > LINE_HEADROOM && !/^\s*"/.test(l)) out.push({ line: i + 1, text: `${l.length} characters` });
      });
      return out;
    },
  },
];

function grepLines(re) {
  return (content) => {
    const out = [];
    content.split('\n').forEach((l, i) => {
      if (re.test(l)) out.push({ line: i + 1, text: l.trim().slice(0, 90) });
    });
    return out;
  };
}

let errors = 0;
let warns = 0;
const seenBaseline = new Set();

// abapGit XML files MUST start with the UTF-8 BOM — abapGit serializes them
// that way, and BOM-less files break the format on the system pull (four
// crept in via agent-written files; human fix PR #38, 2026-07-27). The
// scaffolder and generate-overview both emit the BOM; this gates hand-written
// ones. Checked bytewise, outside the .clas.abap rule loop.
for (const f of walkFiles(SRC, '.xml')) {
  const rel = path.relative(ROOT, f).split(path.sep).join('/');
  const b = fs.readFileSync(f);
  if (!(b[0] === 0xEF && b[1] === 0xBB && b[2] === 0xBF)) {
    console.log(`ERROR ${rel}:1 [abapgit-xml-bom] file does not start with the UTF-8 BOM`);
    console.log('      abapGit XML must begin with EF BB BF — copy a reference clas.xml byte-exactly (PR #38 lesson, 2026-07-27)');
    errors++;
  }
}

for (const f of walkFiles(SRC, '.clas.abap')) {
  const rel = path.relative(ROOT, f).split(path.sep).join('/');
  const isPort = /^src\/\d+\/\d+\/[^/]+$/.test(rel);
  const content = fs.readFileSync(f, 'utf8');
  for (const rule of RULES) {
    if (rule.portsOnly && !isPort) continue;
    const hits = rule.find(content);
    if (!hits.length) continue;
    const key = `${rule.id}|${rel}`;
    if (rule.level === 'error' && BASELINE.has(key)) {
      seenBaseline.add(key);
      console.log(`BASELINE ${rel} [${rule.id}] ${hits.length} known finding(s), tracked in STATUS.md`);
      continue;
    }
    for (const h of hits) {
      console.log(`${rule.level.toUpperCase()} ${rel}:${h.line} [${rule.id}] ${h.text}`);
      console.log(`      ${rule.doc}`);
      if (rule.level === 'error') errors++; else warns++;
    }
  }
}

for (const key of BASELINE) {
  if (!seenBaseline.has(key)) {
    console.log(`STALE baseline entry no longer matches — remove it: ${key}`);
  }
}

// The generation prompt has to speak the builder the corpus is written in.
// It fell a rename behind once: the ports moved from z2ui5_cl_ai_xml to
// z2ui5_cl_ui5_view_builder and its open( )/leaf( )/shut( ) became
// ele( )/tag( )/end( ), but the prompt kept teaching the old three — and it
// is not only read here, mcp-server serves it to agents as `generation_rules`
// (see check-mcp-contract.mjs). Every port generated from it would have been
// written against methods that do not exist, and nothing said so.
const PROMPT = path.join(ROOT, 'scripts', 'generation-prompt.txt');
const RETIRED_VERBS = ['open', 'leaf', 'shut'];
if (fs.existsSync(PROMPT)) {
  const prompt = fs.readFileSync(PROMPT, 'utf8');
  const rel = path.relative(ROOT, PROMPT).split(path.sep).join('/');
  for (const verb of RETIRED_VERBS) {
    // the call shape only — `open the mvc:View` is prose, `open( ` is a claim
    const re = new RegExp(`\\b${verb}\\s*\\(`, 'g');
    for (const m of prompt.matchAll(re)) {
      console.log(`ERROR ${rel}:${lineOf(prompt, m.index)} [prompt-builder-verb] ${verb}( ) is not a method of z2ui5_cl_ui5_view_builder`);
      console.log('      the builder is ele( ) / tag( ) / a( ) / end( ) — the prompt is also served to agents as mcp-server generation_rules');
      errors++;
    }
  }
  for (const verb of ['ele', 'tag', 'end']) {
    if (!new RegExp(`\\b${verb}\\s*\\(`).test(prompt)) {
      console.log(`ERROR ${rel}:1 [prompt-builder-verb] the prompt never mentions ${verb}( )`);
      console.log('      it has to teach the four verbs the corpus is written in');
      errors++;
    }
  }
}

console.log(`\npattern-lint: ${errors} error(s), ${warns} warning(s), ` +
  `${seenBaseline.size}/${BASELINE.size} baseline entries matched.`);
process.exit(errors ? 1 : 0);
