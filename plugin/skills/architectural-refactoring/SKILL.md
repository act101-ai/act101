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
- A run report at `docs/act/<YYYY-MM-DD-HHMMSS>/report.md` — use the run with the highest
  timestamp. `docs/act/` is gitignored, so on a fresh clone the report may be absent even though
  `project-map.md` (which carries findings and the Refuted ledger forward) survives. If no local
  report exists, work from `project-map.md` and re-run `architecture-audit` to regenerate one.

If neither exists, run the `architecture-audit` skill first. (`architecture-audit` replaces the
former `architectural-analysis` skill. If any doc still references that name, or a single
`docs/architectural-analysis-report.md`, it is stale — use the artifacts above.)

## Rules

1. **Start from the audit** — Read `project-map.md` and the latest `docs/act/<ts>/report.md` first. Every refactoring decision must trace back to a confirmed finding (by its finding ID) in that report. Check the map's Refuted & Re-characterized Findings ledger first — never "fix" a smell that was already investigated and disproven.

2. **Find seams, don't invent them** — Use `act analyze seams` to identify natural boundaries. Refactor along these boundaries, not against them.

3. **Evaluate before cutting** — Before extracting a module, use `act analyze surface --files <files>` to measure the API surface. If the surface is too wide, the extraction will create more coupling, not less.

4. **Break cycles first** — Circular dependencies are the highest priority. Use `act analyze cycles` to find them, then break the simplest edge in each cycle.

5. **Extract interfaces at seams** — At each seam boundary, extract an interface that both sides depend on. Use `act query interface <file>` to understand the current API, then `act refactor extract-interface` to create it.

6. **Stable foundations first** — Start with the most stable modules (lowest instability in `act analyze coupling`). Make them independent before touching unstable modules.

7. **Measure coupling reduction** — After each refactoring step, re-run `act analyze coupling` and `act analyze cycles` to verify that coupling decreased and cycles were broken.

8. **Use dead code analysis for cleanup** — Before and after each major refactoring, run `act analyze dead-code` to identify symbols that are no longer needed.

9. **Record every remediation** — After each verified step, append one row to `remediation-log.md` (workspace root) keyed to the finding ID it resolves (see Recording Remediations). Do **not** edit `project-map.md` — `architecture-audit` owns the map and folds the log into it on the next run. To refresh the map after a batch of remediations, re-run `architecture-audit`.

10. **Incremental, verifiable steps** — Each refactoring step should be small enough to verify independently. Commit after each step. Never make multiple structural changes at once.

## Workflow

1. Read `project-map.md` (including its Refuted ledger) and the latest `docs/act/<ts>/report.md`
2. Prioritize confirmed findings by ID: cycles > god classes > high coupling > dead code
3. For each finding:
   a. Verify it's still present (`act analyze cycles` / `act analyze coupling`)
   b. Plan the refactoring (identify seams, measure surface)
   c. Execute the refactoring using `act refactor` operations
   d. Verify the fix (re-run the specific analysis, check tests)
   e. Commit the code fix
   f. Append a remediation row to `remediation-log.md` — its `Commit` column references the
      step-e commit; record the log row in its own follow-up commit (don't try to embed the row
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

## Recording Remediations

Remediations go in an append-only ledger, **not** in `project-map.md`. The map is a full-state
document that `architecture-audit` rewrites wholesale on every run — writing remediations into it
would be clobbered on the next audit and would put two skills in conflict over one file. Keep the
action history separate from the state document:

- **File:** `remediation-log.md` at the workspace root (git-tracked, sibling of `project-map.md`).
  It must be durable, so do **not** place it under the gitignored `docs/act/<ts>/` tree.
- **Append only.** Never rewrite or reorder existing rows. One row per verified step.
- **Key every row to a finding ID** from the report it resolves, so the next audit can match the
  claim against the live structure.

Row format:

```markdown
| Date | Finding | Status | Change | Commit | Verified by |
|------|---------|--------|--------|--------|-------------|
| 2026-05-28 | C-3 (auth↔router cycle) | RESOLVED | Extracted `AuthPort` interface at the seam; router depends on the interface, not auth | abc1234 | `act analyze cycles` → 0 cycles; tests pass |
```

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
