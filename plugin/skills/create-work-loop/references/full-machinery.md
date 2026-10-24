# Full machinery

These rules add to the core for a graph that keeps its rows in `graph.md`.
With another ledger none of this applies. Section numbers (§n) refer to the
skill's `SKILL.md`.

- **Open rows and backlog.** `graph.md` holds at most 25 open rows.
  `backlog.md` holds the open rows that wait for a slot; a closed row in it is
  a defect, because closed rows go to `history.md`.
- **Refill.** After it trims (§9), archiving makes the open rows of
  `graph.md` the `IN-PROGRESS` rows plus the top of the work order, ready
  rows first. The work order is: the **Next** ids, then mechanism heads by
  score, then the other rows in file order. Only rows with a contract move
  into `graph.md`. Rows move verbatim.
- **Findings**, when the header declares
  `**Findings:** (<citation>) blocks <producer>=F-<low>..F-<high>, <producer>=F-<low>..`.
  A block is closed (`F-<low>..F-<high>`) or open (`F-<low>..`, no upper
  bound), and blocks are separated by commas. A producer name is a lowercase
  letter, then lowercase letters, digits, `_` or `-`. The citation goes
  before `blocks` and does not contain the letters `blocks` anywhere. A
  Findings line whose blocks cannot be read is a defect.
  - A producer appends rows to `findings-inbox/<producer>.md` (or
    `<producer>-<suffix>.md`) under
    `| ID | Mechanism | Kind | Severity | Width | Item | Refs |`, with ids
    from its own block. Inbox files are append-only. A row is a defect when
    its Mechanism is not a key or `unique`, its Kind is not `product`,
    `harness`, `corpus`, `docs` or `process`, its Severity is not
    `Critical`, `Major` or `Minor`, or its Width is not a number.
  - `findings-inbox/MECHANISMS.md` lists the mechanism keys
    (`| Key | Tier | Definition |`, tier `A`, `B`, `C` or `-`). A key names
    the mechanism behind a defect, never the language it was found in. Add a
    new key in the same commit as the first row that uses it.
  - Archiving ingests new inbox rows into `backlog.md` and writes
    `findings/<id>.md`. A finding row waits there with Model `—` until the
    controller writes its contract and sets its Model (§7.1 step 5).
  - Archiving creates one mechanism head `M-n` per key with two or more open
    members (tiers `A`–`C`; not `-`, not `unique`). The head is one node; the
    controller writes its contract, whose Files and Acceptance cover every
    member. The schedule skips the members while the head is open. A head's
    score is its members' severity weight (Critical 3, Major 2, Minor 1) over
    its tier cost (A 3, B 2, C 1). When the head is `DONE`, archiving closes
    its members.
