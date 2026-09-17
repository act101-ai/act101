---
name: agent-safety-audit
description: Use before an autonomous agent edits a sensitive or high-blast-radius file, or to judge an edit it already made. Composes secret surface, taint flow, blast radius, API width, and the repo scan into one safety verdict.
---

# agent-safety-audit

Produce a per-file **agent-edit safety card**: does this code touch secrets, carry
untrusted data to a dangerous sink, have a large blast radius, or expose a wide API
the agent could break?

## Tools, in order

| Step | Tool | Question it answers |
|---|---|---|
| 1 | `secret_surface` | Does the file touch credentials, tokens, signing keys, env-secret reads, or hardcoded secret literals? |
| 2 | `taint_flow` | Does untrusted input reach a dangerous sink (raw SQL, eval, command exec, fs path, deserialization)? |
| 3 | `analyze_impact` | How many files transitively depend on the target? |
| 4 | `analyze_surface` | How wide is the public API at this boundary? |
| 5 | `scan` | Repo-level AI-code threats the per-file tools miss: hardcoded credentials across the tree, `.cursorrules`/AI-config hidden-Unicode backdoors, MCP-config RCE, typosquat or hallucinated dependencies, GitHub Actions expression injection, LLM-output-to-exec flows, prompt-injection surfaces. |

`taint_flow` is Architecture tier; each tool enforces its own tier.

## Workflow

1. `secret_surface` on the file. Any `CredentialParam`, `TokenVar`, `SigningKey`,
   `EnvSecretRead`, or `HardcodedLiteral` hit means the agent is editing
   secret-adjacent code: flag for human review.
2. `taint_flow` with `target` and `file`. A source-to-sink path is a hard flag. Note
   unresolved tainted-arg callees on the frontier: analysis stopped there, so
   downstream is unverified.
3. `analyze_impact` with the file as `target` to size the blast radius.
4. `analyze_surface` at the file's boundary.
5. `scan` with `root` set to the repo root. Any `ai_config_backdoor`,
   `mcp_config_rce`, `llm_output_execution`, or `dependency_hallucination` finding is
   a hard HUMAN REVIEW flag. If the repo has a committed `.act/baseline.json`, pass
   `baseline=".act/baseline.json"` and read the `new` partition
   (`baseline.new_finding_ids`): findings absent from the committed baseline.
   The `baselined` partition is acknowledged debt, not a second signal.
   Private repos need the scan entitlement; without it, mark this dimension
   UNAUDITED.

## Verdict

- **SAFE-ish**: no secret surface, no taint path, small blast radius, narrow API,
  and non-empty `modeled_kinds` from `secret_surface`, `taint_flow`, and
  `analyze_surface`.
- **HUMAN REVIEW**: any secret hit, confirmed taint path, large blast radius, wide
  API, or a `scan` finding of the four kinds named in step 5. Name the signal that
  fired.
- **UNAUDITED**: `secret_surface`, `taint_flow`, or `analyze_surface` returned
  empty `modeled_kinds` for this grammar, or a tool was tier-blocked. Name the
  dimension and the language.

## Coverage

Every dimension is AST or heuristic. `secret_surface`, `taint_flow`, and
`analyze_surface` report what they modeled in `modeled_kinds`. A non-empty mask with an empty finding is a genuine negative. An
empty or absent mask means the dimension was not modeled for this grammar: report it
as UNAUDITED, never as clear. Verdicts are advisory, not a security guarantee.

## Output

One safety card per file: secret hits, taint paths (source to sink, with frontier
notes), blast-radius count, API width, `scan` findings, the verdict, and the
`modeled_kinds` plus language for every uncovered dimension.
