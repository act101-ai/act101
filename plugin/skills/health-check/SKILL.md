---
name: health-check
description: >
  Use when asked about code health, quality trends, what's getting worse, or for a
  periodic quality check. Depth 1 — fast, trend-aware. Produces a health snapshot with
  hotspots, cohesion issues, test gaps (evidence-labeled: lcov or convention), and trend
  comparison if prior runs exist.
  Replaces the codebase-analysis skill.
---

# Health Check

**Depth:** Level 1 (Explore).

See `../analysis-protocol/references/protocol.md` for: artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and project
map structure. Read that document before proceeding.

## Phase 1: Parallel Tool Dispatch

Dispatch all available tools in a **single parallel batch**.
Each subagent runs one tool, saves raw JSON to `raw/<tool-name>.json`, returns a
structured summary.

**Must-have tools:**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_hotspots` | Complexity ranking (H1) | `analyze_hotspots` |
| `analyze_patterns` | Tier 1 structural smells | `analyze_patterns` (use `--tier fast`) |

If neither must-have tool is available, report that and stop.

**Extended tools (use if available, skip and note in manifest if not):**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_coupling` | Instability overview | `analyze_coupling` |
| `analyze_cohesion` | Module cohesion (H2) | `analyze_cohesion` |
| `analyze_test_gaps` | Test coverage gaps; supply `coverage_report` for evidence-based statuses (evidence: lcov), else convention-based | `analyze_test_gaps` |
| `analyze_inconsistencies` | Sibling pattern divergence (H5) | `analyze_inconsistencies` |
| `scan` | AI-Code Health Score (security) + AI-config-backdoor / MCP-RCE findings | `scan` (pass `baseline` if `.act/baseline.json` is committed — see Trend Comparison). Scan auto-discovers lcov reports (coverage/lcov.info, lcov.info, target/coverage/lcov.info): when one is found, TestGap statuses are evidence-based and the `test_gaps` coverage record names the report (and flags it `stale` when older than the newest source). Repeat that record's `evidence:` clause in the report — never present convention-based statuses as coverage facts. |
| `analyze_clones` | Duplication mass snapshot | If `scan` already ran in this workflow, source the Duplication row from its findings (cheaper — no re-run needed); otherwise call `analyze_clones` directly. Report `summary.duplicated_tokens` and `summary.clone_class_count` from the result. |

## Phase 2: Follow-up (Explore depth)

From summaries, identify the top 3-5 findings and run one targeted follow-up each:

- For each top hotspot: run `skeleton` to characterize what's wrong
- For untested high-coupling files: note the compound risk (untested + high blast radius)

Keep follow-ups to one round — this is a health check, not a full audit.

## Trend Comparison

**Score/class trend (scan history):** if `.act/scan-history.jsonl` exists in the
repo, do not hand-compare scan scores across runs — run `act trends --root <repo>`
(add `--format markdown` for the report artifact). It renders the score series,
per-class count deltas, top movers, and an Improving/Stable/Degrading verdict with
documented bands. Encourage repos without a history file to adopt
`act scan --history-append` in CI (full scans only — scoped runs are rejected).
Count deltas are not identity tracking; the baseline mechanism below remains the
identity-level security trend.

Check `docs/act/` for a prior Health Check run: look for a `manifest.json` with
`"skill": "health-check"`. If found:

1. Load the most recent prior run's `raw/hotspots.json` and `raw/coupling.json`
2. Report deltas:
   - New hotspots since last run (files that appeared or moved up)
   - Resolved hotspots (files that disappeared or moved down)
   - Coupling changes (improving = lower instability, degrading = higher)
   - Test coverage trend (if `raw/test_gaps.json` exists in both runs; note whether statuses are lcov evidence-based or convention-based via the `evidence` field)

**Security trend (scan):** do not hand-diff finding lists from a prior run's
`raw/scan.json` — the baseline mechanism computes the deltas. If the repo has a
committed `.act/baseline.json`, pass it on the Phase 1 call:
`scan(root=<repo>, baseline=".act/baseline.json")`. The report's `baseline`
section IS the security trend:

- `new` — findings not in the baseline (regressions since it was written)
- `fixed` — baseline entries no longer found (remediated debt)
- `baselined` — acknowledged debt still present

If no baseline exists yet, record one with `baseline_write`
(CLI: `act scan --baseline-write`), commit it, and the next health check gets
real deltas. Score comparability is what the tools report: scores compare only
across identical scan semantics — a diff-scoped scan (`base_ref`) is never
comparable to a full-repo scan.

**Duplication trend:** `summary.duplicated_tokens` is the comparable scalar across runs — but only when both runs used the same `min_tokens` value. Cross-threshold comparisons (e.g. a 50-token run vs. a 100-token run) are invalid and must not be stated as a trend.

Verdict must reflect the trend: **Improving** / **Stable** / **Degrading** —
when `act trends` ran, adopt its verdict unless the artifact-diff evidence
contradicts it (say so explicitly if it does).

## Report Structure

```markdown
# Health Check: <project name>

## Health Summary
Verdict: **Improving** / **Stable** / **Degrading**.
One-paragraph assessment.
If `scan` ran, lead with its **AI-Code Health Score** (security sub-score, 0–100)
and list any `ai_config_backdoor` / `mcp_config_rce` findings as critical items.

## Duplication Snapshot
`duplicated_tokens`: N — `clone_class_count`: N — `min_tokens`: N (sourced from scan Duplication findings or direct `analyze_clones` call).

## Top Hotspots
Ranked list with skeleton context from follow-up. Severity and recommended fix.
Per-hotspot: file path, complexity score, what skeleton revealed, recommended action.

## Cohesion Issues
Low-cohesion modules with split recommendations.
Per-issue: module, cohesion score, suggested split boundary.

## Pattern Inconsistencies
Sibling files that diverge from group conventions.
Per-divergence: what's expected in the group, what's different in this file.

## Test Gaps
Untested files ranked by risk (coupling × blast radius if available, else coupling alone).
Per-gap: file path, risk factors, suggested test type.

## Trend
(Present only if prior run data exists)
| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Top hotspot score | N | N | ↑/↓/= |
| Hotspot count (top 10) | N | N | ↑/↓/= |
| Mean instability | N | N | ↑/↓/= |
| Test gap count | N | N | ↑/↓/= |
| Duplicated tokens (same min_tokens only) | N | N | ↑/↓/= |

What improved, what degraded, what's new since last run.
If `scan` ran with a baseline, lead the security line with the `baseline`
counts: `new` = regressions, `fixed` = remediated debt, `baselined` =
acknowledged debt still present.

## Suggested Fixes
Prioritized list of specific act MCP tool calls or skills to run.
```

## Worked Example: Duplication Snapshot

Call (when no prior scan in workflow):

```
analyze_clones(min_tokens=50)
```

Summary from act repo (2026-06-12, min_tokens 50):

```json
{
  "summary": {
    "files_analyzed": 5392,
    "clone_class_count": 8156,
    "duplicated_tokens": 5067066,
    "min_tokens": 50,
    "test_files_excluded": 47488
  }
}
```

Snapshot row: `duplicated_tokens`: 5,067,066 — `clone_class_count`: 8,156 — `min_tokens`: 50. On the next health check, compare `duplicated_tokens` only if that run also uses `min_tokens=50`; a run at 100 produces a different floor and the delta is not comparable.

## Project Map Updates

Updates the **"Health Snapshot"** section only. Appends to the Analysis History table.
