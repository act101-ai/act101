---
name: health-check
description: Use when asked about code health, quality trends, what is getting worse, or for a periodic quality check. Produces a fast, trend-aware snapshot of hotspots, cohesion, duplication, test gaps, and security score.
---

# Health Check

**Depth:** Level 1 (Explore). Read `../analysis-protocol/references/protocol.md`
first: it defines the run artifacts, the investigation loop, the summary format, and
the project-map structure.

## Phase 1: Parallel tool dispatch

Dispatch every available tool in one parallel batch, one subagent per tool. Each
saves raw JSON to `raw/<tool-name>.json` and returns a structured summary.

**Must-have:**

| Tool | Purpose | Call |
|------|---------|------|
| `analyze_hotspots` | Complexity ranking (H1) | `analyze_hotspots` |
| `analyze_patterns` | Tier 1 structural smells | `analyze_patterns` with `tier: "fast"` |

If neither is available, report that and stop.

**Extended** (use if available; note skips in the manifest):

| Tool | Purpose | Call |
|------|---------|------|
| `analyze_coupling` | Instability overview | `analyze_coupling` |
| `analyze_cohesion` | Module cohesion (H2) | `analyze_cohesion` |
| `analyze_test_gaps` | Test coverage gaps | `analyze_test_gaps`; pass `coverage_report` for evidence-based statuses (`evidence: lcov`), otherwise statuses are convention-based |
| `analyze_inconsistencies` | Sibling pattern divergence (H5) | `analyze_inconsistencies` |
| `scan` | AI-Code Health Score plus AI-config-backdoor and MCP-RCE findings | `scan`, with `baseline` when `.act/baseline.json` is committed (see Trend). Scan auto-discovers lcov reports (`coverage/lcov.info`, `lcov.info`, `target/coverage/lcov.info`); when one is found, test-gap statuses are evidence-based and the `test_gaps` coverage record names the report and flags it `stale` if older than the newest source. Repeat that record's `evidence` clause in the report. |
| `analyze_clones` | Duplication mass | If `scan` already ran, take the Duplication row from its findings; otherwise call `analyze_clones` and report `summary.duplicated_tokens` and `summary.clone_class_count` |

## Phase 2: Follow-up

From the summaries, pick the top 3-5 findings and run one targeted follow-up each:
`skeleton` on each top hotspot to characterize it, and for untested high-coupling
files a note of the compound risk. One round only; this is a health check, not an
audit.

## Trend

**Score and class trend.** If `.act/scan-history.jsonl` exists, run
`act trends --root <repo>` (`--format markdown` for the report artifact) rather than
comparing scan scores by hand. It renders the score series, per-class count deltas,
top movers, and an Improving / Stable / Degrading verdict with documented bands.
Repos without a history file can adopt `act scan --history-append` in CI (full scans
only; scoped runs are rejected). Count deltas are not identity tracking; the
baseline below is the identity-level security trend.

**Prior run deltas.** Look in `.act/runs/` (and the legacy `docs/act/`, read-only)
for the most recent `manifest.json` with `"skill": "health-check"`. Load its
`raw/hotspots.json` and `raw/coupling.json` and report: new hotspots (appeared or
moved up), resolved hotspots (disappeared or moved down), coupling changes (lower
instability is improving), and the test-coverage trend when `raw/test_gaps.json`
exists in both runs (state whether each run's statuses were lcov-based or
convention-based).

**Security trend.** With a committed `.act/baseline.json`, pass
`baseline=".act/baseline.json"` on the Phase 1 `scan` call. The report's `baseline`
section is the trend: `new` (regressions since the baseline), `fixed` (remediated
debt), `baselined` (acknowledged debt still present). Without a baseline, record one
with `baseline_write` (CLI `act scan --baseline-write`), commit it, and the next
health check gets real deltas. Scores compare only across identical scan semantics;
a diff-scoped scan (`base_ref`) is never comparable to a full-repo scan.

**Duplication trend.** `summary.duplicated_tokens` is comparable across runs only
when both used the same `min_tokens`; a cross-threshold comparison is not a trend.

The verdict is **Improving** / **Stable** / **Degrading**. When `act trends` ran,
adopt its verdict unless the artifact deltas contradict it, and say so if they do.

## Report structure

```markdown
# Health Check: <project name>

## Health Summary
Verdict: **Improving** / **Stable** / **Degrading**, with a one-paragraph assessment.
If `scan` ran, lead with its AI-Code Health Score (0-100) and list any
`ai_config_backdoor` or `mcp_config_rce` findings as critical items.

## Duplication Snapshot
`duplicated_tokens`: N, `clone_class_count`: N, `min_tokens`: N (from scan or
analyze_clones).

## Top Hotspots
Per hotspot: file path, complexity score, what skeleton revealed, recommended action.

## Cohesion Issues
Per issue: module, cohesion score, suggested split boundary.

## Pattern Inconsistencies
Per divergence: the group convention, and how this file differs.

## Test Gaps
Untested files ranked by risk (coupling × blast radius if available, else coupling).
Per gap: file path, risk factors, suggested test type. State the `evidence` basis.

## Trend
(Only if prior run data exists.)
| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Top hotspot score | N | N | ↑/↓/= |
| Hotspot count (top 10) | N | N | ↑/↓/= |
| Mean instability | N | N | ↑/↓/= |
| Test gap count | N | N | ↑/↓/= |
| Duplicated tokens (same min_tokens only) | N | N | ↑/↓/= |

What improved, what degraded, what is new. If `scan` ran with a baseline, lead the
security line with the `new` / `fixed` / `baselined` counts.

## Suggested Fixes
Prioritized act MCP tool calls or skills to run.
```

## Project map updates

Updates the **Health Snapshot** section only. Appends to the Analysis History table.
