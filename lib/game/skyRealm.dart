import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// =============== MAIN WRAPPER ===============
class AstronomySkyRealm extends StatelessWidget {
  final String role;
  const AstronomySkyRealm({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return GameFlow(playerName: role);
  }
}

// =============== GAME STAGES ===============
enum GameStage { menu, playing, stageClear, gameOver, leaderboard }

// =============== POWER-UP TYPES ===============
enum PowerUpType { shield, rapid, triple, slow }

class PowerUp {
  double x;
  double y;
  PowerUpType type;
  PowerUp(this.x, this.y, this.type);
}

class Meteor {
  double x;
  double y;
  double size;
  Meteor(this.x, this.y, this.size);
}

class Bullet {
  double x;
  double y;
  Bullet(this.x, this.y);
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

// =============== MAIN GAME FLOW ===============
class GameFlow extends StatefulWidget {
  final String playerName;
  const GameFlow({super.key, required this.playerName});

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  GameStage stage = GameStage.menu;
  int lives = 3;
  int level = 1;
  int score = 0;
  List<LeaderboardEntry> leaderboard = [];

  void _startGame() {
    setState(() {
      stage = GameStage.playing;
      lives = 3;
      level = 1;
      score = 0;
    });
  }

  void _addScore(int points) {
    setState(() {
      score += points;
    });
  }

  void _loseLife() {
    setState(() {
      lives--;
      if (lives <= 0) {
        _gameOver();
      }
    });
  }

  void _stageClear() {
    setState(() {
      stage = GameStage.stageClear;
    });
  }

  void _nextLevel() {
    setState(() {
      level++;
      if (level > 5) {
        _gameOver();
      } else {
        stage = GameStage.playing;
      }
    });
  }

  void _gameOver() {
    _addToLeaderboard();
    setState(() {
      stage = GameStage.gameOver;
    });
  }

