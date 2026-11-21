---
name: plan-work
description: Plans work as a resumable work graph of nodes with contracts, dependencies and fixed acceptance checks, cut from an approved design, validated, reviewed and delivered in a mergeable pull request. Use when the operator asks to write a plan, plan a change, break work down or turn a spec into tasks before writing code ("write a plan", "plan this", "implementation plan", "break this down"), or to create or set up a work loop, work graph or tracker ("create a work loop for this spec", "set up a tracker", "make this resumable").
---

# Plan Work

> ## Rules need the operator's approval
>
> Add no rule the operator has not approved. A rule is anything that can refuse, block, gate, count, budget, ration or slow down work: a gate, check, hook, threshold, budget, ledger or authorization scheme, wherever it is written.
>
> - A citation is who approved the rule and when, or the project file or spec it comes from. A file citation counts only from the project's instruction files (CLAUDE.md, AGENTS.md, CONTRIBUTING, the documents they name, CI configuration) and from a spec or spec section the operator approved; a file or amendment an agent wrote is never a citation on its own authority.
> - To propose a rule, give the operator the rule, the failure it prevents with its evidence, what it costs (time, blocked work, maintenance) and what it gains. Write it only after the operator approves it, with its citation.
> - Every rule in a graph carries its citation. A rule without one is deleted, not debated. Do not write a second rule to work around it.
> - This skill's own rules are its defaults (§2) and carry no citation.

This skill answers "how do we build this approved design". It ends with a
validated work graph in a pull request that can merge. It does not run the
graph: running, resuming and continuing a graph follow the project's
execution workflow.

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
`../work-graph/references/graph-format.md`, cited below as "format §n". The
templates `graph-template.md` and `node-template.md` and the ledger contract
`ledgers.md` sit beside it.

## Who owns what

- **The operator defines the terms.** What the operator said, in this
  conversation or in a project file, is decided. Do not ask it again, do
  not ask the operator to confirm it, and do not redefine it. "Done" means
  what the operator or the project says it means. Without such a
  definition, done is: the work graph is committed, pushed, and in a pull
  request that can merge, with its checks green and no conflict.
- **The author owns the work.** The author is the session that holds the
  conversation. When a subagent writes the text, its brief holds every
  decision, and the session that wrote the brief is still the author. A
  defect in the work is the author's failure. A review measures the
  author; it does not move the responsibility, and it is not run again in
  place of the author's own checks.
- **Mechanics are the author's.** Structure, order, internal names, how to
  test, and how to fix a finding are never questions for the operator.
- **No stop loses work.** Commit and push each artifact when it is first
  written and after each change, so that the session can end at any moment
  without loss.
- **No stop hands the work back.** Do not end a step by telling the
  operator what to type to get the next step. Do the steps the request
  includes, and stop at done.

A graph that the validator rejects, or that the executor cannot run, is
not a graph.

### Questions

A choice is a question for the operator only when all of these are true:

1. The request, the conversation, the repo, a project rule and an approved
   spec do not answer it.
2. The answer changes what the product does for its user.
3. A wrong guess is expensive to reverse.

Every other choice is the author's call: decide it and record it.
Mechanics never pass this test. A design does not ask for an exception to
a project rule; it complies.

Send the questions that pass in one message, each with your recommendation,
so that one word answers it. If none pass, ask none. While a question is
open, continue all work that does not depend on it, on your recommendation.

Node order, graph structure, node size, and the fix for a review finding
are mechanics.

## 1. Entry

| Request | Action |
|---|---|
| Write a plan, plan this, break this down, turn this spec into tasks; create a work loop, set up a graph or a tracker | Create the graph (§3), then deliver it (§6). |

A graph lives in `docs/work/<program>/` unless the project has a
convention. When a graph for the program already exists there, add the new
work to that graph. One request gets one graph on one branch: work from
several specs goes in the same graph, with an edge for each real dependency.
Do not order work between two graphs: the format has no edge between graphs,
and a node that waits on another graph cannot run. When the graph holds more
open rows than `graph.md` allows, the rest go to `backlog.md`
(`../work-graph/references/full-machinery.md`).

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
   lifecycle in `ledger.md` (format §6): for each state change, what the
   lifecycle requires.
4. **Precedence.** An operator instruction, then a workflow the project
   declares, then this skill's defaults. If an adopted workflow conflicts
   with a default in this skill, the higher one in this order applies.
   Record it in the header with its citation.

## 3. Create a graph

