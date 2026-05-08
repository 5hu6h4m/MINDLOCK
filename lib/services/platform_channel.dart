import 'package:flutter/services.dart';

/// Bridge to native Android functionality
class PlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.MindLock/native');

  static Function(String packageName)? onEscapeAttempt;

  static void initializeListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMissionEscapeAttempt') {
        final pkg = call.arguments['package'] as String?;
        if (pkg != null && onEscapeAttempt != null) {
          onEscapeAttempt!(pkg);
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
  static Future<Map<String, int>> getUsageStats() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, int>('getUsageStats');
      return result ?? {};
    } catch (_) {
      return {};
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

  /// Open overlay permission settings
  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
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
  static Future<void> startMission(List<String> blockedApps, String intensity) async {
    try {
      await _channel.invokeMethod('startMission', {
        'blockedApps': blockedApps,
        'intensity': intensity,
      });
    } catch (_) {}
  }

  /// Stop Mission Mode blocking
  static Future<void> stopMission() async {
    try {
      await _channel.invokeMethod('stopMission');
    } catch (_) {}
  }
}
