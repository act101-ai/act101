---
name: architecture-audit
description: >
  Use when asked to audit architecture, produce a comprehensive architectural overview,
  get the full structural picture of a codebase, assess overall health and porting
  readiness, find module boundaries, circular dependencies, coupling hotspots, dead code,
  or code patterns. Depth 3 — full audit with hypothesis-driven investigation.
  Optionally enriches the structural audit with runtime and git evidence (coverage,
  churn, co-change coupling, ownership) when those overlays are available.
  Replaces the architectural-analysis and architecture-audit-plus skills.
---

# Architecture Audit

**Depth:** Level 3 (Full Audit).

See `../analysis-protocol/references/protocol.md` for: artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and project
map structure. Read that document before proceeding.

## Phase 0: Load the Prior Project Map (before any tool dispatch)

Before dispatching anything, check for an existing `project-map.md` at the workspace root.
**If it exists, read it first** and extract:

- **Refuted & Re-characterized Findings** ledger — these are hypotheses already investigated
  and disproven. Do **not** re-investigate them from scratch in Phase 2. Re-open a refuted
  finding **only** if Phase 1 surfaces new structural evidence that contradicts the prior
  refutation; otherwise carry each entry forward verbatim and note "previously refuted
  (date), no new evidence" in the report. This is the single most important reason to read
  the map first — it stops every audit from re-flagging the same disproven smells.
- **Analysis History** table — for the trend verdict (improving / stable / degrading) and to
  append (not overwrite) the new row.
- **Chokepoints, hotspots, cycles, pattern counts** — capture prior numbers so the new report
  can show deltas (e.g. "god_function 1,321 → 1,651"), and so a *newly appeared* cycle or
  chokepoint is flagged as a regression.
- **Scan-score trend:** if `.act/scan-history.jsonl` exists, run `act trends --root <repo>`
  for the score series, per-class count deltas, and banded verdict — never hand-diff scan
  scores across runs. Analyzer outputs not in the history records (chokepoints, clusters,
  hotspot rankings) still come from the prior map's numbers as above.

**Also read `remediation-log.md`** (workspace root, if present). This is the append-only ledger
the `architectural-refactoring` skill writes — one row per remediation, keyed to a finding ID. It
is the other half of the audit → refactor → re-audit loop: it tells you which prior findings were
*claimed* fixed since the last audit, and how. Treat each `RESOLVED`/`PARTIAL` row not as truth
but as a **hypothesis to re-verify** in Phase 2 against this run's fresh structural evidence:

- If the structure confirms the fix (the cycle is gone, instability dropped, the god-object split),
  reflect it in synthesis — mark the recommendation resolved, move the item out of Weaknesses, and
  show it in the delta/trend.
- If the structure *contradicts* the claim (the row says RESOLVED but the cycle is still present, or
  a "split" reintroduced coupling elsewhere), that is a **regression / incomplete-remediation
  finding** — surface it explicitly with the conflicting evidence.

The audit only **reads** this log; the refactoring skill owns the writes. Never edit
`remediation-log.md` from the audit.

If no `project-map.md` exists, this is the first audit — note that, proceed to Phase 1, and
create the map (including an empty Refuted ledger) during synthesis. A `remediation-log.md` with no
prior map is an inconsistency — note it and treat its rows as unverified claims.

## Phase 1: Parallel Tool Dispatch

Dispatch all available tools in a **single parallel batch** — never sequentially.
Each subagent runs one tool, saves raw JSON to `raw/<tool-name>.json`, returns a
structured summary.

**Must-have tools (report is not useful without at least some of these):**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_clusters` | Module groupings | `analyze_clusters` |
| `analyze_coupling` | Instability rankings | `analyze_coupling` (sort: instability) |
| `analyze_cycles` | Circular dependencies | `analyze_cycles` |
| `analyze_seams` | Natural boundaries | `analyze_seams` |
| `analyze_dead_code` | Unreachable symbols | `analyze_dead_code` |
| `analyze_patterns` | Structural smells | `analyze_patterns` |
| `analyze_export` | Codebase dimensions | `analyze_export` |

Interpret `analyze_seams` through the cluster output that feeds it. `total_seams: 0`
only means there are no crossing edges between the detected clusters. If
`analyze_clusters` reports fewer than two clusters, `hub_collapse: true`, or one cluster
containing the whole scope, do not report "no boundary"; report the cluster artifact and
investigate with `dampen_top_k`, `split_module`, `analyze_surface`, or `simulate`.

**Extended tools (use if available, skip and note in manifest if not):**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_layers` | Layer detection + violations (S1+S2) | `analyze_layers` |
| `analyze_hotspots` | Complexity ranking (H1) | `analyze_hotspots` |
| `analyze_cohesion` | Internal relatedness (H2) | `analyze_cohesion` |
| `analyze_chokepoints` | Betweenness centrality (R4) | `analyze_chokepoints` |
| `analyze_stability` | Stability index + violations (R2+R3) | `analyze_stability` |
| `analyze_roles` | Module role classification (S3) | `analyze_roles` |
| `analyze_entry_points` | Application entry points (S5) | `analyze_entry_points` |
| `analyze_clones` | Duplicated-code mass (clone classes) | `analyze_clones` — start with the default `min_tokens` (50); raise it only if the top classes are micro-boilerplate (e.g. single-expression patterns); use `include`/`exclude` to scope large monorepos. Caveats: type-2 clone classes require ≥1 function-context member (same-shape data-only matches are dropped by the engine); test files excluded by default and disclosed via `summary.test_files_excluded`; type-3 (gapped) clones are not detected in v1. |
| `analyze_conformance` | Declared-vs-actual architecture (contract violations) | `analyze_conformance` — **promotes to must-have when the repo declares a contract** (`.act/config.toml` with an `[architecture]` section: layer ranks, deny rules, surface caps; probe for the file before dispatch). Violations cite the offending import's file:line. `contract_present: false` means no contract is declared — that is "nothing to check," never "conformant." Rank convention: 0 = outermost layer. |

