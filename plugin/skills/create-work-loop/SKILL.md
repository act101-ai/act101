---
name: create-work-loop
description: Plans and runs work as a resumable work graph of nodes with contracts, dependencies and fixed acceptance checks, run test-first through verification stages. Use when the operator asks to write a plan, plan a change, break work down or turn a spec into tasks before writing code ("write a plan", "plan this", "implementation plan", "break this down"); to create, run, resume or continue a work loop, work graph or tracker ("create a work loop for this spec", "set up a tracker", "make this resumable", "run the graph", "resume the work loop", "continue the remediation loop", "execute the plan"); or for the quality loop ("run the quality loop", "continuous quality", "quality ratchet", "architecture ratchet", "keep auditing and refactoring").
---

# Create Work Loop

> ## Rules need the operator's approval
>
> Add no rule the operator has not approved. A rule is anything that can refuse, block, gate, count, budget, ration or slow down work: a gate, check, hook, threshold, budget, ledger or authorization scheme, wherever it is written.
>
> - A citation is who approved the rule and when, or the project file or spec it comes from. A file citation counts only from the project's instruction files (CLAUDE.md, AGENTS.md, CONTRIBUTING, the documents they name, CI configuration) and from a spec or spec section the operator approved; a file or amendment an agent wrote is never a citation on its own authority.
> - To propose a rule, give the operator the rule, the failure it prevents with its evidence, what it costs (time, blocked work, maintenance) and what it gains. Write it only after the operator approves it, with its citation.
> - Every rule in a graph carries its citation. A rule without one is deleted, not debated. Do not write a second rule to work around it.
> - This skill's own rules are its defaults (§2) and carry no citation.

A work loop is a **work graph**. Nodes are units of work. Edges are
dependencies. Every node whose dependencies are all done can run, in
parallel. Each node runs as a bounded loop: a fixed acceptance check, an
attempt, then keep or discard. The graph's files are its whole state, so any
session continues it with one instruction: *"resume the work in
`<graph path>`"*.

The separation of powers:

- **Specs own acceptance.** What "done" means lives in the spec. The graph
  points to spec sections and never restates them.
- **`graph.md` owns order and state.** Which nodes exist, how they depend on
  each other, what state each is in, which commits closed it.
- **`nodes/<id>.md` owns the node.** Its contract, its plan, and the
  checkboxes that are the resume state inside the node.

## 1. Entry

| Request | Action |
|---|---|
| Write a plan, plan this, break this down, turn this spec into tasks | Create the graph (§4). Then stop and ask the operator to review it. |
| Create a work loop, set up a graph or a tracker | Create the graph. Then run it (§7), unless the request was only to set it up. |
| Run, resume, continue or execute a plan, loop or graph | Resume (§7.1). |
| Run the quality loop | §10. |

To find the graph: an explicit path wins. Else a named program maps to
`docs/work/<program>/graph.md`. Else look for `graph.md` under `docs/work/`
and for `*-work-loop.md` anywhere in the repo. One match is the graph.
Several matches: ask the operator which one.

A tracker in the older format (`*-work-loop.md`) is resumed by its own resume
protocol, unchanged. Do not convert it.

A small change gets a small graph. One node is a valid graph.

## 2. Adapt to the operator's workflow

This skill's procedures are defaults. Where the operator has chosen a
workflow for part of the work, use it.

1. **Find out what exists.** At creation, read the project's instructions
   (CLAUDE.md, AGENTS.md, CONTRIBUTING and the documents they name). Look
   for: a ticket or issue lifecycle, a planning or review workflow, branch
   and PR conventions, and a ledger the operator uses.
2. **Do not presume.** A workflow applies only when it is written down or the
   operator states it. Infer nothing from a name or a habit.
3. **Record it.** Add a `**Workflows:**` line to the graph header, one entry
   per adopted workflow: what it governs, then its citation. Map a ticket
   lifecycle in `ledger.md` (§3.6): for each state change, what the
   lifecycle requires.
4. **Precedence.** An operator instruction, then a workflow the project
   declares, then this skill's defaults. If an adopted workflow conflicts
   with a rule in this skill, ask the operator which applies and record the
   answer with its citation.

## 3. The graph

### 3.1 Files

A graph lives in `docs/work/<program>/` unless the project has a convention.

| File | Holds |
|---|---|
| `graph.md` | The header, the node table, and the Log. The only file a resume reads in full. |
| `nodes/<id>.md` | One node's contract and plan. |
| `history.md` | Closed rows and old Log entries, moved verbatim. Append-only. |
| `backlog.md` | Open rows that wait for a slot in `graph.md` (`references/full-machinery.md`). |
| `findings-inbox/`, `findings/<id>.md` | Findings intake and evidence, when the graph declares findings (`references/full-machinery.md`). |

