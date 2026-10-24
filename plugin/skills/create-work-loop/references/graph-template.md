# Graph template

Copy the block below to `docs/work/<program>/graph.md` and fill every `<slot>`.
Delete an optional header line you do not use. The result must be a valid
graph (§3.7 of the skill). A `<citation>` is who approved the rule and when,
or the project instruction file or operator-approved spec it comes from (the
notice in `SKILL.md`).

```markdown
# <Program> Work Graph

<!-- work-graph -->

**Goal:** <one sentence>
**Authority:** <spec paths>
**Run:** parallel=3 · worktrees=.worktrees/<program>/ · disk-per-node=—
**Next:** —
**Findings:** (<citation>) blocks <producer>=F-<low>..F-<high>, <producer>=F-<low>..
**Ledger:** <name> — see ledger.md (<citation>)
**Workflows:** <what it governs> — <citation>
**Hygiene:** <procedure> — <citation>

To continue in any session: "resume the work in `docs/work/<program>/graph.md`".

## Global constraints

- <requirement, with the exact value from the spec> — <spec path> §<section>
- <project hard rule, copied verbatim> — <instruction file>
- <rule the operator stated> — <who approved it>, <YYYY-MM-DD>

## Verification floor

- <surface>: <check> — <citation>

## Review focus

1. <input class or failure mode> — <expected behavior> — test in <node id> — <spec path> §<section>

## Nodes

| ID | Node | Depends | State | Model | Refs |
|----|------|---------|-------|-------|------|
| N1 | <what the node delivers> | — | TODO | sonnet | — |

## Log

| Date | Event |
|------|-------|
| <YYYY-MM-DD> | Graph created from <spec>. |
```

A **Run:** `parallel` other than `3` or `disk-per-node` other than `—` is
followed by `(<citation>)` at the end of the line; `worktrees` needs none.
A `<producer>` is a lowercase letter, then lowercase letters, digits, `_` or
`-`. The **Findings:** `<citation>` does not contain the letters `blocks`.

With another ledger (§3.6 of the skill), replace the node table with one
line: `Nodes live in <ledger>. Mapping: ledger.md.`

Archiving creates `history.md` and `backlog.md` when it first needs them.
