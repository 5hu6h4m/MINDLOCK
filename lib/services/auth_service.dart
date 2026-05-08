import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/hive_boxes.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestore = FirestoreService();

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      // Firebase not initialized
    }
  }

  bool get isAvailable => _auth != null;

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  Future<void> signInAnonymously() async {
    if (_auth == null) return;
    try {
      await _auth!.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> signInWithGoogle() async {
    if (_auth == null) return;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth!.signInWithCredential(credential);
    } catch (e) {
      rethrow;
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
    await _auth?.signOut();
  }
}
