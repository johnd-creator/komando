# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**1Komando** is a Flutter mobile application for Serikat Pekerja PLN IP Services (PLN IP Services Union). The app manages union member profiles, dues, finance, notifications, letters, and aspirations.

**Current Status:** Early development phase - project structure is default Flutter with comprehensive API documentation available.

## Development Commands

### Essential Flutter Commands

```bash
# Install dependencies
flutter pub get

# Run the app in development mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Clean build artifacts
flutter clean
```

### Code Generation Commands

This project uses JSON serialization with code generation:

```bash
# Generate JSON serialization code
flutter pub run build_runner build

# Generate JSON serialization code (clean and rebuild)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate automatically
flutter pub run build_runner watch
```

## Architecture

### API Integration

The app connects to a REST API with comprehensive documentation in `docs/mobile-v1.md`.

**Production API Base URL:** `https://anggota.plnipservices.or.id/api/mobile/v1`

**Authentication:** Bearer token stored in secure storage

**Standard HTTP Client:** Dio (recommended in API docs)

**Standard State Management:** Bloc (recommended in API docs)

### Key Features & API Endpoints

**Authentication:**
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout  
- `GET /me` - Get current user info

**Member Profile:**
- `GET /profile` - Get member profile
- `GET /member/card` - Get KTA digital card
- `GET /member/card/qr` - Get QR code image
- `GET /member/card/pdf` - Download KTA as PDF

**Finance (Role-Based Access):**
- `GET /finance/dashboard` - Finance summary
- `GET /finance/ledgers` - List transactions
- `GET /finance/units` - Get accessible units
- Role hierarchy: `bendahara` (own unit + pusat) → `bendahara_pusat` (all units)

**Other Features:**
- `GET /notifications` - List notifications
- `GET /letters/inbox` - Inbox letters
- `GET /aspirations` - Member aspirations
- `POST /aspirations` - Create aspiration

### Role-Based Access Control

**Important:** Finance endpoints use hierarchical visibility rules:

| Role | Access Level |
|------|-------------|
| `bendahara` | Own unit + Pusat unit only |
| `bendahara_pusat` | All units |
| `admin_unit`, `pengurus` | Own unit (read-only) |
| `admin_pusat`, `pengurus_pusat` | All units (read-only) |
| `super_admin` | All units (full access) |

## Project Structure

Currently minimal (default Flutter structure):
```
lib/
├── main.dart          # App entry point (default Flutter code)
```

**Recommended structure** (from API docs):
```
lib/
├── main.dart
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   ├── models/
│   │   └── screens/
│   ├── profile/
│   ├── finance/
│   └── notifications/
├── core/
│   ├── api/
│   │   ├── dio_client.dart
│   │   └── interceptors.dart
│   ├── models/
│   └── utils/
└── l10n/              # Localization
```

## Implementation Guidelines

### API Client Setup

Use Dio with interceptors for authentication and error handling:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  headers: {'Accept': 'application/json'},
));

// Add bearer token from secure storage
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
));
```

### JSON Serialization

Use `json_annotation` and `json_serializable` packages:

```dart
@JsonSerializable()
class User {
  final int id;
  final String name;
  @JsonKey(name: 'current_unit_id')
  final int? currentUnitId;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Error Handling

Handle common HTTP status codes:
- `401` - Navigate to login
- `403` - Show access denied message
- `422` - Show validation errors
- `429` - Show rate limit message
- `500` - Show server error with retry option

### State Management Pattern

Use Bloc pattern with event/state classes:

```dart
// Event
abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}

// State
abstract class AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Implementation
}
```

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## Dependencies Management

```bash
# Add dependency
flutter pub add <package_name>

# Add dev dependency
flutter pub add --dev <package_name>

# Upgrade dependencies
flutter pub upgrade

# Check for outdated dependencies
flutter pub outdated
```

## Important Notes

1. **Security:** Never store access tokens in SharedPreferences. Use `flutter_secure_storage`.
2. **API First:** Comprehensive API documentation is available in `docs/mobile-v1.md` - always refer to it for endpoint specifications.
3. **Role-Based UI:** Adapt UI based on user role, especially for finance features.
4. **Offline Support:** Consider offline functionality for critical features.
5. **Localization:** The app appears to be Indonesian-language focused.

## Reference Documentation

- **API Documentation:** `docs/mobile-v1.md` - Comprehensive API reference with Flutter implementation examples
- **Flutter Documentation:** https://flutter.dev/docs
- **Dart Documentation:** https://dart.dev/guides