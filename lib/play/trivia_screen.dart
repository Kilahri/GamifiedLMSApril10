import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';
import 'package:elearningapp_flutter/services/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';

// ============================================================================
// MATCHING-SPECIFIC ACHIEVEMENT + MISSION MODELS
// ============================================================================

enum MatchAchievementTier { bronze, silver, gold }

class MatchAchievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final MatchAchievementTier tier;
  final Color color;
  final bool Function(Map<String, dynamic> stats) isUnlocked;

  const MatchAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.isUnlocked,
  });
}

class MatchMission {
  final String id;
  final String description;
  final int target;
  final String statKey;
  final int rewardPoints;

  const MatchMission({
    required this.id,
    required this.description,
    required this.target,
    required this.statKey,
    required this.rewardPoints,
  });
}

// ============================================================================
// MATCHING ACHIEVEMENTS (9 total)
// ============================================================================

const List<MatchAchievement> kMatchAchievements = [
  MatchAchievement(
    id: 'match_first_pair',
    title: 'First Match',
    description: 'Match your first pair of cards',
    emoji: '🃏',
    tier: MatchAchievementTier.bronze,
    color: Color(0xFF2196F3),
    isUnlocked: _matchFirstPair,
  ),
  MatchAchievement(
    id: 'match_10_pairs',
    title: 'Pair Pro',
    description: 'Match 10 pairs total',
    emoji: '👏',
    tier: MatchAchievementTier.bronze,
    color: Color(0xFF2196F3),
    isUnlocked: _match10Pairs,
  ),
  MatchAchievement(
    id: 'match_flawless',
    title: 'Flawless',
    description: 'Complete a level with zero wrong flips',
    emoji: '✨',
    tier: MatchAchievementTier.gold,
    color: Color(0xFFFFC107),
    isUnlocked: _matchFlawless,
  ),
  MatchAchievement(
    id: 'match_speed_3',
    title: 'Speed Flipper',
    description: 'Match 3 pairs within 10 seconds of a level starting',
    emoji: '⚡',
    tier: MatchAchievementTier.silver,
    color: Color(0xFFFF9800),
    isUnlocked: _matchSpeed3,
  ),
  MatchAchievement(
    id: 'match_all_topics',
    title: 'Topic Explorer',
    description: 'Play all 5 science topics',
    emoji: '🌍',
    tier: MatchAchievementTier.silver,
    color: Color(0xFF4CAF50),
    isUnlocked: _matchAllTopics,
  ),
  MatchAchievement(
    id: 'match_hard_complete',
    title: 'Hard Mode Champion',
    description: 'Complete all 10 levels on Hard difficulty',
    emoji: '🔥',
    tier: MatchAchievementTier.gold,
    color: Color(0xFFF44336),
    isUnlocked: _matchHardComplete,
  ),
  MatchAchievement(
    id: 'match_score_500',
    title: 'High Scorer',
    description: 'Score 500 points in a single game',
    emoji: '🏅',
    tier: MatchAchievementTier.silver,
    color: Color(0xFF9C27B0),
    isUnlocked: _matchScore500,
  ),
  MatchAchievement(
    id: 'match_no_penalty',
    title: 'Perfect Memory',
    description: 'Complete a full game without any wrong attempts',
    emoji: '🧠',
    tier: MatchAchievementTier.gold,
    color: Color(0xFF009688),
    isUnlocked: _matchNoPenalty,
  ),
  MatchAchievement(
    id: 'match_versatile',
    title: 'Versatile',
    description: 'Win at least one game on each difficulty',
    emoji: '🎯',
    tier: MatchAchievementTier.gold,
    color: Color(0xFF3F51B5),
    isUnlocked: _matchVersatile,
  ),
];

