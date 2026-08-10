# Work-Loop Tracker Template

Instantiate every section below. `«guillemets»` mark slots to fill; HTML comments explain the failure mode each section prevents — read them while instantiating, then drop them from the generated file.

---

```markdown
# «Program Name» Work Loop — «one-line arc, e.g. "Instrumentation → Verification → Surfaces"»

**This file is the resumable state of the «program» program.** To continue in any session: *"resume the work in `«tracker path»`"*.

**Authority chain:** acceptance criteria live in «spec doc(s), with row-prefix mapping if multiple — e.g. "spec-a.md (I-rows), spec-b.md (W/S-rows)"». This file owns ordering and state only — it never restates or overrides spec content. New findings get spec amendments first, then a queue row here.

<!-- If this project has other work loops, name what is inherited and what is excluded.
     Named exclusions prevent "did they forget X?" archaeology later. -->
**Pattern notes:** «inherited conventions, explicit exclusions».

---

## Resume protocol (follow exactly)

1. Read this file fully. Find the first row in the queue whose State is not `DONE`/`DROPPED`. **Branch & PR rules** (defaults; an operator instruction always wins): defer to operator instructions at all times; absent instructions — on the default branch → create a work branch before the first commit, already on a non-default branch → keep working in it; at work-loop completion open a PR for operator review, never merge except by explicit operator request. «Workspace facts: worktree/concurrency specifics — e.g. "No worktrees. On lock contention with a concurrent agent, wait and retry; never delete the lock."»
2. Read that item's spec section. **Re-verify the spec's premises against live code before acting** — never trust prior summaries, plans, or git history; the spec records a baseline that may have drifted. If drift changes the premise, add a dated amendment to the spec, then proceed (or mark the row `DROPPED` with the evidence if the premise is gone).
3. Act according to the row's State:
   - `TODO` → **Plan.** Write the implementation plan «via the project's planning skill, if one exists» to `«plans dir; default .act/plans/ (committed), project convention overrides»/YYYY-MM-DD-<id>-<slug>.md` — dated filename in an undated directory, exactly one dating level (bite-sized TDD tasks with checkboxes). Plan bar (a project planning skill overrides): zero-context implementer; exact paths; complete content — no placeholders; failing-check → pass steps with expected output; global constraints in the header; spec-coverage self-review. Set State `PLANNED` + plan path. Commit the plan and this file together.
   - `PLANNED` → **Execute.** Run the plan «via the project's execution skill(s)», checking off steps in the plan file as they complete — the checkboxes are the fine-grained resume state; this table is the coarse state. Execution bar (a project execution skill overrides): follow steps exactly; read every verification's actual output; stop and mark `BLOCKED` rather than guess; subagents get fresh, complete, sequential dispatches with output contracts. Set State `IN-PROGRESS` at first commit.
   - `IN-PROGRESS` → **Continue the plan file** at its first unchecked step.
4. **Review before closing.** When the plan's steps are complete, run a review pass over the item's changes «via the project's review skill, or a careful self-review against the spec section». Review findings are fixed in-item or captured per rule 5 — never noted-and-ignored.
5. **New findings rule (always in force):** any defect discovered mid-item is in scope — nothing is deferred as "pre-existing" or parked in a follow-ups list. If it blocks the current item, fix it inside the item. Otherwise: add a dated amendment to the appropriate spec (full problem/required-behavior/acceptance format), append an `F-n` row to the queue, and keep going. `F-n` rows carry the same closing discipline as planned rows.
6. **Close an item** only when every acceptance criterion in its spec section passes with shown output. Verification floor: «exact commands per surface — e.g. "`cargo check/test/clippy -p <crate>` per touched crate; worker rows: vitest suite"». Set the row `DONE` with commit refs. One item fully closed before the next begins.
7. Update this file's queue table **in the same commit** as the state change it records. The table must never be stale relative to committed work.

**Hard rules inherited from «project rules source»:** «verbatim list — e.g. "TDD with shown failing output; no stubs; never --no-verify; never git stash; no commits directly to main"».

«Optional program-specific disciplines — per-surface release rules, subagent assignment rules, tool-runtime guidance. Include only what this program actually needs.»

---

## Queue

States: `TODO` → `PLANNED` → `IN-PROGRESS` → `DONE` | `BLOCKED(reason)` | `DROPPED(evidence)`

<!-- One table per phase. Every item from the authority specs gets a row NOW, even far-future
     ones — a complete queue is what makes "first non-DONE row" a total resume algorithm. -->

### Phase «X» — «name» (spec: «doc»)

| ID | Item | Spec § | State | Plan | Refs |
|----|------|--------|-------|------|------|
| «X1» | «item summary — a pointer, not a restatement» | «§» | TODO | — | — |

«…further phases…»

<!-- Findings phase: starts empty; F-n rows land here as discovered. Its existence in the
     template is the point — a designated place means findings get rows instead of vanishing. -->

### Findings (appended as discovered; spec amendment required first)

| ID | Item | Spec amendment | State | Plan | Refs |
|----|------|----------------|-------|------|------|

**Ordering notes:** «dependency facts and user ordering decisions, dated. The user owns reordering.»

---

## Log

<!-- One row per closure or notable event: what changed semantically, dogfood numbers,
     defects found in-item, comparability warnings. The Log is how a resuming session
     learns what the queue table is too terse to say. -->

| Date | Event |
|------|-------|
| «date» | Tracker created from «spec(s)». Queue seeded: «row summary». |
```
