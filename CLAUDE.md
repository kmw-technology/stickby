# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Build entire solution
dotnet build StickBy.sln

# Run the main API (serves both API and Blazor WASM frontend)
dotnet run --project src/StickBy.Api

# Run the Admin Web (Blazor Server)
dotnet run --project src/StickBy.Admin.Web

# Run unit tests (xUnit)
dotnet test tests/StickBy.Api.Tests

# Run E2E tests (Playwright/NUnit) - requires app running on localhost:5050
dotnet test tests/StickBy.E2E.Tests

# Run a single test
dotnet test tests/StickBy.Api.Tests --filter "FullyQualifiedName~TestMethodName"

# EF Core migrations (run from solution root)
dotnet ef migrations add MigrationName --project src/StickBy.Infrastructure --startup-project src/StickBy.Api
dotnet ef database update --project src/StickBy.Infrastructure --startup-project src/StickBy.Api
```

## Docker Development

```bash
# Start all services (PostgreSQL, API, Admin)
docker-compose -f docker-compose.dev.yml up -d

# Services:
# - postgres: localhost:5432
# - api: localhost:5050
# - admin: localhost:5051
```

## Architecture

This is a **contact sharing** application with two separate frontends:

### Project Structure
- **StickBy.Api** - Main ASP.NET Core API with JWT authentication. Hosts Blazor WASM client.
- **StickBy.Web** - Blazor WebAssembly PWA (public-facing frontend). Compiled and served by StickBy.Api.
- **StickBy.Admin.Api** - Admin API (currently scaffolded, not implemented)
- **StickBy.Admin.Web** - Admin dashboard using Blazor Server with interactive SSR
- **StickBy.Infrastructure** - EF Core DbContext, entities, and migrations (PostgreSQL via Npgsql)
- **StickBy.Shared** - Enums and DTOs shared between API and frontends

### Data Flow
The Blazor WASM frontend (StickBy.Web) communicates with the API via HTTP. The API uses services in the `Services/` folder which interact with the database through `StickByDbContext`.

### Key Entities
- **User** - ASP.NET Identity user with contacts, shares, and group memberships
- **ContactInfo** - Encrypted contact information (phone, email, etc.) owned by users
- **Share** - Shareable link containing selected contacts (token-based public access)
- **Group** - User groups for sharing contacts among members
- **GroupShare** - Contact shares within a group context

### Authentication
- JWT Bearer tokens with refresh token rotation
- Magic link support (passwordless)
- Tokens configured via `Jwt:*` settings

### Services Pattern
API services follow interface/implementation pattern:
- `IAuthService` / `AuthService` - Authentication logic
- `IContactService` / `ContactService` - Contact CRUD with encryption
- `IShareService` / `ShareService` - Share management
- `IGroupService` / `GroupService` - Group operations
- `IEncryptionService` / `EncryptionService` - AES encryption for contact values
- `IJwtService` / `JwtService` - Token generation

## Configuration

Environment variables (see `deployment/.env.example`):
- `ConnectionStrings__DefaultConnection` - PostgreSQL connection string
- `Jwt__Secret` - JWT signing key (min 32 chars)
- `Encryption__MasterKey` - Base64-encoded encryption key

## E2E Tests

Tests use Playwright with NUnit. Base URL: `http://localhost:5050`. Tests extend `TestBase` which provides helpers for registration, login, and modal interaction.