Templates: `references/graph-template.md` and `references/node-template.md`.

### 3.2 The header

The header fixes the boundaries before any work starts.

- **Goal:** one sentence.
- **Authority:** the spec files.
- **Run:** `key=value` settings separated by ` · `: `parallel=<n>` or
  `parallel=off`, `worktrees=<git-ignored dir>`, and `disk-per-node=<n>G` or
  `—`. Defaults are `parallel=3` and `disk-per-node=—`; any other value of
  either is followed by its citation in parentheses; `worktrees` needs none.
  `parallel` is a whole number or `off`.
- **Next:** optional. Node ids the operator wants worked first.
- **Findings:** optional. The findings machinery and its id blocks, with its
  citation. Read `references/full-machinery.md` before you declare it.
- **Ledger:** optional (§3.6), with its citation.
- **Workflows:** optional (§2): what each workflow governs, and its citation.
- **Hygiene:** optional. The project's machine-hygiene procedure, and its
  citation. When set, it runs before every verification and at every node
  close. On failure, fix what it reports and run it again.
- **Global constraints:** project-wide requirements every node inherits, with
  exact values from the spec, and the project's hard rules copied verbatim.
  Each cites its spec section, instruction file, or who approved it and when.
- **Verification floor:** the project's exact checks per surface, each with
  its citation.
- **Review focus:** test obligations derived from the spec, not rules: input
  classes and failure modes no node's tests exercise, most likely first. Each
  line names the node that owns the test and its spec section.

### 3.3 The node table

```
| ID | Node | Depends | State | Model | Refs |
|----|------|---------|-------|-------|------|
| N1 | Parse config file | — | DONE | sonnet | a1b2c3d; acceptance 12/12 |
| N2 | Validate config | N1 | IN-PROGRESS | sonnet | wt .worktrees/cfg/N2 |
| N3 | Config defaults | N1 | TODO | haiku | — |
```

- States: `TODO` → `PLANNED` → `IN-PROGRESS` → `DONE`, or `BLOCKED(reason)`,
  or `DROPPED(evidence)`.
- A row is at most 600 characters; a Log entry at most 300. Detail goes in
  the node file or the commit message.
- `Depends` and `Model` live only here, never in the node file.

### 3.4 The node contract

Every node gets a contract at creation, in `nodes/<id>.md`:

```markdown
# N2 — Validate config

**Spec:** design.md §3.2
**Files:** `src/config/validate.rs`, `tests/config_validate.rs`
**Consumes:** `parse_config` (N1)
**Produces:** `validate(cfg: &Config) -> Result<(), ConfigError>`
**Acceptance:** the `config_validate` tests → all pass

## Plan
```

- **Files:** the files the node creates or changes. Two nodes that share a
  file must have a dependency path between them.
- **Consumes:** each name the node uses from another node, with that node's
  id. That node must be one this node depends on, directly or through
  others, and it must list the name under Produces.
- **Produces:** each name later nodes may use, with its exact signature.
- **Acceptance:** a check, in backticks, then `→` and the result that means
  pass. It is fixed at creation and does not change between attempts. It is
  part of the contract, not a rule under the notice: it takes its authority
  from the spec and this skill's defaults (§3.4, and §7.4 for a defect
  node). A §7.4 amendment records the defect and approves no rule.
- A name is the identifier before `(`, with its path: `config::load`,
  `Config.load`. A keyword in front of it (`fn`, `def`) is ignored; without
  `(`, the name is the leading identifier (`MAX: usize` declares `MAX`). A
  consumed name matches a produced name exactly, or names its last segment
  (`load` matches `config::load`).
- Write `—` for a field that has nothing to list. Acceptance is never `—`.

### 3.5 The ready set

A node is ready when its state is `TODO` or `PLANNED` and every dependency
is `DONE`. The schedule is: `IN-PROGRESS` nodes first, then ready nodes in
table order, up to `parallel`, skipping a node whose Files overlap a node
already scheduled. Scheduled nodes run at the same time, each in its own
isolated checkout, unless the operator restricts this.

### 3.6 Another ledger

When the operator asks for an issue tracker or any other ledger, use it in
place of the node table, and cite the request in the **Ledger:** line.
`graph.md` keeps the header and the Log, and its `## Nodes` section points
to the ledger. Contracts and plans stay in `nodes/<id>.md`. `ledger.md` maps
each operation to how the ledger does it. Prove every operation once on a
scratch node before the graph is committed. A mapping that has not been
proven is not used. With another ledger, archiving moves only old Log
entries; the ledger keeps the node history. The contract:
`references/ledgers.md`.

