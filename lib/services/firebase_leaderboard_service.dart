import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseLeaderboardService {
  static final _db = FirebaseFirestore.instance;

  // Canonical game name constants — use these in every game
  static const String GAME_SCIENCE_FUSION = 'Science Fusion Lab';
  static const String GAME_QUIZ = 'Quiz';
  static const String GAME_MATCHING = 'Matching Game';
  static const String GAME_CROSSWORD = 'crossword';
  static const String GAME_PLANET_BUILDER = 'Planet Builder';

  // ── Core save ──────────────────────────────────────────────────────────────
  /// Saves a score for [gameName]. Only writes if [score] beats the stored best.
  /// Also updates the user's aggregate totalScore for the combined leaderboard.
  static Future<void> saveScore({
    required String gameName,
    required int score,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final username =
        prefs.getString('username') ?? user.displayName ?? 'Player';

    String displayName = username;
    String leaderboardName = username;
    String? photoUrl;
    String? section; // ← NEW

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        displayName = data['displayName'] ?? username;
        leaderboardName = data['leaderboardName'] ?? displayName;
        photoUrl = data['photoUrl'];
        section = data['section']; // ← NEW
      }
    } catch (_) {}

    final userId = user.uid;
    final docRef = _db.collection('leaderboard').doc(userId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final existing = snap.exists ? (snap.data() ?? {}) : {};
      final games = Map<String, dynamic>.from(existing['games'] ?? {});
      final prevBest = (games[gameName]?['score'] ?? 0) as int;

      if (score <= prevBest) return;

      games[gameName] = {
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
        ...metadata,
      };

      final total = games.values
          .map((g) => (g['score'] ?? 0) as int)
          .fold<int>(0, (a, b) => a + b);

      tx.set(docRef, {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'leaderboardName': leaderboardName,
        'photoUrl': photoUrl,
        'section': section, // ← NEW
        'totalScore': total,
        'gamesPlayed': games.length,
        'games': games,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // ── Leaderboard reads ──────────────────────────────────────────────────────
  /// Combined leaderboard — ranked by totalScore across all games.
  static Future<List<Map<String, dynamic>>> getOverallLeaderboard({
    int limit = 50,
  }) async {
    final snap =
        await _db
            .collection('leaderboard')
            .orderBy('totalScore', descending: true)
            .limit(limit)
            .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Per-game leaderboard — pass one of the GAME_* constants.
  static Future<List<Map<String, dynamic>>> getGameLeaderboard({
    required String gameName,
    int limit = 50,
  }) async {
    final snap = await _db.collection('leaderboard').get();

    final entries =
        snap.docs
            .map((d) => d.data())
            .where((d) => (d['games'] as Map?)?.containsKey(gameName) == true)
            .map(
              (d) => {
                'userId': d['userId'],
                'username': d['username'],
                'displayName': d['displayName'],
                'leaderboardName': d['leaderboardName'],
                'photoUrl': d['photoUrl'],
                'section': d['section'], // ← NEW
                'score': (d['games'][gameName]['score'] ?? 0) as int,
                'updatedAt': d['games'][gameName]['updatedAt'],
              },
            )
            .toList();

    entries.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return entries.take(limit).toList();
  }

  /// Current user's best score for a specific game. Returns 0 if none.
  static Future<int> getPersonalBest(String gameName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final snap = await _db.collection('leaderboard').doc(user.uid).get();
    if (!snap.exists) return 0;
    return (snap.data()?['games']?[gameName]?['score'] ?? 0) as int;
  }

  /// Current user's uid — convenience getter.
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}
