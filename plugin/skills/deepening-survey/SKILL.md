---
name: deepening-survey
description: >
  Use when asked to find deepening opportunities, survey a codebase for shallow
  modules, ask "where is our abstraction leaking?", "which modules are carrying
  their weight?", or "how do we make an upcoming change easy?". Also use before a
  large build to find the structure that would make it cheap. Depth 2 — investigate.
  Surveys for shallow modules (a wide interface hiding little implementation),
  measures each candidate with simulate before proposing it, and stops with a ranked
  candidate list. Proposes; never edits code.
---

# Deepening Survey

**Depth:** Level 2 (Investigate). **Tier:** Architecture (`simulate`,
`analyze_interface_bloat`, `analyze_cohesion`, `analyze_chokepoints` all enforce it).

See `../analysis-protocol/references/protocol.md` for artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and the
Shared Interpretation Rules. Read that document before proceeding.

## What this skill is

A **survey**, not a refactor. It finds modules that pay for themselves poorly —
a wide interface in front of little implementation — proposes the deepening that
would fix each one, and stops. No file is edited during a run. The only writes are
the run artifacts and the project-map ledger.

The output is a ranked candidate list where **every candidate carries a measured
delta**, not an argued one. A proposal that cannot be measured is reported as
unverified, and a proposal the measurement contradicts is reported as refuted.
Execution belongs to the `architectural-refactoring` skill, which owns
`remediation-log.md`.

## Vocabulary

This skill uses one consistent vocabulary. Use these words in every candidate;
do not drift into "component", "service", "layer", or "API".

| Term | Meaning here | How it is measured |
|------|--------------|--------------------|
| **module** | A file (or directory) that hides an implementation behind a callable surface | the unit `analyze_clusters` and `analyze_coupling` report on |
| **interface** | The symbols outside code actually calls — not what is declared public | `analyze_thickness` `interface_width`; `analyze_surface` at a multi-file boundary |
| **implementation mass** | How much behaviour sits behind that interface | `analyze_thickness` `implementation_mass` (statements) |
| **thickness** | implementation mass ÷ interface width. High = a lot hidden behind a little. Low = shallow | `analyze_thickness` `thickness` |
| **shallow module** | Low thickness with non-trivial mass: the interface costs nearly as much to learn as the code it hides | `analyze_thickness` `class: shallow` |
| **seam** | A narrow point where two groups of modules communicate | `analyze_seams` read through `analyze_clusters` |
| **locality** | How much of one concept lives in one place | `analyze_cohesion` LCOM4 `components`; `analyze_orphan_types` |
| **leverage** | How much future change one deepening buys | `churn_hotspots` × the simulated delta |
| **the deletion test** | Would removing this module concentrate behaviour, or just push it to callers? | `simulate` `delete_module` — see Phase 3 |

**Naming warning — do not write "depth" for thickness.** act101 already ships
`analyze_depth`, which computes the **longest transitive dependency chain per file**.
That is a different quantity. In this skill, and in every report it writes, the
interface-versus-implementation quality is called **thickness**; the word "depth"
refers only to chain length and to the protocol's investigation depth levels.

## Phase 0: Scope and prior state

**Scope before you scan.** A deepening pays off only where change lands, so decide
where to look before looking:

1. If the operator named a direction — a module, a subsystem, an upcoming build, a
   pain point — take it and skip the inference. Pointing this skill at planned work
   ("how do we make this change easy?") produces the most actionable report.
2. Otherwise use `churn_hotspots` in workspace mode to rank where the codebase is
   actually moving, and let those paths pull the survey first. If churn is flat with
   no concentration, widen to the whole workspace and say so in the report.
3. Use `include` / `exclude` on every analyzer to hold the scope. Report the scope
   in `manifest.json`.

**Read the prior ledger.** If `project-map.md` exists at the workspace root, read
its `## Refuted & Re-characterized Findings` ledger first (protocol mandate for
depth-2+ skills). A candidate already refuted does not come back without new
contradicting evidence — carry it forward as "previously refuted (date), no new
evidence". Also read `remediation-log.md` if present: a module already deepened is
not a candidate, and a `RESOLVED` row the structure contradicts is its own finding.

## Phase 1: Parallel tool dispatch

Dispatch in a **single parallel batch**. One subagent per tool; each saves raw JSON
to `raw/<tool-name>.json` and returns a structured summary only.

**Must-have tool** — without it there is no ranking, so report that and stop:

| Tool | Supplies |
|------|----------|
| `analyze_thickness` | interface width, implementation mass, thickness and class per file, with the `calls_modeled` gate |

**Must-have for gating** — without it, candidates can still be ranked but every one
of them ships as `UNVERIFIED`; say so explicitly in the report:

| Tool | Supplies |
|------|----------|
| `simulate` | the measured delta behind every candidate (Phase 3) |

**Extended tools** — use if available, note in `manifest.json` if skipped:

