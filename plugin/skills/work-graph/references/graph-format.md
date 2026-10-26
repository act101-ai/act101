# Work graph format

The format of a work graph: its files, header, node table, node contracts,
ready set, ledgers and validity. Normative for the skills that create and
run a graph. Beside this file: the templates `graph-template.md` and
`node-template.md`, the ledger contract `ledgers.md`, and the backlog and
findings machinery `full-machinery.md`.

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

## 1. Files

A graph lives in `docs/work/<program>/` unless the project has a convention.

| File | Holds |
|---|---|
| `graph.md` | The header, the node table, and the Log. The only file a resume reads in full. |
| `nodes/<id>.md` | One node's contract and plan. |
| `history.md` | Closed rows and old Log entries, moved verbatim. Append-only. |
| `backlog.md` | Open rows that wait for a slot in `graph.md` (`full-machinery.md`). |
| `findings-inbox/`, `findings/<id>.md` | Findings intake and evidence, when the graph declares findings (`full-machinery.md`). |

Templates: `graph-template.md` and `node-template.md`.

## 2. The header

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
  citation. Read `full-machinery.md` before you declare it.
- **Ledger:** optional (§6), with its citation.
- **Workflows:** optional. The workflows adopted at creation: what each
  governs, and its citation.
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

## 3. The node table

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

## 4. The node contract

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
  part of the contract, not a rule under the approval notice: it takes its
  authority from the spec and the skill's defaults; for a node created from a
  found defect, from the dated spec amendment that records the defect, which
  approves no rule.
- A name is the identifier before `(`, with its path: `config::load`,
  `Config.load`. A keyword in front of it (`fn`, `def`) is ignored; without
  `(`, the name is the leading identifier (`MAX: usize` declares `MAX`). A
  consumed name matches a produced name exactly, or names its last segment
  (`load` matches `config::load`).
- Write `—` for a field that has nothing to list. Acceptance is never `—`.

## 5. The ready set

A node is ready when its state is `TODO` or `PLANNED` and every dependency
is `DONE`. The schedule is: `IN-PROGRESS` nodes first, then ready nodes in
table order, up to `parallel`, skipping a node whose Files overlap a node
already scheduled. Scheduled nodes run at the same time, each in its own
isolated checkout, unless the operator restricts this.

## 6. Another ledger

When the operator asks for an issue tracker or any other ledger, use it in
place of the node table, and cite the request in the **Ledger:** line.
`graph.md` keeps the header and the Log, and its `## Nodes` section points
to the ledger. Contracts and plans stay in `nodes/<id>.md`. `ledger.md` maps
each operation to how the ledger does it. Prove every operation once on a
scratch node before the graph is committed. A mapping that has not been
proven is not used. With another ledger, archiving moves only old Log
entries; the ledger keeps the node history. The contract: `ledgers.md`.

## 7. A valid graph

A graph is valid when it has no cycle, no edge to an unknown node, no
missing contract field, no Consumes that does not resolve to a Produces of a
node it depends on, no Files overlap between nodes with no path between
them, a `parallel` setting that is a whole number or `off`, and no more
closed rows or Log entries than the archive caps allow (25 closed rows and
14 days of Log, counted back from the newest entry; with another ledger,
only the Log window applies). Confirm validity at creation and at every
resume, before any work.
