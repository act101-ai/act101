---
name: boundary-analysis
description: >
  Use when looking for extraction candidates, planning a module split, analyzing
  module boundaries, or before decomposing a large component. Also use when asked
  "where should I split this?" or "find natural module boundaries". Depth 2 —
  investigate. Produces extraction candidates with cut costs, layer violations,
  interface width assessment, orphan types, and a recommended decomposition sequence.
---

# Boundary Analysis

**Depth:** Level 2 (Investigate).

See `../analysis-protocol/references/protocol.md` for: artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and project
map structure. Read that document before proceeding.

## Phase 0: Refuted-Ledger Read (before any tool dispatch)

If `project-map.md` exists at the workspace root, read its
`## Refuted & Re-characterized Findings` ledger first (protocol mandate for depth-2+
skills). Do not re-investigate a refuted hypothesis unless this run surfaces new
contradicting evidence — carry it as "previously refuted (date), no new evidence".
During synthesis, add each newly refuted or re-characterized hypothesis from this
run's investigation to that ledger with the disproving evidence.

## Phase 1: Parallel Tool Dispatch

Dispatch all available tools in a **single parallel batch**.
Each subagent runs one tool, saves raw JSON to `raw/<tool-name>.json`, returns a
structured summary.

**Must-have tools:**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_clusters` | Current module groupings | `analyze_clusters` |
| `analyze_seams` | Natural boundaries | `analyze_seams` |

If both must-have tools are unavailable, report that and stop.

Interpret `analyze_seams` through `analyze_clusters` — canonical reading in the
protocol's Shared Interpretation Rules (seam / hub-collapse): empty seams are
actionable only when clustering produced at least two non-hub clusters.

**Extended tools (use if available, skip and note in manifest if not):**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_layers` | Layer detection + violations (S1+S2) | `analyze_layers` |
| `analyze_extraction` | Extraction candidates (M2) | `analyze_extraction` |
| `analyze_interfaces` | Cross-module contracts (M4) | `analyze_interfaces` |
| `analyze_cohesion` | Are current modules coherent? (H2) | `analyze_cohesion` |
| `analyze_interface_bloat` | Are APIs too wide? (H3) | `analyze_interface_bloat` |
| `analyze_orphan_types` | Misplaced type definitions (H4) | `analyze_orphan_types` |

## Phase 2: Investigation

For each significant finding, form a hypothesis before dispatching a subagent:

**Extraction candidate hypothesis example:**
> **Hypothesis N:** `<candidate>` can be extracted as a clean module.
> **Evidence:** `analyze_seams` identified a seam at this boundary; `analyze_extraction`
> scored it high.
> **Confirming query:** `analyze_surface` on the candidate files to measure
> cut cost (edges to sever vs. edges retained internally).
> **Confirms if:** Internal edges >> external edges (low cut cost relative to cohesion).
> **Refutes if:** External edges ≥ internal edges (high entanglement — extraction would
> be expensive).

**Layer violation hypothesis example:**
> **Hypothesis N:** The violation from `<source>` to `<target>` is structural (not
> accidental), indicating architectural erosion.
> **Evidence:** `analyze_layers` flagged an inversion from layer X to layer Y.
> **Confirming query:** `graph` on `<source>` to trace the full import path.
> **Confirms if:** Multiple files in layer X import from layer Y (pattern, not one-off).
> **Refutes if:** Single file, single import — likely a quick fix rather than erosion.

**Low-cohesion split hypothesis example:**
> **Hypothesis N:** `<file>` contains two distinct concept clusters that should be
> separate modules.
> **Evidence:** `analyze_cohesion` scored this module low; it is large.
> **Confirming query:** Read the `analyze_cohesion` LCOM4 fields. For any class with
> `lcom4` ≥ 2, its `components` are the disjoint method/field clusters — the NAMED split
> boundary, preferred over eyeballing the `skeleton`. Cross-check the `lcom4_summary`
> `modeled_kinds` for coverage honesty: a grammar absent from `modeled_kinds` is unjudged,
> not cohesive.
> **Confirms if:** A class reports `lcom4` ≥ 2 and its `components` partition the methods
> into groups with no shared state — split along those clusters.
> **Refutes if:** `lcom4` is 1 (methods share common state/fields), or the file's grammar
> is absent from `modeled_kinds` so cohesion was never judged.

