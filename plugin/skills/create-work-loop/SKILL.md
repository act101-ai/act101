---
name: create-work-loop
description: Use to create, run, resume, or continue a work loop, in any phrasing ("create a work loop for this spec", "set up a tracker", "make this resumable", "work through this spec item by item", "run the work loop", "resume the tracker", "continue the remediation loop") and the quality loop ("run the quality loop", "continuous quality", "quality ratchet", "architecture ratchet", "keep auditing and refactoring"). Given a tracker, it resumes that tracker; otherwise it creates the requested one and starts it.
---

# Create Work Loop

> ## ⛔ STOP — DO NOT INVENT RULES
>
> Do not add rules, gates, checks, hooks, thresholds, budgets, ledgers, or authorization schemes to a tracker without explicit operator authorization.
>
> - A rule the operator did not ask for is not a rule. It is a defect.
> - Every rule in a tracker cites who authorized it and when. No citation, delete it. Do not debate it.
> - A rule is blocking work and nobody can point to the operator asking for it? Delete the rule. Never write a second rule to work around the first.
> - This covers anything that can refuse, block, gate, count, budget, ration, or slow work down.
> - Sounding like good engineering practice is not authorization. Good intentions wrote every invented rule that has already broken a loop.
>
> Ask the operator. Wait for the answer. Then write the rule, with the citation.

A work loop is one markdown file that is the **entire resumable state** of an
implementation program. Any session, tomorrow, after a crash, or a different agent,
continues the program with one instruction: *"resume the work in `<tracker path>`"*.
Progress lives in the tracker or in a plan file the tracker points to, never in
conversation memory.

The design rests on one separation of powers:

- **Specs own acceptance.** What "done" means for every item lives in the spec
  documents. The tracker points at spec sections and never restates them; two
  sources of truth drift.
- **The tracker owns ordering and state.** Which item is next, what state each is
  in, where its plan lives, which commits closed it.
- **Plan files own fine-grained progress.** Checkboxes inside an item's plan are the
  resume state within the item; the tracker is the coarse state across items.

## Entry: resume or create

Every invocation, whatever the verb, starts by locating the tracker:

1. An explicit path in the request wins. Otherwise a named program ("the
   remediation loop") maps to `<program>-work-loop.md`, and with neither, look for
   `*-work-loop.md` at the repo root and under `docs/specs/`; one match is the
   tracker, several means ask which.
2. **The tracker exists: resume it.** Read its snapshot and its own resume protocol,
   then execute that protocol from its first step (display the file-group status,
   integrity check, hygiene, sync gate, first open row). The tracker's protocol is
   authoritative over this skill wherever they differ; it was written for that
   program. Never re-create, re-seed,
   or reformat an existing tracker on a resume; reconcile only when the request is
   to update it (see Idempotency).
3. **No tracker: create it** with the process below, commit it, and then resume it
   immediately unless the request was only to set it up.

## Process (create)

### 1. Gather inputs

Most inputs are already in the conversation or the repo. Derive what you can and
ask only for what is missing, one question at a time.

| Input | Source | Notes |
|---|---|---|
| Authority spec(s) | The approved spec docs this program implements | Required. Several are fine; the tracker lists the authority chain. |
| Tracker path | User preference or project convention | Default `<program>-work-loop.md` at the repo root, a persistent ledger per the protocol's File-Location Convention (`../analysis-protocol/references/protocol.md`). Match any existing work-loop files. It is the ACTIVE file of the loop's file group; the backlog `<program>-work-loop-backlog.md` and the history `<program>-work-loop-history.md` sit beside it (see the file group below). |
| Queue items | Spec sections or items, in execution order | One row per independently closeable unit. Reuse the spec's IDs (E1, R3, …) when it has them; otherwise mint a short prefix per phase. |
| Ordering and dependencies | Spec dependency notes, user decisions | Record as a note under the queue, not as prose scattered through rows. |
| Verification floor | Project test, lint, and build commands (CLAUDE.md, CI config, justfile) | Per surface when the program spans surfaces (cargo for crates, vitest for a worker, repo checks for an action). Record each gate's measured wall time beside it. |
| Hygiene check | The project's machine-hygiene command, if it has one (this repo: `scripts/loop_hygiene.sh check`) | Runs before every gate and at every close. Leaked temp files, orphaned tool processes, and stale build artifacts are the loop's own exhaust; they must be pruned by tooling, not noticed by the operator. |
| Project hard rules | The project's CLAUDE.md | Inherit verbatim: no rules the project lacks, none of its rules dropped. |
| Exclusions | Anything from a sibling work loop that does not apply here | Name them ("scan-score tracking excluded: specific to the remediation loop"). A named exclusion is a decision; a silent omission looks like an oversight. |
| Workspace rules | Branch, worktree, concurrency, and push-cadence facts | E.g. "a concurrent agent shares this checkout; wait out lock contention." Push cadence is an operator decision: a branch that is never pushed meets CI only at reconciliation, and local hooks are not CI. |

**Branch and PR rules** (defaults; an operator instruction always wins):

1. An explicit operator instruction about branches, merges, or PRs overrides
   everything below.
2. Absent instructions: on the default branch, create a work branch before the
   first commit; on a non-default branch, keep working in it.
3. At completion, open a PR for operator review. Merge only on explicit operator
   request.

Throughout: operator instruction > project convention > skill default.

### 2. Generate the tracker

Read `references/tracker-template.md` and instantiate it with the gathered inputs.
The template is the contract: every section exists because a failure mode demanded
it (the template says which). Keep every section; tailor the contents.

Seed the queue completely: every item from the authority specs gets a row at
creation, including far-future ones. A complete queue makes "find the first
non-DONE row" a total resume algorithm; a gap forces the resuming session to
re-derive scope from the specs. Write every row into the tracker, then run the
archive step once: it moves the rows beyond the open-row cap to the backlog, in
reverse priority order, and writes the status block.

### 3. Commit

Commit the tracker (with its backlog and history, when they exist) as its own
change, or together with the state change it records, never apart from one. The
tracker's credibility rests on one invariant: it is never stale relative to
committed work. That starts at the first commit.

## Idempotency

Running the create path against a program whose tracker already exists must be
safe. Reconcile instead of clobbering:

1. Read the existing tracker fully.
2. A row's state only moves forward here; only the resume protocol (doing real
   work) moves states.
