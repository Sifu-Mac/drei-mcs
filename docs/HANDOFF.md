# HANDOFF.md

Stand: 2026-07-30

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `main`
- Aktueller main-Commit: `084ecd4 Fix API task completion toggle`
- VPS-Git-Status: `main...origin/main`, nur `backup-postgres.sh` ist unversioniert.

## Laufende Container und Services

Production-Stack in `/docker/drei-review`:
- `drei-review-db-1`: Service `db`, running, healthy
- `drei-review-web-1`: Service `web`, running
- Healthcheck: `/up` liefert `200`

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

## Wichtige technische Entscheidungen

- Production-Image bleibt ohne Development-/Test-Gems.
- Rails-Tests laufen in separatem `Dockerfile.test`/`docker-compose.test.yml`.
- SMTP ist nur ENV-basiert konfiguriert; keine Zugangsdaten im Repo.
- `User.admin` steuert interne Admin-Rechte; `WorkspaceMembership.role` steuert Workspace-Rollen.
- `Task.completed`/`completed_at` werden ueber den `done`-Status synchronisiert.
- Production-Deployment erfolgt ausschliesslich im Stack `/docker/drei-review`.

## Migrationen

Wichtige zuletzt relevante Migrationen:
- `20260514110000_add_workspaces_and_shared_board_access.rb`
- `20260729205705_create_invites.rb`
- Active Storage Tabellen sind bereits vorhanden und werden fuer Uploads genutzt.

Keine offene Migration bekannt; Production wurde nach Invite-/Upload-Merges migriert.

## Aktuelle Testresultate

Letzte vollstaendige Suite im isolierten Test-Stack:
- Befehl: `docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test`
- Ergebnis: `68 runs, 171 assertions, 0 failures, 0 errors, 0 skips`

Relevanter Einzeltest nach Fix:
- `Api::V1::TasksControllerTest#test_complete_toggles_completed_task_back_to_incomplete`
- Ergebnis: `1 runs, 3 assertions, 0 failures, 0 errors, 0 skips`

## Offene Fehler

- Keine offenen Testfehler bekannt.
- Compose meldet Warnungen fuer nicht gesetzte SMTP-ENV-Werte; Mailversand ist dadurch nicht aktiv verifiziert.

## Offene Aufgaben nach Prioritaet

1. SMTP/Postmark sauber konfigurieren und mit echten ENV-Werten testen, ohne Secrets zu dokumentieren.
2. Invite-Mailversand nach SMTP-Konfiguration mit nicht-produktiver Testadresse pruefen.
3. Backup-Strategie fuer `/docker/drei-review` dokumentieren und verifizieren.
4. README/DEPLOYMENT bei Gelegenheit auf `https://drei.digitalbackup.cloud` und die isolierte Testumgebung aktualisieren.
5. Lokale unversionierte Dubletten-Dateien pruefen und bereinigen, falls sie nicht gebraucht werden.

## Naechster konkreter Arbeitsschritt

Postmark/SMTP-ENV auf dem VPS konfigurieren und danach Invite-Mailversand kontrolliert testen, ohne echte Kundeneinladungen zu versenden.

## Wichtige Dateien und Pfade

- `AGENTS.md`: dauerhafte Arbeitsregeln fuer Agenten.
- `docs/HANDOFF.md`: aktueller Projektstand; nach jeder abgeschlossenen Arbeitssession aktualisieren.
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