### 3.7 A valid graph

A graph is valid when it has no cycle, no edge to an unknown node, no
missing contract field, no Consumes that does not resolve to a Produces of a
node it depends on, no Files overlap between nodes with no path between
them, a `parallel` setting that is a whole number or `off`, and no more
closed rows or Log than §9 allows. Confirm validity at creation and at every
resume, before any work.

## 4. Create a graph

1. **Gather inputs.** The authority specs, the verification floor, the
   project's hard rules, the run settings, and what §2 finds. An approved
   design document is an authority spec. When the request's intent, scope or
   constraints are not settled, get an approved design before you cut nodes,
   in §2 precedence: the operator's instruction; else the project's design
   workflow; else agree intent, scope and constraints with the operator and
   write them to a spec. Take what the repo and the conversation give. Ask
   for the rest, one question at a time.
2. **Map the files.** List the files the work creates or changes and what
   each is responsible for. Decide the decomposition here: one clear
   responsibility per file; files that change together live together; follow
   the codebase's existing patterns.
3. **Cut the nodes.** A node is the smallest unit that has its own
   acceptance check and that a reviewer could reject while approving its
   neighbour. Fold setup, configuration and documentation into the node
   whose deliverable needs them. Every spec item gets a node now, including
   later ones, so "first ready node" always answers what to do next.
4. **Draw the edges.** A node depends on another only when it consumes what
   that node produces or changes a file that node creates. An edge that is
   not a real dependency removes parallelism.
5. **Choose each node's model** (§7.3).
6. **Write the contracts** (§3.4) and the header (§3.2).
7. **Self-review** the graph with the five checks of §5.3, applied to the
   whole graph: every spec requirement maps to a node.
8. **Verification stage** (§6) on the header, the nodes and the edges.
9. **Validate** the graph (§3.7).
10. **Commit** the graph files together, on a work branch (§7.7). If the
    checkouts directory is not ignored by version control, ignore it in the
    same commit, so a merge never stages a checkout.

If the request was to write a plan, stop here: give the operator the path and
ask them to review it.

## 5. Plan a node (`TODO` → `PLANNED`)

### 5.1 Check the premise

Read the node's spec section. Verify its premises against the live code: the
node's dependencies have landed since the graph was created, and the plan is
written against what they actually produced. Never trust earlier summaries,
plans or commit messages. If a premise has drifted, add a dated amendment to
the spec, then plan; or set `DROPPED(<evidence>)` if the premise is gone.

### 5.2 Write the plan

Append the plan under `## Plan` in the node file. Write for an implementer
who has not seen the codebase or the spec and who writes idiomatic code once
the interface and the test are exact.

- **Steps.** Each step is one action with a checkable result: write the
  failing test; run it and see it fail; implement; run it and see it pass;
  commit. Each step is a checkbox (`- [ ]`).
- **A test step** gives the test name and its assertions as code, with the
  spec's exact values.
- **A code step** gives the exact signature, the file, and the values the
  spec fixes. It gives a body only for an algorithm that the signature and
  the tests do not decide.
- **A verification step** gives the check and the result that means pass.
- **Interfaces.** Copy the contract's Consumes and Produces into the plan
  with the exact signatures as they exist in the code now.
- **No placeholders.** "TBD", "handle edge cases", "add validation", "same as
  N3", and any name that no node defines are defects.

### 5.3 Self-review

Run these checks once, and fix what they find in place:

1. **Spec coverage.** Every requirement in the spec section maps to a step.
2. **Step scan.** Every step lets the implementer write exactly one
   reasonable thing, and no step carries a body that the signature and the
   tests already decide.
3. **Interface match.** Names and signatures match the contracts of the
   nodes this node consumes from and the nodes that consume from it.
4. **Review focus.** Every review-focus line assigned to this node has its
   test.
5. **Proportion.** A plan longer than the code it describes has written the
   code. Replace bodies with signatures and assertions.

Then run the verification stage (§6) on the plan. The controller then sets
the node `PLANNED` (§7.2 step 1).

## 6. Verification stages

There are four verification stages: the graph at creation (§4 step 8), a
node's plan (§5.3), a node before it merges (§7.2 step 5), and the graph at
completion (§7.6). Each stage has three steps:

