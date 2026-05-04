import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RatingService {
  static final _db = FirebaseFirestore.instance;

  // ── Submit / update a rating ────────────────────────────────────────────────
  static Future<void> submitRating({
    required String planetDocId,
    required String raterId,
    required String raterName,
    required String ownerUserId,
    required String ownerUsername,
    required String planetName,
    required String planetType,
    required int rating,
  }) async {
    final ref = _db.collection('planet_ratings').doc(planetDocId);
    final now = DateTime.now().toIso8601String();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing =
          snap.exists
              ? Map<String, dynamic>.from(snap.data()!)
              : <String, dynamic>{};

      final ratings = Map<String, dynamic>.from(existing['ratings'] ?? {});

      ratings[raterId] = {
        'rating': rating,
        'raterName': raterName,
        'ratedAt': now,
      };

      int total = 0;
      ratings.forEach((_, v) => total += ((v as Map)['rating'] as int? ?? 0));
      final count = ratings.length;
      final avg = count > 0 ? total / count : 0.0;

      tx.set(ref, {
        'ownerUserId': ownerUserId,
        'ownerUsername': ownerUsername,
        'planetName': planetName,
        'planetType': planetType,
        'ratings': ratings,
        'averageRating': avg,
        'ratingCount': count,
        'updatedAt': now,
      }, SetOptions(merge: true));
    });

    // Replace ISO string with a real server timestamp after the transaction
    await ref.update({'updatedAt': FieldValue.serverTimestamp()});

    // Update the leaderboard (non-blocking — error here must not crash the rating)
    try {
      await _updateLeaderboard(ownerUserId, ownerUsername);
    } catch (e) {
      debugPrint('RatingService._updateLeaderboard error (non-fatal): $e');
    }
  }

  // ── Check if a user already rated ──────────────────────────────────────────
  static Future<bool> hasRated({
    required String planetDocId,
    required String raterId,
  }) async {
    try {
      final snap =
          await _db.collection('planet_ratings').doc(planetDocId).get();
      if (!snap.exists) return false;
      final ratings = Map<String, dynamic>.from(snap.data()?['ratings'] ?? {});
      return ratings.containsKey(raterId);
    } catch (e) {
      debugPrint('RatingService.hasRated error: $e');
      return false;
    }
  }

  // ── Live rating stream for a single planet ──────────────────────────────────
  static Stream<DocumentSnapshot> ratingStream(String planetDocId) =>
      _db.collection('planet_ratings').doc(planetDocId).snapshots();

  // ── Get all raters for a planet ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPlanetRaters(
    String planetDocId,
  ) async {
    try {
      final snap =
          await _db.collection('planet_ratings').doc(planetDocId).get();
      if (!snap.exists) return [];
      final ratings = Map<String, dynamic>.from(snap.data()?['ratings'] ?? {});
      final list =
          ratings.entries.map((e) {
              final v = e.value as Map;
              return {
                'userId': e.key,
                'raterName': v['raterName'] ?? 'Unknown',
                'rating': v['rating'] ?? 0,
                'ratedAt': v['ratedAt'] ?? '',
              };
            }).toList()
            ..sort(
              (a, b) => (b['rating'] as int).compareTo(a['rating'] as int),
            );
      return list;
    } catch (e) {
      debugPrint('RatingService.getPlanetRaters error: $e');
      return [];
    }
  }

  // ── Delete all ratings for a planet ────────────────────────────────────────
  static Future<void> deletePlanetRatings({
    required String planetDocId,
    required String ownerUserId,
    required String ownerUsername,
  }) async {
    try {
      await _db.collection('planet_ratings').doc(planetDocId).delete();
      await _updateLeaderboard(ownerUserId, ownerUsername);
    } catch (e) {
      debugPrint('RatingService.deletePlanetRatings error: $e');
    }
  }

  // ── Update the per-owner leaderboard entry ──────────────────────────────────
  static Future<void> _updateLeaderboard(
    String ownerUserId,
    String ownerUsername,
  ) async {
    final snap =
        await _db
            .collection('planet_ratings')
            .where('ownerUserId', isEqualTo: ownerUserId)
            .get();

    final qualifying =
        snap.docs
            .where((d) => ((d.data()['ratingCount'] as int?) ?? 0) >= 3)
            .toList()
          ..sort((a, b) {
            final aR = (a.data()['averageRating'] as num?)?.toDouble() ?? 0.0;
            final bR = (b.data()['averageRating'] as num?)?.toDouble() ?? 0.0;
            return bR.compareTo(aR);
          });

    final lbRef = _db.collection('planet_rating_leaderboard').doc(ownerUserId);

    if (qualifying.isEmpty) {
      await lbRef.delete();
      return;
    }

    final best = qualifying.first;
    final d = best.data();

    await lbRef.set({
      'ownerUserId': ownerUserId,
      'username': ownerUsername,
      'bestPlanetId': best.id,
      'bestPlanetName': d['planetName'] ?? 'Unknown',
      'bestPlanetType': d['planetType'] ?? '',
      'averageRating': (d['averageRating'] as num?)?.toDouble() ?? 0.0,
      'ratingCount': d['ratingCount'] ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Leaderboard stream ──────────────────────────────────────────────────────
  //
  // FIX: The original used .orderBy('averageRating', descending: true) which
  // requires a Firestore composite index. If that index hasn't been created in
  // the Firebase console, the stream emits a FirebaseException and the
  // leaderboard screen spins forever.
  //
  // We now fetch the full collection (no orderBy) and sort client-side.
  // planet_rating_leaderboard has at most one doc per student, so the
  // collection will never be large — client-side sort is perfectly fine.
  //
  // If you DO want server-side ordering, go to:
  //   Firebase Console → Firestore → Indexes → Create composite index:
  //     Collection: planet_rating_leaderboard
  //     Fields:     averageRating DESC
  // Then revert to: .orderBy('averageRating', descending: true).snapshots()
  static Stream<QuerySnapshot> leaderboardStream() =>
      _db.collection('planet_rating_leaderboard').snapshots();
  //           ↑ No orderBy — avoids the missing-index error.
  //             PlanetRatingLeaderboardScreen sorts the docs itself (see below).
}
