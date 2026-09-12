/* Cut a text to a length at a WORD boundary, and say so.
 *
 * Two generated strings in this repository have a hard length: the abapGit
 * `<DESCRIPT>` (60 characters, what ADT's object list shows) and the
 * `" @summary` line (255, abaplint's line limit). Both were being cut by
 * `slice(0, n)` somewhere - and a slice does not know what a word is, so 27
 * sidecars read `sap.m.Input - This example shows different input value state`
 * and a reader could not tell a clipped title from a finished one.
 *
 * One function, so the two places (and scripts/scaffold.mjs, which writes
 * the DESCRIPT for every new port) cut the same way: at the last space that
 * leaves room for the marker, marker appended, never mid-word. A text that
 * fits comes back untouched. A text with no space early enough is cut hard
 * and still marked - half a word with `...` is honest, a full word that is
 * not the last one is not.
 *
 *   clipAtWord('sap.m.Input - This example shows different input value states', 60)
 *   -> 'sap.m.Input - This example shows different input value...'
 */

/**
 * @param {string} text
 * @param {number} max       the hard length, inclusive
 * @param {string} [marker]  appended when something was cut
 * @returns {string}         `text` if it fits, else at most `max` characters
 */
export function clipAtWord(text, max, marker = '...') {
  const s = String(text ?? '');
  if (s.length <= max) return s;
  const room = Math.max(0, max - marker.length);
  const head = s.slice(0, room + 1);       // one more, so a space AT the cut counts
  const space = head.lastIndexOf(' ');
  const cut = space > 0 ? space : room;
  return `${s.slice(0, cut).replace(/[\s.,;:-]+$/, '')}${marker}`;
}
