# StickBy Deployment auf Hetzner Server

## Voraussetzungen

- SSH Zugang zum Server (5.9.120.221 / kmw-technology.de)
- `shared-network` Docker-Netzwerk existiert bereits
- nginx Container läuft

## Quick Deploy (nur Backend neu bauen)

```bash
# Einloggen und deployen
ssh root@kmw-technology.de
cd /opt/stickby && git pull
cd deployment
docker compose -f docker-compose.production.yml --env-file .env.production build backend
docker compose -f docker-compose.production.yml --env-file .env.production up -d backend
docker logs stickby-backend --tail 20
```

## Quick Deploy (alle Services)

```bash
ssh root@kmw-technology.de
cd /opt/stickby && git pull
cd deployment
docker compose -f docker-compose.production.yml --env-file .env.production up -d --build
```

---

## Vollständige Deployment Schritte

### 1. Projekt auf Server kopieren (nur bei Erstinstallation)

```bash
# Vom lokalen Rechner aus:
scp -r C:\Users\jonas\Desktop\projects\stickby root@5.9.120.221:/opt/stickby
```

### 2. Auf Server einloggen

```bash
ssh root@5.9.120.221
cd /opt/stickby/deployment
```

### 3. Environment-Datei erstellen

```bash
cp .env.production.example .env.production
nano .env.production
# Echte Passwörter und Secrets eintragen!
```

### 4. Container bauen und starten

```bash
docker compose -f docker-compose.production.yml --env-file .env.production build
docker compose -f docker-compose.production.yml --env-file .env.production up -d
```

### 5. nginx Konfiguration aktualisieren

Die nginx Config ist in `deployment/nginx-stickby.conf` versioniert.
Bei Änderungen (z.B. neue SignalR Hubs) muss sie auf dem Server aktualisiert werden:

```bash
# Backup erstellen
cp /opt/infrastructure/nginx.conf /opt/infrastructure/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# nginx-stickby.conf anzeigen (als Referenz)
cat /opt/stickby/deployment/nginx-stickby.conf

# Konfiguration bearbeiten und Locations aktualisieren
nano /opt/infrastructure/nginx.conf

# WICHTIG: Diese Locations müssen vorhanden sein:
# - /stickby/website           (Razor Pages)
# - /stickby/backend/hubs/     (SignalR WebSocket - VOR /stickby/backend!)
# - /stickby/backend           (REST API)
# - /stickby/admin-panel/_blazor (Blazor SignalR)
# - /stickby/admin-panel       (Blazor Server)
```

### 6. nginx testen und neu laden

```bash
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

### 7. Endpoints testen

```bash
# Basis-Endpoints
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/website/
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/backend/health
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/admin-panel/

# Demo Sync API
curl -s https://www.kmw-technology.de/stickby/backend/api/demo/identities

# SignalR Hub (sollte 400 zurückgeben - erwartet WebSocket)
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/backend/hubs/demosync
```

## URLs

| Service | URL |
|---------|-----|
| Website | https://kmw-technology.de/stickby/website |
| Backend API | https://kmw-technology.de/stickby/backend |
| Admin Panel | https://kmw-technology.de/stickby/admin-panel |

## Container verwalten

```bash
# Status prüfen
docker ps | grep stickby

# Logs anzeigen
docker logs stickby-website --tail 50
docker logs stickby-backend --tail 50
docker logs stickby-admin --tail 50

# Neustarten
docker restart stickby-website stickby-backend stickby-admin

# Stoppen
docker compose -f docker-compose.production.yml down

# Neu bauen (nach Code-Änderungen)
docker compose -f docker-compose.production.yml --env-file .env.production build --no-cache
docker compose -f docker-compose.production.yml --env-file .env.production up -d
```

## Troubleshooting

### 502 Bad Gateway
- Container läuft nicht: `docker ps | grep stickby`
- Container nicht im shared-network: `docker network connect shared-network stickby-website`

### Datenbank-Verbindung
- PostgreSQL Container prüfen: `docker logs stickby-postgres`
- Connection String in docker-compose.production.yml prüfen
