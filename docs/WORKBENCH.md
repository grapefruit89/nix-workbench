# mediNix Workbench — How Agents Work In This Repository

> Routing document. It says WHERE things live and HOW to work here — it does
> not duplicate any of them. Entry chain for every agent, human or machine:
>
> ```text
> AGENTS.md           → project/agent contract (rules, permissions, layers)
> docs/ROADMAP.md     → project state (done / next / blocked / decisions)
> docs/WORKBENCH.md   → this file: working model + capability map
> docs/repository.yaml → research registry (external sources, classifications)
> 56-agents/*/SKILL.md → concrete task skills (Agent Context Contract v1.0)
> lib/registry.nix     → decimal / port / UID/GID SSoT
> flake.nix            → objective technical gates
> ```

## Two layers (never mix them)

1. **mediNix architecture** — WHAT the system is: a systemd-native pure-media
   flake (modules, decimal framework, hardening, credentials).
2. **Workbench / agent architecture** — HOW agents work safely and
   reproducibly ON that system (skills, tools, permissions, handoff).

## Responsibility separation (one mechanism per concern)

| Concern | Mechanism |
|---|---|
| Thinking / working rules | Skill (`56-agents/*/SKILL.md`) |
| Deterministic operation | Custom tool (`.opencode/tools/`) |
| Syntax / format | Formatter (nixfmt, auto after edit) |
| Ongoing diagnostic feedback | LSP (optional, measured) |
| Objective technical truth | Nix evaluation / flake checks / NIXMETA |

The agent decides via Skill, acts via Tool, OpenCode corrects form via
Formatter and offers diagnostics via LSP — but only the repository
(Nix/flake/tests/guards) decides whether something is actually true.

## Custom tool principles (before building more)

A custom tool is a small deterministic capability of the workbench — not a
mini-agent, not a wrapper around every shell command.

1. Tools exist for a concrete, repeated, deterministic operation
   (existing: `medinix-meta-check`, `medinix-meta-docs`).
2. Never override built-in tool names (`bash`, `read`, `write`, ...) —
   additional capability, no hidden behavior change.
3. Keep the set small: no tool without a proven, repeated need
   (candidates like `medinix-verify`/`medinix-registry-check` wait for
   Phase 3+ and proof of need).

## SKILL frontmatter split (OpenCode discovery vs mediNix contract)

OpenCode natively recognizes ONLY: `name`, `description` (≤1024 chars),
`license`, `compatibility`, `metadata` (string map). Unknown fields are
ignored. `name` must be the lowercase directory slug (`medinix-review`),
regex `^[a-z0-9]+(-[a-z0-9]+)*$`. Therefore:

- **OpenCode discovery layer**: `name` (slug), `description`,
  `metadata.title` (display name) — must stay OpenCode-conformant at all
  times.
- **mediNix Agent Context Contract layer**: everything else
  (schema_version, id, status, layer, domain, purpose, when_to_use,
  authority, research, invariants, verification, change_policy,
  output_contract) — for agents reading the skill, not for OpenCode's
  skill loader.

Verified 2026-09-16: all target skills conformant (slug name, dir match,
description ≤1024, display title in metadata).

A skill or tool may never redefine layer 1; layer 1 rules win.

## mediNix Default Decision Rule

When several technically valid solutions exist, prefer the one with the
lowest architecture weight, in this order:

1. Nix/NixOS-native
2. existing mediNix infrastructure (registry, factory, hardening, creds)
3. simplest solution
4. fewest dependencies
5. lowest resource and maintenance cost
6. most objectively verifiable
7. smallest necessary change

New abstraction only when it demonstrably solves a concrete problem better
than the existing solution. This is a direction, not a checklist for every
micro-decision.

## OpenCode capability audit (2026-09-16, against opencode.ai/docs)

