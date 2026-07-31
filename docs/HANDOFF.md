# HANDOFF.md

Stand: 2026-07-31

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `codex/postmark-transactional-email`
- Verbindliche Basis: `main` / `origin/main` auf `abd3e4a Document QA remediation deployment`
- Deployter Runtime-/Merge-Commit: `f3c90d8 Merge QA remediation`
- SMTP-Feature-Commit auf dem aktuellen `main`: `b6f031a Harden Postmark transactional email delivery`.
- SMTP-Job-Test und Handoff-Aktualisierung liegen in einem separaten zweiten Feature-Commit.
- Die SMTP-Aenderungen sind noch nicht nach `main` gemergt, nicht zu GitHub gepusht und nicht deployt.
- `backup-postgres.sh` bleibt bewusst unversioniert und wurde nicht beruehrt.

## QA-Sanierungsstand (gemergt und deployt)

- Integrationsbranch: `codex/qa-remediation-integration`
- Freigegebener Integrationsstand: `2816365 Clarify migration reset metadata`
- Der unabhaengige Thread `QA & Review` hat nach der Nachpruefung der From-scratch-Migrationen und des gefilterten Drag-and-drop ausdruecklich Go erteilt.
- Merge nach `main`, GitHub-Push und Production-Deployment erfolgten am 2026-07-31 mit Runtime-Commit `f3c90d8`.

Auf dem Integrationsbranch umgesetzt:
- Verwundbare Ruby-Abhaengigkeiten aktualisiert; Rails/Active Storage `8.1.3.1`, Rack `3.2.6`, Puma `8.0.2`, Nokogiri `1.19.4`, OAuth2 `2.0.25`, JWT `3.2.0`, `action_text-trix` `2.1.19` sowie weitere Advisory-Fixes.
- Alle bisherigen `bundler-audit`-Ausnahmen entfernt.
- Task-Panel-Auto-Save fuer Titel, Beschreibung, Prioritaet, Owner und Farbe repariert; Saves werden serialisiert und Fehler sichtbar behandelt.
- Aenderungen von `BoardColumn.kind` synchronisieren enthaltene Tasks atomar inklusive archivierter Karten.
- Client-Task-Panel als echte Read-only-/Kommentaransicht umgesetzt; zusaetzliche Agent- und API-Mutationsluecken geschlossen.
- Drag-and-drop atomar gemacht und um DOM-/Zaehler-Rollback, Race-Schutz und sichtbare Fehlerbehandlung ergaenzt.
- Drag-and-drop ist bei aktivem Tag-Filter bewusst deaktiviert; UI und Server verhindern damit unvollstaendige Reihenfolgen aus einer gefilterten Teilmenge.
- Bild-Uploads pruefen echte Dateiinhalte, MIME-Uebereinstimmung, Groesse, Defekte und Kommentar-Bildanzahl; ungueltige neue Blobs werden bereinigt.
- Brakeman-Mass-Assignment-Befunde beseitigt und OAuth-Invite-only-Abdeckung erweitert.
- Test-Compose ueber projektabhaengige Namen und Volumes vollstaendig von Production und parallelen Testlaeufen getrennt.
- Production-Single-DB-Migrationskonfiguration bereinigt; `primary` ist die einzige Quelle fuer Datenbanktasks.
- Chromium/ChromeDriver und echte JavaScript-Systemtests fuer Auto-Save, Client-Panel/Kommentar und Drag-and-drop-Fehlerrollback hinzugefuegt.
- Isoliertes PostgreSQL-Restore-Runbook, Restore-Compose und Verifikationsskript hinzugefuegt.

