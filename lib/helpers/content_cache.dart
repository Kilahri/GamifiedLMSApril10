// lib/helpers/content_cache.dart
//
// Drop-in static cache so ReadScreen, WatchScreen, and
// TeacherContentManagement never hit Firestore more than once
// per app session (or after an explicit refresh).

import 'package:cloud_firestore/cloud_firestore.dart';

class ContentCache {
  ContentCache._();

  // ── Cached payloads ──────────────────────────────────────────────
  static Map<String, dynamic>? _teacherData;
  static DateTime? _fetchedAt;

  /// How long cached data is considered fresh (5 minutes by default).
  static const Duration _ttl = Duration(minutes: 5);

  /// Whether the cache is still valid.
  static bool get isValid =>
      _teacherData != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < _ttl;

  // ── Public API ───────────────────────────────────────────────────

  /// Returns teacher Firestore data.
  ///
  /// 1. Returns the in-memory cache instantly if still fresh.
  /// 2. Tries the Firestore *local cache* (zero network cost).
  /// 3. Falls back to a real network fetch.
  ///
  /// Pass [forceRefresh] = true after the teacher saves new content.
  static Future<Map<String, dynamic>> getTeacherData(
    String teacherUid, {
    bool forceRefresh = false,
  }) async {
    // ── 1. In-memory hit ───────────────────────────────────────────
    if (!forceRefresh && isValid) {
      return _teacherData!;
    }

    final ref = FirebaseFirestore.instance
        .collection('teacher_content')
        .doc(teacherUid);

    Map<String, dynamic>? data;

    // ── 2. Try Firestore local disk cache first (instant) ──────────
    if (!forceRefresh) {
      try {
        final snap = await ref
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 300));
        if (snap.exists) data = snap.data();
      } catch (_) {
        // Cache miss or timeout — fall through to network.
      }
    }

    // ── 3. Network fetch (with a reasonable timeout) ───────────────
    if (data == null) {
      try {
        final snap = await ref
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8));
        data = snap.data();
      } catch (e) {
        // Return whatever we have (possibly stale) rather than crashing.
        if (_teacherData != null) return _teacherData!;
        rethrow;
      }
    }

    _teacherData = data ?? {};
    _fetchedAt = DateTime.now();
    return _teacherData!;
  }

  /// Call this after the teacher saves content so the next read
  /// fetches fresh data from Firestore.
  static void invalidate() {
    _teacherData = null;
    _fetchedAt = null;
  }
}
