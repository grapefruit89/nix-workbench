---
schema_version: "1.0"
id: medinix-review
name: medinix-review
metadata:
  title: mediNix Review
version: "1.0"
status: active
layer: agent
domain: review
summary: >
  Review diffs and audit reports: REAL/PHANTOM/UNRESOLVED triage, divergence vs invariant, hardening, portability, feature creep.

description: >
  How to review mediNix-core changes, diffs and audit reports: cross-validate every claim against the primary source (REAL, PHANTOM, UNRESOLVED), distinguish invariant violations from deliberate divergence from nixpkgs, enforce the hardening-profile contract, check portability and feature creep, and close with the objective scan suite. Use when reviewing a diff, an audit finding, or a whole module in mediNix-core.

purpose:
  - "Triage audit claims into REAL / PHANTOM / UNRESOLVED against primary sources."
  - "Distinguish mediNix invariant violations from deliberate divergence from nixpkgs."

when_to_use:
  - "Reviewing a diff, an audit finding, or a whole module in mediNix-core."
  - "Any claim about this repo that must be verified before it grounds changes."

when_not_to_use:
  - "Implementing fixes — the review produces verdicts, not rewrites."
  - "Authoring new modules — medinix-authoring's job."

inputs:
  - "The diff, module or audit report under review; the portability ban-list (Section 6)."

outputs:
  - "A FINDINGS / SCAN / VERDICT report with only evidence-based verdicts."

authority:
  local:
    - "AGENTS.md"
    - "mediNix architecture"
    - "Decimal System"
    - "NIXMETA"
    - "lib/hardening-profiles.nix"

  external:
    - "NixOS/nixpkgs"

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
  skills: [medinix-discipline]
  tools: [medinix-meta-check]
  files: [56-agents/shared/scripts/scan_inconsistencies.py, 56-agents/shared/scripts/scan_duplicates.py]

invariants:
  - "Only REAL findings may ground changes; UNRESOLVED is never closed by assumption."
  - "No fabricated scan results — every SCAN line must have been actually run."
  - "A retired upstream is a review signal, not an automatic removal order."

verification:
  required:
    - "medinix-meta check exits green (metadata/registry level)."
    - "Portability ban-list grep produces no hits in production .nix files."

  preferred:
    - "nix flake check on a Nix-equipped host."

change_policy:
  scope: surgical
  avoid:
    - "Unrequested abstraction."
    - "Unrelated refactoring."

  deletion_over_addition: true

output_contract: "FINDINGS / SCAN / VERDICT"

notes:
  []

---

# mediNix Review — Finding Real Problems

## Purpose

This skill defines how changes, diffs and audit findings are reviewed in
mediNix-core. It produces verdicts, not rewrites: findings first, smallest
fix second.

It does not replace objective verification (`medinix-verify` / flake checks)
or the working discipline (`medinix-discipline`).

## 1. Cross-validation triage

An audit or reviewer claim is a hypothesis, not a fact.

1. Locate the cited file and line.
2. Open the primary source.
3. Verify that the named option, attribute, path or identifier literally
   exists.
4. Classify: REAL, PHANTOM, or UNRESOLVED.
5. Only REAL findings may serve as a basis for changes.

A contradiction between the claim and the source is evidence to
investigate, not permission to guess. UNRESOLVED items must be resolved by
inspection or a human decision — never by technical assumption.

## 2. Upstream divergence is not a bug

`nixpkgs ≠ mediNix` is initially just a difference. It becomes a defect only
when a mediNix invariant is violated. The reviewer must distinguish:

- "mediNix violates its own invariant" — a REAL defect;
- "mediNix deliberately differs from nixpkgs" — a decision, not a fail.

Example: the nixpkgs prowlarr module uses `DynamicUser`; mediNix keeps its
service factory with a static user (UID 5360, GID 5000). That is a
deliberate difference — the factory is authoritative. Do not produce a
review fail merely for divergence from nixpkgs, and never add an override
just to converge with nixpkgs.

Shared-GID 5000 membership is a factory invariant, not a per-service
technical necessity — verify actual file-sharing needs before calling its
absence a problem.

## 3. Hardening rule

A nixpkgs module without (sufficient) hardening must not be accepted as
mediNix-compliant without inspection.

- nixpkgs hardening is reference/input, mediNix hardening profiles
  (`lib/hardening-profiles.nix`) are the contract.
- Compare: what does upstream do → what isolation does nixpkgs provide →
  what isolation does mediNix require?
- Do not blindly add "more hardening": every restriction must be compatible
  with the actual service behavior (e.g. .NET/Node JIT needs
  MemoryDenyWriteExecute=false; GPU transcode needs PrivateDevices=false).
- Document only justified deviations.

## 4. Assertions

- Assertion messages follow the format `[Tag] What. Why. Fix.` (example:
  `[595] SSH service is DISABLED...`) so failures are self-explanatory.
- After any change touching assertions, inspect the COMPLETE assertion
  block in the diff. An LLM refactor that silently drops an assertion is
  the highest-risk failure class in this repo.

## 5. Feature creep

- Net-options rule: every newly added `mkOption` must strike one option
  elsewhere (or justify why none can be struck).
- Before calling settled code done, review for overbuilt options,
  speculative configuration and helper layers — per `medinix-discipline`
  §2.

## 6. Portability scan

One consolidated ban-list (this is THE list — do not redefine it elsewhere):

```
q958 | jarvis | moritz | 192.168. | 10.8. | m7c5.de | privado | /opt/data | Tower | hermes
```

- Any hit in production `.nix` modules or agent-facing documentation is a
  finding.
- Ban-list entries inside reference documents that explain WHY they are
  banned are acceptable.
- Scan commands: `grep -rn` over `*.nix` with the list; the shared scripts
  under `56-agents/shared/scripts/` (scan_inconsistencies.py,
  scan_duplicates.py) run the metadata-level equivalents.
- Machine equivalent of the whole list: `56-agents/shared/scripts/repo-sanity.sh`
  (executes the ban-list with CIDR/example exemptions; do not redefine the list
  elsewhere).

## 7. Research is not done at "found a file"

A review may demand upstream research. Research is complete only when:

1. the source is found (package ≠ module ≠ upstream ≠ test — see
   `medinix-authoring` §4);
2. the statement is understood;
3. verified against the primary source;
4. checked against mediNix invariants;
5. the smallest solution is determined;
6. the reasoning is documented.

## 8. Never trust line numbers

Cited line positions drift the moment a file changes; another model once
swapped correct/incorrect option names (`vpn.dnsServers` vs a
non-existent `vpn.dns`) while both were "verified" from stale lines.
When cross-validating a claim, always reopen the file and verify the
CONTENT, not the line position.

## 9. Review result format

Report findings as:

```
FINDINGS:
  [REAL]     <file:line> — <what> — <why it violates an invariant>
  [PHANTOM]  <claim> — <why the primary source contradicts it>
  [UNRESOLVED] <claim> — <what human decision or evidence is missing>

SCAN: <checks actually run + results>
VERDICT: clean | findings | blocked
```

Never report a scan that was not run. Verdicts come from evidence, not
confidence.
