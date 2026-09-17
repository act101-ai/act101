---
name: security-surface
description: Use on a security review, before shipping code that handles untrusted input, or when asked "what's the attack surface of X?". Produces an application-security surface report for a file or module, or a whole-repo scan.
---

# Security Surface

## Tools

| Tool | Purpose | Call | Tier |
|------|---------|------|------|
| `unsafe_surface` | Dangerous constructs: eval, raw SQL, FFI, unsafe blocks, reflection, unsafe deserialization | `unsafe_surface` with `file` | Free |
| `secret_surface` | Credential params, tokens, signing keys, env-secret reads, hardcoded secrets | `secret_surface` with `file` | Engineering |
| `taint_flow` | Source-to-sink data-flow paths from an entry function | `taint_flow` with `target` and `file` | Architecture |
| `analyze_surface` | API surface at the module boundary, as severity context | `analyze_surface` | Engineering |
| `scan` | Whole-repo superset: credentials (pattern plus entropy), AI-config backdoors, MCP-config RCE, typosquat or hallucinated dependencies, Actions expression injection, LLM-output-to-exec flows, prompt-injection surfaces, plus the AI-Code Health Score | `scan` with `root` | Free for public repos; scan entitlement for private |

The skill's tier is Architecture, the maximum of the composed tools.

For a **whole-repo** read, call `scan`; it runs the full detector set across the
tree. Use the per-file tools for a focused file or module surface.

## Procedure

1. `unsafe_surface(file)`: dangerous constructs with confidence.
2. `secret_surface(file)`: secret-touching symbols.
3. For each entry function in the file (exported, request handler, `main`), run
   `taint_flow(target, file)`: source-to-sink flows plus the frontier.
4. `analyze_surface`: how exposed the module is.

If `taint_flow` is unavailable (below Architecture), run steps 1, 2, and 4 and state
"taint flows not analyzed (Architecture tier required)" in the verdict.

## Severity

| Verdict | Criteria |
|---------|----------|
| **Low** | No taint flows, with taint modeled for this grammar; no high-confidence unsafe items; no hardcoded secrets |
| **Medium** | Unsafe items present but no tainted flow reaches them; or secret-touching code without hardcoded literals |
| **High** | At least one source-to-sink taint flow; or a hardcoded secret literal |
| **Critical** | A taint flow into a RawSql, CommandExec, or Eval sink, or a hardcoded signing key, on an exposed boundary |

Take the highest verdict that applies. When a tool was skipped, or `modeled_kinds`
or `frontier` show the analysis was partial, say so ("flow analysis incomplete:
unresolved callees …").

## Coverage

`taint_flow` reports what it modeled in `modeled_kinds` per call, and there is no
fixed list of supported grammars. A non-empty `taint` entry in `modeled_kinds` with
an empty `flows` result is a genuine "no source-to-sink flow found". An empty or
absent `taint` entry means taint was not modeled for this grammar: report the taint dimension as "not
analyzed", name the language, and give no Low verdict on that basis.

## Summary format

```
## Security Surface: <file / module>

**Severity: <Low / Medium / High / Critical>**
- Taint flows: N (sinks: <RawSql x2, Eval x1, …>) — or "none" / "not analyzed (tier)"
- Unsafe constructs: N (<eval x1, raw_sql x2, …>)
- Secret touches: N (<hardcoded_literal x1, token_var x2, …>)
- Frontier (unresolved tainted callees): <list, or "none">

**Top risks:** <ranked source-to-sink flows and high-confidence unsafe or secret items>
**Suggested:** <e.g. "parameterize the SQL at <loc>", "move the hardcoded key to env", "resolve <callee> to complete flow analysis">
**Coverage caveat:** <modeled_kinds gaps / skipped tools / partial flow>
```

## Artifact mode

Inline by default: return the summary and write no files. For human-initiated audits
or a High or Critical verdict, follow the artifact steps in
`../analysis-protocol/references/protocol.md`: write `.act/runs/<YYYY-MM-DD-HHMMSS>/`
with `manifest.json`, `raw/*.json`, and `report.md`.

## Project map

Reads `project-map.md` for context (entry points, risky files). Never modifies it.