bool _matchFirstPair(Map<String, dynamic> s) => (s['totalMatches'] ?? 0) >= 1;
bool _match10Pairs(Map<String, dynamic> s) => (s['totalMatches'] ?? 0) >= 10;
bool _matchFlawless(Map<String, dynamic> s) => (s['flawlessLevels'] ?? 0) >= 1;
bool _matchSpeed3(Map<String, dynamic> s) =>
    (s['speedMatches'] ?? false) == true;
bool _matchAllTopics(Map<String, dynamic> s) => (s['topicsPlayed'] ?? 0) >= 5;
bool _matchHardComplete(Map<String, dynamic> s) =>
    (s['hardLevelsCompleted'] ?? 0) >= 10;
bool _matchScore500(Map<String, dynamic> s) => (s['bestScore'] ?? 0) >= 500;
bool _matchNoPenalty(Map<String, dynamic> s) =>
    (s['gamesWithNoPenalty'] ?? 0) >= 1;
bool _matchVersatile(Map<String, dynamic> s) =>
    (s['easyWins'] ?? 0) >= 1 &&
    (s['mediumWins'] ?? 0) >= 1 &&
    (s['hardWins'] ?? 0) >= 1;

// ============================================================================
// MATCHING MISSIONS (5 per session)
// ============================================================================

const List<MatchMission> kMatchMissions = [
  MatchMission(
    id: 'match_m1',
    description: 'Match 3 pairs this game',
    target: 3,
    statKey: 'sessionMatches',
    rewardPoints: 15,
  ),
  MatchMission(
    id: 'match_m2',
    description: 'Complete a level with no wrong flips',
    target: 1,
    statKey: 'sessionFlawlessLevels',
    rewardPoints: 30,
  ),
  MatchMission(
    id: 'match_m3',
    description: 'Reach level 3',
    target: 3,
    statKey: 'sessionCurrentLevel',
    rewardPoints: 20,
  ),
  MatchMission(
    id: 'match_m4',
    description: 'Score 100 points',
    target: 100,
    statKey: 'sessionScore',
    rewardPoints: 25,
  ),
  MatchMission(
    id: 'match_m5',
    description: 'Play 3 different topic levels',
    target: 3,
    statKey: 'sessionTopicsPlayed',
    rewardPoints: 40,
  ),
];

// ============================================================================
// MATCHING ACHIEVEMENT SERVICE
// ============================================================================