Verifikation auf dem vollstaendigen Integrationsstand:
- Frisch gebautes Testimage: erfolgreich.
- Vollstaendige Rails-Suite: `144 runs, 702 assertions, 0 failures, 0 errors, 0 skips`.
- JavaScript-Systemtests separat: `5 runs, 27 assertions, 0 failures, 0 errors, 0 skips`.
- RuboCop: `167 files inspected, no offenses`.
- Brakeman: `0 errors`, `0 security warnings`.
- `bundler-audit` mit Advisory-DB-Commit `99b6a95`: keine Schwachstellen.
- Importmap-Audit: keine verwundbaren Pakete.
- Echter From-scratch-Lauf per `db:migrate:reset`: alle `61` Repository-Migrationen erfolgreich und `up`. Unmittelbar nach dem Reset kann Rails zusaetzlich den internen `schema_migrations`-Wert `0` als `000 NO FILE` anzeigen; er gehoert zu keiner Repository-Migrationsdatei, blockiert den Lauf nicht und war nach dem anschliessenden Test-Prepare nicht mehr vorhanden.
- Separat benanntes Production-Pruefimage inklusive Asset-Precompile: erfolgreich und ohne Docker-Secret-Warnung gebaut; nicht deployt und danach entfernt.
- Isolierter Restore des vorhandenen Dumps: Import erfolgreich, aktuelle Migrationen erfolgreich, `36` Tabellen, `61` Repository-Migrationen, `8/8` Kerntabellen; temporaere Container, Images, Netzwerke und Volumes entfernt.
- Diff-/Secret-Pruefung: keine versehentlich aufgenommenen Secret-, Dump- oder ENV-Dateien.
- Production nach dem Deployment: `db` healthy, `web` running, `/up` liefert `200`; alle aktuellen Repository-Migrationen sind `up`.
- Der Production-Migrationsstatus enthaelt weiterhin den historischen Eintrag `20260222000001 NO FILE` aus der frueheren separaten Cache-Datenbankkonfiguration. Die abloesende Primary-Migration `20260222100002` ist `up`; der Alt-Eintrag war bereits vorhanden und blockiert weder Start noch Migration.

## SMTP-/Postmark-Kandidat (noch nicht gemergt oder deployt)

- `digitalbackup.at` ist in Postmark fuer DKIM und Return-Path verifiziert.
- Der transaktionale Message Stream ist `outbound`; SMTP-Zugriff und ein eigener streamgebundener SMTP-Token wurden eingerichtet.
- SMTP-Zugangsdaten und der verifizierte Absender sind ausschliesslich in der unversionierten `.env.production` hinterlegt; die Werte wurden weder ausgegeben noch dokumentiert.
- Ein waehrend der Einrichtung in einem Screenshot sichtbar gewordener Postmark Server API Token wurde unmittelbar erneuert und nicht fuer die Rails-Konfiguration verwendet.
- Der Postmark-Account befindet sich noch im Testmodus und kann derzeit nur an Empfaenger auf verifizierten eigenen Domains senden.
- Production nutzt nach dem Merge `smtp.postmarkapp.com` auf Port `587`, STARTTLS, TLS-Zertifikatspruefung sowie begrenzte Verbindungs- und Lese-Timeouts.
- Transaktionale Mails laufen ueber die dedizierte Solid-Queue-Queue `mailers`. Temporaere Verbindungs-/SMTP-Fehler werden begrenzt wiederholt; Fehlerlogs enthalten nur Job-ID und Fehlerklasse, weder Empfaenger noch Mailinhalt.
- Invite- und Passwort-Reset-Links werden in Production explizit mit `https` erzeugt.
- Die Invite-UI meldet korrekt, dass eine Mail zum Versand eingereiht wurde, statt eine bereits erfolgte Zustellung zu behaupten.
- Mailer-Tests decken Absender, Empfaenger und HTTPS-Links fuer Invite und Passwort-Reset ab.
- Ein separat benanntes, nicht deploytes Production-Pruefimage inklusive Asset-Precompile wurde auf dem kombinierten SMTP-/QA-Stand erfolgreich gebaut.
- Es wurde noch keine echte Testmail, Passwort-Reset-Mail oder Einladung versendet.

## Laufende Container und Services

Production-Stack in `/docker/drei-review`:
- `drei-review-db-1`: Service `db`, running, healthy
- `drei-review-web-1`: Service `web`, running
- Healthcheck: `https://drei.digitalbackup.cloud/up` liefert `200`
- Zuletzt erneut verifiziert am 2026-07-31 nach Deployment von `f3c90d8`: `db` healthy, `web` running, Production-Healthcheck `200`.

Test-Stack:
- `docker-compose.test.yml` definiert `test-db` und `test`.
- Testdatenbank ist getrennt von Production: `drei_mcs_test`.
- Test-Container verwendet keine `.env.production` und keine Production-Secrets.
- Die vom abschliessenden unabhaengigen QA-Lauf hinterlassenen Testcontainer und das zugehoerige isolierte Testvolume wurden nach dem Deployment gezielt entfernt.

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
- Ergebnis nach allen QA-Fixes mit frisch und ohne Cache gebautem Test-Image: `144 runs, 702 assertions, 0 failures, 0 errors, 0 skips`
- Ergebnis auf dem rebasierten SMTP-/Postmark-Kandidaten mit eigenem isoliertem Compose-Projekt: `147 runs, 712 assertions, 0 failures, 0 errors, 0 skips`

