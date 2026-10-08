# ui5/ — original UI5 demo kit templates

The untouched OpenUI5 demo kit samples (JavaScript / XML view / `manifest.json` /
controllers / resources) that the abap2UI5 ports in `../src/` were rebuilt from.

Each folder is **named after the sample** and filed by source library:

```
ui5/<library>/<SampleName>/     e.g. ui5/sap.m/Button/
```

The join key between a port and its template is `meta/<class>.json` →
`sample` (`sap.m.sample.<SampleName>`). Only **ported** samples are archived —
each new generation batch copies its samples over from the OpenUI5 checkout
(everything the sample's `manifest.json` lists under `sap.ui5 > config >
sample > files`, resolving `../<OtherSample>/` references into that sample's
own folder — which is why a few unported folders like `Table/` exist: they are
referenced by a ported sample). Shared demo kit mock data is snapshotted once
in [`mock/`](mock/) (provenance in its README), and [`universe.json`](universe.json)
is the committed snapshot of the full demo kit sample universe (entity, Since,
deprecation per sample) that coverage regenerates from offline (AGENTS §7).

[`descriptions.json`](descriptions.json) is the third snapshot: the sentence the
demo kit prints under each sample title, for all 800 samples, taken from
`src/<lib>/test/**/demokit/docuindex.json` — which is why copying the sample
FILES here never brought it along. It is what `npm run summary` writes onto the
ports as their `" @summary` line; refresh it with
`npm run descriptions -- --openui5 <checkout>`, and its `source` block records
the OpenUI5 commit the text came from. Its `written` block is the handful of
samples the demo kit does not describe, each with a `why` — that block is NOT
touched by a refresh.

These files are held verbatim for reference and to feed the generator and the
structural diff — they are outside the abapGit / abaplint scope (`src/` only)
and are never edited to fit ABAP. `../api.md` links every sample to its
upstream source in the [OpenUI5 repository](https://github.com/SAP/openui5);
the overview app `../src/z2ui5_cl_smpc_app_000.clas.abap` starts each port
in the system.

## Licence

Everything under `ui5/` is third-party material from
[UI5/openui5](https://github.com/UI5/openui5) — © SAP SE or an SAP affiliate
company and OpenUI5 contributors, licensed under the **Apache License 2.0**.
The full licence text is [`LICENSE`](LICENSE) in this folder, copied verbatim
from OpenUI5 1.152.0. It covers the sample files, the `mock/` snapshots and
the `demoapps/` sources alike: OpenUI5's `REUSE.toml` licenses the whole
repository (`path = "**"`) under Apache-2.0, and none of its third-party
exceptions (`thirdparty/` folders, the ChartJS sample of `sap.ui.mdc`, the
Card Explorer's JSON schema validator) is among the files archived here —
checked against `REUSE.toml` and `THIRDPARTY.txt` of `@openui5/sap.m` 1.152.0
on 2026-10-08. The repository's own MIT licence (`../LICENSE`) does not apply
to this folder.

The files are unmodified apart from the normalisation `mock/README.md`
describes. The ABAP classes under `../src/` are derivative works of them —
each rebuilds the sample named in its `meta/` sidecar in ABAP; the deviations
listed there are the changes. Apache 2.0 grants no trademark rights (§6): the
SAP logos some samples ship (`SAP_Logo.png`, `sap-logo.svg`, …) are archived
only as part of their sample and remain trademarks of SAP SE.
