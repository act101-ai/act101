---
name: change-impact
description: >
  Use before modifying a file or symbol, or when asked "what breaks if I change X?".
  Depth 0 — fast, no follow-up queries, returns immediately. Two modes: inline (no
  artifacts, default for agent-initiated use) and artifact (writes to docs/act/,
  triggered for human-initiated requests or Critical risk verdicts).
---

# Change Impact

**Depth:** Level 0 (Collect).

See `../analysis-protocol/references/protocol.md` for: artifact directory structure,
the investigation loop, depth levels, summary format, token budget rules, and project
map structure.

## Tools

| Tool | Purpose | MCP call | Tier |
|------|---------|----------|------|
| `analyze_impact` (file mode) | Blast radius — files that depend on target (R1) | `analyze_impact` with `target: <file>` | Free |
| `analyze_impact` (symbol mode) | Transitive callers of a function symbol | `analyze_impact` with `target: <file>` and `symbol: <name>` | Teams |
| `analyze_test_gaps` | Is the target tested? (R5) | `analyze_test_gaps` | — |
| `analyze_cycle_risk` | Is the target in a risky cycle? (R6) | `analyze_cycle_risk` | — |

**Symbol mode workflow (Teams):** For PR review or before renaming/changing a function signature,
run `skeleton` to confirm the function exists in the file, then use symbol mode to get the full
transitive caller chain. Append `::<line>` to `symbol` to disambiguate overloads
(e.g. `symbol: "process::42"`). Symbol mode uses syntactic-floor analysis; LSP is not required.
The `confidence`, `modeled_kinds`, and `unresolved` fields in the result are honesty signals —
review them to understand gaps in the analysis.

If `analyze_test_gaps` or `analyze_cycle_risk` are unavailable: run `analyze_impact`
only. Note which tools were skipped in the verdict and caveat accordingly.

If `analyze_impact` is unavailable: report that and stop — no useful verdict possible.

## Two Modes

**Inline mode** (default for agent-initiated use):
- Returns the summary directly to the calling agent
- Does NOT write artifacts to disk
- Use when an agent needs a quick risk check before making a change

**Artifact mode** (for human-initiated requests, or when verdict is Critical):
- Follows the full artifact protocol: create `docs/act/<timestamp>/`, write
  `manifest.json`, save `raw/*.json`, write `report.md`
- Triggered automatically when verdict is **Critical**, even if initially invoked inline
- Triggered by explicit user request (e.g., "analyze impact of changing X")

## Risk Verdict

Compute from tool outputs:

| Verdict | Criteria |
|---------|----------|
| **Low** | Blast radius < 5 files, target is tested, not in a risky cycle |
| **Medium** | Blast radius 5-15 files, OR target is untested |
| **High** | Blast radius > 15 files, OR target is untested AND in a cycle |
| **Critical** | Blast radius > 30 files, OR target is in a high-risk cycle (>50% of codebase risk surface) |

When multiple criteria apply, use the highest verdict. When tools are missing, caveat
the verdict: "Medium (test coverage unknown — analyze_test_gaps not available)".

## Summary Format

Return this to the calling agent:

```
## Change Impact: <target>

**Risk: <Low / Medium / High / Critical>**
- Blast radius: N direct, M transitive dependents
- Test coverage: tested / untested / unknown (tool unavailable)
- Cycle risk: none / low / high (N% of codebase affected) / unknown (tool unavailable)

**Caution areas:** <list of highest-risk direct dependents, or "none identified">
**Suggested:** <e.g., "run tests in X before merging", "review Y for breakage", "run architecture-audit to understand full impact">
```

## Project Map Updates

None. Change Impact reads `project-map.md` (workspace root) for context (chokepoints, known
risky files) but does not modify it.
