# mediNix-core — Agent Contract

## Identity

Portable NixOS module set for a systemd-native media stack.

- No Docker. No containers. systemd only.
- No host-specific defaults. Fail closed.
- Prefer native NixOS/systemd mechanisms over new abstractions.
- Decimal framework: module number × 10 = port, UID = port, GID = 5000. Defined in `lib/registry.nix` — never hardcode derived values.

## Source of Truth

Priority when sources disagree:

1. Evaluated NixOS configuration / actual code
2. `lib/registry.nix` for registry-derived values
3. `50-core/MANIFEST.md` for architectural law
4. `docs/adr/` for rationale and decisions
5. `docs/INDEX.md` / `docs/adr/llm-index.json` for navigation
6. Generated per-folder `AGENTS.md` for local navigation
7. Skills for workflow guidance

Never treat chat history as SSoT. Historical notes are not authority unless referenced by an ADR.

## Routing Contract

Before a non-trivial task:

1. Read this file.
2. Read `docs/INDEX.md`.
3. Read `docs/adr/llm-index.json` when the task involves architecture or rationale.
4. For module structure/ownership, run `python3 50-core/medinix-meta.py check`.
5. For rationale, search `docs/adr/`.
6. When entering a numbered domain, read its local `AGENTS.md`.
7. Load only the skill relevant to the current task.
8. For upstream questions (where to look for Nix/NixOS/service truth), consult `docs/repository.yaml`.

Do not preload the entire repository.

## References

The `../mediNix-core` reference (see opencode.jsonc) is read-only reference material. All edits MUST target the current worktree. Never modify files through the medinix reference.

## Generated Files

Folder-level `AGENTS.md` files are generated.

- Do not manually edit content below the AUTO-GENERATED marker.
- Change NIXMETA headers or the generator instead, then run:
  `python3 50-core/medinix-meta.py generate-docs`
- Verify staleness with:
  `python3 50-core/medinix-meta.py check-docs`

## Editing Discipline

- No bulk or regex-based source edits. Exact, surgical edits only.
- Do not rewrite unrelated files.
- After changing assertions, explicitly inspect the complete assertion block in the diff.

## Credentials — HARD RULE

mediNix uses systemd-creds sealed credential blobs (`lib/creds.nix`).

Agents MUST NOT:

- decrypt credentials;
- print credential contents;
- inspect plaintext credential material;
- commit plaintext credentials;
- copy credentials into `/nix/store`;
- place credentials in command-line arguments or ordinary environment variables;
- modify sealed blob contents.

Agents MAY only modify the Nix option/path that references a credential, and only when the task explicitly requires it. If a credential value is required to continue, stop and ask the user.

## Invariants

Never silently remove or weaken:

- `config.assertions` / fail-closed behavior
- service hardening profiles
- network confinement
- credential handling
- registry-derived ports/UIDs/GIDs
- the no-container policy
- host portability

If a refactor would change an invariant, stop and report it.

## Default Decision Rule

When several technically valid solutions exist, prefer the one with the
lowest architecture weight: Nix/NixOS-native, existing mediNix
infrastructure, simplest, fewest dependencies, lowest resource and
maintenance cost, most objectively verifiable, smallest necessary change.
New abstraction only when it demonstrably solves a concrete problem better
than the existing solution. (Full working model: docs/WORKBENCH.md.)

## Verification

Before declaring a code change complete:

1. `git diff` (inspect the full change)
2. formatter check (nixfmt)
3. metadata/doc check (`medinix-meta.py check` + `check-docs`)
4. relevant static checks (statix, deadnix)
5. `nix flake check`

Do not claim success for checks that were not actually executed.
