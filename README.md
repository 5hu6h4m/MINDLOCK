<div align="center">

<img src="https://img.shields.io/badge/MindLock-Digital%20Discipline%20System-6C63FF?style=for-the-badge&logo=android&logoColor=white"/>

# 🧠 MindLock
### *Reclaim Your Focus. Build Real Discipline.*

[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://github.com/5hu6h4m/MINDLOCK/releases)
[![Flutter](https://img.shields.io/badge/Built%20With-Flutter-54C5F8?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Version](https://img.shields.io/badge/Version-1.0.3-6C63FF?style=flat-square)](https://github.com/5hu6h4m/MINDLOCK/releases/tag/v1.0.3)
[![License](https://img.shields.io/badge/License-MIT-FF6584?style=flat-square)](LICENSE)

<br/>

### ⬇️ [Download Latest APK — v1.0.3](https://github.com/5hu6h4m/MINDLOCK/releases/download/v1.0.3/MindLock_v1.0.3.apk)

> Click the link above → APK downloads instantly. No sign-up. No Play Store needed.

</div>

---

## 📖 What is MindLock?

**MindLock** is a premium **Digital Discipline System** for Android — not just another reminder app. It's a complete productivity OS for your phone, built to ensure you stay locked in, focused, and consistent every single day.

Built entirely with **Flutter + Dart**, with deep **native Android (Kotlin)** integration for full-system control.

---

## ✨ Core Features

### 🔔 Smart Reminders
- **4 Priority Levels** — Low / Medium / High / Emergency
- **Full-Screen Overlay** — Reminder takes over the screen; can't be ignored
- **Auto-Repeat** — Keeps firing until you tap "Done" — no escaping it
- **Today / Upcoming / Completed** tabs for clean task management

### 🚀 Mission Mode (Focus System)
| Intensity | What Happens |
|-----------|-------------|
| 🟢 **Light** | Gentle timer with focus nudges |
| 🟡 **Medium** | Actively blocks Instagram, YouTube, Games |
| 🔴 **Hardcore** | Total lockdown — escape attempts penalize your score |

### 👥 Co-Focus Buddy *(Multiplayer Focus)*
- Create or join a **4-digit room**
- **Shared punishment** — if anyone breaks focus, *everyone* fails
- Social accountability that actually works

### 📊 Analytics & Streaks
- **Discipline Score** — live % based on completions & focus sessions
- **Visual charts** — weekly & monthly trends
- **Streak tracking** — don't break the chain!

### 🛡️ Sleep Protection
- Lock your phone after a set bedtime — no more doomscrolling

### 🎨 Premium UI
- **Glassmorphism** design with smooth micro-animations
- **Dark / Light / System** theme modes
- **Cinematic onboarding** experience
- **Floating navigation bar**

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart) |
| **Local DB** | Hive (NoSQL, offline-first) |
| **Navigation** | GoRouter |
| **State Management** | Provider / Riverpod |
| **Native Android** | Kotlin — MethodChannel bridge |
| **Notifications** | flutter_local_notifications |
| **Background Service** | Android ForegroundService |
| **App Monitoring** | AccessibilityService |
| **Boot Persistence** | BootReceiver |

---

## 📁 Project Structure

```
MINDLOCK/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── constants/enums.dart           # Priority, StrictMode enums
│   │   ├── router/app_router.dart         # GoRouter config
│   │   └── theme/app_theme.dart           # Material 3 dark/light theme
│   ├── data/
│   │   ├── local/
│   │   │   ├── hive_boxes.dart            # Hive DB manager
│   │   │   └── models/                    # ReminderModel, ScreenSchedule
│   │   └── repositories/
│   │       └── reminder_repository.dart
│   ├── services/
│   │   ├── notification_service.dart      # Notification channels
│   │   └── platform_channel.dart          # Native Android bridge
│   └── presentation/
│       ├── home/home_screen.dart          # Dashboard
│       ├── reminders/                     # List + Create screens
│       ├── focus/focus_screen.dart        # Mission Mode
│       ├── sleep/sleep_screen.dart        # Sleep protection
│       ├── analytics/analytics_screen.dart
│       ├── settings/settings_screen.dart
│       ├── onboarding/onboarding_screen.dart
│       ├── overlay/full_screen_reminder_overlay.dart
│       └── shell/main_shell.dart          # Nav bar shell
├── android/
│   └── app/src/main/kotlin/com/mindlock/app/
│       ├── MainActivity.kt                # MethodChannel bridge
│       ├── MINDLOCKAccessibilityService.kt
│       ├── ForegroundReminderService.kt
│       └── BootReceiver.kt
└── assets/
```

---

## 🔑 Android Permissions

MindLock needs these to work fully — the onboarding screen guides you through each one:

| Permission | Why Needed |
|-----------|-----------|
| **Display over other apps** | Full-screen reminder overlays |
| **Accessibility Service** | App detection & distraction blocking |
| **Battery Optimization Exempt** | Reliable background alarms |
| **POST_NOTIFICATIONS** | Auto-requested on Android 13+ |
| **RECEIVE_BOOT_COMPLETED** | Survives phone restarts |

---

## 📲 Installation

### Option 1 — Direct APK (Recommended)
```
👉 https://github.com/5hu6h4m/MINDLOCK/releases/download/v1.0.3/MindLock_v1.0.3.apk
```
1. Click the link — APK downloads directly
2. Open the downloaded file on your Android device
3. Tap **"Install"** (enable *Unknown Sources* if prompted)
4. Done ✅

### Option 2 — Build from Source
```powershell
# Prerequisites: Flutter SDK, Android SDK, JDK 17+
git clone https://github.com/5hu6h4m/MINDLOCK.git
cd MINDLOCK
flutter pub get
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

---

## 🗺️ Roadmap

- [ ] Google Play Store release
- [ ] Firebase cloud sync
- [ ] iOS support
- [ ] Widget for home screen discipline score
- [ ] AI-powered habit suggestions

---

## 👨‍💻 Developer

<div align="center">

**Built with ❤️ by [5hu6h4m](https://github.com/5hu6h4m)**

*Digital Discipline System — v1.0.3*

</div>
