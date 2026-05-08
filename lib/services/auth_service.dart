import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/hive_boxes.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> syncDataToCloud() async {
    if (currentUser == null) return;
    
    final stats = HiveBoxes.userStats.get('main');
    if (stats != null) {
      await _firestore.uploadUserStats(stats);
    }
    await _firestore.syncReminders();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
