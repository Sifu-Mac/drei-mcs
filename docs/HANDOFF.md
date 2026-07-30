# HANDOFF.md

Stand: 2026-07-30

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `main`
- Deployter Code-Commit: `4d22898 Merge campaign board structure`
- Feature-Commit: `ba3df99 Add campaign board structure`
- VPS-Git-Status nach Deployment: `main...origin/main`, nur `backup-postgres.sh` ist unversioniert und unberuehrt.

## Laufende Container und Services

Production-Stack in `/docker/drei-review`:
- `drei-review-db-1`: Service `db`, running, healthy
- `drei-review-web-1`: Service `web`, running
- Healthcheck: `https://drei.digitalbackup.cloud/up` liefert `200`

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
- Kampagnenebene umgesetzt: `Kampagne -> mehrere Boards -> mehrere Karten`.
- Linke Navigation zeigt Kampagnen gruppiert mit eingerueckten Boards, Auf-/Zuklappen, Aktionsmenues und „Neue Kampagne“.
- Kampagnen und Boards koennen erstellt, umbenannt, dupliziert, archiviert und wiederhergestellt werden.
- Duplizierung kopiert Boards/Karten und ordnet Karten den neuen Boards zu; Kommentare, Bilder, Coverbilder und Aktivitaeten werden nicht kopiert.
- Kanban-Karten sind kompakt und zeigen keine grosse Coverbild-Vorschau; Coverbilder bleiben in Detailansichten erhalten.
- Sichtbare Board-/Task-/Kommentar-/Navigations-Texte wurden auf Deutsch umgestellt.

## Wichtige technische Entscheidungen

- Production-Image bleibt ohne Development-/Test-Gems.
- Rails-Tests laufen in separatem `Dockerfile.test`/`docker-compose.test.yml`.
- SMTP ist nur ENV-basiert konfiguriert; keine Zugangsdaten im Repo.
- `User.admin` steuert interne Admin-Rechte; `WorkspaceMembership.role` steuert Workspace-Rollen.
- Bestehende Rollen-/Autorisierungshelfer wurden erweitert; keine parallele Policy-Schicht wurde eingefuehrt.
- Clients koennen Kampagnen und Boards sehen, aber Kampagnen-/Board-Struktur nicht serverseitig mutieren.
- Kampagnen und Boards werden ueber `archived_at` archiviert; Board-Aktionen nutzen kein Hard Delete.
- Bestehende Boards wurden per Migration der Standardkampagne `Allgemein` zugeordnet.
- Stabile Datenbank-IDs bleiben DOM-/Route-Basis; Namen werden nicht als technische IDs genutzt.
- `Task.completed`/`completed_at` werden ueber den `done`-Status synchronisiert.
- Production-Deployment erfolgt ausschliesslich im Stack `/docker/drei-review`.

## Migrationen

Neue Migrationen im deployten Stand:
- `20260730130000_create_campaigns.rb`
- `20260730130100_add_campaign_and_archived_at_to_boards.rb`

Production-Migrationsstatus:
- `campaigns` wurde angelegt.
- `boards.campaign_id` und `boards.archived_at` wurden ergaenzt.
- Bestehende Boards wurden der Kampagne `Allgemein` zugeordnet.
- Production-Datencheck: 1 Kampagne, 2 Boards, 0 Boards ohne Kampagne.

## Aktuelle Testresultate

Letzte vollstaendige Suite im isolierten Test-Stack:
- Befehl: `docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test`
- Ergebnis: `84 runs, 251 assertions, 0 failures, 0 errors, 0 skips`

Fokussierte Kampagnen-/Board-Tests:
- Befehl: `docker compose -f docker-compose.test.yml run --rm test bin/rails test test/models/campaign_test.rb test/models/board_test.rb test/controllers/campaigns_controller_test.rb test/controllers/boards_controller_test.rb`
- Ergebnis: `16 runs, 80 assertions, 0 failures, 0 errors, 0 skips`

Production-Smoke:
- `docker compose --env-file .env.production ps`: `db` healthy, `web` running.
- `/up`: `200`.
- HTTPS-Login mit bestehendem Admin: Login-POST `302`, Board-Seite nach Redirect `200`.
- Kampagnen-Navigation sichtbar: ja.
- „Neue Kampagne“ sichtbar fuer Admin: ja.
- Archivierte-Kampagnen-Seite: `200`.
- Kanban-Covervorschau-Marker auf Boardseite: nein.
- Production hat aktuell keine `client`-Membership; Client-UI konnte deshalb ohne Datenveraenderung nicht manuell eingeloggt werden. Server-Blockierung fuer Clients ist testabgedeckt.

## Offene Fehler

- Keine offenen Testfehler bekannt.
- SMTP-Werte sind weiterhin nicht gesetzt; Compose gibt entsprechende Warnungen aus.
- Kein Production-Client-Benutzer vorhanden, daher keine manuelle Client-Smoke-Pruefung ohne Datenanlage.

## Offene Aufgaben nach Prioritaet

1. Einen echten Client-Testzugang ueber den Invite-Flow anlegen und die Client-Ansicht manuell pruefen.
2. SMTP/Postmark sauber konfigurieren und mit echten ENV-Werten testen, ohne Secrets zu dokumentieren.
3. Invite-Mailversand nach SMTP-Konfiguration mit nicht-produktiver Testadresse pruefen.
4. Backup-Strategie fuer `/docker/drei-review` dokumentieren und verifizieren.
5. Lokale unversionierte Dubletten-Dateien pruefen und bereinigen, falls sie nicht gebraucht werden.

## Naechster konkreter Arbeitsschritt

Client-Testzugang per Invite-Flow erstellen und die Client-Ansicht der Kampagnen-/Board-Navigation ohne Strukturaktionen manuell validieren.

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
- Bestehende Production-Daten wurden nicht exportiert.
- Production-Daten wurden nur durch die notwendigen Kampagnen-/Board-Migrationen veraendert.
