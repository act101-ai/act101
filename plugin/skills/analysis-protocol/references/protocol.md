# Analysis Protocol

Shared reference for the analysis-family skills — artifact directory structure, the
investigation loop, depth levels, summary format, and token budget rules. Cited by
architecture-audit, health-check, boundary-analysis, deepening-survey,
migration-assessment, change-impact, and security-surface (create-work-loop also
cites the File-Location Convention below). This directory intentionally has no `SKILL.md`: the protocol is
an include for the skills above, not an invocable skill.

## File-Location Convention (normative for all act101 skills)

Three rules govern every artifact path a skill prescribes. An explicit operator
instruction or an established project convention always overrides these defaults —
state the default, then defer.

**Rule 1 — Persistent ledgers: workspace root, stable undated names, git-tracked.**
A persistent ledger holds cross-run state: `project-map.md`, `remediation-log.md`,
work-loop trackers (`<program>-work-loop.md`), and refuted ledgers (today a section
of `project-map.md`; if ever split into its own file, that file follows this rule).
Ledgers live at the workspace root under a stable, undated, canonical name. Dates
live inside — dated log rows and entries — never in the filename.

**Rule 2 — Ephemeral artifacts: default under `.act/`.**
Ephemeral artifacts are one-shot dated outputs: run reports, raw tool JSON,
manifests, investigation notes, specs, implementation plans, loop-cycle artifacts.

- Run artifacts: `.act/runs/<YYYY-MM-DD-HHMMSS>/` (structure below), **gitignored** —
  ensure a `.act/runs/` entry exists in the target repo's `.gitignore`.
- Skill-prescribed specs and plans: `.act/specs/YYYY-MM-DD-<slug>.md` and
  `.act/plans/YYYY-MM-DD-<id>-<slug>.md`, **committed** (plans are resume state;
  trackers reference plan paths).
- Legacy discovery: when looking for prior runs, also check the legacy `docs/act/`
  location read-only; new runs never write there.
- Reserved: `.act/receipts/`, `.act/baseline.json`, `.act/scan-history.jsonl`, and
  `.act/config.toml` are act product state — never write skill artifacts there.

**Rule 3 — Dating arity: exactly one dating level per ephemeral artifact path.**
Either the filename carries a `YYYY-MM-DD-` prefix and no ancestor directory is
date-stamped, or the filename is undated inside exactly one date-stamped directory.
Never zero, never two. Formats: single-file artifacts use `YYYY-MM-DD-` filename
prefixes; run directories use `YYYY-MM-DD-HHMMSS` (collision-safe for multiple runs
a day). Persistent ledgers are exempt via Rule 1.

## Artifact Directory Structure

