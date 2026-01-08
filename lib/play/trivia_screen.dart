import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isMuted = false;

  /// Initialize and start background music
  static Future<void> playBackgroundMusic() async {
    try {
      await _audioPlayer.setSource(
        AssetSource('lib/assets/audio/matchingGame.mp3'),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the music
      await _audioPlayer.setVolume(_isMuted ? 0.0 : 0.5); // Start at 50% volume
      await _audioPlayer.resume();
    } catch (e) {
      print('Error loading music: $e'); // Handle errors gracefully
    }
  }

  /// Stop music (e.g., when leaving the screen)
  static Future<void> stopMusic() async {
    await _audioPlayer.stop();
  }

  /// Toggle mute/unmute
  static Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _audioPlayer.setVolume(_isMuted ? 0.0 : 0.5);
  }

  /// Check if muted
  static bool get isMuted => _isMuted;
}

class TriviaScreen extends StatefulWidget {
  final String role;
  const TriviaScreen({super.key, required this.role});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

enum Difficulty { easy, medium, hard }

class _TriviaScreenState extends State<TriviaScreen> {
  Difficulty? selectedDifficulty;
  int currentLevel = 1;
  int score = 0;
  int? firstIndex;
  bool showLeaderboard = false;
  bool isProcessing = false; // ✅ NEW: Prevent multiple taps while processing
  List<LeaderboardEntry> leaderboard = [];
  Timer? _timer;
  int _remainingSeconds = 0;

  // Difficulty settings
  Map<Difficulty, Map<String, dynamic>> difficultySettings = {
    Difficulty.easy: {
      'name': 'Easy',
      'icon': '😊',
      'color': Colors.green,
      'pairsPerLevel': 2,
      'timeLimit': 60,
      'wrongPenalty': -2,
      'correctPoints': 10,
    },
    Difficulty.medium: {
      'name': 'Medium',
      'icon': '🤔',
      'color': Colors.orange,
      'pairsPerLevel': 3,
      'timeLimit': 45,
      'wrongPenalty': -3,
      'correctPoints': 15,
    },
    Difficulty.hard: {
      'name': 'Hard',
      'icon': '🔥',
      'color': Colors.red,
      'pairsPerLevel': 4,
      'timeLimit': 30,
      'wrongPenalty': -5,
      'correctPoints': 20,
    },
  };

