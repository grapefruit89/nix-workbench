# ARCHITECT ROADMAP — Agent Workbench State (SSOT)

> **Dies ist die Single Source of Truth für den Projektfortschritt** — nicht der Chat,
> nicht das Agentengedächtnis. Einstieg für jeden (Sub-)Agenten: `AGENTS.md → ROADMAP.md`.
> Zuletzt aktualisiert: 2026-09-16 · Branch: `agent-workbench` · Basis: main @ 89f7c44
>
> Statuslegenden: `DONE` · `IN_PROGRESS` · `NEXT` · `OPEN` · `BLOCKED` · `DEFERRED` · `DECISION`.
> Abkürzung bei Verifikation: `UNVERIFIED` = nicht ausgeführt auf diesem Host — niemals als PASS darstellen.

## Projektzustand — Arbeits-Roadmap (echte Arbeitsliste, keine Wunschliste)

```text
PHASE 0  Workbench Foundation          DONE
PHASE 1  Repository / NIXMETA          DONE
PHASE 2  Agent Architecture            DONE
         └── 26 → 6 Skills             DONE

PHASE 3  Agent Drift Prevention        NEXT
PHASE 4  Controlled Agent Workflow     DONE (4.1–4.8)
PHASE 5  Final Cleanup / Hardening     IN_PROGRESS (5.1 Inventur DONE; Batch B1 = GO-Antrag)

WORKING MODEL (Owner, 2026-09-16 — für alle Code-/Cleanup-Batches):
  RESEARCH → AUDIT (Findings: REAL/PHANTOM/UNRESOLVED, keine Auto-Edits)
  → OWNER GO (je Finding) → kleiner Change-Batch (Change-Budget/Scope)
  → VERIFY (git diff + repo-sanity + NIXMETA + nix-eval ehrlich) → nächster Batch.
  Risikostaffelung: GRÜN zuerst (docs/, 50-core, Einzelmodule) → GELB (5x-Service-
  Module, Workbench) → ROT (lib/registry, service-factory, hardening, creds,
  flake.nix = nur mit belegtem REAL-Befund).
  UMGBUNG-SPLIT: Nobara = Entwicklungs-/Agentenarbeitsplatz (alles außer Nix-
  Ausführung); NixOS = autoritative Nix-Verifikation (nixfmt/statix/deadnix/
  flake check). Nix-Gates bleiben bis dahin BLOCKED/UNVERIFIED.
PHASE 6  Final Acceptance Audit        OPEN

ENVIRONMENT
Nix evaluation                         BLOCKED (kein nix-Binary auf diesem Host)
```

### Phase 0–2 (abgeschlossen — Details im Decision Log)

Phase 0: Worktree, opencode.jsonc, Permissions, Skill-Discovery, root AGENTS.md.
Phase 1: NIXMETA-Cleanup, Custom Tools (medinix-meta-check/docs), destruktives NICHT exponiert.
Phase 2: 6 kanonische Skills (Formular v1.0), Research Registry, Software-Triangulation 15/15,
Frontmatter-Standardisierung, Capability Audit, Gold-Mining (nixos-management-skill),
medinix-debug/verify, Legacy-Migration 25 Skills entfernt (EXTRACT 9 / DUPLICATE 8 / REJECT 8).

### Phase 3 — Agent Drift Prevention (NEXT)

Ziel: Ein fremder Agent kann am Repository arbeiten, ohne unbemerkt die Architektur zu verändern.