3. Add rows for spec items that have none (amendments since creation), appended in
   spec order with a dated Log entry saying what was added and why.
4. A row that no longer applies becomes `DROPPED(evidence)`; rows are never
   deleted, only moved: between the active tracker and its backlog, and from
   either to the history (see the file group below). A move never renumbers or
   edits a row.
5. The archive step is idempotent: a second run moves nothing and changes no
   byte, and `--dry-run` reports the moves and writes nothing. A tracker in a
   shape older than the file group is migrated by that step's first run, never
   by hand.
6. Report drift you noticed but did not change (a row whose plan file is missing)
   rather than silently fixing it.

## What the generated protocol guarantees

The load-bearing behaviors the template encodes. Understand them so wording can be
adapted without breaking them:

- **Plan → implement → review per item.** A `TODO` row gets a written plan (via the
  project's planning skill if present, else per "Planning an item") before any
  code; a `PLANNED` row executes the plan (via the project's execution skills if
  present, else per "Executing an item") with checkboxes ticked as steps complete;
  before an item closes, its changes get a review pass, and every review finding is
  fixed in-item or captured as an F-row.
- **Premise re-verification.** Specs record a baseline that drifts. A resuming
  session verifies the spec's premises against live code before acting and records
  drift as a dated spec amendment.
- **Found-issue discipline.** Any defect discovered mid-item is in scope: nothing
  is "pre-existing", nothing is parked in a follow-ups list. A blocking issue is
  fixed inside the item; a non-blocking one gets a dated spec amendment plus an
  `F-n` queue row with the same closing discipline as planned rows.
- **Evidence-gated closing.** A row reaches `DONE` only when every acceptance
  criterion in its spec section passes with shown output from the verification
  floor. "It should pass" closes nothing.
- **Same-commit state updates.** The queue row changes in the same commit as the
  work it records, so any interruption leaves the tracker describing the last
  committed state.
- **One item at a time.** An item fully closes before the next begins. Parallelism
  is a user decision recorded in the tracker's ordering notes.
- **A file group: an active tracker with hard caps, a backlog, and a history
  (operator direction 2026-09-21; the closed-row cap and rolling archive,
  operator order 2026-09-16).** Each loop is three files. The **active** tracker
  (`<program>-work-loop.md`) is the only file a resume reads in full: the snapshot,
  the resume protocol, the priority order, the Log, and at most **25 open rows**,
  **25 closed rows** (`DONE` / `DROPPED`), and **14 days** of Log. The **backlog**
  (`<program>-work-loop-backlog.md`) holds only open rows that wait for a slot. The
  **history** (`<program>-work-loop-history.md`) holds closed rows and old Log
  entries, verbatim and append-only. At every close and every sync a mechanical
  archive step, never a hand edit: moves closed rows beyond the cap from the active
  tracker to the history, then makes the active tracker's open rows the next 25
  rows of the whole group's work order: the operator's queue-head override (the
  snapshot's **Next row** line) first, then the priority order. Lower-ranked
  waiting rows move to the backlog and higher-ranked ones move in; a started row
  never leaves the active tracker and counts against the 25. The
  step regenerates a machine-maintained **status** in the snapshot: open and closed
  rows in the active tracker, rows in the backlog, archived rows in the history
  (DONE and DROPPED separately), and the id union. **Displaying that status is the
  first step of every resume.** The integrity check **refuses** an active tracker
  over any cap, so the caps are met by tooling and a skipped archive step shows up
  as a red check. Rows move verbatim and IDs are never reused or renumbered;
  cross-references still resolve into whichever file holds the row, and the
  integrity check proves every ID unique and the union contiguous across all three
  files. A re-opened finding gets a new row citing the archived one; archived rows
  are never edited. New non-blocking findings are appended to the backlog; the next
  archive step pulls them in when a slot opens, in priority order. Log rows are one
  line pointing at commits and the row; detail lives in the row, the plan, or the
  commit.
- **Machine hygiene is part of the floor.** The hygiene check runs before every
  gate and at every close; on failure the loop prunes and re-checks. A gate that
  stalls is diagnosed and killed, never waited out.
- **Gates and rules are inputs, never outputs.** The loop never adds a hook stage, a
  coverage pass, a CI job, a rule, or a scheme that rations anything, and never
  lengthens a gate; the cost of every gate and the existence of every rule is the
  operator's decision, cited in the tracker. A rule with no citation is deleted on
  sight — see the notice at the top of this skill. Two real failures came from
  ignoring this: a self-added commit gate that replayed 462 corpus examples on every
  commit and hung for an hour, and a self-invented "one authorization per run" scheme
  that withheld eleven verified test maps from ever running.
- **Operator-owned branch and PR flow**, as in the rules above.

## Planning an item (`TODO` → `PLANNED`)

If the project has its own planning skill, use it. Otherwise the plan must stand
alone for an implementer with zero project context:

- **One plan file per queue item** at the tracker's plans path (default
  `.act/plans/YYYY-MM-DD-<id>-<slug>.md`, committed: plans are resume state).
- **Header:** the goal in one sentence, the spec section it implements, and the
  global constraints binding every task (verification floor, project hard rules),
  copied exactly.
- **Bite-sized tasks:** each task is the smallest unit with its own verify cycle:
  write the failing check, show it fail, implement, show it pass, commit. Every
  step names exact file paths and complete content or commands, with the expected
  verification output. "Add appropriate handling", "similar to task N", and TBD
  placeholders are plan failures.
- **Interfaces between tasks:** when a later task consumes what an earlier one
  produces, both state the exact names and signatures; an implementer sees only
  their own task.
- **Self-review before committing:** every requirement in the spec section maps to
  a task; no placeholder survives; names used later match their definitions.

## Executing an item (`PLANNED` → `DONE`)

If the project has its own execution skills, use them. Otherwise:

- **Follow the plan exactly**, ticking checkboxes in the plan file as steps
  complete.
- **Run every verification as written and read its output.** A step is done when
  its check passed, not when its code is written.
- **Stop when blocked.** An unclear instruction, a missing dependency, a repeatedly
  failing verification, or a plan that contradicts live code sets `BLOCKED(reason)`
  on the row, records what is needed, and surfaces it. Pushing through a broken
  premise creates work that must be undone.
- **Subagent execution** (when the session runs subagents): one fresh subagent per
  task, dispatched sequentially, never in parallel on one checkout. Each dispatch
  carries the task's full text, the interfaces it touches, the global constraints,
  and an output contract (status, commits, verification output). Review each task's
  diff against its task text before dispatching the next; run one whole-item
  review before closing the row.
- **Review before closing**: findings are fixed in-item or captured as F-rows.
- **Archive before closing**: run the archive step (archive, then refill), then
  commit the close and the moves together.

## Variant: the quality loop (the architecture ratchet)

When the request is a quality loop or continuous quality, the program is not a
written spec but the **architecture ratchet**: a continuous `architecture-audit` →
`architectural-refactoring` → `verify-refactor` cycle that lifts structural health
one notch per pass and never lets it slide back. Everything above still applies;
only the source of acceptance and the queue lifecycle change.

**Required sub-skills**, invoked, not reimplemented:

- `architecture-audit` produces `report.md` and `project-map.md`, and owns the
  Refuted ledger and the improving / stable / degrading trend verdict.
- `architectural-refactoring` executes confirmed findings, commits each step, and
  appends to `remediation-log.md`.
- `verify-refactor` is the per-change behavior-preservation gate (SAFE / REVIEW /
  UNSAFE / UNKNOWN).

### Same separation of powers, different sources

| Generic work loop | Quality-loop instance |
|---|---|
| Specs own acceptance | The audit `report.md` and `project-map.md` own acceptance. A finding is done only when a re-audit's fresh structural evidence confirms it resolved, never on an agent's assertion. The tracker points to finding IDs and never restates the finding. |
| Tracker owns ordering and state | The tracker owns the cycle number, the current phase (AUDIT → REMEDIATE → RE-AUDIT), and which findings are open this cycle. |
| Plan files own fine-grained progress | `remediation-log.md` owns per-finding progress; its append-only rows keyed to finding IDs are the equivalent of a plan file's checkboxes. |

The durable state is three artifacts: `project-map.md` (current structure),
`remediation-log.md` (actions taken), and the tracker (which cycle and phase).
*"Resume the quality loop in `<tracker>`"* rehydrates entirely from these.

### The queue is regenerated, not seeded upfront

Each audit pass produces the queue: one row per confirmed actionable finding in the latest `report.md`, in remediation priority order (cycles > god classes > high coupling > dead code). The generic `Spec §` column becomes **`Finding ID + report ref`**. Refuted and re-characterized entries never become rows; a smell investigated and disproven is recorded in the map's Refuted ledger and stays there.

### Running it

If no quality-loop tracker exists, generate one (specialized per the table above)
before driving the cycle. Then:

1. **AUDIT.** Invoke `architecture-audit`. Record the cycle number and seed the
   queue with its confirmed findings by ID. If the audit surfaces no confirmed
   actionable findings and the trend is stable, the ratchet is at its floor: stop
   and report.
2. **REMEDIATE.** For each finding row, in priority order: invoke
   `architectural-refactoring` for that finding (it plans along seams, executes,
   re-runs the specific analysis, commits, and appends a `remediation-log.md`
   row), then run `verify-refactor` on the touched functions. Close the row to
   `DONE` only on a SAFE verdict and the finding's own analysis confirming it
   resolved. UNSAFE or UNKNOWN blocks the row.
3. **RE-AUDIT.** Invoke `architecture-audit` again. It folds the log into the map,
   re-verifies each claimed fix against fresh structure, and surfaces the next
   layer. A claimed-RESOLVED finding the structure contradicts is a regression and
   re-enters the queue as a new finding. Increment the cycle and return to step 2.
4. Repeat until an AUDIT pass hits the step-1 stop condition.

### Found-issue discipline in the loop

Every issue surfaced during the loop is in scope, exactly as in the generic loop.
The audit is structural-only, so anything outside the dependency graph is
invisible to it and the tracker is its only durable home. During REMEDIATE:

- **Blocking** (prevents closing the current finding correctly): fix it inside that
  finding's remediation before its row reaches `DONE`.
- **Non-blocking structural** (a new cycle, a fresh god object the audit will
  re-confirm): append an `F-n` row now so it is tracked.
- **Non-blocking non-structural** (a logic bug spotted while reading, a
  `verify-refactor` `dropped_cleanup`, a missing test, any REVIEW / UNSAFE /
  UNKNOWN verdict): an `F-n` row is mandatory, because no future audit will
  recover it. A non-SAFE `verify-refactor` verdict is a found issue.

`F-n` rows live in the tracker's Findings table with the same closing discipline as
audit-derived rows.

### Ratchet invariants

- The Refuted ledger is carried forward, never dropped.
- `remediation-log.md` is append-only: one row per verified step, keyed to a
  finding ID, never rewritten or reordered.
- The trend is monotonic by construction: a degrade becomes a finding and the loop
  pulls it back.
- Same-commit state updates still hold for the tracker's cycle and phase row.
- The file group (caps, archive, refill, status) applies to the quality-loop
  tracker too; the history keeps every closed cycle's rows.

### Named exclusions for the generated tracker

A quality-loop tracker has no authority-spec chain, no per-item spec premise
re-verification (the audit is the premise check), and no static far-future queue
(each audit regenerates it). Name these exclusions in the generated file.
