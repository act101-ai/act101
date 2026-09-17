---
name: boundary-analysis
description: Use when looking for extraction candidates, planning a module split, analyzing module boundaries, or asked "where should I split this?". Produces ranked extraction candidates with cut costs, layer violations, interface width, orphan types, and a decomposition sequence.
---

# Boundary Analysis

**Depth:** Level 2 (Investigate). Read `../analysis-protocol/references/protocol.md`
first: it defines the run artifacts, the investigation loop, the Shared
Interpretation Rules, the summary format, and the project-map structure.

## Phase 0: Refuted ledger

If `project-map.md` exists at the workspace root, read its `## Refuted &
Re-characterized Findings` ledger before any tool call. A refuted hypothesis is
re-investigated only when this run surfaces new contradicting evidence; otherwise
carry it as "previously refuted (date), no new evidence". During synthesis, add each
newly refuted or re-characterized hypothesis to the ledger with its disproving
evidence.

## Phase 1: Parallel tool dispatch

Dispatch every available tool in one parallel batch, one subagent per tool. Each
saves raw JSON to `raw/<tool-name>.json` and returns a structured summary.

**Must-have:**

| Tool | Purpose |
|------|---------|
| `analyze_clusters` | Current module groupings |
| `analyze_seams` | Natural boundaries |

If both are unavailable, report that and stop. Interpret `analyze_seams` through
`analyze_clusters` per the protocol's seam / hub-collapse rule: empty seams are
actionable only when clustering produced at least two non-hub clusters.

**Extended** (use if available; note skips in the manifest):

| Tool | Purpose |
|------|---------|
| `analyze_layers` | Layer detection and violations (S1+S2) |
| `analyze_extraction` | Extraction candidates (M2) |
| `analyze_interfaces` | Cross-module contracts (M4) |
| `analyze_cohesion` | Are current modules coherent? (H2) |
| `analyze_interface_bloat` | Are APIs too wide? (H3) |
| `analyze_orphan_types` | Misplaced type definitions (H4) |

## Phase 2: Investigation

Form a hypothesis for each significant finding before dispatching a subagent, and
save the notes to `investigation/hypothesis-N.md`.

**Extraction candidate:**
> **Hypothesis N:** `<candidate>` can be extracted as a clean module.
> **Evidence:** `analyze_seams` found a seam at this boundary; `analyze_extraction` scored it high.
> **Confirming query:** `analyze_surface` on the candidate files, to measure cut cost (edges to sever vs. edges retained).
> **Confirms if:** internal edges far outnumber external edges.
> **Refutes if:** external edges equal or exceed internal edges.

**Layer violation:**
> **Hypothesis N:** the violation from `<source>` to `<target>` is structural, not accidental.
> **Evidence:** `analyze_layers` flagged an inversion from layer X to layer Y.
> **Confirming query:** `graph` on `<source>` to trace the full import path.
> **Confirms if:** several files in layer X import from layer Y.
> **Refutes if:** one file, one import: a quick fix, not erosion.

**Low-cohesion split:**
> **Hypothesis N:** `<file>` holds two distinct concept clusters that should be separate modules.
> **Evidence:** `analyze_cohesion` scored the module low, and it is large.
> **Confirming query:** the `analyze_cohesion` LCOM4 fields. A class with `lcom4` of 2 or more lists its `components`, the disjoint method and field clusters: that is the named split boundary. Check `lcom4_summary.modeled_kinds`: a grammar absent from it was never judged.
> **Confirms if:** `lcom4` is 2 or more and the `components` partition the methods into groups sharing no state.
> **Refutes if:** `lcom4` is 1, or the grammar is absent from `modeled_kinds`.

**Interface bloat:**
> **Hypothesis N:** `<module>`'s public API is wider than needed.
> **Evidence:** `analyze_interface_bloat` flagged it as over-exposed.
> **Confirming query:** `references` on each exported symbol.
> **Confirms if:** several exports have no external callers.
> **Refutes if:** every export has at least one external caller.

## Report structure

```markdown
# Boundary Analysis: <project name>

## Boundary Map
Current module structure with cluster sizes and labels; which clusters are
cohesive and which are artificially grouped.

## Layer Architecture
(Only if analyze_layers ran.) Detected or user-specified layers; direction
consistency score.

## Extraction Candidates
Ranked by extraction score. Per candidate: files included, internal vs. external
edges, API surface width, cut cost (edges to sever), and the act MCP operations
that would perform the extraction.

## Layer Violations
(Only if analyze_layers ran.) Per violation: source layer, target layer, files
involved, imported symbols, fix. Distinguish inversions (higher layer imports from
lower) from skips (a layer bypasses an intermediate layer).

## Interface Width Assessment
(Only if analyze_interface_bloat ran.) Per over-wide module: exports used
externally, exports never called externally, recommended visibility reduction.

## Orphan Types
(Only if analyze_orphan_types ran.) Per orphan: where defined, where used,
recommended destination.

## Cohesion Assessment
(Only if analyze_cohesion ran.) Per low-cohesion module: cohesion score, the
`components` of any class with `lcom4` of 2 or more as the named split boundary,
and the next step. Quote `lcom4_summary.modeled_kinds`; a grammar absent from it was
never judged and is not reported as cohesive.

## Recommended Decomposition Steps
Ordered, cheapest and highest-value extractions first, invasive restructuring last.
Each step names a specific act MCP tool call or skill.

Before committing to a cut, simulate it: express the cut as `simulate` ops
(`split_file{file,groups}` for a class or module split, `move_file{from,to}` for a
relocation) and record the predicted deltas: `cycles.resolved` and
`cycles.introduced`, the `coupling` changes, `chokepoints`, and, when an
`[architecture]` contract exists in `.act/config.toml`, `violations.cleared` and
`violations.introduced`. `simulate` never writes to disk. Revise a cut that
introduces violations or leaves the target cycle unresolved. (The delta field names
match the architectural-refactoring skill's simulate step.)

To decide whether a suspected pass-through module is a real boundary, simulate
`delete_module{file}` and read the `deletions` delta in the protocol's canonical
order: `surface_consumers` first, `surface_modeled` as the honesty gate, then
`rewired_edges` and `severed_edges`.
```

## Project map updates

Updates **Module Map**, **Layer Architecture**, and **Key Boundaries**. Adds newly
refuted or re-characterized hypotheses to the **Refuted & Re-characterized Findings**
ledger. Appends to the Analysis History table.
