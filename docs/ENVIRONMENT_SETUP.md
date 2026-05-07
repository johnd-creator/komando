# Environment Setup Guide

This guide provides step-by-step instructions for setting up your development environment for the 1Komando Flutter application.

## Prerequisites

### System Requirements

**Minimum Specifications:**
- **Operating System**:
  - Windows 10 or higher (64-bit)
  - macOS 10.14 or higher
  - Linux (64-bit distributions)
- **RAM**: 8 GB minimum (16 GB recommended)
- **Disk Space**: 10 GB free space (50 GB recommended for full development)
- **Internet Connection**: Required for downloading dependencies and API access

**Recommended Specifications:**
- **RAM**: 16 GB or higher
- **CPU**: Multi-core processor (Intel i5, AMD Ryzen 5, or Apple M1/M2)
- **SSD**: Solid state drive for faster build times
- **Graphics**: Support for hardware acceleration

## Required Software

### 1. Flutter SDK Installation

**Step 1: Download Flutter SDK**

**For Windows:**
1. Visit https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK zip file
3. Extract to `C:\src\flutter` (or preferred location)
4. Add Flutter to PATH:
   ```cmd
   C:\src\flutter\bin
   ```

**For macOS:**
1. Visit https://flutter.dev/docs/get-started/install/macos
2. Download Flutter SDK zip file
3. Extract to `/Users/your-username/development/flutter`
4. Add Flutter to PATH in `~/.zshrc` or `~/.bash_profile`:
   ```bash
   export PATH="$PATH:/Users/your-username/development/flutter/bin"
   ```

**For Linux:**
1. Visit https://flutter.dev/docs/get-started/install/linux
2. Download Flutter SDK tar.xz file
3. Extract to `/home/your-username/development/flutter`
4. Add Flutter to PATH in `~/.bashrc`:
   ```bash
   export PATH="$PATH:/home/your-username/development/flutter/bin"
   ```

**Step 2: Verify Flutter Installation**
```bash
flutter --version
```

Expected output:
```
Flutter 3.10.4 • channel stable
Dart 3.10.4 • DevTools 2.23.1
```

### 2. Dart SDK

Dart SDK is included with Flutter SDK. No separate installation required.

**Verify Dart Installation:**
```bash
dart --version
```

Expected output:
```
Dart SDK version: 3.10.4
```

### 3. IDE Setup

#### Option A: Visual Studio Code (Recommended)

**Installation:**
1. Download VS Code from https://code.visualstudio.com/
2. Install for your operating system
3. Launch VS Code

**Required Extensions:**
1. **Flutter**
   - Install from VS Code Extensions marketplace
   - Search "Flutter" and install official Flutter extension

2. **Dart**
   - Auto-installed with Flutter extension

3. **Bloc**
   - Search "Bloc" and install Felix Angelov's Bloc extension
   - Provides snippets and Bloc visualization

4. **Flutter Widget Snippets**
   - Search "Flutter Widget Snippets"
   - Provides code snippets for Flutter widgets

5. **Error Lens**
   - Search "Error Lens"
   - Shows inline error messages

**Optional but Recommended Extensions:**
- **Awesome Flutter Snippets** - Additional code snippets
- **Flutter Tree** - Visualizes widget tree
- **Pubspec Assist** - Helps with dependencies
- **Color Highlight** - Highlights color codes
- **GitLens** - Enhanced Git capabilities

**VS Code Configuration:**
Create `.vscode/settings.json` in project root:
```json
{
  "dart.lineLength": 100,
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000
}
```

#### Option B: Android Studio / IntelliJ IDEA

**Installation:**
1. Download Android Studio from https://developer.android.com/studio
2. Install for your operating system
3. Launch Android Studio

**Plugin Installation:**
1. Go to `File` → `Settings` → `Plugins`
2. Search and install:
   - **Flutter**
   - **Dart**
3. Restart Android Studio

**Android Studio Configuration:**
1. Go to `File` → `Settings` → `Editor` → `Code Style` → `Dart`
2. Set line length to 100
3. Enable "Reformat code" on save

### 4. Platform-Specific Setup

#### For Android Development