1. **Adversarial review.** The operator's or the project's declared reviewer
   if there is one; otherwise a fresh reviewer that has not seen this
   session: `opus` for the two graph stages and for a node whose Model is
   `opus`, else `sonnet`. Tell it to find defects, not to approve. Give it
   the artifact, the spec section it answers, the contracts it touches, and
   the review focus. It reports each finding with its location, the failure
   it causes, and the evidence.
2. **Verify each finding.** Read the code or text it cites and reproduce it;
   for code, write a failing test. Mark it confirmed or refuted, with the
   evidence. Record a refuted finding with its reason and drop it.
3. **Remediate.** Fix every confirmed finding in this stage, test first for
   code. A confirmed finding outside the stage's scope becomes a new node
   (§7.4). The stage passes when no confirmed finding is open.

## 7. Run the graph

### 7.1 Resume

1. Find the graph (§1).
2. Read its state (counts per state, the ready set, the schedule, the stuck
   nodes), validate it (§3.7), and run the **Hygiene** procedure if the
   header sets one. All must pass before any work.
3. Remove the checkouts whose node is `DONE` or `DROPPED` (§7.5 step 4).
4. Start each scheduled node (§7.2). `IN-PROGRESS` nodes continue at the
   first unchecked step of their plan.
5. Decide each stuck node: re-plan a `BLOCKED` node (§7.2 step 6); re-edge
   or drop a node that depends on a `DROPPED` node. Write the contracts
   (§3.4) and set the Model of backlog rows awaiting one, so they can move
   into `graph.md` (`references/full-machinery.md`). Without these decisions
   the graph never completes.

### 7.2 One node

The controller (the main session) is the only writer of `graph.md`. Nodes
never edit it.

1. **Plan.** If the node is `TODO`, plan it (§5) in the main checkout. Commit
   the plan and the state change to `PLANNED` together, on the work branch.
2. **Start.** Before creating a checkout, check free disk against
   `disk-per-node` when the header sets it. Create the node's isolated
   checkout under the header's checkouts directory, on a branch named
   `<work-branch>--<id>`. Set the node `IN-PROGRESS` with the checkout in
   Refs, and commit that on the work branch. From here until it merges,
   `nodes/<id>.md` is edited only in the node's checkout.
3. **Attempt.** The implementer works the plan in the checkout, test first,
   ticking each checkbox and committing as the steps say.
4. **Measure.** Run the node's Acceptance check and the verification floor
   in the checkout. Read the output.
5. **Verification stage** (§6) on the node's diff, against its contract and
   plan.
6. **Keep or discard.**
   - Acceptance passes and the stage passes: keep (§7.5).
   - Otherwise: start a new round on the same branch, driven by the failure
     output and the confirmed findings. From the second round, set the
     node's Model to `opus`.
   - After three failed rounds: discard the node's branch and checkout, set
     `BLOCKED(<diagnosis>)`, and re-plan the node (split it, change its scope
     or its approach) before any further attempt. When the new plan is
     committed, set the node `PLANNED`; the round count starts again.

### 7.3 Implementers, reviewers and models

When the session can delegate, each running node gets one fresh implementer
in its checkout, and its verification stage gets one fresh reviewer. Each
handoff carries the node file, the graph header, the contracts the node
touches, and an output contract: status, commits, the Acceptance output, and
any finding. Otherwise the controller runs the nodes itself, one at a time.

The model is chosen at creation by the work's complexity, nuance and
technicality:

| Model | Work |
|---|---|
| `haiku` | Mechanical work the plan fully decides: copying, renaming, fixtures, docs that restate code, running a check. |
| `sonnet` | Ordinary implementation from a complete plan; node reviews. |
| `opus` | Design choices the plan leaves open; core or shared code; concurrency, security or data-loss risk; interfaces between nodes; a node in its second or later round; planning a node whose spec is ambiguous; the graph-level verification stages. |

### 7.4 Found issues

Every defect found during a node is in scope. A defect that blocks the node
is fixed in the node. Any other defect gets a dated spec amendment and a new
node with its contract and edges (or an inbox row, see
`references/full-machinery.md`), and the graph is validated again.
Implementers and reviewers report defects in their output; the controller
writes the new node. Nothing goes to a follow-ups list.

### 7.5 Keep: merge into the work branch

1. In the main checkout, on the work branch, merge the node's branch without
   committing yet.
2. Run the node's Acceptance check and the verification floor on the merged
   tree. Nodes that pass alone can fail together; this run shows it. On
   failure, abandon the merge, and the node returns to §7.2 step 3 as a new
   round, with the failure output.
3. On pass: set the node `DONE` with the acceptance result in Refs, archive
   (§9), and commit the merge, the state change and the archive moves as one
   commit.
4. Remove the node's checkout and its branch.

