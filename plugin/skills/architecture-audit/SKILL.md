---
name: architecture-audit
description: Use when asked to audit architecture, get the full structural picture of a codebase, assess overall health or porting readiness, or find module boundaries, circular dependencies, coupling hotspots, dead code, or code smells. Full hypothesis-driven audit, optionally enriched with coverage and git evidence.
---

# Architecture Audit

**Depth:** Level 3 (Full Audit). Read `../analysis-protocol/references/protocol.md`
first: it defines the run artifacts, the investigation loop, the Shared
Interpretation Rules, the summary format, and the project-map structure.

## Phase 0: Load the prior project map

Before any tool call, check for `project-map.md` at the workspace root. If it
exists, read it and extract:

- **Refuted & Re-characterized Findings** ledger: hypotheses already investigated
  and disproven. Re-open one only if Phase 1 surfaces new structural evidence that
  contradicts the prior refutation; otherwise carry each entry forward verbatim and
  note "previously refuted (date), no new evidence". This is what stops every audit
  from re-flagging the same disproven smells.
- **Analysis History** table, for the trend verdict (improving / stable / degrading)
  and the new row to append.
- **Chokepoints, hotspots, cycles, pattern counts**, so the new report can show
  deltas ("god_function 1,321 → 1,651") and flag a newly appeared cycle or
  chokepoint as a regression.
- **Scan-score trend:** if `.act/scan-history.jsonl` exists, run
  `act trends --root <repo>` for the score series, per-class count deltas, and
  banded verdict. Analyzer outputs outside the history records (chokepoints,
  clusters, hotspot rankings) still come from the prior map's numbers.

Also read `remediation-log.md` (workspace root) if present: the append-only ledger
the `architectural-refactoring` skill writes, one row per remediation keyed to a
finding ID. Each `RESOLVED` or `PARTIAL` row is a **hypothesis to re-verify** in
Phase 2 against this run's evidence. If the structure confirms the fix (the cycle is
gone, instability dropped, the god object split), reflect it in synthesis: mark the
recommendation resolved, move the item out of Weaknesses, show it in the delta. If
the structure contradicts the claim (the row says RESOLVED but the cycle is still
there, or a split reintroduced coupling elsewhere), surface it as a regression or
incomplete-remediation finding with the conflicting evidence. The audit only reads
this log; the refactoring skill owns the writes.

If no `project-map.md` exists, this is the first audit: note that, proceed to Phase
1, and create the map (with an empty Refuted ledger) during synthesis. A
`remediation-log.md` with no prior map is an inconsistency; note it and treat its
rows as unverified claims.

## Phase 1: Parallel tool dispatch

Dispatch every available tool in one parallel batch, one subagent per tool. Each
saves raw JSON to `raw/<tool-name>.json` and returns a structured summary.

**Must-have** (the report is not useful without at least some of these):

| Tool | Purpose | Call |
|------|---------|------|
| `analyze_clusters` | Module groupings | `analyze_clusters` |
| `analyze_coupling` | Instability rankings | `analyze_coupling` with `sort: instability` |
| `analyze_cycles` | Circular dependencies | `analyze_cycles` |
| `analyze_seams` | Natural boundaries | `analyze_seams` |
| `analyze_dead_code` | Unreachable symbols | `analyze_dead_code` |
| `analyze_patterns` | Structural smells | `analyze_patterns` |
| `analyze_export` | Codebase dimensions | `analyze_export` |

Interpret `analyze_seams` through the cluster output that feeds it, per the
protocol's seam / hub-collapse rule; `total_seams: 0` alone is not "no boundary".

**Extended** (use if available; note skips in the manifest):

| Tool | Purpose | Call |
|------|---------|------|
| `analyze_layers` | Layer detection and violations (S1+S2) | `analyze_layers` |
| `analyze_hotspots` | Complexity ranking (H1) | `analyze_hotspots` |
| `analyze_cohesion` | Internal relatedness (H2) | `analyze_cohesion` |
| `analyze_chokepoints` | Betweenness centrality (R4) | `analyze_chokepoints` |
| `analyze_stability` | Stability index and violations (R2+R3) | `analyze_stability` |
| `analyze_roles` | Module role classification (S3) | `analyze_roles` |
| `analyze_entry_points` | Application entry points (S5) | `analyze_entry_points` |
| `analyze_clones` | Duplicated-code mass (clone classes) | `analyze_clones`. Start at the default `min_tokens` (50); raise it only if the top classes are micro-boilerplate. Use `include`/`exclude` to scope large monorepos. Type-2 classes need at least one function-context member (same-shape data-only matches are dropped); test files are excluded by default and disclosed in `summary.test_files_excluded`; type-3 (gapped) clones are not detected. |
| `analyze_conformance` | Declared-vs-actual architecture | `analyze_conformance`. **Promotes to must-have when the repo declares a contract** (`.act/config.toml` with an `[architecture]` section: layer ranks, deny rules, surface caps; probe for the file before dispatch). Violations cite the offending import's file:line, which is where to report them. `contract_present: false` means nothing to check, not conformant. Rank convention: 0 is the outermost layer. |

