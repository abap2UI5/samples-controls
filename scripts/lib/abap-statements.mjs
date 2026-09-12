/* ABAP statements, read the way the compiler cuts them: at a `.` that is not
 * inside a literal, a string template or a comment.
 *
 * Two consumers ask the same question - "how long is this statement" - and
 * neither can answer it from lines: the `statement-too-long` rule in
 * scripts/pattern-lint.mjs (a gate) and scripts/probes/statement-length-probe.mjs
 * (the worksheet a maintainer runs before an activation test). One splitter,
 * so the number the gate fails on is the number the probe prints.
 *
 * What is recognised, and what is deliberately not:
 *   - backtick literals with the doubled-backtick escape, single-quote
 *     literals with the doubled-quote escape;
 *   - string templates `|...|`, including `{ expr }` embedded expressions,
 *     which may themselves hold literals and pipes (`|{ a }|` inside `{ }`
 *     is not attempted - the corpus never nests templates);
 *   - `"` line comments and `*` full-line comments;
 *   - a colon chain (`TYPES: BEGIN OF ..., ... .`) is ONE unit here, ending
 *     at its full stop. The compiler treats it as several statements, but the
 *     only statements long enough to matter are a `VALUE #( )` or a builder
 *     chain, and neither is written with a colon.
 *
 * The offsets are character offsets into `source`; `text` includes the
 * closing full stop and the leading whitespace of the first line.
 */

const BT = String.fromCharCode(96);

/**
 * @param {string} source  the class source
 * @returns {{ start: number, end: number, text: string }[]}
 *   every statement, in order; `end` is the offset of its full stop
 */
export function statements(source) {
  const out = [];
  let start = 0;
  let bt = false;      // inside a `...` literal
  let sq = false;      // inside a '...' literal
  let tpl = false;     // inside a |...| template
  let brace = 0;       // nesting of { } inside a template
  let comment = false; // to the end of the line
  let lineStart = true;
  for (let i = 0; i < source.length; i++) {
    const c = source[i];
    if (comment) {
      if (c === '\n') { comment = false; lineStart = true; }
      continue;
    }
    if (bt) {
      if (c === BT) { if (source[i + 1] === BT) i++; else bt = false; }
      continue;
    }
    if (sq) {
      if (c === "'") { if (source[i + 1] === "'") i++; else sq = false; }
      continue;
    }
    if (tpl && brace === 0) {
      if (c === '|') tpl = false;
      else if (c === '{') brace = 1;
      else if (c === '\\') i++;
      continue;
    }
    if (c === '\n') { lineStart = true; continue; }
    if (lineStart && c === '*') { comment = true; continue; }
    if (c !== ' ' && c !== '\t') lineStart = false;
    if (c === '"') { comment = true; continue; }
    if (c === BT) { bt = true; continue; }
    if (c === "'") { sq = true; continue; }
    if (tpl) {
      if (c === '{') brace++;
      else if (c === '}') brace--;
      continue;
    }
    if (c === '|') { tpl = true; continue; }
    if (c === '.') {
      const text = source.slice(start, i + 1);
      if (text.trim()) out.push({ start, end: i, text });
      start = i + 1;
    }
  }
  return out;
}

/** The name of the METHOD a source offset lies in, or '' outside one. */
export function methodAt(source, offset) {
  const head = source.slice(0, offset);
  const last = [...head.matchAll(/^\s*METHOD\s+(\S+?)\s*\.\s*$/gm)].pop();
  if (!last) return '';
  // an ENDMETHOD after the last METHOD means the offset is between methods
  const endAfter = head.lastIndexOf('ENDMETHOD');
  return endAfter > last.index ? '' : last[1];
}

/** 1-based line number of a character offset. */
export const lineAt = (source, offset) => source.slice(0, offset).split('\n').length;
