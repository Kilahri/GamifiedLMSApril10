// helpers/content_fetcher.dart
// Central helper that:
//  • Loads teacher_content docs from ALL teachers in Firestore
//  • Merges them with default (hardcoded) content
//  • ALWAYS filters teacher-created content by the student's section
//  • Caches the RAW (unfiltered) data; filtering always runs on top of it
//    so a stale cache never leaks wrong-section content to a student.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:elearningapp_flutter/data/video_data.dart';
import 'package:elearningapp_flutter/screens/read_screen.dart'
    show scienceBooks, spaceBooks, Book, BookChapter, QuizQuestion;
import 'package:elearningapp_flutter/helpers/video_upload_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CACHE KEYS  (raw, unfiltered data)
// ─────────────────────────────────────────────────────────────────────────────
const String _kRawVideos = 'cf_raw_videos_v2';
const String _kRawBooks = 'cf_raw_books_v2';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

class ContentFetcher {
  // ── In-memory teacher-name lookup (session only) ──────────────────────────
  static final Map<String, String> _teacherNameCache = {};

  // ── Invalidate raw cache (call after teacher saves content) ───────────────
  static Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRawVideos);
    await prefs.remove(_kRawBooks);
    _teacherNameCache.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VIDEOS
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns videos the student should see:
  ///   • ALL default (SciLearn) videos — visible to every section
  ///   • Teacher-created videos whose [sections] list contains [studentSection]
  ///
  /// The filter ALWAYS runs — even when data comes from cache — so a stale
  /// cache can never show wrong-section content to a student.
  static Future<List<Map<String, dynamic>>> getVideosForSection(
    String? studentSection, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> raw;

    if (!forceRefresh) {
      final cached = prefs.getString(_kRawVideos);
      if (cached != null) {
        try {
          raw = List<Map<String, dynamic>>.from(
            (jsonDecode(cached) as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          // Refresh in background so next call gets fresher data
          _refreshRawVideos(prefs);
          // ALWAYS filter with the current section — never return raw directly
          return _filterBySection(raw, studentSection);
        } catch (_) {}
      }
    }

    // No cache or force-refresh: fetch synchronously then filter
    raw = await _refreshRawVideos(prefs);
    return _filterBySection(raw, studentSection);
  }

  /// Fetches all teacher_content docs, merges with defaults, saves raw cache.
  static Future<List<Map<String, dynamic>>> _refreshRawVideos(
    SharedPreferences prefs,
  ) async {
    // 1. Build default lessons (always visible, sections = [])
    final List<Map<String, dynamic>> defaults = [];
    int idx = 0;
    for (final lesson in scienceLessons) {
      defaults.add({
        ..._lessonToMap(lesson),
        'id': 'default_video_$idx',
        'isDefault': true,
        'sections': <String>[], // empty = visible to all sections
        'teacherName': 'SciLearn',
        'teacherUid': '',
      });
      idx++;
    }

    // 2. Fetch every teacher_content document
    final List<Map<String, dynamic>> teacherVideos = [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teacher_content')
          .get()
          .timeout(const Duration(seconds: 10));

      for (final doc in snapshot.docs) {
        final teacherUid = doc.id;
        final data = doc.data();
        final teacherName = await _getTeacherName(teacherUid);

        // ── Apply teacher modifications / deletions to defaults ──
        final modifiedMap = Map<String, dynamic>.from(
          data['modified_default_videos'] ?? {},
        );
        final deletedIds = List<String>.from(
          data['deleted_default_videos'] ?? [],
        );

        // Remove deleted defaults from the list
        defaults.removeWhere((v) => deletedIds.contains(v['id']));

        // Overlay teacher modifications (keep sections=[] → visible to all)
        for (int i = 0; i < defaults.length; i++) {
          final id = defaults[i]['id'] as String;
          if (modifiedMap.containsKey(id)) {
            final mod = Map<String, dynamic>.from(modifiedMap[id] as Map);
            final url = mod['videoUrl'] as String? ?? '';
            if (VideoUploadHelper.isYoutubeUrl(url) ||
                VideoUploadHelper.isValidUrl(url)) {
              defaults[i] = {
                ...mod,
                'id': id,
                'isDefault': true,
                'sections': <String>[], // defaults always visible to all
                'teacherName': 'SciLearn',
                'teacherUid': '',
              };
            }
          }
        }

        // ── Teacher-created videos ──────────────────────────────────────
        final rawList = List<Map<String, dynamic>>.from(
          (data['teacher_videos'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );

        for (final video in rawList) {
          final url = video['videoUrl'] as String? ?? '';
          if (!VideoUploadHelper.isYoutubeUrl(url) &&
              !VideoUploadHelper.isValidUrl(url))
            continue;

          final sections = _parseSections(video['sections']);

          teacherVideos.add({
            ...video,
            'isDefault': false,
            'teacherName': teacherName,
            'teacherUid': teacherUid,
            'sections': sections,
          });
        }
      }
    } catch (_) {
      // Network error — return whatever defaults we built
    }

    final raw = [...defaults, ...teacherVideos];

    // Cache the raw (unfiltered) list
    try {
      await prefs.setString(_kRawVideos, jsonEncode(raw));
    } catch (_) {}

    return raw;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBooksForSection(
    String? studentSection, {
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> raw;

    if (!forceRefresh) {
      final cached = prefs.getString(_kRawBooks);
      if (cached != null) {
        try {
          raw = List<Map<String, dynamic>>.from(
            (jsonDecode(cached) as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          _refreshRawBooks(prefs);
          return _filterBySection(raw, studentSection);
        } catch (_) {}
      }
    }

    raw = await _refreshRawBooks(prefs);
    return _filterBySection(raw, studentSection);
  }

  static Future<List<Map<String, dynamic>>> _refreshRawBooks(
    SharedPreferences prefs,
  ) async {
    final List<Map<String, dynamic>> defaults = [];
    int idx = 0;
    for (final book in [...scienceBooks, ...spaceBooks]) {
      defaults.add({
        ..._bookToMap(book),
        'id': 'default_book_$idx',
        'isDefault': true,
        'sections': <String>[],
        'teacherName': 'SciLearn',
        'teacherUid': '',
      });
      idx++;
    }

    final List<Map<String, dynamic>> teacherBooks = [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teacher_content')
          .get()
          .timeout(const Duration(seconds: 10));

      for (final doc in snapshot.docs) {
        final teacherUid = doc.id;
        final data = doc.data();
        final teacherName = await _getTeacherName(teacherUid);

        final modifiedMap = Map<String, dynamic>.from(
          data['modified_default_books'] ?? {},
        );
        final deletedIds = List<String>.from(
          data['deleted_default_books'] ?? [],
        );

        defaults.removeWhere((b) => deletedIds.contains(b['id']));

        for (int i = 0; i < defaults.length; i++) {
          final id = defaults[i]['id'] as String;
          if (modifiedMap.containsKey(id)) {
            final mod = Map<String, dynamic>.from(modifiedMap[id] as Map);
            defaults[i] = {
              ...mod,
              'id': id,
              'isDefault': true,
              'sections': <String>[],
              'teacherName': 'SciLearn',
              'teacherUid': '',
            };
          }
        }

        final rawList = List<Map<String, dynamic>>.from(
          (data['teacher_books'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );

        for (final book in rawList) {
          final sections = _parseSections(book['sections']);
          teacherBooks.add({
            ...book,
            'isDefault': false,
            'teacherName': teacherName,
            'teacherUid': teacherUid,
            'sections': sections,
          });
        }
      }
    } catch (_) {}

    final raw = [...defaults, ...teacherBooks];

    try {
      await prefs.setString(_kRawBooks, jsonEncode(raw));
    } catch (_) {}

    return raw;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CORE FILTER  — always runs, never skipped
  // ─────────────────────────────────────────────────────────────────────────

  /// Rules:
  ///   isDefault == true  → always visible (sections field is irrelevant)
  ///   isDefault == false → visible ONLY if:
  ///       1. sections is non-empty (teacher assigned at least one section)
  ///       2. studentSection is non-null and is in the sections list
  ///
  /// If sections is empty on a teacher item it means the teacher saved without
  /// selecting a section — we HIDE it rather than show it to everyone.
  static List<Map<String, dynamic>> _filterBySection(
    List<Map<String, dynamic>> raw,
    String? studentSection,
  ) {
    return raw.where((item) {
      // Default (SciLearn) content is always visible to all students
      if (item['isDefault'] == true) return true;

      // Teacher-created: must have at least one section assigned
      final sections = _parseSections(item['sections']);
      if (sections.isEmpty) return false;

      // Student must have a section and it must match
      if (studentSection == null || studentSection.trim().isEmpty) return false;
      return sections.contains(studentSection.trim());
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Safely parse whatever is stored in the 'sections' field to List<String>.
  static List<String> _parseSections(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  static Future<String> _getTeacherName(String uid) async {
    if (_teacherNameCache.containsKey(uid)) return _teacherNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      final name =
          (data?['displayName'] ??
                  data?['fullName'] ??
                  data?['username'] ??
                  'Teacher')
              .toString();
      _teacherNameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Teacher';
    }
  }

  static Map<String, dynamic> _lessonToMap(ScienceLesson lesson) {
    return {
      'title': lesson.title,
      'emoji': lesson.emoji,
      'description': lesson.description,
      'videoUrl': lesson.videoUrl,
      'duration': lesson.duration,
      'funFact': lesson.funFact,
      'keyTopics': lesson.keyTopics,
      'moreFacts': lesson.moreFacts,
      'topic': lesson.topic,
      'quizQuestions':
          lesson.quizQuestions
              .map(
                (q) => {
                  'question': q.question,
                  'options': q.options,
                  'correctAnswer': q.correctAnswer,
                  'explanation': q.explanation,
                  'emoji': q.emoji,
                },
              )
              .toList(),
    };
  }

  static Map<String, dynamic> _bookToMap(Book book) {
    return {
      'title': book.title,
      'image': book.image,
      'summary': book.summary,
      'theme': book.theme,
      'author': book.author,
      'readTime': book.readTime,
      'funFact': book.funFact,
      'chapters':
          book.chapters
              .map(
                (ch) => {
                  'title': ch.title,
                  'content': ch.content,
                  'keyPoints': ch.keyPoints,
                  'didYouKnow': ch.didYouKnow,
                  'quizQuestions':
                      ch.quizQuestions
                          .map(
                            (q) => {
                              'question': q.question,
                              'options': q.options,
                              'correctAnswer': q.correctAnswer,
                              'explanation': q.explanation,
                            },
                          )
                          .toList(),
                },
              )
              .toList(),
    };
  }
}
