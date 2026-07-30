# HANDOFF.md

Stand: 2026-07-30

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `main`
- Repository-Stand vor dieser Handoff-Aktualisierung: `1847dae Add maintained project roadmap`
- Deployter Code-Commit: `e8fab25 Merge PWA icon fix`
- Aktuelle QA-Fix-Commits: `2a94ffe Fix production QA issues`, `642bdda Fix PWA icon links`
- VPS-Git-Status nach Deployment: `main...origin/main`, nur `backup-postgres.sh` ist unversioniert und unberuehrt.

## Laufende Container und Services

Production-Stack in `/docker/drei-review`:
- `drei-review-db-1`: Service `db`, running, healthy
- `drei-review-web-1`: Service `web`, running
- Healthcheck: `https://drei.digitalbackup.cloud/up` liefert `200`
- Zuletzt erneut verifiziert am 2026-07-30: `db` healthy, `web` running, Production-Healthcheck `200`.

Test-Stack:
- `docker-compose.test.yml` definiert `test-db` und `test`.
- Testdatenbank ist getrennt von Production: `drei_mcs_test`.
- Test-Container verwendet keine `.env.production` und keine Production-Secrets.
- Test-Stack wurde nach der letzten Ausfuehrung gestoppt; das gemeinsame Compose-Netz blieb wegen laufender Production-Container erhalten.

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
- Dynamische Board-Spalten (`BoardColumn`) ersetzen fest codierte Kanban-Spalten.
- Board-Vorlagen vorhanden: `Standard Review` und `Einfach`.
- Interne Nutzer koennen Spalten erstellen, umbenennen, verschieben, die Spaltenart aendern und leere Spalten loeschen.
- Clients koennen Boards/Karten lesen und kommentieren, aber keine Spalten-, Struktur- oder Kartenmutationen ausfuehren.
- Karten haben ein internes Drei-Punkte-Menue fuer Bearbeiten, Duplizieren, Archivieren und Loeschen.
- Karten koennen archiviert und aus einer Archivansicht wiederhergestellt werden.
- Kartenfarbe ist als dezenter visueller Akzent verfuegbar.
- Kanban-Karten sind kompakt, zeigen keine Coverbild-Vorschau und begrenzen Titel auf drei Zeilen; Coverbilder bleiben in Detailansichten erhalten.
- Board-UI-Interaktionen repariert: ganze Kartenflaeche oeffnet das Task-Panel, Drag-and-drop loest keinen Kartenklick aus, Karten- und Spaltenmenues werden per portaled/fixed Dropdown angezeigt und nicht mehr von Spalten-Overflow abgeschnitten.
- Spaltenlayout ist grosszuegiger: Desktop-Spaltenbreite `320px`, Spaltenabstand `16px`, Karten-Innenabstand ca. `16px`, Kartenabstand `12px`, Spaltentitel `18px`, Kartentitel `15.5px`.
- Spaltenbearbeitung ist im Dropdown standardmaessig geschlossen; Formular erscheint erst nach Auswahl von `Spalte umbenennen` oder `Spaltenart aendern`.
- Sichtbare Board-/Task-/Kommentar-/Navigations-Texte wurden auf Deutsch umgestellt.
- Portalisierte Spaltenmenues behalten ihre Aktions-/Edit-Ziele; `Spalte umbenennen` und `Spaltenart aendern` oeffnen wieder das Formular.
- Kampagnen- und Board-Settings-Modals nutzen eine gemeinsame Stimulus-Steuerung mit Escape-, Backdrop- und Fokusbehandlung.
- API-Tokens sind standardmaessig maskiert und koennen bewusst angezeigt, verborgen, kopiert oder neu erzeugt werden.
- Kartenduplizierung bleibt per Turbo Stream im Board, fuegt die Kopie sofort ein, aktualisiert den Zaehler und oeffnet das Task-Panel; das HTML-Fallback leitet zum Board.
- Leere Inline-Kartentitel zeigen eine deutsche Validierungsrueckmeldung und behalten den Fokus.
- Settings-, Profil-, Admin-, Benutzer- und Invite-Oberflaechen wurden konsistent deutsch lokalisiert.
- Das PWA-Manifest referenziert die vorhandenen Icons; der Browser-404 fuer `/icon.png` ist behoben.

