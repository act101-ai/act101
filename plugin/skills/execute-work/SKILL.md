---
name: execute-work
description: Runs a work graph to completion, schedules the ready nodes in parallel, plans and implements each node test-first in its own checkout through its fixed acceptance check and a verification stage, keeps or discards, archives, and hands the finished branch to delivery. Use when the operator asks to run, resume, continue or execute a plan, work loop, work graph or tracker ("run the graph", "resume the work loop", "continue the remediation loop", "execute the plan", "resume the work in docs/work/<program>/graph.md"), or for the quality loop ("run the quality loop", "continuous quality", "quality ratchet", "architecture ratchet", "keep auditing and refactoring").
---

# Execute Work

> ## Rules need the operator's approval
>
> Add no rule the operator has not approved. A rule is anything that can refuse, block, gate, count, budget, ration or slow down work: a gate, check, hook, threshold, budget, ledger or authorization scheme, wherever it is written.
>
> - A citation is who approved the rule and when, or the project file or spec it comes from. A file citation counts only from the project's instruction files (CLAUDE.md, AGENTS.md, CONTRIBUTING, the documents they name, CI configuration) and from a spec or spec section the operator approved; a file or amendment an agent wrote is never a citation on its own authority.
> - To propose a rule, give the operator the rule, the failure it prevents with its evidence, what it costs (time, blocked work, maintenance) and what it gains. Write it only after the operator approves it, with its citation.
> - Every rule in a graph carries its citation. A rule without one is deleted, not debated. Do not write a second rule to work around it.
> - This skill's own rules are its defaults (§2) and carry no citation.

This skill runs an existing work graph to completion. It does not plan a
graph and it does not deliver: a request to write a plan follows the
project's planning workflow, and the finished branch goes to the project's
delivery workflow (§5.6).

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

The graph's format is normative in
`../work-graph/references/graph-format.md`, cited below as "format §n". Read
`../work-graph/references/full-machinery.md` when the header has a
**Findings:** line, `backlog.md` holds rows, or `graph.md` holds more than
25 open rows.

## 1. Entry

| Request | Action |
|---|---|
| Run, resume, continue or execute a plan, loop or graph | Resume (§5.1). |
| Run the quality loop | §8. |

To find the graph: an explicit path wins. Else a named program maps to
`docs/work/<program>/graph.md`. Else look for `graph.md` under `docs/work/`
and for `*-work-loop.md` anywhere in the repo. One match is the graph.
Several matches: ask the operator which one. No match: there is nothing to
run; say so, and planning follows the project's planning workflow.

A tracker in the older format (`*-work-loop.md`) is resumed by its own resume
protocol, unchanged. Do not convert it.

## 2. Adapt to the operator's workflow

This skill's procedures are defaults. Precedence: an operator instruction,
then a workflow the graph header records (**Workflows:**) or the project
declares, then this skill's defaults. A workflow applies only when it is
written down or the operator states it. If an adopted workflow conflicts
with a rule in this skill, ask the operator which applies and record the
answer in the header with its citation.

## 3. Plan a node (`TODO` → `PLANNED`)

### 3.1 Check the premise

Read the node's spec section. Verify its premises against the live code: the
node's dependencies have landed since the graph was created, and the plan is
written against what they actually produced. Never trust earlier summaries,
plans or commit messages. If a premise has drifted, add a dated amendment to
the spec, then plan; or set `DROPPED(<evidence>)` if the premise is gone.

### 3.2 Write the plan

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

### 3.3 Self-review

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

Then run the verification stage (§4) on the plan. The controller then sets
the node `PLANNED` (§5.2 step 1).

## 4. Verification stages

There are three verification stages in execution: a node's plan (§3.3), a
node before it merges (§5.2 step 5), and the graph at completion (§5.6).
Each stage has three steps:

