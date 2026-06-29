---
name: agent-safety-audit
description: Audit whether an AI agent edit to a file is safe — composes secret-surface, taint-flow, change-impact, and API-surface analysis into an agent-edit safety report. Use before letting an agent modify a sensitive or high-blast-radius file.
---

# agent-safety-audit

Produce an **agent-edit safety report** for a file an autonomous agent is about
to (or just did) modify. It answers: does this code touch secrets, carry
untrusted data to dangerous sinks, have a large blast radius, or expose a wide
API the agent could break? Builds on the change-impact approach but its value is
the composition of the four named tools below.

## Honesty caveat (read first)

Every dimension is AST/heuristic. `secret_surface`, `taint_flow`, and
`unsafe`-style scans report `modeled_kinds`; an empty `modeled_kinds` for the
file's grammar means that dimension is **not covered** — that is "no evidence,"
NOT "all clear." Read `modeled_kinds` per call — per the COVERAGE LAW taint (and
the unsafe/secret scans) apply to **every applicable tier-1+ grammar**, so there
is no fixed "supported" grammar list. A non-empty mask for a dimension means it
**was modeled** for this grammar (an empty finding is then genuine — e.g. no
source→sink path); an **empty/absent** mask means that dimension was **not
modeled** — "no evidence," not "clear," and a coverage gap to close. Always name
the language and the uncovered dimensions. Verdicts are advisory, not a security
guarantee.

## Tier

**Architecture.** `taint_flow` is Architecture; the composed tools enforce their own tiers.
If a tool is rejected for tier, the corresponding dimension is UNAUDITED — say
so rather than implying it passed.

## Tools (in order)

| Step | Tool | What it answers |
|---|---|---|
| 1 | `secret_surface` | Does the file touch credentials, tokens, signing keys, env-secret reads, or hardcoded secret literals? |
| 2 | `taint_flow` | Does untrusted input reach a dangerous sink (raw SQL, eval, command exec, fs path, deserialization)? |
| 3 | `analyze_impact` | What is the change's blast radius — which files transitively depend on the target? |
| 4 | `analyze_surface` | How wide is the public API at this boundary the agent might break? |
| 5 | `scan` | Repo-level AI-code threats the per-file tools miss: hardcoded credentials across the tree (pattern + entropy heuristic), `.cursorrules`/AI-config hidden-Unicode backdoors, MCP-config RCE (CVE-2025-59944), typosquat/hallucinated dependencies, GitHub Actions expression injection, LLM-output-to-exec flows, and prompt-injection surfaces. |

## Workflow

1. Call `secret_surface` on the file. Any `CredentialParam` / `TokenVar` /
   `SigningKey` / `EnvSecretRead` / `HardcodedLiteral` hit means the agent is
   editing secret-adjacent code — flag for human review.
2. Call `taint_flow` with `target` + `file`. A source→sink path is a hard flag;
   note any unresolved tainted-arg callees on the frontier (analysis stopped
   there, so downstream is unverified).
3. Call `analyze_impact` with the file as `target` to size the blast radius.
   Many transitive dependents → an agent mistake here cascades widely.
4. Call `analyze_surface` at the file's boundary. A wide exposed API means more
   contract the agent can silently break.
5. Call `scan` on the repo (`root` = repo root). Any `ai_config_backdoor`,
   `mcp_config_rce`, `llm_output_execution`, or `dependency_hallucination`
   finding is a hard **HUMAN REVIEW** flag — these are agent-targeted
   supply-chain / injection attacks the per-file dimensions above do not
   cover. If the repo has a committed `.act/baseline.json`, pass
   `baseline=".act/baseline.json"` — the report's `baseline` section separates
   `new` findings from `baselined` (acknowledged) repo debt, and for an edit
   audit the `new` partition (IDs in `baseline.new_finding_ids`) is the signal
   that matters. Private repos require the scan entitlement; if absent, mark
   this dimension UNAUDITED (never present it as clear).

## Verdict synthesis

- **SAFE-ish** — no secret surface, no taint source→sink path, small blast
  radius, narrow API, and the relevant `modeled_kinds` are non-empty for the
  grammar.
- **HUMAN REVIEW** — secret surface present, a confirmed taint path, large blast
  radius, or a wide API. Name which signal fired — or any `mcp_config_rce` /
  `ai_config_backdoor` finding from `scan`.
- **UNAUDITED** — `taint_flow`/`secret_surface` returned empty `modeled_kinds`
  for this grammar, or a tool was tier-blocked. State which dimension is
  uncovered; never present UNAUDITED as SAFE.

## Output

A per-file safety card: secret hits, taint paths (source → sink, with frontier
notes), blast-radius count, API width, and the verdict. Quote `modeled_kinds`
and the language for every uncovered dimension.
