# StickBy Backend Server Deployment Scripts

Wiederverwendbare Deployment-Skripte für den Hetzner Server.

## Erstmalige Installation

```bash
ssh root@kmw-technology.de
cd /opt/stickby
git pull
chmod +x deployment/backend-server/*.sh
./deployment/backend-server/install.sh
```

## Verwendung

Nach der Installation kann `stickby-deploy` von überall aufgerufen werden:

```bash
# Backend neu bauen und deployen (Standard)
stickby-deploy

# Nur Backend deployen
stickby-deploy backend

# Alle Services deployen
stickby-deploy all

# nginx Config aktualisieren
stickby-deploy nginx

# Endpoints testen
stickby-deploy test

# Logs anzeigen
stickby-deploy logs
```

## Was das Script macht

### `stickby-deploy backend`
1. `git pull` - Neueste Änderungen holen
2. Backend Container neu bauen
3. Backend Container starten
4. Health Check durchführen
5. Endpoints testen

### `stickby-deploy nginx`
1. `git pull` - Neueste Änderungen holen
2. Backup der aktuellen nginx.conf erstellen
3. Prüfen ob SignalR Hub Location konfiguriert ist
4. nginx Config testen und neu laden

### `stickby-deploy all`
1. `git pull` - Neueste Änderungen holen
2. Alle Container neu bauen
3. Alle Container starten
4. Endpoints testen

## Manuelle nginx Konfiguration

Falls die SignalR Hub Location fehlt, muss sie manuell hinzugefügt werden:

```bash
# Backup erstellen
cp /opt/infrastructure/nginx.conf /opt/infrastructure/nginx.conf.backup

# Config bearbeiten
nano /opt/infrastructure/nginx.conf

# Diese Location VOR /stickby/backend einfügen:
```

```nginx
# StickBy Backend API - SignalR WebSocket Hub
location /stickby/backend/hubs/ {
    proxy_pass http://stickby-backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-PathBase /stickby/backend;
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;
    proxy_socket_keepalive on;
    tcp_nodelay on;
    proxy_buffering off;
    proxy_cache off;
}
```

```bash
# Testen und neu laden
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

## Troubleshooting

### Backend startet nicht
```bash
docker logs stickby-backend --tail 50
```

### 502 Bad Gateway
```bash
docker ps | grep stickby
docker network connect shared-network stickby-backend
```

### SignalR funktioniert nicht
1. Prüfen ob `/stickby/backend/hubs/` Location in nginx konfiguriert ist
2. Prüfen ob Location VOR `/stickby/backend` steht
3. WebSocket Headers prüfen (Upgrade, Connection)
