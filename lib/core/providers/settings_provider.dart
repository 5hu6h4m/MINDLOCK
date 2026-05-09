import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool badgeEnabled;
  final bool disciplineScoreEnabled;
  final bool aiSuggestionsEnabled;
  final bool streakTrackingEnabled;
  final bool noScrollEnabled;
  final bool awarenessPulseEnabled;
  final int reflectionHour;
  final int reflectionMinute;

  AppSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.badgeEnabled = true,
    this.disciplineScoreEnabled = true,
    this.aiSuggestionsEnabled = true,
    this.streakTrackingEnabled = true,
    this.noScrollEnabled = false,
    this.awarenessPulseEnabled = false,
    this.reflectionHour = 22,
    this.reflectionMinute = 30,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeEnabled,
    bool? disciplineScoreEnabled,
    bool? aiSuggestionsEnabled,
    bool? streakTrackingEnabled,
    bool? noScrollEnabled,
    bool? awarenessPulseEnabled,
    int? reflectionHour,
    int? reflectionMinute,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      disciplineScoreEnabled: disciplineScoreEnabled ?? this.disciplineScoreEnabled,
      aiSuggestionsEnabled: aiSuggestionsEnabled ?? this.aiSuggestionsEnabled,
      streakTrackingEnabled: streakTrackingEnabled ?? this.streakTrackingEnabled,
      noScrollEnabled: noScrollEnabled ?? this.noScrollEnabled,
      awarenessPulseEnabled: awarenessPulseEnabled ?? this.awarenessPulseEnabled,
      reflectionHour: reflectionHour ?? this.reflectionHour,
      reflectionMinute: reflectionMinute ?? this.reflectionMinute,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box('settings');
    state = AppSettings(
      soundEnabled: box.get('soundEnabled', defaultValue: true),
      vibrationEnabled: box.get('vibrationEnabled', defaultValue: true),
      badgeEnabled: box.get('badgeEnabled', defaultValue: true),
      disciplineScoreEnabled: box.get('disciplineScoreEnabled', defaultValue: true),
      aiSuggestionsEnabled: box.get('aiSuggestionsEnabled', defaultValue: true),
      streakTrackingEnabled: box.get('streakTrackingEnabled', defaultValue: true),
      noScrollEnabled: box.get('noScrollEnabled', defaultValue: false),
      awarenessPulseEnabled: box.get('awarenessPulseEnabled', defaultValue: false),
      reflectionHour: box.get('reflectionHour', defaultValue: 22),
      reflectionMinute: box.get('reflectionMinute', defaultValue: 30),
    );
  }

  void updateReflectionTime(int hour, int minute) {
    final box = Hive.box('settings');
    box.put('reflectionHour', hour);
    box.put('reflectionMinute', minute);
    state = state.copyWith(reflectionHour: hour, reflectionMinute: minute);
  }

  void updateSetting(String key, bool value) {
    final box = Hive.box('settings');
    box.put(key, value);
    
    switch (key) {
      case 'soundEnabled':
        state = state.copyWith(soundEnabled: value);
        break;
      case 'vibrationEnabled':
        state = state.copyWith(vibrationEnabled: value);
        break;
      case 'badgeEnabled':
        state = state.copyWith(badgeEnabled: value);
        break;
      case 'disciplineScoreEnabled':
        state = state.copyWith(disciplineScoreEnabled: value);
        break;
      case 'aiSuggestionsEnabled':
        state = state.copyWith(aiSuggestionsEnabled: value);
        break;
      case 'streakTrackingEnabled':
        state = state.copyWith(streakTrackingEnabled: value);
        break;
      case 'noScrollEnabled':
        state = state.copyWith(noScrollEnabled: value);
        break;
      case 'awarenessPulseEnabled':
        state = state.copyWith(awarenessPulseEnabled: value);
        break;
    }
  }
}
