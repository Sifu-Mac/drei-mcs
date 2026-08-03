# HANDOFF.md

Stand: 2026-08-03

## Aktueller Release-Stand

- `main` enthält zusätzlich zum Runtime-Commit `606f70c` den reinen Dokumentations-Merge `9645629`. Die Production-Arbeitskopie bleibt absichtlich detached bei `606f70c`; ein Deployment ist für Dokumentation nicht erforderlich.
- Production unter `https://drei.digitalbackup.cloud` ist gesund: `web` läuft, `db` ist healthy und `/up` liefert `200`.
- Der aktuelle Stand ist für den ersten GoLive als gemeinsamer Workspace ausgelegt: ein Admin verwaltet technische Einstellungen und Einladungen, Clients arbeiten auf allen aktiven Kampagnen, Boards und Karten desselben Workspaces.
- Der sichtbare Rollenvertrag besteht nur aus `Admin` und `Client`. Interne historische Mitgliedschaftswerte werden nicht in der UI angeboten.
- GitHub-OAuth, GitHub-/Discord-Navigation, die öffentliche Vorlagen-Landingpage und OpenClaw-Produkttexte sind entfernt. Die neutrale Agentenbasis bleibt erhalten, damit später eine Hermes-Integration möglich ist.
- Die MIT-Lizenz der ursprünglichen Vorlage bleibt unverändert erhalten. Das erlaubt die kommerzielle Weiterverwendung und verlangt die Beibehaltung des Lizenzhinweises.

## Abgeschlossen und deployt

- Invite-only Login mit Passwort-Reset, Passwortwechsel und einer Admin-only Benutzerverwaltung.
- Admins können Clients einladen, zu Admins befördern/zurückstufen und löschen; der letzte Admin sowie die eigene Adminrolle sind geschützt.
- Beim Löschen eines Users wird dessen eigene Karte mitgelöscht. Aktivitäten an weiterhin bestehenden Karten bleiben erhalten und werden durch den FK `task_activities.user_id` auf `NULL` anonymisiert.
- Admin-only Audit-Protokoll für Verwaltungsereignisse; keine Passwörter, Tokens oder Inhalte werden gespeichert.
- Kampagnen, Boards, dynamische Spalten und Karten inklusive Archivierung, Wiederherstellung, kontrollierter endgültiger Kampagnenlöschung und CSV-Boardexport.
- Kartenfunktionen für Admins und Clients: Anlegen, Duplizieren, Löschen, Inline-Titel/-Beschreibung, Farbe, Asset-Checkliste, Kommentare mit Zeitstempel, Bearbeiten/Löschen des eigenen Kommentars, Zitate und sichere klickbare HTTP(S)-Links. Agentensteuerung bleibt intern.
- `Freigegeben` bleibt eine sichtbare Review-Stufe, `Fertig` ist die finale Spalte; Karten werden in keinem Status ausgegraut.
- UI-Navigation, mobile Rückwege, Board-Dichte, textuelle Kartenaktion und die Wortmarke `DB × DREI` sind umgesetzt.
- SMTP über Postmark ist gehärtet: STARTTLS, Zertifikatsprüfung, HTTPS-Links, dedizierte Mail-Queue, begrenzte Retries und datensparsame Fehlerlogs. Absender: `DREI Asset Review <noreply@digitalbackup.at>`.
- Tägliches lokales PostgreSQL-Backup per `drei-review-backup.timer` um 03:30 UTC; Aufbewahrung maximal 14 Dumps. Ein isolierter Restore-Ablauf ist dokumentiert und getestet.
- Historischer Migrationsdrift für `api_usage_records` wurde mit `20260802190000` behoben; ein echter Reset erzeugt wieder den für `upsert` notwendigen eindeutigen Monatsindex.

## Verifikation vom 2026-08-03

