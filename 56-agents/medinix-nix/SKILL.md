---
schema_version: "1.0"
id: medinix-nix
name: medinix-nix
metadata:
  title: mediNix Nix
version: "1.0"
status: active
layer: agent
domain: nix
summary: >
  Resolve Nix and NixOS questions from the cheapest authoritative source, recording recurring mediNix footguns.

description: >
  How to resolve Nix and NixOS questions in mediNix-core without hallucinating: start with the cheapest authoritative source — repo code, then nixpkgs/NixOS source, then nix repl or nix eval, then official documentation — and escalate only while uncertainty remains. Also records the recurring mediNix Nix footguns (flake scope, secret paths, systemd unit names, eval gates, decimal enforcer). Use when unsure about a Nix option, attribute, or pattern.

purpose:
  - "Establish the source-ladder for Nix questions: repo code > nixpkgs/NixOS source > nix repl/eval > official docs."
  - "Record and enforce mediNix Nix footgun rules."

when_to_use:
  - "Uncertainty about a Nix option, attribute or pattern."
  - "Before touching flake scope, unit names, secret paths or eval gates."

when_not_to_use:
  - "Routine formatting or packaging questions already settled by nixfmt and existing code."

inputs:
  - "The concrete Nix question and its context (file, module, intent)."

outputs:
  - "A verified answer with its source named."

authority:
  local:
    - "AGENTS.md"
    - "mediNix architecture"
    - "Decimal System"
    - "NIXMETA"

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
    repos: ["https://zero-to-nix.com/"]
  context7:
    enabled: false
    library_id: null

related:
  skills: [medinix-authoring, medinix-review]
  tools: [medinix-meta-check]
  files: [flake.nix, lib/registry.nix]

invariants:
  - "Never bypass the Ratsche eval gates (medinix-meta check) to ship unverified Nix."
  - "Credential options are types.str carrying a sealed-blob host path; the secret value never enters the store."
  - "Unit names and Decimal-derived numbers come from the registry, never invented."

verification:
  required:
    - "Answer names its primary source (file/URL)."
    - "Reproducible snippet verified against the local code or nixpkgs source."

  preferred:
    - "nix repl / nix eval check on a Nix-equipped host."

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

# mediNix Nix — Resolving Nix Knowledge Correctly

## Purpose

This skill explains how to obtain authoritative answers about Nix, NixOS and
nixpkgs in the mediNix-core context, and records the repository's recurring
Nix footguns.

It does not document Nix itself. It does not replace the flake checks, the
registry, or the sibling skills (`medinix-authoring` for repo structure,
`medinix-verify` for objective proof).

## 1. Verification ladder

The ladder is not a rigid mandatory sequence. Start with the cheapest
authoritative source that can answer the question; escalate only while
uncertainty remains.

1. **Repository / actual code** — the evaluated configuration and the
   repository `lib/` implementations are authoritative for this repo's
   behavior. If the local code answers the question, stop here.
2. **nixpkgs / NixOS source** — module definitions, option types, defaults.
3. **nix repl / nix eval** — evaluate expressions and probe whether an
   option, attribute, or value actually exists on the evaluated system.
4. **Official documentation** — nix.dev, NixOS manual, nixpkgs manual.

Rule: an unknown option, attribute, or flag is never written from memory.
Resolve it with the ladder, then implement. If uncertainty remains after
the ladder, stop and ask.

## 2. Recurring footguns (mediNix gold)

### 2.1 Flake scope: `inherit (x) y` expands to `y = x.y`

Classic scope bug: `inherit (nixpkgs.lib) lib` yields
`lib = nixpkgs.lib.lib` — wrong. The correct form is `inherit (nixpkgs) lib`
(equivalently `lib = nixpkgs.lib`). Always check what the source of the
`inherit` actually is.

### 2.2 `types.path` materializes credential files into the Nix store

Store contents are world-readable. For credential paths use `types.str` —
never `types.path` for secrets.

### 2.3 Service-factory systemd unit names are plain