## Wichtige technische Entscheidungen

- Production-Image bleibt ohne Development-/Test-Gems.
- Rails-Tests laufen in separatem `Dockerfile.test`/`docker-compose.test.yml`.
- SMTP ist nur ENV-basiert konfiguriert; keine Zugangsdaten im Repo.
- `User.admin` steuert interne Admin-Rechte; `WorkspaceMembership.role` steuert Workspace-Rollen.
- Bestehende Rollen-/Autorisierungshelfer wurden erweitert; keine parallele Policy-Schicht wurde eingefuehrt.
- Clients koennen Kampagnen, Boards, Karten und Kommentare sehen, aber Kampagnen-/Board-/Spalten-/Kartenstruktur nicht serverseitig mutieren.
- Kampagnen, Boards und Karten werden ueber `archived_at` archiviert; normale Ansichten blenden archivierte Datensaetze aus.
- `BoardColumn.kind` ist die technische Bedeutung der Spalte; der sichtbare Spaltenname ist frei editierbar.
- `Task.board_column_id` ist die Source of Truth fuer Boardposition, Completion und Blocked-State.
- `Task.status` bleibt als Legacy-Spiegel fuer API-Kompatibilitaet erhalten und wird aus `BoardColumn.kind` synchronisiert.
- API-Status-Parameter werden weiterhin akzeptiert und auf passende `BoardColumn.kind`-Spalten gemappt.
- Stabile Datenbank-IDs sind DOM-/Route-/Turbo-Basis; Namen werden nicht als technische IDs genutzt.
- Dropdowns in scrollbaren Board-Containern nutzen den bestehenden Stimulus-`dropdown_controller` mit Portal in `document.body`, fixed Positionierung, Viewport-Clamping und Upward-Flip bei wenig Platz nach unten.
- Ursache der nicht klickbaren Karten: Die Karte hatte nur einen kleinen Titellink; Drag-/Menuelemente und `overflow-hidden`-Container erzeugten eine fragile Klickflaeche. Zusaetzlich blockierte ein undefiniertes `status_labels` im Task-Panel den direkten Turbo-Frame-Aufruf mit 500.
- Production-Deployment erfolgt ausschliesslich im Stack `/docker/drei-review`.

## Migrationen

Neue Migrationen im deployten Stand:
- `20260730130000_create_campaigns.rb`
- `20260730130100_add_campaign_and_archived_at_to_boards.rb`
- `20260730160000_create_board_columns.rb`
- `20260730160100_add_dynamic_columns_to_tasks.rb`

Production-Migrationsstatus:
- `campaigns` wurde angelegt.
- `boards.campaign_id` und `boards.archived_at` wurden ergaenzt.
- Bestehende Boards wurden der Kampagne `Allgemein` zugeordnet.
- `board_columns` wurde angelegt.
- `tasks.board_column_id`, `tasks.color` und `tasks.archived_at` wurden ergaenzt.
- Bestehende Tasks wurden passenden BoardColumns zugeordnet; keine Tasks ohne Spalte.
- Production-Datencheck: 3 Kampagnen, 5 Boards, 25 BoardColumns, 16 Tasks, 0 Tasks ohne BoardColumn, 0 archivierte Tasks.

## Aktuelle Testresultate

Letzte vollstaendige Suite im isolierten Test-Stack:
- Befehl: `docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test`
- Ergebnis nach allen QA- und PWA-Fixes mit neu gebautem Test-Image: `109 runs, 417 assertions, 0 failures, 0 errors, 0 skips`

Fokussierte QA-Regressionslaeufe:
- Board-, Task-, Profil- und Admin-Lokalisierungstests: `23 runs, 151 assertions, 0 failures, 0 errors, 0 skips`
- PWA-Manifest: `2 runs, 8 assertions, 0 failures, 0 errors, 0 skips`
- RuboCop fuer alle geaenderten Ruby-Dateien: keine Verstoesse.

