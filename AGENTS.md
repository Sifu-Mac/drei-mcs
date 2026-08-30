# AGENTS.md

## Projektzweck und Architektur

DREI Asset Review (`drei-mcs`) ist eine selbst gehostete Rails-Anwendung fuer Asset-, Task- und Review-Workflows mit Agent-Integration. Die Anwendung nutzt Rails 8, PostgreSQL, Hotwire/Turbo/Stimulus, Tailwind CSS, Active Storage, Solid Queue, Solid Cable und Solid Cache.

Wichtige Architekturpunkte:
- Runtime-App: Rails-Webservice im Docker-Compose-Service `web`.
- Datenbank: PostgreSQL im Compose-Service `db`.
- Entwicklungs- und Test-Checkout auf KVM2: `/srv/drei-review` (Git-Repository,
  Branch `main`, GitHub-Remote nur lesend über einen Deploy Key).
- Production-Runtime auf KVM2: `/docker/drei-review` (kein Git-Repository;
  Compose-Artefakte und ausgerollter Quellstand).
- Production-Deployment: `docker compose --project-name drei-production
  --env-file .env.production --file docker-compose.production.yml` im
  Runtime-Ordner.
- Live-URL: `https://digital-drei.at`.
- KVM4 ist ausschließlich ein Rollback-Stand und darf bis zu seiner separaten
  Stilllegungsfreigabe weder deployed noch für Jobs oder Datenänderungen
  verwendet werden.
- Testumgebung: separater Compose-Stack `docker-compose.test.yml` mit eigenem `test-db` und `Dockerfile.test`.
- Production-Container bleibt schlank; Development-/Test-Gems gehoeren nur in das Test-Image.

## Git- und Branch-Workflow

- Hauptbranch ist `main`.
- Feature-Arbeit erfolgt auf sprechenden Branches und wird vor Merge getestet.
- Vor jedem Merge: `git status`, Diff-Review, Secret-Pruefung und passende Tests ausfuehren.
- Nach Merge in `main`: `main` zu GitHub pushen.
- Auf dem VPS kann GitHub-Push per HTTPS fehlen; dann Commit per SSH lokal holen und von lokal nach GitHub pushen.
- Unversionierte Dateien wie `backup-postgres.sh` auf dem VPS nicht anfassen, sofern nicht explizit beauftragt.
- Am Ende jeder Arbeitssession muss `docs/HANDOFF.md` aktualisiert werden, bevor ein Abschlussbericht ausgegeben wird.

## Lead-Agent-Arbeitsweise

- Der aktive Hauptagent traegt die Verantwortung als Lead Agent fuer Analyse, Planung, Koordination, Review, Merge-Reihenfolge, Gesamttests, Deployment und Abschlussbericht.
- Jede Anforderung zuerst analysieren und danach entscheiden, ob sie direkt oder mit Subagents umgesetzt wird.
- Subagents nur fuer klar getrennte, unabhaengige Teilaufgaben einsetzen.
- Kleine, zusammenhaengende oder riskante Aenderungen durch den Lead Agent selbst bearbeiten.
- Niemals mehrere Agenten gleichzeitig an denselben Dateien oder eng gekoppelten Bereichen arbeiten lassen.
- Parallele Aenderungen nur in getrennten Worktrees oder Branches ausfuehren.
- Bei groesseren Aufgaben zuerst einen verstaendlichen Plan erstellen, parallelisierbare Teile ausweisen und die Freigabe des Benutzers abwarten.
- Nach der Freigabe selbststaendig umsetzen und nur bei einem echten technischen Risiko oder einer erforderlichen fachlichen Entscheidung stoppen.
- Vor Merge und Deployment alle relevanten Tests vollstaendig ausfuehren.
- Nach erfolgreichem Merge `main` zu GitHub pushen, den Commit im KVM2-Checkout
  `/srv/drei-review` prüfen und erst nach frischem Backup sowie bestätigtem
  Rollbackpunkt gezielt in `/docker/drei-review` ausrollen. Danach ausschließlich
  die KVM2-Production prüfen.