**Conformance worked example** (real run): a repo declaring

```toml
[architecture]
[[architecture.deny]]
from = "src/core/**"
to = "src/ui/**"
reason = "core must not depend on presentation"
```

where `src/core/logic.ts` imports `src/ui/render.ts` returns
`contract_present: true` and one violation: `kind: "deny"`, `rule: "src/core/** -> src/ui/**"`,
`file: "src/core/logic.ts"`, `line: 1`, evidence `src/core/logic.ts --imports--> src/ui/render.ts`,
with the rule's written `reason` echoed. Report violations with that file:line —
it is the offending import statement, not the rule definition.

## Phase 2: Smell Taxonomy + Hypothesis Formation

Before dispatching any investigation subagents, form explicit hypotheses using this
taxonomy. One module appearing in multiple columns is a stronger signal.

| Evidence pattern | Architectural smell | Confirming query |
|-----------------|--------------------|--------------------|
| High instability + appears in cycle | God object / hub | `skeleton` + `interface` — is the API surface wider than the abstraction warrants? |
| High instability + wide seam API | Leaky abstraction | `analyze_surface` at boundary — count unrelated symbols crossing it |
| Large cluster + low cohesion score | Accidental cluster / false boundary | `skeleton` on cluster members — do they share a concept? |
| Cycle length > 3 | Tightly-coupled subsystem | `analyze_surface --files <members>` — find the minimum cut |
| Single-file cluster | Orphan / orphaned extract | `references` — does anything depend on this module? |
| Dead code in frequently-modified file | Zombie code / incomplete refactor | `symbols` + `references` — confirm no live callers |
| Pattern hotspot + high instability | Design debt accumulation point | `skeleton` — does the file serve multiple unrelated concerns? |
| Module instability = 1.0, many dependents | Unstable abstraction | `interface` — is this a leaf that should be stable? |
| Seam API surface > 10 symbols | Wide interface / tight coupling | `analyze_surface` — which symbols cross; can the seam be narrowed? |
| No cycles but very large clusters | Low cohesion, high coupling within cluster | `analyze_coupling` within cluster |
| High centrality + low cohesion | Overloaded chokepoint | `skeleton` — is this file doing too many things? |
| Layer violations + high coupling | Architectural erosion | `graph` — trace the violation path, assess if structural or incidental |
| Top clone classes by mass (token_count × members) | Structural duplication / abstraction debt | When a class carries a `remediation.operation: "extract_function"` pointer, use `extract_function` — all members already sit in function bodies. For classes without a remediation pointer (data literals, top-level declarations), consider consolidation at the module level rather than extraction. |
| Contract violations (declared layers/deny rules breached) | Architectural erosion against an explicit contract — stronger than inferred-layer violations because the team wrote the rule down | `analyze_conformance` output cites the violating import's file:line; `graph` to trace whether the dependency is load-bearing or incidental before recommending the cut |

**Anomaly flags — investigate regardless of smell match:**
- Cluster containing 1 file (orphan or misclassified)
- Cluster containing >30% of all files (god cluster) — `analyze_clusters` now self-discloses via `hub_collapse=true` + `top_hubs` (named hub files); consume these fields from the result and report the named hubs; the >30% rule remains as a cross-check (it also catches large clusters whose cohesion sits above the 0.05 disclosure floor)
- All instability scores near 0 or near 1 (degenerate dependency structure)
- Seam with 0 API symbols (disconnected component)
- Dead code in a file that is also in a cycle (phantom dependency)
- Zero cycles in a codebase >100 files (suspiciously clean)

## Phase 3: Full Audit Synthesis

