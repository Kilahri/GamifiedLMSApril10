// lesson_selection_screen.dart - REDESIGNED UI
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

// ── Design tokens (matches app-wide palette) ─────────────────────────────────
const Color _kBg = Color(0xFF07091A);
const Color _kSurface = Color(0xFF0F1230);
const Color _kCard = Color(0xFF131629);
const Color _kAccent = Color(0xFF7B4DFF);
const Color _kAccentLt = Color(0xFF9D77FF);
const Color _kGold = Color(0xFFFFBF3C);
const Color _kTeal = Color(0xFF1DB8A0);
const Color _kCoral = Color(0xFFFF6B6B);
const Color _kBorder = Color(0xFF1E2248);
const Color _kMuted = Color(0xFF5A5D7A);
const Color _kText = Color(0xFFE8E9F5);
const Color _kTextSub = Color(0xFF9496B0);

class LessonSelectionScreen extends StatefulWidget {
  const LessonSelectionScreen({super.key});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen>
    with SingleTickerProviderStateMixin {
  Set<int> completedLessons = {};
  int totalPoints = 0;

  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;
  String? _studentSection;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> topics = [
    {
      'id': 'changes_of_matter',
      'title': 'Changes of\nMatter',
      'emoji': '🧪',
      'description': 'Physical & chemical changes',
      'color': const Color(0xFF7B4DFF),
      'lightColor': const Color(0xFF9D77FF),
    },
    {
      'id': 'water_cycle',
      'title': 'Water\nCycle',
      'emoji': '💧',
      'description': 'How water moves through Earth',
      'color': const Color(0xFF2196F3),
      'lightColor': const Color(0xFF64B5F6),
    },
    {
      'id': 'photosynthesis',
      'title': 'Photo-\nsynthesis',
      'emoji': '🌱',
      'description': 'How plants make food',
      'color': const Color(0xFF1DB8A0),
      'lightColor': const Color(0xFF4DD0C4),
    },
    {
      'id': 'solar_system',
      'title': 'Solar\nSystem',
      'emoji': '🪐',
      'description': 'Space and planets',
      'color': const Color(0xFFFF9800),
      'lightColor': const Color(0xFFFFB74D),
    },
    {
      'id': 'ecosystem_food_web',
      'title': 'Ecosystem\n& Food Web',
      'emoji': '🦁',
      'description': "Nature's connections",
      'color': const Color(0xFF4CAF50),
      'lightColor': const Color(0xFF81C784),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProgress();
    _loadLessons();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
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
      _studentSection = await StudentCache.getSection();
      if (_studentSection == null) {
        await Future.delayed(const Duration(milliseconds: 600));
        final freshProfile = await StudentCache.getProfile(forceRefresh: true);
        _studentSection = freshProfile?['section'] as String?;
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

  int _getCompletedCountForTopic(String topicId) {
    final topicIndices =
        allLessons
            .asMap()
            .entries
            .where((e) => e.value['topic'] == topicId)
            .map((e) => e.key)
            .toList();
    return topicIndices.where((i) => completedLessons.contains(i)).length;
  }

  void _navigateToTopicLessons(String topicId, String topicTitle, Color color) {
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
              topicColor: color,
              lessons: topicLessons,
              allLessons: allLessons,
              completedLessons: completedLessons,
              onLessonCompleted: (index, points) {
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
        backgroundColor: _kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _kAccent,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading topics…',
                style: TextStyle(color: _kTextSub, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final totalLessons = allLessons.length;
    final progress =
        totalLessons > 0 ? completedLessons.length / totalLessons : 0.0;
    final progressPct = (progress * 100).round();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Glow orbs ───────────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(size: 260, color: _kAccent.withOpacity(0.12)),
          ),
          Positioned(
            top: 300,
            left: -60,
            child: _GlowOrb(size: 200, color: _kTeal.withOpacity(0.08)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App bar ─────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Progress card ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: _buildProgressCard(
                        progress,
                        progressPct,
                        totalLessons,
                      ),
                    ),
                  ),

                  // ── Section label ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _kAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Topics',
                            style: TextStyle(
                              color: _kText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Topics grid ─────────────────────────────────────────
                  allLessons.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.82,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildTopicCard(topics[index]),
                            childCount: topics.length,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Science Videos',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                if (_studentSection != null)
                  Text(
                    _studentSection!,
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: _kGold, size: 16),
                const SizedBox(width: 5),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    color: _kGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Refresh
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: _kTextSub,
                size: 18,
              ),
              onPressed: () {
                _loadLessons(forceRefresh: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Topics refreshed!'),
                    backgroundColor: _kAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress card ─────────────────────────────────────────────────────────
  Widget _buildProgressCard(
    double progress,
    int progressPct,
    int totalLessons,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3D1FA8),
            const Color(0xFF6B3DFF),
            _kAccent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${completedLessons.length} of $totalLessons lessons',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(_kGold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Percentage circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$progressPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'done',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Topic card ────────────────────────────────────────────────────────────
  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final topicId = topic['id'] as String;
    final color = topic['color'] as Color;
    final lightColor = topic['lightColor'] as Color;
    final lessonCount = _getLessonCountForTopic(topicId);
    final completedCount = _getCompletedCountForTopic(topicId);
    final hasLessons = lessonCount > 0;
    final topicProgress = lessonCount > 0 ? completedCount / lessonCount : 0.0;

    return GestureDetector(
      onTap: () {
        if (hasLessons) {
          _navigateToTopicLessons(
            topicId,
            topic['title'].toString().replaceAll('\n', ' '),
            color,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No lessons in this topic yet'),
              backgroundColor: _kMuted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top color strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(colors: [color, lightColor]),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        topic['emoji'] as String,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic['title'] as String,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  // Progress bar
                  if (hasLessons) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: topicProgress,
                        minHeight: 4,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Lesson count chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              hasLessons ? color.withOpacity(0.15) : _kBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              color: hasLessons ? color : _kMuted,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$lessonCount ${lessonCount == 1 ? 'video' : 'videos'}',
                              style: TextStyle(
                                color: hasLessons ? color : _kMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasLessons && completedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$completedCount done',
                            style: const TextStyle(
                              color: _kTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: _kMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No lessons available',
            style: TextStyle(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact your teacher to add lessons',
            style: TextStyle(color: _kMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadLessons(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  final Color topicColor;
  final List<MapEntry<int, Map<String, dynamic>>> lessons;
  final List<Map<String, dynamic>> allLessons;
  final Set<int> completedLessons;
  final Function(int index, int points) onLessonCompleted;

  const TopicLessonsScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.topicColor,
    required this.lessons,
    required this.allLessons,
    required this.completedLessons,
    required this.onLessonCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _GlowOrb(size: 220, color: topicColor.withOpacity(0.14)),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Custom app bar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _kText,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: topicColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _emojiForTopic(topicId),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          topicTitle,
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: topicColor.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: topicColor.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${lessons.length} ${lessons.length == 1 ? 'lesson' : 'lessons'}',
                          style: TextStyle(
                            color: topicColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Lesson list ─────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lessonEntry = lessons[index];
                      final lesson = lessonEntry.value;
                      final globalIndex = lessonEntry.key;
                      final isDefault = lesson['isDefault'] == true;
                      final teacherName =
                          lesson['teacherName'] as String? ?? 'SciLearn';
                      final sections = List<String>.from(
                        lesson['sections'] ?? [],
                      );
                      final isDone = completedLessons.contains(globalIndex);

                      return _LessonCard(
                        lesson: lesson,
                        globalIndex: globalIndex,
                        isDefault: isDefault,
                        teacherName: teacherName,
                        sections: sections,
                        isDone: isDone,
                        topicColor: topicColor,
                        allLessons: allLessons,
                        onLessonCompleted: onLessonCompleted,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForTopic(String id) {
    const map = {
      'changes_of_matter': '🧪',
      'water_cycle': '💧',
      'photosynthesis': '🌱',
      'solar_system': '🪐',
      'ecosystem_food_web': '🦁',
    };
    return map[id] ?? '📚';
  }
}

// ── Lesson card extracted for clarity ────────────────────────────────────────
class _LessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final int globalIndex;
  final bool isDefault;
  final String teacherName;
  final List<String> sections;
  final bool isDone;
  final Color topicColor;
  final List<Map<String, dynamic>> allLessons;
  final Function(int, int) onLessonCompleted;

  const _LessonCard({
    required this.lesson,
    required this.globalIndex,
    required this.isDefault,
    required this.teacherName,
    required this.sections,
    required this.isDone,
    required this.topicColor,
    required this.allLessons,
    required this.onLessonCompleted,
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WatchScreen(
              initialLessonIndex: globalIndex,
              lessons: allLessons,
              onLessonCompleted: onLessonCompleted,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? _kTeal.withOpacity(0.4) : _kBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top accent bar ──────────────────────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                color: isDone ? _kTeal : topicColor,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row: emoji + info ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji box
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: topicColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                lesson['emoji'] as String,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          if (isDone)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: _kTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            )
                          else if (!isDefault)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: _kGold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['title'] as String,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Teacher + duration row
                            Row(
                              children: [
                                Icon(
                                  isDefault
                                      ? Icons.auto_awesome_rounded
                                      : Icons.school_rounded,
                                  color: isDefault ? _kGold : _kAccentLt,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  teacherName,
                                  style: TextStyle(
                                    color: isDefault ? _kGold : _kAccentLt,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: _kMuted,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lesson['duration'] as String,
                                  style: const TextStyle(
                                    color: _kMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                if (!isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: _kGold,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Section chips
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children:
                                  isDefault || sections.isEmpty
                                      ? [_sectionChip('All Sections', _kTeal)]
                                      : sections
                                          .map(
                                            (s) => _sectionChip(s, _kAccentLt),
                                          )
                                          .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Text(
                    lesson['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextSub,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _open(context),
                      icon: Icon(
                        isDone
                            ? Icons.replay_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isDone ? 'Watch Again' : 'Start Lesson',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDone ? _kTeal : topicColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_rounded, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow orb ──────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