| # | Aufgabe | Status |
|---|---|---|
| 3.1 | Drift-Threat-Map erstellen | DONE |
| 3.2 | Bestehende Invarianten inventarisieren | OPEN |
| 3.3 | Bereits vorhandene Prüfungen gegenprüfen | DONE |
| 3.4 | Maschinell erkennbare Drift definieren | DONE |
| 3.5 | Nicht-maschinelle Regeln dem Agent Contract zuordnen | DONE |
| 3.6 | Minimal notwendige Drift-Guards bauen | DONE | 2026-09-16: INV-24 RESOLVED (types.str ist Implementierung, Wording korrigiert); genau ein Guard 56-agents/shared/scripts/repo-sanity.sh (Struktur/Banlist/bestehende Scans/Git-Budget/Protected); scan_duplicates worktree-sicher repariert; echte Banlist-Befunde gefixt (m7c5.de in example, q958 in arr-provision); Integration in medinix-verify §3.7 + review §6 |
| 3.7 | Git-Diff-/Scope-Guard festlegen | OPEN |
| 3.8 | Legacy-/Skill-Drift verhindern | OPEN |
| 3.9 | Decimal-/Registry-Drift absichern | OPEN |
| 3.10 | NIXMETA-/Contract-Drift absichern | OPEN |
| 3.11 | Credential-/Host-Drift prüfen | OPEN |
| 3.12 | Guards gegen einen absichtlich "schlechten" Agenten testen | OPEN |
| 3.13 | Phase-3-Review | OPEN |

3.6 kommt absichtlich erst nach 3.1–3.5: keine Guards, bevor der tatsächliche Drift bekannt ist.

### Phase 4 — Controlled Agent Workflow

Testet den realen Arbeitsablauf eines fremden Agents:
Orientierung → Research → PLAN → kleinste Änderung → Formatter → lokale Guards → Diff → VERIFY → RESULT.

| # | Aufgabe | Status |
|---|---|---|
| 4.1 | Fremdagent-Orientierungstest | DONE |
| 4.2 | Research → Change Workflow testen | DONE |
| 4.3 | absichtliche Fehländerung testen | DONE |
| 4.4 | unerlaubte Architekturänderung testen | DONE |
| 4.5 | unerwarteten Diff erkennen | DONE |
| 4.6 | BLOCKED/UNVERIFIED korrekt behandeln | DONE | Präzisierung: Fremdagent kann ohne Owner KEINE ask-gated Aktion ausführen und KEINE nicht erlaubte Schreibaktion; allow-gelistete Read-/Git-Aktionen (git status/diff/log) bleiben möglich |
| 4.7 | Multi-Agent-Handoff testen | DONE | 2026-09-16: echter Round-Trip Architekt→Builder→Verify→Architekt-Review; Builder ohne Chat-Kontext arbeitete ausschließlich nach Auftrag (exakter Diff, keine Seiteneffekte); Mechanismus: scoped edit-grant (nur beauftragte Datei) |
| 4.8 | Workflow-Review | DONE | 2026-09-16: Review ergab KEINE Dokumentationsdrift (AGENTS.md Verification endet auf 'Do not claim success…', WORKBENCH Enforcement-Layer = getestete Realität); Phase 4 komplett PASS |

Entscheidender Test: Kann ein Agent, der den bisherigen Chat nicht kennt, das Repository sicher verändern?

### Phase 5 — Final Cleanup / Research Integration (erst nach Phase 4)

Deletion over addition.