After all investigation subagents return:

1. **Cross-reference findings** across all categories — a module appearing in hotspots,
   coupling, AND cycles is a compounding risk
2. **Build evidence chains** — not "instability = 0.94" but "module X has instability
   0.94, is in 2 cycles, and its API surface exposes 23 symbols across a seam to
   cluster B — skeleton shows it handles both auth and request routing, confirming
   god-object smell"
3. **Note negative space** — absence of expected problems is a meaningful finding
4. **Record every refuted or re-characterized hypothesis** — for each Phase 2 hypothesis that
   came back refuted, partially refuted, or re-characterized (the real issue differs from the
   hypothesized smell), and for each tool output that is an artifact rather than a finding
   (e.g. degenerate dead-code/cohesion/layers results), capture it with its disproving
   evidence. These feed the project map's **Refuted & Re-characterized Findings** ledger.
5. **Reconcile claimed remediations** — for each `remediation-log.md` row read in Phase 0, state
   the verdict from this run's evidence: *confirmed* (fold into the map, mark the recommendation
   resolved, show the delta), or *contradicted* (surface as a regression / incomplete-remediation
   finding). Do not silently drop a claimed fix that the structure no longer supports.
6. Write `report.md`, then update `project-map.md` (full rewrite of all sections, carrying the
   Refuted ledger forward and reflecting confirmed remediations — see Project Map Updates)

## Report Structure

```markdown
# Architecture Audit: <project name>

## Overview
Files, symbols, languages, analysis date.

## Executive Summary
2-3 sentence assessment. Explicit verdict: **Ready** / **Needs work** / **Not ready**.
One-sentence justification for the verdict.

## Module Map
Clusters with sizes, labels, cohesion scores. Anomalies noted.
Module roles (entry point, routing, business logic, data access, utility, etc.).

## Entry Points
Application entry points by kind (application, HTTP route, CLI, event listener, test,
public API).

## Layer Architecture
Detected layers with directory mappings. Violations with evidence.

## Dependency Structure
Instability rankings with interpretation — what the scores mean structurally.
Stability violations.

## Circular Dependencies
All cycles: length, members, confirmed break points from investigation.

## Boundary Assessment
Seams: API surface width, confirmed leaky vs. clean.

## Complexity Hotspots
Ranked hotspots with skeleton context from investigation.

## Chokepoints
High-centrality files with blast radius and split recommendations.

## Dead Code
Confirmed unreachable symbols. Zombie code noted separately.

## Code Patterns
Findings grouped by pattern type and severity.

## Strengths
What the architecture does well. Notable absence of expected problems.

## Weaknesses
Confirmed structural issues with evidence chains.

## Refuted & Re-characterized Findings
Hypotheses investigated and NOT confirmed (refuted / partially refuted / re-characterized),
and tool outputs that are artifacts rather than findings. Each with its disproving evidence.
Include findings carried forward from the prior project map (mark "previously refuted, no new
evidence"). This section prevents future audits from re-flagging disproven smells.

## Risks
Causal chains: what breaks first, what cascades, minimum intervention.

## Recommendations
Prioritized, actionable steps, each linked to a confirmed finding.

When the audit confirms structural findings that warrant remediation (cycles, god
objects, coupling hotspots, dead code), the single recommended next action is to run the
`architectural-refactoring` skill — **not** a cherry-picked inline fix. That skill executes
the prioritized set as a unit and records each remediation to `remediation-log.md`, which is
what closes the audit → refactor → re-audit cycle and lets it go deeper each pass. Proposing a
one-off "move X, fix two imports, re-run" edit here short-circuits the cycle and leaves no
durable remediation record. The specific act MCP tool calls are the *mechanism* the refactoring
skill uses, not a substitute for invoking it.

Because the handoff is artifact-based (this report + `project-map.md` + `remediation-log.md` on
disk), the refactoring skill needs no conversation context. Phrase the next action so it works
from a clean slate, e.g.: "Clear context, then run `/architectural-refactoring` — it rehydrates
from this report and the project map." Use individual tool-call recommendations only for findings
that are genuinely outside a refactoring pass (e.g. "add a coverage run before the next audit").
```

## Project Map Updates

Updates **all sections** of `project-map.md` (workspace root, full rewrite). Appends to the
Analysis History table.

**Confirmed remediations:** when this run's evidence confirms a `remediation-log.md` claim, reflect
it in the rewritten map — drop or down-rank the resolved item in Chokepoints & Risks / Weaknesses,
and let the resolution show in the delta and trend verdict. Do **not** copy the remediation log
into the map and do **not** edit the log itself — the map records *current state*, the log records
*actions taken*, and the refactoring skill owns the log. A claim the structure contradicts stays an
open finding (and may warrant a Refuted-ledger entry if the "fix" was based on a misdiagnosis).