class MatchAchievementService {
  Future<List<MatchAchievement>> checkAchievements({
    required String username,
    required Map<String, dynamic> stats,
  }) async {
    final userId = await StudentCache.getUserId() ?? '';
    if (userId.isEmpty) return [];

    final doc = FirebaseFirestore.instance
        .collection('matching_achievements')
        .doc(userId);
    final snap = await doc.get();
    final existing = List<String>.from(snap.data()?['unlocked'] ?? []);

    final newlyUnlocked = <MatchAchievement>[];
    for (final ach in kMatchAchievements) {
      if (!existing.contains(ach.id) && ach.isUnlocked(stats)) {
        newlyUnlocked.add(ach);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await doc.set({
        'unlocked': [...existing, ...newlyUnlocked.map((a) => a.id)],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return newlyUnlocked;
  }
}

// ============================================================================
// MISSIONS PANEL WIDGET (Matching-specific)
// ============================================================================

class MatchMissionsPanel extends StatefulWidget {
  final Map<String, dynamic> sessionStats;
  const MatchMissionsPanel({Key? key, required this.sessionStats})
    : super(key: key);

  @override
  State<MatchMissionsPanel> createState() => _MatchMissionsPanelState();
}

class _MatchMissionsPanelState extends State<MatchMissionsPanel> {
  bool _expanded = false; // collapsed by default in-game to save space

  @override
  Widget build(BuildContext context) {
    final done =
        kMatchMissions.where((m) {
          final v = widget.sessionStats[m.statKey] ?? 0;
          return (v is int ? v : 0) >= m.target;
        }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  const Text(
                    'Missions',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$done/${kMatchMissions.length}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: kMatchMissions.map((m) => _missionRow(m)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _missionRow(MatchMission mission) {
    final raw = widget.sessionStats[mission.statKey] ?? 0;
    final int current = raw is bool ? (raw ? mission.target : 0) : (raw as int);
    final bool isDone = current >= mission.target;
    final double progress =
        (current / mission.target).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? Colors.green.withOpacity(0.2) : Colors.white10,
              border: Border.all(
                color: isDone ? Colors.greenAccent : Colors.white24,
              ),
            ),
            child:
                isDone
                    ? const Icon(
                      Icons.check,
                      color: Colors.greenAccent,
                      size: 10,
                    )
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.description,
                  style: TextStyle(
                    color: isDone ? Colors.white38 : Colors.white70,
                    fontSize: 11,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isDone) ...[
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isDone ? '✓' : '$current/${mission.target}',
            style: TextStyle(
              color: isDone ? Colors.greenAccent : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '+${mission.rewardPoints}',
            style: const TextStyle(color: Colors.amber, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime date;
  final Difficulty difficulty;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.date,
    required this.difficulty,
  });
}

enum Difficulty { easy, medium, hard }

enum GameState { difficultySelect, playing, paused, gameOver, leaderboard }

// ============================================================================
// SCREEN
// ============================================================================

class TriviaScreen extends StatefulWidget {
  final String role;
  const TriviaScreen({super.key, required this.role});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen>
    with TickerProviderStateMixin {
  final MatchAchievementService _achService = MatchAchievementService();

  GameState _gameState = GameState.difficultySelect;
  Difficulty? selectedDifficulty;
  int currentLevel = 1;
  int score = 0;
  int totalMatches = 0;
  int? firstIndex;
  bool isProcessing = false;
  List<LeaderboardEntry> leaderboard = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;

  // Per-level tracking for achievements
  int _wrongFlipsThisLevel = 0;
  int _levelStartSeconds = 0;
  bool _speedMatchUnlocked = false;
  Set<String> _topicsPlayedThisSession = {};
  int _wrongFlipsThisGame = 0;
  Set<String> _difficultiesWon = {};

  // Session stats for missions panel
  final Map<String, dynamic> _sessionStats = {
    'sessionMatches': 0,
    'sessionFlawlessLevels': 0,
    'sessionCurrentLevel': 1,
    'sessionScore': 0,
    'sessionTopicsPlayed': 0,
  };

  late AnimationController _pulseController;
  late AnimationController _cardFlipController;

  final Map<Difficulty, Map<String, dynamic>> difficultySettings = {
    Difficulty.easy: {
      'name': 'Easy',
      'icon': '😊',
      'color': Colors.green,
      'pairsPerLevel': 2,
      'timeLimit': 60,
      'wrongPenalty': -2,
      'correctPoints': 10,
      'totalLevels': 5,
    },
    Difficulty.medium: {
      'name': 'Medium',
      'icon': '🤔',
      'color': Colors.orange,
      'pairsPerLevel': 3,
      'timeLimit': 45,
      'wrongPenalty': -3,
      'correctPoints': 15,
      'totalLevels': 7,
    },
    Difficulty.hard: {
      'name': 'Hard',
      'icon': '🔥',
      'color': Colors.red,
      'pairsPerLevel': 4,
      'timeLimit': 30,
      'wrongPenalty': -5,
      'correctPoints': 20,
      'totalLevels': 10,
    },
  };

  final List<Map<String, String>> allTerms = [
    {
      "term": "🌱 Chlorophyll",
      "definition": "Green pigment in plants",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "☀️ Sunlight",
      "definition": "Energy source for plants",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "🍃 Photosynthesis",
      "definition": "Plants making food from sunlight",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "💨 Carbon Dioxide",
      "definition": "Gas plants breathe in",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "🌿 Oxygen",
      "definition": "Gas plants release",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "🍂 Glucose",
      "definition": "Sugar made by plants",
      "topic": "🌱 Photosynthesis",
    },
    {
      "term": "☀️ Sun",
      "definition": "Star at center of solar system",
      "topic": "🪐 Solar System",
    },
    {
      "term": "🌍 Earth",
      "definition": "Third planet from the Sun",
      "topic": "🪐 Solar System",
    },
    {
      "term": "🌙 Moon",
      "definition": "Natural satellite of Earth",
      "topic": "🪐 Solar System",
    },
    {
      "term": "🪐 Saturn",
      "definition": "Planet with beautiful rings",
      "topic": "🪐 Solar System",
    },
    {
      "term": "🔴 Mars",
      "definition": "The red planet",
      "topic": "🪐 Solar System",
    },
    {
      "term": "🌌 Galaxy",
      "definition": "System of billions of stars",
      "topic": "🪐 Solar System",
    },
    {
      "term": "💧 Melting",
      "definition": "Solid turning into liquid",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "☁️ Evaporation",
      "definition": "Liquid turning into gas",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "❄️ Freezing",
      "definition": "Liquid turning into solid",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "💦 Condensation",
      "definition": "Gas turning into liquid",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "🧊 Solid",
      "definition": "Matter with fixed shape",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "💧 Liquid",
      "definition": "Matter that flows",
      "topic": "💧 Changes of Matter",
    },
    {
      "term": "🌿 Producer",
      "definition": "Makes its own food",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🦌 Herbivore",
      "definition": "Animal that eats plants",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🦁 Carnivore",
      "definition": "Animal that eats meat",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🐻 Omnivore",
      "definition": "Eats both plants and animals",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🦅 Predator",
      "definition": "Hunter in food chain",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🐰 Prey",
      "definition": "Animal that is hunted",
      "topic": "🦁 Food Chain",
    },
    {
      "term": "🌧️ Precipitation",
      "definition": "Water falling from clouds",
      "topic": "🌊 Water Cycle",
    },
    {
      "term": "💧 Collection",
      "definition": "Water gathering in oceans",
      "topic": "🌊 Water Cycle",
    },
    {
      "term": "☁️ Water Cycle",
      "definition": "Continuous movement of water",
      "topic": "🌊 Water Cycle",
    },
    {
      "term": "🌊 Transpiration",
      "definition": "Water release from plants",
      "topic": "🌊 Water Cycle",
    },
    {
      "term": "🌈 Runoff",
      "definition": "Water flowing over land",
      "topic": "🌊 Water Cycle",
    },
    {
      "term": "💦 Condensation",
      "definition": "Water vapor forming clouds",
      "topic": "🌊 Water Cycle",
    },
  ];

  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    AudioService.playBackgroundMusic("matchingGame.mp3");
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _cardFlipController.dispose();
    AudioService.stopBackgroundMusic();
    super.dispose();
  }

  void _startGame(Difficulty difficulty) {
    setState(() {
      selectedDifficulty = difficulty;
      currentLevel = 1;
      score = 0;
      totalMatches = 0;
      _gameState = GameState.playing;
      _isNewHighScore = false;
      _wrongFlipsThisGame = 0;
      _topicsPlayedThisSession.clear();
      _sessionStats['sessionMatches'] = 0;
      _sessionStats['sessionFlawlessLevels'] = 0;
      _sessionStats['sessionCurrentLevel'] = 1;
      _sessionStats['sessionScore'] = 0;
      _sessionStats['sessionTopicsPlayed'] = 0;
    });
    _prepareCards();
    _startTimer();
  }

  void _pauseGame() {
    if (_gameState != GameState.playing) return;
    _timer?.cancel();
    setState(() => _gameState = GameState.paused);
    AudioService.pauseBackgroundMusic();
  }

  void _resumeGame() {
    if (_gameState != GameState.paused) return;
    setState(() => _gameState = GameState.playing);
    _startTimer();
    AudioService.resumeBackgroundMusic();
  }

  void _startTimer() {
    _timer?.cancel();
    final settings = difficultySettings[selectedDifficulty]!;
    final timeLimit = settings['timeLimit'] as int;
    setState(() {
      _remainingSeconds = timeLimit;
      _levelStartSeconds = timeLimit;
      _wrongFlipsThisLevel = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == GameState.paused) return;
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _showSnack("⏰ Time's Up!", Colors.red);
    setState(() => score = (score - 10).clamp(0, 9999));
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final settings = difficultySettings[selectedDifficulty]!;
      if (currentLevel < (settings['totalLevels'] as int)) {
        setState(() {
          currentLevel++;
          _gameState = GameState.playing;
        });
        _sessionStats['sessionCurrentLevel'] = currentLevel;
        _prepareCards();
        _startTimer();
      } else {
        _endGame();
      }
    });
  }

  void _prepareCards() {
    if (selectedDifficulty == null) return;
    final settings = difficultySettings[selectedDifficulty]!;
    final pairsCount = settings['pairsPerLevel'] as int;

    final topicIndex = (currentLevel - 1) % 5;
    final topics = [
      "🌱 Photosynthesis",
      "🪐 Solar System",
      "💧 Changes of Matter",
      "🦁 Food Chain",
      "🌊 Water Cycle",
    ];
    final currentTopic = topics[topicIndex];

    _topicsPlayedThisSession.add(currentTopic);
    _sessionStats['sessionTopicsPlayed'] = _topicsPlayedThisSession.length;

    final topicTerms =
        allTerms.where((t) => t['topic'] == currentTopic).toList()
          ..shuffle(Random());
    final selectedPairs = topicTerms.take(pairsCount).toList();

    _cards = [];
    for (final pair in selectedPairs) {
      _cards.add(pair['term']!);
      _cards.add(pair['definition']!);
    }
    _cards.shuffle(Random());
    _flipped = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    firstIndex = null;
    isProcessing = false;
  }

  void _flipCard(int index) {
    if (_gameState != GameState.playing) return;
    if (_remainingSeconds <= 0 || isProcessing) return;
    if (_flipped[index] || _matched[index]) return;

    setState(() => _flipped[index] = true);

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      isProcessing = true;
      final int savedFirst = firstIndex!;

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        final settings = difficultySettings[selectedDifficulty]!;

        if (_isMatch(savedFirst, index)) {
          final timeElapsed = _levelStartSeconds - _remainingSeconds;
          if (totalMatches % (settings['pairsPerLevel'] as int) == 0 &&
              timeElapsed < 10) {
            _speedMatchUnlocked = true;
          }

          setState(() {
            score += settings['correctPoints'] as int;
            totalMatches++;
            _matched[savedFirst] = true;
            _matched[index] = true;
            firstIndex = null;
            isProcessing = false;
            _sessionStats['sessionMatches'] = totalMatches;
            _sessionStats['sessionScore'] = score;
          });
          _showSnack(
            "🎉 Match! +${settings['correctPoints']} pts",
            Colors.green,
          );

          if (_matched.every((m) => m)) {
            _handleLevelComplete();
          }
        } else {
          setState(() {
            score = (score + (settings['wrongPenalty'] as int)).clamp(0, 9999);
            _flipped[savedFirst] = false;
            _flipped[index] = false;
            firstIndex = null;
            isProcessing = false;
            _wrongFlipsThisLevel++;
            _wrongFlipsThisGame++;
            _sessionStats['sessionScore'] = score;
          });
          _showSnack(
            "❌ Not a match! ${settings['wrongPenalty']} pts",
            Colors.red,
          );
        }
      });
    }
  }

  void _handleLevelComplete() {
    _timer?.cancel();
    final settings = difficultySettings[selectedDifficulty]!;
    final totalLevels = settings['totalLevels'] as int;

    if (_wrongFlipsThisLevel == 0) {
      setState(() {
        _sessionStats['sessionFlawlessLevels'] =
            (_sessionStats['sessionFlawlessLevels'] as int) + 1;
      });
    }

    final timeBonus = (_remainingSeconds * 0.5).floor();
    setState(() => score += timeBonus);
    if (timeBonus > 0)
      _showSnack("⚡ Speed bonus! +$timeBonus pts", Colors.amber);

    if (currentLevel < totalLevels) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          currentLevel++;
          _gameState = GameState.playing;
          _sessionStats['sessionCurrentLevel'] = currentLevel;
        });
        _showSnack("⭐ Level $currentLevel!", Colors.blue);
        _prepareCards();
        _startTimer();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), _endGame);
    }
  }

