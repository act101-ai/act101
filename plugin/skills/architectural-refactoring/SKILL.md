---
name: architectural-refactoring
description: Use when breaking circular dependencies, splitting god classes, reducing coupling between modules, extracting interfaces at seams, or executing any structural change identified by an architecture audit. Requires a prior architecture-audit run that produced project-map.md and a report.
---

# Architectural Refactoring with act

Execute structural decompositions from an architectural analysis report.

## Prerequisites

- `project-map.md` at the workspace root: the living architectural document,
  including its `## Refuted & Re-characterized Findings` ledger.
- A run report at `.act/runs/<YYYY-MM-DD-HHMMSS>/report.md`; use the highest
  timestamp (legacy runs may sit read-only under `docs/act/`). `.act/runs/` is
  gitignored, so on a fresh clone the report may be absent while `project-map.md`
  survives; then work from the map and re-run `architecture-audit` to regenerate a
  report.

If neither exists, run the `architecture-audit` skill first.

## Rules

1. **Start from the audit.** Read `project-map.md` and the latest report first.
   Every refactoring decision traces to a confirmed finding by its finding ID. Check
   the Refuted ledger before acting: a smell already investigated and disproven is
   left alone.
2. **Find boundaries, don't invent them.** Use `act analyze seams` together with
   `act analyze clusters`. A zero-seam result is not proof that no boundary exists;
   read it per the protocol's seam / hub-collapse rule and use dampened clusters,
   `split_module`, and `simulate` to find the smallest verified cut.
3. **Measure before cutting.** `act analyze surface --files <files>` gives the API
   surface of a proposed extraction. A surface that is too wide means the extraction
   adds coupling rather than removing it.
4. **Break cycles first.** `act analyze cycles` finds them; break the simplest edge
   in each.
5. **Extract interfaces at seams.** `act query interface <file>` shows the current
   API; `act refactor extract-interface <Class> <InterfaceName>` creates the
   interface both sides depend on.
6. **Stable foundations first.** Start with the lowest-instability modules in
   `act analyze coupling` and make them independent before touching unstable ones.
7. **Measure the reduction.** After each step, re-run `act analyze coupling` and
   `act analyze cycles` to confirm coupling dropped and cycles broke.
8. **Clean up with dead-code analysis.** Run `act analyze dead-code` before and
   after each major step.
9. **Record every remediation** as one row in `remediation-log.md` (workspace root),
   keyed to the finding ID it resolves (see Recording remediations). Leave
   `project-map.md` to `architecture-audit`, which folds the log into it on the next
   run.
10. **Small, verifiable steps.** Each step is small enough to verify on its own, and
    is committed on its own. One structural change at a time.

## Workflow

1. Read `project-map.md` (including its Refuted ledger) and the latest report.
2. Prioritize confirmed findings by ID: cycles > god classes > high coupling > dead code
3. For each finding:
   a. Confirm it is still present (`act analyze cycles`, `act analyze coupling`).
   b. Plan the change: identify boundaries and seams, measure the surface.
   c. **Simulate before cutting.** Call `simulate(ops=[…], include=[…])` with the
      planned change as `split_file`, `move_file`, `remove_edge`, `merge_files`, or
      `delete_module` ops and record the predicted deltas (cycles resolved, coupling
      changes, violations cleared or introduced) in the remediation row's "Verified
      by" cell. For a chokepoint or refuted-ledger row that hinges on "is this wide
      module load-bearing or a pass-through?", `delete_module{file}` settles it: read
      the `deletions` delta in the protocol's canonical order (`surface_consumers`
      first, `surface_modeled` as the honesty gate, then `rewired_edges` and
      `severed_edges`) and record the surface count plus a named consumer. Example
      for a god-module split:

      ```
      simulate(ops=[{op: "split_file", file: "src/core.ts", groups: [["parseUser", "validateUser"], ["formatReport"]]}])
      ```

      The result shows `cycles.resolved`, `coupling.changed` (per-unit before and
      after instability), and, when an `[architecture]` contract exists,
      `violations.cleared` and `violations.introduced`. Revise a cut that introduces
      violations or leaves the target cycle unresolved before touching disk.
   d. Execute with `act refactor` operations. When the change is the same transform
      repeated across many sites, author and run a recipe instead (see Mass changes).
   e. Verify: re-run the specific analysis, run the tests.
   f. Commit the code change.
   g. Append the remediation row to `remediation-log.md` in its own follow-up commit,
      since the row's `Commit` column names the step-f commit.
