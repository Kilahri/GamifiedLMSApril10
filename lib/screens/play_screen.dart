import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/cms/game_cms.dart';
import 'package:elearningapp_flutter/play/quiz_screen.dart';
import 'package:elearningapp_flutter/play/trivia_screen.dart';
import 'package:elearningapp_flutter/play/puzzle_screen.dart';
import 'package:elearningapp_flutter/play/cross_word.dart';
import 'package:elearningapp_flutter/planet_builder/planet_gallery_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';

// ── Unified achievement model ─────────────────────────────────────────────

enum AchievementTier { bronze, silver, gold }

class UnifiedAchievement {
  final String id;
  final String gameId;
  final String gameName;
  final String gameEmoji;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final Color color;
  final bool Function(Map<String, dynamic> stats) isUnlocked;

  const UnifiedAchievement({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.gameEmoji,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.isUnlocked,
  });
}

// ── All achievements across all games ────────────────────────────────────

final List<UnifiedAchievement> kAllAchievements = [
  // ── Quiz ──────────────────────────────────────────────────────────────
  UnifiedAchievement(
    id: 'quiz_first_answer',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'First Correct Answer',
    description: 'Answer your first question correctly',
    emoji: '✅',
    tier: AchievementTier.bronze,
    color: const Color(0xFFFF8C00),
    isUnlocked: (s) => (s['totalCorrect'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'quiz_streak_3',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'On a Roll',
    description: 'Get 3 correct answers in a row',
    emoji: '🔥',
    tier: AchievementTier.bronze,
    color: const Color(0xFFFF5722),
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 3,
  ),
  UnifiedAchievement(
    id: 'quiz_streak_5',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Hot Streak',
    description: 'Get 5 correct answers in a row',
    emoji: '🌟',
    tier: AchievementTier.silver,
    color: const Color(0xFFFFC107),
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 5,
  ),
  UnifiedAchievement(
    id: 'quiz_streak_10',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Unstoppable',
    description: 'Get 10 correct answers in a row',
    emoji: '⚡',
    tier: AchievementTier.gold,
    color: const Color(0xFFFFEB3B),
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 10,
  ),
  UnifiedAchievement(
    id: 'quiz_perfect_topic',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Topic Master',
    description: 'Score 100% on any topic',
    emoji: '🏆',
    tier: AchievementTier.gold,
    color: const Color(0xFFFFC107),
    isUnlocked: (s) => (s['perfectTopics'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'quiz_all_topics',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Science Scholar',
    description: 'Complete all 5 topics',
    emoji: '🎓',
    tier: AchievementTier.gold,
    color: const Color(0xFF9C27B0),
    isUnlocked: (s) => (s['topicsCompleted'] ?? 0) >= 5,
  ),
  UnifiedAchievement(
    id: 'quiz_speed_demon',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Speed Demon',
    description: 'Answer a hard question in under 5 seconds',
    emoji: '💨',
    tier: AchievementTier.silver,
    color: const Color(0xFF03A9F4),
    isUnlocked: (s) => (s['fastHardAnswer'] ?? false) == true,
  ),
  UnifiedAchievement(
    id: 'quiz_hard_hero',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Hard Mode Hero',
    description: 'Answer 5 hard questions correctly',
    emoji: '🦸',
    tier: AchievementTier.silver,
    color: const Color(0xFF3F51B5),
    isUnlocked: (s) => (s['hardCorrect'] ?? 0) >= 5,
  ),
  UnifiedAchievement(
    id: 'quiz_century',
    gameId: 'quiz',
    gameName: 'Science Quiz',
    gameEmoji: '🦉',
    title: 'Century',
    description: 'Answer 100 questions correctly across all topics',
    emoji: '💯',
    tier: AchievementTier.gold,
    color: const Color(0xFF4CAF50),
    isUnlocked: (s) => (s['totalCorrect'] ?? 0) >= 100,
  ),

  // ── Science Fusion ────────────────────────────────────────────────────
  UnifiedAchievement(
    id: 'fusion_first_discovery',
    gameId: 'science_fusion',
    gameName: 'Element Fusion',
    gameEmoji: '🧪',
    title: 'First Discovery',
    description: 'Make your first element combination',
    emoji: '🔬',
    tier: AchievementTier.bronze,
    color: const Color(0xFF2196F3),
    isUnlocked: (s) => (s['totalDiscoveries'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'fusion_collector',
    gameId: 'science_fusion',
    gameName: 'Element Fusion',
    gameEmoji: '🧪',
    title: 'Element Collector',
    description: 'Collect 10 different elements',
    emoji: '📦',
    tier: AchievementTier.silver,
    color: const Color(0xFF9C27B0),
    isUnlocked: (s) => (s['collected'] ?? 0) >= 10,
  ),
  UnifiedAchievement(
    id: 'fusion_streak_master',
    gameId: 'science_fusion',
    gameName: 'Element Fusion',
    gameEmoji: '🧪',
    title: 'Combo Master',
    description: 'Achieve a 5x combo streak',
    emoji: '🔥',
    tier: AchievementTier.silver,
    color: const Color(0xFFFF9800),
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 5,
  ),
  UnifiedAchievement(
    id: 'fusion_speed',
    gameId: 'science_fusion',
    gameName: 'Element Fusion',
    gameEmoji: '🧪',
    title: 'Speed Scientist',
    description: 'Complete a level in under 2 minutes',
    emoji: '⚡',
    tier: AchievementTier.silver,
    color: const Color(0xFF4CAF50),
    isUnlocked: (s) => (s['fastestLevel'] ?? 999) < 120,
  ),
  UnifiedAchievement(
    id: 'fusion_perfectionist',
    gameId: 'science_fusion',
    gameName: 'Element Fusion',
    gameEmoji: '🧪',
    title: 'Perfectionist',
    description: 'Complete a game without using hints',
    emoji: '✨',
    tier: AchievementTier.gold,
    color: const Color(0xFFFFC107),
    isUnlocked:
        (s) => (s['hintsUsed'] ?? 1) == 0 && (s['levelsCompleted'] ?? 0) >= 3,
  ),

  // ── Matching Game ─────────────────────────────────────────────────────
  UnifiedAchievement(
    id: 'matching_first_match',
    gameId: 'matching',
    gameName: 'Matching Game',
    gameEmoji: '🃏',
    title: 'First Match',
    description: 'Complete your first matching game',
    emoji: '🎴',
    tier: AchievementTier.bronze,
    color: const Color(0xFF4CAF50),
    isUnlocked: (s) => (s['matching_best'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'matching_scorer',
    gameId: 'matching',
    gameName: 'Matching Game',
    gameEmoji: '🃏',
    title: 'Sharp Mind',
    description: 'Score 100+ points in Matching Game',
    emoji: '🧠',
    tier: AchievementTier.silver,
    color: const Color(0xFF00BCD4),
    isUnlocked: (s) => (s['matching_best'] ?? 0) >= 100,
  ),
  UnifiedAchievement(
    id: 'matching_expert',
    gameId: 'matching',
    gameName: 'Matching Game',
    gameEmoji: '🃏',
    title: 'Memory Expert',
    description: 'Score 300+ points in Matching Game',
    emoji: '🏅',
    tier: AchievementTier.gold,
    color: const Color(0xFFFFC107),
    isUnlocked: (s) => (s['matching_best'] ?? 0) >= 300,
  ),

  // ── Crossword ─────────────────────────────────────────────────────────
  UnifiedAchievement(
    id: 'crossword_first_solve',
    gameId: 'crossword',
    gameName: 'Science Crossword',
    gameEmoji: '📝',
    title: 'Word Finder',
    description: 'Complete your first crossword puzzle',
    emoji: '📖',
    tier: AchievementTier.bronze,
    color: const Color(0xFF534AB7),
    isUnlocked: (s) => (s['crossword_best'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'crossword_scorer',
    gameId: 'crossword',
    gameName: 'Science Crossword',
    gameEmoji: '📝',
    title: 'Wordsmith',
    description: 'Score 100+ points in Crossword',
    emoji: '✏️',
    tier: AchievementTier.silver,
    color: const Color(0xFF7B4DFF),
    isUnlocked: (s) => (s['crossword_best'] ?? 0) >= 100,
  ),
  UnifiedAchievement(
    id: 'crossword_master',
    gameId: 'crossword',
    gameName: 'Science Crossword',
    gameEmoji: '📝',
    title: 'Crossword Champion',
    description: 'Score 300+ points in Crossword',
    emoji: '🏆',
    tier: AchievementTier.gold,
    color: const Color(0xFF9B8DFF),
    isUnlocked: (s) => (s['crossword_best'] ?? 0) >= 300,
  ),

  // ── Planet Builder ────────────────────────────────────────────────────
  UnifiedAchievement(
    id: 'planet_first',
    gameId: 'planet_builder',
    gameName: 'Planet Builder',
    gameEmoji: '🪐',
    title: 'Planet Creator',
    description: 'Launch your first planet',
    emoji: '🚀',
    tier: AchievementTier.bronze,
    color: const Color(0xFF4FC3F7),
    isUnlocked: (s) => (s['planet_best'] ?? 0) >= 1,
  ),
  UnifiedAchievement(
    id: 'planet_scorer',
    gameId: 'planet_builder',
    gameName: 'Planet Builder',
    gameEmoji: '🪐',
    title: 'Galactic Engineer',
    description: 'Score 150+ points on a planet',
    emoji: '🌌',
    tier: AchievementTier.silver,
    color: const Color(0xFF4FC3F7),
    isUnlocked: (s) => (s['planet_best'] ?? 0) >= 150,
  ),
  UnifiedAchievement(
    id: 'planet_legendary',
    gameId: 'planet_builder',
    gameName: 'Planet Builder',
    gameEmoji: '🪐',
    title: 'Legendary World',
    description: 'Score 250+ points — build a Legendary World',
    emoji: '🌟',
    tier: AchievementTier.gold,
    color: const Color(0xFFFFD54F),
    isUnlocked: (s) => (s['planet_best'] ?? 0) >= 250,
  ),
];

// ── PlayScreen ────────────────────────────────────────────────────────────

class PlayScreen extends StatefulWidget {
  final String role;
  final String username;

  const PlayScreen({super.key, required this.role, required this.username});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        automaticallyImplyLeading: false,
        title: const Text(
          'PLAY',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.role == 'teacher' ||
              widget.role == 'parent' ||
              widget.role == 'admin')
            IconButton(
              icon: const Icon(Icons.edit, size: 28),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameCMS(role: widget.role),
                    ),
                  ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFCC00),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFFCC00),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.sports_esports, size: 18), text: 'Games'),
            Tab(icon: Icon(Icons.emoji_events, size: 18), text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GamesTab(
            role: widget.role,
            username: widget.username,
            userId: userId,
          ),
          _AchievementsTab(username: widget.username),
        ],
      ),
    );
  }
}

// ── Games Tab ─────────────────────────────────────────────────────────────

class _GamesTab extends StatelessWidget {
  final String role;
  final String username;
  final String userId;

  const _GamesTab({
    required this.role,
    required this.username,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryButton(Icons.local_fire_department, 'Trending'),
                  _categoryButton(Icons.star, 'Popular'),
                  _categoryButton(Icons.sports_esports, 'New'),
                ],
              ),
            ),
          ),

          // Daily Feature
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '🔥 Daily Feature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          _featureBanner(
            context,
            'Planet Builder',
            'lib/assets/spaceExplorer.jpg',
            PlanetGalleryScreen(userId: userId, username: username),
          ),

          // Play Games
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              '🎮 Play Games',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childAspectRatio: 0.85,
            children: [
              _gameCard(
                context,
                'Science Quiz',
                'lib/assets/quiz.jpg',
                QuizScreenWithAchievements(role: role, username: username),
                Icons.lightbulb,
              ),
              _gameCard(
                context,
                'Element Fusion',
                'lib/assets/puzzle.jpg',
                ScienceFusionHome(username: username),
                Icons.extension,
              ),
              _gameCard(
                context,
                'Space Explorer',
                'lib/assets/spaceExplorer.jpg',
                PlanetGalleryScreen(userId: userId, username: username),
                Icons.public,
              ),
              _gameCard(
                context,
                'Matching Game',
                'lib/assets/popularRead.png',
                TriviaScreen(role: role),
                Icons.compare_arrows,
              ),
              _gameCard(
                context,
                'Science Crossword',
                'lib/assets/popularPlay.png',
                ScienceCrosswordScreen(role: role),
                Icons.grid_on,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _categoryButton(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B5998),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          elevation: 0,
        ),
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _featureBanner(
    BuildContext context,
    String title,
    String imagePath,
    Widget screen,
  ) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0C22),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey.shade700,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => screen),
                          ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
  }

  Widget _gameCard(
    BuildContext context,
    String title,
    String imagePath,
    Widget screen,
    IconData icon,
  ) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F3E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey.shade700,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF0D102C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievements Tab ──────────────────────────────────────────────────────