| # | Aufgabe | Status | Notiz |
|---|---|---|---|
| 5.1 | temporäre Dateien entfernen | DONE | 2026-09-16: Inventur PASS — Repo enthält KEINE temporären Migration-/Smoke-Reste; aud uns unref. Altbestand = MEDIUM/UNRESOLVED, kein Blind-Delete. Batch B1 (GEMINI.md, SVG, INDEX-SSoT) + B2 (51-ingress F1/F2/F6) + F3-Batch + 511 ExecReload(--force) ausgeführt & verifiziert |
| 5.2 | Research PoC (frischer Agent, 3 echte Fragen, 7-Punkte-Score) | DONE | 2026-09-16: R1/R2/R3 je 7/7 PASS (21/21) — frische Agenten ohne Chat-Kontext; Research funktionierte mit vorhandenen Tools (Read/Grep/Glob/WebFetch/WebSearch); keine Agent-Edits; Ephemeral-Records /tmp/opencode/poc/ |
| 5.3 | Research-Workflow (CLAIM→LOCAL→PATTERN→UPSTREAM→EVIDENCE→DECISION) kanonisch machen | DONE | 2026-09-16: Kette als kanonischer Ablauf in AUDIT-BRIEF.md Abschnitt 8 verankert (+ UNRESOLVED-Steuerregel) |
| 5.4 | Research-Adapter (MCP als Transport, GitHub/nixpkgs/Docs/Context7 als Quellen) | DONE (Entscheidung: nicht bauen) | 2026-09-16: PoC bewies, dass vorhandene OpenCode-Tools die Recherche-Kette vollständig abdecken; KEIN Adapter, KEIN Research-MCP, kein Knowledge-Sumpf. MCP bleibt optionale Transport-Erweiterung |
| 5.5 | Agent End-to-End (PoC-Ergebnis → vollständiger Audit-Zyklus ohne Chat-Kontext) | DONE | 2026-09-16: Fresh-Agent-Audit 511-caddy.nix (Scorecard A–J alles PASS, Repo-Intaktheit bestätigt); Agent fand F1 (stripAuthHeaders/response-vs-request-header REAL) + F2 (ntfy-lookup REAL) — beide von Owner verifiziert; F5/F6 ehrlich UNRESOLVED |
| 5.6 | Final Audit | IN_PROGRESS | 2026-09-16 Acceptance: A1–A7/A9 PASS; A8+A10 = Doc-Drift → B3-Konsistenzbatch; kritisch: Git-Anker fehlte → B3.2 |
| 5.7 | ROADMAP auf Endzustand bringen | NEXT | letzte Phase-5-Aufgabe nach B3 |

Ephemeral-Regel: Research-Output ist Arbeitsdatensatz des aktuellen Audits (untracked, verwerflich); nur mediNix-spezifische Erkenntnisse wandern danach in eine lokale SSoT/ADR/Doku. Kein dauerhafter docs/research/-Ordner, kein Knowledge-Sumpf.

### Phase 6 — Final Acceptance Audit

Prüft: Architektur, Skills, Research, OpenCode-Konfiguration, Permissions, Custom Tools,
NIXMETA, Decimal System, Registry, Credentials, Host-Portabilität, Git-Scope, Drift Guards,
Dokumentation, Agent-Handoff. Explizit: NIX EVAL = BLOCKED/UNVERIFIED solange kein nix
verfügbar ist — kein Fehler der Workbench.

### OPEN FINDINGS — 51-ingress/511-caddy (aus 5.5 Fresh-Agent-Audit, Owner-verifiziert)

Ledger für chirurgische Batches NACH dem Git-Anker (kein Mischen mit Architekturarbeit):

| Finding | Klassifikation | Stelle | Beschreibung | Status |
|---|---|---|---|---|
| 511-F1 | REAL | 511-caddy.nix:67-75 | stripAuthHeaders nutzt Caddy `header` (Response-Header-Semantik); Sicherheitsziel „client-seitige Identity-Header entfernen" braucht `request_header` — skipPaths/nicht-auth-Flows reichen gefälschte Remote-User/X-Auth-Request-*-Header unverifiziert durch | OPEN |
| 511-F2 | REAL | 511-caddy.nix:27-34 + 581-ntfy.nix:16 | enabledServices-Lookup fragt flach `cfg.ntfy`/toCamelCase, Option liegt nested (`medinix.observability.ntfy.enable`, default.nix:574) → ntfy-vhost wird nie gerendert | OPEN |
| 511-F5 | UNRESOLVED | 511:251-271 vs 311 | Hardening-Parität: standalone = mediNix network-Profil, global = nur nixpkgs-Basis + OOMScoreAdjust — Architekturentscheidung ausstehend (ADR-511 klärt) | OPEN |
| 511-F6 | UNRESOLVED | 511:106-109 + default.nix:499-507 | forwardAuthUri-Default `/oauth2/auth` als Pocket-ID-Endpoint upstream nicht verifizierbar (Verdacht: oauth2-proxy-geprägt) — Pocket-ID-Forward-Auth-Vertrag klären | OPEN |
| 511-F3-Doc | Doc-Drift (LOW) | 51-ingress/README.md:97 | „.local no WAN abort" widerspricht Implementierung (lanAbort ist da) | OPEN |

