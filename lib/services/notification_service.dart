import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels
    await _createChannels();
  }

  static Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Normal reminder channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'MindLock_normal',
        'Normal Reminders',
        description: 'Standard reminder notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // High priority channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'MindLock_high',
        'High Priority Reminders',
        description: 'High priority reminders that demand attention',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF7C5CFC),
      ),
    );

    // Emergency channel - cannot be missed
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'MindLock_emergency',
        'Emergency Reminders',
        description: 'Emergency reminders that override DND',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF4560),
        bypassDnd: true,
      ),
    );

    // Foreground service channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'MindLock_service',
        'MindLock Service',
        description: 'Running in background to manage your reminders',
        importance: Importance.low,
        playSound: false,
      ),
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap actions
    final actionId = response.actionId;
    final payload = response.payload;
    debugPrint('Notification action: $actionId, payload: $payload');
  }

  // ─── Show Notifications ───────────────────────────────────────────────────

  static Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    required int priorityIndex,
    String? payload,
  }) async {
    final channelId = priorityIndex == 3
        ? 'MindLock_emergency'
        : priorityIndex >= 2
            ? 'MindLock_high'
            : 'MindLock_normal';

    final importance = priorityIndex >= 2 ? Importance.max : Importance.high;
    final priority = priorityIndex >= 2 ? Priority.max : Priority.high;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      priorityIndex == 3 ? 'Emergency Reminders' : 'Reminders',
      importance: importance,
      priority: priority,
      fullScreenIntent: priorityIndex >= 2,
      category: AndroidNotificationCategory.alarm,
      actions: const [
        AndroidNotificationAction('done', '✅ Done'),
        AndroidNotificationAction('snooze', '⏰ Snooze 10min'),
        AndroidNotificationAction('ignore', '❌ Ignore'),
      ],
      styleInformation: BigTextStyleInformation(body),
      color: const Color(0xFF7C5CFC),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> showServiceNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'MindLock_service',
      'MindLock Service',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    await _plugin.show(
      id: 999,
      title: 'MindLock Active',
      body: 'Monitoring your reminders and focus schedule',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