## Phase 2: Smell taxonomy and hypotheses

Write every hypothesis before dispatching an investigation subagent. A module that
appears in several columns is a stronger signal.

| Evidence pattern | Architectural smell | Confirming query |
|-----------------|--------------------|--------------------|
| High instability, appears in a cycle | God object / hub | `skeleton` + `interface`: is the API wider than the abstraction warrants? |
| High instability, wide seam API | Leaky abstraction | `analyze_surface` at the boundary: count unrelated symbols crossing it |
| Large cluster, low cohesion score | Accidental cluster / false boundary | `skeleton` on cluster members: do they share a concept? |
| Cycle length over 3 | Tightly coupled subsystem | `analyze_surface` with `files: [<members>]`: find the minimum cut |
| Single-file cluster | Orphan / orphaned extract | `references`: does anything depend on it? |
| Dead code in a frequently modified file | Zombie code / incomplete refactor | `symbols` + `references`: confirm no live callers |
| Pattern hotspot, high instability | Design-debt accumulation point | `skeleton`: does the file serve unrelated concerns? |
| Instability 1.0 with many dependents | Unstable abstraction | `interface`: is this a leaf that should be stable? |
| Seam API surface over 10 symbols | Wide interface / tight coupling | `analyze_surface`: which symbols cross; can the seam narrow? |
| No cycles but very large clusters | Low cohesion, high coupling within the cluster | `analyze_coupling` within the cluster |
| High centrality, low cohesion | Overloaded chokepoint | `skeleton`: is this file doing too many things? |
| Layer violations, high coupling | Architectural erosion | `graph`: trace the violation path; structural or incidental? |
| Top clone classes by mass (token_count × members) | Structural duplication / abstraction debt | A class carrying `remediation.operation: "extract_function"` has every member inside a function body, so `extract_function` at the first member site is the next step. A class without a remediation pointer (data literals, top-level declarations) is a module-level consolidation. |
| Contract violations (declared layers or deny rules breached) | Erosion against an explicit contract, stronger than an inferred-layer violation because the team wrote the rule down | `analyze_conformance` cites the violating import's file:line; `graph` to judge whether the dependency is load-bearing before recommending the cut |

**Anomaly flags** (investigate regardless of smell match):

- A cluster of one file (orphan or misclassified).
- A cluster over 30% of all files (god cluster). `analyze_clusters` self-discloses
  this through `hub_collapse: true` and `top_hubs`; report the named hubs, and keep
  the 30% rule as a cross-check for large clusters whose cohesion sits above the
  0.05 disclosure floor.
- All instability scores near 0 or near 1 (degenerate dependency structure).
- A seam with 0 API symbols (disconnected component).
- Dead code in a file that is also in a cycle (phantom dependency).
- Zero cycles in a codebase over 100 files (suspiciously clean).

Dispatch one subagent per hypothesis; a follow-up is capped at one extra round.

## Phase 3: Synthesis

1. **Cross-reference** across categories: a module in hotspots, coupling, and cycles
   is a compounding risk.
2. **Build evidence chains**, not data points: "module X has instability 0.94, is in
   2 cycles, and its API exposes 23 symbols across a seam to cluster B; skeleton
   shows it handles both auth and request routing, confirming the god-object smell".
3. **Note negative space**: the absence of an expected problem is a finding.
4. **Record every refuted or re-characterized hypothesis**, and every tool output
   that is an artifact rather than a finding (degenerate dead-code, cohesion, or
   layer results), with its disproving evidence, for the Refuted ledger.
5. **Reconcile claimed remediations**: for each `remediation-log.md` row read in
   Phase 0, state the verdict from this run's evidence: confirmed (fold into the
   map, mark resolved, show the delta) or contradicted (surface as a regression or
   incomplete remediation).
6. Write `report.md`, then rewrite `project-map.md` in full, carrying the Refuted
   ledger forward and reflecting confirmed remediations.

## Report structure