### Definition of Done (harter Abschlusszustand — WORKBENCH DONE)

```text
[ ] Fremder Agent versteht Repository ohne Chat-Historie
[ ] Fremder Agent kennt die 6 Skills
[ ] Fremder Agent kennt Authority Hierarchy
[ ] Fremder Agent kennt Decision Rule
[ ] Fremder Agent recherchiert über repository.yaml
[ ] Fremder Agent verändert nur den notwendigen Scope
[ ] Architektur-Drift wird erkannt
[ ] unerlaubte Skill-Erweiterung wird verhindert
[ ] Decimal-/Registry-Drift wird erkannt
[ ] NIXMETA-Drift wird erkannt
[ ] Credential-Regeln sind geschützt
[ ] Host-spezifische Drift wird erkannt
[ ] unerwartete Git-Änderungen werden erkannt
[ ] fehlende Tools führen zu BLOCKED/UNVERIFIED
[ ] kein Fake-PASS möglich
[ ] keine unnötigen MCPs/Tools/Abstraktionen
[ ] Legacy-Skills = 0
[ ] aktive Skills = 6
[ ] Nix-Evaluation bleibt ehrlich BLOCKED/UNVERIFIED
```

## Research-Eingänge (klassifiziert — KEINE Installation)

| Quelle | Klasse/Status | Behandlung |
|---|---|---|
| milahu/nixos-config-webui | legacy-reference | REFERENCE ONLY (WebUI-UX-Ideen); letzte Aktivität ~2022-09 |
| vimjoyer/lezer-parser-nix | future-tooling-reference | Nur relevant falls syntax-aware Tooling jemals bewiesen wird |
| michalzubkowicz/nixos-management-skill | gold-mining | Benchmark/Gold-Mining: extract pattern → mediNix-native; NIE kopieren |
| curriedsoftware/nixomatic-skill | optional-tooling-reference | Ephemeral-Tooling-Idee; kein Kernbestandteil |
| mcpmarket NixOS Module Patterns | low-value-reference | Generische Patterns überschreiben niemals lokale Architektur |
| Determinate Systems (4 Projekte, s.o. 2e++) | candidate/deferred | CI-/Verify-Infrastruktur, kein Skill-Stoff |

## Decision Log (endgültig — nicht wieder aufräumen)

| Decision | Status | Result |
|---|---|---|
| Prowlarr 536 Factory | DONE | mediNix-Factory maßgeblich, kein nixpkgs-Override zur Konvergenz |
| Readarr 534 | DONE | RETIRED, nichts gelöscht, Slot 534 reserviert, Daten unangetastet |
| Context7 | DECIDED | optional reference, nie authority; verifizierte Library-ID = fertig recherchiert |
| Research Registry | DONE | routing/index; repository.yaml ≠ Wissensdatenbank |
| Determinate tools | DEFERRED/CANDIDATE | noch keine Adoption; flake-checker ≠ Ersatz für mediNix-Verify |
| Neue Research-Eingänge (5) | DONE | klassifiziert als reference/gold-mining, nicht installiert |
| Frontmatter-Schema | DECIDED | Formular v1.0 (identity, authority, research, invariants, verification, change_policy, output_contract); null statt weglassen |
| Legacy-Migration | DONE | 2026-09-16: 25 Legacy-Skills entfernt, 15 Gold-Regeln verdichtet, 6 aktive Skills |

## Verifikations-Lücken (honest state)

