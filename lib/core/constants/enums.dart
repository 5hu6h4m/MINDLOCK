// Priority levels for reminders
enum ReminderPriority { low, medium, high, emergency }

// Strict mode confirmation types
enum StrictModeType { none, math, holdButton, swipe }

// Repeat interval options
enum RepeatInterval { oneMin, fiveMin, tenMin, fifteenMin, thirtyMin, custom }

// Screen schedule action types
enum ScheduleAction { screenOff, closeApps, navigateHome, showWarning }

// Reminder action results
enum ReminderAction { done, snooze, delay, ignore, reschedule }

// Focus session status
enum FocusStatus { idle, running, paused, completed }

// Badge types
enum BadgeType { nightDiscipline, taskWarrior, focusMaster, noReels, sleepGuard, deepWorker, dopamineSlayer }

// Mission Categories
enum MissionCategory { study, work, coding, reading, fitness, meditation, sleep, custom }

// Mission Intensity
enum MissionIntensity { light, medium, hardcore }

extension ReminderPriorityExt on ReminderPriority {
  String get label {
    switch (this) {
      case ReminderPriority.low: return 'Low';
      case ReminderPriority.medium: return 'Medium';
      case ReminderPriority.high: return 'High';
      case ReminderPriority.emergency: return 'Emergency';
    }
  }

  int get colorValue {
    switch (this) {
      case ReminderPriority.low: return 0xFF00E5A0;
      case ReminderPriority.medium: return 0xFF4A90E2;
      case ReminderPriority.high: return 0xFFFFC107;
      case ReminderPriority.emergency: return 0xFFFF4560;
    }
  }

  int get notificationPriority {
    switch (this) {
      case ReminderPriority.low: return 0;
      case ReminderPriority.medium: return 1;
      case ReminderPriority.high: return 2;
      case ReminderPriority.emergency: return 3;
    }
  }
}

extension RepeatIntervalExt on RepeatInterval {
  String get label {
    switch (this) {
      case RepeatInterval.oneMin: return '1 min';
      case RepeatInterval.fiveMin: return '5 min';
      case RepeatInterval.tenMin: return '10 min';
      case RepeatInterval.fifteenMin: return '15 min';
      case RepeatInterval.thirtyMin: return '30 min';
      case RepeatInterval.custom: return 'Custom';
    }
  }

  int get minutes {
    switch (this) {
      case RepeatInterval.oneMin: return 1;
      case RepeatInterval.fiveMin: return 5;
      case RepeatInterval.tenMin: return 10;
      case RepeatInterval.fifteenMin: return 15;
      case RepeatInterval.thirtyMin: return 30;
      case RepeatInterval.custom: return 0;
    }
  }
}

extension MissionCategoryExt on MissionCategory {
  String get label {
    switch (this) {
      case MissionCategory.study: return 'Study';
      case MissionCategory.work: return 'Work';
      case MissionCategory.coding: return 'Coding';
      case MissionCategory.reading: return 'Reading';
      case MissionCategory.fitness: return 'Fitness';
      case MissionCategory.meditation: return 'Meditation';
      case MissionCategory.sleep: return 'Sleep';
      case MissionCategory.custom: return 'Custom';
    }
  }
}

extension MissionIntensityExt on MissionIntensity {
  String get label {
    switch (this) {
      case MissionIntensity.light: return 'Light';
      case MissionIntensity.medium: return 'Medium';
      case MissionIntensity.hardcore: return 'Hardcore';
    }
  }
}
