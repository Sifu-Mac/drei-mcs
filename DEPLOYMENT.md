# Deployment

## Ziel
Deployment auf `mission.digitalbackup.cloud` hinter Traefik.

## Voraussetzungen
- Docker + Docker Compose auf dem Zielhost
- laufendes Traefik auf dem Host mit Docker-Provider
- DNS für `mission.digitalbackup.cloud` zeigt auf den Host

## Start
```bash
cp .env.production.example .env.production
# Secrets anpassen

docker compose --env-file .env.production up -d --build
```

## Wichtige Variablen
- `APP_HOST=mission.digitalbackup.cloud`
- `APP_URL=https://mission.digitalbackup.cloud`
- `SECRET_KEY_BASE=...`
- `POSTGRES_PASSWORD=...`
- `DATABASE_URL=postgresql://...`
## Hinweise
- Diese Version nutzt `SOLID_QUEUE_IN_PUMA=1` für ein schlankes Single-Web-Service-Setup.
- GitHub OAuth ist optional.

## Offene fachliche Umbauten
- Statusmodell auf MCS anpassen
- Owner-Modell für Sifu/James/Codex ergänzen
- Branding konsequent auf Mission Control umstellen