  // All available terms (will be filtered by difficulty)
  final List<Map<String, String>> allTerms = [
    // Photosynthesis
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

    // Solar System
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

    // Changes of Matter
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

    // Food Chain
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

    // Water Cycle
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

  @override
  void initState() {
    super.initState();

    // Start background music when entering the trivia screen
    AudioService.playBackgroundMusic();
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.stopMusic(); // Stop music when leaving
    super.dispose();
  }

  void _startGame(Difficulty difficulty) {
    setState(() {
      selectedDifficulty = difficulty;
      currentLevel = 1;
      score = 0;
      _prepareCards();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final settings = difficultySettings[selectedDifficulty]!;
    setState(() {
      _remainingSeconds = settings['timeLimit'] as int;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _showMessage("⏰ Time's Up! Moving to next level", Colors.red);
    Future.delayed(const Duration(seconds: 2), () {
      if (currentLevel < 10) {
        setState(() {
          currentLevel++;
          _prepareCards();
          _startTimer();
        });
      } else {
        _showMessage("🏆 Game Complete!", Colors.purple);
        _addToLeaderboard();
      }
    });
  }

  void _prepareCards() {
    if (selectedDifficulty == null) return;

    final settings = difficultySettings[selectedDifficulty]!;
    final pairsCount = settings['pairsPerLevel'] as int;

    // Get terms for current topic
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
        allTerms.where((term) => term['topic'] == currentTopic).toList();
    topicTerms.shuffle(Random());

    final selectedPairs = topicTerms.take(pairsCount).toList();

    _cards = [];
    for (var pair in selectedPairs) {
      _cards.add(pair['term']!);
      _cards.add(pair['definition']!);
    }
    _cards.shuffle(Random());
    _flipped = List<bool>.filled(_cards.length, false);
    firstIndex = null;
    isProcessing = false; // ✅ Reset processing state
  }

  void _flipCard(int index) {
    // ✅ FIXED: Prevent interactions during processing and when time is up
    if (_remainingSeconds <= 0 || isProcessing || _flipped[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (firstIndex == null) {
      // First card selected
      firstIndex = index;
    } else {
      // Second card selected - prevent further taps
      isProcessing = true;
      final int savedFirstIndex = firstIndex!; // ✅ Save the first index

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return; // ✅ Safety check

        final settings = difficultySettings[selectedDifficulty]!;

        if (_isMatch(savedFirstIndex, index)) {
          // ✅ CORRECT MATCH
          setState(() {
            score += settings['correctPoints'] as int;
            firstIndex = null;
            isProcessing = false;
          });
          _showMessage(
            "🎉 Great Match! +${settings['correctPoints']} points",
            Colors.green,
          );

          // Check if level completed
          if (_flipped.every((f) => f)) {
            _handleLevelComplete();
          }
        } else {
          // ✅ WRONG MATCH - Fixed to properly close both cards
          setState(() {
            score += settings['wrongPenalty'] as int;
            _flipped[savedFirstIndex] = false; // ✅ Close first card
            _flipped[index] = false; // ✅ Close second card
            firstIndex = null;
            isProcessing = false;
          });
          _showMessage(
            "❌ Wrong! ${settings['wrongPenalty']} points",
            Colors.red,
          );
        }
      });
    }
  }

  void _handleLevelComplete() {
    _timer?.cancel();
    if (currentLevel < 10) {
      setState(() {
        currentLevel++;
      });
      _showMessage("⭐ Level $currentLevel Unlocked!", Colors.blue);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _prepareCards();
          _startTimer();
        }
      });
    } else {
      _showMessage("🏆 Amazing! You Won!", Colors.purple);
      _addToLeaderboard();
    }
  }

  bool _isMatch(int a, int b) {
    String cardA = _cards[a];
    String cardB = _cards[b];

    for (var term in allTerms) {
      if ((term['term'] == cardA && term['definition'] == cardB) ||
          (term['term'] == cardB && term['definition'] == cardA)) {
        return true;
      }
    }
    return false;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addToLeaderboard() {
    leaderboard.add(
      LeaderboardEntry(
        playerName: widget.role,
        score: score,
        date: DateTime.now(),
        difficulty: selectedDifficulty!,
      ),
    );
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 10) {
      leaderboard = leaderboard.sublist(0, 10);
    }
  }

  String _getLevelTopic() {
    final topicIndex = (currentLevel - 1) % 5;
    final topics = [
      "🌱 Photosynthesis",
      "🪐 Solar System",
      "💧 Changes of Matter",
      "🦁 Food Chain",
      "🌊 Water Cycle",
    ];
    return topics[topicIndex];
  }

  @override
  Widget build(BuildContext context) {
    if (showLeaderboard) {
      return _buildLeaderboard();
    }

    if (selectedDifficulty == null) {
      return _buildDifficultySelection();
    }

    return _buildGameScreen();
  }

  Widget _buildDifficultySelection() {
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
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Mute/Unmute Button (New)
          IconButton(
            icon: Icon(
              AudioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              await AudioService.toggleMute();
              setState(() {}); // Refresh UI to update icon
            },
            tooltip: AudioService.isMuted ? "Unmute Music" : "Mute Music",
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, size: 28),
            onPressed: () {
              setState(() {
                showLeaderboard = true;
              });
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Choose Your Challenge!",
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ...Difficulty.values.map((difficulty) {
                final settings = difficultySettings[difficulty]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 32,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _startGame(difficulty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: settings['color'] as Color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          settings['icon'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${settings['pairsPerLevel']} pairs • ${settings['timeLimit']}s • ${settings['wrongPenalty']} pts penalty",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final settings = difficultySettings[selectedDifficulty]!;
    final timerColor =
        _remainingSeconds > 10 ? Colors.greenAccent : Colors.redAccent;

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
              selectedDifficulty = null;
              score = 0;
              currentLevel = 1;
            });
          },
        ),
        title: const Text(
          "🎮 Science Matching Game",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${settings['icon']} ${settings['name']}",
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: timerColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: timerColor, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              "$_remainingSeconds s",
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLevelTopic(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip("Level $currentLevel/10", Icons.stars),
                      _buildInfoChip("Score: $score", Icons.emoji_events),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      _cards.length <= 4
                          ? 2
                          : _cards.length <= 6
                          ? 2
                          : 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _flipCard(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        gradient:
                            _flipped[index]
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF66BB6A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                : const LinearGradient(
                                  colors: [
                                    Color(0xFF5C6BC0),
                                    Color(0xFF7E57C2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _flipped[index]
                                    ? Colors.greenAccent.withOpacity(0.5)
                                    : Colors.purpleAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child:
                          _flipped[index]
                              ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  _cards[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellowAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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
          onPressed: () {
            setState(() {
              showLeaderboard = false;
            });
          },
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
          // Mute/Unmute Button (New)
          IconButton(
            icon: Icon(
              AudioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () async {
              await AudioService.toggleMute();
              setState(() {}); // Refresh UI to update icon
            },
            tooltip: AudioService.isMuted ? "Unmute Music" : "Mute Music",
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
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 100,
                        color: Colors.yellowAccent,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No scores yet!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Complete all levels to get on the board!",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    final diffSettings = difficultySettings[entry.difficulty]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              index < 3
                                  ? [
                                    const Color(0xFFFFD700).withOpacity(0.3),
                                    const Color(0xFFFFA500).withOpacity(0.3),
                                  ]
                                  : [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      diffSettings['icon'] as String,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${diffSettings['name']} • ${_formatDate(entry.date)}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
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
                                fontSize: 16,
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

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }
}

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
