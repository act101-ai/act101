---
name: security-surface
description: >
  Use to produce an application-security surface report for a file or module —
  dangerous constructs, secret-touching code, and source→sink taint flows.
  Composes unsafe_surface + secret_surface + taint_flow + analyze_surface.
  Architecture tier (taint_flow is Architecture). Inline by default; artifact mode for
  human-initiated audits or High/Critical verdicts.
---

# Security Surface

**Composes (ops only — never other skills):**

| Tool | Purpose | MCP call | Tier |
|------|---------|----------|------|
| `unsafe_surface` | Dangerous constructs (eval, raw SQL, FFI, unsafe blocks, reflection, deserialize) | `unsafe_surface` with `file: <F>` | Free |
| `secret_surface` | Credential params, tokens, signing keys, env reads, hardcoded secrets | `secret_surface` with `file: <F>` | Engineering |
| `taint_flow` | Source→sink data-flow paths from an entry function | `taint_flow` with `target: <fn>, file: <F>` | Architecture |
| `analyze_surface` | API surface area at the module boundary (context) | `analyze_surface` | Engineering |
| `scan` | Repo-wide superset: credential (pattern + entropy) / AI-config-backdoor / MCP-RCE / typosquat-dependency / Actions-injection / LLM-output-to-exec / prompt-injection-surface detectors across the whole tree + Health Score | `scan` with `root: <repo>` | Free (public) / scan entitlement (private) |

**Tier:** Architecture (the max of composed op tiers; `taint_flow` gates it).

## When to use
Before merging or shipping code that handles untrusted input, on a security review,
or when asked "what's the attack surface of X?". For a single entry point, pass its
function name as `taint_flow`'s `target`.

For a **whole-repo** read (not a single file/module), call `scan` — it runs the
full detector set across the tree (credentials incl. the entropy heuristic,
`.cursorrules`/AI-config backdoors, MCP-config RCE, typosquat/hallucinated
dependencies, GitHub Actions expression injection, LLM-output-to-exec taint,
prompt-injection surfaces) and returns the AI-Code Health Score. Use the
per-file ops above for a focused single-file/module surface.

## Procedure
1. `unsafe_surface(file)` — collect dangerous constructs with confidence.
2. `secret_surface(file)` — collect secret-touching symbols.
3. For each entry function in the file (exported / request handler / `main`), run
   `taint_flow(target, file)` — collect source→sink flows + the frontier.
4. `analyze_surface` — note how exposed the module is (context for severity).

If `taint_flow` is unavailable (below Architecture), run steps 1–2 + 4 and caveat the
verdict: "taint flows not analyzed (Architecture tier required)."

## Honesty caveat (read first)

`taint_flow` coverage is reported per call in `modeled_kinds` — read it; never
assume a fixed list of "supported" grammars. Coverage rule: taint applies to
**every applicable tier-1+ grammar** — there is no language subset to enumerate:

- A non-empty `modeled_kinds:{taint}` means taint **was modeled** for this
  grammar; an empty `flows` result is then a genuine **"no source→sink flow
  found."**
- An **empty / absent** `taint` in `modeled_kinds` means taint was **not
  modeled** for this grammar — **"no evidence," not "no taint."** Never emit a
  Low / "no taint flows" verdict on that basis: name the language and caveat the
  taint dimension as **not analyzed**, not clean. A not-modeled result is a
  coverage gap to close, never a feature boundary.

## Severity verdict

| Verdict | Criteria |
|---------|----------|
| **Low** | No taint flows **AND taint was actually covered for this grammar** (real flows would populate); no high-confidence unsafe items; no hardcoded secrets. If taint is uncovered/not-modeled for the grammar, this is NOT Low — caveat the taint dimension as not analyzed (see Honesty caveat). |
| **Medium** | Unsafe items present but no tainted flow reaches them; OR secret-touching code without hardcoded literals |
| **High** | At least one source→sink taint flow to a sink; OR a hardcoded secret literal |
| **Critical** | A taint flow to a RawSql / CommandExec / Eval sink, OR a hardcoded signing key, on an exposed boundary |

Use the highest applicable verdict. Caveat when a tool was skipped or when
`modeled_kinds`/`frontier` show the analysis was partial (e.g. "flow analysis
incomplete — unresolved callees: …").

## Summary format

```
## Security Surface: <file / module>

**Severity: <Low / Medium / High / Critical>**
- Taint flows: N (sinks: <RawSql x2, Eval x1, …>) — or "none / not analyzed (tier)"
- Unsafe constructs: N (<eval x1, raw_sql x2, …>)
- Secret touches: N (<hardcoded_literal x1, token_var x2, …>)
- Frontier (unresolved tainted callees): <list, or "none">

**Top risks:** <ranked source→sink flows and high-confidence unsafe/secret items>
**Suggested:** <e.g. "parameterize the SQL at <loc>", "move the hardcoded key to env", "resolve <callee> to complete flow analysis">
**Coverage caveat:** <modeled_kinds gaps / skipped tools / partial flow>
```

## Artifact mode
Inline by default (return the summary to the caller, no files). For human-initiated
audits or a High/Critical verdict, follow the artifact protocol in
`../analysis-protocol/references/protocol.md` (write `.act/runs/<YYYY-MM-DD-HHMMSS>/` with
`manifest.json`, `raw/*.json`, `report.md`).

## Project Map Updates
None. Reads `project-map.md` for context (entry points, risky files) but does not modify it.
