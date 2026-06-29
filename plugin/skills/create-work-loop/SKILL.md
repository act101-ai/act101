---
name: create-work-loop
description: Generate a robust, idempotent work-loop tracker — the single resumable state file that drives a large implementation program through plan → implement → review cycles with self-tracking, found-issue capture, and remediation discipline. Use whenever the user wants to execute a large or multi-item implementation systematically; triggers include "create a work loop", "set up a tracker", "make this resumable", "execution harness", "work through this spec item by item", or any time one or more approved specs need to be implemented across many sessions or by many agents and progress must survive context loss. Also drives and resumes the **quality loop** — a.k.a. "continuous quality", "the quality ratchet", "the architecture ratchet" — which maps to the architecture-audit → architectural-refactoring → verify-refactor skill cycle; triggers include "run the quality loop", "set up a quality ratchet", "keep auditing and refactoring", "continuously improve architecture".
---

# Create Work Loop

A work loop is one markdown file that is the **entire resumable state** of an implementation program. Any session — tomorrow, after a crash, a different agent — continues the program with a single instruction: *"resume the work in `<tracker path>`"*. Nothing about progress lives in conversation memory, plans-in-flight, or anyone's head; if it isn't in the tracker (or in a plan file the tracker points to), it didn't happen.

The design rests on one separation of powers, and everything else follows from it:

- **Specs own acceptance.** What "done" means for every item lives in spec documents. The tracker never restates or overrides spec content — restating invites drift, and drift between two sources of truth is how programs rot.
- **The tracker owns ordering and state.** Which item is next, what state each is in, where its plan lives, which commits closed it.
- **Plan files own fine-grained progress.** Checkboxes inside each item's implementation plan are the resume state *within* an item; the tracker is the coarse state *across* items.

## Process

### 1. Gather inputs (from context first)

Most inputs are usually already in the conversation or repo. Derive what you can; ask only for what's genuinely missing, one question at a time.

| Input | Source | Notes |
|---|---|---|
| Authority spec(s) | The approved spec docs this program implements | Required. More than one is fine — the tracker lists the authority chain. |
| Tracker path | User preference or project convention | Default `docs/specs/<program>-work-loop.md`. Check for existing work-loop files to match local convention. |
| Queue items | Spec sections/items, in execution order | One row per independently closeable unit. If the spec has explicit IDs (E1, R3…), reuse them; otherwise mint a short prefix per phase. |
| Ordering & dependencies | Spec dependency notes, user decisions | Record them as a note under the queue, not as prose scattered through rows. |
| Verification floor | Project test/lint/build commands (CLAUDE.md, CI config, justfile) | Per surface if the program spans surfaces (e.g., cargo for crates, vitest for a worker, repo checks for an action). |
| Project hard rules | The project's CLAUDE.md | Inherit **verbatim** — never invent rules the project doesn't have, never drop ones it does. |
| Exclusions | Anything from a sibling work loop that does NOT apply here | Name exclusions explicitly (e.g., "scan-score tracking excluded — specific to the remediation loop"). Silent omission looks like an oversight; named exclusion is a decision. |
| Workspace rules | Branch/worktree/concurrency facts | E.g., "work stays on the current branch; a concurrent agent shares this checkout — wait out lock contention." Branch/merge/PR decisions belong to the user unless they have said otherwise. |

### 2. Generate the tracker

Read `references/tracker-template.md` and instantiate it with the gathered inputs. The template is the contract — every section in it exists because a failure mode demanded it (the template annotates which). Keep all sections; tailor their contents.

Seed the queue completely: every item from the authority specs gets a row at creation time, even far-future ones. A complete queue is what makes "find the first non-DONE row" a total resume algorithm — gaps force the resuming session to re-derive scope from the specs, which is exactly the context-dependence the tracker exists to eliminate.

### 3. Commit

Commit the tracker as its own change (or together with the state change it records — never apart from one). The tracker's credibility rests on one invariant: **it is never stale relative to committed work**. That invariant starts at the first commit.