No step changes version-control configuration from a node's checkout:
linked checkouts share the main checkout's configuration, and a change made
from one breaks the main checkout.

### 7.6 Graph completion

When every node is `DONE` or `DROPPED`:

1. Merge the remote default branch into the work branch, and run the
   verification floor.
2. Run the verification stage (§6) over the whole branch, from where it left
   the default branch to its head, on the most capable model, with the
   header's review focus. Confirmed findings become nodes and run through
   §7.2.
3. When the stage passes, deliver the branch in §2 precedence: the
   operator's instruction; else the project's delivery workflow; else open
   one PR for the operator to review, carrying this stage's result and the
   head it reviewed. A defect found in delivery becomes a node (§7.4);
   delivery resumes when that node is `DONE`. Merge only when the operator
   asks.

### 7.7 Branches

An operator instruction about branches, merges or PRs wins. Without one: on
the default branch, create a work branch before the first commit; on any
other branch, keep working in it. Never open a PR per node or per row: work
reaches the default branch only when the operator says so.

## 8. Report

At every stop (a plan written, a session ending, the graph complete), report:

- the graph path and the work branch;
- counts per state, and the nodes closed this session with their commits;
- each stuck node and the decision it needs;
- every check that did not run, marked not run with its reason.

Every claim cites a result from this session.

## 9. Archive, tiers and sync

- **Caps and archive.** `graph.md` holds at most 25 closed rows and 14 days
  of Log, counted back from the newest entry. At every node close, move the
  closed rows beyond the cap and the Log entries beyond the window to
  `history.md`, verbatim. A second archive pass moves nothing. Ids are never
  reused. With another ledger (§3.6) the ledger keeps the node history: the
  row-length and closed-row caps do not apply, archiving moves only old Log
  entries, and the backlog and findings below are off.
- **Backlog and findings.** The full machinery adds a cap of 25 open rows
  with `backlog.md` and refill, the findings inbox, and mechanism heads.
  Read `references/full-machinery.md` when the header has a **Findings:**
  line, `backlog.md` holds rows, or `graph.md` holds more than 25 open rows.
- **Ceremony tiers.** The tier comes from the files a node changes; a
  mechanism head's tier is in its row. Tier A (core or shared code, any
  Critical data loss): one implementer and one review per plan step, plus the
  node's verification stage. Tier B (per-language handler files): one
  implementer per language batch, one reviewer, at most two fix rounds. Tier
  C (docs, corpus, harness, process): the controller works the node itself,
  still in the node's checkout. A `process` node closes by deleting the rule
  it names.
- **Sync with main.** Merge the remote default branch into the work branch at
  node start and at graph completion (§7.6 step 1). Never merge another
  loop's branch. When the operator runs a session that coordinates several
  loops, report each cross-loop event (inbox appended, PR merged, mechanism
  key added) to it in one message, and do not wait for an answer.

## 10. Quality-loop variant

The quality loop is a graph whose nodes come from an architecture audit, not
from a written spec. It lifts structural health one step per cycle and never
lets it slide back. Everything above applies; only the source of acceptance
and the node lifecycle change.

- **Acceptance** comes from the audit. A node is a confirmed finding; its
  Spec field is the finding id and its place in the audit report; its
  Acceptance is the finding's own analysis showing it resolved, plus a
  verdict that the change preserved behavior.
- **The header** records the cycle number and the phase (AUDIT, REMEDIATE or
  RE-AUDIT).
- **Durable state** is the audit's project map, `remediation-log.md`
  (append-only, one row per verified step, keyed to a finding id) and the
  graph.

The cycle:

1. **AUDIT.** Audit the architecture. Create one node per confirmed
   actionable finding, in remediation priority order (cycles > god classes > high coupling > dead code),
   with edges where one fix depends on another (a cycle break before the
   split of a module in that cycle). Table order is
   the order in which ready nodes start. If there is no confirmed actionable
   finding and the trend is stable, stop and report.
2. **REMEDIATE.** Run the graph (§7). Each node makes the structural change
   its finding calls for, then confirms the changed functions preserved
   behavior. A verdict of unsafe or unknown blocks the node. A verdict that
   needs review, unsafe or unknown, or any defect outside the dependency
   graph, is a found issue (§7.4): the audit cannot see it, so the graph is
   its only record.
3. **RE-AUDIT.** Audit again. A finding marked resolved that the structure
   contradicts is a regression and becomes a new node. Increase the cycle
   number and return to step 2.

The audit's refuted findings are carried forward, never dropped. A
quality-loop graph has no authority-spec chain and no per-node premise check
(the audit is the premise check); say so in its header.