```
project-map.md                     # living STATE document at workspace root, tracked in git
remediation-log.md                 # append-only ACTION ledger at workspace root, tracked in git
.act/runs/
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
living document, full-rewritten by the analysis skills each run. The `.act/runs/` tree holds
ephemeral timestamped reports and is gitignored. Timestamped subdirectories prevent collisions
and enable trend comparison.

`remediation-log.md` also lives at the workspace root and is tracked in git, but it is
**append-only** and owned by the `architectural-refactoring` skill, not the analysis skills.
It records *actions taken* (one row per verified remediation, keyed to a finding ID), as opposed
to the map's *current state*. Keeping the two separate avoids two skills clobbering one file:
refactoring appends to the log; analysis skills only **read** it (in Phase 0) and fold confirmed
remediations into the map narrative. It must stay out of the gitignored `.act/runs/<YYYY-MM-DD-HHMMSS>/` tree so
it survives as a durable record.

## Investigation Depth Levels

| Level | Name | What happens | Used by |
|-------|------|-------------|---------|
| 0 | **Collect** | Run tools, save raw output, produce summary | Change Impact |
| 1 | **Explore** | Collect + one round of follow-up on top findings | Health Check |
| 2 | **Investigate** | Explore + hypothesis formation, targeted confirmation, evidence chains | Boundary Analysis, Deepening Survey, Migration Assessment |
| 3 | **Full Audit** | Investigate + cross-category synthesis, smell taxonomy, anomaly flags | Architecture Audit |

Inline-default skills (change-impact, security-surface) sit outside the depth ladder —
they follow this loop only when running in artifact mode (see each skill's artifact-mode
section).

## The Investigation Loop

### Step 1: Setup (artifact-writing runs only)

Inline-mode runs (change-impact's default, security-surface's default) return their
summary directly and skip artifact setup entirely — steps 1 and 6's file writes apply
only when a run writes artifacts.

Create `.act/runs/<YYYY-MM-DD-HHMMSS>/` and `raw/` subdirectory. Ensure `.act/runs/`
is listed in the target repo's `.gitignore` (add the entry if missing).

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

## Shared Interpretation Rules

Canonical readings shared by the skills that use these tools. Skills cite this
section instead of restating it.

### Seam / hub-collapse interpretation

Interpret `analyze_seams` through the `analyze_clusters` output that feeds it.
`total_seams: 0` only means no crossing edges between the detected clusters — it is
NOT evidence that no boundary exists. When clustering reports fewer than two non-hub
clusters, `hub_collapse: true`, or one cluster holding the whole scope, treat seam
output as uninformative: report the cluster artifact and investigate with dampened
clusters (`dampen_top_k`), `split_module`, `analyze_surface`, or `simulate`.

### The deletion test (delete_module) — reading order

To decide whether a suspected pass-through module is a real boundary, simulate
`delete_module{file}`: it drops the module, re-wires transitive bridges
(`A→M→B` ⇒ `A→B`), and reports a `deletions` delta. Read it in this order:

1. `surface_consumers` — external symbols that **call or extend the module's own
   symbols** (`top_consumers` names them). A non-zero count means the module is
   load-bearing — those dependencies can never be re-homed because the
   callee/superclass body is deleted. Cite the count and a name or two instead of
   arguing the deletion test in prose.
2. `surface_modeled` — **honesty gate.** `surface_consumers: 0` is a genuine conduit
   signal ONLY when this is `true`. When `false` the call channel was not modeled for
   the module's grammar; the verdict is UNKNOWN, never "clean conduit" (field-access
   consumption is not modeled at all — treat 0 with care).
3. `rewired_edges` / `severed_edges` — the file-import routing side: high
   `rewired_edges` with `severed_edges: 0` and `surface_consumers: 0` (modeled) is a
   clean pass-through whose callers only routed through it.

## Common Summary Format

Artifact-writing runs return this brief summary to the calling agent (not the full report); inline-mode skills define their own summary format in their SKILL.md:

```
## <Skill Name>: <Verdict>

**Top findings:**
1. [critical/warning/info] finding description
2. [critical/warning/info] finding description
3. [critical/warning/info] finding description

**Full report:** .act/runs/<YYYY-MM-DD-HHMMSS>/report.md
**Project map:** project-map.md (updated / not updated)
**Suggested next actions:** <specific skill or manual step>
```

When confirmed structural findings warrant remediation, the suggested next action is to run the
remediation skill that closes the cycle (for Architecture Audit: `architectural-refactoring`), not
a cherry-picked inline fix — the skill records remediations to `remediation-log.md` and feeds the
next audit. Recommend a one-off tool call or manual step only for work that falls outside a
remediation pass.

## Token Budget Rules

- Subagents protect the main context — raw tool output stays in subagents and on disk,
  **never** in the main conversation
- `manifest.json` records every tool call made
- Depth 0-1: cheap (a few tool calls + summaries)
- Depth 2-3: can dispatch 10-20+ subagent calls — scope hypotheses before dispatching
- For trend comparison in Health Check: load prior `raw/*.json` directly, don't re-run tools

## Tool Availability

Not all extended tools are implemented yet. Every skill handles this gracefully:

- Discover availability with `status()` (tool list + tier state); treat an unavailable-tool call error as a skip
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

## Refuted & Re-characterized Findings
Persistent ledger of hypotheses investigated and NOT confirmed (refuted / partially
refuted / re-characterized) and tool outputs that are artifacts rather than findings.
Carried forward every run; re-opened only on new contradicting evidence. Read first
(before tool dispatch) so audits don't re-flag disproven smells.
| Finding | Status | Since | Evidence / why |
|---------|--------|-------|----------------|

## Analysis History
| Date | Skill | Verdict | Report |
|------|-------|---------|--------|
```

Skills that run hypothesis-driven investigation (Architecture Audit, depth 2+) must read the
Refuted & Re-characterized Findings ledger before dispatching tools and update it during
synthesis. See each skill for its Phase 0 / Project Map Updates rules.