- Reine Dokumentationsaenderungen erfordern keinen Production-Rebuild; der Healthcheck bleibt dennoch Pflicht.
- Vor jedem Abschlussbericht `docs/HANDOFF.md` aktualisieren.

## VPS- und Docker-Struktur

Nur dieses Projekt bearbeiten:
- Entwicklungs-/Test-Checkout: `/srv/drei-review`
- VPS-Runtime-Pfad: `/docker/drei-review`
- Production Compose: `docker-compose.production.yml`, Compose-Projekt
  `drei-production`
- Production Services: `web`, `db`
- Production Volumes: `drei-production_drei-production-postgres`,
  `drei-production_drei-production-storage`
- Test Compose: `docker-compose.test.yml`
- Test Services: `test`, `test-db`
- Test-Projekt: `drei-kvm2-test`; Test Volume: `drei-review-test-postgres`

Die bestehende Mission-Control-Instanz niemals veraendern. Keine Kommandos in fremden Docker-Stacks, fremden Repositories oder alten App-Pfaden ausfuehren.

## Sicherheitsregeln

- Secrets niemals committen, ausgeben oder in Dokumentation kopieren.
- `.env.production` nicht anzeigen und nicht versionieren.
- Keine echten Passwoerter, Tokens, API Keys, SMTP-Zugangsdaten oder OAuth-Secrets in Git schreiben.
- SMTP-Zugangsdaten nicht erfinden; Mailversand nur testen, wenn echte Werte bewusst bereitgestellt wurden.
- Keine Produktionsdaten veraendern, ausser die Aufgabe verlangt es explizit.
- Fuer Smoke-Tests nur temporaere Daten verwenden und danach gezielt entfernen.
- Keine bestehende Mission-Control-Instanz beruehren.

## Tests und Deployment

Vor Merge und Deployment passende Tests ausfuehren:

```bash
cd /srv/drei-review
docker compose --project-name drei-kvm2-test -f docker-compose.test.yml build test
docker compose --project-name drei-kvm2-test -f docker-compose.test.yml up --no-build --abort-on-container-exit --exit-code-from test test
```

Production pruefen:

```bash
cd /docker/drei-review
docker compose --project-name drei-production --env-file .env.production --file docker-compose.production.yml ps
curl -s -o /dev/null -w "%{http_code}" https://digital-drei.at/up
```

Production nur neu bauen, wenn Runtime-Code, Gem-Abhaengigkeiten, Assets, Dockerfile oder Compose-Konfiguration fuer Production geaendert wurden.

## Rollen, Datenmodelle und Konventionen

Bekannte Rollen und Modelle:
- `User.admin` ist die interne Admin-Berechtigung fuer Admin-Funktionen.
- `WorkspaceMembership.role`: `owner`, `member`, `client`.
- `Invite.role` uebernimmt Rollen fuer neue WorkspaceMemberships.
- `BoardColumn.kind`: `backlog`, `active`, `review`, `blocked`, `done`; sichtbare Spaltennamen sind frei editierbar.
- `Task.board_column_id` ist die Source of Truth fuer Board-Position und Completion-State.
- `Task.status` bleibt als Legacy-Spiegel fuer API-Kompatibilitaet erhalten.
- `Task.owner`: `unassigned`, `internal`, `integration`; ein neutraler Legacy-/API-Wert ohne Berechtigungslogik.
- `Task.completed`, `Task.completed_at`, `Task.blocked` und Legacy-`status` werden aus `Task.board_column.kind` synchronisiert.
- `Task.color`: `none`, `blue`, `green`, `yellow`, `orange`, `red`, `purple`, `gray`; nur visueller Akzent ohne Business-Logik.
- Task-Coverbilder und Kommentar-Bilder laufen ueber Active Storage.

Technische Konventionen:
- Business-Logik klein und lokal aendern.
- Keine Auth-, Rollen-, Invite-, Upload- oder UI-Logik beiläufig veraendern.
- Keine Tests abschwaechen oder entfernen, nur um Gruen zu erreichen.
- Dokumente aktuell halten: `AGENTS.md` fuer dauerhafte Regeln, `docs/HANDOFF.md` fuer aktuellen Projektstand.
