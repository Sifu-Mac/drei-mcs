# HANDOFF.md

Stand: 2026-07-30

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `feature/campaign-board-structure`
- Aktueller main-Commit vor Merge: `ba9968b Add project agent and handoff docs`
- VPS-Git-Status: Feature-Branch mit Kampagnen-/Board-Struktur in Arbeit; `backup-postgres.sh` bleibt unversioniert und unberuehrt.

## Laufende Container und Services

Production-Stack in `/docker/drei-review`:
- `drei-review-db-1`: Service `db`, zuletzt running/healthy
- `drei-review-web-1`: Service `web`, zuletzt running
- Healthcheck vor dieser Arbeit: `/up` liefert `200`

Test-Stack:
- `docker-compose.test.yml` definiert `test-db` und `test`.
- Testdatenbank ist getrennt von Production: `drei_mcs_test`.
- Test-Container verwendet keine `.env.production` und keine Production-Secrets.

## Umgesetzte Funktionen

- Branding auf `DREI Asset Review` / `drei-mcs` aktualisiert.
- Invite-only Auth umgesetzt; oeffentliche Registrierung entfernt.
- Admin-Invite-Verwaltung und oeffentliche Invite-Annahme vorhanden.
- Helles DREI-UI mit blauem Akzent gemergt.
- Task-Coverbilder und mehrere Bilder pro Task-Kommentar via Active Storage umgesetzt.
- Isolierte Docker-Testumgebung erstellt.
- API-Task-Completion-Toggle repariert.
- Erster interner Admin-Benutzer wurde angelegt; Zugangsdaten werden nicht dokumentiert.
- In `feature/campaign-board-structure` umgesetzt: Kampagnenebene, Boards innerhalb von Kampagnen, Archivierung/Wiederherstellung, Duplizierung ohne Kommentare/Bilder/Aktivitaeten, deutsche Board-/Task-Oberflaeche und kompakte Kanban-Karten ohne Coverbild-Vorschau.

## Wichtige technische Entscheidungen

- Production-Image bleibt ohne Development-/Test-Gems.
- Rails-Tests laufen in separatem `Dockerfile.test`/`docker-compose.test.yml`.
- SMTP ist nur ENV-basiert konfiguriert; keine Zugangsdaten im Repo.
- `User.admin` steuert interne Admin-Rechte; `WorkspaceMembership.role` steuert Workspace-Rollen.
- Bestehende Rollen-/Autorisierungshelfer wurden erweitert; keine parallele Policy-Schicht wurde eingefuehrt.
- Clients koennen Kampagnen und Boards sehen, aber Kampagnen-/Board-Struktur nicht serverseitig mutieren.
- Kampagnen und Boards werden ueber `archived_at` archiviert; kein Hard Delete fuer Board-Aktionen.
- Bestehende Boards werden per Migration der Standardkampagne `Allgemein` zugeordnet.
- `Task.completed`/`completed_at` werden ueber den `done`-Status synchronisiert.
- Production-Deployment erfolgt ausschliesslich im Stack `/docker/drei-review`.

## Migrationen

Wichtige zuletzt relevante Migrationen:
- `20260514110000_add_workspaces_and_shared_board_access.rb`
- `20260729205705_create_invites.rb`
- `20260730130000_create_campaigns.rb`
- `20260730130100_add_campaign_and_archived_at_to_boards.rb`
- Active Storage Tabellen sind bereits vorhanden und werden fuer Uploads genutzt.

Neue offene Production-Migrationen bis zum Deployment:
- `campaigns` anlegen.
- `boards.campaign_id` und `boards.archived_at` ergaenzen.
- Bestehende Boards der Kampagne `Allgemein` zuordnen.

## Aktuelle Testresultate

Letzte vollstaendige Suite im isolierten Test-Stack:
- Befehl: `docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test`
- Ergebnis: `84 runs, 251 assertions, 0 failures, 0 errors, 0 skips`

Fokussierte Kampagnen-/Board-Tests:
- Befehl: `docker compose -f docker-compose.test.yml run --rm test bin/rails test test/models/campaign_test.rb test/models/board_test.rb test/controllers/campaigns_controller_test.rb test/controllers/boards_controller_test.rb`
- Ergebnis: `16 runs, 80 assertions, 0 failures, 0 errors, 0 skips`

## Offene Fehler

- Keine offenen Testfehler bekannt.
- Deployment fuer die Kampagnen-/Board-Struktur steht noch aus.
- Compose meldet Warnungen fuer nicht gesetzte SMTP-ENV-Werte; Mailversand ist dadurch nicht aktiv verifiziert.

## Offene Aufgaben nach Prioritaet

1. `feature/campaign-board-structure` committen, zu GitHub pushen, in `main` mergen und `main` pushen.
2. VPS-Stack neu bauen, Migrationen ausfuehren und Production-Smoke pruefen.
3. Admin- und Client-Ansicht der Kampagnen-/Board-Struktur manuell pruefen.
4. SMTP/Postmark sauber konfigurieren und mit echten ENV-Werten testen, ohne Secrets zu dokumentieren.
5. Backup-Strategie fuer `/docker/drei-review` dokumentieren und verifizieren.

## Naechster konkreter Arbeitsschritt

Feature-Branch committen, pushen, in `main` mergen und danach den VPS-Stack mit Migrationen deployen.

## Wichtige Dateien und Pfade

- `AGENTS.md`: dauerhafte Arbeitsregeln fuer Agenten.
- `docs/HANDOFF.md`: aktueller Projektstand; nach jeder abgeschlossenen Arbeitssession aktualisieren.
- `app/models/campaign.rb`: Kampagnenmodell.
- `app/models/board.rb`: Board-Zuordnung zu Kampagnen, Archivierung, Duplizierung.
- `app/controllers/campaigns_controller.rb`: Kampagnenaktionen.
- `app/controllers/boards_controller.rb`: Boardaktionen und kampagnenbasierte Navigation.
- `app/views/boards/_sidebar.html.erb`: linke Kampagnen-/Board-Navigation.
- `Dockerfile`: Production-Image.
- `Dockerfile.test`: Test-Image mit Development-/Test-Gems.
- `docker-compose.yml`: Production-Stack.
- `docker-compose.test.yml`: isolierter Test-Stack.
- `.env.production.example`: Beispielwerte ohne echte Secrets.
- `/docker/drei-review/.env.production`: echte Production-ENV-Datei, nicht anzeigen oder committen.

## Postmark-/SMTP-Status

- SMTP-Konfiguration ist ENV-basiert in Production.
- Aktuell sind SMTP-ENV-Werte im Compose-Kontext nicht gesetzt; Docker Compose gibt entsprechende Warnungen aus.
- Keine SMTP-Zugangsdaten wurden dokumentiert oder veraendert.
- Keine echten Einladungen wurden versendet.

## Backup-Status

- Auf dem VPS existiert unversioniert `backup-postgres.sh`; Inhalt und Einsatzstatus wurden nicht veraendert.
- Kein verifizierter aktueller Backup-Lauf dokumentiert.
- Bestehende Production-Daten wurden nicht exportiert oder veraendert.
