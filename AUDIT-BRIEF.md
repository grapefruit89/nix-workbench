# MediNix Agent Audit Brief

## 0. Zweck

Du erhältst diese Datei als **einzigen initialen Auftrag**.

Deine Aufgabe ist nicht, möglichst schnell Dateien zu ändern.

Deine Aufgabe ist:

> **Repository verstehen → relevante Regeln und SSoTs selbst finden → Evidenz sammeln → Befunde klassifizieren → minimalen Änderungsplan erstellen → auf GO warten.**

Du sollst dich innerhalb des Repositorys **selbstständig orientieren**.

Der Auftraggeber möchte keine vorweggenommene Lösung.
Wenn die Architektur bereits korrekt ist, lautet das Ergebnis ausdrücklich `KEEP`.

---

# 1. START

Beginne mit dieser Datei.

Danach ermittle selbstständig den für deinen Auftrag notwendigen Repository-Kontext.

### Zuerst lesen

1. `AGENTS.md`
2. relevante lokale `AGENTS.md`
3. `56-agents/` und die dortigen aktiven Skills
4. anschließend die für deinen konkreten Auftrag relevanten SSoTs und Vergleichsmuster

**Nicht das gesamte Repository blind lesen.**

Arbeite nach dem Prinzip:

> **Startpunkt → Abhängigkeit → SSoT → Muster → Beleg**

Wenn du eine zusätzliche Datei liest, muss klar sein, **warum sie für die aktuelle Entscheidung relevant ist**.

---

# 2. AUFTRAG

Der konkrete Untersuchungsgegenstand wird dir zusätzlich genannt.

Er kann beispielsweise sein:

- eine einzelne `.nix`-Datei,
- ein Modul,
- ein Service,
- ein Verzeichnis,
- eine Architekturentscheidung,
- ein Audit-Finding,
- eine behauptete Inkonsistenz,
- eine Migration,
- eine Hardening-Frage.

Behandle den genannten Gegenstand als **Startpunkt**, nicht automatisch als Fehler.

Eine Behauptung ist keine Tatsache.

---

# 3. SELBSTSTÄNDIGE ORIENTIERUNG

Finde selbst heraus:

### Architektur

- Wo ist die relevante SSoT?
- Welche lokale Architekturregel gilt?
- Gibt es bereits eine Factory oder ein vorhandenes Pattern?
- Gibt es einen bestehenden vergleichbaren Use-Case?
- Gibt es eine Registry-Zuordnung?
- Gibt es ein Hardening-Profil?
- Gibt es relevante Credentials-Regeln?
- Gibt es lokale Modul-/Verzeichnisregeln?

### Abhängigkeiten

Verfolge relevante Beziehungen beispielsweise über:

```text
Modul
  ↓
Registry
  ↓
Factory
  ↓
Hardening
  ↓
Credentials / systemd / Runtime
```

oder den tatsächlich vorhandenen Pfad.

**Nicht jede Datei muss geprüft werden.**

---

# 4. SOURCE-OF-TRUTH-REGEL

Bevor du eine Architekturbehauptung aufstellst:

1. finde die vermutete SSoT,
2. öffne die tatsächliche Stelle,
3. prüfe das tatsächliche Attribut / Pattern,
4. vergleiche es mit dem untersuchten Code,
5. erst danach klassifizieren.

Insbesondere nicht aus Dateinamen, Kommentaren oder fremden Audit-Berichten schließen.

Wenn ein Audit ein bestimmtes Attribut oder eine bestimmte Zeile nennt:

> **Öffne diese Stelle selbst.**

---

# 5. BESTEHENDE MUSTER VOR NEUER ABSTRAKTION

Suche zuerst nach einem bestehenden funktionierenden Pattern.

Bevor du vorschlägst:

- Factory erweitern
- Registry erweitern
- neue Skill-Struktur
- neues Helper-Modul
- neue Abstraktion
- neue Datei
- neue Dependency

prüfe:

> Gibt es bereits eine einfache vorhandene Lösung?

Grundregel:

