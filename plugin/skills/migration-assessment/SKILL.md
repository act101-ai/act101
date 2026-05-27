---
name: migration-assessment
description: >
  Use when assessing migration readiness, planning a port to another language,
  understanding what makes this codebase hard to rewrite, or requesting "how ready
  is this for porting?". Depth 2 — investigate. Produces per-module readiness cards,
  recommended migration order, hard/soft blocker list, and platform dependency assessment.
  Optionally enriches the plan with security and history evidence (taint flow, secret
  surface, unsafe constructs, coverage, churn, ownership) so blockers reflect real
  porting risk, not structure alone. Replaces the migration-readiness-plus skill.
---

# Migration Assessment

**Depth:** Level 2 (Investigate).

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
| `analyze_readiness` | Composite migration score (M1) | `analyze_readiness` |

If `analyze_readiness` is unavailable, report that and stop — no useful migration
assessment is possible without it.

**Extended tools (use if available, skip and note in manifest if not):**

| Tool | Purpose | MCP call |
|------|---------|----------|
| `analyze_features` | Language feature inventory (M3) | `analyze_features` |
| `analyze_platform_deps` | Platform/runtime dependencies (M5) | `analyze_platform_deps` |
| `analyze_interfaces` | Cross-module contracts (M4) | `analyze_interfaces` |
| `analyze_type_completeness` | Type boundary holes (M7) | `analyze_type_completeness` |
| `analyze_fan_balance` | Migration ordering — fan-in/fan-out (M6) | `analyze_fan_balance` |
| `analyze_depth` | Dependency chain depth (S4) | `analyze_depth` |
| `analyze_inheritance` | Tangled inheritance hierarchies (H6) | `analyze_inheritance` |
| `analyze_patterns` | Hard porting blockers | `analyze_patterns` (use `--pattern porting_blockers` if available, else `--tier all`) |

## Phase 2: Investigation

For each file or module scored "hard" in readiness, or flagged as a hard blocker:

**Platform dependency hypothesis example:**
> **Hypothesis N:** The `<module>` module is migration-ready despite `<N>` platform
> deps because they're isolated behind a `<WrapperClass>` abstraction.
> **Evidence:** `analyze_readiness` scored it "needs-work"; `analyze_platform_deps`
> shows N imports of `<platform-api>`.
> **Confirming query:** `skeleton` on the wrapper file + `references`
> on the platform import symbol.
> **Confirms if:** Only the wrapper file imports the platform module directly.
> **Refutes if:** Multiple files import the platform module directly.

**Complexity blocker hypothesis example:**
> **Hypothesis N:** `<file>` is a hard blocker due to dynamic dispatch, not complexity.
> **Evidence:** `analyze_readiness` scored it "hard"; patterns flagged reflection/eval use.
> **Confirming query:** `skeleton` on the file to count dynamic call sites.
> **Confirms if:** Multiple reflection/eval call sites with no static alternative.
> **Refutes if:** Single call site that can be wrapped or replaced.

Save investigation notes to `investigation/hypothesis-N.md`.

## Report Structure

```markdown
# Migration Assessment: <project name>

## Readiness Summary
Ready / Needs work / Hard counts with percentages.
Overall verdict: **Ready** / **Needs work** / **Hard** — with confidence note.

## Recommended Migration Order
Foundation modules first (high fan-in, low fan-out — ported early, depended upon).
Orchestrators last (low fan-in, high fan-out — ported after their dependencies).
Numbered list with rationale per module.

## Porting Blockers
Per-file list with context from investigation.
Distinguish clearly:
- **Hard blockers:** eval, reflection, FFI, dynamic dispatch — no mechanical equivalent
- **Soft blockers:** high complexity, tight coupling — require refactor before porting

## Platform Dependencies
By category (filesystem, network, OS, process, browser, FFI).
For each dependency:
- Which files use it
- Wrapped vs. direct (direct = higher porting cost)
- Adaptation strategy for the target language

## Type Boundary Gaps
Modules with low type completeness.
Per-gap: module path, missing type annotations, impact on mechanical translation.

## Language Feature Concerns
Features with no direct equivalent in the target language.
Per-feature: count, affected files, suggested adaptation approach.

## Inheritance Complexity
Deep hierarchies and diamond inheritance patterns that complicate porting.
Per-finding: chain depth, members, recommended simplification before porting.

## Dependency Depth
Deepest dependency chains (leaf modules to port first).
Per-chain: length, root, leaf, recommended port order.

## Per-Module Readiness Cards
For each top-level module:
- Readiness score: ready / needs-work / hard
- Blocker count (hard / soft)
- Platform dep count
- Recommended action
```

## Project Map Updates

Appends or updates the **"Migration Readiness"** section. Appends to the Analysis
History table.

## Optional Enrichment: Security & History Evidence

The readiness scores above are structural/heuristic. When the workspace has the
relevant evidence, enrich the plan so the recommended migration order reflects real
porting risk — code that is hard to port AND dangerous AND historically volatile —
not just structural readiness. This is optional: skip any dimension whose evidence
or tier is unavailable and mark it UNASSESSED (never a clean bill).

**Tier:** composed tools enforce their own tiers — `unsafe_surface` Free,
`secret_surface` Pro, `taint_flow`/`coverage_overlay`/`ownership_map` Teams,
`churn_hotspots` Free for a single file / Teams in workspace mode. If a tool is
tier-blocked, its dimension is UNASSESSED — say so.

**Honesty caveat:** `taint_flow`/`secret_surface`/`unsafe_surface` report
`modeled_kinds` — read it per call. A non-empty mask means the dimension *was*
modeled for that grammar (an empty finding is then genuine); an empty/absent mask
means it was *not* modeled — "no evidence," not "clean." `coverage_overlay`/
`churn_hotspots`/`ownership_map` reflect one coverage run and the git history
present; state the window and `unmapped`.

| Tool | Enriches the plan with |
|---|---|
| `taint_flow` | Source→sink data-flow paths a port must preserve exactly — a hard porting hazard. |
| `secret_surface` | Secret-touching code needing careful handling / rotation during the move. |
| `unsafe_surface` | Unsafe blocks, eval, raw SQL, FFI, reflection, unsafe deserialization — rarely port 1:1. |
| `coverage_overlay` | Which modules have a test safety net for the port vs. which are flying blind. |
| `churn_hotspots` | Volatile modules — porting a still-changing target is a moving-target risk. |
| `ownership_map` | Bus factor — low ownership on a hard module concentrates the knowledge to port it. |

**Enrichment workflow (after the structural plan):**

1. Run `unsafe_surface` and `secret_surface` per module; run `taint_flow` on entry
   functions. Any unsafe construct, secret surface, or live taint path raises that
   module's effective difficulty above its structural score.
2. `coverage_overlay` (lcov `report`) — a low-coverage module cannot be safely
   verified after porting; front-load test work or reorder.
3. `churn_hotspots` (workspace) and `ownership_map` — a high-churn or low-bus-factor
   module is a scheduling risk: stabilize or pair-port it.
4. Recompute the order: structurally-ready AND well-tested AND low-risk first; hard +
   dangerous + volatile last (or split first). Reclassify any soft blocker that an
   unsafe/taint/secret finding promotes to a hard blocker.

When enrichment runs, each readiness card adds: taint paths, secret/unsafe hits,
coverage %, churn rank, and bus factor — and each blocker cites which evidence
dimension fired.