class _AchievementsTab extends StatefulWidget {
  final String username;

  const _AchievementsTab({required this.username});

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> {
  bool _loading = true;
  Set<String> _unlocked = {};
  Map<String, dynamic> _stats = {};
  String _filterGame = 'All';

  static const List<String> _gameFilters = [
    'All',
    'Science Quiz',
    'Element Fusion',
    'Matching Game',
    'Science Crossword',
    'Planet Builder',
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final userId = await StudentCache.getUserId() ?? '';
      final stats = <String, dynamic>{};

      if (userId.isNotEmpty) {
        // Quiz achievements from Firestore
        final quizAchDoc =
            await FirebaseFirestore.instance
                .collection('quiz_achievements')
                .doc(userId)
                .get();
        final unlockedIds = Set<String>.from(
          quizAchDoc.data()?['unlocked'] ?? [],
        );

        // Quiz stats
        final quizScoreDoc =
            await FirebaseFirestore.instance
                .collection('quiz_scores')
                .doc(userId)
                .get();
        if (quizScoreDoc.exists) {
          int totalCorrect = 0;
          int topicsCompleted = 0;
          int perfectTopics = 0;
          final data = quizScoreDoc.data() ?? {};
          data.forEach((topic, val) {
            if (val is Map) {
              final best = (val['bestScore'] as num?)?.toInt() ?? 0;
              final max = (val['maxScore'] as num?)?.toInt() ?? 1;
              totalCorrect += best;
              topicsCompleted++;
              if (best == max) perfectTopics++;
            }
          });
          stats['totalCorrect'] = totalCorrect;
          stats['topicsCompleted'] = topicsCompleted;
          stats['perfectTopics'] = perfectTopics;
        }

        // Leaderboard-based stats for other games
        final lb =
            await FirebaseFirestore.instance
                .collection('leaderboard')
                .doc(userId)
                .get();
        if (lb.exists) {
          final d = lb.data() ?? {};
          stats['matching_best'] =
              (d[FirebaseLeaderboardService.GAME_MATCHING]?['score'] as num?)
                  ?.toInt() ??
              0;
          stats['crossword_best'] =
              (d[FirebaseLeaderboardService.GAME_CROSSWORD]?['score'] as num?)
                  ?.toInt() ??
              0;
        }

        // Planet leaderboard
        final planetDoc =
            await FirebaseFirestore.instance
                .collection('planet_leaderboard')
                .doc(userId)
                .get();
        if (planetDoc.exists) {
          stats['planet_best'] =
              (planetDoc.data()?['score'] as num?)?.toInt() ?? 0;
        }

        // Science Fusion leaderboard
        final fusionDoc =
            await FirebaseFirestore.instance
                .collection('leaderboard')
                .doc(userId)
                .get();
        if (fusionDoc.exists) {
          final d = fusionDoc.data() ?? {};
          final fusionData = d[FirebaseLeaderboardService.GAME_SCIENCE_FUSION];
          if (fusionData != null) {
            stats['levelsCompleted'] =
                (fusionData['metadata']?['levelsCompleted'] as num?)?.toInt() ??
                0;
            stats['collected'] =
                (fusionData['metadata']?['collectedElements'] as num?)
                    ?.toInt() ??
                0;
            stats['maxStreak'] =
                (fusionData['metadata']?['maxStreak'] as num?)?.toInt() ?? 0;
            stats['hintsUsed'] =
                (fusionData['metadata']?['hintsUsed'] as num?)?.toInt() ?? 1;
            stats['fastestLevel'] =
                (fusionData['metadata']?['fastestLevel'] as num?)?.toInt() ??
                999;
            stats['totalDiscoveries'] = stats['collected'];
          }
        }

        // Compute which achievements are unlocked from stats
        final computedUnlocked = <String>{};
        for (final a in kAllAchievements) {
          if (unlockedIds.contains(a.id) || a.isUnlocked(stats)) {
            computedUnlocked.add(a.id);
          }
        }

        setState(() {
          _unlocked = computedUnlocked;
          _stats = stats;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Achievement load error: $e');
      setState(() => _loading = false);
    }
  }

  List<UnifiedAchievement> get _filtered {
    if (_filterGame == 'All') return kAllAchievements;
    return kAllAchievements.where((a) => a.gameName == _filterGame).toList();
  }

  int get _totalUnlocked => _unlocked.length;
  int get _totalAchievements => kAllAchievements.length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    final filtered = _filtered;
    final unlockedFiltered =
        filtered.where((a) => _unlocked.contains(a.id)).length;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFFFFCC00),
      backgroundColor: const Color(0xFF1C1F3E),
      child: CustomScrollView(
        slivers: [
          // ── Summary header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFCC00).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Achievements',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalUnlocked of $_totalAchievements unlocked',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                _totalAchievements > 0
                                    ? _totalUnlocked / _totalAchievements
                                    : 0,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFCC00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tier counts
                  Column(
                    children: [
                      _tierCount('🥇', AchievementTier.gold),
                      const SizedBox(height: 4),
                      _tierCount('🥈', AchievementTier.silver),
                      const SizedBox(height: 4),
                      _tierCount('🥉', AchievementTier.bronze),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Game filter chips ───────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _gameFilters.length,
                itemBuilder: (_, i) {
                  final f = _gameFilters[i];
                  final isActive = f == _filterGame;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterGame = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? const Color(0xFFFFCC00)
                                  : const Color(0xFF1C1F3E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isActive
                                    ? const Color(0xFFFFCC00)
                                    : Colors.white24,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color:
                                isActive
                                    ? const Color(0xFF0D102C)
                                    : Colors.white54,
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Count label ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '$unlockedFiltered/${filtered.length} unlocked',
                style: const TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ── Achievement cards ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final a = filtered[i];
                final isUnlocked = _unlocked.contains(a.id);
                return _AchievementCard(achievement: a, isUnlocked: isUnlocked);
              }, childCount: filtered.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCount(String emoji, AchievementTier tier) {
    final count =
        _unlocked.where((id) {
          final a = kAllAchievements.firstWhere(
            (a) => a.id == id,
            orElse: () => kAllAchievements.first,
          );
          return a.tier == tier;
        }).length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Achievement card widget ───────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final UnifiedAchievement achievement;
  final bool isUnlocked;

  const _AchievementCard({required this.achievement, required this.isUnlocked});

  Color get _tierColor {
    switch (achievement.tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFF9E9E9E);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  String get _tierLabel {
    switch (achievement.tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isUnlocked
                ? achievement.color.withOpacity(0.08)
                : const Color(0xFF1C1F3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isUnlocked
                  ? achievement.color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  isUnlocked
                      ? achievement.color.withOpacity(0.18)
                      : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: 24,
                  color: isUnlocked ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _tierColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _tierColor.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _tierLabel,
                        style: TextStyle(
                          color: _tierColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white54 : Colors.white24,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                // Game tag
                Row(
                  children: [
                    Text(
                      achievement.gameEmoji,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      achievement.gameName,
                      style: TextStyle(
                        color:
                            isUnlocked
                                ? achievement.color.withOpacity(0.8)
                                : Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isUnlocked) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
