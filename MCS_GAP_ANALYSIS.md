# MCS_GAP_ANALYSIS.md

## Ziel
ClawDeck als Basis für ein eigenes **Mission Control System (MCS)** nutzen.

Zielzustand:
- mehrere sauber getrennte Projekte
- Zusammenarbeit zwischen **Sifu**, **James**, **Codex**
- schlanker Workflow ohne Datenmüll
- self-hosted auf `mission.digitalbackup.cloud`
- integriert in bestehende Infrastruktur mit **Traefik**

---

## Kurzurteil
**Ja, ClawDeck ist eine brauchbare Basis.**

Aber:
- nicht produktionsreif für deinen Ziel-Workflow ohne Anpassungen
- gute Basis für **MCS v1**
- kein guter Kandidat für "einfach so deployen und fertig"

**Empfehlung:**
- Forken
- gezielt umbauen
- erst MCS v1 schlank machen
- später tiefere Automationen

---

## Was schon passt

### 1. Grundidee passt
ClawDeck ist bereits auf Agent-Zusammenarbeit ausgelegt:
- Boards
- Tasks
- Aktivitätsfeed
- API
- Agent-Zuweisung
- Statuswechsel
- blocked / assigned / in_review

Das ist näher an deinem Ziel als GitHub Projects oder eine rohe ToDo-App.

### 2. Multi-Board vorhanden
Es gibt bereits `boards` als oberste Arbeitseinheit.
Das kann für deine Projekttrennung genutzt werden.

Für MCS v1 ist das gut genug:
- `OpenClaw`
- `TeachBoard`
- `James`
- `Infrastruktur`
- `Business Ops`

### 3. API-Basis vorhanden
Die API ist schon brauchbar für Agent-Arbeit:
- `GET /api/v1/boards`
- `GET /api/v1/tasks`
- `PATCH /api/v1/tasks/:id`
- `assign`, `unassign`, `claim`, `unclaim`, `complete`

Das spart viel Basisarbeit.

### 4. Activity-Logik existiert
Tasks haben Aktivitäten und Agent-Metadaten.
Das ist wichtig für Mission Control.

---

## Was nicht passt / Gaps

## A. Fachliche Gaps

### A1. Statusmodell passt nur teilweise
Aktuell vorhanden:
- `inbox`
- `up_next`
- `in_progress`
- `in_review`
- `done`

Für dein Modell fehlt:
- `planned`
- `ready`
- klare Trennung zwischen vorbereitet und sofort umsetzbar

**Folge:**
Das Statusmodell muss erweitert oder sauber umbenannt werden.

**Empfehlung:**
Zielstatus für MCS:
- Inbox
- Planned
- Ready
- In Progress
- Blocked
- Review
- Done

Wichtig:
`blocked` ist aktuell offenbar eher Zusatzflag als echte Spalte/primärer Zustand.
Für dein System sollte `Blocked` sichtbar dominanter sein.

---

### A2. Rollenmodell fehlt
ClawDeck kennt Agenten, aber nicht dein klares Dreieck:
- Sifu
- James
- Codex

Es gibt aktuell kein sauberes fachliches Owner-/Rollenmodell für diese Zusammenarbeit.

**Empfehlung:**
MCS braucht:
- `owner_type` oder klaren `owner`
- Werte: `Sifu`, `James`, `Codex`
- optional später: Reviewer separat

---

### A3. Task-Struktur ist noch zu generisch
Für MCS brauchst du minimal, aber klar:
- Titel
- Projekt
- Typ
- Priorität
- Owner
- Status
- Definition of Done
- Blocker
- Aktivitätslog

ClawDeck hat davon einiges, aber nicht alles sauber genug für dein Zielmodell.

**Fehlt/unscharf:**
- Definition of Done
- klare Task-Typen
- expliziter Owner für Mensch/James/Codex
- echte Entscheidungs-Tasks

---

### A4. Decision-/Review-Flow ist noch zu weich
`in_review` existiert, aber das reicht nicht.
Für dein Setup braucht Review klare Bedeutung:
- Ergebnis liegt vor
- wartet auf Prüfung/Freigabe
- erst dann Done

Das ist eher Prozess-/UI-Logik als nur Datenbank.

---

## B. Technische Gaps

### B1. Self-hosting ist nicht auf dein Setup optimiert
Die Upstream-Doku denkt primär in:
- Ruby direkt auf VPS
- PostgreSQL direkt auf VPS
- Puma + Nginx
- eher klassische Rails-Deployments

Dein Stack ist aber:
- Docker
- Traefik
- bestehende Container-Landschaft
- Subdomain `mission.digitalbackup.cloud`

**Folge:**
Wir sollten nicht deren Standard-Deployment kopieren.

**Empfehlung:**
- ClawDeck für dein Setup containerisieren bzw. Docker-first aufziehen
- Traefik-Routing sauber darüber legen
- Subdomain direkt als Ziel-Domain konfigurieren

---

### B2. Hartcodierte Hosted-URL ist ein echter Fehler
Im Task-JSON wird aktuell eine URL wie
`https://clawdeck.io/boards/...`
erzeugt.

Das ist für Self-Hosting falsch.

