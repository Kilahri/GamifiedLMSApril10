// lib/services/firebase_service.dart
// Central Firebase service — import this in all screens

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Converts username → synthetic email for Firebase Auth
  static String _toEmail(String username) =>
      '${username.toLowerCase()}@scilearn.internal';

  // ─────────────────────────────────────────
  //  AUTH
  // ─────────────────────────────────────────

  static Future<UserCredential> signUp({
    required String username,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: _toEmail(username),
      password: password,
    );
  }

  static Future<UserCredential> signIn({
    required String username,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: _toEmail(username),
      password: password,
    );
  }

  static Future<void> signOut() => _auth.signOut();

  static User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────
  //  USER PROFILE (Firestore)
  // ─────────────────────────────────────────

  static Future<void> createUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set(data);
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // Find user by username — used by admin panel and forgot-password
  static Future<Map<String, dynamic>?> findUserByUsername(
    String username,
  ) async {
    final query =
        await _db
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
    if (query.docs.isEmpty) return null;
    return {...query.docs.first.data(), 'uid': query.docs.first.id};
  }

  // Get all users by role (for admin panel)
  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final query =
        await _db.collection('users').where('role', isEqualTo: role).get();
    return query.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList();
  }

  // Activate / deactivate a user (admin panel)
  static Future<void> setUserActive(String uid, bool isActive) async {
    await _db.collection('users').doc(uid).update({'isActive': isActive});
  }

  // ─────────────────────────────────────────
  //  ADMIN: Create teacher/student using
  //  secondary app (avoids signing out admin)
  // ─────────────────────────────────────────

  static Future<String> adminCreateTeacher({
    required String username,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'teacherCreate_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _toEmail(username),
        password: password,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      // Save profile + store password so admin can reset it later
      await _db.collection('users').doc(uid).set({
        ...profileData,
        'password': password, // stored for admin password-reset flow
      });

      return uid;
    } finally {
      await secondaryApp?.delete();
    }
  }

  // ─────────────────────────────────────────
  //  ADMIN: Update another user's password
  //  (uses secondary app — admin stays signed in)
  // ─────────────────────────────────────────

  static Future<void> adminUpdateUserPassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'pwUpdate_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Sign in as that user using their synthetic email + stored password
      final credential = await secondaryAuth.signInWithEmailAndPassword(
        email: _toEmail(username),
        password: currentPassword,
      );

      // Update to new password
      await credential.user!.updatePassword(newPassword);
      await secondaryAuth.signOut();
    } finally {
      await secondaryApp?.delete();
    }
  }

  // ─────────────────────────────────────────
  //  LEADERBOARD
  // ─────────────────────────────────────────

  static Future<void> updateLeaderboard({
    required String uid,
    required String displayName,
    required int xp,
    int score = 0,
  }) async {
    await _db.collection('leaderboard').doc(uid).set({
      'displayName': displayName,
      'xp': xp,
      'score': score,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream for real-time leaderboard updates
  static Stream<QuerySnapshot> getLeaderboardStream() {
    return _db
        .collection('leaderboard')
        .orderBy('xp', descending: true)
        .limit(50)
        .snapshots();
  }

  // One-time fetch of leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final query =
        await _db
            .collection('leaderboard')
            .orderBy('xp', descending: true)
            .limit(50)
            .get();
    return query.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList();
  }

  // ─────────────────────────────────────────
  //  QUIZ RESULTS
  // ─────────────────────────────────────────

  static Future<void> saveQuizResult({
    required String uid,
    required String quizId,
    required int score,
    required int xp,
    required int totalQuestions,
    Map<String, dynamic>? answers,
  }) async {
    await _db.collection('users').doc(uid).collection('quiz_results').add({
      'quizId': quizId,
      'score': score,
      'xp': xp,
      'totalQuestions': totalQuestions,
      'answers': answers ?? {},
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getQuizResults(String uid) async {
    final query =
        await _db
            .collection('users')
            .doc(uid)
            .collection('quiz_results')
            .orderBy('completedAt', descending: true)
            .get();
    return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  // Get best score for a specific quiz
  static Future<int> getBestScore(String uid, String quizId) async {
    final query =
        await _db
            .collection('users')
            .doc(uid)
            .collection('quiz_results')
            .where('quizId', isEqualTo: quizId)
            .orderBy('score', descending: true)
            .limit(1)
            .get();
    if (query.docs.isEmpty) return 0;
    return query.docs.first.data()['score'] as int? ?? 0;
  }

  // Get total XP for a user
  static Future<int> getTotalXP(String uid) async {
    final query =
        await _db.collection('users').doc(uid).collection('quiz_results').get();
    int total = 0;
    for (final doc in query.docs) {
      total += (doc.data()['xp'] as int? ?? 0);
    }
    return total;
  }
}
