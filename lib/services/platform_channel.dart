import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Bridge to native Android functionality
class PlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.MindLock/native');

  static Function(String packageName)? onEscapeAttempt;
  static Function(Map<String, dynamic> data)? onNativeAlarm;
  static Function(String route)? onNativeNavigation;

  static void initializeListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMissionEscapeAttempt') {
        final pkg = call.arguments['package'] as String?;
        if (pkg != null && onEscapeAttempt != null) {
          onEscapeAttempt!(pkg);
        }
      } else if (call.method == 'onNativeAlarm') {
        final data = Map<String, dynamic>.from(call.arguments);
        if (onNativeAlarm != null) {
          onNativeAlarm!(data);
        }
      } else if (call.method == 'onNativeNavigation') {
        final route = call.arguments['route'] as String?;
        if (route != null && onNativeNavigation != null) {
          onNativeNavigation!(route);
        }
      }
    });
  }

  /// Turn screen off / lock device
  static Future<void> lockScreen() async {
    try {
      await _channel.invokeMethod('lockScreen');
    } catch (e) {
      // Requires device admin permission
    }
  }

  /// Navigate to home screen
  static Future<void> goHome() async {
    try {
      await _channel.invokeMethod('goHome');
    } catch (_) {}
  }

  /// Pause current media playback
  static Future<void> pauseMedia() async {
    try {
      await _channel.invokeMethod('pauseMedia');
    } catch (_) {}
  }

  /// Close/kill a specific app by package name
  static Future<void> closeApp(String packageName) async {
    try {
      await _channel.invokeMethod('closeApp', {'package': packageName});
    } catch (_) {}
  }

  /// Get foreground app package name
  static Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod<String>('getForegroundApp');
    } catch (_) {
      return null;
    }
  }

  /// Get app usage stats in minutes for today
  static Future<Map<String, int>> getUsageStats({String period = 'day'}) async {
    final Map<dynamic, dynamic>? stats =
        await _channel.invokeMethod('getUsageStats', {'period': period});
    return stats?.map((key, value) => MapEntry(key.toString(), (value as num).toInt())) ??
        {};
  }

  static Future<bool> scheduleNativeReminder({
    required int id,
    required String title,
    required String body,
    required int timeMs,
    required int priority,
    String tone = 'default',
    int repeatIntervalMinutes = 0,
    int remainingRepeats = 0,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('scheduleNativeReminder', {
        'id': id,
        'title': title,
        'body': body,
        'timeMs': timeMs,
        'priority': priority,
        'tone': tone,
        'repeatIntervalMinutes': repeatIntervalMinutes,
        'remainingRepeats': remainingRepeats,
      });
      return result;
    } catch (e) {
      debugPrint('Native schedule error: $e');
      return false;
    }
  }

  static Future<bool> cancelNativeReminder(int id) async {
    try {
      final bool result = await _channel.invokeMethod('cancelNativeReminder', {'id': id});
      return result;
    } catch (e) {
      debugPrint('Native cancel error: $e');
      return false;
    }
  }

  /// Wake device and turn screen on
  static Future<void> wakeDevice() async {
    try {
      await _channel.invokeMethod('wakeDevice');
    } catch (_) {}
  }

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open accessibility service settings
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  /// Check if overlay permission is granted
  static Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if usage stats permission is granted
  static Future<bool> checkUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open usage stats permission settings
  static Future<void> openUsageStatsSettings() async {
    try {
      await _channel.invokeMethod('openUsageStatsSettings');
    } catch (_) {}
  }

  /// Open overlay permission settings
  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  /// Check if exact alarm permission is granted (Android 12+)
  static Future<bool> checkExactAlarmPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkExactAlarmPermission') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Open exact alarm permission settings
  static Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {}
  }

  /// Request ignore battery optimization
  static Future<void> requestBatteryOptimizationExemption() async {
    try {
      await _channel.invokeMethod('requestBatteryExemption');
    } catch (_) {}
  }

  /// Trigger vibration pattern
  static Future<void> vibrate({int intensity = 1}) async {
    try {
      await _channel.invokeMethod('vibrate', {'intensity': intensity});
    } catch (_) {}
  }

  /// Start Mission Mode blocking
  static Future<void> startMission(List<String> blockedApps, String intensity, int seconds) async {
    try {
      await _channel.invokeMethod('startMission', {
        'blockedApps': blockedApps,
        'intensity': intensity,
        'seconds': seconds,
      });
    } catch (_) {}
  }

  /// Stop Mission Mode blocking
  static Future<void> stopMission() async {
    try {
      await _channel.invokeMethod('stopMission');
    } catch (_) {}
  }

  /// Get remaining mission time in seconds
  static Future<int> getRemainingMissionTime() async {
    try {
      return await _channel.invokeMethod<int>('getRemainingMissionTime') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get active mission details
  static Future<Map<String, dynamic>?> getActiveMissionDetails() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getActiveMissionDetails');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Toggle Do Not Disturb mode
  static Future<bool> setDNDMode(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('setDNDMode', {'enabled': enabled}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open DND (Notification Policy) settings
  static Future<void> openDNDSettings() async {
    try {
      await _channel.invokeMethod('openDNDSettings');
    } catch (_) {}
  }

  static Future<bool> setDeepSleepMode(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('setDeepSleepMode', {'enabled': enabled}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> startSleepTimer(int minutes) async {
    try {
      await _channel.invokeMethod('startSleepTimer', {'minutes': minutes});
    } catch (_) {}
  }

  static Future<void> startSleepTimerSeconds(int seconds) async {
    try {
      await _channel.invokeMethod('startSleepTimerSeconds', {'seconds': seconds});
    } catch (_) {}
  }

  static Future<void> stopSleepTimer() async {
    try {
      await _channel.invokeMethod('stopSleepTimer');
    } catch (_) {}
  }

  static Future<int> getRemainingSleepTime() async {
    try {
      return await _channel.invokeMethod<int>('getRemainingSleepTime') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Check if DND access is granted
  static Future<bool> isDNDPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isDNDPermissionGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open external URL
  static Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod('openUrl', {'url': url});
    } catch (_) {}
  }

  /// Open email client
  static Future<void> openEmail(String recipient, String subject) async {
    try {
      await _channel.invokeMethod('openEmail', {
        'recipient': recipient,
        'subject': subject,
      });
    } catch (_) {}
  }

  /// Get the APK file path of the current app
  static Future<bool> setAwarenessMode(bool enabled) async {
    try {
      final bool success = await _channel.invokeMethod('setAwarenessMode', {'enabled': enabled});
      return success;
    } catch (e) {
      return false;
    }
  }

  static Future<void> scheduleDailyReflection({int hour = 22, int minute = 30}) async {
    await _channel.invokeMethod('scheduleDailyReflection', {
      'hour': hour,
      'minute': minute,
    });
  }

  static Future<void> stopReflectionService() async {
    await _channel.invokeMethod('stopReflectionService');
  }

  static Future<void> snoozeDailyReflection() async {
    await _channel.invokeMethod('snoozeDailyReflection');
  }

  static Future<String?> getAppApkPath() async {
    try {
      return await _channel.invokeMethod<String>('getAppApkPath');
    } catch (_) {
      return null;
    }
  }

  /// Toggle Anti-Scroll mode
  static Future<bool> setNoScrollMode(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('setNoScrollMode', {'enabled': enabled}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if Anti-Scroll mode is active
  static Future<bool> isNoScrollActive() async {
    try {
      return await _channel.invokeMethod<bool>('isNoScrollActive') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Manually trigger the 10:30 PM lockdown behavior
  static Future<void> triggerNightlyLockdown() async {
    try {
      await _channel.invokeMethod('triggerNightlyLockdown');
    } catch (_) {}
  }
}
