# Development Workflow Guide

This guide outlines the standard workflows and best practices for developing the 1Komando Flutter application.

## Development Environment Setup

### Prerequisites

**Required Software:**
- **Flutter SDK**: 3.10.4 or higher
- **Dart SDK**: 3.10.4 or higher (included with Flutter)
- **Git**: Latest version for version control
- **IDE**: VS Code or Android Studio with Flutter extensions

**Verification:**
```bash
flutter --version
flutter doctor -v
```

### IDE Setup

**VS Code Extensions (Required):**
- **Flutter** - Core Flutter support
- **Dart** - Dart language support
- **Bloc** - Bloc snippet and visualization support
- **Flutter Widget Snippets** - Widget code snippets
- **Error Lens** - Inline error display

**VS Code Settings (Recommended):**
```json
{
  "dart.lineLength": 100,
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false
}
```

**Android Studio/IntelliJ:**
- Install Flutter and Dart plugins
- Enable "Save actions" for automatic formatting
- Configure live templates for Flutter widgets

## Project Setup and Initialization

### Initial Setup

```bash
# Clone repository
git clone <repository-url> komando
cd komando

# Install dependencies
flutter pub get

# Verify Flutter setup
flutter doctor

# Run code generation for JSON models
flutter pub run build_runner build --delete-conflicting-outputs
```

### Environment Configuration

**Create environment configuration file** (`.env` - not tracked in git):
```bash
# API Configuration
API_BASE_URL=https://anggota.plnipservices.or.id/api/mobile/v1
API_TIMEOUT=30000

# Feature Flags
ENABLE_FINANCE_WORKFLOW=true
ENABLE_PUSH_NOTIFICATIONS=false
```

**Load environment variables** in `main.dart`:
```dart
Future<void> main() async {
  await loadEnvironmentVariables();
  runApp(MyApp());
}
```

## Code Generation Workflow

### JSON Serialization

**Step 1: Create Model Class**
```dart
// lib/features/profile/data/models/member_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'member_model.g.dart';

@JsonSerializable()
class MemberModel {
  final int id;
  final String name;
  @JsonKey(name: 'current_unit_id')
  final int? currentUnitId;

  MemberModel({
    required this.id,
    required this.name,
    this.currentUnitId,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) =>
      _$MemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$MemberModelToJson(this);
}
```

**Step 2: Generate Serialization Code**
```bash
# One-time generation
flutter pub run build_runner build

# Clean build with conflict resolution
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate automatically
flutter pub run build_runner watch
```

**Step 3: Verify Generated Files**
```bash
# Check that .g.dart files were created
find . -name "*.g.dart" -type f
```

### Code Generation Best Practices

- **Run watch mode during development** for automatic regeneration
- **Commit generated files** to version control
- **Delete .g.dart files** when model structure changes significantly
- **Use --delete-conflicting-outputs** when encountering conflicts
- **Verify generated code** after complex model changes

## Git Workflow

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code
- `develop` - Integration branch for features

**Feature Branches:**
- `feature/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `refactor/component-name` - Code refactoring
- `docs/update-description` - Documentation updates

### Commit Message Convention

Follow **Conventional Commits** specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

**Examples:**
```bash
git commit -m "feat(auth): implement login screen with bloc"
git commit -m "fix(finance): resolve unit filter access control issue"
git commit -m "docs(readme): update setup instructions"
git commit -m "refactor(profile): simplify profile update flow"
```

### Development Workflow

**1. Start New Feature:**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

**2. Make Changes and Commit:**
```bash
# Stage changes
git add .

# Commit with conventional message
git commit -m "feat(scope): description"

# Or use staged commit with detailed message
git commit
```

**3. Sync with Remote:**
```bash
# Fetch latest changes
git fetch origin

# Rebase with develop if needed
git rebase origin/develop
```

**4. Create Pull Request:**
- Push feature branch to remote
- Create PR from feature branch to develop
- Request review from team members
- Address review feedback

**5. Merge and Cleanup:**
```bash
# After PR approval and merge
git checkout develop
git pull origin develop
git branch -d feature/your-feature-name
```

## Testing Workflow

### Unit Testing

**Run All Unit Tests:**
```bash
flutter test
```

**Run Specific Test File:**
```bash
flutter test test/features/auth/auth_bloc_test.dart
```

**Run Tests with Coverage:**
```bash
flutter test --coverage
```

**View Coverage Report:**
```bash
# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Widget Testing

