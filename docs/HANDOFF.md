# HANDOFF.md

Stand: 2026-08-05

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
- Browser-Titel aller Rails-Layouts lautet `DB × DREI`; das bereitgestellte DB-Symbol wird als sicheres, lokales SVG-Favicon ausgeliefert.
- Sidebar-Aktionsmenüs für Kampagnen und Boards sowie „Board hinzufügen“ verwenden den zentralen Dropdown-Controller: Menüs schließen sich gegenseitig, per Escape und bei Klick außerhalb. Die seitlichen Aktionsmenüs öffnen nach rechts, damit sie keine benachbarten Bedienelemente verdecken.
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
- Favicon-/Titel-Kandidat: volle Suite `174 runs, 916 assertions, 0 failures, 0 errors`; RuboCop für die geänderten Ruby-Tests ohne Befund; unabhängiges `QA & Review`-Go.
- Favicon-/Titel-Deployment mit Merge-Commit `e442b18` erfolgreich: `web` läuft, `db` ist healthy, Startseite liefert `DB × DREI` sowie `/icon.svg`; SVG und `/up` liefern jeweils `200`.
- Sidebar-Menü-Deployment mit Merge-Commit `9f432f9` erfolgreich: volle Rails-Suite `174 runs, 916 assertions, 0 failures, 0 errors`; frischer unabhängiger Selenium-Lauf mit dem neuen fokussierten Test grün (`1 run, 6 assertions`); unabhängiges `QA & Review`-Go. `web` läuft neu, `db` ist healthy und `/up` liefert `200`.
- Board-Kopier-Deployment mit Merge-Commit `13e06a2` erfolgreich: Assetlisten werden beim Duplizieren eines Boards mit Titel und Reihenfolge übernommen, jedoch als offen angelegt. Vollständige isolierte Rails-Suite `174 runs, 918 assertions, 0 failures, 0 errors`; unabhängiges `QA & Review`-Go. `web` läuft neu, `db` ist healthy und `/up` liefert `200`. Der ausdrücklich beauftragte Abgleich kopierte je `30` offene Assetpunkte in die jeweils `9` passenden Karten von `Consideration 1`, `Consideration 2`, `Performance 1` und `Performance 2`; Titel und Reihenfolge entsprechen jeweils `Awareness`.
- Kartenübertragungs-Deployment mit Merge-Commit `068da93` erfolgreich: vollständiges Kopieren und Verschieben zwischen aktiven Boards desselben Workspaces, mit expliziter Zielspalte. Kopien enthalten Kartenattribute, Tags, Assetliste samt Status, Kommentare, Zitate und Kommentar-Bilder; Agentzustände und alte Aktivitäten werden nicht übertragen. Vollständige isolierte Rails-Suite `179 runs, 958 assertions, 0 failures, 0 errors`; unabhängiges `QA & Review`-Go. `web` läuft neu, `db` ist healthy und `/up` liefert `200`.
- Kartenübertragungs-UX-Deployment mit Merge-Commit `1451e83` erfolgreich: Nach Kopieren oder Verschieben führt die App direkt zum Zielboard statt in die Karten-Detailansicht. Fokussierter Controller-Test `11 runs, 137 assertions` und vollständige isolierte Rails-Suite `179 runs, 958 assertions` grün; unabhängiges `QA & Review`-Go. `web` läuft neu, `db` ist healthy und `/up` liefert `200`.
- Standardspalten-Umbenennung-Deployment mit Merge-Commit `f072838` erfolgreich: `Eingang` wurde als Backlog-Spalte zu `Produktionsplan`, `Kunden-Review` als Review-Spalte zu `DREI-Review` und `Änderungen angefordert` als Blocked-Spalte zu `Korrekturen`. Neue Standard-Review-Boards erhalten diese Namen; die reversible Migration änderte nur exakt passende bisherige Standardspalten. Echter isolierter Reset sowie Up/Down-Nachweis erfolgreich; volle Suite `180 runs, 964 assertions, 0 failures, 0 errors`; unabhängiges `QA & Review`-Go. Production bestätigt jeweils sechs neue Standardspalten und keine alten Standardnamen; `web` läuft, `db` ist healthy und `/up` liefert `200`.
- Mail-Text-Deployment mit Merge-Commit `83f47ed` erfolgreich: Absendername, Betreffe und Inhalte der Einladungs- und Passwort-Reset-E-Mails lauten nun `DB × DREI` und sind auf Deutsch. Die gemeinsame Fußzeile beschreibt DB × DREI als digitales Kollaborations- und Freigabetool der Digitalbackup MW GmbH. Mailer-Tests `2 runs, 20 assertions` und volle isolierte Suite `180 runs, 974 assertions, 0 failures, 0 errors` grün; unabhängiges `QA & Review`-Go ohne Befunde. `web` läuft neu, `db` ist healthy und `/up` liefert `200`.
- Einladungsannahme-Benachrichtigung mit Merge-Commit `1823e21` erfolgreich deployt: Nach erfolgreicher Annahme einer Einladung erhält ausschließlich die einladende Person eine deutsche Mail mit dem Anzeigenamen des neuen Users. Das Einreihen erfolgt erst nach Abschluss der Datenbanktransaktion; Ausnahmen und ein stilles, falsches Queue-Ergebnis werden datensparsam geloggt und verhindern weder Account-Erstellung noch Login. Fokussierte Tests `11 runs, 48 assertions` und vollständige isolierte Suite `183 runs, 993 assertions, 0 failures, 0 errors` grün; unabhängiges `QA & Review`-Go ohne Befunde. `web` läuft neu, `db` ist healthy und `/up` liefert `200`.
- Täglicher Admin-Aktivitätsreport bereit für QA: Werktags um 07:30 Uhr `Europe/Vienna` fasst eine responsive HTML- und Text-E-Mail Kartenbewegungen sowie neue Kommentare seit dem vorigen Report zusammen; montags umfasst der Zeitraum Freitag bis Sonntag. Ohne Änderungen wird keine Mail versendet. Der Report geht ausschließlich an Admins, kürzt Kommentar-Auszüge datensparsam und ist pro Admin/Zeitraum gegen Doppelversand geschützt. Fokussierte Tests `8 runs, 39 assertions` und vollständige isolierte Suite `191 runs, 1032 assertions, 0 failures, 0 errors` grün; Schema-Reset enthält die neue Tabelle. Unabhängiges `QA & Review` steht noch aus.

## Inhaltsreset vom 2026-08-03

- Auf ausdrückliche Benutzerfreigabe wurde um 15:07 UTC zuerst ein frischer lokaler PostgreSQL-Dump erstellt.
- Danach wurden alle Arbeitsinhalte in Production transaktional gelöscht: aktive und archivierte Kampagnen, Boards, Spalten, Karten, Kommentare, Unteraufgaben, Kartenaktivitäten und Karten-Tag-Zuordnungen.
- Nachprüfung: Kampagnen, Boards, Spalten, Karten, Kommentare, Unteraufgaben, Aktivitäten und Karten-Tag-Zuordnungen jeweils `0`; keine archivierten Kampagnen, Boards oder Karten verbleiben.
- Die zwei Benutzerkonten, der gemeinsame Workspace, Rollen, Zugänge, Einstellungen, Postmark-Konfiguration und der Backup-Timer blieben unverändert. `/up` liefert anschließend `200`.

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
