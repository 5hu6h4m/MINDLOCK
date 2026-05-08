import 'package:flutter/foundation.dart';
import 'platform_channel.dart';
import '../data/local/models/reminder_model.dart';

class AlarmService {
  static Future<void> initialize() async {
    // Native alarm doesn't need explicit initialization here
    debugPrint('MINDLOCK: Native Alarm Service Initialized');
  }

  static Future<void> scheduleReminder(ReminderModel reminder) async {
    final alarmId = reminder.id.hashCode.abs();
    
    // Use NATIVE Android scheduling for 100% reliability
    await PlatformChannel.scheduleNativeReminder(
      id: alarmId,
      title: reminder.title,
      body: reminder.description,
      timeMs: reminder.dateTime.millisecondsSinceEpoch,
      priority: reminder.priorityIndex,
      tone: reminder.tone,
    );
    
    debugPrint('MINDLOCK: Scheduled NATIVE alarm for ${reminder.title} at ${reminder.dateTime}');
  }

  static Future<void> cancelReminder(String reminderId) async {
    final alarmId = reminderId.hashCode.abs();
    await PlatformChannel.cancelNativeReminder(alarmId);
    debugPrint('MINDLOCK: Cancelled NATIVE alarm for $reminderId');
  }
}
