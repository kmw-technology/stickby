# StickBy Deployment Scripts

Unified deployment scripts for the Hetzner server. Handles **all** StickBy services:
- Backend API
- Website
- Admin Panel

## Installation (einmalig)

```bash
ssh root@kmw-technology.de
cd /opt/stickby
git pull
chmod +x deployment/scripts/*.sh
./deployment/scripts/install.sh
```

## Verwendung

Nach der Installation kann `stickby-deploy` von überall aufgerufen werden:

```bash
# Backend deployen (Standard)
stickby-deploy

# Einzelne Services deployen
stickby-deploy backend    # Backend API
stickby-deploy website    # Website (Razor Pages)
stickby-deploy admin      # Admin Panel (Blazor)

# Alle Services auf einmal
stickby-deploy all

# nginx Config aktualisieren
stickby-deploy nginx

# Status und Diagnose
stickby-deploy test       # Endpoints testen
stickby-deploy status     # Container Status anzeigen
stickby-deploy logs       # Backend Logs
stickby-deploy logs website   # Website Logs
stickby-deploy logs admin     # Admin Logs
```

## Was passiert bei einem Deployment?

### `stickby-deploy [service]`
1. `git pull` - Neueste Änderungen vom Repository
2. Alter Container wird gestoppt
3. Neues Image wird gebaut (`docker compose build`)
4. Container wird gestartet (`docker compose up -d`)
5. Container wird mit `shared-network` verbunden
6. Health Checks werden durchgeführt

### `stickby-deploy all`
1. `git pull`
2. Alle Container werden gestoppt
3. Alle Images werden neu gebaut
4. Alle Container werden gestartet
5. Endpoints werden getestet

### `stickby-deploy nginx`
1. `git pull`
2. Backup der nginx.conf
3. Config-Vollständigkeit prüfen
4. `nginx -t` testen
5. `nginx -s reload`

## Dateistruktur

```
deployment/
├── scripts/
│   ├── deploy.sh      # Haupt-Deployment-Script
│   ├── install.sh     # Einmalige Installation
│   └── README.md      # Diese Dokumentation
├── docker-compose.production.yml  # Container-Definitionen
├── .env.production                # Secrets (nur auf Server!)
├── Dockerfile.Backend             # Backend Image
├── Dockerfile.Website             # Website Image
├── Dockerfile.AdminServer         # Admin Image
└── nginx-stickby.conf             # nginx Locations
```

## Troubleshooting

### Container startet nicht
```bash
stickby-deploy logs [service]
docker logs stickby-[service] --tail 100
```

### 502 Bad Gateway
```bash
stickby-deploy status
docker network connect shared-network stickby-[service]
```

### SignalR funktioniert nicht
1. Prüfen ob `/stickby/backend/hubs/` Location in nginx konfiguriert ist
2. Prüfen ob Location VOR `/stickby/backend` steht
3. WebSocket Headers prüfen (Upgrade, Connection)

### Nach Code-Änderungen
```bash
stickby-deploy [service]   # Einfach neu deployen
```

### Alle Container neu starten
```bash
stickby-deploy all
```

## Server-Info

- **Host:** kmw-technology.de (Hetzner)
- **Projekt-Pfad:** /opt/stickby
- **nginx Config:** /opt/infrastructure/nginx.conf
- **Docker Network:** shared-network