**Muss in V1 raus.**

Ziel:
- Basis-URL aus Environment
- z. B. `APP_URL=https://mission.digitalbackup.cloud`

---

### B3. Kein sauberer Docker-first-Pfad sichtbar
Im Repo ist kein klarer Docker-Standardpfad erkennbar.
Das ist nicht unlösbar, aber Arbeit.

**Folge:**
Wir brauchen:
- Dockerfile
- Compose/Stack-Definition
- Traefik-Labels
- persistente Volumes
- env-Konzept

---

### B4. Auth muss für dich pragmatisch bleiben
Upstream bietet Email/Passwort und optional GitHub OAuth.

Für deinen ersten produktiven Einsatz ist wichtig:
- nicht zu viel Auth-Komplexität
- keine unnötige Angriffsfläche
- sauber hinter Subdomain

**Empfehlung für V1:**
- erstmal einfacher Login
- GitHub OAuth nur wenn es echten Mehrwert bringt

---

## C. Produkt-/UX-Gaps

### C1. Noch zu sehr "ToDo-App"
ClawDeck wirkt in Teilen noch wie eine ToDo-App mit Agent-Flavor.
Du willst aber ein echtes Mission Control.

Das heißt:
- weniger Consumer-ToDo-Vibe
- mehr Übersicht, Verantwortung, Übergaben, Blocker, Review

### C2. Onboarding/Copy/Branding unpassend
Repo enthält ClawDeck-spezifisches Onboarding und Branding.
Das passt nicht zu deinem System.

**Muss ersetzt werden durch:**
- MCS / Mission Control Sprache
- James/Codex/Sifu Workflow
- weniger Demo-/Marketing-Ton

---

## Subdomain- und Infrastruktur-Anforderungen

Ziel-Domain:
- `mission.digitalbackup.cloud`

Anforderungen:
- sauber per Traefik veröffentlicht
- TLS über bestehende Traefik-Mechanik
- getrennt von OpenClaw
- keine Konflikte mit bestehendem Port-/Container-Setup

### Zielbild Deployment
Empfohlen:
- eigener Container für MCS-Webapp
- eigener Container für PostgreSQL
- internes Docker-Netz
- Traefik-Router für `mission.digitalbackup.cloud`
- App-interner Port z. B. `3000`
- externe Erreichbarkeit nur über Traefik

### Minimale Env-Konfiguration
Später voraussichtlich nötig:
- `APP_URL=https://mission.digitalbackup.cloud`
- `RAILS_ENV=production`
- `RAILS_MASTER_KEY=...`
- `SECRET_KEY_BASE=...`
- `DATABASE_URL=...`

Optional:
- GitHub OAuth
- Mailer-Konfiguration

---

## Empfehlung für MCS v1

### Behalten
- Boards als Projekte
- Tasks
- Aktivitäten
- API
- Agent-Zuweisung als Basis

### Früh umbauen
1. Branding auf MCS
2. `APP_URL`-basiertes URL-Handling
3. Statusmodell auf MCS anpassen
4. Owner-Modell ergänzen
5. Task-Felder schärfen
6. Docker-/Traefik-Deployment auf dein Setup anpassen

### Erst später umbauen
1. tiefe GitHub-Integration
2. ausgefeilte Reporting-Ansichten
3. komplexe Automationen
4. erweiterte Review-Workflows
5. Feintuning für James/Codex-spezifische Steuerung

---

## Priorisierte Umbauphasen

## Phase 0 — Entscheidung / Zielmodell
Noch ohne Installation:
- Projektstruktur finalisieren
- Statusmodell finalisieren
- Owner-Modell finalisieren
- Task-Felder finalisieren

## Phase 1 — Fork + technische Basis
- Repo forken
- Docker-first Deployment bauen
- Traefik + Subdomain `mission.digitalbackup.cloud`
- Self-hosting sauber lauffähig machen
- harte URLs entfernen

## Phase 2 — MCS v1 fachlicher Umbau
- Statusmodell anpassen
- Owner ergänzen
- Task-Typen ergänzen
- Definition of Done ergänzen
- Branding/Copy anpassen

## Phase 3 — Agent-Arbeitsmodus schärfen
- James/Codex-Workflow
- Review-Regeln
- Blocker-Mechanik
- bessere Aktivitätsdarstellung

## Phase 4 — Automationen
- GitHub-Anbindung
- spätere OpenClaw-Verknüpfungen
- eventuelle Task-Syncs

---

## Harte Meinung
**Ja, das lohnt sich.**

Aber nur, wenn wir diszipliniert bleiben:
- kein Feature-Müll
- kein Full-Rewrite aus Reflex
- kein blindes Upstream-Deployment
- kein sofortiger Großumbau

Der richtige Weg ist:
**ClawDeck als solides Rohmaterial für MCS v1 verwenden.**

Nicht perfekt.
Aber effizient.

---

## Nächste sinnvolle Schritte
1. MCS-Zielmodell final festzurren
2. entscheiden: Board = Projekt wirklich so übernehmen?
3. Fork-Plan schreiben
4. Deployment-Konzept für `mission.digitalbackup.cloud` definieren
5. erst dann Umsetzung freigeben