**Refuted & Re-characterized Findings ledger (required):** the project map carries a persistent
`## Refuted & Re-characterized Findings` section (see the protocol's Project Map Structure). On
every run:

1. **Carry forward** every entry from the prior map's ledger — never drop a refutation just
   because this run didn't re-test it. Keep its original "Since" date.
2. **Add** each newly refuted / re-characterized hypothesis and each newly identified tool
   artifact from this run's Phase 2, with the disproving evidence and this run's date.
3. **Update** an entry's status only if this run found new evidence that overturns the prior
   refutation (e.g. a once-clean boundary now genuinely leaks) — note the change explicitly.

Each ledger row: `| Finding | Status (REFUTED / RE-CHARACTERIZED / ARTIFACT / UNRELIABLE) |
Since (date first established) | Evidence / why |`. This ledger is what Phase 0 reads on the
next run to avoid re-investigating disproven smells.

## Rules

1. Dispatch Phase 1 in a single parallel batch — never sequentially
2. Write all hypotheses before dispatching Phase 2 — no browsing without a hypothesis
3. Evidence chains, not data points — explain what scores mean structurally
4. Follow new signals — if a Phase 2 subagent finds something unexpected, dispatch a
   follow-up (capped at one extra round)
5. Note negative space — absence of expected problems is a finding
6. Executive summary must include an explicit Ready / Needs work / Not ready verdict

## Worked Example: Clone-Mass Dispatch

Call (default min_tokens; scoped to source):

```
analyze_clones(include=["crates"])
```

Top of result (act repo, 2026-06-12, min_tokens 50):

```json
{
  "clone_classes": [
    {
      "id": "clone-3407fede907f0634",
      "clone_type": "type-2",
      "token_count": 57,
      "members": [
        { "file": "crates/act-refactor/src/operations/actionscript/operations/add_documentation_comment.rs",
          "start_line": 24, "end_line": 30 }
        // … 1506 more members
      ],
      "remediation": {
        "operation": "extract_function",
        "note": "All members are function definitions or lie within function bodies."
      }
    }
  ],
  "summary": {
    "files_analyzed": 5392,
    "files_with_clones": 3970,
    "clone_class_count": 8156,
    "duplicated_tokens": 5067066,
    "min_tokens": 50,
    "test_files_excluded": 47488
  }
}
```

Reading this: the top class by mass (57 tokens × 1507 members = 85,842 mass) has a `remediation.operation: "extract_function"` pointer — every member lies in a function body, so `extract_function` at the first member site is the right next step. The 5,067,066 `duplicated_tokens` total against 5,392 files analyzed signals systematic abstraction debt, not isolated copy-paste.

## Optional Enrichment: Runtime & Git Evidence

The structural audit above is AST/graph-based. When the workspace has a coverage
run and git history, enrich each structural finding with evidence overlays so the
report reflects what actually runs and what actually changes — not just the static
graph. This is optional: skip any overlay whose evidence is absent and say so.

**Tier:** the four overlays (`coverage_overlay`, `churn_hotspots` in workspace mode,
`co_change_clusters`, `ownership_map`) are **Architecture** and enforce that tier
themselves; the base structural audit is unaffected. If an overlay is tier-blocked,
its dimension is UNASSESSED — state it, never imply "clean."

| Tool | Enriches |
|---|---|
| `coverage_overlay` | Joins lcov coverage onto symbols — turns "this hotspot is complex" into "complex AND uncovered." |
| `churn_hotspots` | Ranks symbols by git change frequency × recency — "high coupling" becomes "high coupling AND frequently churned." |
| `co_change_clusters` | Symbols that change together across history — confirms or contradicts the static clusters (hidden / shotgun-surgery coupling). |
| `ownership_map` | Per-symbol author shares + bus factor — flags knowledge-concentration risk on critical modules. |

**Enrichment workflow (after the structural audit):**

1. `coverage_overlay` with the lcov `report` — a complexity hotspot or chokepoint
   with `covered: false` is a high-risk node (complex, central, untested).
2. `churn_hotspots` (workspace mode) — a high-coupling / high-instability module
   that is also high-churn is an active design-debt accumulation point.
3. `co_change_clusters` — where these disagree with the static `analyze_clusters`
   boundaries, you have hidden coupling the structure does not show.
4. `ownership_map` — a low bus factor on a chokepoint or god-module is a compounding
   people-risk on top of the structural risk.

When enrichment runs, every Risk and Recommendation should cite the structural
finding AND its overlay evidence — e.g. "module X: instability 0.94, in 2 cycles
(structure) + uncovered + 31 commits in 90 days + bus factor 1 (overlays) →
top-priority refactor." Overlays are window-bounded: report `unmapped`/`modeled_kinds`
and the coverage/git window as caveats. Absence of overlay evidence is "no evidence,"
not absolution.
