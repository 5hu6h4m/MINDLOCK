# MINDLOCK Android App

A premium digital discipline and reminder management Android app built with Flutter.

## 🚀 Quick Setup

### Prerequisites
- Windows PC with Git installed
- Android phone (USB debugging enabled) OR Android emulator
- Java JDK (already installed ✅)

### Step 1: Wait for Flutter Download
Flutter SDK is downloading to `C:\flutter\flutter.zip`. Once complete:

### Step 2: Run Setup Script
```powershell
powershell -ExecutionPolicy Bypass -File "d:\DEV\projects\COSTOM REMINDER\MINDLOCK\setup_flutter.ps1"
```

### Step 3: Run the App
```powershell
cd "d:\DEV\projects\COSTOM REMINDER\MINDLOCK"
flutter run
```

### Step 4: Build APK
```powershell
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Project Structure

```
MINDLOCK/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── constants/enums.dart     # Priority, StrictMode, etc.
│   │   ├── router/app_router.dart   # GoRouter navigation
│   │   └── theme/app_theme.dart     # Dark/light Material 3 theme
│   ├── data/
│   │   ├── local/
│   │   │   ├── hive_boxes.dart      # Hive DB manager
│   │   │   └── models/             # ReminderModel, ScreenSchedule
│   │   └── repositories/
│   │       └── reminder_repository.dart
│   ├── services/
│   │   ├── notification_service.dart  # Local notification channels
│   │   └── platform_channel.dart     # Native Android bridge
│   └── presentation/
│       ├── home/home_screen.dart         # Dashboard
│       ├── reminders/                    # List + Create
│       ├── focus/focus_screen.dart       # Countdown timer
│       ├── sleep/sleep_screen.dart       # Sleep protection
│       ├── analytics/analytics_screen.dart
│       ├── settings/settings_screen.dart
│       ├── onboarding/onboarding_screen.dart
│       ├── overlay/full_screen_reminder_overlay.dart
│       └── shell/main_shell.dart         # Nav bar
├── android/
│   ├── app/src/main/
│   │   ├── kotlin/com/mindlock/app/
│   │   │   ├── MainActivity.kt              # MethodChannel bridge
│   │   │   ├── MINDLOCKAccessibilityService.kt
│   │   │   ├── ForegroundReminderService.kt
│   │   │   └── BootReceiver.kt
│   │   ├── AndroidManifest.xml              # All permissions
│   │   └── res/xml/accessibility_service_config.xml
│   └── build.gradle
└── setup_flutter.ps1  # Run this first!
```

---

## 🔑 Key Features Built

| Feature | Status |
|---|---|
| Home Dashboard (stats, emergency banner, quick actions) | ✅ |
| Reminder CRUD (create, list, complete, delete) | ✅ |
| Priority levels (Low/Medium/High/Emergency) | ✅ |
| Repeat reminder engine | ✅ |
| Full-screen overlay with strict mode | ✅ |
| Sleep protection timer | ✅ |
| Focus mode countdown | ✅ |
| Analytics + streak badges | ✅ |
| Settings + permission management | ✅ |
| Cinematic onboarding | ✅ |
| Floating navigation bar | ✅ |
| Native Android foreground service | ✅ |
| Accessibility service (app monitoring) | ✅ |
| Boot receiver (survives reboot) | ✅ |
| All required permissions | ✅ |

---

## 🛡️ Required Permissions (Android)

The onboarding screen guides users to enable:

1. **Display over other apps** → Full-screen reminders over lock screen
2. **Accessibility Service** → App detection, media control, home navigation
3. **Battery Optimization Exempt** → Reliable background alarms
4. **Notifications** → Auto-requested on Android 13+

---

## 🔥 Firebase Setup (Optional)

To enable cloud sync:
1. Create project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package `com.mindlock.app`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`
5. Uncomment Firebase lines in `android/app/build.gradle`

---

## 📱 Install on Phone

```powershell
# Via ADB (USB connected phone)
adb install build/app/outputs/flutter-apk/app-release.apk
```
