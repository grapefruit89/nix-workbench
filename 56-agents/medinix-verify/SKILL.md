---
schema_version: "1.0"
id: medinix-verify
name: medinix-verify
metadata:
  title: mediNix Verify
version: "1.0"
status: active
layer: agent
domain: verify
summary: >
  Verify objectively whether a change is verified: run the available checks
  in the canonical pipeline and report PASS, FAIL, BLOCKED or UNVERIFIED —
  never a subjective "looks good".
description: >
  Objective verification for mediNix-core changes: the canonical pipeline
  (formatter → NIXMETA → docs → static checks → Nix evaluation → mediNix
  invariants → git diff), the four-state result model, the evidence rule,
  and the standard VERIFY report. Use after every change, before claiming
  any work is done.
purpose:
  - "Establish what is actually verified versus only assumed."
  - "Report each check's real status: PASS, FAIL, BLOCKED or UNVERIFIED."
when_to_use:
  - "After any change to mediNix-core files, before declaring it done."
  - "When a claim about the repo's state needs objective backing."
when_not_to_use:
  - "Finding root causes — medinix-debug's job."
  - "Judging whether an audit finding is real — medinix-review's job."
inputs:
  - "The change under verification (diff, file set)."
outputs:
  - "A VERIFY report with per-level statuses and an overall RESULT."
authority:
  local:
    - "AGENTS.md"
    - "mediNix architecture"
    - "Decimal System"
    - "NIXMETA"
  external:
    - "NixOS/nixpkgs"
  rule: >
    Local mediNix architecture and explicit project invariants take
    precedence over external patterns.
research:
  upstream:
    repo: null
    docs: null
    api: null
  nixpkgs:
    package: null
    module: null
    tests: null
  reference:
    repos: []
  context7:
    enabled: false
    library_id: null
related:
  skills: [medinix-discipline, medinix-nix, medinix-review, medinix-debug]
  tools: [medinix-meta-check, medinix-meta-docs]
  files: [flake.nix, AGENTS.md]
invariants:
  - "A check may be reported PASS only if it was actually executed."
  - "A missing infrastructure check is BLOCKED/UNVERIFIED, never PASS."
  - "No external source may waive a local mediNix invariant."
verification:
  required:
    - "VERIFY report in the standard format with per-level statuses."
    - "git diff --check clean; only expected files changed."
  preferred:
    - "nix flake check on a Nix-equipped host."
change_policy:
  scope: surgical
  avoid:
    - "Unrequested abstraction."
    - "Unrelated refactoring."
  deletion_over_addition: true
output_contract: "VERIFY report (per-level statuses + RESULT + OPEN)"
notes: []
---

# mediNix Verify — Objective, Not Optimistic

## 1. Canonical pipeline

```
Agent writes
    ↓
Formatter
    ↓
NIXMETA
    ↓
Docs / generated-state checks
    ↓
Static checks
    ↓
Nix evaluation
    ↓
mediNix invariant checks
    ↓
Git diff / diff --check
    ↓
RESULT
```

Not every step is runnable on every host. A required check that cannot run
because of missing infrastructure is `BLOCKED` or `UNVERIFIED` — never
`PASS`.

## 2. Status model — exactly four states

- **PASS** — the check was actually executed and passed.
- **FAIL** — the check was executed and found a problem.
- **BLOCKED** — the check could not run due to an external precondition
  (e.g. `nix flake check → BLOCKED: nix executable unavailable`).
- **UNVERIFIED** — the available information is insufficient to treat a
  statement as verified. Never treat as PASS.

## 3. Verification levels

### 3.1 Format
- Relevant formatter (nixfmt for `.nix`), `git diff --check`, no obvious
  whitespace/format problems.
- Formatter success is NOT functional correctness.

### 3.2 NIXMETA
- For every changed `.nix` file: header present, required fields present,
  `medinix-meta check` green.
- For generated `AGENTS.md`: edit the SOURCE (NIXMETA header or
  generator), never patch the generated file directly.

### 3.3 Documentation / generated state
- `medinix-meta check-docs` green; generated docs consistent; no manual
  drift states.

### 3.4 Static checks
- Syntax and static analysis when available and relevant; existing mediNix
  gates (registry/decimal-enforcer via `medinix-meta check`).
- Never invent a new checking tool just to produce a green display.

### 3.5 Nix evaluation
- If `nix` is available: `nix flake check` (or the existing relevant
  flake gates).
- If not: `BLOCKED` / `UNVERIFIED`. Static reading never substitutes for
  evaluation.

### 3.6 mediNix invariants
Verify against the actually applicable invariants — Decimal System,
registry consistency, port/UID/GID conventions, NIXMETA, factory usage
where mandated, hardening rules, credentials rules, portability, no
unauthorized host coupling, no unallowed new abstractions. The local
mediNix source is authoritative; no external source "verifies away" a
local invariant.

### 3.7 Git diff / repo-sanity
Always close with:
```
git status
git diff --check
git diff
56-agents/shared/scripts/repo-sanity.sh   # with declared scope, if any
```
Check: only expected files changed, no accidental edits, no secrets, no
generated artifacts, no temp files, no unrequested refactorings.

## 4. Evidence rule

A claim may be called verified only if the corresponding check was
actually executed. Examples:

- `nix flake check` not runnable → `NIX EVAL: BLOCKED`, never PASS.
- "The code looks correct" is not a verification result — it is
  UNVERIFIED (or an opinion; report it as neither).

## 5. Report format

```
VERIFY

FORMAT        PASS/FAIL/BLOCKED/UNVERIFIED
NIXMETA       PASS/FAIL/BLOCKED/UNVERIFIED
DOCS          PASS/FAIL/BLOCKED/UNVERIFIED
STATIC        PASS/FAIL/BLOCKED/UNVERIFIED
NIX EVAL      PASS/FAIL/BLOCKED/UNVERIFIED
INVARIANTS    PASS/FAIL/BLOCKED/UNVERIFIED
GIT DIFF      PASS/FAIL/BLOCKED/UNVERIFIED

RESULT        PASS/FAIL/BLOCKED/UNVERIFIED

OPEN
- ...
```

An overall PASS is valid only when every required level was actually
verified. Any BLOCKED level forces at least BLOCKED (or UNVERIFIED) as
RESULT for that level's aspect.

## 6. Missing tools

If a check is missing: (1) determine whether it is actually required for
this change; (2) check whether an existing mediNix tool already covers
it; (3) if not runnable → BLOCKED/UNVERIFIED; (4) do not build a new tool
automatically. Tool extensions require a separate architecture decision.

## 7. No cargo cult

This skill must not demand — merely because other projects use them —
additional external tools, MCP servers, LSP servers, CI systems, test
frameworks or abstractions. Every addition needs a proven, concrete need
and its own decision.

## 8. Responsibility boundaries

```
discipline → HOW do we work?
nix        → WHAT applies for Nix/NixOS?
authoring  → HOW do we build mediNix-conform?
review     → IS a finding actually real?
debug      → WHY does something not work?
verify     → IS the change actually verified?
```

On any overlap, attribute the question to exactly one of these.