  void _addToLeaderboard() {
    leaderboard.add(
      LeaderboardEntry(
        playerName: widget.playerName,
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

  void _showLeaderboard() {
    setState(() {
      stage = GameStage.leaderboard;
    });
  }

  void _backToMenu() {
    setState(() {
      stage = GameStage.menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (stage) {
          GameStage.menu => MenuScreen(
            key: const ValueKey("menu"),
            onStart: _startGame,
            onLeaderboard: _showLeaderboard,
            onExit: () => Navigator.pop(context),
          ),
          GameStage.playing => SpaceGameScreen(
            key: ValueKey("playing$level"),
            level: level,
            lives: lives,
            currentScore: score,
            onScoreChange: _addScore,
            onLifeLost: _loseLife,
            onStageClear: _stageClear,
          ),
          GameStage.stageClear => StageClearScreen(
            key: const ValueKey("clear"),
            level: level,
            score: score,
            onNext: _nextLevel,
          ),
          GameStage.gameOver => GameOverScreen(
            key: const ValueKey("over"),
            score: score,
            level: level,
            onPlayAgain: _startGame,
            onMenu: _backToMenu,
          ),
          GameStage.leaderboard => LeaderboardScreen(
            key: const ValueKey("leaderboard"),
            entries: leaderboard,
            onBack: _backToMenu,
          ),
        },
      ),
    );
  }
}

// =============== MENU SCREEN ===============
class MenuScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLeaderboard;
  final VoidCallback onExit;

  const MenuScreen({
    super.key,
    required this.onStart,
    required this.onLeaderboard,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F), Color(0xFF2D3561)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🚀", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              "Space Adventure",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
                shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Learn & Defend the Galaxy!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 50),
            _MenuButton(
              icon: Icons.play_arrow,
              label: "Start Mission",
              color: Colors.green,
              onPressed: onStart,
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.leaderboard,
              label: "Leaderboard",
              color: Colors.orange,
              onPressed: onLeaderboard,
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.exit_to_app,
              label: "Exit",
              color: Colors.red,
              onPressed: onExit,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text(
                    "🎮 How to Play:",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Drag rocket left/right to move\n• Tap screen to shoot meteors\n• Collect power-ups (⭐)\n• Answer quiz questions correctly\n• Avoid red meteors ☄️",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

// =============== MAIN GAME SCREEN ===============
class SpaceGameScreen extends StatefulWidget {
  final int level;
  final int lives;
  final int currentScore;
  final Function(int) onScoreChange;
  final VoidCallback onLifeLost;
  final VoidCallback onStageClear;

  const SpaceGameScreen({
    super.key,
    required this.level,
    required this.lives,
    required this.currentScore,
    required this.onScoreChange,
    required this.onLifeLost,
    required this.onStageClear,
  });

  @override
  State<SpaceGameScreen> createState() => _SpaceGameScreenState();
}

class _SpaceGameScreenState extends State<SpaceGameScreen> {
  double rocketX = 0;
  List<Meteor> meteors = [];
  List<PowerUp> powerUps = [];
  List<Bullet> bullets = [];

  Timer? gameLoop;
  Timer? countdownTimer;
  int timeLeft = 45;
  bool paused = false;

  // Power-up states
  bool hasShield = false;
  bool rapidFire = false;
  bool tripleFire = false;
  bool slowMotion = false;
  int canShoot = 0;

  // Difficulty
  double meteorSpeed = 0.015;
  double powerUpSpeed = 0.012;
  double bulletSpeed = 0.025;

  @override
  void initState() {
    super.initState();
    meteorSpeed += 0.005 * (widget.level - 1);
    powerUpSpeed += 0.003 * (widget.level - 1);
    timeLeft = max(30, 50 - (widget.level - 1) * 5);
    _startGame();
  }

  void _startGame() {
    meteors.clear();
    powerUps.clear();
    bullets.clear();

    gameLoop = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (paused) return;
      setState(() {
        // Update meteors
        final speed = slowMotion ? meteorSpeed * 0.5 : meteorSpeed;
        for (var meteor in meteors) {
          meteor.y += speed;
        }
        meteors.removeWhere((m) => m.y > 1.2);

        // Update power-ups
        for (var p in powerUps) {
          p.y += powerUpSpeed;
        }
        powerUps.removeWhere((p) => p.y > 1.2);

        // Update bullets
        for (var bullet in bullets) {
          bullet.y -= bulletSpeed;
        }
        bullets.removeWhere((b) => b.y < -0.2);

        // Bullet-Meteor collisions
        for (var bullet in List<Bullet>.from(bullets)) {
          for (var meteor in List<Meteor>.from(meteors)) {
            if (_bulletHitsMeteor(bullet, meteor)) {
              bullets.remove(bullet);
              meteors.remove(meteor);
              widget.onScoreChange(10 * widget.level);
              break;
            }
          }
        }

        // Rocket-Meteor collisions
        for (var meteor in List<Meteor>.from(meteors)) {
          if (_rocketHitsMeteor(meteor)) {
            meteors.remove(meteor);
            if (hasShield) {
              hasShield = false;
            } else {
              widget.onLifeLost();
            }
            break;
          }
        }

        // Collect power-ups
        for (var p in List<PowerUp>.from(powerUps)) {
          if (_rocketHitsPowerUp(p)) {
            powerUps.remove(p);
            _collectPowerUp(p.type);
            break;
          }
        }

        // Spawn meteors
        if (Random().nextDouble() < 0.03 + (widget.level * 0.01)) {
          final size = 35.0 + Random().nextDouble() * 25;
          meteors.add(Meteor(Random().nextDouble() * 2 - 1, -0.1, size));
        }

        // Spawn power-ups
        if (Random().nextDouble() < 0.008) {
          final types = PowerUpType.values;
          powerUps.add(
            PowerUp(
              Random().nextDouble() * 2 - 1,
              -0.1,
              types[Random().nextInt(types.length)],
            ),
          );
        }

        if (canShoot > 0) canShoot--;
      });
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (paused) return;
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          _winStage();
        }
      });
    });
  }

