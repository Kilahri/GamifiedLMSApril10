import 'package:cloud_firestore/cloud_firestore.dart';
import 'planet_model.dart';

class ScoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Score calculation ─────────────────────────────────────────────────

  static int calculateScore(PlanetModel planet) {
    return getBreakdown(planet).values.fold(0, (a, b) => a + b);
  }

  static Map<String, int> getBreakdown(PlanetModel planet) {
    final Map<String, int> scores = {};

    // Base size points
    scores['🪐 Size'] = (planet.size * 25).round();

    // Atmosphere
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
        scores['🌤 Atmosphere'] = 22; // complex = interesting
        break;
      case AtmosphereType.none:
        scores['🌤 Atmosphere'] = 5;
        break;
    }

    // Rings
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

    // Moons
    if (planet.moonCount > 0) {
      scores['🌙 Moons'] = planet.moonCount * 10;
    }

    // Surface type
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

    // Star type
    switch (planet.starType) {
      case StarType.blueGiant:
        scores['☀️ Star'] = 28;
        break;
      case StarType.binaryStar:
        scores['☀️ Star'] = 24;
        break;
      case StarType.neutronStar:
        scores['☀️ Star'] = 30; // exotic
        break;
      case StarType.yellowStar:
        scores['☀️ Star'] = 18;
        break;
      case StarType.redDwarf:
        scores['☀️ Star'] = 12;
        break;
    }

    // Magnetic field
    if (planet.magneticField) scores['🧲 Magnetic Field'] = 20;

    // Tectonic activity
    if (planet.tectonicActivity > 0) {
      scores['🌋 Tectonics'] = planet.tectonicActivity * 6;
    }

    // Oceans
    if (planet.hasOceans) scores['🌊 Oceans'] = 25;

    // Cloud coverage (interesting appearance)
    if (planet.cloudCoverage > 20) {
      scores['☁️ Clouds'] = (planet.cloudCoverage / 10).round();
    }

    // Life bonus — biggest reward
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

    // Habitable zone bonus
    if (planet.orbitalDistance >= 0.7 && planet.orbitalDistance <= 1.5) {
      scores['🎯 Habitable Zone'] = 15;
    }

    // Day length variety bonus
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
          'userId': userId, // ← required for the where() query
          'username': username,
          'score': score,
          'createdAt': FieldValue.serverTimestamp(), // ← required for orderBy
        });

    // Save to the top-level collection that _MyPlanetsTab queries
    await _db.collection('user_planets').add(data);

    // Update leaderboard high score
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

  static Future<void> deleteCustomPlanet(String docId) async {
    // docId is just the document ID, not a full path
    await _db.collection('user_planets').doc(docId).delete();
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
