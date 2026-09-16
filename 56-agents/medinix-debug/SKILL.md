---
schema_version: "1.0"
id: medinix-debug
name: medinix-debug
metadata:
  title: mediNix Debug
version: "1.0"
status: active
layer: agent
domain: debug
summary: >
  Debug mediNix-core configuration defects systematically: root-cause first,
  Nix evaluation traps, systemd isolation pitfalls, lockout avoidance.
description: >
  How to debug mediNix-core modules and services without cargo-cult fixes:
  root-cause discipline, the recurring Nix evaluation and mkMerge traps,
  isolation-as-LIST semantics, legit JIT/GPU exceptions to systemd
  hardening, the anti-lockout deployment chain, dry-run-first and the
  diagnostic checklist. Use when a service misbehaves, an option does not
  take effect, a build breaks, or an evaluation fails.
purpose:
  - "Find the actual cause before changing anything."
  - "Recognize the recurring mediNix Nix/systemd traps without rediscovering them."
when_to_use:
  - "A service misbehaves, fails to start, or an option does not take effect."
  - "A build or eval error appears, or a hardening setting is suspected of breaking a service."
when_not_to_use:
  - "Reviewing a diff for defects — medinix-review's job."
  - "Authoring new modules — medinix-authoring's job."
inputs:
  - "The failing behavior or error, and the affected module/service."
outputs:
  - "Root-cause diagnosis plus smallest verified fix."
authority:
  local:
    - "AGENTS.md"
    - "mediNix architecture"
    - "Decimal System"
    - "NIXMETA"
    - "lib/hardening-profiles.nix"
    - "lib/service-factory.nix"
  external:
    - "NixOS/nixpkgs"
    - "Upstream documentation"
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
  skills: [medinix-nix, medinix-review, medinix-verify]
  tools: [medinix-meta-check]
  files: [lib/service-factory.nix, lib/hardening-profiles.nix]
invariants:
  - "Diagnose before fix: no change without a stated root cause."
  - "Test/verify before switch: dry-run-first, anti-lockout order."
  - "Hardening exceptions must be minimal and service-justified."
verification:
  required:
    - "medinix-meta check exits green after the fix."
    - "The fix states its root cause and the evidence that confirmed it."
  preferred:
    - "nix flake check / nixos-rebuild test on a Nix-equipped host."
change_policy:
  scope: surgical
  avoid:
    - "Unrequested abstraction."
    - "Unrelated refactoring."
  deletion_over_addition: true
output_contract: "PLAN / EXECUTE / VERIFY / RESULT / OPEN"
notes: []
---

# mediNix Debug — Root Cause, Not Symptom Whack-a-Mole

## Purpose

Fix the actual cause. Every debug session produces a diagnosis (what is
wrong and why), then the smallest fix that addresses the cause — nothing
else.

## 1. Method: diagnose before fix

1. Reproduce or observe the failure concretely (exact command, exact error).
2. Form a hypothesis about the cause.
3. Confirm the hypothesis against a primary source (code, eval, log).
4. State the root cause in one sentence.
5. Apply the smallest fix that addresses it.
6. Verify: re-run the failing check, then the objective gates.

If the hypothesis cannot be confirmed, stop and report UNRESOLVED — do not
"try things" on productive config.

## 2. Nix evaluation traps (mediNix gold)

### 2.1 mkMerge isolation trap: isolation-as-LIST is required

Inside `mkMerge`/service options, isolation options are LIST-typed
(`IPAddressDeny`, `RestrictNetworkInterfaces`, `InaccessiblePaths`,
`ReadWritePaths`). A merge that appends `["lo"]` to
`IPAddressDeny = ["any"]` is semantically contradictory — `any` plus an
allow-listed exception never resolves via lists. When debugging "network
does not work under hardening": (a) evaluate the ACTUAL merged value,
(b) compare the mkMerge fragments and which layer wins,
(c) verify against `lib/service-factory.nix` and the module,
(d) only then consider touching hardening code — never relax it as a
first reaction.

### 2.2 Isolation layers are different mechanisms

Two isolation dimensions must never be mixed in diagnosis:

- `IPAddressDeny` / IP-family options: address-space level (which
  addresses may be contacted).
- `RestrictNetworkInterfaces`: interface level (which interfaces the unit
  may use at all).

Before concluding "network hardening broke the service", determine which
isolation layer was actually configured: is the value replaced, appended,
or influenced by different merge semantics? "Option X does not work" is
not a diagnosis — inspect the actual data form (scalar vs list) first.

### 2.3 Shallow `//` replaces whole subtrees

`config // { networking = { ... }; }` discards the rest of `networking`.
Debug "option disappeared" cases by checking for a `//` merge that
replaced a nested set (see medinix-nix §2.9). Use `lib.recursiveUpdate`
or proper module values instead.

### 2.4 Bare `if` on `config.*` can cause infinite recursion

