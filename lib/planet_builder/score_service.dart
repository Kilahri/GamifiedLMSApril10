import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/planet_builder/rating_service.dart'; // ← ADD
import 'planet_model.dart';

class ScoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Score calculation ─────────────────────────────────────────────────

  static int calculateScore(PlanetModel planet) {
    return getBreakdown(planet).values.fold(0, (a, b) => a + b);
  }

  static Map<String, int> getBreakdown(PlanetModel planet) {
    final Map<String, int> scores = {};

    scores['🪐 Size'] = (planet.size * 25).round();

    switch (planet.atmosphere) {
      case AtmosphereType.earth:
        scores['🌤 Atmosphere'] = 30;
        break;
      case AtmosphereType.thick:
        scores['🌤 Atmosphere'] = 18;
        break;
      case AtmosphereType.thin:
        scores['🌤 Atmosphere'] = 12;
        break;
      case AtmosphereType.toxic:
        scores['🌤 Atmosphere'] = 22;
        break;
      case AtmosphereType.none:
        scores['🌤 Atmosphere'] = 5;
        break;
    }

    if (planet.hasRings) {
      switch (planet.ringType) {
        case RingType.ice:
          scores['💫 Rings'] = 20;
          break;
        case RingType.rocky:
          scores['💫 Rings'] = 15;
          break;
        case RingType.dust:
          scores['💫 Rings'] = 10;
          break;
        case RingType.none:
          break;
      }
    }

    if (planet.moonCount > 0) {
      scores['🌙 Moons'] = planet.moonCount * 10;
    }

    switch (planet.surfaceType) {
      case SurfaceType.forest:
        scores['🌿 Surface'] = 35;
        break;
      case SurfaceType.oceanic:
        scores['🌿 Surface'] = 30;
        break;
      case SurfaceType.volcanic:
        scores['🌿 Surface'] = 18;
        break;
      case SurfaceType.frozen:
        scores['🌿 Surface'] = 12;
        break;
      case SurfaceType.desert:
        scores['🌿 Surface'] = 14;
        break;
      case SurfaceType.rocky:
        scores['🌿 Surface'] = 8;
        break;
    }

    switch (planet.starType) {
      case StarType.blueGiant:
        scores['☀️ Star'] = 28;
        break;
      case StarType.binaryStar:
        scores['☀️ Star'] = 24;
        break;
      case StarType.neutronStar:
        scores['☀️ Star'] = 30;
        break;
      case StarType.yellowStar:
        scores['☀️ Star'] = 18;
        break;
      case StarType.redDwarf:
        scores['☀️ Star'] = 12;
        break;
    }

    if (planet.magneticField) scores['🧲 Magnetic Field'] = 20;

    if (planet.tectonicActivity > 0) {
      scores['🌋 Tectonics'] = planet.tectonicActivity * 6;
    }

    if (planet.hasOceans) scores['🌊 Oceans'] = 25;

    if (planet.cloudCoverage > 20) {
      scores['☁️ Clouds'] = (planet.cloudCoverage / 10).round();
    }

    final lc = planet.lifeChance;
    if (lc >= 75) {
      scores['🌱 Life Bonus'] = 60;
    } else if (lc >= 55) {
      scores['🌱 Life Bonus'] = 40;
    } else if (lc >= 35) {
      scores['🌱 Life Bonus'] = 20;
    } else if (lc >= 15) {
      scores['🌱 Life Bonus'] = 10;
    }

    if (planet.orbitalDistance >= 0.7 && planet.orbitalDistance <= 1.5) {
      scores['🎯 Habitable Zone'] = 15;
    }

    if (planet.dayLength < 0.5 || planet.dayLength > 2.0) {
      scores['⏱ Exotic Day'] = 8;
    }

    return scores;
  }

  // ── Firestore ops ──────────────────────────────────────────────────────

  static Future<void> saveCustomPlanet({
    required String userId,
    required String username,
    required String planetName,
    required PlanetModel planet,
  }) async {
    final score = calculateScore(planet);
    final data =
        planet.toMap()..addAll({
          'planetName': planetName,
          'userId': userId,
          'username': username,
          'score': score,
          'createdAt': FieldValue.serverTimestamp(),
        });

    await _db.collection('user_planets').add(data);

    final userRef = _db.collection('planet_leaderboard').doc(userId);
    final snap = await userRef.get();
    if (!snap.exists || (snap.data()?['score'] ?? 0) < score) {
      await userRef.set({
        'userId': userId,
        'username': username,
        'score': score,
        'planetName': planetName,
        'planetType': planet.planetType,
        'lifeChance': planet.lifeChance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── UPDATED: also deletes ratings + leaderboard entry ─────────────────
  static Future<void> deleteCustomPlanet({
    required String docId,
    required String ownerUserId,
    required String ownerUsername,
  }) async {
    // 1. Delete the planet document
    await _db.collection('user_planets').doc(docId).delete();

    // 2. Delete its ratings and update the rating leaderboard
    await RatingService.deletePlanetRatings(
      planetDocId: docId,
      ownerUserId: ownerUserId,
      ownerUsername: ownerUsername,
    );

    // 3. Recalculate the score-based leaderboard for this user
    //    (find their next best planet, or remove them if none left)
    try {
      final remaining =
          await _db
              .collection('user_planets')
              .where('userId', isEqualTo: ownerUserId)
              .orderBy('score', descending: true)
              .limit(1)
              .get();

      final lbRef = _db.collection('planet_leaderboard').doc(ownerUserId);

      if (remaining.docs.isEmpty) {
        await lbRef.delete();
      } else {
        final best = remaining.docs.first.data();
        await lbRef.set({
          'userId': ownerUserId,
          'username': ownerUsername,
          'score': best['score'] ?? 0,
          'planetName': best['planetName'] ?? 'Unknown',
          'planetType': best['planetType'] ?? '',
          'lifeChance': best['lifeChance'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Non-critical — leaderboard will self-correct next save
    }
  }

  static String scoreLabel(int score) {
    if (score >= 250) return 'Legendary World';
    if (score >= 180) return 'Exceptional';
    if (score >= 120) return 'Remarkable';
    if (score >= 70) return 'Decent';
    return 'Starter Planet';
  }

  static Future<int?> getUserRank(String userId) async {
    try {
      final snap =
          await _db
              .collection('planet_leaderboard')
              .orderBy('score', descending: true)
              .get();

      if (snap.docs.isEmpty) return null;
      final index = snap.docs.indexWhere((d) => d.id == userId);
      if (index == -1) return null;
      return index + 1;
    } catch (_) {
      return null;
    }
  }
}