**Interface bloat hypothesis example:**
> **Hypothesis N:** `<module>`'s public API is wider than necessary — some exports are
> never used externally.
> **Evidence:** `analyze_interface_bloat` flagged this module as over-exposed.
> **Confirming query:** `references` on each exported symbol.
> **Confirms if:** Several exports have 0 external callers.
> **Refutes if:** All exports have at least one external caller.

Save investigation notes to `investigation/hypothesis-N.md`.

## Report Structure

```markdown
# Boundary Analysis: <project name>

## Boundary Map
Current module structure with cluster sizes and labels.
Which clusters are cohesive vs. artificially grouped.

## Layer Architecture
Detected or user-specified layers. Direction consistency score.
(Present only if analyze_layers ran successfully.)

## Extraction Candidates
Ranked by extraction score. Per-candidate:
- Files included
- Internal vs. external edges
- API surface width
- Cut cost (edges to sever)
- Recommended extraction steps (specific act MCP operations)

## Layer Violations
(Present only if analyze_layers ran successfully.)
Per-violation: source layer, target layer, specific files involved, imported symbols,
fix recommendation. Distinguish: inversions (higher layer imports from lower) vs.
skips (layer bypasses an intermediate layer).

## Interface Width Assessment
(Present only if analyze_interface_bloat ran successfully.)
Modules with disproportionately wide public APIs.
Per-module: which exports are used externally, which are never called externally,
recommended visibility reduction.

## Orphan Types
(Present only if analyze_orphan_types ran successfully.)
Type definitions living in the wrong module.
Per-orphan: where defined, where used, recommended move destination.

## Cohesion Assessment
(Present only if analyze_cohesion ran successfully.)
Low-cohesion modules with natural split points. Per-module: cohesion score, identified
split boundary, recommended next step.
For each class with `lcom4` ≥ 2, report its `components` (the disjoint method/field
clusters) as the named split boundary — this is the LCOM4 evidence, preferred over an
eyeballed skeleton read. Quote the `lcom4_summary` `modeled_kinds` so coverage is honest:
a grammar absent from `modeled_kinds` was never judged and must not be reported as cohesive.

## Recommended Decomposition Steps
Prioritized, ordered steps to improve module boundaries.
Each step links to a specific act MCP tool call or skill.
Order: cheapest/highest-value extractions first, invasive restructuring last.

Before committing to a cut, simulate it. Express the proposed cut as `simulate` ops —
`split_file{file,groups}` for a class/module split, `move_file{from,to}` for a relocation —
and record the predicted deltas: `cycles.resolved`/`cycles.introduced`, the `coupling`
changes, `chokepoints`, and conformance `violations.cleared`/`violations.introduced` (the
last only when an `[architecture]` contract exists in `.act/config.toml`). `simulate` never
writes disk. Revise the cut if it introduces violations or fails to resolve the target cycle.
(Delta-field names match the architectural-refactoring skill's simulate step.)

To decide whether a suspected pass-through module is a real boundary at all — the
deletion test — simulate `delete_module{file}` and read the `deletions` delta in the
protocol's canonical order (Shared Interpretation Rules: `surface_consumers` first,
`surface_modeled` as the honesty gate, then `rewired_edges`/`severed_edges`).
```

## Project Map Updates

Updates **"Module Map"**, **"Layer Architecture"**, and **"Key Boundaries"** sections.
Adds newly refuted / re-characterized hypotheses to the **Refuted & Re-characterized
Findings** ledger (see Phase 0). Appends to the Analysis History table.
