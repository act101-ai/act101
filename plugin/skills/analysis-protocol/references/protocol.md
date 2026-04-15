---
name: analysis-protocol
description: >
  Shared protocol for all analysis skills — artifact structure, investigation loop,
  depth levels, summary format, and token budget rules. Included by all five analysis
  skills. Do not invoke this skill directly.
---

# Analysis Protocol

All analysis skills share this protocol. It defines the common machinery: artifact
directory structure, investigation depth levels, the investigation loop steps, summary
format, and token budget rules.

## Artifact Directory Structure

```
project-map.md                     # living document at workspace root, tracked in git
docs/act/
└── <YYYY-MM-DD-HHMMSS>/          # timestamped run directory (gitignored)
    ├── manifest.json              # what was run, when, which tools, which skill
    ├── raw/                       # tool JSON outputs (one file per tool invocation)
    │   ├── hotspots.json
    │   ├── coupling.json
    │   └── ...
    ├── investigation/             # follow-up exploration results (depth 2+)
    │   ├── hypothesis-1.md
    │   └── ...
    └── report.md                  # synthesized narrative for this run
```

`project-map.md` lives at the workspace root and is tracked in git — it is the durable
living document. The `docs/act/` tree holds ephemeral timestamped reports and is
gitignored. Timestamped subdirectories prevent collisions and enable trend comparison.

## Investigation Depth Levels

| Level | Name | What happens | Used by |
|-------|------|-------------|---------|
| 0 | **Collect** | Run tools, save raw output, produce summary | Change Impact |
| 1 | **Explore** | Collect + one round of follow-up on top findings | Health Check |
| 2 | **Investigate** | Explore + hypothesis formation, targeted confirmation, evidence chains | Boundary Analysis, Migration Assessment |
| 3 | **Full Audit** | Investigate + cross-category synthesis, smell taxonomy, anomaly flags | Architecture Audit |

## The Investigation Loop

### Step 1: Setup

Create `docs/act/<YYYY-MM-DD-HHMMSS>/` and `raw/` subdirectory.

Write `manifest.json`:
```json
{
  "skill": "<skill-name>",
  "timestamp": "<YYYY-MM-DD-HHMMSS>",
  "target": "<target if applicable, else null>",
  "tools": ["<tool1>", "<tool2>"],
  "skipped": ["<unavailable-tool1>"]
}
```

### Step 2: Collect (all depths)

Dispatch all tools for this skill **in parallel** via subagents. Each subagent:
1. Runs one tool
2. Saves the raw JSON output to `raw/<tool-name>.json`
3. Returns a structured summary to the main agent — counts, names, scores, file paths

The main agent receives **summaries only** — raw output stays in subagents and on disk,
never in the main conversation.

Each subagent prompt must include:
> "Run `<command>`. Save the raw output to `<path>/raw/<tool-name>.json`. Return a
> structured summary of the findings — include counts, names, scores, and file paths.
> Do not return raw tool output."

### Step 3: Explore (depth 1+)

From summaries, identify the top 3-5 findings worth exploring. For each, run one
targeted follow-up:
- `skeleton` on a flagged file
- `references` on a flagged symbol
- `analyze_surface` on a flagged boundary

Fold follow-up context into the findings before proceeding.

### Step 4: Investigate (depth 2+)

Form explicit hypotheses before dispatching any Phase 2 subagents:

> **Hypothesis N:** `<module/cluster/seam name>` exhibits `<smell/issue name>`.
> **Evidence:** `<what Collect/Explore showed>`.
> **Confirming query:** `<exact act MCP tool call>`.
> **What confirms it:** `<what the output must show>`.
> **What refutes it:** `<what the output would show if the issue isn't present>`.

Dispatch one subagent per hypothesis. Each returns: confirmed/refuted, evidence, any
new signals. If a new signal is architecturally significant, dispatch one additional
follow-up (cap: one extra round per hypothesis).

Save investigation notes to `investigation/hypothesis-N.md`.

### Step 5: Full Audit (depth 3 only)

- Cross-reference findings across all categories using the smell taxonomy
- Check anomaly flags
- Build evidence chains connecting multiple data points into named architectural smells
- Note meaningful negative space (expected problems that weren't found)

### Step 6: Synthesize (all depths)

- Write `report.md` with sections appropriate to the skill (see each skill for its report structure)
- Classify every finding by severity: **critical** / **warning** / **info**
- Include recommendations with specific next actions and act MCP tool calls
- Update `project-map.md` (workspace root) sections per the update rules (see each skill)
- Return the Common Summary to the calling agent

## Common Summary Format

Every skill returns this brief summary to the calling agent (not the full report):

```
## <Skill Name>: <Verdict>

**Top findings:**
1. [critical/warning/info] finding description
2. [critical/warning/info] finding description
3. [critical/warning/info] finding description

**Full report:** docs/act/<timestamp>/report.md
**Project map:** project-map.md (updated / not updated)
**Suggested next actions:** <specific skill or manual step>
```

## Token Budget Rules

- Subagents protect the main context — raw tool output stays in subagents and on disk,
  **never** in the main conversation
- `manifest.json` records every tool call made
- Depth 0-1: cheap (a few tool calls + summaries)
- Depth 2-3: can dispatch 10-20+ subagent calls — scope hypotheses before dispatching
- For trend comparison in Health Check: load prior `raw/*.json` directly, don't re-run tools

## Tool Availability

Not all extended tools are implemented yet. Every skill handles this gracefully:

- Before dispatching, check which tools are available (call will return error if unavailable)
- Unavailable tools: skip, note in `manifest.json` as `"skipped": ["tool-name"]`
- Proceed with available tools — a partial report is better than no report
- If a skill's must-have tools are all unavailable, inform the agent:
  > "Required tools not available: [list]. Cannot produce a useful [skill name] report."

## Project Map Structure

`project-map.md` (workspace root) is the living architectural document. All skills that modify
it append a row to the Analysis History table. Full structure:

```markdown
# Project Map: <project name>

> Last updated: <date> by <skill name>

## Overview
- Languages, file count, symbol count
- Primary framework/patterns detected
- One-paragraph architectural summary

## Module Map
Clusters with labels, sizes, and one-line descriptions.
Which modules are foundational, which are orchestrators, which are leaf.

## Layer Architecture
Detected layers with directory mappings.
Known violations.

## Key Boundaries
Natural seams, API surface width, cleanliness assessment.

## Chokepoints & Risks
High-centrality files, risky cycles, unstable foundations.
"If you're touching these files, run Change Impact first."

## Health Snapshot
Top hotspots, cohesion issues, test gap summary.
Trend direction if multiple runs exist (improving/stable/degrading).

## Migration Readiness
(Present only after Migration Assessment has run)
Ready/needs-work/hard counts, recommended migration order summary.

## Analysis History
| Date | Skill | Verdict | Report |
|------|-------|---------|--------|
```
