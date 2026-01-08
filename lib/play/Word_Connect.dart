import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isMuted = false;

  /// Initialize and start background music
  static Future<void> playBackgroundMusic() async {
    try {
      await _audioPlayer.setSource(
        AssetSource('lib/assets/audio/word_connect.mp3'),
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

// --- Data Models ---
class Word {
  final String text;
  final String hint;
  bool isFound;

  Word({required this.text, required this.hint, this.isFound = false});
}

class GameLevel {
  final String category;
  final List<String> letters;
  final List<Word> words;

  GameLevel({
    required this.category,
    required List<String> letters,
    required this.words,
  }) : letters = letters.toList()..shuffle(Random());
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime date;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.date,
  });
}

// --- Game Data: Grade 6 Science Topics ---
class GameData {
  static final List<GameLevel> allLevels = [
    // PHOTOSYNTHESIS (Levels 1-4)
    GameLevel(
      category: "🌱 Photosynthesis",
      letters: ["L", "E", "A", "F"],
      words: [
        Word(text: "LEAF", hint: "Green part of plant that makes food 🍃"),
        Word(text: "ALE", hint: "A type of beverage"),
      ],
    ),
    GameLevel(
      category: "🌱 Photosynthesis",
      letters: ["S", "U", "N", "L", "I", "G", "H", "T"],
      words: [
        Word(text: "SUNLIGHT", hint: "Energy source plants need ☀️"),
        Word(text: "LUNG", hint: "Breathing organ"),
        Word(text: "SUN", hint: "Star in our sky"),
      ],
    ),
    GameLevel(
      category: "🌱 Photosynthesis",
      letters: ["O", "X", "Y", "G", "E", "N"],
      words: [
        Word(text: "OXYGEN", hint: "Gas plants release that we breathe 💨"),
        Word(text: "GONE", hint: "Not here anymore"),
        Word(text: "YEN", hint: "Japanese money"),
      ],
    ),
    GameLevel(
      category: "🌱 Photosynthesis",
      letters: ["C", "H", "L", "O", "R", "O", "P", "L", "A", "S", "T"],
      words: [
        Word(text: "CHLORO", hint: "Prefix meaning green in chloroplast 🌿"),
        Word(text: "CORAL", hint: "Ocean organism"),
        Word(text: "CART", hint: "Wheeled vehicle"),
      ],
    ),

    // SOLAR SYSTEM (Levels 5-8)
    GameLevel(
      category: "🪐 Solar System",
      letters: ["S", "U", "N"],
      words: [
        Word(text: "SUN", hint: "Star at the center of our solar system ☀️"),
        Word(text: "US", hint: "You and me"),
      ],
    ),
    GameLevel(
      category: "🪐 Solar System",
      letters: ["E", "A", "R", "T", "H"],
      words: [
        Word(text: "EARTH", hint: "The third planet from the Sun 🌍"),
        Word(text: "HEART", hint: "Organ that pumps blood"),
        Word(text: "HEAR", hint: "To perceive sound"),
      ],
    ),
    GameLevel(
      category: "🪐 Solar System",
      letters: ["M", "O", "O", "N"],
      words: [
        Word(text: "MOON", hint: "Earth's natural satellite 🌙"),
        Word(text: "NOON", hint: "Midday time"),
      ],
    ),
    GameLevel(
      category: "🪐 Solar System",
      letters: ["O", "R", "B", "I", "T"],
      words: [
        Word(text: "ORBIT", hint: "Path planets take around the Sun 🔄"),
        Word(text: "TRIO", hint: "Group of three"),
        Word(text: "RIOT", hint: "Violent disturbance"),
      ],
    ),

    // CHANGES OF MATTER (Levels 9-12)
    GameLevel(
      category: "💧 Changes of Matter",
      letters: ["S", "O", "L", "I", "D"],
      words: [
        Word(text: "SOLID", hint: "State of matter with fixed shape 🧊"),
        Word(text: "SOIL", hint: "Dirt where plants grow"),
        Word(text: "IDOL", hint: "Hero or star"),
      ],
    ),
    GameLevel(
      category: "💧 Changes of Matter",
      letters: ["L", "I", "Q", "U", "I", "D"],
      words: [
        Word(text: "LIQUID", hint: "State of matter that flows 💧"),
        Word(text: "QUIL", hint: "Part of quill feather"),
      ],
    ),
    GameLevel(
      category: "💧 Changes of Matter",
      letters: ["M", "E", "L", "T", "I", "N", "G"],
      words: [
        Word(text: "MELTING", hint: "Solid changing to liquid when heated 🔥"),
        Word(text: "TILE", hint: "Square floor covering"),
        Word(text: "MINT", hint: "Fresh plant or candy"),
      ],
    ),
    GameLevel(
      category: "💧 Changes of Matter",
      letters: ["F", "R", "E", "E", "Z", "E"],
      words: [
        Word(text: "FREEZE", hint: "Liquid turning into solid ice ❄️"),
        Word(text: "FREE", hint: "Not costing money"),
        Word(text: "REEF", hint: "Coral structure in ocean"),
      ],
    ),

    // FOOD CHAIN (Levels 13-16)
    GameLevel(
      category: "🦁 Food Chain",
      letters: ["P", "L", "A", "N", "T", "S"],
      words: [
        Word(text: "PLANTS", hint: "Producers that make their own food 🌿"),
        Word(text: "SLANT", hint: "To lean or slope"),
        Word(text: "PLAN", hint: "Strategy or idea"),
      ],
    ),
    GameLevel(
      category: "🦁 Food Chain",
      letters: ["H", "E", "R", "B", "I", "V", "O", "R", "E"],
      words: [
        Word(text: "HERBIVORE", hint: "Animal that eats only plants 🦌"),
        Word(text: "HERO", hint: "Brave person"),
        Word(text: "HIVE", hint: "Where bees live"),
      ],
    ),
    GameLevel(
      category: "🦁 Food Chain",
      letters: ["P", "R", "E", "D", "A", "T", "O", "R"],
      words: [
        Word(text: "PREDATOR", hint: "Hunter that eats other animals 🦁"),
        Word(text: "TRADE", hint: "To exchange goods"),
        Word(text: "DARE", hint: "Challenge to do something"),
      ],
    ),
    GameLevel(
      category: "🦁 Food Chain",
      letters: ["P", "R", "E", "Y"],
      words: [
        Word(text: "PREY", hint: "Animal that is hunted for food 🐰"),
        Word(text: "PER", hint: "For each"),
        Word(text: "RYE", hint: "Type of grain"),
      ],
    ),

    // WATER CYCLE (Levels 17-20)
    GameLevel(
      category: "🌊 Water Cycle",
      letters: ["R", "A", "I", "N"],
      words: [
        Word(text: "RAIN", hint: "Water falling from clouds 🌧️"),
        Word(text: "AIR", hint: "What we breathe"),
      ],
    ),
    GameLevel(
      category: "🌊 Water Cycle",
      letters: ["C", "L", "O", "U", "D", "S"],
      words: [
        Word(text: "CLOUDS", hint: "Visible water vapor in the sky ☁️"),
        Word(text: "OULD", hint: "Past tense helper word"),
        Word(text: "SOUL", hint: "Spirit or essence"),
      ],
    ),
    GameLevel(
      category: "🌊 Water Cycle",
      letters: ["E", "V", "A", "P", "O", "R", "A", "T", "E"],
      words: [
        Word(text: "EVAPORATE", hint: "Water turning into vapor ☀️💧"),
        Word(text: "RATE", hint: "Speed or frequency"),
        Word(text: "TRAP", hint: "Device to catch"),
      ],
    ),
    GameLevel(
      category: "🌊 Water Cycle",
      letters: ["C", "Y", "C", "L", "E"],
      words: [
        Word(text: "CYCLE", hint: "Repeating process like water cycle 🔄"),
        Word(text: "EYE", hint: "Organ for seeing"),
      ],
    ),
  ];
}

class WordConnectScreen extends StatefulWidget {
  final String role;

  const WordConnectScreen({super.key, required this.role});

  @override
  State<WordConnectScreen> createState() => _WordConnectScreenState();
}

class _WordConnectScreenState extends State<WordConnectScreen> {
  int _currentLevelIndex = 0;
  int _score = 0;
  late GameLevel _currentLevel;
  String _currentDraggedWord = "";
  List<int> _selectedLetterIndices = [];
  late ConfettiController _confettiController;
  int _currentWordIndex = 0;
  GlobalKey _letterWheelKey = GlobalKey();
  Size? _letterButtonSize;
  List<Offset> _dragLineOffsets = [];
  bool showLeaderboard = false;
  List<LeaderboardEntry> leaderboard = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadLevel(_currentLevelIndex);

    // Start background music
    AudioService.playBackgroundMusic();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    AudioService.stopMusic(); // Stop music when leaving
    super.dispose();
  }

  void _loadLevel(int index) {
    if (index >= GameData.allLevels.length) {
      _showOverallCompletionDialog();
      return;
    }

    final newLevelData = GameData.allLevels[index];
    final List<Word> wordsCopy =
        newLevelData.words
            .map((w) => Word(text: w.text, hint: w.hint))
            .toList();

    _currentLevel = GameLevel(
      category: newLevelData.category,
      letters: newLevelData.letters,
      words: wordsCopy,
    );

    setState(() {
      _currentLevelIndex = index;
      _currentWordIndex = 0;
      _currentDraggedWord = "";
      _selectedLetterIndices = [];
      _dragLineOffsets = [];
      _letterButtonSize = null;
    });
  }

  Offset _getLetterCenterOffset(int index, Size wheelSize) {
    if (wheelSize.isEmpty) return Offset.zero;

    final double wheelRadius = wheelSize.width / 2;
    final double angleStep = 2 * pi / _currentLevel.letters.length;
    double angle = index * angleStep - pi / 2;
    final buttonRadiusOffset = wheelRadius * 0.7;

    return Offset(
      wheelRadius + buttonRadiusOffset * cos(angle),
      wheelRadius + buttonRadiusOffset * sin(angle),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _resetSelection();
    _detectAndSelectLetter(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _detectAndSelectLetter(details.globalPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _checkWord();
    _resetSelection();
  }

  void _resetSelection() {
    setState(() {
      _currentDraggedWord = "";
      _selectedLetterIndices = [];
      _dragLineOffsets = [];
    });
  }

  void _detectAndSelectLetter(Offset globalPosition) {
    if (_letterButtonSize == null || _letterWheelKey.currentContext == null)
      return;

    final RenderBox renderBox =
        _letterWheelKey.currentContext!.findRenderObject() as RenderBox;
    final Offset wheelLocalOrigin = renderBox.localToGlobal(Offset.zero);
    final Offset localPosition = globalPosition - wheelLocalOrigin;
    final Size wheelSize = renderBox.size;

    int? detectedIndex;

    for (int i = 0; i < _currentLevel.letters.length; i++) {
      final buttonCenter = _getLetterCenterOffset(i, wheelSize);
      final dx = localPosition.dx - buttonCenter.dx;
      final dy = localPosition.dy - buttonCenter.dy;
      if (dx * dx + dy * dy <
          (_letterButtonSize!.width / 2) * (_letterButtonSize!.width / 2)) {
        detectedIndex = i;
        break;
      }
    }

    if (detectedIndex != null) {
      setState(() {
        if (!_selectedLetterIndices.contains(detectedIndex)) {
          _selectedLetterIndices.add(detectedIndex!);
        }

        _currentDraggedWord =
            _selectedLetterIndices
                .map((idx) => _currentLevel.letters[idx])
                .join();
        _dragLineOffsets =
            _selectedLetterIndices
                .map((idx) => _getLetterCenterOffset(idx, wheelSize))
                .toList();
        _dragLineOffsets.add(localPosition);
      });
    } else {
      setState(() {
        if (_selectedLetterIndices.isNotEmpty) {
          _dragLineOffsets =
              _selectedLetterIndices
                  .map((idx) => _getLetterCenterOffset(idx, wheelSize))
                  .toList();
          _dragLineOffsets.add(localPosition);
        }
      });
    }
  }

  void _checkWord() {
    if (_currentDraggedWord.isEmpty) return;

    final targetWord = _currentLevel.words[_currentWordIndex].text;

    if (targetWord == _currentDraggedWord) {
      setState(() {
        _currentLevel.words[_currentWordIndex].isFound = true;
        _score += 10;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🎉 Awesome! You found \"$_currentDraggedWord\"! +10 points",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 1),
        ),
      );

      if (_currentWordIndex < _currentLevel.words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
      } else {
        _confettiController.play();
        _showLevelCompletionDialog();

        Future.delayed(const Duration(seconds: 3), () {
          _loadLevel(_currentLevelIndex + 1);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🤔 \"$_currentDraggedWord\" isn't right. Try again!",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showLevelCompletionDialog() {
    final nextLevelIndex = _currentLevelIndex + 1;
    String nextLevelCategory = "Finished!";

    if (nextLevelIndex < GameData.allLevels.length) {
      nextLevelCategory = GameData.allLevels[nextLevelIndex].category;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: LevelCompleteDialog(
            currentLevelIndex: _currentLevelIndex,
            nextLevelCategory: nextLevelCategory,
            score: _score,
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showOverallCompletionDialog() {
    _addToLeaderboard();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.amber.shade50,
          title: const Text(
            "🏆 CONGRATULATIONS! 🏆",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "You completed all science challenges!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Final Score: $_score points! 🌟",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text(
                "View Leaderboard",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  showLeaderboard = true;
                });
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Play Again",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _score = 0;
                });
                _loadLevel(0);
              },
            ),
          ],
        );
      },
    );
  }

  void _addToLeaderboard() {
    leaderboard.add(
      LeaderboardEntry(
        playerName: widget.role,
        score: _score,
        date: DateTime.now(),
      ),
    );
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 10) {
      leaderboard = leaderboard.sublist(0, 10);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (showLeaderboard) {
      return _buildLeaderboard();
    }

    final currentWord = _currentLevel.words[_currentWordIndex];
    final foundWordsCountInLevel = _currentWordIndex;
    final totalWordsInLevel = _currentLevel.words.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade700,
                  Colors.blue.shade600,
                  Colors.cyan.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: StarPainter())),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentLevel.category,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellowAccent,
                            ),
                          ),
                          Text(
                            "Level ${_currentLevelIndex + 1} • Word ${foundWordsCountInLevel + 1}/$totalWordsInLevel",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Mute/Unmute Button (New)
                          IconButton(
                            icon: Icon(
                              AudioService.isMuted
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () async {
                              await AudioService.toggleMute();
                              setState(() {}); // Refresh UI to update icon
                            },
                            tooltip:
                                AudioService.isMuted
                                    ? "Unmute Music"
                                    : "Mute Music",
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.yellowAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$_score",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.leaderboard,
                              color: Colors.yellowAccent,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                showLeaderboard = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: LinearProgressIndicator(
                    value: foundWordsCountInLevel / totalWordsInLevel,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "🔍 SCIENCE CLUE",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            currentWord.hint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                currentWord.text.split('').map((letter) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Container(
                                      width: 28,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child:
                                          currentWord.isFound
                                              ? Text(
                                                letter,
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  height: 70,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.cyan.shade50],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    _currentDraggedWord.isEmpty
                        ? "Connect the letters!"
                        : _currentDraggedWord,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        key: _letterWheelKey,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.blue.shade400.withOpacity(0.3),
                              Colors.purple.shade600.withOpacity(0.3),
                            ],
                          ),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double wheelRadius = constraints.maxWidth / 2;
                            final letterCount = _currentLevel.letters.length;
                            double sizeFactor =
                                letterCount > 7
                                    ? 0.6
                                    : letterCount < 6
                                    ? 0.8
                                    : 0.7;
                            final double letterButtonSize =
                                wheelRadius * sizeFactor / 1.5;

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_letterButtonSize == null ||
                                  _letterButtonSize!.width !=
                                      letterButtonSize) {
                                setState(() {
                                  _letterButtonSize = Size(
                                    letterButtonSize,
                                    letterButtonSize,
                                  );
                                });
                              }
                            });

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DragLinePainter(
                                      _dragLineOffsets,
                                      Colors.yellowAccent,
                                      letterButtonSize / 3,
                                    ),
                                  ),
                                ),
                                ...List.generate(_currentLevel.letters.length, (
                                  index,
                                ) {
                                  final center = _getLetterCenterOffset(
                                    index,
                                    constraints.biggest,
                                  );
                                  final x = center.dx - (letterButtonSize / 2);
                                  final y = center.dy - (letterButtonSize / 2);
                                  final bool isSelected = _selectedLetterIndices
                                      .contains(index);

                                  return Positioned(
                                    left: x,
                                    top: y,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: letterButtonSize,
                                      height: letterButtonSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient:
                                            isSelected
                                                ? LinearGradient(
                                                  colors: [
                                                    Colors.amber,
                                                    Colors.orange.shade400,
                                                  ],
                                                )
                                                : LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.cyan.shade50,
                                                  ],
                                                ),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.deepOrange
                                                  : Colors.grey.shade300,
                                          width: isSelected ? 4 : 2,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: Colors.amber
                                                        .withOpacity(0.8),
                                                    blurRadius: 15,
                                                  ),
                                                ]
                                                : [
                                                  const BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        _currentLevel.letters[index],
                                        style: TextStyle(
                                          fontSize: letterButtonSize * 0.5,
                                          fontWeight: FontWeight.w900,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.purple.shade700,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.03,
              numberOfParticles: 50,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
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
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              showLeaderboard = false;
            });
          },
        ),
        title: const Text(
          "🏆 Science Champions",
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade700,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
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
                        "No champions yet!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Complete all levels to join the board!",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              index < 3
                                  ? [
                                    Colors.amber.shade300.withOpacity(0.4),
                                    Colors.orange.shade400.withOpacity(0.4),
                                  ]
                                  : [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 36)),
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
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  _formatDate(entry.date),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "${entry.score}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
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
}

class LevelCompleteDialog extends StatelessWidget {
  final int currentLevelIndex;
  final String nextLevelCategory;
  final int score;

  const LevelCompleteDialog({
    super.key,
    required this.currentLevelIndex,
    required this.nextLevelCategory,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 20,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 60)),
            const SizedBox(height: 10),
            Text(
              "Level ${currentLevelIndex + 1} Complete!",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Score: $score points! 🌟",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Text(
                "Next: $nextLevelCategory",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Loading next level...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: const LinearProgressIndicator(
                  value: null,
                  backgroundColor: Colors.purple,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DragLinePainter extends CustomPainter {
  final List<Offset> offsets;
  final Color color;
  final double strokeWidth;

  DragLinePainter(this.offsets, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.length < 2) return;

    final paint =
        Paint()
          ..color = color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final path = Path();
    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DragLinePainter oldDelegate) {
    return oldDelegate.offsets != offsets || oldDelegate.color != color;
  }
}

class StarPainter extends CustomPainter {
  final Random _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white54;
    const int numberOfStars = 100;

    for (int i = 0; i < numberOfStars; i++) {
      final double x = _random.nextDouble() * size.width;
      final double y = _random.nextDouble() * size.height;
      final double radius = 0.5 + _random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