**Test Widget Rendering:**
```dart
testWidgets('LoginScreen renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(),
    ),
  );

  expect(find.text('Email'), findsOneWidget);
  expect(find.byType(TextFormField), findsWidgets);
});
```

**Test User Interactions:**
```dart
testWidgets('Login button triggers login', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginScreen(),
    ),
  );

  await tester.enterText(
    find.byKey(Key('email_field')),
    'test@example.com',
  );

  await tester.tap(find.byKey(Key('login_button')));
  await tester.pump();

  // Verify login was triggered
});
```

### Integration Testing

**Run Integration Tests:**
```bash
flutter test integration_test/
```

**Integration Test Example:**
```dart
testWidgets('Full authentication flow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Enter credentials
  await tester.enterText(
    find.byKey(Key('email_field')),
    'test@example.com',
  );
  await tester.enterText(
    find.byKey(Key('password_field')),
    'password123',
  );

  // Submit login
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();

  // Verify navigation to dashboard
  expect(find.text('Dashboard'), findsOneWidget);
});
```

### Testing Best Practices

- **Test Driven Development (TDD)**: Write tests before implementation
- **AAA Pattern**: Arrange, Act, Assert structure
- **Descriptive Test Names**: Test names should describe what is being tested
- **One Assertion Per Test**: Keep tests focused and simple
- **Mock External Dependencies**: Use mocks for API calls and repositories
- **Test Edge Cases**: Test error conditions and boundary cases

## Code Review Guidelines

### Review Checklist

**Functionality:**
- [ ] Code implements the intended functionality
- [ ] Edge cases and error conditions are handled
- [ ] User input validation is implemented
- [ ] Loading states are handled appropriately

**Code Quality:**
- [ ] Code follows project architecture and patterns
- [ ] Code is readable and well-documented
- [ ] No code duplication
- [ ] Proper error handling and logging

**Testing:**
- [ ] Unit tests are included
- [ ] Tests cover critical functionality
- [ ] Tests are not failing
- [ ] Edge cases are tested

**Security:**
- [ ] Sensitive data is properly secured
- [ ] No hardcoded credentials or API keys
- [ ] Input validation prevents injection attacks
- [ ] Role-based access control is enforced

**Performance:**
- [ ] No memory leaks
- [ ] Efficient algorithms and data structures
- [ ] Proper disposal of resources
- [ ] Optimized image loading and caching

### Review Process

1. **Self-Review**: Review your own code before submitting
2. **Automated Checks**: Ensure all tests pass and linting is clean
3. **Peer Review**: Request review from team members
4. **Address Feedback**: Make necessary changes based on feedback
5. **Approval**: Get approval from required reviewers
6. **Merge**: Merge into target branch after approval

## Debugging Techniques

### Flutter DevTools

**Launch DevTools:**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Connect to Running App:**
```bash
flutter run --profile
# In DevTools, connect to the running app
```

**DevTools Features:**
- **Widget Inspector**: Examine widget tree
- **Performance View**: Analyze frame rendering and performance
- **Memory View**: Track memory usage and leaks
- **Network View**: Monitor API calls and responses
- **Logging**: View application logs

### Logging Strategy

**Implement Structured Logging:**
```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Usage
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: error, stackTrace: stackTrace);
```

**API Call Logging:**
```dart
class ApiLogger extends Interceptor {
  final logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('API Request: ${options.method} ${options.uri}');
    logger.d('Headers: ${options.headers}');
    logger.d('Data: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i('API Response: ${response.statusCode} ${response.uri}');
    logger.d('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('API Error: ${err.message}');
    logger.e('Response: ${err.response}');
    handler.next(err);
  }
}
```

### Common Debugging Scenarios

**Authentication Issues:**
1. Check token storage in secure storage
2. Verify token is sent in request headers
3. Check API response for authentication errors
4. Verify role-based access control

**State Management Issues:**
1. Check if bloc is properly provided to widget tree
2. Verify events are being added to bloc
3. Check state transitions in bloc
4. Use BlocObserver to monitor state changes

**UI Rendering Issues:**
1. Use Flutter Inspector to examine widget tree
2. Check for layout constraints and overflow
3. Verify widgets are properly rebuilt on state changes
4. Check for memory leaks in controllers

**API Communication Issues:**
1. Check network connectivity
2. Verify API base URL configuration
3. Check request/response format
4. Verify error handling in interceptors

## Hot Reload vs Hot Restart

### Hot Reload (🔥)

**Usage:**
```bash
# In running app terminal
press 'r' or click hot reload button
```

