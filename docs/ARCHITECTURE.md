# Architecture Documentation

## System Overview

**1Komando** is a Flutter mobile application for managing Serikat Pekerja PLN IP Services (PLN IP Services Union). The application follows a layered architecture pattern with clear separation of concerns.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Screens   │  │    Widgets   │  │   Blocs      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Repositories│ │  Use Cases   │  │  Models      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  API Client  │  │   Local DB   │  │ Secure Store │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Architecture Layers

### 1. Presentation Layer

**Responsibilities:**
- UI rendering and user interaction
- State management using Bloc pattern
- Navigation and routing
- User input validation and display

**Components:**
- **Screens**: Full-screen composables (e.g., `LoginScreen`, `DashboardScreen`)
- **Widgets**: Reusable UI components (e.g., `FinanceCard`, `NotificationItem`)
- **Blocs**: State management for features (e.g., `AuthBloc`, `FinanceBloc`)
- **Events**: User interactions and system events
- **States**: UI states derived from business logic

**File Organization:**
```
lib/features/
├── auth/
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── widgets/
│   │   │   └── login_form.dart
│   │   └── bloc/
│   │       ├── auth_bloc.dart
│   │       ├── auth_event.dart
│   │       └── auth_state.dart
```

### 2. Business Logic Layer

**Responsibilities:**
- Domain models and business rules
- Data transformation and validation
- Coordination between data sources
- Business use case implementation

**Components:**
- **Repositories**: Abstract data access interfaces
- **Use Cases**: Encapsulated business logic
- **Domain Models**: Core business entities
- **Mappers**: Data transformation between layers

**File Organization:**
```
lib/features/
├── finance/
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── finance_repository.dart
│   │   ├── entities/
│   │   │   └── finance_ledger.dart
│   │   └── usecases/
│   │       └── get_finance_dashboard.dart
```

### 3. Data Layer

**Responsibilities:**
- API communication
- Local data persistence
- Caching strategies
- Secure data storage

**Components:**
- **API Client**: HTTP client with Dio
- **Data Sources**: Remote and local data implementations
- **DTOs**: Data transfer objects for API serialization
- **Secure Storage**: Encrypted token storage

**File Organization:**
```
lib/features/
├── profile/
│   ├── data/
│   │   ├── repositories/
│   │   │   └── profile_repository_impl.dart
│   │   ├── datasources/
│   │   │   ├── profile_remote_datasource.dart
│   │   │   └── profile_local_datasource.dart
│   │   └── models/
│   │       └── member_model.dart
```

## State Management

### Bloc Pattern

The application uses the **Bloc (Business Logic Component)** pattern for state management.

**Key Principles:**
- **Unidirectional Data Flow**: Events → Bloc → State → UI
- **Immutable States**: All state changes create new state objects
- **Reactive**: UI reacts to state changes using `BlocBuilder`
- **Testable**: Business logic separated from UI

**Bloc Structure:**
```dart
// Event
abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}

// State
abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final User user;
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.call(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}
```

**Bloc Conventions:**
- Events use present tense: `AuthLoginRequested`
- States use past/adjective tense: `AuthAuthenticated`, `AuthLoading`
- Bloc methods use private functions: `_onLoginRequested`
- All bloc events and states extend `Equatable` for value equality

## API Client Architecture

### Dio Configuration

**Base Setup:**
```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
));
```

**Authentication Interceptor:**
```dart
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await secureStorage.delete(key: 'access_token');
      // Navigate to login
    }
    handler.next(err);
  }
}
```

**Error Handling:**
```dart
class ApiErrorHandler {
  static String getMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa koneksi internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      case DioExceptionType.badResponse:
        return _handleErrorResponse(error.response?.statusCode);
      default:
        return 'Terjadi kesalahan tidak terduga.';
    }
  }

  static String _handleErrorResponse(int? statusCode) {
    switch (statusCode) {
      case 401:
        return 'Sesi telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses ke fitur ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 422:
        return 'Data yang dikirim tidak valid.';
      case 429:
        return 'Terlalu banyak permintaan. Coba lagi nanti.';
      case 500:
        return 'Terjadi kesalahan server. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan.';
    }
  }
}
```

