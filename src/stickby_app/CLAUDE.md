# CLAUDE.md - StickBy Flutter App

## Overview

This is the **Flutter mobile app** for StickBy, designed to match the Razor Pages website design and connect to the same backend API.

## Architecture

```
lib/
├── main.dart              # Entry point, Provider setup
├── app.dart               # MaterialApp, auth routing
├── config/
│   └── api_config.dart    # API base URL & endpoints
├── models/                # Data models (match backend DTOs)
│   ├── user.dart
│   ├── auth_response.dart
│   ├── contact.dart       # ContactType enum, ReleaseGroup
│   ├── share.dart
│   ├── group.dart         # GroupMemberRole, GroupMemberStatus
│   └── profile.dart
├── services/
│   ├── api_service.dart   # HTTP client, all API calls
│   └── storage_service.dart  # Secure token storage
├── providers/             # State management (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── contacts_provider.dart
│   ├── groups_provider.dart
│   ├── shares_provider.dart
│   └── profile_provider.dart
├── screens/               # UI screens
│   ├── auth/              # Login, Register
│   ├── home/              # Dashboard
│   ├── contacts/          # Contact list, add contact
│   ├── groups/            # Group list, details, create
│   ├── shares/            # Share list, create share
│   ├── profile/           # Profile view, edit
│   └── main_screen.dart   # Tab navigation
├── widgets/               # Reusable components
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── avatar.dart
│   ├── contact_tile.dart
│   ├── group_card.dart
│   ├── empty_state.dart
│   └── loading_indicator.dart
└── theme/
    └── app_theme.dart     # Colors, typography (matches website)
```

## Key Design Decisions

### State Management
Uses **Provider** with ChangeNotifier pattern:
- Each domain has its own provider (auth, contacts, groups, shares, profile)
- Providers injected at app root via MultiProvider
- Screens use `context.watch<Provider>()` for reactive updates

### Authentication Flow
1. App starts → `AuthProvider.checkAuthStatus()`
2. If token exists → try refresh → authenticated or unauthenticated
3. Login/Register → save tokens to secure storage → authenticated
4. Logout → clear tokens → unauthenticated

### API Integration
- `ApiService` handles all HTTP calls
- Tokens stored via `flutter_secure_storage`
- Automatic auth header injection
- Error handling via `ApiException`

## Commands

```bash
# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows

# Run on connected Android device
flutter run

# Build APK
flutter build apk

# Build iOS (requires Mac)
flutter build ios
```

## API Connection

Connects to: `https://www.kmw-technology.de/stickby/backend`

Configured in `lib/config/api_config.dart`

## Design System

Colors match the website:
- Primary: `#2563eb` (Blue)
- Success: `#22c55e` (Green)
- Danger: `#ef4444` (Red)
- Background: `#f8fafc`
- Surface: `#ffffff`

Typography: Inter font via Google Fonts

## Dependencies

Key packages:
- `provider` - State management
- `http` - API calls
- `flutter_secure_storage` - Token storage
- `google_fonts` - Typography
- `cached_network_image` - Image caching
- `qr_flutter` - QR code generation
- `share_plus` - Native share sheet

## Features Implemented

- [x] Authentication (login, register, logout)
- [x] Contacts CRUD with category grouping
- [x] Release group visibility controls
- [x] Shares with QR codes
- [x] Groups with invitations
- [x] Profile management
- [x] Bottom tab navigation
- [x] Pull-to-refresh
- [x] Loading states
- [x] Error handling

## Testing Requirements

To test the app:
1. Install Flutter SDK
2. Run `flutter pub get`
3. Run on emulator or device
4. Register a new account or use existing credentials
5. All features connect to production backend
