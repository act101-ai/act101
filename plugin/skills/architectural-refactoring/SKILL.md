---
name: architectural-refactoring
description: >
  Execute structural decompositions based on an architectural analysis report.
  Use when breaking circular dependencies, splitting god classes, reducing coupling
  between modules, extracting interfaces at seam boundaries, or executing any
  large-scale structural change identified in an architectural analysis. Requires
  a prior architecture audit (the architecture-audit skill) that produced
  project-map.md and a run report.
---

# Architectural Refactoring with act

Execute structural decompositions based on an architectural analysis report.

## Prerequisites

A prior architecture audit must exist:

- `project-map.md` at the workspace root — the living architectural document, including its
  `## Refuted & Re-characterized Findings` ledger.
- A run report at `.act/runs/<YYYY-MM-DD-HHMMSS>/report.md` — use the run with the highest
  timestamp (legacy runs may sit read-only under `docs/act/`). `.act/runs/` is gitignored, so on a fresh clone the report may be absent even though
  `project-map.md` (which carries findings and the Refuted ledger forward) survives. If no local
  report exists, work from `project-map.md` and re-run `architecture-audit` to regenerate one.

If neither exists, run the `architecture-audit` skill first. (`architecture-audit` replaces the
former `architectural-analysis` skill. If any doc still references that name, or a single
`docs/architectural-analysis-report.md`, it is stale — use the artifacts above.)

## Rules

1. **Start from the audit** — Read `project-map.md` and the latest `.act/runs/<YYYY-MM-DD-HHMMSS>/report.md` first. Every refactoring decision must trace back to a confirmed finding (by its finding ID) in that report. Check the map's Refuted & Re-characterized Findings ledger first — never "fix" a smell that was already investigated and disproven.

2. **Find boundaries, don't invent them** — Use `act analyze seams` together with `act analyze clusters`. A zero-seam result is not proof that no boundary exists — canonical reading in the protocol's Shared Interpretation Rules (seam / hub-collapse); use dampened clusters, `split_module`, and `simulate` to identify the smallest verified cut.

3. **Evaluate before cutting** — Before extracting a module, use `act analyze surface --files <files>` to measure the API surface. If the surface is too wide, the extraction will create more coupling, not less.

4. **Break cycles first** — Circular dependencies are the highest priority. Use `act analyze cycles` to find them, then break the simplest edge in each cycle.

5. **Extract interfaces at seams** — At each seam boundary, extract an interface that both sides depend on. Use `act query interface <file>` to understand the current API, then `act refactor extract-interface` to create it.

6. **Stable foundations first** — Start with the most stable modules (lowest instability in `act analyze coupling`). Make them independent before touching unstable modules.

7. **Measure coupling reduction** — After each refactoring step, re-run `act analyze coupling` and `act analyze cycles` to verify that coupling decreased and cycles were broken.

8. **Use dead code analysis for cleanup** — Before and after each major refactoring, run `act analyze dead-code` to identify symbols that are no longer needed.

9. **Record every remediation** — After each verified step, append one row to `remediation-log.md` (workspace root) keyed to the finding ID it resolves (see Recording Remediations). Do **not** edit `project-map.md` — `architecture-audit` owns the map and folds the log into it on the next run. To refresh the map after a batch of remediations, re-run `architecture-audit`.

10. **Incremental, verifiable steps** — Each refactoring step should be small enough to verify independently. Commit after each step. Never make multiple structural changes at once.

## Workflow

1. Read `project-map.md` (including its Refuted ledger) and the latest `.act/runs/<YYYY-MM-DD-HHMMSS>/report.md`
2. Prioritize confirmed findings by ID: cycles > god classes > high coupling > dead code
3. For each finding:
   a. Verify it's still present (`act analyze cycles` / `act analyze coupling`)
   b. Plan the refactoring (identify boundaries/seams, measure surface)
   c. **Before cutting, simulate the intended change** — call
      `simulate(ops=[…], include=[…])` with the planned change expressed as
      `split_file`/`move_file`/`remove_edge`/`merge_files`/`delete_module` ops and record the
      predicted deltas (cycles resolved, coupling changes, violations cleared/introduced) in the
      remediation row's "Verified by" cell. For a chokepoint or refuted-ledger row that hinges
      on "is this wide module load-bearing or a pass-through?", `delete_module{file}` settles it
      deterministically — read the `deletions` delta in the protocol's canonical order (Shared
      Interpretation Rules: `surface_consumers` first, `surface_modeled` as the honesty gate,
      then `rewired_edges`/`severed_edges`). Record the surface count + a named consumer in the
      "Verified by" cell instead of re-arguing the deletion test by hand. Example for a planned
      split of a god module:

      ```
      simulate(ops=[{op: "split_file", file: "src/core.ts", groups: [["parseUser", "validateUser"], ["formatReport"]]}])
      ```

      The result shows `cycles.resolved`, `coupling.changed` (per-unit before/after instability),
      and — when an `[architecture]` contract exists — `violations.cleared`/`violations.introduced`.
      If the simulation introduces new violations or does not resolve the target cycle, revise the
      cut before touching disk.
   d. Execute the refactoring using `act refactor` operations. **When the change is
      a repetitive mass edit** — the same transform repeated across many sites (a
      deprecation rename across the codebase, an import reorganization, wrapping a
      pattern) — do not hand-edit site by site. Author and run a recipe instead (see
      Mass Changes below).
   e. Verify the fix (re-run the specific analysis, check tests)
   f. Commit the code fix
   g. Append a remediation row to `remediation-log.md` — its `Commit` column references the
      step-f commit; record the log row in its own follow-up commit (don't try to embed the row
      in the very commit it names)