**Install Android SDK:**
1. Install Android Studio (includes Android SDK)
2. Open Android Studio
3. Go to `SDK Manager`
4. Install:
   - **Android SDK Platform-Tools**
   - **Android SDK Build-Tools**
   - **Android 13.0 (API Level 33)** or higher

**Setup Android Emulator:**
1. In Android Studio, go to `Tools` → `Device Manager`
2. Click "Create Device"
3. Select device (e.g., Pixel 6)
4. Select system image (API Level 33 or higher)
5. Finish creation

**Enable USB Debugging (for Physical Device):**
1. Enable Developer Options on your Android device
2. Enable USB Debugging in Developer Options
3. Connect device via USB
4. Verify connection: `flutter devices`

#### For iOS Development (macOS only)

**Install Xcode:**
1. Install Xcode from Mac App Store
2. Open Xcode and accept license agreement
3. Install additional components

**Setup iOS Simulator:**
1. Open Xcode
2. Go to `Preferences` → `Components`
3. Install iOS Simulator (latest version)

**Setup CocoaPods:**
```bash
sudo gem install cocoapods
```

**Physical Device Setup:**
1. Connect iPhone/iPad via USB
2. Trust this computer on your device
3. Enable Developer Mode on device (iOS 16+)
4. Verify connection: `flutter devices`

## Project Setup

### 1. Clone Repository

```bash
# Clone repository
git clone <repository-url> komando
cd komando
```

### 2. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Verify no dependency issues
flutter doctor
```

### 3. Generate JSON Serialization Code

```bash
# Generate .g.dart files for JSON models
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Verify Setup

```bash
# Run Flutter doctor to check setup
flutter doctor -v

# Expected output should show no errors for:
# - Flutter SDK
# - Android toolchain
# - Xcode (if on macOS)
# - VS Code/Android Studio
# - Connected device
```

### 5. Run Application

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on default device
flutter run

# Run with detailed logging
flutter run --verbose
```

## Environment Configuration

### 1. Environment Variables

Create `.env` file in project root (not tracked in git):
```bash
# API Configuration
API_BASE_URL=https://anggota.plnipservices.or.id/api/mobile/v1
API_TIMEOUT=30000

# Feature Flags
ENABLE_FINANCE_WORKFLOW=true
ENABLE_PUSH_NOTIFICATIONS=false

# Environment
ENVIRONMENT=development
```

### 2. Load Environment Variables

**Using flutter_dot_env (Recommended):**

1. Add dependency to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Load environment in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

**Using --dart-define (Alternative):**
```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

### 3. API Configuration

Create `lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  );

  static const Duration timeout = Duration(
    milliseconds: int.fromEnvironment(
      'API_TIMEOUT',
      defaultValue: 30000,
    ),
  );

  // Endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/profile';
  static const String financeDashboard = '/finance/dashboard';
  static const String notifications = '/notifications';
}
```

## Verification Checklist

Use this checklist to verify your environment setup is complete:

### Flutter Setup
- [ ] Flutter SDK installed (version 3.10.4+)
- [ ] Dart SDK installed (version 3.10.4+)
- [ ] `flutter doctor` shows no critical issues
- [ ] `flutter --version` works correctly

### IDE Setup
- [ ] VS Code or Android Studio installed
- [ ] Flutter extension installed
- [ ] Dart extension installed
- [ ] Bloc extension installed (VS Code)
- [ ] Code formatting configured

### Android Development
- [ ] Android Studio installed
- [ ] Android SDK installed
- [ ] Android emulator created or physical device connected
- [ ] `flutter devices` shows Android device

### iOS Development (macOS only)
- [ ] Xcode installed
- [ ] Xcode license accepted
- [ ] iOS Simulator working
- [ ] CocoaPods installed
- [ ] `flutter devices` shows iOS device/simulator

### Project Setup
- [ ] Repository cloned
- [ ] Dependencies installed (`flutter pub get`)
- [ ] JSON code generation completed
- [ ] `.env` file created
- [ ] App runs on at least one device

### Functionality
- [ ] Hot reload works (press 'r' in running app)
- [ ] Hot restart works (press 'R' in running app)
- [ ] Can connect to API
- [ ] No build errors
- [ ] No runtime errors in sample app