```text
Nix-/NixOS-native
    >
bestehende MediNix-Infrastruktur
    >
einfachste Lösung
    >
wenigste Dependencies
    >
geringster Wartungsaufwand
    >
einfachste objektive Verifikation
    >
kleinste notwendige Änderung
```

**Keine Abstraktion nur für einen einzelnen Sonderfall.**

---

# 6. KLASSIFIKATION

Jeder relevante Befund erhält genau eine Klassifikation:

```text
REAL
PHANTOM
UNRESOLVED
KEEP
```

### REAL

Die Behauptung ist durch den tatsächlichen Code belegbar und verletzt eine reale Regel, Invariante oder funktionale Voraussetzung.

### PHANTOM

Die behauptete Problematik existiert im tatsächlichen Code nicht oder wird bereits korrekt behandelt.

### UNRESOLVED

Die vorhandenen Belege reichen für eine belastbare Entscheidung nicht aus.

### KEEP

Der untersuchte Mechanismus ist korrekt und sollte nicht verändert werden.

---

# 7. IST / TARGET TRENNEN

Wenn mehrere Systeme oder Zustände existieren, muss ihre Rolle ausdrücklich bestimmt werden.

Beispiel:

```text
IST / Produktion / Referenz
TARGET / zukünftige Architektur
```

Information aus einem IST-System ist **kein Beweis** für den TARGET-Zustand.

Live-Messungen dürfen nicht stillschweigend als Beweis für nicht laufende Zielsysteme verwendet werden.

Wenn eine Information nur Referenzcharakter besitzt:

```text
REFERENCE ONLY
```

angeben.

---

# 8. RESEARCH

Recherche ist kein Selbstzweck.

Recherchiere nur, wenn der lokale Repository-Kontext die Frage nicht ausreichend beantwortet.

### Kanonische Research-Kette

```text
CLAIM → LOCAL → PATTERN → UPSTREAM → EVIDENCE → DECISION
```

1. **CLAIM** — die konkrete Behauptung bzw. das Audit-Finding isolieren.
2. **LOCAL** — zuerst lokale SSoT und tatsächliche Implementierung prüfen.
3. **PATTERN** — bestehende mediNix-Muster und Abhängigkeiten prüfen.
4. **UPSTREAM** — erst danach aktuelle externe Primärquellen zur Semantik verifizieren (Live-Quelle, nicht Modellgedächtnis; bei 404 Pfad über GitHub-API/Verzeichnislisting entdecken, dann raw fetchen).
5. **EVIDENCE** — konkrete Belege an den tatsächlichen Fundstellen sichern.
6. **DECISION** — daraus KEEP / REAL / PHANTOM / UNRESOLVED bzw. einen minimalen Änderungsplan ableiten.

Fehlt eine Stufe der Kette, ist die DECISION unbelastbar — im Zweifel UNRESOLVED statt Behauptung.

Bevorzugte Reihenfolge:

```text
1. lokaler mediNix-Kontext
2. Upstream GitHub
3. nixpkgs package
4. nixpkgs module
5. Nix builtins/lib/pkgs-Funktionssignaturen → noogle.dev
   (dokumentierte Query-API; liefert Quelle + Position zur
   Rückverfolgung; Index gegen master — Signatur gegen die
   konkrete Ziel-Channel-Version verifizieren)
6. offizielle Upstream-Dokumentation
7. gezielte Referenz-Repositories
8. Context7 als optionaler Accelerator
```

Lokale mediNix-Regeln haben Vorrang vor externen Patterns.

Ein externes Beispiel darf nicht automatisch zur lokalen Architekturregel werden.

---

# 9. NIX-EINSCHRÄNKUNG

Wenn Nix/NixOS in der aktuellen Umgebung nicht verfügbar ist:

```text
BLOCKED/UNVERIFIED
```

verwenden.

Nicht simulieren.

Nicht behaupten, eine Nix-Evaluation sei erfolgreich gewesen.

Nicht aus statischer Analyse einen Runtime-Beweis machen.

Unterscheide ausdrücklich:

```text
statisch verifiziert
runtime verifiziert
Nix-Evaluation
BLOCKED/UNVERIFIED
```