| Tool | Supplies |
|------|----------|
| `analyze_interface_bloat` | `export_ratio` per file: how much of the file is surface rather than hidden |
| `analyze_surface` | width across a multi-file boundary, which `analyze_thickness` measures only per file. Reports `total_parameters` and its own `calls_modeled` gate |
| `analyze_clusters` | current module grouping; `hub_collapse` + `top_hubs` disclosure |
| `analyze_seams` | where a deepened boundary could sit |
| `analyze_cohesion` | LCOM4 `components` — the named split of a module doing two things |
| `analyze_orphan_types` | types defined away from their only consumers (a locality defect) |
| `analyze_chokepoints` | high-centrality modules where a deepening has the widest reach |
| `analyze_cycles` | cycles a deepening could resolve |
| `churn_hotspots` | leverage weighting (Phase 0 scope, Phase 4 ranking) |
| `analyze_test_gaps` | which candidates are untested — a thin interface is what makes them testable |
| `coverage_overlay` | with an lcov / JaCoCo / coverage.py report, turns "untested" into evidence |

Interpret `analyze_seams` through `analyze_clusters` per the protocol's Shared
Interpretation Rules (seam / hub-collapse). `total_seams: 0` is never "no boundary
exists".

## Phase 2: Thickness ranking

`analyze_thickness` computes this directly. Read its output; do not recompute the
ratio by hand.

Per file it returns `interface_width` (symbols called from outside the file),
`exposed_parameters`, `implementation_mass` (statements), `thickness`
(`mass / max(width, 1)`), and a `class` of `shallow` / `proportionate` / `deep` /
`unassessed`. Files come back ascending by thickness — shallowest first, which is
the order to work in.

**`unassessed` is not a mild finding, it is the absence of one.** It means the
file was not judged: `summary.calls_modeled` is false, so interface width was
unknowable, or the file has no measurable implementation, or nothing calls into
it so it presents no interface at all. Never fold `unassessed` files into a
"nothing wrong here" reading — count them separately, as the summary does.

**Scope the run so it contains the callers.** Interface width counts calls from
outside the file but inside the analyzed graph, so an `include` narrowed to a
single module hides the very callers that give its files a width — and returns
mostly `unassessed`. Measured on this repo, `include: ["crates/act-analysis"]`
judged 4 of 38 files; the other 34 were unassessed purely because their callers
sat outside the scope. If `unassessed_count` dominates, widen the scope and
re-run before reporting anything about thickness.

`proportionate` is likewise a real answer, not a near-miss. A small file with a
small interface is in proportion; flagging it would make every helper a finding.

`analyze_interface_bloat` is the corroborating second opinion, not the ratio itself:
its `export_ratio` is exported symbols ÷ total symbols — "how much of this file is
public", where `analyze_thickness` asks "how much does it hide". A module that
classes `shallow` **and** carries a high `export_ratio` is the strongest shape. A
module that only classes `shallow` still qualifies; say which evidence backed it.

**Three shallowness shapes to name explicitly.** Each has a different deepening:

| Shape | Evidence | Deepening |
|-------|----------|-----------|
| **Pass-through** — the module forwards and adds nothing | `simulate` `delete_module`: `surface_consumers: 0` with `surface_modeled: true`, high `rewired_edges`, `severed_edges: 0` | remove it; `inline` the forwarders into callers |
| **Split personality** — one module holding two concepts, so neither is local | `analyze_cohesion` `lcom4` ≥ 2 with named `components` | split along the `components` — `split_module` proposes the cut, `move_symbol` executes it |
| **Testability shrapnel** — logic extracted to satisfy a test, leaving the real behaviour in the caller | a symbol with exactly one caller (`references`) in a file whose `analyze_test_gaps` status is covered while the caller is not | fold it back with `inline`, then test through the deepened interface |

## Phase 3: Gate every candidate with `simulate`

**A candidate without a simulated delta does not get a card.** This is what
separates this skill from an opinion. `simulate` never touches disk, so gating is
free.

Express each proposed deepening as an ops script and record the returned deltas:

| Proposal | Op |
|----------|-----|
| Remove a suspected pass-through | `delete_module{file}` |
| Split a module along its `components` | `split_file{file, groups:[[symbol]]}` |
| Relocate an orphan type to its consumer | `move_file{from, to}` |
| Collapse two modules that should be one | `merge_files{files, to}` |
| Cut a dependency a deepening would remove | `remove_edge{from, to}` |

Call it as `simulate(ops=[…], include=[…])` and record `cycles` (resolved /
introduced), the per-unit `coupling` deltas, `chokepoints` centrality changes, and —
only when an `[architecture]` contract exists in `.act/config.toml` —
`violations.cleared` / `violations.introduced`.

**Reading the deletion test.** Follow the protocol's canonical order exactly:
`surface_consumers` first (with a named consumer from `top_consumers`), then
`surface_modeled` as the honesty gate, then `rewired_edges` / `severed_edges`.
`surface_consumers: 0` with `surface_modeled: false` is **UNKNOWN**, never a clean
conduit — the call channel was not modeled for that grammar.

**Verdict, derived from the measurement — never asserted:**

