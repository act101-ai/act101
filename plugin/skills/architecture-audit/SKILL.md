---
name: architecture-audit
description: >
  Use when asked to audit architecture, produce a comprehensive architectural overview,
  get the full structural picture of a codebase, assess overall health and porting
  readiness, find module boundaries, circular dependencies, coupling hotspots, dead code,
  or code patterns. Depth 3 — full audit with hypothesis-driven investigation.
  Replaces the architectural-analysis skill.
---

# Architecture Audit

**Depth:** Level 3 (Full Audit).

See `../analysis-protocol/references/protocol.md` for: artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and project
map structure. Read that document before proceeding.

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

**Anomaly flags — investigate regardless of smell match:**
- Cluster containing 1 file (orphan or misclassified)
- Cluster containing >30% of all files (god cluster)
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
4. Write `report.md`, update `project-map.md` (full rewrite of all sections)

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

## Risks
Causal chains: what breaks first, what cascades, minimum intervention.

## Recommendations
Prioritized, actionable steps. Each linked to a confirmed finding
and a specific act MCP tool call or skill.
```

## Project Map Updates

Updates **all sections** of `project-map.md` (workspace root, full rewrite). Appends to the
Analysis History table.

## Rules

1. Dispatch Phase 1 in a single parallel batch — never sequentially
2. Write all hypotheses before dispatching Phase 2 — no browsing without a hypothesis
3. Evidence chains, not data points — explain what scores mean structurally
4. Follow new signals — if a Phase 2 subagent finds something unexpected, dispatch a
   follow-up (capped at one extra round)
5. Note negative space — absence of expected problems is a finding
6. Executive summary must include an explicit Ready / Needs work / Not ready verdict