4. After the batch, re-run `architecture-audit`. It reads the log, re-verifies each
   claimed fix against fresh structural evidence, and folds confirmed remediations
   into the map. That closes one audit → refactor → re-audit cycle; the next cycle
   starts from the refreshed map.

**When there is nothing to remediate** (every confirmed finding is already
`RESOLVED` in the log, or the report holds only refuted and re-characterized
entries), the next step is a fresh audit, not invented work and not a re-opened
refuted smell. Hand off the same way the audit does: "Clear context, then run
`/architecture-audit`." A new audit re-baselines against the current structure and
surfaces the next layer of findings.

## Mass changes: author a recipe

When a remediation is the same transform repeated across many sites (a deprecation
rename, an import reorganization, wrapping a recurring pattern), drive it as a
codemod recipe. A recipe (`match → transform → optional verify`) runs one
`act refactor` operation across every matching site, atomically, with optional
gate verification and receipts. Site-by-site `act refactor` calls are for the few
one-off cuts.

Run it with the `recipe_run` MCP tool or `act recipe run <recipe.toml>`:

1. **Preview** (`preview` / `--preview`) lists every match and its planned
   operation. Confirm the match set is exactly the intended sites before applying.
2. **Verify behavior-changing transforms.** A pure rename needs only the match set
   checked. For a transform that can change behavior (wrapping awaits,
   restructuring calls), enable the recipe's verify stage so the gate trio runs over
   each changed file; sites that fail come back `FLAGGED` instead of applied.
3. **Cut atomically** with `all_or_nothing` / `--all-or-nothing` when the change
   must land whole: if any site fails, the run rolls back through history and the
   tree is untouched.
4. **Record receipts** with `receipts` / `--receipts` and put the receipt IDs in the
   remediation row's "Verified by" cell.

`recipe_run` parameters: `recipe_path` (required), `root`, `preview`,
`all_or_nothing`, `receipts`. Its per-site report (matched / applied / failed /
flagged / rolled_back) is the evidence for the remediation row; one recipe run
resolves the finding across all sites, so log it as a single remediation.
`recipe_run` is Enterprise tier.

## Recording remediations

Remediations go in an append-only ledger, separate from `project-map.md` (the
protocol's Artifact Directory Structure explains the split): the log is action
history, the map is current state.

- **File:** `remediation-log.md` at the workspace root, git-tracked, sibling of
  `project-map.md`. It must be durable, so it never lives under the gitignored
  `.act/runs/` tree.
- **Append only.** Existing rows are never rewritten or reordered. One row per
  verified step.
- **Key every row to a finding ID** from the report it resolves, so the next audit
  can match the claim against the live structure.

Row format:

```markdown
| Date | Finding | Status | Change | Commit | Verified by |
|------|---------|--------|--------|--------|-------------|
| 2026-05-28 | C-3 (auth↔router cycle) | RESOLVED | Extracted `AuthPort` interface at the seam; router depends on the interface, not auth | abc1234 | `act analyze cycles` → 0 cycles; tests pass |
| 2026-06-12 | C-7 (validateAge logic) | RESOLVED | Tightened boundary condition in validateAge | def5678 | `act analyze coupling` → 0 violations; receipt `8bb683bbfe8e27cf` |
```

When the step ran `act gate --receipts` (or `gate(receipts=true)`), or a refactor op
ran with `receipt=true`, put the receipt IDs in the Verified-by cell beside the
structural check. Receipts are evidence, not authority: a hash or schema mismatch at
consumption time discards the receipt and triggers fresh verification. Emission
mechanics and the receipt schema are in the refactor-receipt skill.

`Status` is `RESOLVED` (fix verified) or `PARTIAL` (reduced, with what remains
noted). The next `architecture-audit` reads this log in Phase 0, re-verifies each
claim against fresh structural evidence, and reflects confirmed fixes in the map,
flagging any claim the structure contradicts.

## Delegation

- `refactoring` skill for individual operations (rename, extract, move).
- `code-generation` skill for scaffolding new modules.
- `code-navigation` skill to understand code before modifying it.

## Focus

- `act analyze cycles --max-length 3` for the tightest cycles first.
- `act analyze coupling --threshold 0.7` for the most unstable modules.
- `act query skeleton` instead of reading full files.
- Re-run only the analysis your change affects, not the full suite.