Production-Smoke:
- `docker compose --env-file .env.production ps`: `db` healthy, `web` running.
- `/up`: `200`.
- Public Root: `200`.
- Echter Chromium/Selenium-Smoke: alle 21 Pruefpunkte bestanden, einschliesslich Kartenduplizierung, Modal-/Dropdown-Bedienung, Token-Maskierung, Lokalisierung, Responsive-Verhalten und fehlerfreier Browserkonsole.
- Oeffentliche Registrierung: kein sichtbarer Registrierungsmarker im Public-Smoke.
- Produktionsdaten: 1 interner Benutzer, 0 Client-Mitgliedschaften.
- Client-UI konnte ohne Datenanlage nicht manuell eingeloggt werden. Server-Blockierung fuer Clients ist testabgedeckt.


## Letzter Browser-QA-Stand

Umfassender Browser-QA-Lauf und Wiederholung nach Deployment gegen `https://drei.digitalbackup.cloud` am 2026-07-30 mit isoliertem Headless-Chromium/Selenium-Fallback, weil `Browser Use` in der Sitzung nicht als Tool verfuegbar war. Fuer mutierende Flows wurde nach ausdruecklicher Freigabe ein temporaerer Admin-/Owner-Benutzer verwendet. Der Benutzer, seine Sessions, API-Tokens und alle erzeugten `CODEX-QA-*`-Karten wurden danach geloescht; die Bereinigung wurde mit 0 verbleibenden QA-Benutzern und 0 QA-Karten verifiziert. Das temporaere Browser-Image und der Test-Stack wurden ebenfalls entfernt.

Geprueft:
- Public Login, fehlende oeffentliche Registrierung, Passwort-Reset-Link und Login-Redirect.
- Boardansicht, komplette Kartenflaeche, Kartenmenue, Kartenanlage, Kartenkopie, Task-Panel, Spaltenmenue und Kampagnenmodal.
- Direkte Seiten und interne Links fuer `/boards`, `/settings`, `/admin`, `/admin/users`, `/admin/invites`, Task-Detailrouten und `/boards/:id/tasks/archived`.
- Archiv-Leerzustand und leere Inline-Karteneingabe.
- Responsive Viewports `1280x800`, `1024x768`, `768x1024`, `390x844` und `360x800`.
- Sichtbarkeit des API-Tokens, Sprachkonsistenz und Browserkonsole.

Nach den Fixes bestanden:
- Login, alle geprueften internen Links und Direktseiten funktionieren ohne sichtbaren HTTP-/Routing-/Application-Fehler.
- Ganze Kartenflaeche oeffnet das Task-Panel; `Karte bearbeiten` oeffnet die Kopie ebenfalls im Modal.
- Kartenkopie bleibt auf dem Board, erscheint ohne Reload und oeffnet direkt das Task-Panel der Kopie.
- Kampagnenmodal schliesst per Escape und Backdrop.
- Portalisierte Spaltenbearbeitung oeffnet sichtbar im Dropdown.
- API-Token ist initial maskiert und nur nach expliziter Aktion sichtbar.
- Leere Inline-Karteneingabe zeigt eine sichtbare Fehlermeldung.
- Settings, Admin, Benutzer und Einladungen sind konsistent deutsch.
- Archivseite zeigt den korrekten Leerzustand.
- Kein Body-Level-Horizontaloverflow in den final geprueften Viewports `1280x800`, `768x1024`, `390x844` und `360x800`.
- Keine Browser-Konsolenfehler im Lauf.

Behobene Befunde:
- P1: Portalisierte Spaltenbearbeitung war nicht sichtbar.
- P1: Kampagnenmodal schloss nicht per Escape.
- P1: API-Token war standardmaessig im Klartext sichtbar.
- P1/P2: Kartenkopie navigierte aus dem Board und wirkte dadurch defekt.
- P2: Admin-, Settings-, Profil- und Invite-Texte waren teilweise Englisch.
- P2: Leere Inline-Karteneingabe hatte keine sichtbare Rueckmeldung.
- P2: Das PWA-Manifest verursachte wiederholte `/icon.png`-404 in der Browserkonsole.

# Roadmap

## 1. Abgeschlossen

