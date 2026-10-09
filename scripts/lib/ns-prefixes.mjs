/*
 * The canonical XML namespace prefixes of this corpus — AGENTS.md §8, "One
 * canonical prefix per XML namespace, corpus-wide". Majority spelling won
 * each row on 2026-09-12, with one decision: `f` is reserved for sap.f, so
 * sap.ui.layout.form is `form`. pattern-lint's `xmlns-prefix` rule holds
 * every `xmlns:<prefix>` declaration under src/ to this map in BOTH
 * directions — a listed namespace under another prefix, and a listed prefix
 * bound to another namespace — and the tooling tests hold the map to the
 * AGENTS.md table, so the two cannot drift apart.
 *
 * A namespace that is not listed (sap.f.semantic, the SAPUI5-only libraries
 * of src/03, the custom-data URI) is free, as long as it does not borrow a
 * listed prefix.
 */
export const CANONICAL_PREFIX = Object.freeze({
  'sap.m': 'm',
  'sap.ui.core': 'core',
  'sap.ui.core.mvc': 'mvc',
  'sap.ui.layout': 'l',
  'sap.ui.layout.form': 'form',
  'sap.ui.layout.cssgrid': 'grid',
  'sap.ui.integration.widgets': 'w',
  'sap.tnt': 'tnt',
  'sap.ui.unified': 'u',
  'sap.f': 'f',
  'sap.f.cards': 'card',
  'sap.ui.table': 'table',
  'sap.ui.table.rowmodes': 'trm',
  'sap.ui.table.plugins': 'tp',
  'sap.m.plugins': 'plugins',
  'sap.m.table': 'mt',
  'sap.uxap': 'uxap',
});