1. **Gather inputs.** The authority specs, the verification floor, the
   project's hard rules, the run settings, and what §2 finds. An approved
   design document is an authority spec. When the request's intent, scope or
   constraints are not settled, get an approved design before you cut nodes,
   in §2 precedence: the operator's instruction; else the project's design
   workflow; else agree intent, scope and constraints with the operator and
   write them to a spec. Take what the repo and the conversation give.
   Decide the rest by the test in Questions.
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
5. **Choose each node's capability** (§4).
6. **Write the contracts** (format §4) and the header (format §2).
7. **Author's checks** on the graph, and fix what you find in place:
   1. **Spec coverage.** Every requirement in every authority spec maps to a
      node.
   2. **Interface match.** Every Consumes resolves to a Produces of a node
      the consumer depends on, with the signature as it exists in the code
      now or as the producing node's contract states it.
   3. **Review focus.** Every review-focus line names the node that owns its
      test.
   4. **Proportion.** A contract that describes the code instead of its
      interface has written the code. Replace bodies with signatures and
      acceptance checks.
   5. **Live code.** Open every file, symbol and signature a contract cites
      and confirm each against the code as it is now.
   6. **Runnable.** Every Acceptance is a command. Every id has the form the
      validator accepts. Every node can become ready through edges inside
      this graph.
8. **Validate** the graph (format §7): run
   `python3 <this skill's directory>/../work-graph/scripts/work_graph.py check <graph.md>`
   and read its output. Exit status 0 is the only proof that the graph is
   valid; a report that the graph is valid quotes this output. A session
   that gave the planning to a subagent runs the command again itself.
9. **Commit and push** the graph files together, on a work branch. An operator
   instruction about branches wins. Without one: on the default branch,
   create a work branch before the first commit; on any other branch, keep
   working in it. If the checkouts directory is not ignored by version
   control, ignore it in the same commit, so a merge never stages a
   checkout.
10. **One audit** (§5), then validate again (step 8), commit and push.

## 4. Capabilities

A node's capability is chosen at creation by the work's complexity, nuance
and technicality:

| Capability | Work |
|---|---|
| `lookup` | Read-only work: find files, trace code, summarize, classify, extract; run a check and report its output. Changes no file. |
| `mechanical` | Small edits the plan fully decides: copying, renaming, fixtures, docs that restate code. |
| `implementation` | Ordinary implementation from a complete plan; node reviews. |
| `judgment` | Design choices the plan leaves open; core or shared code; concurrency, security or data-loss risk; interfaces between nodes; a node in its second or later round; planning a node whose spec is ambiguous; the graph-level verification stages. |

A node that edits files is never `lookup`.

A capability names the class of task. A session maps it to the subagent or model it uses for that class of task — `judgment` for demanding or nuanced coding work, `implementation` for normal coding work, `mechanical` and `lookup` for simple work — and never to a newer or frontier model beyond that class. When the session's configuration assigns a model to a role (an implementer, a reviewer, a planner), that assignment wins over the capability.

Choose the subagent by its capability as the session describes it; do not set a model on the call when the session describes subagents.

## 5. One audit

The audit has three steps:

1. **Adversarial review.** The operator's or the project's declared reviewer
   if there is one; otherwise a fresh reviewer that has not seen this
   session, with the `judgment` capability. Tell it to find defects, not to
   approve. Give it the graph, the authority specs it answers, and the review
   focus. Give nothing else: no summary, reasoning or concern from this
   session. It reports each finding with its location, the failure it causes,
   and the evidence.
2. **Verify each finding.** Read the spec or graph text it cites and
   reproduce it. Mark it confirmed or refuted, with the evidence. Record a
   refuted finding with its reason and drop it.
3. **Remediate.** Fix every confirmed finding in the graph: a missing node, a
   wrong or missing edge, an unresolved Consumes, a contract that restates
   the spec or writes the code. The audit passes when no confirmed finding
   is open. It does not run a second time. A finding goes to the operator
   only when it passes the test in Questions; the fix for a finding is the
   author's call. A finding that shows the graph cannot run, or several
   findings of one kind, shows which of the author's checks (§3 step 7) was
   skipped: do that check again over the whole graph.

## 6. Hand over

Open a pull request for the work branch, or update the one that exists,
and make it mergeable: checks green, no conflict. Fix a failed check
yourself. Give the operator the pull request link.

When the request includes running the graph, go on to execution without
asking: it follows the operator's instruction, else the project's
execution workflow. Otherwise stop here; do not start execution, and do
not tell the operator what to type to start it. Any session can continue
the graph from its path.

## 7. Report

At hand-over, report:

- the pull request link and the state of its checks;
- the graph path and the work branch;
- the node count, the ready set, and the authority specs;
- each choice made as the author's call, so the operator can check it;
- every check that did not run, marked not run with its reason.

Every claim cites a result from this session.
