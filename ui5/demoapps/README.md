# ui5/demoapps/ — the original demo apps

The UI5 demo kit has two kinds of content, and this folder holds the second
one. `ui5/<library>/<Sample>/` archives a demo kit **sample** — one control,
one view, the thing a port under `src/01` / `src/02` rebuilds 1:1. This folder
archives a demo kit **demo app**: a whole application with several views, a
router, a model layer and an OData mock server, of which OpenUI5 ships eight.
`src/04` rebuilds those, one abap2UI5 class per app (AGENTS §3).

```
ui5/demoapps/<library>/<app folder>/    the original webapp, as upstream has it
```

The path is the app's key in [`../demoapps.json`](../demoapps.json), which is
the snapshot of what the demo kit says about each app (name, description,
category, upstream folder) plus this repository's mapping from a class to the
app it rebuilds. `scripts/fetch-demoapps.mjs` writes that file; the folders
here are copied by hand from the same OpenUI5 checkout.

Held verbatim, exactly like the sample templates next door: never edited to fit
ABAP, and never trimmed to what the rebuild happens to use. The one thing left
out is **binaries** — images, fonts, icon files. A rebuild reads the views, the
controllers, the i18n bundle and the mock data; the pictures only make the
checkout bigger, and no gate here compares them (the demo apps are outside the
sidecar-driven port machinery, so `structural_diff` and `data_fidelity` never
see them at all).

Reading a rebuild is meant to be a side-by-side exercise: the class under
`src/04` next to the app here, the same way the ports read next to their
samples.

Provenance: **SAP/openui5, branch `master`**, the commit
[`ui5/demoapps.json`](../demoapps.json) pins under `source`.
Licence: Apache-2.0 (OpenUI5).
