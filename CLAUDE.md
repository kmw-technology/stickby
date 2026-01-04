# CLAUDE.md - StickBy Project Guide

This file provides comprehensive guidance to Claude Code when working with this repository.

## Project Overview

**StickBy** is a contact sharing application that allows users to:
- Store and organize personal contact information (phone, email, social media, etc.)
- Control visibility via "Release Groups" (Family, Friends, Business, Leisure)
- Share contact bundles via token-based URLs with QR codes
- Collaborate in groups with shared contacts

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION DEPLOYMENT                        │
│                    https://kmw-technology.de/stickby/                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   /website          /backend              /admin-panel              │
│   ┌──────────┐      ┌──────────┐          ┌──────────┐              │
│   │ StickBy  │ ───► │ StickBy  │ ◄─────── │ StickBy  │              │
│   │   Web    │      │   Api    │          │Admin.Web │              │
│   │ (Razor)  │      │  (REST)  │          │ (Blazor) │              │
│   └──────────┘      └────┬─────┘          └──────────┘              │
│                          │                                           │
│                     ┌────▼─────┐                                     │
│                     │PostgreSQL│                                     │
│                     │(internal)│                                     │
│                     └──────────┘                                     │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────┐      │
│   │                    Flutter Mobile App                     │      │
│   │                    (stickby_app)                         │      │
│   │         Connects to: /stickby/backend/api/               │      │
│   └──────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
stickby/
├── src/
│   ├── StickBy.Api/          # Backend REST API (JWT auth, business logic)
│   ├── StickBy.Web/          # Razor Pages frontend (SSR website)
│   ├── StickBy.Admin.Web/    # Blazor Server admin dashboard
│   ├── StickBy.Infrastructure/  # EF Core, entities, migrations
│   ├── StickBy.Shared/       # DTOs and enums shared across projects
│   └── stickby_app/          # Flutter mobile app
├── tests/
│   ├── StickBy.Api.Tests/    # xUnit unit tests
│   └── StickBy.E2E.Tests/    # Playwright/NUnit E2E tests
├── deployment/               # Docker, nginx, production configs
├── documentation/            # Additional docs
└── artifacts/                # Old code, scripts, temporary files
```

## Key Technologies

| Layer | Technology |
|-------|------------|
| Backend API | ASP.NET Core 8.0, JWT Bearer Auth |
| Website | ASP.NET Core Razor Pages |
| Admin Panel | Blazor Server (Interactive SSR) |
| Mobile App | Flutter 3.5+ with Provider |
| Database | PostgreSQL via EF Core + Npgsql |
| Deployment | Docker, nginx reverse proxy |
| Testing | xUnit, Playwright, NUnit |

## Build and Run Commands

```bash
# Build entire solution
dotnet build StickBy.sln

# Run Backend API (port 5001 locally)
dotnet run --project src/StickBy.Api

# Run Website (port 5000 locally, needs API running)
dotnet run --project src/StickBy.Web

# Run Admin Panel (port 5051)
dotnet run --project src/StickBy.Admin.Web

# Run tests
dotnet test tests/StickBy.Api.Tests          # Unit tests
dotnet test tests/StickBy.E2E.Tests          # E2E tests (requires running app)

# EF Core migrations
dotnet ef migrations add <Name> --project src/StickBy.Infrastructure --startup-project src/StickBy.Api
dotnet ef database update --project src/StickBy.Infrastructure --startup-project src/StickBy.Api

# Flutter app
cd src/stickby_app
flutter pub get
flutter run -d chrome    # Web
flutter run -d windows   # Desktop
flutter run              # Connected device
```

## Production Deployment

**URLs:**
- Website: https://kmw-technology.de/stickby/website
- API: https://kmw-technology.de/stickby/backend
- Admin: https://kmw-technology.de/stickby/admin-panel

**Deploy changes:**
```bash
# From local machine
git push origin master

# On server (/opt/stickby)
cd /opt/stickby && git pull
cd deployment
docker compose -f docker-compose.production.yml --env-file .env.production build <service>
docker compose -f docker-compose.production.yml --env-file .env.production up -d <service>

# Services: website, backend, admin, postgres
```

## API Endpoints Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login, returns JWT |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Revoke refresh token |

### Contacts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/contacts` | Get all user's contacts |
| POST | `/api/contacts` | Create contact |
| PUT | `/api/contacts/{id}` | Update contact |
| DELETE | `/api/contacts/{id}` | Delete contact |

### Shares
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/shares` | Get user's shares |
| POST | `/api/shares` | Create share |
| DELETE | `/api/shares/{id}` | Delete share |
| GET | `/api/shares/view/{token}` | View share (public) |

### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/groups` | Get user's groups |
| GET | `/api/groups/invitations` | Get pending invitations |
| POST | `/api/groups` | Create group |
| POST | `/api/groups/{id}/join` | Accept invitation |
| POST | `/api/groups/{id}/decline` | Decline invitation |
| POST | `/api/groups/{id}/leave` | Leave group |

### Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/profile` | Get user profile with contacts |
| PUT | `/api/profile` | Update profile |
| PUT | `/api/profile/release-groups/bulk` | Update release groups |

## Key Domain Concepts

### Contact Types (by category)
- **General (0-99)**: Email, Phone, Address, Website
- **Personal (100-199)**: Birthday, Nationality, Education
- **Private (200-299)**: Mobile, Emergency Contact
- **Business (300-399)**: Company, Position, Business Email/Phone
- **Social (400-499)**: Facebook, Instagram, LinkedIn, Twitter, etc.
- **Gaming (500-599)**: Steam, Discord

### Release Groups (bitmask flags)
```
None = 0, Family = 1, Friends = 2, Business = 4, Leisure = 8, All = 15
```
Used to control which groups can see specific contact info.

### Encryption
All contact values are encrypted at rest using AES-256 with user-specific keys derived from a master key.

## Important Files to Know

| File | Purpose |
|------|---------|
| `src/StickBy.Api/Program.cs` | API startup, DI, middleware |
| `src/StickBy.Api/Services/` | Business logic services |
| `src/StickBy.Web/Services/ApiService.cs` | Website → API HTTP client |
| `src/StickBy.Web/Pages/Shared/_Layout.cshtml` | Main website layout |
| `src/StickBy.Infrastructure/StickByDbContext.cs` | EF Core context |
| `deployment/docker-compose.production.yml` | Production containers |
| `deployment/.env.production` | Production secrets (on server only) |

## PathBase Configuration

All projects support reverse proxy deployment with PathBase:
- Set `PathBase` in appsettings.Production.json
- Use `~/` prefix in Razor views for links (e.g., `href="~/Auth/Login"`)
- API uses `UsePathBase()` middleware

## Common Issues & Solutions

1. **Wrong URL redirects**: Ensure links use `~/` prefix, not hardcoded `/`
2. **CSS not loading in Admin**: Check `<base href="">` in App.razor uses PathBase
3. **API 401 errors**: Check JWT token in Authorization header, may need refresh
4. **Docker network issues**: Ensure shared-network exists (`docker network create shared-network`)

## Configuration

Environment variables (set in `.env.production` or docker-compose):
```
ConnectionStrings__DefaultConnection=Host=postgres;Database=stickby;Username=stickby;Password=xxx
Jwt__Secret=<32+ char secret>
Jwt__Issuer=StickByAPI
Jwt__Audience=StickByClient
Encryption__MasterKey=<base64 key>
PathBase=/stickby/backend  # or /stickby/website
ApiBaseUrl=http://backend:8080/stickby/backend/
```
