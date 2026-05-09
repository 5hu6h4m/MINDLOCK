import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/models/user_stats_model.dart';
import '../data/local/models/daily_reflection_model.dart';
import '../data/local/models/reminder_model.dart';
import '../data/local/models/mission_model.dart';
import '../data/local/models/timetable_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  final firestore = FirestoreService();
  return DataSyncService(ref, firestore);
});

class DataSyncService {
  final Ref _ref;
  final FirestoreService _firestore;

  DataSyncService(this._ref, this._firestore);

  Future<void> fullSync() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) {
      debugPrint('MINDLOCK: No user logged in, skipping sync.');
      return;
    }

    try {
      debugPrint('MINDLOCK: Starting Full Cloud Sync for ${user.email}...');

      // 1. Sync User Stats
      final cloudStats = await _firestore.downloadUserStats();
      final localStats = HiveBoxes.userStats.get('main') ?? UserStatsModel();
      
      if (cloudStats != null) {
        if ((cloudStats['totalFocusPoints'] ?? 0) > localStats.totalFocusPoints) {
          final updatedStats = localStats.copyWith(
            totalFocusPoints: cloudStats['totalFocusPoints'],
            missionsCompleted: cloudStats['missionsCompleted'],
            missionsFailed: cloudStats['missionsFailed'],
            currentStreak: cloudStats['currentStreak'],
            longestStreak: cloudStats['longestStreak'],
          );
          await HiveBoxes.userStats.put('main', updatedStats);
        } else {
          await _firestore.uploadUserStats(localStats);
        }
      } else {
        await _firestore.uploadUserStats(localStats);
      }

      // 2. Sync Reminders
      final cloudReminders = await _firestore.downloadReminders();
      for (var data in cloudReminders) {
        final id = data['id'];
        if (id != null && !HiveBoxes.reminders.containsKey(id)) {
          final reminder = ReminderModel(
            id: id,
            title: data['title'],
            description: data['description'] ?? '',
            dateTime: DateTime.parse(data['dateTime']),
            isCompleted: data['isCompleted'] ?? false,
            priorityIndex: data['priority'] ?? 0,
            createdAt: DateTime.now(),
          );
          await HiveBoxes.reminders.put(id, reminder);
        }
      }
      await _firestore.syncReminders();

      // 3. Sync Missions
      final cloudMissions = await _firestore.downloadMissions();
      for (var data in cloudMissions) {
        final id = data['id'];
        if (id != null && !HiveBoxes.missions.containsKey(id)) {
          final mission = MissionModel(
            id: id,
            title: data['title'],
            categoryIndex: data['categoryIndex'] ?? 0,
            durationMinutes: data['durationMinutes'],
            intensityIndex: data['intensityIndex'] ?? 0,
            isCompleted: data['isCompleted'] ?? false,
            startTime: DateTime.parse(data['startTime']),
            endTime: data['endTime'] != null ? DateTime.parse(data['endTime']) : null,
            escapeAttempts: data['escapeAttempts'] ?? 0,
            focusPointsEarned: data['focusPointsEarned'] ?? 0,
            blockedApps: List<String>.from(data['blockedApps'] ?? []),
          );
          await HiveBoxes.missions.put(id, mission);
        }
      }
      await _firestore.syncMissions();

      // 4. Sync Timetable
      final cloudTT = await _firestore.downloadTimetable();
      for (var data in cloudTT) {
        final id = data['id'];
        if (id != null && !HiveBoxes.timetable.containsKey(id)) {
          final entry = TimetableSlot(
            subject: data['subject'],
            dayOfWeek: data['dayOfWeek'] ?? 1,
            startHour: data['startHour'] ?? 0,
            startMinute: data['startMinute'] ?? 0,
            endHour: data['endHour'] ?? 0,
            endMinute: data['endMinute'] ?? 0,
            isAutoSilent: data['isAutoSilent'] ?? true,
          );
          await HiveBoxes.timetable.put(id, entry);
        }
      }
      await _firestore.syncTimetable();

      // 5. Sync Reflections
      final cloudReflections = await _firestore.downloadReflections();
      for (var data in cloudReflections) {
        final id = data['id'];
        if (id != null && !HiveBoxes.reflections.containsKey(id)) {
          final reflection = DailyReflectionModel(
            id: id,
            date: DateTime.parse(data['date']),
            summary: data['summary'],
            appUsage: Map<String, int>.from(data['appUsage']),
            aiVerdict: data['aiVerdict'],
            moodIndex: data['moodIndex'],
            isSynced: true,
          );
          await HiveBoxes.reflections.put(id, reflection);
        }
      }

      debugPrint('MINDLOCK: Full Cloud Sync Completed Successfully.');
    } catch (e) {
      debugPrint('MINDLOCK: Sync Error: $e');
    }
  }

  Future<void> pushStats() async {
    final stats = HiveBoxes.userStats.get('main');
    if (stats != null) {
      await _firestore.uploadUserStats(stats);
    }
  }
}