## Security Model

### Authentication Flow

**Login Sequence:**
1. User enters credentials
2. Call `POST /auth/login` with email, password, device_name
3. Store `access_token` in secure storage
4. Update Dio interceptor with token
5. Navigate to authenticated screens

**Session Management:**
- **Token Storage**: `flutter_secure_storage` for encrypted storage
- **Auto-Login**: Check for stored token on app launch
- **Token Refresh**: Currently not implemented (tokens are long-lived)
- **Logout**: Call `POST /auth/logout` and clear local storage

### Role-Based Access Control (RBAC)

**Role Hierarchy:**
```
super_admin (All access)
    ↓
admin_pusat, pengurus_pusat (All units read-only)
    ↓
bendahara_pusat (All units finance access)
    ↓
bendahara (Own unit + Pusat unit finance access)
    ↓
admin_unit, pengurus (Own unit read-only)
    ↓
anggota (Basic member access)
```

**Access Control Implementation:**
```dart
class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final Role? role;

  bool get isBendahara => role?.name == 'bendahara';
  bool get isBendaharaPusat => role?.name == 'bendahara_pusat';
  bool get canViewGlobal => isBendaharaPusat || role?.name == 'super_admin';
  bool get canAccessFinance => isBendahara || isBendaharaPusat ||
                               role?.name == 'admin_pusat' ||
                               role?.name == 'pengurus_pusat';
}
```

**Finance Access Rules:**
- `bendahara`: Can only access own unit + Pusat unit
- `bendahara_pusat`: Can access all units
- `admin_unit`, `pengurus`: Read-only access to own unit
- `admin_pusat`, `pengurus_pusat`: Read-only access to all units
- `super_admin`: Full access to all units

### Data Security

**Sensitive Data Handling:**
- **Access Tokens**: Stored in `flutter_secure_storage`
- **User Credentials**: Never stored, only used for authentication
- **Personal Data**: Encrypted at rest using platform secure storage
- **API Communication**: HTTPS only with certificate pinning (future enhancement)

## Folder Structure Standards

### Recommended Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Cross-cutting concerns
│   ├── api/
│   │   ├── dio_client.dart     # Dio configuration
│   │   ├── api_interceptor.dart # Auth/refresh interceptors
│   │   └── error_handler.dart  # Centralized error handling
│   ├── constants/
│   │   ├── api_constants.dart  # API endpoints
│   │   ├── app_constants.dart  # App-wide constants
│   │   └── storage_keys.dart   # Storage key constants
│   ├── error/
│   │   ├── exceptions.dart     # Custom exceptions
│   │   └── failures.dart       # Failure types
│   ├── network/
│   │   └── network_info.dart   # Network connectivity
│   ├── security/
│   │   └── secure_storage.dart # Secure storage wrapper
│   ├── theme/
│   │   ├── app_theme.dart      # App theming
│   │   └── colors.dart         # Color constants
│   └── utils/
│       ├── validators.dart     # Input validators
│       └── formatters.dart     # Data formatters
├── features/                    # Feature-based organization
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── screens/
│   │       └── widgets/
│   ├── profile/
│   ├── finance/
│   ├── notifications/
│   ├── letters/
│   └── aspirations/
└── l10n/                       # Internationalization
    └── app_localizations.dart
```

### File Naming Conventions

- **Files**: `snake_case.dart` (e.g., `login_screen.dart`)
- **Classes**: `PascalCase` (e.g., `LoginScreen`, `AuthBloc`)
- **Variables/Methods**: `camelCase` (e.g., `getUserData()`)
- **Constants**: `camelCase` with `k` prefix (e.g., `kApiBaseUrl`)
- **Private members**: Prefix with `_` (e.g., `_privateMethod()`)

### Import Organization

```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Core imports
import '../../../../core/api/dio_client.dart';
import '../../../../core/error/failures.dart';