4. After the batch, re-run `architecture-audit` to refresh `project-map.md`. It reads the log,
   re-verifies each claimed fix against fresh structural evidence, and folds confirmed
   remediations into the map. This closes one audit → refactor → re-audit cycle; the next cycle
   starts from the refreshed map and goes deeper.

**If there's nothing to remediate** — when the report's confirmed findings are already all
`RESOLVED` in `remediation-log.md`, or the report surfaces no confirmed actionable findings (only
refuted/re-characterized entries remain), do **not** invent work and do **not** re-open refuted
smells. The cycle's next step is a fresh audit, not a manufactured refactor. Recommend it the same
clean-slate way the audit hands off to you: "Clear context, then run `/architecture-audit`." A new
audit re-baselines against the current structure and surfaces the next layer of findings — that is
how the cycle goes deeper: refactoring exhausts a report, the audit produces the next one.

## Mass Changes — Author a Recipe, Don't Hand-Edit

When a structural remediation is the **same transform repeated across many sites** —
a deprecation rename propagated through the codebase, an import reorganization, wrapping
a recurring pattern — drive it as a codemod recipe rather than editing each site by hand.
A recipe (`match → transform → optional verify`) runs one `act refactor` operation in bulk
across every matching site, atomically, with optional gate-verify and receipts. This is the
executor for repetitive mass changes; reserve site-by-site `act refactor` calls for the
handful of one-off cuts.

Run it via the `recipe_run` MCP tool, or `act recipe run <recipe.toml>` on the CLI:

1. **Preview first.** Run with `preview` (MCP) / `--preview` (CLI) to list every match and
   its planned operation before anything touches disk. Confirm the match set is exactly the
   sites you intend — no more, no less — before applying.
2. **Verify behaviour-changing transforms.** A pure rename only needs the match set checked.
   For any transform that can change behaviour (wrapping awaits, restructuring calls), enable
   the recipe's verify stage so the E6 gate trio runs over each changed file; sites that fail
   verification come back `FLAGGED` instead of silently applied.
3. **Cut atomically.** For a remediation that must land as a single all-or-nothing change,
   set `all_or_nothing` (MCP) / `--all-or-nothing` (CLI) — if any site fails, the whole run
   rolls back via history and the tree is left untouched.
4. **Record receipts.** Run with `receipts` (MCP) / `--receipts` (CLI) to emit E7 receipts for
   verified transforms, and record the receipt ID(s) in the remediation row's "Verified by"
   cell exactly as for any other receipted step (see Recording Remediations).

`recipe_run` parameters: `recipe_path` (required), `root`, `preview`, `all_or_nothing`,
`receipts`. The per-site report it returns (matched / applied / failed / flagged / rolled_back)
is the evidence for the remediation row — one recipe run resolves the finding across all sites,
so log it as a single remediation keyed to the finding ID. `recipe_run` is an Enterprise tool.

## Recording Remediations

Remediations go in an append-only ledger, **not** in `project-map.md` (separation rationale:
the protocol's Artifact Directory Structure). Keep the action history separate from the state
document:

- **File:** `remediation-log.md` at the workspace root (git-tracked, sibling of `project-map.md`).
  It must be durable, so do **not** place it under the gitignored `.act/runs/<YYYY-MM-DD-HHMMSS>/` tree.
- **Append only.** Never rewrite or reorder existing rows. One row per verified step.
- **Key every row to a finding ID** from the report it resolves, so the next audit can match the
  claim against the live structure.

Row format:

```markdown
| Date | Finding | Status | Change | Commit | Verified by |
|------|---------|--------|--------|--------|-------------|
| 2026-05-28 | C-3 (auth↔router cycle) | RESOLVED | Extracted `AuthPort` interface at the seam; router depends on the interface, not auth | abc1234 | `act analyze cycles` → 0 cycles; tests pass |
| 2026-06-12 | C-7 (validateAge logic) | RESOLVED | Tightened boundary condition in validateAge | def5678 | `act analyze coupling` → 0 violations; receipt `8bb683bbfe8e27cf` |
```

When the remediation step ran `act gate --receipts` (or `gate(receipts=true)`) over the change,
or a refactor op was run with `receipt=true`, record the receipt ID(s) in the Verified-by cell
alongside the structural check. Receipts are evidence, never authority — any hash or schema
mismatch at consumption time discards the receipt and falls back to fresh verification
automatically. Emission mechanics and the receipt JSON schema live in the refactor-receipt skill;
this skill only records the IDs.

`Status` is `RESOLVED` (fix verified) or `PARTIAL` (reduced but not eliminated — note what
remains). The next `architecture-audit` reads this log in Phase 0, re-verifies each claim against
fresh structural evidence, and reflects confirmed fixes in the map (flagging any claim the
structure contradicts). That hand-off — refactoring writes the log, the audit folds it into the
map — is what lets the audit → refactor cycle run repeatedly and go deeper each pass.

## Delegation

- Use `refactoring` skill for individual operations (rename, extract, move)
- Use `code-generation` skill for scaffolding new modules
- Use `code-navigation` skill to understand code before modifying it

## Token-Saving Hints

- Use `act analyze cycles` with `--max-length 3` to focus on the tightest cycles first
- Use `act analyze coupling --threshold 0.7` to focus on the most unstable modules
- Use `act query skeleton` instead of reading full files
- Re-run only the specific analysis that your change affects, not the full suite
