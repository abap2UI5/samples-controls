#!/usr/bin/env node
/*
 * NOTE cluster — the 1,900 NOTE deviations sorted by porting idiom.
 *
 * What the question is: a `NOTE` is a deviation that costs the port nothing
 * visible - the corpus decided a rule and this is the rule working (a
 * fragment inlined, a round-trip replaced by an expression binding, a toast
 * composed on the client). `improvised-cluster.mjs` sorts the 160
 * IMPROVISED entries into gap / policy / boundary / rework, because those
 * are where a framework gap hides. The NOTEs are ten times as many and
 * nobody had ever read them as a set: which idioms the corpus leans on, how
 * often, and which ports show each one - the list a guide (`idiom-lookup`)
 * should be citing, and the list a linter rule for a NEW idiom should be
 * measured against before it ships.
 *
 * Why no gate sees it: a NOTE declares nothing a gate checks. It is prose
 * for a reader, and prose clusters only when somebody reads it.
 *
 * What a hit means: nothing by itself - every row here is a decided idiom.
 * What the tail means is the point: an UNCLASSIFIED NOTE is either an idiom
 * this file does not know yet (add the family, so the next probe counts it)
 * or a sentence that is not a NOTE at all (a loss that should be IMPROVISED,
 * a verification that should have been closed).
 *
 * First matching family wins, so the order below IS the classification:
 * narrow, phrase-specific idioms first, the broad ones (dropped attribute,
 * two-way binding) last, so a port is not swallowed by its most generic
 * sentence. Keyed off meta/*.json - the whole corpus by construction; the
 * overview app has no sidecar and quotes every one of these patterns.
 *
 * Run:  node scripts/probes/note-cluster.mjs [--family <key>] [--json] [--strict]
 *       --family  print every NOTE of one family in full
 *       --strict  exit 1 when the UNCLASSIFIED tail is not empty
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const META = path.join(ROOT, 'meta');

// ordered: first match wins
const FAMILIES = [
  // --- records rather than idioms: a verification, a gate declaration ------
  {
    key: 'live-test-closed',
    label: 'a former LIVE_TEST closed by the e2e harness (the text stays verbatim so gate declarations keep matching)',
    re: /\*\*e2e-verified|e2e-verified \d{4}|nightly e2e interaction|meta\/interactions\//i,
  },
  {
    key: 'unverified-wire',
    label: 'a wire still declared unverified in a running system (a LIVE_TEST that was retyped, or never was one)',
    re: /unverified in a running system|not yet run in a system|not yet verified in a (?:running )?system/i,
  },
  {
    key: 'live-check-record',
    label: 'a maintainer live check recorded on the port (what was watched to work, and when)',
    re: /live-verified|live check|maintainer live|verified in a running system|in a real browser/i,
  },
  {
    key: 'diff-declaration',
    label: 'names a structural-diff / data-fidelity finding so the gate reads it as declared (control extra, attr missing, binding value)',
    re: /structural-diff|control extra|control missing|attr missing|binding value|data-fidelity|data_fidelity/i,
  },

  // --- narrow idioms: one phrase, one technique -----------------------------
  {
    key: 'asset-host',
    label: 'asset paths host-absolutized onto sdk.openui5.org (the offline asset-URL rule)',
    re: /host-absolutiz|sdk\.openui5\.org|asset-URL rule|asset URL|test-resources\//i,
  },
  {
    key: 'stylesheet-injected',
    label: 'the sample\'s stylesheet injected through a core:HTML style leaf (custom CSS)',
    re: /core:HTML|style\.css|stylesheet|\bCSS\b|custom style class|styleClass/i,
  },
  {
    key: 'drag-and-drop',
    label: 'drag and drop (DragDropInfo / DropInfo / dnd) rebuilt or reduced',
    re: /drag ?(?:and|&|\/) ?drop|\bdnd\b|DragDropInfo|DragInfo|DropInfo|draggable|droppable/i,
  },
  {
    key: 'lossy-keystroke',
    label: 'a per-keystroke round-trip (liveChange / liveSearch) that is lossy under fast typing, or replaced by a client-side path',
    re: /liveChange|liveSearch|per-keystroke|keystroke|lossy|as the user types/i,
  },
  {
    key: 'timer-delay',
    label: 'a timer / setTimeout / delayed call of the original (busy simulation, auto-close)',
    re: /setTimeout|setInterval|\btimer\b|timeout|delayed|after \d+ ?ms|\bdelay\b/i,
  },
  {
    key: 'odata-replaced',
    label: 'an OData / mock server service replaced by an ABAP table on the default model',
    re: /OData|MockServer|mock server|ODataModel|metadata\.xml|\$metadata/i,
  },
  {
    key: 'routing-collapsed',
    label: 'a Component with a Router and several views collapsed into the one port view',
    re: /\brouting\b|\bRouter\b|\broutes?\b|Component\.js|manifest routing|several views|five views|two views/i,
  },
  {
    key: 'factory-replaced',
    label: 'controls the controller builds in a loop (addItem / factory / createContent) become a bound aggregation with one template',
    re: /factory|addItem\(|createContent|addContent\(|insertContent|built in a loop|in a loop with|client-side control factory|programmatically (?:built|created|added)/i,
  },
  {
    key: 'message-manager',
    label: 'the message> model fed through the z2ui5.cc.MessageManager bridge control',
    re: /MessageManager|message> model|message>\//i,
  },
  {
    key: 'deterministic-random',
    label: 'a randomised original made deterministic (the corpus must stay diffable)',
    re: /Math\.random|randomi[sz]|\brandom\b|deterministic/i,
  },
  {
    key: 'device-media',
    label: 'the device> model / media ranges / phone-vs-desktop switches of the original',
    re: /device>|Device\.system|Device\.media|media range|\bphone\b|\bdesktop\b|sap\.ui\.Device/i,
  },
  {
    key: 'focus-scroll',
    label: 'initial focus, focus moves or scrollTo of the original (client-only, done by frontend action or dropped)',
    re: /\bfocus\b|scrollTo|scrollToElement|scroll position|\bscroll\b/i,
  },
  {
    key: 'named-model-folded',
    label: 'a named model (i18n, a second JSONModel) folded onto the one default model',
    re: /named model|named JSONModel|second model|i18n model|ResourceModel|resource bundle|>\/ prefix|model name/i,
  },
  {
    key: 'element-binding',
    label: 'bindElement / a fixed-index element binding seeded at the default-model root',
    re: /bindElement|element binding|bound to a single record|\/0\b/i,
  },
  {
    key: 'typed-binding',
    label: 'a typed / complex binding (type:, formatOptions, parts) kept as the raw binding string or reduced',
    re: /sap\.ui\.model\.type|typed binding|type:\s*'|formatOptions|composite binding|\bparts:|raw (?:binding )?string|kept as (?:a )?raw/i,
  },
  {
    key: 'formatter-in-abap',
    label: 'a controller formatter moved to ABAP (precomputed field) or to an expression binding',
    re: /\bformatter/i,
  },
  {
    key: 'expression-binding',
    label: 'a controller round-trip replaced by an expression binding ({= …})',
    re: /expression binding|\{=/i,
  },
  {
    key: 'client-toast',
    label: 'a MessageToast composed on the client from event data (control_global MESSAGE_TOAST)',
    re: /toast/i,
  },
  {
    key: 'popup-rebuilt',
    label: 'a Dialog / Popover / ActionSheet fragment rebuilt as a core:FragmentDefinition shown with popup_display / popover_display',
    re: /popup_display|popover_display|popup_destroy|popover_close|Dialog\.fragment|ResponsivePopover|ActionSheet|MessageBox/i,
  },
  {
    key: 'fragment-inlined',
    label: 'a fragment (core:Fragment / Fragment.load) inlined 1:1 into the one port view',
    re: /fragment/i,
  },
  {
    key: 'frontend-action',
    label: 'a controller method call reproduced as a frontend action (follow_up_action, control_by_id, control_global)',
    re: /follow_up_action|control_by_id|control_global|frontend action|cs_event-/i,
  },
  {
    key: 'client-filter-sort',
    label: 'filter / sort / group done on the client through binding_call',
    re: /binding_call|\bfilter(?:ed|ing|s)?\b|\bsort(?:ed|ing|er)?\b|\bgroup(?:ed|ing)?\b/i,
  },
  {
    key: 'empty-vs-default',
    label: 'an initial ABAP field would serialize as "" and override a UI5 property default (enum, absent key)',
    re: /empty string|enum|absent (?:key|field)|property default|falls back to (?:its|the) default/i,
  },
  {
    key: 'payload-unmarshalled',
    label: 'a control-valued event payload (selectedDates, selectedItems, the confirm payload) unmarshalled with z2ui5_cl_ajson',
    re: /z2ui5_cl_ajson|unmarshall|JSON payload|parsed (?:in|by) ABAP/i,
  },
  {
    key: 'a11y-tooltip',
    label: 'an icon-only Button given a tooltip so it is reachable with a screen reader (the one accessibility addition a port makes)',
    re: /icon-only|screen reader|accessibility addition/i,
  },
  {
    key: 'event-arg-expression',
    label: 'an event argument that is a UI5 expression (${$parameters>…}, ${$source>…}, $event.…, an index transported with the event)',
    re: /\$\{\$parameters>|\$\{\$source>|\$event\.|event arg|travels? (?:as|with|through|in) (?:the|an?|one) |indexOfItem|getBindingContext/i,
  },
  {
    key: 'setter-to-binding',
    label: 'a controller setter (setVisible, setProperty, setX) replaced by binding the property: the writer and the reader share one field, the handler is dropped',
    re: /bindable|setProperty|setVisible|is bindable|share(?:s)? (?:one|the same|a) (?:bound )?(?:field|flag|string table)|bound (?:flag|field)|two-way bound/i,
  },
  {
    key: 'namespace-prefix',
    label: 'a control carries a namespace prefix (f:, l:) the original does not, because the merged view has another default xmlns',
    re: /xmlns|namespace prefix|\bprefix\b|f:FlexibleColumnLayout/i,
  },
  {
    key: 'sibling-difference',
    label: 'what this port shares with, or adds over, a sibling sample of the same family (the difference carried literally)',
    re: /sibling|neighbouring sample|same as app|shares? one view|what this sample adds|differs? from (?:the|its)|Same as \w+ but/i,
  },
  {
    key: 'static-view',
    label: 'a static sample: no controller behaviour, no model, no events - view_display and nothing else',
    re: /static sample|no controller|only view_display|there is no model|no model at all|fully static/i,
  },
  {
    key: 'upstream-defect',
    label: 'a defect in the sample itself (a typo, a setter the control does not have, an unwired handler) carried or corrected',
    re: /\btypo\b|does not have|not a controller-method reference|without the leading dot|dead code upstream|upstream (?:bug|defect)|is NOT wired/i,
  },
  {
    key: 'whitespace-text',
    label: 'a text attribute whose line breaks, tabs or entities the XML view normalises differently from an ABAP literal',
    re: /whitespace|line breaks?|&#xA;|\\n and \\t|multi-paragraph|lorem/i,
  },
  {
    key: 'abap-typing',
    label: 'the ABAP type chosen for a value (string vs packed, decfloat34 for epoch milliseconds, a nested structure for an object path)',
    re: /decfloat34|TYPE string|DECIMALS|CONV i|packed|nested (?:ABAP )?structure|typed to|scalar ABAP/i,
  },
  {
    key: 'absolute-binding',
    label: 'a root-level aggregation bound ABSOLUTELY via _bind( path = abap_true ), because a bare path is relative',
    re: /path = abap_true|bound ABSOLUTELY|absolute(?:ly)? (?:bound|binding)/i,
  },
  {
    key: 'dated-correction',
    label: 'a dated record of a correction, restoration or measurement on the port (what changed, and when)',
    re: /(?:corrected|restored|declared|measured|re-?counted|fixed|reworked|rebuilt|reproduced) (?:on )?20\d\d-\d\d-\d\d|since 20\d\d-\d\d-\d\d|until 20\d\d-\d\d-\d\d/i,
  },
  {
    key: 'validation-in-abap',
    label: 'a value-state / validation rule recomputed in ABAP on the same change wire',
    re: /validat|valueState|value state/i,
  },
  {
    key: 'date-handling',
    label: 'dates: sy-datum for today, ISO strings, Date objects the model cannot carry',
    re: /sy-datum|\btoday\b|\bDate\b|DateCreateObject|ISO 8601|yyyy-MM-dd/i,
  },
  {
    key: 'mock-data',
    label: 'the sample\'s mock data moved verbatim (or as a declared subset) into model_init',
    re: /mock|\brows\b|model_init|data\.json|products\.json|verbatim/i,
  },

  // --- broad idioms last: a port lands here only when nothing narrower fits -
  {
    key: 'two-way-binding',
    label: 'an imperative getter/setter pair replaced by a two-way binding',
    re: /two-way|two way|bound two-way|imperative/i,
  },
  {
    key: 'inlined-1to1',
    label: 'a controller-built or sample-local piece inlined 1:1 with nothing else to say',
    re: /inlined|inline|1:1|reproduced/i,
  },
  {
    key: 'dropped-attribute',
    label: 'an attribute, id, wrapper or handler the port drops as inert (dead wire, cosmetic, host chrome)',
    re: /dropped|is not ported|not ported|omitted|left out|has no counterpart|no counterpart/i,
  },
];

const args = process.argv.slice(2);
const strict = args.includes('--strict');
const asJson = args.includes('--json');
const only = args.includes('--family') ? args[args.indexOf('--family') + 1] : null;

const rows = [];
for (const f of fs.readdirSync(META).sort()) {
  if (!f.endsWith('.json')) continue;
  const m = JSON.parse(fs.readFileSync(path.join(META, f), 'utf8'));
  const port = f.replace('z2ui5_cl_smpc_app_', '').replace('.json', '');
  for (const d of m.deviations || []) {
    if (d.type !== 'NOTE') continue;
    const what = String(d.what || '').replace(/\s+/g, ' ');
    const fam = FAMILIES.find((x) => x.re.test(what)) || null;
    rows.push({ port, class: m.class, entity: m.entity, status: m.status, what, family: fam?.key ?? null });
  }
}

const byKey = new Map(FAMILIES.map((f) => [f.key, []]));
const unclassified = [];
for (const r of rows) (r.family ? byKey.get(r.family) : unclassified).push(r);

if (asJson) {
  console.log(JSON.stringify({ total: rows.length, rows, unclassified: unclassified.length }, null, 1));
} else if (only) {
  const fam = FAMILIES.find((f) => f.key === only);
  if (!fam) { console.error(`unknown family '${only}'`); process.exit(2); }
  console.log(`${fam.key} - ${fam.label}\n`);
  for (const r of byKey.get(only)) console.log(`  ${r.port} [${r.status}] ${r.entity}\n    ${r.what}\n`);
} else {
  console.log(`NOTE deviations: ${rows.length} across ${new Set(rows.map((r) => r.port)).size} ports\n`);
  console.log(`${'theme'.padEnd(22)} ${'notes'.padStart(5)} ${'ports'.padStart(5)}  examples`);
  for (const f of FAMILIES) {
    const hits = byKey.get(f.key);
    const ports = [...new Set(hits.map((h) => h.port))];
    console.log(`${f.key.padEnd(22)} ${String(hits.length).padStart(5)} ${String(ports.length).padStart(5)}  ${ports.slice(0, 3).map((p) => `z2ui5_cl_smpc_app_${p}`).join(' ') || '-'}`);
    console.log(`${''.padEnd(22)}              ${f.label}`);
  }
  console.log('');
  if (unclassified.length) {
    console.log(`== UNCLASSIFIED (${unclassified.length}) - add the idiom to FAMILIES, or retype the deviation`);
    for (const r of unclassified) console.log(`   ${r.port} [${r.status}] ${r.entity}\n     ${r.what.slice(0, 300)}${r.what.length > 300 ? '…' : ''}\n`);
  } else {
    console.log('== UNCLASSIFIED: none');
  }
}

if (strict && unclassified.length) {
  console.error(`\nFAIL: ${unclassified.length} NOTE deviation(s) match no family.`);
  process.exit(1);
}
