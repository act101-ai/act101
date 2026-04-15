---
name: health-check
description: >
  Use when asked about code health, quality trends, what's getting worse, or for a
  periodic quality check. Depth 1 — fast, trend-aware. Produces a health snapshot
  with hotspots, cohesion issues, test gaps, and trend comparison if prior runs exist.
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
| `analyze_test_gaps` | Test coverage gaps (R5) | `analyze_test_gaps` |
| `analyze_inconsistencies` | Sibling pattern divergence (H5) | `analyze_inconsistencies` |

## Phase 2: Follow-up (Explore depth)

From summaries, identify the top 3-5 findings and run one targeted follow-up each:

- For each top hotspot: run `skeleton` to characterize what's wrong
- For untested high-coupling files: note the compound risk (untested + high blast radius)

Keep follow-ups to one round — this is a health check, not a full audit.

## Trend Comparison

Check `docs/act/` for a prior Health Check run: look for a `manifest.json` with
`"skill": "health-check"`. If found:

1. Load the most recent prior run's `raw/hotspots.json` and `raw/coupling.json`
2. Report deltas:
   - New hotspots since last run (files that appeared or moved up)
   - Resolved hotspots (files that disappeared or moved down)
   - Coupling changes (improving = lower instability, degrading = higher)
   - Test coverage trend (if `raw/test_gaps.json` exists in both runs)

Verdict must reflect the trend: **Improving** / **Stable** / **Degrading**.

## Report Structure

```markdown
# Health Check: <project name>

## Health Summary
Verdict: **Improving** / **Stable** / **Degrading**.
One-paragraph assessment.

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

What improved, what degraded, what's new since last run.

## Suggested Fixes
Prioritized list of specific act MCP tool calls or skills to run.
```

## Project Map Updates

Updates the **"Health Snapshot"** section only. Appends to the Analysis History table.
