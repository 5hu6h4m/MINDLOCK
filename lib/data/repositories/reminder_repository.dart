import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../local/models/reminder_model.dart';
import '../../services/alarm_service.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

class ReminderRepository {
  final _uuid = const Uuid();

  Box<ReminderModel> get _box => HiveBoxes.reminders;

  // ─── CRUD ────────────────────────────────────────────────────────────────

  Future<ReminderModel> createReminder({
    required String title,
    String description = '',
    required DateTime dateTime,
    int priorityIndex = 1,
    int repeatIntervalMinutes = 5,
    int repeatCount = 1,
    bool isFullScreenMode = false,
    bool isStrictMode = false,
    int strictTypeIndex = 0,
    bool isPersistent = false,
    int vibrationIntensity = 1,
    String tone = 'default',
  }) async {
    final reminder = ReminderModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      dateTime: dateTime,
      priorityIndex: priorityIndex,
      repeatIntervalMinutes: repeatIntervalMinutes,
      repeatCount: repeatCount,
      remainingRepeats: repeatCount,
      isFullScreenMode: isFullScreenMode,
      isStrictMode: isStrictMode,
      strictTypeIndex: strictTypeIndex,
      isPersistent: isPersistent,
      vibrationIntensity: vibrationIntensity,
      createdAt: DateTime.now(),
      tone: tone,
    );
    await _box.put(reminder.id, reminder);
    
    // Schedule alarm (Ensure it's done)
    try {
      await AlarmService.scheduleReminder(reminder);
      debugPrint('MINDLOCK: Real Alarm scheduled for ${reminder.title}');
    } catch (e) {
      debugPrint('MINDLOCK: Real Alarm scheduling failed: $e');
    }
    
    return reminder;
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await _box.put(reminder.id, reminder);
    await AlarmService.scheduleReminder(reminder);
  }

  Future<void> deleteReminder(String id) async {
    await _box.delete(id);
    await AlarmService.cancelReminder(id);
  }

  Future<void> markCompleted(String id) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.isCompleted = true;
      reminder.completedAt = DateTime.now();
      await reminder.save();
    }
  }

  Future<void> markIgnored(String id) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.isIgnored = true;
      await reminder.save();
    }
  }

  Future<void> snooze(String id, {int minutes = 10}) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.dateTime = DateTime.now().add(Duration(minutes: minutes));
      reminder.snoozeCount++;
      await reminder.save();
    }
  }

  Future<void> rescheduleToDate(String id, DateTime newDate) async {
    final reminder = _box.get(id);
    if (reminder != null) {
      reminder.dateTime = newDate;
      await reminder.save();
    }
  }

  Future<void> decrementRepeat(String id) async {
    final reminder = _box.get(id);
    if (reminder != null && reminder.remainingRepeats > 0) {
      reminder.remainingRepeats--;
      if (reminder.remainingRepeats <= 0) {
        reminder.isCompleted = true;
      }
      await reminder.save();
    }
  }

  // ─── Queries ─────────────────────────────────────────────────────────────

  List<ReminderModel> getAll() => _box.values.toList();

  List<ReminderModel> getToday() {
    final now = DateTime.now();
    return _box.values.where((r) {
      return !r.isCompleted &&
          !r.isIgnored &&
          r.dateTime.year == now.year &&
          r.dateTime.month == now.month &&
          r.dateTime.day == now.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<ReminderModel> getHistoryForDate(DateTime date) {
    return _box.values.where((r) {
      return r.dateTime.year == date.year &&
          r.dateTime.month == date.month &&
          r.dateTime.day == date.day;
    }).toList();
  }

  List<ReminderModel> getPending() {
    final now = DateTime.now();
    return _box.values.where((r) {
      return !r.isCompleted && !r.isIgnored && r.dateTime.isAfter(now);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<ReminderModel> getCompleted() {
    return _box.values.where((r) => r.isCompleted).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt)
          .compareTo(a.completedAt ?? a.createdAt));
  }

  List<ReminderModel> getEmergency() {
    return _box.values
        .where((r) => r.priorityIndex == 3 && !r.isCompleted)
        .toList();
  }

  ReminderModel? getById(String id) => _box.get(id);

  // ─── Analytics ───────────────────────────────────────────────────────────

  int get totalCompleted => _box.values.where((r) => r.isCompleted).length;
  int get totalIgnored => _box.values.where((r) => r.isIgnored).length;
  int get totalPending => _box.values.where((r) => !r.isCompleted && !r.isIgnored).length;

  double get completionRate {
    final total = _box.length;
    if (total == 0) return 0;
    return totalCompleted / total;
  }

  // Added for Badge Logic
  List<ReminderModel> getCompletedAfter(int hour) {
    return _box.values.where((r) => r.isCompleted && r.dateTime.hour >= hour).toList();
  }

  int get totalMissionsCompleted => _box.values.where((r) => r.isCompleted && r.title.toLowerCase().contains('mission')).length;

  Map<int, List<int>> getWeeklyStats() {
    final now = DateTime.now();
    final stats = <int, List<int>>{}; // dayOffset -> [completed, ignored]

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = _box.values.where((r) {
        return r.dateTime.year == date.year &&
            r.dateTime.month == date.month &&
            r.dateTime.day == date.day;
      });

      final completed = dayTasks.where((r) => r.isCompleted).length;
      final ignored = dayTasks.where((r) => r.isIgnored).length;
      stats[6 - i] = [completed, ignored];
    }
    return stats;
  }
}