## Common Setup Issues and Solutions

### Issue: Flutter Command Not Found

**Solution:**
- Verify Flutter is in your PATH
- Restart terminal/command prompt
- Try full path: `/path/to/flutter/bin/flutter`

### Issue: Android License Not Accepted

**Solution:**
```bash
flutter doctor --android-licenses
```
Accept all licenses by typing 'y' when prompted.

### Issue: CocoaPods Not Installed (macOS)

**Solution:**
```bash
sudo gem install cocoapods
```

### Issue: Code Generation Fails

**Solution:**
```bash
# Clean build
flutter clean

# Delete generated files
find . -name "*.g.dart" -delete

# Regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Device Not Found

**Solution:**
- Enable USB debugging on device
- Verify USB cable connection
- Restart adb server: `adb kill-server && adb start-server`
- Check device is in developer mode

### Issue: Build Fails with Dependency Errors

**Solution:**
```bash
# Clean Flutter cache
flutter clean

# Remove pub cache
rm -rf ~/.pub-cache/hosted/pub.dartlang.org/*

# Reinstall dependencies
flutter pub get
flutter pub upgrade
```

## Development Workflow

### Daily Development

**Start Development:**
```bash
# Pull latest changes
git pull origin develop

# Install any new dependencies
flutter pub get

# Regenerate code if models changed
flutter pub run build_runner build --delete-conflicting-outputs

# Start app
flutter run
```

**During Development:**
- Use hot reload (press 'r') for UI changes
- Use hot restart (press 'R') for code changes
- Run tests: `flutter test`
- Check for issues: `flutter analyze`

### Testing Setup

**Run All Tests:**
```bash
flutter test
```

**Run Tests with Coverage:**
```bash
flutter test --coverage
```

**Run Integration Tests:**
```bash
flutter test integration_test/
```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS IPA:**
```bash
flutter build ios --release
```

## Performance Optimization

### Improve Build Performance

**Enable Build Cache:**
```bash
flutter build apk --release --build-cache
```

**Use Skia Rendering Engine (Experimental):**
```bash
flutter run --enable-impeller
```

### Reduce Debug Build Time

**Use specific target:**
```bash
flutter run --target=lib/main.dart
```

**Disable unnecessary features:**
```bash
flutter run --no-sound-null-safety
```

## Additional Tools

### Git Setup

**Install Git:**
- Windows: https://git-scm.com/download/win
- macOS: `brew install git` or included with Xcode
- Linux: `sudo apt-get install git`

**Configure Git:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Postman/cURL for API Testing

**Install Postman:**
- Download from https://www.postman.com/downloads/

**Test API with cURL:**
```bash
curl -X GET 'https://anggota.plnipservices.or.id/api/mobile/v1/me' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <your-token>'
```

### Device Simulators

**Genymotion (Advanced Android Simulation):**
- Download from https://www.genymotion.com/

**iOS Simulator (Included with Xcode):**
- Already installed if Xcode is installed

## Next Steps

After completing environment setup:

1. **Read Architecture Documentation**: Understand system design
2. **Review Development Workflow**: Learn development practices
3. **Check Feature Roadmap**: Understand implementation priorities
4. **Start with Authentication**: Begin with the foundation feature

## Support and Resources

### Official Flutter Documentation
- Flutter Documentation: https://flutter.dev/docs
- Dart Documentation: https://dart.dev/guides
- Flutter API Reference: https://api.flutter.dev/

### Community Resources
- Flutter Discord: https://flutter.dev/discord
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter
- Flutter Community: https://flutter.dev/community

### Project Documentation
- **[Architecture](./ARCHITECTURE.md)**: System architecture
- **[Development Workflow](./DEVELOPMENT_WORKFLOW.md)**: Development guidelines
- **[Feature Roadmap](./FEATURE_ROADMAP.md)**: Implementation priorities
- **[API Documentation](./mobile-v1.md)**: API reference

---

## Environment Setup Complete! ✅

Your development environment is now ready for 1Komando Flutter development. You can:

1. Run the app: `flutter run`
2. Run tests: `flutter test`
3. Build for production: `flutter build apk --release`

Happy coding! 🚀