| Capability | OpenCode native | mediNix already has | Verdict |
|---|---|---|---|
| Skills | `SKILL.md`, native `skill` tool, name must match dir name, only `name`/`description`/`license`/`compatibility`/`metadata` frontmatter recognized; unknown fields ignored | 6 target skills in `56-agents/` via `skills.paths`, Agent Context Contract v1.0 | **ADOPT** (native discovery) + our richer frontmatter stays for agents reading the file — no conflict |
| Skill permissions | `permission.skill` patterns, per-agent overrides | gated 2026-09-16 (Phase 2i): exactly the 6 canonical skills `allow`, `*` `deny` in `opencode.jsonc` | **ADOPTED** — native pattern syntax; no custom gating |
| References | path/repository references with description, auto-exposed to agent context, read-only | `medinix` reference to `../mediNix-core` | **ADOPT** (already wired; add more only with reason) |
| Custom tools | `.opencode/tools/*.ts`, `tool()`, `context.worktree` | `medinix-meta-check` (read-only), `medinix-meta-docs` (docs: ask) | **ADOPT** (built exactly this way) |
| Permissions | read/edit/bash/skill patterns, per-agent | permission model in `opencode.jsonc`, destructive meta-modes not exposed | **ADOPT** |
| Agents | primary build/plan; subagents general/explore/**scout** (read-only upstream-doc research) | none custom | **ADOPT** — use built-in `@scout` for upstream/dependency research (fits "extract patterns, not files"); no custom agent files |
| Formatters | native nixfmt integration | nixfmt single formatter, others disabled | **ADOPT** (no overlap) |
| LSP | native LSP incl. **nixd for .nix**; docs themselves warn about memory cost, version drift, slower workflows | config note warns against over-trusting nixd | **INVESTIGATE** — nixd is native but stays off until measured on a Nix host. Decision chain: nixfmt → NIXMETA → static checks → nix eval/flake checks → optional nixd diagnostics. LSP is extra feedback, never authority |
| MCP | per-server enable/disable | 7 inherited servers disabled | **ADOPT** (stays off unless a task truly needs one) |
| Rules | `AGENTS.md`-style global rules | root `AGENTS.md` is our contract | **OVERLAP** — our AGENTS.md is richer; no second rules file |
| Commands | custom slash-commands | none | **DEFER** — possible `/review`/`/verify` shortcuts after Phase 2h |
| Plugins/hooks | event hooks (plugin system) | none | **DEFER** — candidate for Phase 3 automated invariant guards; do not build ahead of proven need |
| Snapshots | session context management | — | **DEFER** |

## Multi-agent handoff (any agent, any tool)

An incoming agent (OpenCode, Codex, Claude Code, ...) MUST, in order:

1. Read `AGENTS.md` — the contract (Go-gate, no invented options, portability).
2. Read `docs/ROADMAP.md` — know where the project stands before acting.
3. Read `docs/WORKBENCH.md` (this file) — working model and decision rule.
4. Load the relevant target skill(s) from `56-agents/`.
5. Check `docs/repository.yaml` for every external source before using it.

Hard rules for every agent:

- The workbench branch (`agent-workbench`) is where edits happen; the
  canonical `mediNix-core` main is read-only context (reference `medinix`).
- `repository.yaml` routes research — it is NOT a knowledge base to read
  wholesale.
- Objective verification (flake checks, NIXMETA, docs) never comes from
  agent confidence; run it or report BLOCKED/UNVERIFIED.
- No change without the project owner's explicit Go.


---

# Drift-Threat-Map (Phase 3.1, 2026-09-16)

Wer verursacht Drift: (A) fremder Agent ohne Chat-Historie, (B) sorgloser Agent,
(C) absichtlich "schlechter" Agent, (D) Tooling/Updates, (E) Owner-Handarbeit.
Jede Zeile = eine konkrete Drift-Möglichkeit, ihre Erkennbarkeit und der
Phase-3-Aufgabencode, der sie adressiert. **Keine Guards gebaut — nur kartiert.**

## Threat-Map

| ID | Threat-Klasse | Konkreter Drift | Erkennung | Heute abgedeckt? | Task |
|---|---|---|---|---|---|
| T01 | Skill-Landschaft | Siebter Skill angelegt (`56-agents/<neu>/SKILL.md`) oder Skill-Sammlung/Helfer | Verzeichnisliste vs. Soll-6; Discovery-Scan | nein | 3.8 |
| T02 | Skill-Landschaft | Legacy-Skill wiedereingeführt (anderer Name, alter Inhalt) | Namen-Historie + Inhalts-Signatur (Footgun-Strings, alte Formularfelder) | nein | 3.8 |
| T03 | Skill-Contract | Frontmatter-Felder entfernt/umbenannt, `name` ≠ Verzeichnis, description > 1024 | Formular-v1.0-Feldvergleich pro Skill (maschinell) | teilweise (metamanuell) | 3.10 |
| T04 | Skill-Content | Regeln in falschem Zielskill (z. B. Review-Regel nach discipline), Gold doppelt | Verantwortungs-Matrix-Audit (manuell) | nein | 3.8/3.13 |
| T05 | Permission | `permission.skill` Pattern erweitert/geleert oder umgangen (anderer Pfad via `skills.paths`) | opencode.jsonc-Diff-Review (manuell/ maschinell parsebar) | nein | 3.8 |
| T06 | Decimal/Registry | Port/UID/GID geändert oder dupliziert, ohne Registry-Änderung | registry.nix als SSoT gegen 53-acquisition diffen; scan_inconsistencies.py/scan_duplicates.py | teilweise (Skripte vorhanden, nicht gegated) | 3.9 |
| T07 | Decimal/Registry | Neue Datei ohne `NNN-` Präfix (inert) oder Nummer außerhalb 500–599 | Dateinamen-Scan (maschinell trivial) | nein | 3.9 |
| T08 | Decimal/Registry | Slot-Nummer vergeben, die RETIRED reserviert ist (z. B. 534) | Registry-Eintrag-Status-Scan | nein | 3.9 |
| T09 | NIXMETA | Header entfernt/geändert, `status:` ohne verifizierte Basis gesetzt | medinix-meta-check (vorhanden, exit 0 heute) | ja, aber ungegated | 3.10 |
| T10 | NIXMETA | Statusfälschung: DONE/PASS ohne Evidence (Fake-PASS in Header/Doku) | Evidence-Rule-Prüfung; VERIFY-Report-Abgleich (manuell) | nein | 3.4/3.5 |
| T11 | Architektur | Factory umgangen: direkter systemd-Config-Code statt service-factory | Muster-Scan nach `systemd.services.` außerhalb Factory/5xx-Modul | nein | 3.4 |
| T12 | Architektur | Neue Root-Ordner/Abstraktion (helpers/, neues MCP, neues Custom Tool, neue checks) | opencode.jsonc + flake.nix + Repo-Baum Diff (Soll-Struktur) | nein | 3.7 |
| T13 | Credentials/Host | Host-IP/Hostname/Domain in `.nix` Defaults oder Code (q958, 192.168.x, m7c5.de, privado) | Portability-Banlist-Scan (muster in review §6, Skript assert_no_ips.sh vorhanden) | teilweise (Skript, ungegated) | 3.11 |
| T14 | Credentials | Secret über `types.path` in Store, Secret im Repo/Chat | Options-Typ-Scan + Repo-Grep (maschinell) | nein | 3.11 |
| T15 | Git-Scope | Diff enthält Dateien außerhalb des erklärten Scopes (flake.nix, lib/, andere Slots) | `git diff --stat` vs. deklariertem Scope im PLAN (manuell, VERIFY §7) | manuell abgedeckt | 3.7 |
| T16 | Git-Scope | Ungetrackte/junk-Dateien committet, .bak/.old/.legacy | `git status --porcelain` + Namensmuster-Scan | nein | 3.7 |
| T17 | Docs | ROADMAP-Status gefälscht (DONE ohne Anmerkung/Evidence), SSOT-Widerspruch zu WORKBENCH/AGENTS | Cross-Doc-Konsistenz-Check (manuell) | nein | 3.4/3.5 |
| T18 | Research | Erfundene Context7-ID/Upstream-URL, repository.yaml als Wissensdump missbraucht | ID-Verifikationspflicht (Discipline §5/Review §7; maschinell nicht trivial) | regel-abgedeckt | 3.5 |
| T19 | Environment | Nix-Evaluation vorgetäuscht (PASS ohne nix-Binary, BLOCKED als PASS gemeldet) | `command -v nix`-Check in VERIFY-Kette (maschinell trivial) | regel-abgedeckt | 3.4 |
| T20 | Tooling | Formatter ausgetauscht/deaktiviert, Checks entfernt, MCP-Wiederaktivierung | opencode.jsonc/flake.nix-Diff-Review | nein | 3.7 |
| T21 | Unverstanden | Agent folgt fremdem Mentalmodel (ChatGPT-Struktur, SaaS-Tooling, kanban) anstelle der Workbench | Orientierungstest Phase 4.1 (manuell) | nein | 4.x |

## Ablesung (wichtig für 3.2–3.5)

- **Bereits abgedeckt** (nur gegaten werden muss): T09 (medinix-meta-check), T15 (VERIFY §7),
  T13/T06 teilweise (Skripte existieren in `56-agents/shared/scripts/`).
- **Trivial maschinell** (kleinste Guards-Kandidaten): T01/T07 (Baum-Scan), T14/T19 (Grep /
  command -v), T16 (git status).
- **Nicht sinnvoll maschinell** (→ Agent Contract statt Guard): T10, T17, T18, T21 (Evidence,
  Ehrlichkeit, Mentalmodel = Verhaltensregeln).
- **Regel folgt dem Guard-Grundsatz**: kleinste Zahl von Guards, die die Threats mit
  realem Risiko schließen — nicht jede Zeile wird ein Guard.

## Enforcement layers (verified 2026-09-16)

- Permission layer = hard outer boundary (ask/deny; non-interactive requests are auto-rejected)
- Agent contract / skills = behavior within the boundary
- repo-sanity = objective drift/diff check (Git is the sole change truth)
- medinix-verify = domain verification (evidence rule; BLOCKED is never PASS)
- Git = the record of what actually changed

### WCR-001 (2026-09-16, Baseline 1.0 → 1.1)

- WHY: Freeze-Boundary deckte 4 Workbench-Pfade nicht ab (PROTECTED-Liste).
- WHAT: repo-sanity.sh PROTECTED erweitert um ^AGENTS.md$ / ^AUDIT-BRIEF.md$ /
  ^docs/WORKBENCH.md$ / ^\.opencode/ (1 Zeile; Domain-AGENTS.md bleibt
  generator-synced und ist bewusst NICHT protected).
- IMPACT: Freeze-Gate deckt Boundary vollständig.
- BASELINE: 4853772 (1.0)
- VERIFICATION: git diff --check / medinix-meta check / check-docs / repo-sanity
- NEW BASELINE: siehe Commit (1.1)
