import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/hive_boxes.dart';
import '../local/models/daily_reflection_model.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  return ReflectionRepository();
});

class ReflectionRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<DailyReflectionModel> getAll() {
    return HiveBoxes.reflections.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  DailyReflectionModel? getByDate(DateTime date) {
    final id = _getDateId(date);
    return HiveBoxes.reflections.get(id);
  }

  Future<void> saveReflection(DailyReflectionModel reflection) async {
    // Save locally
    await HiveBoxes.reflections.put(reflection.id, reflection);

    // Sync to Cloud if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('reflections')
            .doc(reflection.id)
            .set(reflection.toMap());
        
        await HiveBoxes.reflections.put(
          reflection.id, 
          reflection.copyWith(isSynced: true)
        );
      } catch (e) {
        print('Cloud sync failed: $e');
      }
    }
  }

  Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('reflections')
          .get();

      for (var doc in snapshot.docs) {
        final reflection = DailyReflectionModel.fromMap(doc.data());
        if (!HiveBoxes.reflections.containsKey(reflection.id)) {
          await HiveBoxes.reflections.put(reflection.id, reflection);
        }
      }
    } catch (e) {
      print('Download from cloud failed: $e');
    }
  }

  String _getDateId(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }
}