---

# 10. SECURITY / CREDENTIALS

Credentials niemals:

- entschlüsseln,
- ausgeben,
- inspizieren,
- in Logs schreiben,
- in generierte Dokumentation schreiben,
- in `/nix/store` legen,
- als CLI-Argument verwenden,
- als gewöhnliche Umgebungsvariable exponieren.

Wenn die Analyse einen Secret-Wert benötigen würde:

> **STOP und Auftraggeber fragen.**

Die Existenz und korrekte Verwendung eines sealed-credential Mechanismus darf dagegen statisch geprüft werden.

---

# 11. CHANGE POLICY

Während der Analyse:

> **KEINE EDITS.**

Erst wenn die Analyse abgeschlossen ist:

```text
FINDINGS
↓
IMPLEMENTATION PLAN
↓
STOP
↓
GO
↓
minimaler Edit
↓
objektive Verifikation
```

Ein `GO` gilt nur für den beschriebenen Scope.

Kein stilles „Aufräumen nebenbei".

Keine opportunistischen Refactorings.

Keine Bulk-Rewrites.

Keine Formatierungsänderungen außerhalb des erlaubten Scopes.

---

# 12. VERIFICATION NACH GO

Nach einem erlaubten Edit mindestens prüfen, soweit die Umgebung es erlaubt:

```text
git diff
git diff --check
medinix-meta check
check-docs
repo-sanity
```

Weitere verfügbare Prüfungen nur, wenn sie für den geänderten Bereich relevant sind.

Nicht verfügbare Prüfungen ehrlich als:

```text
BLOCKED/UNVERIFIED
```

ausweisen.

---

# 13. DIFF-SCOPE

Der finale Diff muss exakt zum genehmigten Auftrag passen.

Prüfe:

```text
Was sollte geändert werden?
Was wurde tatsächlich geändert?
Gibt es unerwartete Dateien?
Gibt es unerwartete Nebenänderungen?
```

Wenn der Diff über den genehmigten Scope hinausgeht:

> **STOP.**

Nicht eigenmächtig bereinigen.

---

# 14. AUSGABE VOR GO

Berichte ausschließlich in diesem Format:

```text
SCOPE

[untersuchte Dateien / Bereiche]

CONTEXT DISCOVERED

[selbst gefundene relevante SSoTs, Skills, Patterns und Abhängigkeiten]

AUDIT

[F1] REAL / PHANTOM / UNRESOLVED / KEEP
[F2] REAL / PHANTOM / UNRESOLVED / KEEP
...

EVIDENCE

- konkrete Datei + Stelle
- tatsächliches Pattern
- relevante SSoT
- Vergleichsmuster
- Schlussfolgerung

ARCHITECTURE DECISION

[falls erforderlich:
welche lokale Architekturentscheidung aus der Evidenz folgt]

IMPLEMENTATION PLAN

[nur wenn Änderungen tatsächlich erforderlich sind]

- Datei
- konkrete Änderung
- warum
- was ausdrücklich NICHT geändert werden soll

VERIFICATION PLAN

[welche Prüfungen nach GO möglich sind]

BLOCKED / UNVERIFIED

[alles, was in der aktuellen Umgebung nicht objektiv geprüft werden kann]

OPEN

[verbleibende Unsicherheiten]

STOP

Keine Änderungen ohne explizites GO.
```

---

# 15. WICHTIGSTE REGEL

Du bist kein Autocomplete-System.

Du sollst nicht versuchen, die vom Auftraggeber erwartete Lösung zu erraten.

Deine Aufgabe ist:

> **Beweise sammeln. Bestehende Architektur verstehen. Fehler von Nicht-Fehlern unterscheiden. Die kleinste notwendige Änderung identifizieren. Dann STOP.**

Wenn die richtige Antwort lautet:

```text
KEEP
```

ist das ein erfolgreiches Ergebnis.

Wenn die richtige Antwort lautet:

```text
UNRESOLVED
```

ist das ebenfalls ein erfolgreiches Ergebnis.

**Ein schneller falscher Fix ist schlechter als ein sauber begründetes STOP.**
