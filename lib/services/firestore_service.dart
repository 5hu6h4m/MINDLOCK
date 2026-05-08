import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/local/models/user_stats_model.dart';
import '../data/local/models/reminder_model.dart';
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
    
    for (var r in reminders) {
      final docRef = _db!.collection('users').doc(uid).collection('reminders').doc(r.id);
      batch.set(docRef, {
        'title': r.title,
        'description': r.description,
        'dateTime': r.dateTime.toIso8601String(),
        'isCompleted': r.isCompleted,
        'priority': r.priorityIndex,
      });
    }
    await batch.commit();
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