## Idempotency (re-running this skill)

`/create-work-loop` against a program whose tracker already exists must be safe. Never clobber. Reconcile instead:

1. Read the existing tracker fully.
2. **Never regress state** — a row's state only moves forward here; only the resume protocol (executing real work) moves states.
3. **Add missing rows** for spec items that have no row (new spec amendments since creation), appended in spec order with a dated Log entry naming what was added and why.
4. **Never delete rows** — a row that no longer applies is `DROPPED(evidence)`, which preserves the audit trail.
5. Report drift you noticed but did not change (e.g., a row whose plan file is missing) rather than silently "fixing" it.

## What the generated protocol guarantees

These are the load-bearing behaviors the template encodes — understand them so you can adapt wording without breaking them:

- **Plan → implement → review per item.** `TODO` rows get a written plan (via the project's planning skill if present) before any code; `PLANNED` rows execute the plan with checkboxes ticked as they complete; before an item closes, its changes get a review pass, and review findings are either fixed in-item or captured as F-rows — never noted-and-ignored.
- **Premise re-verification.** Specs record a baseline that drifts. Resuming sessions verify the spec's premises against live code before acting, and record drift as a dated spec amendment. This is the defense against confidently implementing against a world that no longer exists.
- **Found-issue discipline.** Any defect discovered mid-item is in scope — nothing is "pre-existing", nothing is parked in a follow-ups list. Blocking issues are fixed inside the item; non-blocking ones get a dated spec amendment plus an `F-n` queue row carrying the same closing discipline as planned rows. This is what keeps a long program from accumulating a shadow backlog nobody owns.
- **Evidence-gated closing.** A row reaches `DONE` only when every acceptance criterion in its spec section passes **with shown output** — the verification floor actually run, not asserted. "It should pass" closes nothing.
- **Same-commit state updates.** The queue row changes in the same commit as the work it records. This is the idempotency anchor: any interruption leaves the tracker accurately describing the last committed state.
- **One item at a time.** An item fully closes before the next begins. Parallelism, when wanted, is a user decision recorded in the tracker's ordering notes — not an agent improvisation.

## Variant: the quality loop (the architecture ratchet)

When the request is a **quality loop** / **continuous quality** / **"run the quality loop"**, the program being driven is not a written spec — it is the **architecture ratchet**: a continuous `architecture-audit` → `architectural-refactoring` → `verify-refactor` cycle that lifts structural health one notch per pass and never lets it slide back. Everything in this skill still applies; only the *source of acceptance* and the *queue lifecycle* specialize. Reach for this variant when the user wants ongoing structural quality, not a fixed feature list.

**REQUIRED SUB-SKILLS** — the loop *invokes* these, it does not reimplement them:
- `architecture-audit` — produces `report.md` + `project-map.md`; owns the Refuted & Re-characterized ledger and the improving/stable/degrading trend verdict.
- `architectural-refactoring` — executes confirmed findings, commits each step, appends to `remediation-log.md`.
- `verify-refactor` — the per-change behavior-preservation gate (SAFE / REVIEW / UNSAFE / UNKNOWN).

### Same separation of powers, different sources

| Generic work loop | Quality-loop instance |
|---|---|
| Specs own acceptance | **The audit `report.md` + `project-map.md` own acceptance.** A finding is "done" only when a re-audit's fresh structural evidence confirms it resolved — never on an agent's assertion. The tracker points to finding IDs; it never restates the finding. |
| Tracker owns ordering & state | **Tracker owns the cycle number + current phase** (AUDIT → REMEDIATE → RE-AUDIT) and which findings are open this cycle. |
| Plan files own fine-grained progress | **`remediation-log.md` owns per-finding progress** — the append-only ledger keyed to finding IDs is the equivalent of a plan file's checkboxes. |

The durable cross-session state is therefore three artifacts in concert — `project-map.md` (current structural state), `remediation-log.md` (actions taken), and the work-loop tracker (which cycle/phase we're in). *"Resume the quality loop in `<tracker>`"* rehydrates entirely from these; nothing lives in conversation memory.

### The queue is regenerated, not seeded upfront

Unlike a spec-driven loop where every row exists at creation, the quality-loop queue is **produced by each audit pass**: one row per *confirmed actionable* finding in the latest `report.md`, in remediation priority order (cycles > god classes > high coupling > dead code). In the queue table, the generic `Spec §` column becomes **`Finding ID + report ref`**. Refuted / re-characterized entries never become rows — that is the ratchet's lower pawl: a smell investigated and disproven is recorded in the map's Refuted ledger and never re-flagged.

### Running it ("run the quality loop")

If no quality-loop tracker exists yet, generate one (the normal job of this skill, specialized per the table above) before driving the cycle. Then:

1. **AUDIT.** Invoke `architecture-audit`. Record the cycle number; seed the queue with its confirmed findings by ID. If the audit surfaces *no* confirmed actionable findings (only refuted / re-characterized remain) and the trend is stable, the ratchet is at its current floor — stop and report. Do not invent work or re-open refuted smells.
2. **REMEDIATE.** For each finding row, in priority order: invoke `architectural-refactoring` for that finding (it plans along seams, executes, re-runs the specific analysis, commits, appends a `remediation-log.md` row), then run `verify-refactor` on the touched function(s). Close the row to `DONE` only on a **SAFE** verdict *and* the finding's own analysis confirming it resolved. `UNSAFE` / `UNKNOWN` blocks the row — never upgrade it to closed.
3. **RE-AUDIT.** After the batch, invoke `architecture-audit` again. It folds the remediation log into the map, re-verifies each claimed fix against fresh structure, and surfaces the next layer. A claimed-RESOLVED finding the structure contradicts is a **regression** — it re-enters the queue as a new finding. Increment the cycle; return to step 2 with the new findings.
4. Repeat until an AUDIT pass hits the step-1 stop condition.

### Found-issue discipline (the generic rule still binds — and bites harder here)

Every issue an agent surfaces *during* the loop is in scope, exactly as in the generic loop: nothing is deferred as "pre-existing" or parked in a follow-ups list. **Do not assume the next audit will catch it** — the audit is structural-only, so anything outside the dependency graph is invisible to it and the tracker is its only durable home. Concretely, during REMEDIATE:

- **Blocking** (the issue prevents closing the current finding correctly) → fix it inside that finding's remediation before its row reaches `DONE`.
- **Non-blocking structural** finding the audit *will* independently re-confirm (a new cycle, a fresh god object) → append an `F-n` row now so it is tracked, even though the next RE-AUDIT will also surface it.
- **Non-blocking non-structural** finding the audit will **not** resurface — a logic bug spotted while reading code, a `verify-refactor` `dropped_cleanup`, a missing test, or any `REVIEW` / `UNSAFE` / `UNKNOWN` verdict — **must** get an `F-n` row, because no future audit will recover it. A non-SAFE `verify-refactor` verdict is a found issue, never a warning to wave past.

`F-n` rows live in the tracker's Findings table and carry the same closing discipline as audit-derived rows.

### Ratchet invariants (what must never regress)

- **The Refuted ledger is carried forward, never dropped** — disproven smells stay disproven across cycles.
- **`remediation-log.md` is append-only** — one row per verified step, keyed to a finding ID; never rewritten or reordered.
- **Trend is monotonic by construction** — the audit's improving/stable/degrading verdict is the ratchet read-out; a degrade is not silently tolerated, it becomes a finding and the loop pulls it back.
- **Same-commit state updates still hold** — the tracker's cycle/phase row changes in the same commit as the work (or the log row) it records.

### Named exclusions for the generated tracker

A quality-loop tracker has **no authority-spec chain**, **no per-item spec premise re-verification** (the audit *is* the premise check), and **no static far-future queue** (each audit regenerates it). Name these exclusions in the generated file — silent omission of the spec sections looks like an oversight; a named exclusion is a decision.
