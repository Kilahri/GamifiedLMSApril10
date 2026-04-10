// lesson_selection_screen.dart - TOPIC-BASED VERSION
//
// ────────────────────────────────────────────────────────────────────────────
// FIXES IN THIS VERSION
// ────────────────────────────────────────────────────────────────────────────
//
// FIX 1 – Content disappears on relogin (BUG 1)
//   Added a retry in _loadLessons() after getSection() returns null.
//   If the student section is null on first call (Firebase Auth not yet
//   re-hydrated), we wait 600 ms and force-refresh the profile from Firestore.
//   Then we force-refresh the content fetch with the real section so teacher-
//   created content is included.
//
// FIX 2 – Students should see teacher name AND section on lesson cards (BUG 2)
//   TopicLessonsScreen lesson cards now show:
//     • Teacher badge (already existed)
//     • Section chips — a purple chip for each section the lesson is assigned
//       to. For default/SciLearn content "All Sections" is shown instead.
// ────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elearningapp_flutter/data/video_data.dart';
import 'package:elearningapp_flutter/screens/watch_screen.dart';
import 'package:elearningapp_flutter/helpers/video_upload_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/helpers/student_cache.dart';
import 'package:elearningapp_flutter/helpers/content_fetcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonSelectionScreen extends StatefulWidget {
  const LessonSelectionScreen({super.key});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen> {
  Set<int> completedLessons = {};
  int totalPoints = 0;

  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;
  String? _studentSection;

  final List<Map<String, dynamic>> topics = [
    {
      'id': 'changes_of_matter',
      'title': 'Changes of Matter',
      'emoji': '🧪',
      'description': 'Learn about physical and chemical changes',
      'color': Color(0xFF7B4DFF),
    },
    {
      'id': 'water_cycle',
      'title': 'Water Cycle',
      'emoji': '💧',
      'description': 'Explore how water moves through Earth',
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'photosynthesis',
      'title': 'Photosynthesis',
      'emoji': '🌱',
      'description': 'Discover how plants make food',
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'solar_system',
      'title': 'Solar System',
      'emoji': '🪐',
      'description': 'Journey through space and planets',
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'ecosystem_food_web',
      'title': 'Ecosystem & Food Web',
      'emoji': '🦁',
      'description': 'Understand nature\'s connections',
      'color': Color(0xFF8BC34A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadLessons();
  }

  Future<String> _getProgressKey() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'lesson_progress_$uid';
  }

  Future<void> _loadProgress() async {
    final key = await _getProgressKey();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        setState(() {
          completedLessons = Set<int>.from(
            (map['completed'] as List).map((e) => e as int),
          );
          totalPoints = (map['points'] as int?) ?? 0;
        });
      } catch (_) {}
    }
  }

  Future<void> _saveProgress() async {
    final key = await _getProgressKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'completed': completedLessons.toList(),
        'points': totalPoints,
      }),
    );
  }

  Future<void> _loadLessons({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (allLessons.isEmpty) setState(() => _isLoadingLessons = true);

    try {
      // ── FIX 1: Retry if section is null ──────────────────────────────────
      // On a fresh login, Firebase Auth may not have re-hydrated the session
      // by the time this runs. StudentCache returns null, and without a section
      // the content fetcher skips all teacher-created content.
      // Solution: if section comes back null, wait briefly and force-refresh
      // the profile, then force-refresh the content fetch.
      _studentSection = await StudentCache.getSection();

      if (_studentSection == null) {
        // Wait for Firebase Auth session to fully settle, then retry once.
        await Future.delayed(const Duration(milliseconds: 600));
        final freshProfile = await StudentCache.getProfile(forceRefresh: true);
        _studentSection = freshProfile?['section'] as String?;
        // Always force-refresh content when we just loaded a fresh profile.
        forceRefresh = true;
      }

      final lessons = await ContentFetcher.getVideosForSection(
        _studentSection,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          allLessons = lessons;
          _isLoadingLessons = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      if (mounted) setState(() => _isLoadingLessons = false);
    }
  }

  int _getLessonCountForTopic(String topicId) =>
      allLessons.where((l) => l['topic'] == topicId).length;

  void _navigateToTopicLessons(String topicId, String topicTitle) {
    final topicLessons =
        allLessons
            .asMap()
            .entries
            .where((entry) => entry.value['topic'] == topicId)
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TopicLessonsScreen(
              topicId: topicId,
              topicTitle: topicTitle,
              lessons: topicLessons,
              allLessons: allLessons,
              completedLessons: completedLessons, // ← ADD
              onLessonCompleted: (index, points) {
                // ← ADD
                setState(() {
                  completedLessons.add(index);
                  totalPoints += points;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLessons) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F3E),
          elevation: 0,
          title: const Text(
            'Science Topics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF7B4DFF)),
              SizedBox(height: 16),
              Text('Loading topics…', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final totalLessons = allLessons.length;
    final progress =
        totalLessons > 0 ? completedLessons.length / totalLessons : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Science Topics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_studentSection != null)
              Text(
                _studentSection!,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadLessons(forceRefresh: true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Topics refreshed!'),
                  backgroundColor: Color(0xFF7B4DFF),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Topics',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1F3E), Color(0xFF0D102C)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${completedLessons.length}/$totalLessons Lessons',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.category, color: Color(0xFF7B4DFF), size: 24),
                SizedBox(width: 8),
                Text(
                  'Choose a Topic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Topics grid
          Expanded(
            child:
                allLessons.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.video_library,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No lessons available',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Contact your teacher to add lessons',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _loadLessons(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DFF),
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        final lessonCount = _getLessonCountForTopic(
                          topic['id'] as String,
                        );

                        return Card(
                          color: const Color(0xFF1C1F3E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (lessonCount > 0) {
                                _navigateToTopicLessons(
                                  topic['id'] as String,
                                  topic['title'] as String,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No lessons in this topic yet',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (topic['color'] as Color).withOpacity(0.2),
                                    (topic['color'] as Color).withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: topic['color'] as Color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (topic['color'] as Color)
                                              .withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        topic['emoji'] as String,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    topic['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    topic['description'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          lessonCount > 0
                                              ? topic['color'] as Color
                                              : Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color:
                                              lessonCount > 0
                                                  ? Colors.white
                                                  : Colors.white54,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$lessonCount ${lessonCount == 1 ? 'video' : 'videos'}',
                                          style: TextStyle(
                                            color:
                                                lessonCount > 0
                                                    ? Colors.white
                                                    : Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOPIC LESSONS SCREEN
// ============================================================================

class TopicLessonsScreen extends StatelessWidget {
  final String topicId;
  final String topicTitle;
  final List<MapEntry<int, Map<String, dynamic>>> lessons;
  final List<Map<String, dynamic>> allLessons;
  final Set<int> completedLessons; // ← ADD
  final Function(int index, int points) onLessonCompleted; // ← ADD

  const TopicLessonsScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.lessons,
    required this.allLessons,
    required this.completedLessons, // ← ADD
    required this.onLessonCompleted, // ← ADD
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          topicTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1F3E), Color(0xFF0D102C)],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.video_library,
                  color: Color(0xFF7B4DFF),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '${lessons.length} ${lessons.length == 1 ? 'Lesson' : 'Lessons'} Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lessonEntry = lessons[index];
                final lesson = lessonEntry.value;
                final globalIndex = lessonEntry.key;
                final isDefault = lesson['isDefault'] == true;
                final teacherName =
                    lesson['teacherName'] as String? ?? 'SciLearn';

                // ── FIX 2: Read section list from lesson data ─────────────
                final sections = List<String>.from(lesson['sections'] ?? []);

                return Card(
                  color: const Color(0xFF1C1F3E),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => WatchScreen(
                                  initialLessonIndex: globalIndex,
                                  lessons: allLessons,
                                  onLessonCompleted: onLessonCompleted,
                                ),
                          ),
                        ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top row: emoji + title + meta ─────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B4DFF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        lesson['emoji'] as String,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                  if (!isDefault)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFC107),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson['title'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // ── Teacher badge ─────────────────
                                    Row(
                                      children: [
                                        Icon(
                                          isDefault
                                              ? Icons.auto_awesome
                                              : Icons.school,
                                          color:
                                              isDefault
                                                  ? Colors.amber
                                                  : const Color(0xFF7B4DFF),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          teacherName,
                                          style: TextStyle(
                                            color:
                                                isDefault
                                                    ? Colors.amber
                                                    : const Color(0xFF7B4DFF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // ── Duration + NEW badge ──────────
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white54,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          lesson['duration'] as String,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (!isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFFC107,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(
                                                color: Color(0xFFFFC107),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── FIX 2: Section chips row ───────────────────
                          // Default (SciLearn) content has no sections list —
                          // show "All Sections". Teacher content shows which
                          // sections it was assigned to.
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children:
                                isDefault || sections.isEmpty
                                    ? [
                                      _sectionChip('All Sections', Colors.teal),
                                    ]
                                    : sections
                                        .map(
                                          (s) => _sectionChip(
                                            s,
                                            const Color(0xFF7B4DFF),
                                          ),
                                        )
                                        .toList(),
                          ),

                          const SizedBox(height: 10),

                          // ── Description ────────────────────────────────
                          Text(
                            lesson['description'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Start button ───────────────────────────────
                          ElevatedButton.icon(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => WatchScreen(
                                          initialLessonIndex: globalIndex,
                                          lessons: allLessons,
                                          onLessonCompleted: onLessonCompleted,
                                        ),
                                  ),
                                ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Lesson',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Small reusable section chip ──────────────────────────────────────────
  Widget _sectionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
