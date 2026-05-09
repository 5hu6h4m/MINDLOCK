import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/local/models/user_stats_model.dart';
import '../data/local/models/reminder_model.dart';
import '../data/local/models/mission_model.dart';
import '../data/local/models/timetable_model.dart';
import '../data/local/hive_boxes.dart';

class FirestoreService {
  FirebaseFirestore? _db;
  FirebaseAuth? _auth;

  FirestoreService() {
    try {
      _db = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    } catch (e) {
      // Firebase not initialized
    }
  }

  String? get uid => _auth?.currentUser?.uid;

  // ── User Data Sync ────────────────────────────────────────────────────────

  Future<void> uploadUserStats(UserStatsModel stats) async {
    if (uid == null || _db == null) return;
    await _db!.collection('users').doc(uid).set({
      'stats': {
        'totalFocusPoints': stats.totalFocusPoints,
        'missionsCompleted': stats.missionsCompleted,
        'missionsFailed': stats.missionsFailed,
        'currentStreak': stats.currentStreak,
        'longestStreak': stats.longestStreak,
        'lastUpdateDate': stats.lastUpdateDate?.toIso8601String(),
      }
    }, SetOptions(merge: true));
  }

  Future<void> syncReminders() async {
    if (uid == null || _db == null) return;
    final reminders = HiveBoxes.reminders.values.toList();
    final batch = _db!.batch();
    
    // Clear existing cloud reminders to keep it in sync with local
    // (Simple approach: replace cloud with local state)
    final snapshot = await _db!.collection('users').doc(uid).collection('reminders').get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    for (var r in reminders) {
      final docRef = _db!.collection('users').doc(uid).collection('reminders').doc(r.id);
      batch.set(docRef, {
        'id': r.id,
        'title': r.title,
        'description': r.description,
        'dateTime': r.dateTime.toIso8601String(),
        'isCompleted': r.isCompleted,
        'priority': r.priorityIndex,
      });
    }
    await batch.commit();
  }

  Future<void> syncMissions() async {
    if (uid == null || _db == null) return;
    final missions = HiveBoxes.missions.values.toList();
    final batch = _db!.batch();
    
    for (var m in missions) {
      final docRef = _db!.collection('users').doc(uid).collection('missions').doc(m.id);
      batch.set(docRef, {
        'id': m.id,
        'title': m.title,
        'categoryIndex': m.categoryIndex,
        'durationMinutes': m.durationMinutes,
        'intensityIndex': m.intensityIndex,
        'startTime': m.startTime.toIso8601String(),
        'endTime': m.endTime?.toIso8601String(),
        'isCompleted': m.isCompleted,
        'escapeAttempts': m.escapeAttempts,
        'focusPointsEarned': m.focusPointsEarned,
        'blockedApps': m.blockedApps,
      });
    }
    await batch.commit();
  }

  Future<void> syncTimetable() async {
    if (uid == null || _db == null) return;
    final entries = HiveBoxes.timetable.values.toList();
    final batch = _db!.batch();
    
    for (var e in entries) {
      final docId = e.key?.toString() ?? e.subject;
      final docRef = _db!.collection('users').doc(uid).collection('timetable').doc(docId);
      batch.set(docRef, {
        'subject': e.subject,
        'dayOfWeek': e.dayOfWeek,
        'startHour': e.startHour,
        'startMinute': e.startMinute,
        'endHour': e.endHour,
        'endMinute': e.endMinute,
        'isAutoSilent': e.isAutoSilent,
      });
    }
    await batch.commit();
  }

  Future<void> uploadReflection(Map<String, dynamic> data) async {
    if (uid == null || _db == null) return;
    await _db!
        .collection('users')
        .doc(uid)
        .collection('reflections')
        .doc(data['id'])
        .set(data);
  }

  // ── Download (Restore) ──

  Future<Map<String, dynamic>?> downloadUserStats() async {
    if (uid == null || _db == null) return null;
    final doc = await _db!.collection('users').doc(uid).get();
    return doc.data()?['stats'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> downloadReminders() async {
    if (uid == null || _db == null) return [];
    final snapshot = await _db!.collection('users').doc(uid).collection('reminders').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> downloadMissions() async {
    if (uid == null || _db == null) return [];
    final snapshot = await _db!.collection('users').doc(uid).collection('missions').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> downloadTimetable() async {
    if (uid == null || _db == null) return [];
    final snapshot = await _db!.collection('users').doc(uid).collection('timetable').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> downloadReflections() async {
    if (uid == null || _db == null) return [];
    final snapshot = await _db!.collection('users').doc(uid).collection('reflections').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // ── Co-Focus Rooms ─────────────────────────────────────────────────────────

  Future<void> createRoom(String roomCode, int duration) async {
    if (uid == null || _db == null) return;
    await _db!.collection('rooms').doc(roomCode).set({
      'hostId': uid,
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'duration': duration,
      'members': [uid],
    });
  }

  Future<void> joinRoom(String roomCode) async {
    if (uid == null || _db == null) return;
    await _db!.collection('rooms').doc(roomCode).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  Stream<DocumentSnapshot>? watchRoom(String roomCode) {
    return _db?.collection('rooms').doc(roomCode).snapshots();
  }

  Future<void> updateRoomStatus(String roomCode, String status) async {
    if (_db == null) return;
    await _db!.collection('rooms').doc(roomCode).update({'status': status});
  }
}