  void _collectPowerUp(PowerUpType type) {
    setState(() {
      switch (type) {
        case PowerUpType.shield:
          hasShield = true;
          break;
        case PowerUpType.rapid:
          rapidFire = true;
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) setState(() => rapidFire = false);
          });
          break;
        case PowerUpType.triple:
          tripleFire = true;
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) setState(() => tripleFire = false);
          });
          break;
        case PowerUpType.slow:
          slowMotion = true;
          Future.delayed(const Duration(seconds: 7), () {
            if (mounted) setState(() => slowMotion = false);
          });
          break;
      }
    });

    // Show quiz for extra points
    _showQuiz();
  }

  void _showQuiz() {
    paused = true;
    final quiz = quizPool[Random().nextInt(quizPool.length)];
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (_) => QuizScreen(
              question: quiz["q"]!,
              options: quiz["opts"]!,
              correctAnswer: quiz["ans"]!,
              onAnswer: (correct) {
                if (correct) {
                  widget.onScoreChange(50 * widget.level);
                }
                setState(() => paused = false);
              },
            ),
      ),
    );
  }

  void _shoot() {
    if (canShoot > 0 && !rapidFire) return;

    setState(() {
      if (tripleFire) {
        bullets.add(Bullet(rocketX - 0.1, 0.85));
        bullets.add(Bullet(rocketX, 0.85));
        bullets.add(Bullet(rocketX + 0.1, 0.85));
      } else {
        bullets.add(Bullet(rocketX, 0.85));
      }
      canShoot = rapidFire ? 2 : 5;
    });
  }

  bool _bulletHitsMeteor(Bullet bullet, Meteor meteor) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final bulletPos = Offset((bullet.x + 1) / 2 * width, bullet.y * height);
    final meteorPos = Offset((meteor.x + 1) / 2 * width, meteor.y * height);

    return (bulletPos - meteorPos).distance < meteor.size / 2 + 10;
  }

  bool _rocketHitsMeteor(Meteor meteor) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final rocketPos = Offset((rocketX + 1) / 2 * width, height - 80);
    final meteorPos = Offset((meteor.x + 1) / 2 * width, meteor.y * height);

    return (rocketPos - meteorPos).distance < meteor.size / 2 + 30;
  }

  bool _rocketHitsPowerUp(PowerUp p) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final rocketPos = Offset((rocketX + 1) / 2 * width, height - 80);
    final powerUpPos = Offset((p.x + 1) / 2 * width, p.y * height);

    return (rocketPos - powerUpPos).distance < 40;
  }

  void _winStage() {
    gameLoop?.cancel();
    countdownTimer?.cancel();
    widget.onStageClear();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          rocketX = (rocketX + details.delta.dx / width * 2).clamp(-0.95, 0.95);
        });
      },
      onTapDown: (_) => _shoot(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F), Color(0xFF2D3561)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Stars background
            ...List.generate(50, (i) {
              final random = Random(i);
              return Positioned(
                left: random.nextDouble() * width,
                top: random.nextDouble() * height,
                child: Container(
                  width: 2 + random.nextDouble() * 2,
                  height: 2 + random.nextDouble() * 2,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

            // Meteors
            ...meteors.map(
              (m) => Positioned(
                left: (m.x + 1) / 2 * width - m.size / 2,
                top: m.y * height,
                child: Container(
                  width: m.size,
                  height: m.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.red.shade300, Colors.red.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text("☄️", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            ),

            // Power-ups
            ...powerUps.map(
              (p) => Positioned(
                left: (p.x + 1) / 2 * width - 25,
                top: p.y * height,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.yellow.shade200, Colors.orange.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getPowerUpIcon(p.type),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),

            // Bullets
            ...bullets.map(
              (b) => Positioned(
                left: (b.x + 1) / 2 * width - 5,
                top: b.y * height,
                child: Container(
                  width: 10,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Rocket
            Positioned(
              bottom: 50,
              left: (rocketX + 1) / 2 * width - 35,
              child: Column(
                children: [
                  if (hasShield)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.lightBlueAccent,
                          width: 3,
                        ),
                        color: Colors.lightBlueAccent.withOpacity(0.2),
                      ),
                    ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade300, Colors.red.shade400],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.6),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("🚀", style: TextStyle(fontSize: 40)),
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lives
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: List.generate(
                              widget.lives,
                              (i) => const Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 28,
                              ),
                            ),
                          ),
                        ),

                        // Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                timeLeft <= 10
                                    ? Colors.red.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  timeLeft <= 10
                                      ? Colors.red
                                      : Colors.cyanAccent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$timeLeft s",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Score
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.currentScore}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Level & Power-ups
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Level ${widget.level}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (rapidFire)
                              _PowerUpIndicator(
                                icon: "⚡",
                                color: Colors.yellow,
                              ),
                            if (tripleFire)
                              _PowerUpIndicator(
                                icon: "3️⃣",
                                color: Colors.blue,
                              ),
                            if (slowMotion)
                              _PowerUpIndicator(
                                icon: "🐌",
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ],
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

  String _getPowerUpIcon(PowerUpType type) {
    return switch (type) {
      PowerUpType.shield => "🛡️",
      PowerUpType.rapid => "⚡",
      PowerUpType.triple => "3️⃣",
      PowerUpType.slow => "🐌",
    };
  }
}

class _PowerUpIndicator extends StatelessWidget {
  final String icon;
  final Color color;

  const _PowerUpIndicator({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 20)),
    );
  }
}

// =============== QUIZ SCREEN ===============
class QuizScreen extends StatelessWidget {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final Function(bool) onAnswer;

  const QuizScreen({
    super.key,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F)],
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
                  "🌟 SPACE QUIZ 🌟",
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                  ),
                  child: Text(
                    question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ...options.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        final correct = opt == correctAnswer;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              correct
                                  ? "✅ Correct! +50 bonus points!"
                                  : "❌ Wrong! The answer was: $correctAnswer",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                correct ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Future.delayed(const Duration(milliseconds: 500), () {
                          Navigator.pop(context);
                          onAnswer(correct);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        opt,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============== STAGE CLEAR SCREEN ===============
class StageClearScreen extends StatelessWidget {
  final int level;
  final int score;
  final VoidCallback onNext;

  const StageClearScreen({
    super.key,
    required this.level,
    required this.score,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              "Level $level Complete!",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Score: $score",
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                "Next Level",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== GAME OVER SCREEN ===============
class GameOverScreen extends StatelessWidget {
  final int score;
  final int level;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.level,
    required this.onPlayAgain,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🏆", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              level > 5 ? "Mission Complete!" : "Game Over",
              style: TextStyle(
                color: level > 5 ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Final Score: $score",
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Reached Level: $level",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Play Again",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onMenu,
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                "Main Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== LEADERBOARD SCREEN ===============
class LeaderboardScreen extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final VoidCallback onBack;

  const LeaderboardScreen({
    super.key,
    required this.entries,
    required this.onBack,
  });

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F4F), Color(0xFF2D3561)],
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
                    onPressed: onBack,
                  ),
                  const Expanded(
                    child: Text(
                      "🏆 Hall of Fame",
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
                  entries.isEmpty
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
                              "No records yet!",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Be the first space explorer!",
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
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
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
                                        Colors.purple,
                                        Colors.deepPurple,
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
    );
  }
}

// =============== QUIZ POOL ===============
final List<Map<String, dynamic>> quizPool = [
  {
    "q": "Which planet is known as the Red Planet?",
    "opts": ["Venus", "Mars", "Jupiter", "Mercury"],
    "ans": "Mars",
  },
  {
    "q": "What is the largest planet in our solar system?",
    "opts": ["Saturn", "Earth", "Jupiter", "Neptune"],
    "ans": "Jupiter",
  },
  {
    "q": "Which planet has the most moons?",
    "opts": ["Mars", "Saturn", "Jupiter", "Uranus"],
    "ans": "Saturn",
  },
  {
    "q": "What is the Sun mainly made of?",
    "opts": ["Oxygen", "Hydrogen", "Iron", "Carbon"],
    "ans": "Hydrogen",
  },
  {
    "q": "Which planet is closest to the Sun?",
    "opts": ["Venus", "Earth", "Mercury", "Mars"],
    "ans": "Mercury",
  },
  {
    "q": "What is the name of Earth's natural satellite?",
    "opts": ["Titan", "Moon", "Europa", "Phobos"],
    "ans": "Moon",
  },
  {
    "q": "Which planet has beautiful rings around it?",
    "opts": ["Jupiter", "Saturn", "Uranus", "Neptune"],
    "ans": "Saturn",
  },
  {
    "q": "How many planets are in our solar system?",
    "opts": ["7", "8", "9", "10"],
    "ans": "8",
  },
  {
    "q": "What is the hottest planet in our solar system?",
    "opts": ["Mercury", "Venus", "Mars", "Jupiter"],
    "ans": "Venus",
  },
  {
    "q": "What do we call a large group of stars?",
    "opts": ["Asteroid", "Comet", "Galaxy", "Nebula"],
    "ans": "Galaxy",
  },
  {
    "q": "Which planet is known as the 'Blue Planet'?",
    "opts": ["Neptune", "Uranus", "Earth", "Venus"],
    "ans": "Earth",
  },
  {
    "q": "What is a shooting star actually?",
    "opts": ["A falling star", "A meteor", "A comet", "A planet"],
    "ans": "A meteor",
  },
];
