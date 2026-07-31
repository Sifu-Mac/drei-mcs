# DREI Asset Review

Technischer Projektname: `drei-mcs`

DREI Asset Review ist eine selbst gehostete Rails-Anwendung fuer Projekt-, Task- und Asset-Review-Workflows mit Agent-Integration.

## Aktueller Stand

- Produktbranding ist auf `DREI Asset Review` ausgerichtet.
- Deployment ist fuer `mission.digitalbackup.cloud` mit Docker, PostgreSQL und Traefik vorbereitet.
- Planungsdokumente liegen unter `docs/planning/`.

## Schnellstart

1. `.env.production.example` nach `.env.production` kopieren
2. Secrets setzen
3. Docker-/Traefik-Stack starten

```bash
cp .env.production.example .env.production
docker compose --env-file .env.production up -d --build
```

## Tests

Der Test-Stack verwendet den festen Compose-Projektnamen
`drei-review-test` und ausschließlich das Volume
`drei-review-test-postgres`. Dadurch bleiben seine Container, sein Netzwerk
und seine Datenbank vom Production-Stack getrennt.

```bash
docker compose -f docker-compose.test.yml build test
docker compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test test
```

Die Production-Konfiguration verwendet eine physische PostgreSQL-Datenbank
für `primary`, `cache`, `queue` und `cable`. Migrationen werden ausschließlich
über `primary` aus `db/migrate` verwaltet; dort liegen auch die Migrationen für
Solid Cache, Solid Queue und Solid Cable.

## Lokale Entwicklung

### Voraussetzungen

- Ruby 3.3.1
- PostgreSQL
- Bundler

### Setup

```bash
git clone https://github.com/Sifu-Mac/drei-mcs.git
cd drei-mcs
bundle install
bin/rails db:prepare
bin/dev
```

Die lokale App laeuft standardmaessig unter `http://localhost:3000`.

## Features

- Kanban Boards fuer Aufgaben ueber mehrere Boards
- Agent Assignment mit sichtbarem Fortschritt
- Activity Feed fuer laufende Updates
- REST API fuer Agent-Integrationen
- Hotwire-basierte Echtzeit-UI

## Authentifizierung

DREI Asset Review unterstuetzt zwei Authentifizierungsarten:

1. Email/Passwort
2. GitHub OAuth optional fuer Production

### GitHub OAuth

1. GitHub Developer Settings oeffnen
2. Eine neue OAuth App anlegen
3. Werte setzen:
   - Application name: `DREI Asset Review`
   - Homepage URL: eigene Domain
   - Authorization callback URL: `https://yourdomain.com/auth/github/callback`
4. Credentials in der Umgebung setzen:

```bash
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

## API

DREI Asset Review stellt eine REST API fuer Agent-Integrationen bereit. Den API Token findest du in den Settings.

### Authentifizierung

```http
Authorization: Bearer YOUR_TOKEN
X-Agent-Name: Maxie
X-Agent-Emoji: fox
```

### Boards

```http
GET /api/v1/boards
GET /api/v1/boards/:id
POST /api/v1/boards
PATCH /api/v1/boards/:id
DELETE /api/v1/boards/:id
```

### Tasks

```http
GET /api/v1/tasks
GET /api/v1/tasks?board_id=1
GET /api/v1/tasks?status=in_progress
GET /api/v1/tasks?assigned=true
POST /api/v1/tasks
PATCH /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
PATCH /api/v1/tasks/:id/complete
PATCH /api/v1/tasks/:id/assign
PATCH /api/v1/tasks/:id/unassign
```

## Tests

```bash
bin/rails test
bin/rails test:system
bin/rubocop
```

## Wichtige Dateien

- `docker-compose.yml`
- `Dockerfile`
- `.env.production.example`
- `docs/AGENT_INTEGRATION.md`
- `docs/planning/`

## Lizenz

MIT License, siehe `LICENSE`.