Repository, Betrieb und Arbeitsgrundlage:
- Privates GitHub-Repository `Sifu-Mac/drei-mcs` erstellt und die urspruengliche Mission-Control-Codebasis unabhaengig geforkt.
- Branding auf `DREI Asset Review` angepasst.
- Isoliertes Single-Tenant-Deployment unter `/docker/drei-review` und Live-Domain `https://drei.digitalbackup.cloud` eingerichtet.
- Eigener Docker-Stack `drei-review`, eigene PostgreSQL-Datenbank und persistentes Active-Storage-Volume eingerichtet.
- HTTPS ueber das bestehende Traefik-Setup eingerichtet.
- Automatische taegliche PostgreSQL-Backups per aktivem Systemd-Timer eingerichtet; letzter verifizierter Lauf am 2026-07-30 erfolgreich.
- Aufbewahrung der letzten 14 lokalen Backups im Backup-Skript konfiguriert.
- `AGENTS.md` und `docs/HANDOFF.md` als dauerhafte Arbeits- und Uebergabedokumentation eingerichtet.
- Lead-Agent-Arbeitsweise mit Regeln fuer Planung, Subagents, getrennte Worktrees, Review, Tests, Merge und Deployment dauerhaft in `AGENTS.md` verankert.
- SSH-Zugriff vom Mac zum VPS und Codex CLI auf dem VPS eingerichtet.
- VPS per SSH mit GitHub verbunden; direkte Commits und Pushes vom VPS funktionieren.

Authentifizierung und Rollen:
- Invite-only Auth und Admin-Einladungsverwaltung umgesetzt; oeffentliche Registrierung entfernt.
- Rolle `client` eingefuehrt; Client-Mutationen werden serverseitig blockiert.
- Login und Passwort-Reset erhalten.

Oberflaeche und Assets:
- Helles DREI-UI mit blauem Akzent und deutsche sichtbare Benutzeroberflaeche umgesetzt.
- Task-Coverbilder und mehrere Bild-Uploads in Kommentaren umgesetzt.
- Board-UI grosszuegiger und lesbarer gestaltet; Karten vollstaendig klickbar gemacht.
- Dropdowns und Popovers mit Portal-/Viewport-Positionierung repariert.
- Task-Panel-Fehler behoben.

Kampagnen, Boards, Spalten und Karten:
- Kampagnenmodell und Struktur `Kampagne -> Boards -> Karten` umgesetzt.
- Bestehende Boards verlustfrei der Standardkampagne `Allgemein` zugeordnet.
- Kampagnen koennen dupliziert, archiviert und wiederhergestellt werden.
- Boards koennen dupliziert und archiviert werden.
- Dynamische Board-Spalten mit den Arten `backlog`, `active`, `review`, `blocked` und `done` umgesetzt.
- Spalten koennen hinzugefuegt, umbenannt, sortiert und leer geloescht werden.
- Bestehende Tasks wurden verlustfrei auf dynamische Spalten migriert.
- Karten sind per Drag-and-drop zwischen Spalten verschiebbar.
- Drei-Punkte-Menue sowie Bearbeiten, Duplizieren, Archivieren und Loeschen fuer Karten umgesetzt.
- Optionale Kartenfarben umgesetzt.
- Bekannter Task-Completion-Bug und die beim Browser-QA gefundenen P1/P2-Fehler behoben.

Qualitaet:
- Isolierte Docker-Testumgebung eingerichtet.
- Vollstaendige Rails-Test-Suite lauffaehig; letzter Stand: `109 runs, 417 assertions, 0 failures, 0 errors, 0 skips`.
- Production-QA mit echtem Headless Chromium abgeschlossen; alle 21 finalen Pruefpunkte bestanden.

## 2. Aktuell offen

### SMTP und Postmark

- Postmark-Account ist eingerichtet.
- `digitalbackup.at` ist DKIM-verifiziert; der Return-Path ist verifiziert.
- SMTP-Zugangsdaten sind noch nicht in `.env.production` hinterlegt; alle erwarteten SMTP-Variablen fehlen aktuell.
- Action Mailer wurde noch nicht mit echtem Versand getestet.
- Test-Einladung an eine eigene interne E-Mail-Adresse ist noch offen.
- Keine echten DREI-Kunden einladen, bevor Testmail und Testeinladung erfolgreich waren.

### Client-Test

- Aktuell ist kein dauerhafter Production-Client-Benutzer vorhanden.
- Client-Ansicht vollstaendig manuell im Browser testen.
- Pruefen, dass Clients nur lesen und kommentieren koennen.
- Pruefen, dass Kommentar-Bilduploads fuer Clients funktionieren.
- Pruefen, dass keine internen Aktionen im HTML erscheinen.
- Mutierende Requests muessen weiterhin serverseitig blockiert bleiben.

