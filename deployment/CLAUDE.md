# CLAUDE.md - Deployment Configuration

## Overview

This folder contains all deployment-related files for the StickBy application running on a Hetzner server at `kmw-technology.de`.

## Production URLs

| Service | URL | Container |
|---------|-----|-----------|
| Website | https://kmw-technology.de/stickby/website | stickby-website |
| Backend API | https://kmw-technology.de/stickby/backend | stickby-backend |
| Admin Panel | https://kmw-technology.de/stickby/admin-panel | stickby-admin |
| Database | Internal only (port 5432) | stickby-postgres |

## File Structure

```
deployment/
├── docker-compose.production.yml  # Production container definitions
├── docker-compose.yml            # Alternative/dev compose
├── Dockerfile.Website            # Razor Pages website
├── Dockerfile.Backend            # REST API
├── Dockerfile.AdminServer        # Blazor Server admin
├── Dockerfile.Dev               # Development container
├── nginx-stickby.conf           # nginx location blocks
├── .env.production              # Production secrets (on server only!)
├── .env.production.example      # Template for secrets
├── .env.example                 # General env template
└── DEPLOY.md                    # Deployment instructions
```

## Docker Compose Services

```yaml
services:
  postgres:     # PostgreSQL database
  backend:      # StickBy.Api (REST API)
  website:      # StickBy.Web (Razor Pages)
  admin:        # StickBy.Admin.Web (Blazor Server)

networks:
  shared-network:  # External network for nginx connectivity
```

## Deployment Commands

```bash
# SSH to server
ssh root@kmw-technology.de

# Navigate to project
cd /opt/stickby

# Pull latest changes
git pull

# Rebuild specific service
cd deployment
docker compose -f docker-compose.production.yml --env-file .env.production build website
docker compose -f docker-compose.production.yml --env-file .env.production up -d website

# Rebuild all services
docker compose -f docker-compose.production.yml --env-file .env.production up -d --build

# View logs
docker logs stickby-website -f
docker logs stickby-backend -f

# Restart nginx (if config changed)
docker restart nginx
```

## Environment Variables

Required in `.env.production`:
```
POSTGRES_PASSWORD=<secure password>
JWT_SECRET=<32+ character secret>
ENCRYPTION_MASTER_KEY=<base64 encoded key>
```

## nginx Configuration

The `nginx-stickby.conf` file contains:
1. Upstream definitions for each service
2. Location blocks for path routing
3. Proxy headers for PathBase support

Add to nginx config: `include /path/to/nginx-stickby.conf;`

## PathBase Setup

Each service has PathBase configured:
- Website: `/stickby/website`
- Backend: `/stickby/backend`
- Admin: `/stickby/admin-panel`

Set via:
- `appsettings.Production.json` → `"PathBase": "/stickby/xxx"`
- Environment variable → `PathBase=/stickby/xxx`

## Container Network

All containers join `shared-network` (external):
```bash
# Create if not exists
docker network create shared-network
```

nginx connects to this network to reach the containers.

## Health Checks

Each service exposes a health endpoint:
- Backend: `GET /health` → `{"status": "healthy", ...}`
- Website: `GET /health` → `{"status": "healthy", ...}`
- Admin: `GET /health` → `{"status": "healthy", ...}`

## Troubleshooting

1. **Container won't start**: Check logs with `docker logs <container>`
2. **502 Bad Gateway**: Container not running or network issue
3. **404 Not Found**: PathBase misconfigured
4. **CSS not loading**: Check `<base href>` includes PathBase
5. **Database connection failed**: Check POSTGRES_PASSWORD in .env

## Server Info

- Host: Hetzner Cloud
- OS: Ubuntu/Debian
- Docker: Latest
- nginx: Running as container on shared-network
- SSH Key: Located at `C:\Users\jonas\Desktop\server\hetzner-kmw-technology\`
