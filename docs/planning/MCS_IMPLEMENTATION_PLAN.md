# MCS Implementation Plan

## Phase 1 — technische Basis
- ClawDeck-Fork als Basis importieren
- Docker-first Deployment bauen
- Traefik-Expose auf `mission.digitalbackup.cloud`
- PostgreSQL + persistent storage anbinden
- Self-hosting-Hardcodings entfernen

## Phase 2 — MCS v1 fachlich
- Statusmodell von ClawDeck auf MCS anpassen
- Owner-Modell für `Sifu`, `James`, `Codex`
- Task-Typen ergänzen
- Definition of Done ergänzen
- Branding von ClawDeck auf Mission Control umstellen

## Phase 3 — Arbeitsmodus
- Übergaben James ↔ Codex sauber abbilden
- Review-Flow schärfen
- Blocked-Logik prominenter machen
- Projekttrennung in der UI schärfen

## Phase 4 — Automationen
- GitHub-Integration vertiefen
- OpenClaw-Agent-Workflows verbessern
- automatische Aktivitäts- und Review-Updates

## Phase 5 — Shared Workspace / echte Kollaboration

### Ziel
- **Sifu, James und Codex arbeiten auf derselben Datenbasis**.
- Boards dürfen **nicht mehr user-isoliert** sein.
- `Owner` bleibt pro Task erhalten, aber Sichtbarkeit und Bearbeitung laufen über einen **gemeinsamen Workspace**.

### Warum das nötig ist
- aktueller Zustand: jeder User sieht nur eigene Boards/Tasks
- Folge: James-User und Codex-User sehen Sifus echte Ready-Tasks nicht
- damit ist die Mission-Control-Idee fachlich noch nicht erfüllt

### Zielmodell
- `Workspace` oder `Project Space` als gemeinsame Hülle
- `Workspace has_many boards`
- `Workspace has_many members`
- `Board belongs_to workspace`
- `Task belongs_to board` (indirekt also auch zum Workspace)
- `Membership` verbindet `User` ↔ `Workspace` mit Rolle

### Rollen im Workspace
- `owner` — volle Kontrolle
- `member` — normale Mitarbeit
- optional später: `agent` / `service`

### Datenmodell-Umbau
1. neue Tabelle `workspaces`
2. neue Tabelle `workspace_memberships`
3. `boards.user_id` fachlich ablösen durch `boards.workspace_id`
4. bestehende Boards eines Users in einen Default-Workspace migrieren
5. bestehende Tasks unverändert an Boards hängen lassen
6. Zugriffslogik überall von `current_user.boards/...` auf `current_user.workspaces...` umstellen

### Rechte- und Sichtbarkeitslogik
- User sieht Boards nur, wenn er Mitglied im Workspace ist
- James und Codex bekommen Mitgliedschaft im selben Workspace wie Sifu
- API liefert dann echte gemeinsame Ready-Tasks

### API-/Agent-Folgen
- Board- und Task-Endpunkte müssen membership-basiert autorisieren
- James/Codex können mit eigenem User + eigenem Token arbeiten
- kein Arbeiten "als Sifu" nötig
- `Owner = James/Codex` wird damit operativ nutzbar statt nur dekorativ

### UI-Folgen
- Workspace-Kontext sichtbar machen
- Board-Sidebar bleibt, aber basiert auf Workspace-Boards
- später optional Workspace-Switcher für mehrere Firmen-/Projektkontexte

### Migrationsstrategie
#### Schritt 1 — intern vorbereiten
- Tabellen + Modelle anlegen
- bestehende Daten in Default-Workspace pro User migrieren

#### Schritt 2 — Leselogik umstellen
- Controller/Scopes auf Workspace-Mitgliedschaft umstellen
- UI unverändert lassen, nur Datenquelle ändern

#### Schritt 3 — Kollaboration aktivieren
- James und Codex als Mitglieder in Sifus Workspace aufnehmen
- echte gemeinsame Boards testen

#### Schritt 4 — aufräumen
- alte user-zentrierte Annahmen entfernen
- optional später Einladungen / Rollenpflege in Admin/UI

### Akzeptanzkriterien
- James sieht Sifus Ready-Tasks im selben Board
- Codex sieht dieselben relevanten Tasks ebenfalls
- Änderungen von James/Codex sind live für Sifu sichtbar
- API-Zugriff läuft mit eigenem User-Token, nicht über Sifus Account
- mehrere getrennte Projekte bleiben möglich

### Nicht Teil dieses Schritts
- kein kurzfristiger Token-Workaround über Sifus Account
- keine Invite-/Email-Produktpolitur zuerst
- keine komplexe ACL, solange `owner/member` reicht
