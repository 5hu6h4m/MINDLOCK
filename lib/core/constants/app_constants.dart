/// App-wide string constants, asset paths, and configuration values.
/// Centralizes all magic strings to prevent typos and enable easy updates.
library;

class AppConstants {
  AppConstants._();

  // ─── App Info ───────────────────────────────────────────────────────────
  static const String appName = 'MindLock';
  static const String appVersion = '1.0.3';
  static const String appTagline = 'Reclaim Your Focus. Build Real Discipline.';
  static const String developerHandle = '5hu6h4m';

  // ─── Hive Box Names ─────────────────────────────────────────────────────
  static const String boxReminders = 'reminders';
  static const String boxUserStats = 'user_stats';
  static const String boxSettings = 'settings';
  static const String boxMissions = 'missions';
  static const String boxTimetable = 'timetable';
  static const String boxDailyReflection = 'daily_reflection';
  static const String boxCoFocus = 'co_focus';

  // ─── Notification Channel IDs ───────────────────────────────────────────
  static const String channelReminders = 'mindlock_reminders';
  static const String channelFocus = 'mindlock_focus';
  static const String channelSleep = 'mindlock_sleep';
  static const String channelEmergency = 'mindlock_emergency';

  // ─── Route Names ────────────────────────────────────────────────────────
  static const String routeHome = '/';
  static const String routeReminders = '/reminders';
  static const String routeCreateReminder = '/reminders/create';
  static const String routeAlarm = '/reminders/alarm';
  static const String routeFocus = '/focus';
  static const String routeSleep = '/sleep';
  static const String routeAnalytics = '/analytics';
  static const String routeSettings = '/settings';
  static const String routeOnboarding = '/onboarding';

  // ─── Discipline Score Thresholds ────────────────────────────────────────
  static const double scoreLegendary = 0.9;
  static const double scoreDisciplined = 0.8;
  static const double scoreOnTrack = 0.6;
  static const double scoreRoomToGrow = 0.4;

  // ─── Focus / Mission Durations (in minutes) ─────────────────────────────
  static const List<int> focusDurationOptions = [15, 25, 30, 45, 60, 90, 120];
  static const int defaultFocusDuration = 25; // Pomodoro default

  // ─── Sleep Protection ───────────────────────────────────────────────────
  static const int defaultSleepHour = 23;   // 11:00 PM
  static const int defaultSleepMinute = 0;
  static const int defaultWakeHour = 6;     // 6:00 AM
  static const int defaultWakeMinute = 0;

  // ─── Co-Focus ────────────────────────────────────────────────────────────
  static const int coFocusRoomCodeLength = 4;
  static const int maxCoFocusParticipants = 5;

  // ─── Snooze ─────────────────────────────────────────────────────────────
  static const int maxSnoozeCount = 3;
  static const int snoozeDurationMinutes = 5;

  // ─── Punctuality Windows ────────────────────────────────────────────────
  static const int punctualityStrictMinutes = 15;
  static const int punctualityLooseMinutes = 60;

  // ─── Animation Durations ────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration animPageTransition = Duration(milliseconds: 400);
}