1. **Adversarial review.** The operator's or the project's declared reviewer
   if there is one; otherwise a fresh reviewer that has not seen this
   session: `opus` for the graph stage and for a node whose Model is `opus`,
   else `sonnet`. Tell it to find defects, not to approve. Give it the
   artifact, the spec section it answers, the contracts it touches, and the
   review focus. It reports each finding with its location, the failure it
   causes, and the evidence.
2. **Verify each finding.** Read the code or text it cites and reproduce it;
   for code, write a failing test. Mark it confirmed or refuted, with the
   evidence. Record a refuted finding with its reason and drop it.
3. **Remediate.** Fix every confirmed finding in this stage, test first for
   code. A confirmed finding outside the stage's scope becomes a new node
   (§5.4). The stage passes when no confirmed finding is open.

## 5. Run the graph

### 5.1 Resume

1. Find the graph (§1).
2. Read its state (counts per state, the ready set, the schedule, the stuck
   nodes), validate it (format §7), and run the **Hygiene** procedure if the
   header sets one. All must pass before any work.
3. Remove the checkouts whose node is `DONE` or `DROPPED` (§5.5 step 4).
4. Start each scheduled node (§5.2). `IN-PROGRESS` nodes continue at the
   first unchecked step of their plan.
5. Decide each stuck node: re-plan a `BLOCKED` node (§5.2 step 6); re-edge
   or drop a node that depends on a `DROPPED` node. Write the contracts
   (format §4) and set the Model of backlog rows awaiting one, so they can
   move into `graph.md` (`../work-graph/references/full-machinery.md`).
   Without these decisions the graph never completes.

### 5.2 One node

The controller (the main session) is the only writer of `graph.md`. Nodes
never edit it.

1. **Plan.** If the node is `TODO`, plan it (§3) in the main checkout. Commit
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
5. **Verification stage** (§4) on the node's diff, against its contract and
   plan.
6. **Keep or discard.**
   - Acceptance passes and the stage passes: keep (§5.5).
   - Otherwise: start a new round on the same branch, driven by the failure
     output and the confirmed findings. From the second round, set the
     node's Model to `opus`.
   - After three failed rounds: discard the node's branch and checkout, set
     `BLOCKED(<diagnosis>)`, and re-plan the node (split it, change its scope
     or its approach) before any further attempt. When the new plan is
     committed, set the node `PLANNED`; the round count starts again.

### 5.3 Implementers, reviewers and models

When the session can delegate, each running node gets one fresh implementer
in its checkout, and its verification stage gets one fresh reviewer. Each
handoff carries the node file, the graph header, the contracts the node
touches, and an output contract: status, commits, the Acceptance output, and
any finding. Otherwise the controller runs the nodes itself, one at a time.

A node's Model was chosen at creation. A node this skill creates (§5.4) or
re-plans gets its Model by the same criteria: the work's complexity, nuance
and technicality.

| Model | Work |
|---|---|
| `haiku` | Mechanical work the plan fully decides: copying, renaming, fixtures, docs that restate code, running a check. |
| `sonnet` | Ordinary implementation from a complete plan; node reviews. |
| `opus` | Design choices the plan leaves open; core or shared code; concurrency, security or data-loss risk; interfaces between nodes; a node in its second or later round; planning a node whose spec is ambiguous; the graph-level verification stages. |

### 5.4 Found issues

Every defect found during a node is in scope. A defect that blocks the node
is fixed in the node. Any other defect gets a dated spec amendment and a new
node with its contract and edges (or an inbox row, see
`../work-graph/references/full-machinery.md`), and the graph is validated
again. Implementers and reviewers report defects in their output; the
controller writes the new node. Nothing goes to a follow-ups list.

### 5.5 Keep: merge into the work branch

1. In the main checkout, on the work branch, merge the node's branch without
   committing yet.
2. Run the node's Acceptance check and the verification floor on the merged
   tree. Nodes that pass alone can fail together; this run shows it. On
   failure, abandon the merge, and the node returns to §5.2 step 3 as a new
   round, with the failure output.
