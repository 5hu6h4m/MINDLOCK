import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final box = Hive.box('settings');
    final themeStr = box.get('themeMode', defaultValue: 'dark');
    state = _themeModeFromString(themeStr);
  }

  void setTheme(String themeStr) {
    final box = Hive.box('settings');
    box.put('themeMode', themeStr.toLowerCase());
    state = _themeModeFromString(themeStr);
  }

  ThemeMode _themeModeFromString(String themeStr) {
    switch (themeStr.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
}