**What It Does:**
- Injects updated source code into running Dart VM
- Preserves app state
- Fast updates (typically <1 second)

**When to Use:**
- UI changes and widget updates
- Business logic changes in blocs
- Most code changes during development

**Limitations:**
- Doesn't work for all changes (generative code, main.dart)
- State changes may not be reflected
- Some changes require hot restart

### Hot Restart (🔄)

**Usage:**
```bash
# In running app terminal
press 'R' or click hot restart button
```

**What It Does:**
- Restarts the app from main()
- Loses app state
- Slower than hot reload (~3-5 seconds)

**When to Use:**
- Changes to main.dart
- Changes to generative code (.g.dart files)
- Changes that hot reload can't handle
- When you need fresh app state

### Best Practices

- **Try Hot Reload First**: It's faster and preserves state
- **Use Hot Restart for State Reset**: When you need fresh state
- **Hot Restart After Code Generation**: After running build_runner
- **Save Files Before Hot Reload**: Ensure changes are saved

## Performance Optimization

### Build Performance

**Optimize Build Times:**
```bash
# Use debug mode for development
flutter run --debug

# Use profile mode for performance testing
flutter run --profile

# Enable compilation caching
flutter run --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/
```

### Runtime Performance

**Widget Performance:**
- Use `const` constructors where possible
- Avoid excessive widget rebuilds
- Use `ListView.builder` for long lists
- Implement proper image caching

**Bloc Performance:**
- Use `cubit` for simple state management
- Implement proper bloc disposal
- Use `BlocProvider.value()` to pass existing blocs
- Avoid unnecessary state emissions

**API Performance:**
- Implement request caching
- Use pagination for large datasets
- Optimize image loading and compression
- Implement retry logic with exponential backoff

## Code Quality Tools

### Static Analysis

**Run Flutter Analyze:**
```bash
flutter analyze
```

**Fix Issues Automatically:**
```bash
dart fix --apply
```

### Code Formatting

**Format All Files:**
```bash
flutter format .
```

**Format Specific File:**
```bash
flutter format lib/main.dart
```

**Format with Line Length:**
```bash
flutter format --line-length=100 .
```

### Linting Rules

**Enable Additional Lints** in `analysis_options.yaml`:
```yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - avoid_print
    - prefer_single_quotes
    - sort_constructors_first
    - always_declare_return_types
```

## Continuous Integration

### Pre-commit Hooks

**Install Husky for Git Hooks:**
```bash
# Install Husky
npm install husky --save-dev

# Setup Git hooks
npx husky install
npx husky add .husky/pre-commit "flutter test && flutter analyze"
```

### Automated Testing

**GitHub Actions Example:**
```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.4'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --debug
```

## Common Issues and Solutions

### Build Issues

**Issue:** "Flutter SDK not found"
```bash
export PATH="$PATH:/path/to/flutter/bin"
flutter doctor
```

**Issue:** "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Code Generation Issues

**Issue:** "Missing generated file"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Issue:** "Conflicting generated files"
```bash
# Delete all .g.dart files
find . -name "*.g.dart" -delete

# Regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

### State Management Issues

**Issue:** Bloc not found in widget tree
```bash
# Ensure BlocProvider is provided
BlocProvider(
  create: (context) => AuthBloc(),
  child: MyApp(),
)
```

## Development Best Practices

### Daily Workflow

1. **Start with git pull** from main development branch
2. **Run hot reload** during active development
3. **Test frequently** using hot reload and widget tests
4. **Commit often** with descriptive commit messages
5. **Run tests** before pushing changes
6. **Review code** before creating pull requests

### Code Organization

- **Feature-based structure**: Group related files by feature
- **Separate concerns**: Keep UI, business logic, and data separate
- **Use meaningful names**: Files, classes, and variables should be self-documenting
- **Comment complex logic**: Explain why, not what
- **Keep functions small**: Functions should do one thing well

### Collaboration

- **Communicate changes**: Inform team of significant changes
- **Review pull requests**: Provide constructive feedback
- **Document decisions**: Document architectural decisions and trade-offs
- **Share knowledge**: Mentor team members and share learnings
- **Be respectful**: Treat all team members with respect

---

## Related Documentation

- **[Architecture](./ARCHITECTURE.md)**: System architecture and design patterns
- **[Feature Roadmap](./FEATURE_ROADMAP.md)**: Implementation priorities
- **[Environment Setup](./ENVIRONMENT_SETUP.md)**: Detailed setup instructions
- **[API Documentation](./mobile-v1.md)**: Complete API reference