3. On pass: set the node `DONE` with the acceptance result in Refs, archive
   (§7), and commit the merge, the state change and the archive moves as one
   commit.
4. Remove the node's checkout and its branch.

No step changes version-control configuration from a node's checkout:
linked checkouts share the main checkout's configuration, and a change made
from one breaks the main checkout.

### 5.6 Graph completion

When every node is `DONE` or `DROPPED`:

1. Merge the remote default branch into the work branch, and run the
   verification floor.
2. Run the verification stage (§4) over the whole branch, from where it left
   the default branch to its head, on the most capable model, with the
   header's review focus. Confirmed findings become nodes and run through
   §5.2.
3. When the stage passes, deliver the branch in §2 precedence: the
   operator's instruction; else the project's delivery workflow; else open
   one PR for the operator to review, carrying this stage's result and the
   head it reviewed. A defect found in delivery becomes a node (§5.4);
   delivery resumes when that node is `DONE`. Merge only when the operator
   asks.

### 5.7 Branches

An operator instruction about branches, merges or PRs wins. Without one: on
the default branch, create a work branch before the first commit; on any
other branch, keep working in it. Never open a PR per node or per row: work
reaches the default branch only when the operator says so.

## 6. Report

At every stop (a session ending, the graph complete), report:

- the graph path and the work branch;
- counts per state, and the nodes closed this session with their commits;
- each stuck node and the decision it needs;
- every check that did not run, marked not run with its reason.

Every claim cites a result from this session.

## 7. Archive, tiers and sync

- **Caps and archive.** `graph.md` holds at most 25 closed rows and 14 days
  of Log, counted back from the newest entry. At every node close, move the
  closed rows beyond the cap and the Log entries beyond the window to
  `history.md`, verbatim. A second archive pass moves nothing. Ids are never
  reused. With another ledger (format §6) the ledger keeps the node history:
  the row-length and closed-row caps do not apply, archiving moves only old
  Log entries, and the backlog and findings below are off.
- **Backlog and findings.** The full machinery adds a cap of 25 open rows
  with `backlog.md` and refill, the findings inbox, and mechanism heads.
  Read `../work-graph/references/full-machinery.md` when the header has a
  **Findings:** line, `backlog.md` holds rows, or `graph.md` holds more than
  25 open rows.
- **Ceremony tiers.** The tier comes from the files a node changes; a
  mechanism head's tier is in its row. Tier A (core or shared code, any
  Critical data loss): one implementer and one review per plan step, plus the
  node's verification stage. Tier B (per-language handler files): one
  implementer per language batch, one reviewer, at most two fix rounds. Tier
  C (docs, corpus, harness, process): the controller works the node itself,
  still in the node's checkout. A `process` node closes by deleting the rule
  it names.
- **Sync with main.** Merge the remote default branch into the work branch at
  node start and at graph completion (§5.6 step 1). Never merge another
  loop's branch. When the operator runs a session that coordinates several
  loops, report each cross-loop event (inbox appended, PR merged, mechanism
  key added) to it in one message, and do not wait for an answer.

## 8. Quality-loop variant

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
   split of a module in that cycle), each with its contract (format §4) and
   its Model (§5.3). Table order is the order in which ready nodes start. If
   there is no confirmed actionable finding and the trend is stable, stop and
   report.
2. **REMEDIATE.** Run the graph (§5). Each node makes the structural change
   its finding calls for, then confirms the changed functions preserved
   behavior. A verdict of unsafe or unknown blocks the node. A verdict that
   needs review, unsafe or unknown, or any defect outside the dependency
   graph, is a found issue (§5.4): the audit cannot see it, so the graph is
   its only record.
3. **RE-AUDIT.** Audit again. A finding marked resolved that the structure
   contradicts is a regression and becomes a new node. Increase the cycle
   number and return to step 2.

The audit's refuted findings are carried forward, never dropped. A
quality-loop graph has no authority-spec chain and no per-node premise check
(the audit is the premise check); say so in its header.