`config = if config.services.foo.enable then ...` re-reads the config it
is computing → recursion. The pattern is `lib.mkIf`. When debugging
evaluation hangs or "infinite recursion" errors, look for bare `if` or
direct `config.<option>` reads inside `config` definitions — but do NOT
flag every `if config.*` expression as a defect; only the actual
evaluation dependency matters.

### 2.7 `rec { }` as a debugging footgun

Not a blanket ban. When a `rec` block misbehaves: check why `rec` is used
at all, whether a self-reference exists, and whether `let` expresses the
dependency more clearly. Default: prefer `let ... in` when no genuinely
recursive attribute structure is needed.

### 2.5 New files invisible until git add

"File exists in the working directory, but Nix/flake behaves as if it did
not exist." Diagnostic ladder: file exists? → expected path? → captured
by the flake source tree? → `git status`? → only then interpret Nix
behavior. Flake evaluation reads the git tree — an untracked file is
invisible to it. Do not blame Nix or import paths first.

### 2.6 `with pkgs;` as a debugging/analysis footgun

File-scope `with pkgs;` makes package origin less explicit and attribute
resolution opaque to analysis. The mediNix default is `pkgs.foo`
qualified access; when debugging "where does this attribute come from",
check first whether a `with` scope is hiding the source.

## 3. systemd hardening vs service reality

Hardening restrictions must be compatible with the actual service behavior.
Known legitimate exceptions (each minimal, justified per-service — never a
blanket relaxation):

- **JIT runtimes (.NET, Node/V8)**: JIT writes code pages at runtime →
  `MemoryDenyWriteExecute = false` is required; JIT works fine under most
  other hardening. See the existing dotnet profile in
  `lib/hardening-profiles.nix`.
- **Hardware transcoding (VA-API/VDPAU on Jellyfin)**: check hardware need
  BEFORE touching sandboxing, in order: (1) does the service actually
  require hardware acceleration? (2) which device node is required
  (e.g. render node)? (3) which hardening rule blocks that access?
  (4) is the minimal exception (device allow-list, not blanket
  `PrivateDevices = false`) compatible with the rest? A common
  mis-diagnosis is blaming the transcode config when the device path is
  simply not exposed.
- **VPN-bound transfer services (sabnzbd)**: network confinement is
  deliberate (`RestrictNetworkInterfaces = [lo vpn-if]` via cgroup-BPF);
  if the service "cannot reach the internet", that may be the feature
  working as designed — check the interface binding before relaxing
  anything.

Do not add "more hardening" when debugging: add only restrictions
justified by evidence, and document justified deviations from profiles.

## 4. Anti-lockout order (deploy-related debugging)

For anything that can break SSH/network configuration, the order is fixed:

```
1. nix flake check (or the local eval gates)
2. nixos-rebuild dry-activate   — preview what will change
3. nixos-rebuild test           — activates without switching boot entry
4. verify SSH + service manually
5. only then: nixos-rebuild switch
```

Never switch directly over SSH. If access is lost: boot the previous
generation from the bootloader menu, or `nixos-rebuild switch --rollback`
if SSH still works.

## 5. Diagnostic checklist (after a rebuild breaks something)

```
[ ] git status — were all new files git-added?
[ ] nix flake check / medinix-meta check — did the objective gates pass?
[ ] journalctl -u <unit>.service — what does the service itself report?
[ ] Secrets reachable? (systemd-creds paths / credentials mechanisms)
[ ] Hardening lists conflicting (mkMerge fragments fighting)?
[ ] dry-activate output — what actually changed vs expectation?
[ ] stateVersion / registry values sane for this machine?
[ ] If locked out: boot previous generation.
```

## 6. Debugging principle — the fixed chain

```
SYMPTOM
  ↓
HYPOTHESE
  ↓
ISOLATION
  ↓
EVIDENCE
  ↓
ROOT CAUSE
  ↓
SMALLEST FIX
  ↓
VERIFY
```

Never: symptom → patch everything → hope.

## 7. Out of scope (host-ops domain — intentionally excluded)

This is root-cause debugging for mediNix modules, not general NixOS
administration. Do not become a host-admin skill; the following stay out
(classified host-ops / rejected in the gold-mining review):

- general host administration, disko, LUKS, impermanence
- garbage collection, `system.stateVersion`
- deployment systems generally (NixOps etc.)
- alternative secret systems (agenix), `mcp-nixos`
- Docker fallbacks, generic WebUI management

## 8. Source treatment

Gold-mining findings (e.g. from the nixos-management-skill research input)
may be cited as confirming/adding to a mediNix rule — citing never makes
them authority. Local mediNix architecture remains authoritative.

## 9. Output

Report in PLAN / EXECUTE / VERIFY / RESULT / OPEN; every RESULT states
root cause, evidence, fix, and the verification actually run. Report scans
and checks that were not run as UNVERIFIED — never as PASS.