Fokussierte QA-Regressionslaeufe:
- Invite-, Passwort-Mailer-, Delivery-Job- und Admin-Invite-Tests auf dem SMTP-Kandidaten: `9 runs, 34 assertions, 0 failures, 0 errors, 0 skips`
- Selenium-Systemtests fuer Auto-Save, Client-Berechtigungen sowie gefiltertes und ungefiltertes Drag-and-drop: `5 runs, 27 assertions, 0 failures, 0 errors, 0 skips`
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
- Vollstaendige Rails-Test-Suite lauffaehig; deployter QA-Stand: `144 runs, 702 assertions, 0 failures, 0 errors, 0 skips`.
- Production-QA mit echtem Headless Chromium abgeschlossen; alle 21 finalen Pruefpunkte bestanden.

## 2. Aktuell offen

### SMTP und Postmark

- Postmark-Account ist eingerichtet.
- `digitalbackup.at` ist DKIM-verifiziert; der Return-Path ist verifiziert.
- SMTP-Zugangsdaten sind sicher in `.env.production` hinterlegt; keine Werte befinden sich im Repository oder in der Dokumentation.
- Der SMTP-Code ist auf `codex/postmark-transactional-email` review-bereit, aber noch nicht gemergt oder deployt.
- Der Postmark-Account ist noch im Testmodus; externe, nicht verifizierte Empfaengerdomains sind noch gesperrt.
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
- Der projektspezifische PostgreSQL-Restore-Ablauf ist dokumentiert und wurde im isolierten Restore-Stack erfolgreich verifiziert.
- Automatisierte Offsite-Backups sind noch nicht eingerichtet.

### Unversionierte Serverdateien

- `backup-postgres.sh` bleibt bewusst unversioniert.
- `.env.production` bleibt unversioniert.
- Aktuell ist nur `backup-postgres.sh` im Git-Worktree unversioniert; `git stash list` ist leer.
- Bei Bedarf spaeter pruefen, ob ausserhalb des aktuellen Git-Status bekannte lokale Dubletten bereinigt werden sollen.
- Niemals Secrets, Datenbank-Dumps oder Backups in Git uebernehmen.

## 3. Als Naechstes

Empfohlene Reihenfolge:

1. SMTP-Feature-Branch reviewen und nach Freigabe in `main` mergen.
2. `main` zu GitHub pushen und den Runtime-Code deployen.
3. Production-Healthcheck, Solid Queue und Mailer-Konfiguration ohne Versand pruefen.
4. Testmail, Passwort-Reset und Testeinladung ausschliesslich an eigene Adressen auf der verifizierten Domain senden.
5. Links, Postmark Activity und Rails-/Queue-Logs pruefen; temporaere Testeinladung gezielt entfernen.
6. Postmark-Accountfreigabe fuer externe Empfaengerdomains abschliessen.
7. Temporaeren Client-Benutzer ueber den Invite-Flow anlegen.
8. Vollstaendigen Admin- und Client-Smoke-Test durchfuehren.
9. Temporaeren Test-Client anschliessend vollstaendig entfernen.
10. Erst danach kontrolliert echte DREI-Nutzer und DREI-Kunden einladen.

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

- SMTP-Konfiguration bleibt vollstaendig ENV-basiert; `.env.production` ist unversioniert.
- Alle erwarteten SMTP-ENV-Werte sind gesetzt, wurden aber nicht ausgegeben oder dokumentiert.
- SMTP-Haertung, HTTPS-Mail-Links, dedizierte Mail-Queue, Retry und datensparsames Fehlerlogging liegen review-bereit auf `codex/postmark-transactional-email`.
- Vollstaendige kombinierte Rails-Suite: `147 runs, 712 assertions, 0 failures, 0 errors, 0 skips`; fokussierte Mailer-/Job-/Invite-Tests: `9 runs, 34 assertions, 0 failures, 0 errors, 0 skips`; RuboCop: `170 files inspected, no offenses`.
- Der Code ist noch nicht gemergt oder deployt.
- Keine echte Testmail und keine echte Einladung wurden versendet.

## Backup-Status

- Auf dem VPS existiert bewusst unversioniert `backup-postgres.sh`; es wurde nicht veraendert.
- `drei-review-backup.timer` ist aktiviert und wartet auf den naechsten taeglichen Lauf um `03:30 UTC`.
- Der letzte verifizierte automatische Lauf am 2026-07-30 um `03:30 UTC` endete erfolgreich.
- Das Skript behaelt die letzten 14 Backups; am 2026-07-30 waren zwei komprimierte Dumps vorhanden.
- Der projektspezifische Restore-Ablauf ist dokumentiert und isoliert erfolgreich getestet.
- Bestehende Production-Daten wurden nicht exportiert.
- Production-Daten wurden nur durch die notwendigen Kampagnen-/Board- und dynamische-Spalten-Migrationen veraendert.
