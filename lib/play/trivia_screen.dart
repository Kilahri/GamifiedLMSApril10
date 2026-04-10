import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';
import 'package:elearningapp_flutter/services/audio_service.dart';
import 'package:elearningapp_flutter/services/game_achievement_service.dart';

/// Compact collapsible missions panel — embed in any game screen.
/// Pass [sessionStats] as a reactive map; the panel auto-updates progress.
class MissionsPanel extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic> sessionStats;
  final Color accentColor;

  const MissionsPanel({
    Key? key,
    required this.gameId,
    required this.sessionStats,
    this.accentColor = Colors.purpleAccent,
  }) : super(key: key);

  @override
  State<MissionsPanel> createState() => _MissionsPanelState();
}

class _MissionsPanelState extends State<MissionsPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final missions = GameAchievementService.missionsFor(widget.gameId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header row — tap to collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Missions',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _completedBadge(missions),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: missions.map((m) => _missionRow(m)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _completedBadge(List<GameMission> missions) {
    final done =
        missions.where((m) {
          final val = widget.sessionStats[m.statKey] ?? 0;
          return (val is int ? val : 0) >= m.target;
        }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$done/${missions.length}',
        style: TextStyle(
          color: widget.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _missionRow(GameMission mission) {
    final rawVal = widget.sessionStats[mission.statKey] ?? 0;
    final int current =
        rawVal is bool ? (rawVal ? mission.target : 0) : (rawVal as int);
    final bool done = current >= mission.target;
    final double progress =
        (current / mission.target).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // Status circle
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? Colors.green.withOpacity(0.2) : Colors.white10,
              border: Border.all(
                color: done ? Colors.greenAccent : Colors.white24,
              ),
            ),
            child:
                done
                    ? const Icon(
                      Icons.check,
                      color: Colors.greenAccent,
                      size: 12,
                    )
                    : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.description,
                  style: TextStyle(
                    color: done ? Colors.white38 : Colors.white70,
                    fontSize: 12,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!done) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      color: widget.accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            done ? '✓' : '$current/${mission.target}',
            style: TextStyle(
              color: done ? Colors.greenAccent : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+${mission.rewardPoints}',
            style: const TextStyle(color: Colors.amber, fontSize: 10),
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────────
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

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _cardFlipController;

  // ── Difficulty config ──────────────────────────────────────────────────────
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

  // ── Terms ──────────────────────────────────────────────────────────────────
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

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    AudioService.stopBackgroundMusic();
    AudioService.playBackgroundMusic("matchingGame.mp3");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    _cardFlipController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      AudioService.pauseBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      if (_gameState == GameState.playing) {
        AudioService.resumeBackgroundMusic();
      }
    }
  }

  // ── Game logic ─────────────────────────────────────────────────────────────
  void _startGame(Difficulty difficulty) {
    AudioService.stopBackgroundMusic(); // ✅ reset
    AudioService.playBackgroundMusic('matchingGame.mp3');
    setState(() {
      selectedDifficulty = difficulty;
      currentLevel = 1;
      score = 0;
      totalMatches = 0;
      _gameState = GameState.playing;
      _isNewHighScore = false;
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
    setState(() => _remainingSeconds = settings['timeLimit'] as int);

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
    final settings = difficultySettings[selectedDifficulty]!;
    final totalLevels = settings['totalLevels'] as int;
    AudioService.playSoundEffect('timeout.mp3');
    _showSnack("⏰ Time's Up!", Colors.red);

    // Lose 10 points for running out of time
    setState(() => score = (score - 10).clamp(0, 9999));

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (currentLevel < totalLevels) {
        setState(() {
          currentLevel++;
          _gameState = GameState.playing;
        });
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
          AudioService.playSoundEffect('correct.mp3'); // ✅ add
          setState(() {
            score += settings['correctPoints'] as int;
            totalMatches++;
            _matched[savedFirst] = true;
            _matched[index] = true;
            firstIndex = null;
            isProcessing = false;
          });
          _showSnack(
            "🎉 Match! +${settings['correctPoints']} pts",
            Colors.green,
          );
          if (_matched.every((m) => m)) {
            _handleLevelComplete();
          }
        } else {
          AudioService.playSoundEffect('wrong.mp3'); // ✅ add
          setState(() {
            score = (score + (settings['wrongPenalty'] as int)).clamp(0, 9999);
            _flipped[savedFirst] = false;
            _flipped[index] = false;
            firstIndex = null;
            isProcessing = false;
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

    // Time bonus
    final timeBonus = (_remainingSeconds * 0.5).floor();
    setState(() => score += timeBonus);

    if (timeBonus > 0) {
      _showSnack("⚡ Speed bonus! +$timeBonus pts", Colors.amber);
    }

    if (currentLevel < totalLevels) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          currentLevel++;
          _gameState = GameState.playing;
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
    AudioService.stopBackgroundMusic();
    // Check high score
    if (score > _highScore) {
      _highScore = score;
      _isNewHighScore = true;
    }

    setState(() => _gameState = GameState.gameOver);

    // Save to leaderboard
    await FirebaseLeaderboardService.saveScore(
      gameName: FirebaseLeaderboardService.GAME_MATCHING,
      score: score,
      metadata: {
        'difficulty': selectedDifficulty?.name ?? 'unknown',
        'levelsCompleted': currentLevel,
        'totalMatches': totalMatches,
      },
    );

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
          (term['term'] == cardB && term['definition'] == cardA)) {
        return true;
      }
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

  // ── BUILD ──────────────────────────────────────────────────────────────────
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

  // ── DIFFICULTY SELECT ──────────────────────────────────────────────────────
  Widget _buildDifficultySelect() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          // ADD THIS BLOCK
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            AudioService.stopBackgroundMusic();
            Navigator.pop(context);
          },
        ),
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

  // ── GAME SCREEN ────────────────────────────────────────────────────────────
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
            AudioService.stopBackgroundMusic();
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
            tooltip: isPaused ? "Resume" : "Pause",
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
                // ── HUD ──
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
                      // Level progress
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
                      // Score
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
                      // Timer
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
                const SizedBox(height: 8),
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
                // ── Card Grid ──
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

          // ── PAUSE OVERLAY ──
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
                            AudioService.stopBackgroundMusic();
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
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

  // ── GAME OVER ──────────────────────────────────────────────────────────────
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
                // Score card
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

  // ── LEADERBOARD ────────────────────────────────────────────────────────────
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

// ── Difficulty Card Widget ─────────────────────────────────────────────────
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
