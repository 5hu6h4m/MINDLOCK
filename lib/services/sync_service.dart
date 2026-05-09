import 'package:firebase_auth/firebase_auth.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/models/reminder_model.dart';
import '../data/local/models/mission_model.dart';
import '../data/local/models/timetable_model.dart';
import '../data/local/models/user_stats_model.dart';
import 'firestore_service.dart';

class SyncService {
  final FirestoreService _firestore = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isLoggedIn => _auth.currentUser != null;

  // ── Push to Cloud ──

  Future<void> pushAllData() async {
    if (!isLoggedIn) return;
    try {
      await _firestore.uploadUserStats(HiveBoxes.userStats.get('current')!);
      await _firestore.syncReminders();
      await _firestore.syncMissions();
      await _firestore.syncTimetable();
      print('MINDLOCK: All data pushed to cloud successfully');
    } catch (e) {
      print('MINDLOCK: Sync Push Error: $e');
    }
  }

  // ── Restore from Cloud ──

  Future<void> restoreAllData() async {
    if (!isLoggedIn) return;
    try {
      // 1. Restore Stats
      final statsMap = await _firestore.downloadUserStats();
      if (statsMap != null) {
        final stats = UserStatsModel(
          totalFocusPoints: statsMap['totalFocusPoints'] ?? 0,
          missionsCompleted: statsMap['missionsCompleted'] ?? 0,
          missionsFailed: statsMap['missionsFailed'] ?? 0,
          currentStreak: statsMap['currentStreak'] ?? 0,
          longestStreak: statsMap['longestStreak'] ?? 0,
          lastUpdateDate: statsMap['lastUpdateDate'] != null 
              ? DateTime.parse(statsMap['lastUpdateDate']) 
              : null,
        );
        await HiveBoxes.userStats.put('current', stats);
      }

      // 2. Restore Reminders
      final remindersList = await _firestore.downloadReminders();
      for (var r in remindersList) {
        final reminder = ReminderModel(
          id: r['id'],
          title: r['title'],
          description: r['description'],
          dateTime: DateTime.parse(r['dateTime']),
          isCompleted: r['isCompleted'] ?? false,
          priorityIndex: r['priority'] ?? 0,
        );
        await HiveBoxes.reminders.put(reminder.id, reminder);
      }

      // 3. Restore Missions
      final missionsList = await _firestore.downloadMissions();
      for (var m in missionsList) {
        final mission = MissionModel(
          id: m['id'],
          title: m['title'],
          durationMinutes: m['durationMinutes'],
          intensity: m['intensity'],
          isCompleted: m['isCompleted'] ?? false,
          date: DateTime.parse(m['date']),
          pointsAwarded: m['pointsAwarded'] ?? 0,
        );
        await HiveBoxes.missions.put(mission.id, mission);
      }

      // 4. Restore Timetable
      final ttList = await _firestore.downloadTimetable();
      for (var t in ttList) {
        final entry = TimetableModel(
          id: t['id'],
          subject: t['subject'],
          startTime: DateTime.parse(t['startTime']),
          endTime: DateTime.parse(t['endTime']),
          day: t['day'],
          isBreak: t['isBreak'] ?? false,
        );
        await HiveBoxes.timetable.put(entry.id, entry);
      }

      print('MINDLOCK: Cloud restore completed successfully');
    } catch (e) {
      print('MINDLOCK: Cloud Restore Error: $e');
    }
  }
}
