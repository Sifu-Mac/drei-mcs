# HANDOFF.md

Stand: 2026-07-30

## Aktueller Stand

- Repository: `Sifu-Mac/drei-mcs`
- VPS-Projektpfad: `/docker/drei-review`
- Live-URL: `https://drei.digitalbackup.cloud`
- Aktueller Branch: `main`
- Deployter Code-Commit: `bf05416 Merge task panel board UI fix`
- Feature-Commits: `b6d2287 Fix board UI interactions`, `73a11d5 Fix task panel status label`
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
- Ergebnis nach Board-UI-Fix mit neu gebautem Test-Image: `102 runs, 347 assertions, 0 failures, 0 errors, 0 skips`

Fokussierte Board-UI-/Task-Tests:
- `test/controllers/boards_controller_test.rb test/controllers/boards_tasks_controller_test.rb`: `10 runs, 42 assertions, 0 failures, 0 errors, 0 skips`
- Task-Panel-Regressionslauf: `4 runs, 18 assertions, 0 failures, 0 errors, 0 skips`

Production-Smoke:
- `docker compose --env-file .env.production ps`: `db` healthy, `web` running.
- `/up`: `200`.
- Public Root: `200`.
- Admin-HTTP-Smoke: Boardseite `200`, Task-Panel per `Turbo-Frame: task_panel` `200`, Kartencontroller vorhanden, Portal-Menues vorhanden, Karten-/Spaltenaktionen fuer Admin sichtbar, `md:w-[320px]` und Drei-Zeilen-Clamp im HTML vorhanden.
- Oeffentliche Registrierung: kein sichtbarer Registrierungsmarker im Public-Smoke.
- Produktionsdaten: 1 interner Benutzer, 0 Client-Mitgliedschaften.
- Client-UI konnte ohne Datenanlage nicht manuell eingeloggt werden. Server-Blockierung fuer Clients ist testabgedeckt.

## Offene Fehler

- Keine offenen Testfehler bekannt.
- SMTP-Werte sind weiterhin nicht gesetzt; Compose gibt entsprechende Warnungen aus.
- Kein Production-Client-Benutzer vorhanden, daher keine manuelle Client-Smoke-Pruefung ohne Datenanlage.
- Direkt nach dem finalen Container-Recreate lieferte `/up` einmal kurz `502`; nach Puma-Start lieferte `/up` wieder `200`.
- Kein echter Browser-Drag-and-drop-Smoke wurde gegen Production automatisiert; serverseitige/HTML-Vertraege und Task-Panel-Aufruf sind geprueft.

## Offene Aufgaben nach Prioritaet

1. Einen echten Client-Testzugang ueber den Invite-Flow anlegen und die Client-Ansicht manuell pruefen.
2. SMTP/Postmark sauber konfigurieren und mit echten ENV-Werten testen, ohne Secrets zu dokumentieren.
3. Invite-Mailversand nach SMTP-Konfiguration mit nicht-produktiver Testadresse pruefen.
4. Backup-Strategie fuer `/docker/drei-review` dokumentieren und verifizieren.
5. Dynamische Board-Spalten in einem echten Admin-Browser-Flow pruefen: Spalte erstellen, umbenennen, verschieben, leere Spalte loeschen.
6. Browser-Smoke fuer Drag-and-drop und Dropdown-Flipping mit Maus/Trackpad gegen Production nachholen.
7. Lokale unversionierte Dubletten-Dateien pruefen und bereinigen, falls sie nicht gebraucht werden.

## Naechster konkreter Arbeitsschritt

Browser-Smoke fuer Kartenklick, Menueoeffnung, Drag-and-drop und Dropdown-Flipping mit einem internen Testnutzer durchfuehren; danach Client-Testzugang per Invite-Flow erstellen und Client-Ansicht validieren.

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

- Auf dem VPS existiert unversioniert `backup-postgres.sh`; Inhalt und Einsatzstatus wurden nicht veraendert.
- Kein verifizierter aktueller Backup-Lauf dokumentiert.
- Bestehende Production-Daten wurden nicht exportiert.
- Production-Daten wurden nur durch die notwendigen Kampagnen-/Board- und dynamische-Spalten-Migrationen veraendert.