// 5. Feature imports
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
```

## Key Architectural Decisions

### Why Bloc Pattern?

**Rationale:**
- **Separation of Concerns**: Business logic separated from UI
- **Testability**: Easy to unit test business logic
- **Reactive**: Automatic UI updates on state changes
- **Debugging**: Clear event→state flow for debugging
- **Scalability**: Handles complex state management scenarios

### Why Dio for HTTP Client?

**Rationale:**
- **Interceptors**: Built-in support for request/response interception
- **Error Handling**: Comprehensive error types and handling
- **File Upload**: Native support for multipart/form-data
- **Timeout Control**: Granular timeout configuration
- **Cancellation**: Request cancellation support

### Why Feature-First Organization?

**Rationale:**
- **Modularity**: Features are self-contained and independent
- **Onboarding**: Easier for new developers to understand
- **Maintenance**: Changes are scoped to specific features
- **Testing**: Feature-specific tests are easier to organize
- **Code Reuse**: Clear boundaries for reusable components

### Why Clean Architecture Layers?

**Rationale:**
- **Testability**: Business logic independent of frameworks
- **Independence**: UI changes don't affect business logic
- **Scalability**: Easy to add new data sources or features
- **Maintainability**: Clear separation of concerns

## Technology Stack

### Core Framework
- **Flutter**: ^3.10.4 (UI framework)
- **Dart**: ^3.10.4 (programming language)

### State Management
- **flutter_bloc**: ^8.1.0 (State management)
- **bloc**: ^8.1.0 (Core bloc library)
- **equatable**: ^2.0.5 (Value equality)

### Networking
- **dio**: ^5.4.0 (HTTP client)
- **connectivity_plus**: ^5.0.0 (Network connectivity)

### Data Storage
- **flutter_secure_storage**: ^9.0.0 (Secure token storage)
- **shared_preferences**: (Future - simple key-value storage)

### JSON Serialization
- **json_annotation**: ^4.8.0 (JSON annotations)
- **json_serializable**: ^6.7.0 (Code generation)
- **build_runner**: ^2.4.0 (Code generation runner)

### UI Components
- **cached_network_image**: ^3.3.0 (Image caching)
- **file_picker**: ^6.1.0 (File selection)
- **permission_handler**: ^11.0.0 (Device permissions)

### Additional Libraries
- **qr_code_scanner**: ^1.0.1 (QR code scanning)
- **pdf**: ^3.10.0 (PDF generation)
- **open_file**: ^3.3.0 (Open downloaded files)

## Performance Considerations

### State Management Optimization
- Use `BlocBuilder` only where needed
- Implement `cubit` for simple state management
- Use `BlocProvider.value()` for passing existing blocs
- Implement proper bloc disposal to prevent memory leaks

### API Communication
- Implement request caching where appropriate
- Use pagination for large data sets
- Implement retry logic for failed requests
- Optimize image loading and caching

### Memory Management
- Dispose controllers and listeners properly
- Use `const` constructors where possible
- Implement proper image caching strategies
- Monitor memory usage with profiling tools

## Testing Strategy

### Unit Tests
- Test business logic in blocs
- Test use cases and repositories
- Test model serialization/deserialization
- Test utility functions and validators

### Widget Tests
- Test individual widget rendering
- Test user interactions
- Test state changes
- Test navigation flows

### Integration Tests
- Test complete user flows
- Test API integration with mocking
- Test authentication flows
- Test critical business scenarios

## Future Enhancements

### Planned Improvements
1. **Offline Support**: Implement local database for offline functionality
2. **Push Notifications**: Integrate Firebase Cloud Messaging
3. **Analytics**: Add user analytics and crash reporting
4. **Performance Monitoring**: Implement performance monitoring
5. **Certificate Pinning**: Enhance security with SSL pinning
6. **Biometric Auth**: Add fingerprint/face authentication
7. **Background Sync**: Implement background data synchronization

### Scalability Considerations
- Design for multiple language support (i18n)
- Prepare for white-label customization
- Plan for plugin architecture for extensibility
- Design for A/B testing capabilities

---

## Related Documentation

- **[API Documentation](./mobile-v1.md)**: Complete API reference
- **[Development Workflow](./DEVELOPMENT_WORKFLOW.md)**: Development guidelines
- **[Feature Roadmap](./FEATURE_ROADMAP.md)**: Implementation priorities
- **[Environment Setup](./ENVIRONMENT_SETUP.md)**: Setup instructions