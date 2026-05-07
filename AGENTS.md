# Repository Guidelines

## ⚠️ MANDATORY: Read Documentation Before Working

**ALL AI AGENTS and DEVELOPERS MUST read the `/docs` directory before working on this application.**

This is critical for ensuring development continuity and consistent implementation patterns across different AI models and human developers.

### Required Reading Order (Before Making Any Changes):

1. **`docs/ARCHITECTURE.md`** - System architecture, design patterns, and technical decisions
2. **`docs/DEVELOPMENT_WORKFLOW.md`** - Development practices, coding standards, and workflows
3. **`docs/FEATURE_ROADMAP.md`** - Implementation priorities, feature status, and dependencies
4. **`docs/ENVIRONMENT_SETUP.md`** - Environment configuration and setup instructions

### API Reference:
- **`docs/mobile-v1.md`** - Complete API documentation with Flutter implementation examples

### Why This Is Critical:
- Ensures consistent architectural patterns across all features
- Prevents contradictory implementation approaches
- Maintains code quality and security standards
- Facilitates seamless handover between different developers/AI models
- Reduces onboarding time and prevents common mistakes

### Documentation Usage:
- **Before implementing features**: Read feature-specific documentation in `docs/features/`
- **Before technical changes**: Consult technical guides in `docs/technical/`
- **For API integration**: Always reference `docs/mobile-v1.md` for endpoint specifications
- **For architectural decisions**: Follow patterns established in `docs/ARCHITECTURE.md`

**FAILURE TO READ DOCUMENTATION MAY RESULT IN:**
- Inconsistent code patterns that are difficult to maintain
- Security vulnerabilities from improper implementation
- Wasted time re-solving already-documented problems
- Code that doesn't integrate well with existing architecture

---

## Project Structure & Module Organization

- `lib/` contains Dart application code. The current entry point is `lib/main.dart`.
- `test/` contains Flutter tests, currently starting with `test/widget_test.dart`.
- `android/` and `ios/` contain platform-specific Flutter host projects and native configuration.
- `docs/` contains project documentation. `docs/mobile-v1.md` documents the production mobile API and authentication headers.
- `pubspec.yaml` defines dependencies, SDK constraints, assets, fonts, and app metadata.

Add new features under `lib/` using clear folders as the codebase grows, for example `lib/features/auth/` or `lib/services/`.

## Build, Test, and Development Commands

- `flutter pub get`: install or refresh dependencies.
- `flutter run`: run the app on a selected device.
- `flutter analyze`: run static analysis with `flutter_lints`.
- `flutter test`: run all widget and unit tests in `test/`.
- `flutter build apk`: build an Android APK.
- `flutter build ios`: build the iOS app; requires macOS and Xcode.

Run `flutter analyze` and `flutter test` before submitting changes.

## Coding Style & Naming Conventions

Use standard Dart formatting with two-space indentation. Format changed Dart files with `dart format lib test`. `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.

Follow Flutter and Dart conventions:

- Files and directories use `snake_case.dart`, for example `member_card_page.dart`.
- Classes, widgets, and enums use `UpperCamelCase`.
- Methods, variables, parameters, and providers use `lowerCamelCase`.
- Private members start with `_`.
- Prefer `const` constructors and immutable widgets.

Keep UI widgets small enough to test. Move API access, storage, and parsing out of widget build methods.

## Testing Guidelines

Use `flutter_test` for widget and unit tests. Name test files with the `_test.dart` suffix and place them in `test/`, mirroring `lib/` when possible.

For UI behavior, pump the relevant widget and assert visible text, icons, state changes, and navigation. For services or parsing logic, use deterministic fixtures.

## Commit & Pull Request Guidelines

Git history is unavailable in this workspace, so use concise, imperative commit messages such as `Add login form validation` or `Document mobile API usage`.

Pull requests should include:

- A short summary of the change and why it is needed.
- Test evidence, usually `flutter analyze` and `flutter test`.
- Screenshots or screen recordings for visible UI changes.
- Linked issue or task references when available.

## Security & Configuration Tips

The production mobile API is documented in `docs/mobile-v1.md`. Use `Authorization: Bearer <access_token>` and `Accept: application/json`. Store access tokens in secure device storage, never in source files, logs, or fixtures.