Factory-generated unit names are plain (`sonarr.service`); the port lives
only in `StateDirectory` and socket bindings. When a reviewer claims the
unit name contains the port, verify against the primary source
(`lib/service-factory.nix`) — this mis-diagnosis is the most repeated false
finding in this repo's history.

### 2.4 Ratsche eval-gate pattern

A stubbed `nixosConfigurations.check` (grub disabled, tmpfs root) whose
toplevel evaluation is wired into `checks` makes a single typo in any module
fail `nix flake check`. Do not weaken or remove the stub. Read the actual
pattern in `flake.nix` — do not restate or reimplement it here.

### 2.5 Decimal enforcer is Nix-native

Enforcement of the module-number naming uses Nix-native `readDir` + `match`,
not bash grep (grep misses 3-digit files). Never replace it with a bash
implementation.

### 2.6 Formatting

This repo standardizes on `nixfmt-rfc-style`, enforced by the flake checks.
One formatter per language — do not introduce a second one.

### 2.7 `with pkgs;` at file scope blocks static analysis

`with` pollutes the scope and hides where attributes come from, so
attribute lookups cannot be traced by code reading or tooling. Write
`pkgs.`-qualified names (or a local `let` alias) instead.

### 2.8 `rec { ... }` risks infinite recursion

`rec` bindings that accidentally reference each other produce
hard-to-debug recursion. Prefer `let ... in` where dependencies are
explicit and one-directional.

### 2.9 `//` is a shallow merge and replaces whole subtrees

`config // { networking = { ... }; }` replaces ALL of `networking`, not
just the intended key. For nested updates use `lib.recursiveUpdate` (or
compose `mkMerge`/module values). Verify merge depth before using `//` on
anything with nesting.

### 2.10 New flake files are invisible until `git add`

Flake evaluation reads the git tree: a newly created `.nix` file not
staged with `git add` produces "file not found" errors even though it
exists on disk. When a build cannot find a file that exists, check
`git status` first.

### 2.11 `eachDefaultSystem` double-nesting

Inside `perSystem`/`eachDefaultSystem` the iterator is already `system`:
never write `formatter.${system}` or `devShells.${system}.default` there
(produces `formatter.x86_64-linux.x86_64-linux`, invalid). Write
`formatter = ...` / `devShells.default = ...` directly.

### 2.12 `writeShellApplication` for ShellCheck-at-build

Bash inside a `.nix` module goes through `pkgs.writeShellApplication`
(never inline `script = '''...'''`): ShellCheck and `set -euo pipefail`
run at build time, `runtimeInputs` names every binary the script calls.

### 2.13 `network-online.target` in `after`/`requires` adds boot delay

It serializes units behind network readiness (10–15s on such hosts).
Only use it when the service genuinely needs external network at start;
elsewhere rely on socket activation / path units.

### 2.14 `StartLimit*` caps starts, `RateLimit*` throttles logs

`RateLimitBurst`/`RateLimitIntervalSec` (serviceConfig) throttle LOG
output, not service starts. To cap how often a unit STARTS (e.g. a path
unit hammering a chatty dir), use `StartLimitBurst` +
`StartLimitIntervalSec` on the unit.

### 2.15 `find` operator precedence: `-o` separates, not ANDs

`find DIR -type f -size +50M -o -name '*.mkv'` matches ALL `*.mkv`
regardless of size. Group whitelists: `find DIR -type f -size +50M
\( -name '*.mkv' -o -name '*.mp4' \)`.

*(Footguns 2.1–2.6 from the 2026-08 migration era; 2.7–2.10 adopted
from the nixos-management-skill research input, reviewed 2026-09-16;
2.11–2.15 extracted from the legacy nix-idioms / feature-creep-audit /
flake-ci skills during the 2026-09-16 legacy migration.)*
nixos-management-skill research input (docs/repository.yaml →
research_inputs), reviewed 2026-09-16 and reformulated mediNix-native.)*

## 3. Where the domain detail lives

Concrete repo structure (module numbers, service map, NIXMETA headers,
hardening profiles) is `medinix-authoring` territory. Objective proof gates
are `medinix-verify` and the flake. Do not duplicate either here.
