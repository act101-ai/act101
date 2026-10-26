# Node template

Copy the block below to `docs/work/<program>/nodes/<id>.md` at creation. Fill
the contract; write `—` for Files, Consumes or Produces when there is nothing
to list. The plan is written when the node starts.

```markdown
# <id> — <what the node delivers>

**Spec:** <spec path> §<section>
**Files:** `<path>`, `<path>`
**Consumes:** `<name>` (<id of the node that produces it>)
**Produces:** `<name(params) -> return type>`
**Acceptance:** `<check>` → <the result that means pass>

## Plan

**Interfaces (as they exist now):**
- Consumes: `<exact signature>`
- Produces: `<exact signature>`

- [ ] Write the failing test `<test name>`:
      <assertions as code, with the spec's exact values>
- [ ] Run `<check>` → FAIL: <expected failure>
- [ ] Implement `<signature>` in `<path>`
- [ ] Run `<check>` → PASS
- [ ] Commit
```
