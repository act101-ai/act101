---
name: change-impact
description: Use before modifying a file or symbol, or when asked "what breaks if I change X?". Returns a blast-radius, test-coverage, and cycle-risk verdict immediately, with no follow-up investigation.
---

# Change Impact

**Depth:** Level 0 (Collect). Read `../analysis-protocol/references/protocol.md` for
the artifact layout and project-map structure; the summary format is defined below.

## Tools

| Tool | Purpose | Call | Tier |
|------|---------|------|------|
| `analyze_impact` (file mode) | Files that depend on the target, directly and transitively (R1) | `analyze_impact` with `target: <file>` | Free |
| `analyze_impact` (symbol mode) | Transitive callers of one function | `analyze_impact` with `target: <file>` and `symbol: <name>` | Architecture |
| `analyze_test_gaps` | Is the target tested? (R5) | `analyze_test_gaps` | Architecture |
| `analyze_cycle_risk` | Is the target in a risky cycle? (R6) | `analyze_cycle_risk` | Architecture |

**Symbol mode** (PR review, or before renaming or changing a signature): run
`skeleton` to confirm the function exists in the file, then call symbol mode. Append
`::<line>` to `symbol` to disambiguate overloads (`symbol: "process::42"`). Symbol
mode is syntactic-floor analysis and needs no LSP. Read `confidence`,
`modeled_kinds`, and `unresolved` in the result: they state where the analysis
stopped.

If `analyze_test_gaps` or `analyze_cycle_risk` is unavailable, run `analyze_impact`
alone and name the skipped tool in the verdict. If `analyze_impact` is unavailable,
report that and stop.

## Two modes

**Inline** (default for agent-initiated use): return the summary below to the caller
and write nothing to disk.

**Artifact** (human-initiated requests such as "analyze impact of changing X", or
any Critical verdict, even when the run started inline): follow the protocol's
artifact steps, writing `.act/runs/<YYYY-MM-DD-HHMMSS>/` with `manifest.json`,
`raw/*.json`, and `report.md`.

## Risk verdict

| Verdict | Criteria |
|---------|----------|
| **Low** | Blast radius under 5 files, target tested, not in a risky cycle |
| **Medium** | Blast radius 5-15 files, or target untested |
| **High** | Blast radius over 15 files, or target untested and in a cycle |
| **Critical** | Blast radius over 30 files, or target in a high-risk cycle (over 50% of codebase risk surface) |

Take the highest verdict that applies. When a tool was skipped, qualify the
verdict: "Medium (test coverage unknown: analyze_test_gaps unavailable)".

## Summary format

```
## Change Impact: <target>

**Risk: <Low / Medium / High / Critical>**
- Blast radius: N direct, M transitive dependents
- Test coverage: tested / untested / unknown (tool unavailable)
- Cycle risk: none / low / high (N% of codebase affected) / unknown (tool unavailable)

**Caution areas:** <highest-risk direct dependents, or "none identified">
**Suggested:** <e.g. "run tests in X before merging", "review Y for breakage", "run architecture-audit for the full picture">
```

## Project map

Reads `project-map.md` (workspace root) for context such as chokepoints and known
risky files. Never modifies it.
