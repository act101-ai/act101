# Work-Loop Tracker Template

Instantiate every section below. `«guillemets»` mark slots to fill; HTML comments explain the failure mode each section prevents — read them while instantiating, then drop them from the generated file.

> ## ⛔ STOP — DO NOT INVENT RULES
>
> Do not write rules, gates, checks, hooks, thresholds, budgets, ledgers, or authorization schemes into the generated tracker without explicit operator authorization.
>
> - A rule the operator did not ask for is not a rule. It is a defect.
> - Every rule you write cites who authorized it and when. No citation, delete it. Do not debate it.
> - A rule is blocking work and nobody can point to the operator asking for it? Delete the rule. Never write a second rule to work around the first.
> - This covers anything that can refuse, block, gate, count, budget, ration, or slow work down.
> - Sounding like good engineering practice is not authorization. Good intentions wrote every invented rule that has already broken a loop.
>
> Ask the operator. Wait for the answer. Then write the rule, with the citation.

---

```markdown
# «Program Name» Work Loop — «one-line arc, e.g. "Instrumentation → Verification → Surfaces"»

**This file is the resumable state of the «program» program.** To continue in any session: *"resume the work in `«tracker path»`"*.

**Authority chain:** acceptance criteria live in «spec doc(s), with row-prefix mapping if multiple — e.g. "spec-a.md (I-rows), spec-b.md (W/S-rows)"». This file owns ordering and state only — it never restates or overrides spec content. New findings get spec amendments first, then a queue row here.

<!-- If this project has other work loops, name what is inherited and what is excluded.
     Named exclusions prevent "did they forget X?" archaeology later. -->
**Pattern notes:** «inherited conventions, explicit exclusions».

<!-- The file group (operator direction 2026-09-21): this file is the ACTIVE tracker, the only
     file a resume reads. Rows waiting for a slot live in the backlog; closed rows and old Log
     entries live in the history. The archive step moves rows between the three files, so this
     file stays small enough to read in full on every resume. -->
**File group:** active `«tracker path»` (this file) · backlog `«program»-work-loop-backlog.md` (open rows waiting; never resume from it) · history `«program»-work-loop-history.md` (closed rows and old Log entries, verbatim; never read on a normal resume).

---

## Current snapshot

<!-- The status block is machine-maintained: the archive step regenerates it at every close and
     every sync. Never edit it by hand. The Next row line is the operator's queue-head override:
     the ids in its first sentence, in order, are worked (and pulled in from the backlog) first. -->
«status block — written by the first run of the archive step»
- **Next row:** «optional, operator-set: the id(s) to work first, e.g. "F-12, then F-9."»

---

## Resume protocol (follow exactly)

1. **Display the file-group status** («status command — e.g. `python3 scripts/archive_work_loop.py status «tracker path»`»): open and closed rows here, rows in the backlog, archived rows in the history (DONE and DROPPED separately), the id union, and the head of the queue. Then run the integrity check (below) and the hygiene check «project hygiene command, if any — e.g. `scripts/loop_hygiene.sh check`»; both must pass before any work, and hygiene runs again before every gate. Read this file fully. The row to work is the head of the queue: the snapshot's **Next row** id, else the first row in the queue whose State is not `DONE`/`DROPPED`. **Branch & PR rules** (defaults; an operator instruction always wins): defer to operator instructions at all times; absent instructions — on the default branch → create a work branch before the first commit, already on a non-default branch → keep working in it; at work-loop completion open a PR for operator review, never merge except by explicit operator request. «Workspace facts: worktree/concurrency specifics — e.g. "No worktrees. On lock contention with a concurrent agent, wait and retry; never delete the lock."»
2. Read that item's spec section. **Re-verify the spec's premises against live code before acting** — never trust prior summaries, plans, or git history; the spec records a baseline that may have drifted. If drift changes the premise, add a dated amendment to the spec, then proceed (or mark the row `DROPPED` with the evidence if the premise is gone).
3. Act according to the row's State:
   - `TODO` → **Plan.** Write the implementation plan «via the project's planning skill, if one exists» to `«plans dir; default .act/plans/ (committed), project convention overrides»/YYYY-MM-DD-<id>-<slug>.md` — dated filename in an undated directory, exactly one dating level (bite-sized TDD tasks with checkboxes). Plan bar (a project planning skill overrides): zero-context implementer; exact paths; complete content — no placeholders; failing-check → pass steps with expected output; global constraints in the header; spec-coverage self-review. Set State `PLANNED` + plan path. Commit the plan and this file together.
   - `PLANNED` → **Execute.** Run the plan «via the project's execution skill(s)», checking off steps in the plan file as they complete — the checkboxes are the fine-grained resume state; this table is the coarse state. Execution bar (a project execution skill overrides): follow steps exactly; read every verification's actual output; stop and mark `BLOCKED` rather than guess; subagents get fresh, complete, sequential dispatches with output contracts. Set State `IN-PROGRESS` at first commit.
   - `IN-PROGRESS` → **Continue the plan file** at its first unchecked step.
4. **Review before closing.** When the plan's steps are complete, run a review pass over the item's changes «via the project's review skill, or a careful self-review against the spec section». Review findings are fixed in-item or captured per rule 5 — never noted-and-ignored.
5. **New findings rule (always in force):** any defect discovered mid-item is in scope — nothing is deferred as "pre-existing" or parked in a follow-ups list. If it blocks the current item, fix it inside the item. Otherwise: add a dated amendment to the appropriate spec (full problem/required-behavior/acceptance format), append an `F-n` row to the backlog's Findings table (the archive step pulls it into this file when a slot opens), and keep going. `F-n` rows carry the same closing discipline as planned rows.
6. **Close an item** only when every acceptance criterion in its spec section passes with shown output. Verification floor: «exact commands per surface — e.g. "`cargo check/test/clippy -p <crate>` per touched crate; worker rows: vitest suite"». Set the row `DONE` with commit refs. One item fully closed before the next begins.
7. Update this file's queue table **in the same commit** as the state change it records. The table must never be stale relative to committed work.
8. **Archive and refill at every close and every sync.** Run «archive command — e.g. `python3 scripts/archive_work_loop.py «tracker path»`» and commit its moves with the close. It moves closed rows beyond the newest «N, default 25» and Log entries older than «D, default 14» days verbatim to `«program»-work-loop-history.md` (append-only; never edited); makes this file's open rows the next «O, default 25» rows of the whole group's work order — the **Next row** ids first, then the queue order — moving lower-ranked waiting rows to the backlog and higher-ranked ones in (a started row never leaves this file and counts against «O»); and regenerates the status block. Rows move verbatim; IDs are never reused or renumbered. A second run is a no-op; `--dry-run` writes nothing. The integrity check refuses this file over any cap.

**Hard rules inherited from «project rules source»:** «verbatim list — e.g. "TDD with shown failing output; no stubs; never --no-verify; never git stash; no commits directly to main"».

«Optional program-specific disciplines — per-surface release rules, subagent assignment rules, tool-runtime guidance. Include ONLY rules the operator asked for, each with its authorization citation (who, when). Nothing here is yours to invent — see the notice at the top of the template.»

---

## Integrity check

<!-- The caps are a refusal, not advice: a loop that skips its archive step is stopped at commit
     and in CI instead of growing its resume cost silently. Archived and waiting rows stay
     allocated — the check reads the backlog and the history so IDs remain unique and contiguous
     across all three files. -->

Run before every tracker commit: «integrity command — e.g. `python3 scripts/validate_remediation_trackers.py --group «tracker path»`». It refuses: more than «O, default 25» open rows here; more than «N, default 25» closed rows here; a Log entry more than «D, default 14» days older than the newest one; a duplicate or missing ID across this file, the backlog and the history; an archived row in an open state; a malformed row.

---

## Queue

States: `TODO` → `PLANNED` → `IN-PROGRESS` → `DONE` | `BLOCKED(reason)` | `DROPPED(evidence)`

<!-- One table per phase. Every item from the authority specs gets a row NOW, even far-future
     ones — a complete queue is what makes "first non-DONE row" a total resume algorithm. Write
     every row here; the archive step's first run moves the rows beyond the open-row cap to the
     backlog, under the same phase headings, and pulls them back as rows close. -->

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

<!-- One row per closure or notable event, ONE LINE each: what changed, the commits, the row.
     Detail lives in the row, the plan, or the commit message — a Log that narrates is a Log
     nobody can afford to resume from. Entries older than the cap move to the history ledger. -->

| Date | Event |
|------|-------|
| «date» | Tracker created from «spec(s)». Queue seeded: «row summary». |
```