### Browser-Smoke

- Drag-and-drop im echten Browser manuell pruefen.
- Karten- und Spaltenmenues am oberen und unteren Viewport-Rand sowie Dropdown-Flipping pruefen.
- Laptop- und Tablet-Breite manuell pruefen.
- Ein Board mit vielen Spalten und vielen Karten pruefen.

### Backup und Restore

- Der taegliche Backup-Timer ist aktiv; der letzte verifizierte Lauf war erfolgreich.
- Zwei lokale Backup-Dateien waren am 2026-07-30 vorhanden; die konfigurierte Aufbewahrung behaelt maximal 14.
- Einen projektspezifischen PostgreSQL-Restore-Ablauf dokumentieren und mit einem isolierten Test-Stack verifizieren. Dieser Punkt ist entgegen einer frueheren Annahme noch nicht abgeschlossen.
- Automatisierte Offsite-Backups sind noch nicht eingerichtet.

### Unversionierte Serverdateien

- `backup-postgres.sh` bleibt bewusst unversioniert.
- `.env.production` bleibt unversioniert.
- Aktuell ist nur `backup-postgres.sh` im Git-Worktree unversioniert; `git stash list` ist leer.
- Bei Bedarf spaeter pruefen, ob ausserhalb des aktuellen Git-Status bekannte lokale Dubletten bereinigt werden sollen.
- Niemals Secrets, Datenbank-Dumps oder Backups in Git uebernehmen.

## 3. Als Naechstes

Empfohlene Reihenfolge:

1. SMTP/Postmark produktiv konfigurieren.
2. Testmail und Testeinladung an eine eigene interne Adresse senden.
3. Temporaeren Client-Benutzer ueber den Invite-Flow anlegen.
4. Vollstaendigen Admin- und Client-Smoke-Test durchfuehren.
5. Temporaeren Test-Client anschliessend vollstaendig entfernen.
6. UI-/UX-Fehler aus dem manuellen Test sammeln.
7. Einen gebuendelten UI-/UX-Feinschliff umsetzen.
8. Rollout-Checkliste fuer echte DREI-Nutzer durchfuehren.
9. Erste echte interne Einladungen senden.
10. Danach kontrolliert DREI-Kunden einladen.

## 4. Spaeter geplant

Folgende Erweiterungen sind spaeter oder optional:
- Benachrichtigungen bei neuen Kommentaren; interne Nutzer benachrichtigen, den Autor selbst nicht.
- Clients standardmaessig nicht als E-Mail-Empfaenger behandeln.
- Granularere Board-, Kampagnen- oder Kartenfreigaben, falls nicht alle Inhalte sichtbar sein sollen.
- Suche ueber Kampagnen, Boards und Karten.
- Filter nach Kartenfarbe, Spalte, Kampagne und Statusart.
- Aktivitaetsprotokoll weiter ausbauen.
- Freigabe- und Korrekturschleifen expliziter abbilden.
- CSV-Import einer Produktionsplanung und automatisches Erstellen von Kampagnen, Boards und Karten.
- Optionale Asset-Metadaten wie Format, Kanal, Sujet und Funnel.
- Dashboard mit offenen Reviews, blockierten Karten und Freigaben.
- Automatisierte Offsite-Backups zusaetzlich zu lokalen VPS-Backups.
- Monitoring und Fehlerbenachrichtigungen.
- Wiederverwendbare Deployment-Vorlage und eigenes isoliertes Deployment je weiterem Kunden.

## 5. Offene fachliche Entscheidungen

- Sind innerhalb eines Kunden-Deployments immer alle Kampagnen und Boards fuer alle Clients sichtbar?
- Werden spaeter feinere Board-, Kampagnen- oder Kartenfreigaben benoetigt?
- Welche Kartenfarben sollen verbindlich welchen Asset-Typen entsprechen?
- Soll es feste Asset-Typen zusaetzlich zur freien Kartenfarbe geben?
- Welche Metadaten muessen aus zukuenftigen Produktionslisten uebernommen werden?
- Wie soll der Freigabestatus fachlich benannt und ausgewertet werden?
- Sollen archivierte Karten, Boards und Kampagnen zentral durchsuchbar sein?
- Welche E-Mail-Benachrichtigungen sollen interne Benutzer und Clients erhalten?
- Soll Postmark pro Kunden-Deployment einen eigenen Server oder Message Stream bekommen?
- Welche Daten muessen bei Kampagnen- oder Board-Duplikaten zusaetzlich uebernommen werden?