- `nix flake check` / statix / deadnix: **BLOCKED** (nix-Binary fehlt auf diesem Host) — Phase 2c-Gates bleiben UNVERIFIED.
- Smoke-Tests der Zielskills: via `opencode run` non-interactive (discipline/nix/authoring/review grün).
- Keine SSH-Konnektivität zum Nix-Host im Worktree-Kontext — Verifikation muss auf einem Nix-Host nachgeholt werden.

## Nächster Schritt

1. Phase 3: 3.1–3.6 DONE (Threat-Map, Inventur, Enforcement-Audit, Mapping, Taxonomie, repo-sanity-Guard); nächstes 3.7 erst nach Owner-Review.
2. Nix-Evaluation bleibt BLOCKED/UNVERIFIED bis `nix` auf einem Host verfügbar ist.

---

# mediNix-core — Architektur-Leitfaden & Feature-Roadmap (historisch)

> **Legacy-Sektion:** Die nachfolgende Feature-Roadmap beschreibt die Media-Architektur-Pläne
> (Observability, Storage-Tiering). Sie ist historischer Planungskontext und wird mit Phase 4
> (Final Cleanup) gegen den dann aktuellen Zustand gesichtet. Sie ist NICHT Teil der
> Agent-Workbench-SSOT oben.

# mediNix-core — Architektur-Leitfaden & Zukunfts-Roadmap

> **Vision:** `mediNix-core` ist ein spezialisierter, systemd-nativer **Pure-Media-Flake**.  
> Er enthält **ausschließlich** Mediendienste (Ingress, Acquisition, Transfer, Playback, Storage-Tiering) inklusive eines maßgeschneiderten **Observability- & Logging-Stacks** und robuster **Ressourcen-/OOM-Absicherung**.  
> Allrounder-Ballast (Smart Home, Vaultwarden, Git, Paperless, Game Server) verbleibt auf dem Host und gehört bewusst **nicht** in diesen Flake.

> **Status Quo & Verifikation:**  
> Die Kernarchitektur (Storage-Tiering, gehärteter Mover, *arr MediaCover Bind-Mounts, Jellyfin XML-Pre-Seeding mit nativer `MetadataPath`-Auslagerung, SSoT Memory-/OOM-Policy, spindown-sicheres smartd-Monitoring) ist **vollständig implementiert** und unter [`docs/ACCEPTANCE-TESTS.md`](ACCEPTANCE-TESTS.md) eingefroren.

---

## 1. Observability-Stack: Status & Logging

Ein vollwertiger Medien-Stack benötigt Transparenz über Service-Health, Streaming-Traffic und Fehler-Spitzen, ohne auf Cloud-Dienste angewiesen zu sein.

### A. Gatus: Visuelles Health- & Status-Dashboard (Nächster Schritt)
- **Quell-Dateien:** [`NixmitGROK/modules/40-observability.nix`](/home/moritz/repos/NixmitGROK/modules/40-observability.nix) & [`NixmitGROK/lib/gatus-endpoints.nix`](/home/moritz/repos/NixmitGROK/lib/gatus-endpoints.nix)
- **Konzept:**
  - Extrem schlanker Go-basierter Status-Server mit sauberem Web-UI (`585-gatus.nix`).
  - Automatische Generierung von Endpoints für alle aktiven mediNix-Dienste:
    - HTTP-Checks auf `127.0.0.1:${port}` (Caddy, Jellyfin, Sonarr, Radarr, SABnzbd, etc.).
    - Mountpoint-Checks für Tier B (Fast Pool) und Tier C (Media Pool).
    - Lokale Socket-Checks für Ingress & SQLite.
  - Caddy vHost: `status.${domain}` mit `accessGroup = "internal"`.

### B. Vector + Loki + Grafana: Die Medien-Logging-Pipeline (Optional / Später)
- **Quell-Datei:** [`NixmitGROK/modules/40-observability.nix`](/home/moritz/repos/NixmitGROK/modules/40-observability.nix)
- **Architektur:**
  ```text
  [ Caddy JSON-Logs ] ──┐
  [ systemd journal ] ──┴─► [ Vector ] (Remap / Parse) ──► [ Loki ] ──► [ Grafana UI ]
  ```
