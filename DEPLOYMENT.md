# Deployment

## Ziel
Deployment auf der kundenspezifischen Domain hinter einem HTTPS-Proxy.

## Voraussetzungen
- Docker + Docker Compose auf dem Zielhost
- laufendes Traefik auf dem Host mit Docker-Provider
- DNS für die kundenspezifische Domain zeigt auf den Host

## Start
```bash
cp .env.production.example .env.production
# Secrets anpassen

docker compose --env-file .env.production up -d --build
```

## Wichtige Variablen
- `APP_HOST=<kunden-domain>`
- `APP_URL=https://<kunden-domain>`
- `SECRET_KEY_BASE=...`
- `POSTGRES_PASSWORD=...`
- `DATABASE_URL=postgresql://...`
## Hinweise
- Diese Version nutzt `SOLID_QUEUE_IN_PUMA=1` für ein schlankes Single-Web-Service-Setup.
- Zugang erfolgt ausschliesslich über Einladungen und E-Mail/Passwort.
- Die MIT-Lizenz der ursprünglichen ClawDeck-Basis bleibt im Repository erhalten.
