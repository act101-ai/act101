# Ledger adapters

The default ledger is the node table in `graph.md` with `history.md`. When the
operator asks for another ledger, the graph uses it. The process does not
change: nodes, edges, contracts, states, the ready set and the verification
stages are the same. Only the place that stores the node rows changes.

## What stays in files

- `graph.md`: the header and the Log. Its `## Nodes` section holds one line:
  `Nodes live in <ledger>. Mapping: ledger.md.`
- `nodes/<id>.md`: every contract and plan, named by the ledger's id. The
  ledger's record of a node links to this file.

## ledger.md

`ledger.md` sits beside `graph.md`. It maps each operation to how the
ledger does it:

| Operation | Must do |
|---|---|
| Create | Create a node with its id, title and a link to `nodes/<id>.md`. Use the id the ledger assigns as the node id and name the node file after it. |
| Edge | Record that one node depends on another, as a dependency that blocks readiness. |
| State | Set each of `TODO`, `PLANNED`, `IN-PROGRESS`, `DONE`, `BLOCKED(reason)`, `DROPPED(evidence)`. Where the ledger has no status for a state, record it with a label. |
| Model | Record `haiku`, `sonnet` or `opus`. |
| Refs | Add commits and acceptance results to a node. |
| Export | List every node with its id, its dependencies, its state in this skill's states, and its model. |
| Lifecycle | For each state change, what an adopted ticket workflow requires (§2 of the skill). |

The ready set and the schedule (§3.5 of the skill) are computed from the
export, with `parallel` and the Files-overlap rule applied; the ledger's own
view of unblocked work does not know either.

The markdown caps (row length, closed rows) do not apply: the ledger keeps
the node history. Archiving moves only old Log entries from `graph.md` to
`history.md`; the Log window still applies to `graph.md`.

## Proving the mapping

Write `ledger.md` from the ledger's own documentation for the version that
is in use. Then prove every operation once on a scratch node: create it, add
an edge, move it through every state, export, and validate the graph from
the export. Delete the scratch node. A mapping that has not been proven is
not used.