```markdown
# Architecture Audit: <project name>

## Overview
Files, symbols, languages, analysis date.

## Executive Summary
2-3 sentences with an explicit verdict: **Ready** / **Needs work** / **Not ready**,
and a one-sentence justification.

## Module Map
Clusters with sizes, labels, cohesion scores; anomalies; module roles.

## Entry Points
By kind: application, HTTP route, CLI, event listener, test, public API.

## Layer Architecture
Detected layers with directory mappings; violations with evidence.

## Dependency Structure
Instability rankings with structural interpretation; stability violations.

## Circular Dependencies
Every cycle: length, members, confirmed break points.

## Boundary Assessment
Seams: API surface width, confirmed leaky vs. clean.

## Complexity Hotspots
Ranked, with skeleton context from investigation.

## Chokepoints
High-centrality files with blast radius and split recommendations.

## Dead Code
Confirmed unreachable symbols; zombie code noted separately.

## Code Patterns
Findings grouped by pattern type and severity.

## Strengths
What the architecture does well; notable absence of expected problems.

## Weaknesses
Confirmed structural issues with evidence chains.

## Refuted & Re-characterized Findings
Hypotheses investigated and not confirmed, and tool outputs that are artifacts,
each with its disproving evidence. Include entries carried forward from the prior
map, marked "previously refuted, no new evidence".

## Risks
Causal chains: what breaks first, what cascades, the minimum intervention.

## Recommendations
Prioritized steps, each linked to a confirmed finding.

When confirmed findings warrant remediation (cycles, god objects, coupling
hotspots, dead code), the one recommended next action is the
`architectural-refactoring` skill, which executes the prioritized set as a unit and
records each remediation in `remediation-log.md`. A cherry-picked inline fix ("move
X, fix two imports, re-run") short-circuits the cycle and leaves no durable record;
the act MCP calls are the mechanism that skill uses, not a substitute for it.

The handoff is artifact-based (this report, `project-map.md`, `remediation-log.md`),
so phrase it for a clean slate: "Clear context, then run
`/architectural-refactoring`; it rehydrates from this report and the project map."
Recommend an individual tool call only for work outside a refactoring pass ("add a
coverage run before the next audit").
```

## Project map updates

Rewrites every section of `project-map.md` (workspace root) and appends to the
Analysis History table.

**Confirmed remediations:** when this run's evidence confirms a `remediation-log.md`
claim, drop or down-rank the resolved item in Chokepoints & Risks and Weaknesses and
let the resolution show in the delta and trend. The log itself is never copied into
the map or edited. A claim the structure contradicts stays an open finding, and may
warrant a Refuted-ledger entry if the fix rested on a misdiagnosis.

**Refuted & Re-characterized Findings ledger:** on every run, carry forward every
prior entry with its original "Since" date; add each newly refuted or
re-characterized hypothesis and each newly identified tool artifact with its
evidence and this run's date; and update an entry's status only when new evidence
overturns the prior refutation, noting the change. Row format:
`| Finding | Status (REFUTED / RE-CHARACTERIZED / ARTIFACT / UNRELIABLE) | Since | Evidence / why |`.

## Optional enrichment: runtime and git evidence

The structural audit is AST and graph based. When the workspace has a coverage run
and git history, enrich each structural finding so the report reflects what runs
and what changes. Skip any overlay whose evidence is absent and say so.

The four overlays (`coverage_overlay`, `churn_hotspots` in workspace mode,
`co_change_clusters`, `ownership_map`) are Architecture tier and enforce it
themselves; a tier-blocked overlay leaves its dimension UNASSESSED.

| Tool | Enriches |
|---|---|
| `coverage_overlay` | Joins lcov coverage onto symbols: "complex" becomes "complex and uncovered" |
| `churn_hotspots` | Ranks symbols by git change frequency × recency: "high coupling" becomes "high coupling and frequently churned" |
| `co_change_clusters` | Symbols that change together across history; confirms or contradicts the static clusters (hidden or shotgun-surgery coupling) |
| `ownership_map` | Per-symbol author shares and bus factor; knowledge-concentration risk on critical modules |

After the structural audit:

1. `coverage_overlay` with the lcov `report`: a hotspot or chokepoint with
   `covered: false` is complex, central, and untested.
2. `churn_hotspots` (workspace mode): a high-coupling or high-instability module
   that is also high-churn is an active design-debt accumulation point.
3. `co_change_clusters`: where these disagree with the static `analyze_clusters`
   boundaries, the structure hides coupling.
4. `ownership_map`: a low bus factor on a chokepoint or god module is a people risk
   on top of the structural risk.

With enrichment, every Risk and Recommendation cites the structural finding and its
overlay evidence: "module X: instability 0.94, in 2 cycles (structure); uncovered,
31 commits in 90 days, bus factor 1 (overlays): top-priority refactor". Overlays are
window-bounded, so report `unmapped`, `modeled_kinds`, and the coverage and git
window. Absence of overlay evidence is no evidence, not absolution.