## 6. Arbeitsregeln fuer kommende Sessions

- Jede neue Session beginnt mit dem vollstaendigen Lesen von `AGENTS.md` und `docs/HANDOFF.md`.
- Vor groesseren Aenderungen zuerst einen Plan erstellen und die Freigabe abwarten.
- Jede Funktion auf einem eigenen, sprechenden Branch entwickeln.
- Keine parallelen Agenten an denselben Dateien oder stark gekoppelten Bereichen arbeiten lassen.
- Vor Merge und Deployment die vollstaendige passende Testsuite ausfuehren.
- Keine Secrets committen, ausgeben oder dokumentieren.
- Die bestehende Mission-Control-Instanz niemals veraendern.
- Nur Ressourcen unter `/docker/drei-review` bearbeiten.
- Nach erfolgreichem Merge `main` zu GitHub pushen.
- Danach das VPS-Deployment und den Production-Healthcheck durchfuehren; reine Dokumentationsaenderungen benoetigen keinen Rebuild.
- Vor jedem Abschlussbericht `docs/HANDOFF.md` aktualisieren.
- Erledigte Roadmap-Punkte aus offenen Bereichen entfernen und nach `Abgeschlossen` verschieben.
- Das Handoff muss immer den tatsaechlichen Stand wiedergeben, nicht nur den geplanten Stand.

## Wichtige Dateien und Pfade

- `AGENTS.md`: dauerhafte Arbeitsregeln fuer Agenten.
- `docs/HANDOFF.md`: aktueller Projektstand; nach jeder abgeschlossenen Arbeitssession aktualisieren.
- `app/models/campaign.rb`: Kampagnenmodell.
- `app/models/board.rb`: Board-Zuordnung zu Kampagnen, Archivierung, Duplizierung inklusive Spaltenkopie.
- `app/models/board_column.rb`: dynamische Board-Spalten und Vorlagen.
- `app/models/task.rb`: Kartenmodell mit BoardColumn-Source-of-Truth, Legacy-Status-Spiegel, Archivierung und Farbe.
- `app/controllers/campaigns_controller.rb`: Kampagnenaktionen.
- `app/controllers/boards_controller.rb`: Boardaktionen, kampagnenbasierte Navigation und Spalten-Board-Rendering.
- `app/controllers/board_columns_controller.rb`: Spaltenverwaltung.
- `app/controllers/boards/tasks_controller.rb`: Kartenaktionen, Archivierung, Duplizierung, Farbe und interne Mutationsrechte.
- `app/controllers/api/v1/tasks_controller.rb`: API-Kompatibilitaet fuer Legacy-Status und neue BoardColumn-Felder.
- `app/views/boards/_sidebar.html.erb`: linke Kampagnen-/Board-Navigation.
- `app/views/boards/_column.html.erb`: dynamische Spaltenansicht und Spaltenaktionen.
- `app/views/boards/tasks/_task_card.html.erb`: kompakte Karte mit Farbakzent und internem Menue.
- `app/javascript/controllers/dropdown_controller.js`: portaled/fixed Dropdowns fuer Board-Menues.
- `app/javascript/controllers/task_card_controller.js`: ganze Kartenflaeche oeffnet Task-Panel und ignoriert Menues/Drag/Formulare.
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

- Auf dem VPS existiert bewusst unversioniert `backup-postgres.sh`; es wurde nicht veraendert.
- `drei-review-backup.timer` ist aktiviert und wartet auf den naechsten taeglichen Lauf um `03:30 UTC`.
- Der letzte verifizierte automatische Lauf am 2026-07-30 um `03:30 UTC` endete erfolgreich.
- Das Skript behaelt die letzten 14 Backups; am 2026-07-30 waren zwei komprimierte Dumps vorhanden.
- Ein projektspezifischer Restore-Ablauf ist noch zu dokumentieren und isoliert zu testen.
- Bestehende Production-Daten wurden nicht exportiert.
- Production-Daten wurden nur durch die notwendigen Kampagnen-/Board- und dynamische-Spalten-Migrationen veraendert.
