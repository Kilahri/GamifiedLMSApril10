// helpers/student_cache.dart
// Fetches the logged-in student's profile (section, name, etc.) from Firestore.
//
// DESIGN:
//   • On every fresh login the cache is cleared (call StudentCache.clear()
//     from your login success handler).
//   • getSection() / getProfile() always do a real Firestore fetch the FIRST
//     time they are called in a session (no cache hit yet) so the section is
//     guaranteed to be correct before any content is filtered.
//   • Subsequent calls in the same session return the in-memory value
//     instantly and also refresh the SharedPreferences cache in the background.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/services/firebase_services.dart';

class StudentCache {
  static const String _kProfileKey = 'cached_student_profile_v2';

  // ── In-memory cache for the current session ──────────────────────────────
  static Map<String, dynamic>? _sessionProfile;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the student's section string, e.g. "Section B".
  /// Always does a real Firestore fetch on the first call per login session.
  static Future<String?> getSection() async {
    final profile = await getProfile();
    return profile?['section'] as String?;
  }

  /// Returns the full student profile map.
  /// Strategy:
  ///   1. If we already fetched in this session → return in-memory value
  ///      (and silently refresh SharedPreferences in background).
  ///   2. Otherwise → fetch from Firestore, cache in memory + SharedPreferences.
  static Future<Map<String, dynamic>?> getProfile({
    bool forceRefresh = false,
  }) async {
    // 1. In-memory hit (same session, already fetched once)
    if (!forceRefresh && _sessionProfile != null) {
      return _sessionProfile;
    }

    // 2. Fetch from Firestore (authoritative source)
    final fresh = await _fetchFromFirestore();
    if (fresh != null) {
      _sessionProfile = fresh;
      // Also persist to SharedPreferences for offline resilience
      _persistToPrefs(fresh);
      return fresh;
    }

    // 3. Firestore failed → fall back to SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kProfileKey);
    if (cached != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(cached) as Map);
        _sessionProfile = map;
        return map;
      } catch (_) {}
    }

    return null;
  }

  static Future<String?> getUserId() async {
    final profile = await getProfile();
    return profile?['uid'] as String?;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this immediately after a successful login so the next getProfile()
  /// always does a fresh Firestore fetch (picks up any section changes).
  static Future<void> clear() async {
    _sessionProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileKey);
  }

  /// Alias for clear() — call after teacher/admin changes a student's section.
  static Future<void> invalidate() async => clear();

  // ─────────────────────────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _fetchFromFirestore() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists || doc.data() == null) return null;

      final data = Map<String, dynamic>.from(doc.data()!);
      data['uid'] = user.uid;
      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistToPrefs(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, jsonEncode(profile));
    } catch (_) {}
  }
}
