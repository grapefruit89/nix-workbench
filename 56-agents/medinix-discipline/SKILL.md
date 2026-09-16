---
schema_version: "1.0"
id: medinix-discipline
name: medinix-discipline
metadata:
  title: mediNix Discipline
version: "1.0"
status: active
layer: agent
domain: workflow
summary: >
  Think before coding, edit surgically, verify against primary sources, stop on unresolved uncertainty.

description: >
  Working discipline for mediNix-core changes. Think before coding, simplify before abstracting, make surgical edits, verify against primary sources, cross-validate audit findings, and stop on unresolved uncertainty. Use for every non-trivial change to mediNix-core.

purpose:
  - "Enforce deliberate, minimal, reversible change execution."
  - "Define the PLAN / EXECUTE / VERIFY / RESULT / OPEN working loop."

when_to_use:
  - "Every non-trivial change to mediNix-core files."
  - "Before executing: when the plan for a change must be stated and frozen."

when_not_to_use:
  - "Pure informational questions answerable by reading one file."
  - "Running objective verification — that is medinix-verify's job."

inputs:
  - "The task description and the affected files/invariants."

outputs:
  - "A change report in PLAN / EXECUTE / VERIFY / RESULT / OPEN format."

authority:
  local:
    - "AGENTS.md"
    - "mediNix architecture"
    - "Decimal System"
    - "NIXMETA"

  external: []

  rule: >
    Local mediNix architecture and explicit project invariants take precedence over external patterns.

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
  skills: [medinix-review, medinix-verify]
  tools: [medinix-meta-check]
  files: [AGENTS.md]

invariants:
  - "No change without explicit human Go."
  - "No invented options or abstraction layers."
  - "Stop on unresolved uncertainty — never resolve by assumption."

verification:
  required:
    - "Assertions follow [Tag/What/Why/Fix] format and survive edits."
    - "medinix-meta check exits green after the change."

  preferred: []

change_policy:
  scope: surgical
  avoid:
    - "Unrequested abstraction."
    - "Unrelated refactoring."

  deletion_over_addition: true

output_contract: "PLAN / EXECUTE / VERIFY / RESULT / OPEN"

notes:
  []

---

# mediNix Discipline

## Purpose

This skill governs working behavior and decision-making for every non-trivial
change to mediNix-core.

It does not replace Nix evaluation, repository checks, or source inspection.
It is a working instruction, not a security mechanism — enforcement comes from
permissions, tools, and flake checks.

## 1. Think before coding

Before editing:

1. State the requested outcome.
2. Identify the exact files and source-of-truth involved.
3. Separate facts, assumptions, and open questions.
4. Check whether the requested behavior already exists.
5. Define the smallest acceptable success condition.

If a required fact is unknown, do not invent it.
Inspect the repository, the primary implementation, or the relevant official
documentation. If uncertainty remains material, stop and ask.

## 2. Simplify before adding

Use this order:

1. Delete unnecessary behavior.
2. Reuse an existing implementation.
3. Use the existing Nix/NixOS mechanism.
4. Change the smallest existing unit.
5. Add a new abstraction only when the simpler options fail.

Do not add speculative configuration, helper layers, wrappers, registries,
scripts, dependencies, or generated artifacts.

A smaller solution is preferred only if it preserves:

- security;
- validation;
- portability;
- explicit user requirements;
- required operational behavior.

## 3. Surgical changes

Every changed line must have a reason traceable to the task.

Rules:

- touch the fewest files possible;
- do not perform unrelated cleanup;
- do not rename for style alone;
- do not reformat neighboring code unnecessarily;
- remove only orphans created by the current change;
- preserve existing conventions unless they are part of the defect;
- do not rewrite working code merely because another style looks nicer.

If adjacent drift is discovered, record it separately instead of silently
expanding the scope.

## 4. Root cause, not symptom

For a bug:

1. reproduce or locate the failure;
2. inspect the primary source;
3. identify the root cause;
4. fix the root cause;
5. verify that the original failure is gone;
6. check that no invariant was weakened.

Do not add a workaround before understanding the failure.

## 5. Source-of-truth precedence

Respect this precedence:

1. actual implementation and evaluated configuration;
2. repository registries and module metadata;
3. generated documentation (outputs — modify their source, regenerate, verify);
4. architecture and policy documents;
5. skills and notes;
6. model assumptions.

Never create a second handwritten source of truth for ports, UIDs, GIDs,
services, hardening, credentials, or module identity.

## 6. Audit evidence must be cross-validated

An audit finding is not accepted merely because an agent reports it.

For every finding:

1. locate the cited file and line;
2. inspect the primary source;
3. verify that the named option, attribute, path, or identifier exists;
4. classify it as REAL, PHANTOM, or UNRESOLVED;
5. fix only REAL findings.

A contradiction between an audit and the source is evidence to investigate,
not permission to guess.

## 7. Security and credentials

Never decrypt, print, inspect, expose, or commit plaintext credentials.

Do not place secrets in:

- Nix store paths;
- command-line arguments;
- ordinary environment variables;
- logs;
- generated documentation;
- chat output;
- test fixtures.

Modify only the configuration that references the approved credential
mechanism. If the actual secret value is required, stop and request it through
the approved human-controlled process.

## 8. Completion means verified

Before declaring success:

1. inspect the final diff;
2. run the narrowest relevant check;
3. run formatting and static checks available in the environment;
4. run metadata and documentation checks when relevant;
5. run Nix evaluation or flake checks on a real Nix host when required;
6. report checks that were not run and why.

Never replace an unavailable verification step with confidence.

## 9. Discipline gold (legacy migration 2026-09-16)

- **Grounding rule**: before editing any file, quote a real line from
  that file in the response. If you cannot quote a line, you have not
  read the file — no edits from assumed file structure.
- **Event-driven > calendar**: prefer `systemd.path` (PathChanged /
  DirectoryNotEmpty) with a brake in the script (e.g. a `minFreeGb` check
  that exits 0 when there is no pressure) over fixed-interval
  `OnCalendar` wakes. Never introduce cron or iptables as mechanisms
  (systemd timers and nftables only).
- **ADMIN-HANDOFF is the single host-duties file**: mediNix-core is a
  portable flake/module; host responsibilities live exclusively in the
  handoff document at repo root. No scattered host hints in AGENTS.md,
  README or module comments — and `mkOption default =` never hardcodes
  a host value (generic example values only).

## 10. Output contract

For non-trivial work, report exactly one format:

- PLAN: intended minimal change;
- EXECUTE: files actually changed;
- VERIFY: checks actually run;
- RESULT: pass, fail, or blocked;
- OPEN: unresolved uncertainty or deferred scope.

Keep it short and checkable. Do not invent a second format.