- **Komponenten:**
  1. **Vector:** Liest direkt aus `journald`, parst Caddy-Access-Logs per VRL.
  2. **Loki:** TSDB-Schema v13 mit Filesystem-Storage auf Tier B (`/var/lib/loki`), 7 Tage Retention.
  3. **Grafana:** Hört lokal auf Unix-Socket (`/run/grafana/grafana.sock`) hinter Caddy mit vorkonfiguriertem Dashboard.

---

## 2. Storage-Erweiterungen (Optional / Später)

### A. HDD-freundliche Deferred Deletion Queue
- **Quell-Datei:** [`NixmitGROK/modules/05-deferred-ops.nix`](/home/moritz/repos/NixmitGROK/modules/05-deferred-ops.nix)  
  *Dokumentation:** [`NixmitGROK/docs/guides/GUIDE-storage-tiers.md`](/home/moritz/repos/NixmitGROK/docs/guides/GUIDE-storage-tiers.md)
- **Konzept:**
  - Löschanfragen für Tier C wandern in eine Queue auf Tier B (`${storage.mediaRoot}/delete_queue`).
  - Periodischer Timer prüft via `hdparm -C` den Status der Platten:
    ```bash
    if hdparm -C "$dev" 2>/dev/null | grep -q "active/idle"; then
      # HDDs laufen ohnehin -> jetzt sicher löschen
    fi
    ```
  - Befinden sich die HDDs im `standby`, bleibt die Datei in der Queue (kein unnötiger Spinup).
  - Spätestens nach `maxAgeDays = 7` wird das Löschen beim nächsten regulären Aufwachen forciert.

### B. Label-basiertes Automounting & MergerFS
- **Quell-Datei:** [`NixmitGROK/modules/35-automount.nix`](/home/moritz/repos/NixmitGROK/modules/35-automount.nix)
- **Konzept:**
  - Automatisches Einhängen anhand von Dateisystem-Labels (`NIXDATA`, `NIXMEDIA`, `NIXBACKUP`).
  - Dynamisches Hinzufügen von Zweigen zum MergerFS-Pool ohne manuelles Bearbeiten der Host-fstab.

---

## 3. Offene Implementierungs-Phasen

| Phase | Thema | Enthaltene Komponenten | Priorität |
|---|---|---|:---:|
| **Phase 18** | **Media Observability** | Gatus Health-Dashboard (`585-gatus.nix`) | **Mittel (Aktiv)** |
| **Phase 18b** | **Media Logging** | Vector + Loki + Grafana Pipeline (`586-logging.nix`) | Niedrig / Später |
| **Phase 19** | **Storage & Spindown** | Deferred Deletion Queue (`544-deferred-delete.nix`), Automounting | Niedrig / Später |

---

## 4. Bewusst abgelehnte Elemente (Out of Scope)

Die folgenden Elemente aus `NixmitGROK` bleiben dauerhaft **ausgeschlossen**:
- **Audiobookshelf QuickSync (VA-API):** Audiobookshelf ist ein reiner Audioserver; QuickSync/VA-API beschleunigt hardwareseitig ausschließlich Video-Codecs. Audio-Transcoding läuft immer auf der CPU. Eine Durchreichung von `/dev/dri` würde die systemd-Sandbox schwächen ohne jeden Nutzen.
- **Allround-Apps:** Vaultwarden, Homepage Dashboard, Paperless-ngx, n8n, Home Assistant, Zigbee2MQTT, Forgejo, Cockpit, AMP Game Server.
- **Host-Netzwerk:** Blocky DoT DNS Resolver, AdGuardHome (gehört auf den Router/Host).
- **Zentrale Shared-DBs:** PostgreSQL, Valkey (mediNix bleibt autonom mit isolierten SQLite-Datenbanken).
