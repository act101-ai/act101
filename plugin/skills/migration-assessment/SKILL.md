---
name: migration-assessment
description: Use when assessing migration readiness, planning a port to another language, or asked "how ready is this for porting?". Produces per-module readiness cards, a recommended migration order, hard and soft blockers, and platform dependencies, optionally enriched with security and history evidence.
---

# Migration Assessment

**Depth:** Level 2 (Investigate). Read `../analysis-protocol/references/protocol.md`
first: it defines the run artifacts, the investigation loop, the summary format, and
the project-map structure.

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

**Must-have:** `analyze_readiness` (composite migration score, M1). Without it, report
that and stop.

**Extended** (use if available; note skips in the manifest):

| Tool | Purpose |
|------|---------|
| `analyze_features` | Language feature inventory (M3) |
| `analyze_platform_deps` | Platform and runtime dependencies (M5) |
| `analyze_interfaces` | Cross-module contracts (M4) |
| `analyze_type_completeness` | Type boundary holes (M7) |
| `analyze_fan_balance` | Fan-in/fan-out for migration ordering (M6) |
| `analyze_depth` | Dependency chain depth (S4) |
| `analyze_inheritance` | Tangled inheritance hierarchies (H6) |
| `analyze_patterns` | Hard porting blockers: `pattern: "porting_blockers"` if available, else `tier: "all"` |

**Monorepos.** When the repo is a workspace with package manifests, run the
structural pass at package granularity so readiness cards map to real packages:
`analyze_clusters` and `analyze_layers` with `granularity: package` cluster and
layer the package dependency graph (`DependsOn` edges from manifests), giving the
cross-package porting order; `analyze_conformance` with `granularity: package`
checks deny rules against package names. The graph's package nodes report which
manifest kinds were modeled (empty when none). Fall back to file or directory
granularity when no workspace manifest exists.

## Phase 2: Investigation

For each file or module scored "hard" or flagged as a hard blocker, form a
hypothesis and save the notes to `investigation/hypothesis-N.md`.

**Platform dependency:**
> **Hypothesis N:** `<module>` is migration-ready despite `<N>` platform deps because they are isolated behind `<WrapperClass>`.
> **Evidence:** `analyze_readiness` scored it "needs-work"; `analyze_platform_deps` shows N imports of `<platform-api>`.
> **Confirming query:** `skeleton` on the wrapper file, and `references` on the platform import symbol.
> **Confirms if:** only the wrapper file imports the platform module directly.
> **Refutes if:** several files import it directly.

**Complexity blocker:**
> **Hypothesis N:** `<file>` is a hard blocker because of dynamic dispatch, not complexity.
> **Evidence:** `analyze_readiness` scored it "hard"; patterns flagged reflection or eval.
> **Confirming query:** `skeleton` on the file to count dynamic call sites.
> **Confirms if:** several reflection or eval sites with no static alternative.
> **Refutes if:** a single site that can be wrapped or replaced.

## Optional enrichment: security and history evidence

Readiness scores are structural. When the workspace has the evidence, enrich the
plan so the migration order reflects real porting risk: code that is hard to port
and dangerous and volatile. Skip any dimension whose evidence or tier is unavailable
and mark it UNASSESSED.

| Tool | Tier | Adds |
|---|---|---|
| `taint_flow` | Architecture | Source-to-sink paths a port must preserve exactly |
| `secret_surface` | Engineering | Secret-touching code needing careful handling or rotation |
| `unsafe_surface` | Free | Unsafe blocks, eval, raw SQL, FFI, reflection, unsafe deserialization: rarely port 1:1 |
| `coverage_overlay` | Architecture | Which modules have a test safety net for the port |
| `churn_hotspots` | Free per file, Architecture in workspace mode | Volatile modules: a moving target |
| `ownership_map` | Architecture | Bus factor: low ownership on a hard module concentrates the knowledge to port it |

After the structural plan:

1. `unsafe_surface` and `secret_surface` per module, and `taint_flow` on entry
   functions. Any unsafe construct, secret surface, or live taint path raises the
   module's effective difficulty above its structural score.
2. `coverage_overlay` with the lcov `report`: a low-coverage module cannot be
   verified after porting, so front-load test work or reorder.
3. `churn_hotspots` (workspace mode) and `ownership_map`: a high-churn or
   low-bus-factor module is a scheduling risk; stabilize it or pair-port it.
4. Recompute the order: structurally ready, well tested, and low risk first; hard,
   dangerous, and volatile last or split first. Promote any soft blocker that an
   unsafe, taint, or secret finding turns into a hard one.

With enrichment, each readiness card adds taint paths, secret and unsafe hits,
coverage percent, churn rank, and bus factor, and each blocker names the evidence
dimension that fired. `taint_flow`, `secret_surface`, and `unsafe_surface` report
`modeled_kinds` per call: a non-empty mask with an empty finding is genuine, an
empty mask means the dimension was not modeled. The overlays describe one coverage
run and the git history present; state the window and `unmapped`.

## Report structure

```markdown
# Migration Assessment: <project name>

## Readiness Summary
Ready / Needs work / Hard counts with percentages, and an overall verdict of
**Ready** / **Needs work** / **Hard** with a confidence note.

## Recommended Migration Order
Foundation modules first (high fan-in, low fan-out), orchestrators last (low
fan-in, high fan-out). Numbered, with a rationale per module.

## Porting Blockers
Per file, with investigation context. Hard blockers (eval, reflection, FFI, dynamic
dispatch: no mechanical equivalent) vs. soft blockers (high complexity, tight
coupling: refactor before porting).

## Platform Dependencies
By category (filesystem, network, OS, process, browser, FFI). Per dependency: files
using it, wrapped vs. direct, adaptation strategy for the target language.

## Type Boundary Gaps
Per gap: module path, missing type annotations, impact on mechanical translation.

## Language Feature Concerns
Per feature with no direct target-language equivalent: count, affected files,
suggested adaptation.

## Inheritance Complexity
Per finding: chain depth, members, simplification recommended before porting.

## Dependency Depth
Per chain: length, root, leaf, recommended port order (leaves first).

## Per-Module Readiness Cards
Per top-level module: readiness (ready / needs-work / hard), blocker counts (hard /
soft), platform dep count, recommended action, and enrichment evidence when it ran.
```

## Project map updates

Appends or updates the **Migration Readiness** section. Adds newly refuted or
re-characterized hypotheses to the **Refuted & Re-characterized Findings** ledger.
Appends to the Analysis History table.
