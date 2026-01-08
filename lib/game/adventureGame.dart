import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// =============== PHOTOSYNTHESIS GAME ===============
class PhotosynthesisFactory extends StatefulWidget {
  final String role;
  const PhotosynthesisFactory({super.key, required this.role});

  @override
  State<PhotosynthesisFactory> createState() => _PhotosynthesisFactoryState();
}

enum GameStage { menu, tutorial, playing, quiz, complete, leaderboard }

class Ingredient {
  double x;
  double y;
  String type; // "co2", "water", "sunlight"
  bool collected = false;

  Ingredient(this.x, this.y, this.type);
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final int level;
  final DateTime date;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.level,
    required this.date,
  });
}

class _PhotosynthesisFactoryState extends State<PhotosynthesisFactory> {
  GameStage stage = GameStage.menu;
  int level = 1;
  int score = 0;
  int co2Count = 0;
  int waterCount = 0;
  int sunlightCount = 0;
  int oxygenProduced = 0;
  int glucoseProduced = 0;

  Timer? gameTimer;
  Timer? spawnTimer;
  int timeRemaining = 60;

  List<Ingredient> ingredients = [];
  double plantX = 0;
  bool isProcessing = false;

  List<LeaderboardEntry> leaderboard = [];

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      stage = GameStage.playing;
      level = 1;
      score = 0;
      _resetIngredients();
      _startLevel();
    });
  }

  void _startLevel() {
    timeRemaining = max(40, 60 - (level - 1) * 5);
    ingredients.clear();
    _resetIngredients();

    spawnTimer = Timer.periodic(
      Duration(milliseconds: max(800, 1500 - level * 100)),
      (timer) {
        _spawnIngredient();
      },
    );

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeRemaining--;
        if (timeRemaining <= 0) {
          _checkLevelComplete();
        }
      });
    });
  }

  void _resetIngredients() {
    setState(() {
      co2Count = 0;
      waterCount = 0;
      sunlightCount = 0;
    });
  }

  void _spawnIngredient() {
    final types = ["co2", "water", "sunlight"];
    final type = types[Random().nextInt(types.length)];
    final x = Random().nextDouble() * 2 - 1;

    setState(() {
      ingredients.add(Ingredient(x, -0.1, type));
    });
  }

  void _updateGame() {
    setState(() {
      // Move ingredients down
      for (var ingredient in ingredients) {
        ingredient.y += 0.01 * (1 + level * 0.1);
      }

      // Remove off-screen ingredients
      ingredients.removeWhere((i) => i.y > 1.2);

      // Check collisions
      for (var ingredient in List<Ingredient>.from(ingredients)) {
        if (_checkCollision(ingredient) && !ingredient.collected) {
          ingredient.collected = true;
          _collectIngredient(ingredient.type);
          ingredients.remove(ingredient);
        }
      }
    });
  }

  bool _checkCollision(Ingredient ingredient) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final plantPos = Offset((plantX + 1) / 2 * width, height - 120);
    final ingredientPos = Offset(
      (ingredient.x + 1) / 2 * width,
      ingredient.y * height,
    );

    return (plantPos - ingredientPos).distance < 60;
  }

  void _collectIngredient(String type) {
    setState(() {
      switch (type) {
        case "co2":
          co2Count++;
          break;
        case "water":
          waterCount++;
          break;
        case "sunlight":
          sunlightCount++;
          break;
      }
      score += 5;
    });
  }

  void _photosynthesize() {
    if (co2Count >= 6 && waterCount >= 6 && sunlightCount >= 1) {
      setState(() {
        co2Count -= 6;
        waterCount -= 6;
        sunlightCount -= 1;
        oxygenProduced += 6;
        glucoseProduced += 1;
        score += 50 * level;
        isProcessing = true;
      });

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          isProcessing = false;
        });
      });
    } else {
      _showMessage("❌ Not enough! Need: 6 CO₂, 6 H₂O, 1 Sunlight", Colors.red);
    }
  }

  void _checkLevelComplete() {
    gameTimer?.cancel();
    spawnTimer?.cancel();

    if (glucoseProduced >= level * 3) {
      setState(() {
        stage = GameStage.quiz;
      });
    } else {
      _showMessage("⏰ Time's up! Try again!", Colors.orange);
      Future.delayed(const Duration(seconds: 2), () {
        _startLevel();
      });
    }
  }

  void _answerQuiz(bool correct) {
    if (correct) {
      score += 100;
      if (level < 5) {
        setState(() {
          level++;
          oxygenProduced = 0;
          glucoseProduced = 0;
          stage = GameStage.playing;
        });
        _startLevel();
      } else {
        _gameComplete();
      }
    } else {
      score -= 20;
      setState(() {
        stage = GameStage.playing;
      });
      _startLevel();
    }
  }

  void _gameComplete() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    _addToLeaderboard();
    setState(() {
      stage = GameStage.complete;
    });
  }

  void _addToLeaderboard() {
    leaderboard.add(
      LeaderboardEntry(
        playerName: widget.role,
        score: score,
        level: level,
        date: DateTime.now(),
      ),
    );
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    if (leaderboard.length > 10) {
      leaderboard = leaderboard.sublist(0, 10);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (stage) {
          GameStage.menu => _buildMenu(),
          GameStage.tutorial => _buildTutorial(),
          GameStage.playing => _buildGameScreen(),
          GameStage.quiz => _buildQuiz(),
          GameStage.complete => _buildComplete(),
          GameStage.leaderboard => _buildLeaderboard(),
        },
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🌱", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              "Photosynthesis Factory",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Learn How Plants Make Food!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 50),
            _MenuButton(
              icon: Icons.play_arrow,
              label: "Start Learning",
              color: Colors.green.shade700,
              onPressed: () => setState(() => stage = GameStage.tutorial),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.leaderboard,
              label: "Leaderboard",
              color: Colors.orange.shade700,
              onPressed: () => setState(() => stage = GameStage.leaderboard),
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.exit_to_app,
              label: "Exit",
              color: Colors.red.shade700,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorial() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🎓 How Photosynthesis Works",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _TutorialCard(
                emoji: "☀️",
                title: "Sunlight",
                description: "Plants capture energy from the sun",
                color: Colors.amber,
              ),
              _TutorialCard(
                emoji: "💧",
                title: "Water (H₂O)",
                description: "Plants absorb water through roots",
                color: Colors.blue,
              ),
              _TutorialCard(
                emoji: "💨",
                title: "Carbon Dioxide (CO₂)",
                description: "Plants take in CO₂ from the air",
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Column(
                  children: [
                    Text(
                      "⚡ Photosynthesis Equation",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "6CO₂ + 6H₂O + Sunlight\n→ C₆H₁₂O₆ (Glucose) + 6O₂",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                label: const Text(
                  "Start Factory!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    // Start update loop
    if (gameTimer?.isActive ?? false) {
      Future.microtask(() => _updateGame());
    }

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          plantX = (plantX + details.delta.dx / width * 2).clamp(-0.9, 0.9);
        });
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF90EE90)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Falling ingredients
            ...ingredients.map(
              (ingredient) => Positioned(
                left: (ingredient.x + 1) / 2 * width - 30,
                top: ingredient.y * height,
                child: _IngredientWidget(type: ingredient.type),
              ),
            ),

            // Plant
            Positioned(
              bottom: 50,
              left: (plantX + 1) / 2 * width - 50,
              child: Column(
                children: [
                  if (isProcessing)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellowAccent.withOpacity(0.3),
                      ),
                      child: const Center(
                        child: Text("⚡", style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Colors.lightGreen, Colors.green],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("🌿", style: TextStyle(fontSize: 60)),
                    ),
                  ),
                ],
              ),
            ),

            // HUD
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(
                          icon: "⏱️",
                          value: "$timeRemaining s",
                          color: timeRemaining <= 10 ? Colors.red : Colors.blue,
                        ),
                        _StatCard(
                          icon: "⭐",
                          value: "$score",
                          color: Colors.amber,
                        ),
                        _StatCard(
                          icon: "🎯",
                          value: "Level $level",
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _IngredientCount(
                                emoji: "💨",
                                count: co2Count,
                                needed: 6,
                              ),
                              _IngredientCount(
                                emoji: "💧",
                                count: waterCount,
                                needed: 6,
                              ),
                              _IngredientCount(
                                emoji: "☀️",
                                count: sunlightCount,
                                needed: 1,
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ProductCount(
                                emoji: "🍬",
                                label: "Glucose",
                                count: glucoseProduced,
                                goal: level * 3,
                              ),
                              _ProductCount(
                                emoji: "🫧",
                                label: "Oxygen",
                                count: oxygenProduced,
                                goal: 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Photosynthesize button
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _photosynthesize,
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 32,
                  ),
                  label: const Text(
                    "PHOTOSYNTHESIZE!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final quizzes = [
      {
        "q": "What gas do plants take in during photosynthesis?",
        "opts": ["Oxygen", "Carbon Dioxide", "Nitrogen", "Hydrogen"],
        "ans": "Carbon Dioxide",
      },
      {
        "q": "What is the main product of photosynthesis?",
        "opts": ["Water", "Oxygen", "Glucose", "Carbon Dioxide"],
        "ans": "Glucose",
      },
      {
        "q": "Where does photosynthesis occur in plant cells?",
        "opts": ["Nucleus", "Mitochondria", "Chloroplast", "Ribosome"],
        "ans": "Chloroplast",
      },
      {
        "q": "What gives plants their green color?",
        "opts": ["Chlorophyll", "Carotene", "Xanthophyll", "Anthocyanin"],
        "ans": "Chlorophyll",
      },
      {
        "q": "What gas is released during photosynthesis?",
        "opts": ["Carbon Dioxide", "Nitrogen", "Oxygen", "Methane"],
        "ans": "Oxygen",
      },
    ];

    final quiz = quizzes[level - 1];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🧪 Science Quiz!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  quiz["q"] as String,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ...(quiz["opts"] as List<String>).map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      final correct = opt == quiz["ans"];
                      _showMessage(
                        correct
                            ? "✅ Correct! +100 points"
                            : "❌ Wrong! Try again",
                        correct ? Colors.green : Colors.red,
                      );
                      Future.delayed(const Duration(seconds: 1), () {
                        _answerQuiz(correct);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildComplete() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🏆", style: TextStyle(fontSize: 100)),
            const SizedBox(height: 20),
            const Text(
              "Photosynthesis Master!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Final Score: $score",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Level Completed: $level",
                    style: const TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  stage = GameStage.leaderboard;
                });
              },
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text(
                "View Leaderboard",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Play Again",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          stage = GameStage.menu;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        "🏆 Top Scientists",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child:
                    leaderboard.isEmpty
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 100,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "No scientists yet!",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Complete the game to join!",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      index < 3
                                          ? [
                                            Colors.amber.withOpacity(0.3),
                                            Colors.orange.withOpacity(0.2),
                                          ]
                                          : [
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      index < 3 ? Colors.amber : Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    medal,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.playerName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Level ${entry.level} • ${_formatDate(entry.date)}",
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 14,
                                          ),
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
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.green,
                                          Colors.lightGreen,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${entry.score}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============== HELPER WIDGETS ===============
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 28),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;

  const _TutorialCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientWidget extends StatelessWidget {
  final String type;

  const _IngredientWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    final data = switch (type) {
      "co2" => {"emoji": "💨", "color": Colors.grey},
      "water" => {"emoji": "💧", "color": Colors.blue},
      "sunlight" => {"emoji": "☀️", "color": Colors.amber},
      _ => {"emoji": "?", "color": Colors.white},
    };

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: data["color"] as Color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (data["color"] as Color).withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          data["emoji"] as String,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientCount extends StatelessWidget {
  final String emoji;
  final int count;
  final int needed;

  const _IngredientCount({
    required this.emoji,
    required this.count,
    required this.needed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        Text(
          "$count/$needed",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: count >= needed ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}

class _ProductCount extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final int goal;

  const _ProductCount({
    required this.emoji,
    required this.label,
    required this.count,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          goal > 0 ? "$count/$goal" : "$count",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