- Vollständige isolierte Rails-Suite: `174 runs, 911 assertions, 0 failures, 0 errors, 0 skips`.
- Separate Headless-Chromium-Systemsuite: `7 runs, 39 assertions, 0 failures, 0 errors, 0 skips`.
- Brakeman 7.1.0: `0` Security Warnings.
- `bundler-audit` mit Advisory-DB-Stand 2026-08-02: keine bekannten Schwachstellen.
- Production: `drei-review-db-1` healthy, `drei-review-web-1` running, Healthcheck `200`.
- Backup-Timer aktiv; letzter Lauf am 2026-08-03 03:30:05 UTC erfolgreich, Dump erstellt.
- Aggregierter Produktionscheck: ein Admin, ein Client, keine offenen Einladungen und keine wartenden Mail-Jobs. Keine personenbezogenen Werte, Tokens oder Mailinhalte wurden ausgegeben.

## Bewusst offen / externe Entscheidungen

1. **Postmark aus Testmodus freischalten.** Technisch ist die App bereit; die Accountfreigabe erfolgt im Postmark-Konto und kann nicht sicher automatisiert werden. Erst danach Einladungen an beliebige Kundendomains senden.
2. **Offsite-Backups.** Lokale Backups und ein isolierter Restore sind verifiziert. Für eine zweite, räumlich getrennte Kopie braucht es ein freigegebenes Ziel (z. B. S3-kompatibler Bucket, Zugriffsmodell, Aufbewahrung und Verschlüsselungs-/Kostenentscheidung). Keine Zugangsdaten raten oder in Git ablegen.
3. **Historische leere Tabellen.** `projects` und `task_lists` enthalten in Production jeweils `0` Datensätze; Anwendungscode referenziert sie nicht mehr. `tasks.task_list_id` existiert historisch noch. Vor einem destruktiven Entfernen ist ein separater, backupgestützter Migrationskandidat mit From-scratch- und Restore-Nachweis erforderlich. Nichts davon ist bislang gelöscht worden.
4. **Echter Produktions-Client-Smoke.** Der reguläre Invite-Flow, Zustellung und Client-Eintritt wurden vom Benutzer bereits bestätigt. Die Browser-Systemtests decken Client-Kartenaktionen automatisiert ab. Ein weiterer interaktiver Production-Lauf braucht eine vom Benutzer bereitgestellte angemeldete Session oder einen explizit beauftragten temporären Test-Invite; ohne das keine neue Mail versenden.

## Nicht Teil dieses Pakets

- Neue Produktfunktionen wie Suche, Dashboard, Benachrichtigungen, feinere Berechtigungen oder Hermes-Anbindung.
- Produktive Datenbereinigung, neue echte Kunden oder Production-Deployment.

## Arbeitsregeln

- Zu Beginn einer Session `AGENTS.md` und dieses Dokument vollständig lesen.
- Feature-Arbeit auf sprechendem Branch; vor Merge: Diff-/Secret-Prüfung, passende Tests und unabhängiges `QA & Review`-Go.
- Keine Secrets, `.env.production`, Dumps oder `backup-postgres.sh` versionieren oder verändern.
- Nur `/docker/drei-review` bearbeiten; die Mission-Control-Instanz niemals berühren.
- Nach jedem Abschluss dieses Dokument aktualisieren.

## Wichtige Pfade

- `AGENTS.md`: dauerhafte Betriebs- und Sicherheitsregeln.
- `docs/CUSTOMER_DEPLOYMENT_CHECKLIST.md`: wiederverwendbare, secretfreie Kunden-Deployment-Checkliste.
- `docker-compose.yml`: Production-Stack (`web`, `db`).
- `docker-compose.test.yml` und `Dockerfile.test`: isolierte Testumgebung.
- `docs/RESTORE.md` und `docker-compose.restore.yml`: isolierter Restore-Ablauf.
- `app/models/task.rb`, `app/models/board_column.rb`, `app/controllers/boards/tasks_controller.rb`: Karten- und Spaltenkern.
- `app/controllers/admin/users_controller.rb`, `app/models/audit_event.rb`: Admin- und Audit-Funktionen.
