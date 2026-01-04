# StickBy Deployment auf Hetzner Server

## Voraussetzungen

- SSH Zugang zum Server (5.9.120.221)
- `shared-network` Docker-Netzwerk existiert bereits
- nginx Container läuft

## Deployment Schritte

### 1. Projekt auf Server kopieren

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

### 5. nginx Konfiguration ergänzen

```bash
# Backup erstellen
cp /opt/infrastructure/nginx.conf /opt/infrastructure/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Konfiguration bearbeiten
nano /opt/infrastructure/nginx.conf

# Füge den Inhalt von nginx-stickby.conf ein:
# - Upstreams im http-Block
# - Locations im server-Block (vor dem Fallback)
```

### 6. nginx testen und neu laden

```bash
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

### 7. Endpoints testen

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/website/
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/backend/health
curl -s -o /dev/null -w "%{http_code}\n" https://www.kmw-technology.de/stickby/admin-panel/
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