  void _endGame() async {
    _timer?.cancel();
    if (score > _highScore) {
      _highScore = score;
      _isNewHighScore = true;
    }

    // Track difficulty wins
    if (selectedDifficulty != null)
      _difficultiesWon.add(selectedDifficulty!.name);
    setState(() => _gameState = GameState.gameOver);

    await FirebaseLeaderboardService.saveScore(
      gameName: FirebaseLeaderboardService.GAME_MATCHING,
      score: score,
      metadata: {
        'difficulty': selectedDifficulty?.name ?? 'unknown',
        'levelsCompleted': currentLevel,
        'totalMatches': totalMatches,
      },
    );

    // Check achievements
    final achStats = {
      'totalMatches': totalMatches,
      'flawlessLevels': _sessionStats['sessionFlawlessLevels'],
      'speedMatches': _speedMatchUnlocked,
      'topicsPlayed': _topicsPlayedThisSession.length,
      'hardLevelsCompleted':
          selectedDifficulty == Difficulty.hard ? currentLevel : 0,
      'bestScore': score,
      'gamesWithNoPenalty': _wrongFlipsThisGame == 0 ? 1 : 0,
      'easyWins': _difficultiesWon.contains('easy') ? 1 : 0,
      'mediumWins': _difficultiesWon.contains('medium') ? 1 : 0,
      'hardWins': _difficultiesWon.contains('hard') ? 1 : 0,
    };

    final newAchs = await _achService.checkAchievements(
      username: widget.role,
      stats: achStats,
    );
    if (newAchs.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showAchievementDialog(newAchs);
      });
    }

    leaderboard.add(
      LeaderboardEntry(
        playerName: widget.role,
        score: score,
        date: DateTime.now(),
        difficulty: selectedDifficulty!,
      ),
    );
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 10) leaderboard = leaderboard.sublist(0, 10);
  }

  bool _isMatch(int a, int b) {
    final cardA = _cards[a];
    final cardB = _cards[b];
    for (final term in allTerms) {
      if ((term['term'] == cardA && term['definition'] == cardB) ||
          (term['term'] == cardB && term['definition'] == cardA))
        return true;
    }
    return false;
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAchievementDialog(List<MatchAchievement> achievements) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🎉", style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    achievements.length == 1
                        ? "Achievement Unlocked!"
                        : "${achievements.length} Achievements Unlocked!",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...achievements.map(
                    (a) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: a.color.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Text(a.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  a.description,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tierColor(a.tier).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _tierLabel(a.tier),
                                    style: TextStyle(
                                      color: _tierColor(a.tier),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Awesome!",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _tierColor(MatchAchievementTier tier) {
    switch (tier) {
      case MatchAchievementTier.bronze:
        return Colors.brown;
      case MatchAchievementTier.silver:
        return Colors.blueGrey;
      case MatchAchievementTier.gold:
        return Colors.amber;
    }
  }

  String _tierLabel(MatchAchievementTier tier) {
    switch (tier) {
      case MatchAchievementTier.bronze:
        return '🥉 Bronze';
      case MatchAchievementTier.silver:
        return '🥈 Silver';
      case MatchAchievementTier.gold:
        return '🥇 Gold';
    }
  }

  String _getLevelTopic() {
    final topics = [
      "🌱 Photosynthesis",
      "🪐 Solar System",
      "💧 Changes of Matter",
      "🦁 Food Chain",
      "🌊 Water Cycle",
    ];
    return topics[(currentLevel - 1) % 5];
  }

  @override
  Widget build(BuildContext context) {
    switch (_gameState) {
      case GameState.difficultySelect:
        return _buildDifficultySelect();
      case GameState.playing:
      case GameState.paused:
        return _buildGameScreen();
      case GameState.gameOver:
        return _buildGameOver();
      case GameState.leaderboard:
        return _buildLeaderboard();
    }
  }

  Widget _buildDifficultySelect() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text(
          "🎮 Science Matching Game",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              AudioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () async {
              await AudioService.toggleMute();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white),
            onPressed: () => setState(() => _gameState = GameState.leaderboard),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🃏", style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  "Match the Terms!",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Flip cards to match science terms with their definitions",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                ...Difficulty.values.map((diff) {
                  final s = difficultySettings[diff]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DifficultyCard(
                      icon: s['icon'] as String,
                      name: s['name'] as String,
                      color: s['color'] as Color,
                      pairs: s['pairsPerLevel'] as int,
                      timeLimit: s['timeLimit'] as int,
                      penalty: s['wrongPenalty'] as int,
                      totalLevels: s['totalLevels'] as int,
                      onTap: () => _startGame(diff),
                    ),
                  );
                }),
                if (_highScore > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Your Best: $_highScore pts",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final settings = difficultySettings[selectedDifficulty]!;
    final totalLevels = settings['totalLevels'] as int;
    final timerColor =
        _remainingSeconds > 10 ? Colors.greenAccent : Colors.redAccent;
    final isPaused = _gameState == GameState.paused;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _gameState = GameState.difficultySelect;
              selectedDifficulty = null;
            });
          },
        ),
        title: Text(
          _getLevelTopic(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 28,
            ),
            onPressed: isPaused ? _resumeGame : _pauseGame,
          ),
          IconButton(
            icon: Icon(
              AudioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () async {
              await AudioService.toggleMute();
              setState(() {});
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF3949AB),
                ],
              ),
            ),
            child: Column(
              children: [
                // HUD
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Level $currentLevel / $totalLevels",
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: currentLevel / totalLevels,
                                backgroundColor: Colors.white24,
                                color: Colors.yellowAccent,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const Text(
                            "Score",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            "$score",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: timerColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: timerColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$_remainingSeconds s",
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Missions panel
                MatchMissionsPanel(sessionStats: _sessionStats),
                const SizedBox(height: 6),

                // Difficulty badge
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (settings['color'] as Color).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: settings['color'] as Color,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          "${settings['icon']} ${settings['name']}",
                          style: TextStyle(
                            color: settings['color'] as Color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${settings['correctPoints']} pts per match",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Card grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GridView.builder(
                      itemCount: _cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _cards.length <= 4 ? 2 : 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: _cards.length <= 4 ? 1.3 : 1.1,
                      ),
                      itemBuilder:
                          (context, index) => _buildCard(index, settings),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pause overlay
          if (isPaused)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F3E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("⏸️", style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 12),
                      const Text(
                        "Game Paused",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Score: $score pts",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(
                            "Resume",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _resumeGame,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Text("Quit to Menu"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            setState(() {
                              _gameState = GameState.difficultySelect;
                              selectedDifficulty = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(int index, Map<String, dynamic> settings) {
    final isFlipped = _flipped[index] || _matched[index];
    final isMatchedCard = _matched[index];

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient:
              isMatchedCard
                  ? const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : isFlipped
                  ? LinearGradient(
                    colors: [
                      (settings['color'] as Color).withOpacity(0.8),
                      (settings['color'] as Color),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : const LinearGradient(
                    colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isMatchedCard
                    ? Colors.greenAccent
                    : isFlipped
                    ? Colors.white70
                    : Colors.white24,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isMatchedCard
                      ? Colors.greenAccent.withOpacity(0.4)
                      : isFlipped
                      ? (settings['color'] as Color).withOpacity(0.4)
                      : Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child:
            isFlipped
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isMatchedCard)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    if (isMatchedCard) const SizedBox(height: 4),
                    Text(
                      _cards[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, color: Colors.white70, size: 32),
                    SizedBox(height: 6),
                    Text(
                      "Tap to flip",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildGameOver() {
    final settings = difficultySettings[selectedDifficulty]!;
    final totalLevels = settings['totalLevels'] as int;
    final completedAll = currentLevel >= totalLevels;
    final pct =
        (score /
                (totalLevels *
                    (settings['pairsPerLevel'] as int) *
                    (settings['correctPoints'] as int)) *
                100)
            .clamp(0, 100)
            .round();
    final String rank =
        pct >= 90
            ? "🌟 Science Master!"
            : pct >= 70
            ? "🥇 Expert Scientist!"
            : pct >= 50
            ? "🥈 Good Scientist!"
            : "🥉 Keep Practicing!";

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  completedAll ? "🏆" : "🎮",
                  style: const TextStyle(fontSize: 72),
                ),
                const SizedBox(height: 16),
                Text(
                  completedAll ? "Game Complete!" : "Game Over!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rank,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isNewHighScore) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Text(
                      "🏆 NEW HIGH SCORE!",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$score",
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "points",
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      _statRow(
                        "🎯 Levels Completed",
                        "$currentLevel / $totalLevels",
                      ),
                      _statRow("✅ Total Matches", "$totalMatches"),
                      _statRow(
                        "${settings['icon']} Difficulty",
                        settings['name'] as String,
                      ),
                      if (_highScore > 0 && !_isNewHighScore)
                        _statRow("🏆 Personal Best", "$_highScore pts"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text(
                      "Play Again",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _startGame(selectedDifficulty!),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Main Menu"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        () => setState(
                          () => _gameState = GameState.difficultySelect,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.leaderboard, color: Colors.amber),
                    label: const Text(
                      "Leaderboard",
                      style: TextStyle(color: Colors.amber, fontSize: 15),
                    ),
                    onPressed:
                        () =>
                            setState(() => _gameState = GameState.leaderboard),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6F00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => setState(() => _gameState = GameState.difficultySelect),
        ),
        title: const Text(
          "🏆 Leaderboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              AudioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () async {
              await AudioService.toggleMute();
              setState(() {});
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child:
            leaderboard.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("🏅", style: TextStyle(fontSize: 72)),
                      SizedBox(height: 16),
                      Text(
                        "No scores yet!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Complete a game to appear here!",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboard[index];
                    final medal =
                        index == 0
                            ? "🥇"
                            : index == 1
                            ? "🥈"
                            : index == 2
                            ? "🥉"
                            : "⭐";
                    final ds = difficultySettings[entry.difficulty]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            index < 3
                                ? Colors.amber.withOpacity(0.12)
                                : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              index < 3
                                  ? Colors.amber.shade700
                                  : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "${ds['icon']} ${ds['name']} • ${_formatDate(entry.date)}",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${entry.score} pts",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }

  String _formatDate(DateTime date) => "${date.month}/${date.day}/${date.year}";
}

class _DifficultyCard extends StatelessWidget {
  final String icon;
  final String name;
  final Color color;
  final int pairs;
  final int timeLimit;
  final int penalty;
  final int totalLevels;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.icon,
    required this.name,
    required this.color,
    required this.pairs,
    required this.timeLimit,
    required this.penalty,
    required this.totalLevels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$pairs pairs  •  ${timeLimit}s per level  •  $totalLevels levels",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "$penalty pts wrong answer penalty",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