| Verdict | Earned by |
|---------|-----------|
| `CONFIRMED` | The simulation supports the proposal: a cycle resolves, coupling drops on the affected units, no new conformance violation, and — for a removal — `surface_consumers: 0` with `surface_modeled: true` |
| `UNVERIFIED` | `simulate` was unavailable, or the dimension that would decide it is unmodeled (`surface_modeled: false`, a grammar absent from `modeled_kinds`). State which dimension is dark |
| `REFUTED` | The simulation contradicts the proposal — it introduces a cycle or a conformance violation, raises coupling, or the deletion test finds load-bearing consumers |

Write each gated candidate to `investigation/candidate-N.md`.

**Every `REFUTED` candidate goes into the project map's Refuted ledger** with its
disproving evidence, so the next survey does not re-propose it.

## Phase 4: Rank and report

Order candidates by leverage: the simulated delta weighted by how much the module
actually changes (`churn_hotspots`) and how far its blast radius reaches
(`analyze_chokepoints`). A large delta in dormant code ranks below a modest delta in
code that moves every week.

The report is **markdown with ASCII diagrams**, written to
`.act/runs/<YYYY-MM-DD-HHMMSS>/report.md`. It renders in the terminal, in a diff, and
in a review — with no network access, no CDN, and no step where the diagram silently
fails to load and nobody notices.

```markdown
# Deepening Survey: <project name>

## Overview
Scope surveyed (include/exclude), files, date. Why this scope — operator direction
or churn concentration.

## Verdict
One of: **N deepening candidates** / **No deepening candidates found**.
"No candidates" is a legitimate and expected outcome — report it plainly when the
measurements do not support any proposal. Do not manufacture a candidate to fill
the report.

## Thickness Ranking
Table: module | interface width | exposed parameters | implementation mass |
thickness | class | export_ratio, straight from `analyze_thickness`.
Report `summary.unassessed_count` and `summary.calls_modeled` alongside it — a
ranking drawn from an unmodeled call graph is not a short list of findings, it is
no measurement at all.

## Candidates
One section per candidate, ordered by leverage:

### C-N: <deepening stated as an action> — `CONFIRMED` / `UNVERIFIED` / `REFUTED`

**Shape:** pass-through / split personality / testability shrapnel
**Modules:** the files involved
**Friction:** what the current structure costs, in locality and leverage terms
**Proposal:** what would change, in plain language
**Measured delta:** the exact `simulate` output — cycles resolved/introduced,
coupling before/after per unit, deletion-test counts with a named consumer
**Tests:** which tests get simpler, and what `analyze_test_gaps` / `coverage_overlay`
say about the current coverage of this module
**Execution:** the specific ops — `split_module`, `move_symbol`, `inline`,
`extract_function` — that `architectural-refactoring` would run

Before / after, drawn as ASCII:

    before                          after
    ┌────────┐                      ┌────────┐
    │ caller │──┐                   │ caller │──┐
    └────────┘  │                   └────────┘  │
    ┌────────┐  ├──> shim ──> impl   ┌────────┐  ├──────────> impl
    │ caller │──┘     (7 exports,    │ caller │──┘            (2 exports)
    └────────┘         0 logic)      └────────┘

## Refuted Candidates
Proposals this run measured and rejected, with the contradicting evidence.
Carried into the project map's Refuted ledger.

## Top Recommendation
Which candidate to take first and why — leverage, not size.
```

## Handoff

**Stop after the report.** Return the protocol's Common Summary and ask which
candidate the operator wants to pursue. Do not begin designing an interface, do not
open an editor, and do not chain into execution on your own initiative.

When the operator picks one, the next action is a clean-slate handoff — the
artifacts on disk carry everything needed:

> "Clear context, then run `/architectural-refactoring` — it rehydrates from
> `project-map.md` and this run's report, and records the remediation to
> `remediation-log.md`."

Work **one candidate per session**. Carrying the survey, the design, and the edit in
a single context is how the report, the reasoning, and the diff end up competing for
the same window.

## Project Map Updates

Updates **"Key Boundaries"** and **"Chokepoints & Risks"** with confirmed candidates.
Adds every `REFUTED` candidate to the **Refuted & Re-characterized Findings** ledger
with its disproving evidence and this run's date, carrying prior entries forward
verbatim with their original "Since" date. Appends one row to the Analysis History
table. Never edits `remediation-log.md` — that ledger belongs to
`architectural-refactoring`.

## Rules

1. **Propose, never edit.** A run that changes a source file has failed, regardless
   of how good the change was.
2. **No card without a delta.** Every candidate is gated by `simulate`, or ships as
   `UNVERIFIED` with the dark dimension named.
3. **"No candidates" is a valid report.** The measurements decide how many
   candidates exist. Never pad the report to look productive.
4. **Say "thickness", never "depth"** for the interface-versus-implementation
   quality. `analyze_depth` is chain length.
5. **Report the measurement, do not recompute it.** `analyze_thickness` owns the
   ratio and the classification. Re-deriving either by hand invents a second,
   unpinned definition of shallow.
6. **Unmodeled is not clean.** `calls_modeled: false`, a `class` of `unassessed`,
   an empty `modeled_kinds`, `surface_modeled: false`, or a skipped tool all mean
   UNASSESSED. Never report absence of evidence as absence of a problem.
7. **Stop at the report** and let the operator choose.
