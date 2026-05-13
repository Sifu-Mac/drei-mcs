# MCS Build Log

## Zweck
Kurzes laufendes Protokoll für den Umbau von ClawDeck zu Mission Control System (MCS).

---

## 2026-05-13

### Zielbild festgelegt
- ClawDeck wird zu einem selbstgehosteten **Mission Control System** für Zusammenarbeit zwischen **Sifu, James, Codex**.
- Mehrere getrennte Projekte müssen unterstützt werden.
- Deployment-Ziel: `mission.digitalbackup.cloud`
- VPS-Hardening bewusst **verschoben**, später als MCS-Task.

### Planung erstellt
- `docs/planning/MCS_GAP_ANALYSIS.md`
- `docs/planning/MCS_IMPLEMENTATION_PLAN.md`

### Repo und Basisimport
- privates GitHub-Repo erstellt:
  - `https://github.com/Sifu-Mac/mission-control-system`
- ClawDeck als Basis importiert und lokal für MCS angepasst.

### Docker-Deployment gebaut
Angelegt / angepasst:
- `Dockerfile`
- `docker-compose.yml`
- `docker/entrypoint-web.sh`
- `.env.production.example`
- `DEPLOYMENT.md`

### Self-hosting / Production-Patches
Angepasst:
- `app/helpers/application_helper.rb`
- `config/environments/production.rb`
- `app/controllers/api/v1/tasks_controller.rb`
- `app/mailers/application_mailer.rb`
- `app/views/layouts/landing.html.erb`

### Hostinger-/Traefik-Anpassung
Entscheidungen:
- Traefik läuft mit `network_mode: host`
- kein shared external Docker network
- Routing über Traefik-Labels
- kein Host-Port-Binding für den MCS-Web-Container

### Build-Fix
- Docker-Build auf Production gesetzt
- Fix für Fehler:
  - `LoadError: cannot load such file -- debug/prelude`

Commit:
- `f04227d` — `Set production env during Docker build`

### Deployment auf VPS
Pfad:
- `/docker/mission-control-system`

Ergebnis:
- App live auf `https://mission.digitalbackup.cloud`
- Healthcheck erfolgreich (`HTTP/2 200`)

### Sicherheitslage festgestellt, aber bewusst nicht verändert
Festgehalten:
- kein neuer öffentlicher Host-Port durch MCS
- `ufw` inaktiv
- `iptables INPUT policy ACCEPT`
- weitere öffentliche/listening Ports vorhanden

Wichtig:
- vorerst **nichts ändern**
- später als MCS-Arbeit erfassen

---

## Produktumbau Phase 1: Branding

### ClawDeck → Mission Control
Sichtbares Branding umgestellt:
- Layout-Titel
- Meta-/PWA-Namen
- Navbar
- Auth-Seiten
- Landingpage-Texte
- Profil-/Integrationscopy
- Admin-Titel

GitHub-Links umgestellt auf:
- `https://github.com/Sifu-Mac/mission-control-system`

Commit:
- `427519c` — `Rebrand UI from ClawDeck to Mission Control`

### Root direkt auf Login
- Landingpage bleibt vorhanden, aber Root zeigt direkt auf Login.

Commit:
- `839fea5` — `Send root path directly to sign-in`

---

## Produktumbau Phase 2: Workflow-Modell

### Neues Statusmodell
Eingebaut:
- `Inbox`
- `Planned`
- `Ready`
- `In Progress`
- `Blocked`
- `Review`
- `Done`

Migration alter Stati:
- `up_next` → `ready`
- `in_review` → `review`
- blockierte Tasks → `blocked`

### Owner-Modell
Eingebaut:
- `Sifu`
- `James`
- `Codex`

Umfang:
- Task-Modell
- Board-UI
- Task-Panel
- New-Task-Modal
- API
- Agent-Workflow
- Activity-Texte

Commit:
- `ad9239a` — `Add MCS workflow statuses and task owners`

---

## Produktumbau Phase 3: Kommentare

### Echte Kommentare pro Task
Eingebaut:
- neue `task_comments` Tabelle
- Kommentare im Task-Panel
- Kommentare schreiben + anzeigen
- erstmal bewusst ohne Edit/Delete

Commit:
- `ed7fec6` — `Add task comments to task panel`

---

## Bewusste Nicht-Entscheidungen

### Definition of Done
Aktuell **nicht eingebaut**.

Grund:
- Board hat bereits `Done`
- erst echte Nutzung testen
- nicht unnötig mit Feldern aufblasen

### Task-Type-System
Aktuell **noch nicht eingebaut**.

Grund:
- wahrscheinlich erstmal zu viel
- Priorität liegt eher auf echter Nutzbarkeit

---

## Nächste sinnvolle Schritte
1. Account anlegen und echtes UI testen
2. Status / Owner / Kommentare im echten Flow prüfen
3. Owner sichtbarer machen, falls nötig
4. Kommentar-UI nachschärfen, falls nötig
5. später optional kleines Type-Set
6. später MCS-Task für VPS-Hardening anlegen
7. später Repo-Pulls auf VPS via SSH Deploy Key sauberer machen
