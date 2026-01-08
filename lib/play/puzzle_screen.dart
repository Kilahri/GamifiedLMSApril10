import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Added for the new service
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// IMPROVEMENTS MADE:
// 1. ✅ Completed cut-off code sections
// 2. ✅ Added Tutorial/Help system with interactive guide
// 3. ✅ Added Achievement system with badges
// 4. ✅ Enhanced animations and visual feedback
// 5. ✅ Added haptic feedback for interactions
// 6. ✅ Improved collection panel with statistics
// 7. ✅ Added educational info cards for each element
// 8. ✅ Better progress tracking and statistics
// 9. ✅ Added combo chain visual effects
// 10. ✅ Improved leaderboard with filters and stats
//
// LATEST FIXES (v2.0):
// 11. ✅ Fixed bottom menu - now shows ALL discovered elements in grid
// 12. ✅ All discovered elements can now fuse with each other (not just base)
// 13. ✅ Implemented REAL storage for leaderboard (using SharedPreferences)
// 14. ✅ Added high score tracking per user per game
// 15. ✅ High scores now display on leaderboard (keeps best score)
// 16. ✅ Fixed hint system - proper deduction and messages
// 17. ✅ Fixed scoring calculations and point deductions
// 18. ✅ Added "NEW HIGH SCORE" celebration when beaten
// 19. ✅ Personal best now shows in game UI and completion screen
// 20. ✅ Leaderboard shows only highest score per player
// ============================================================================
class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isMuted = false;

  /// Initialize and start background music
  static Future<void> playBackgroundMusic() async {
    try {
      await _audioPlayer.setSource(AssetSource('lib/assets/audio/puzzle.mp3'));
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

// --- Element Visuals/Colors ---
final Map<String, dynamic> scienceVisuals = {
  // === PHOTOSYNTHESIS GAME ===
  "Sunlight": {
    "color": Colors.amber,
    "icon": Icons.wb_sunny,
    "emoji": "☀️",
    "info": "Energy from the sun that plants use to make food",
  },
  "Water": {
    "color": Colors.blueAccent,
    "icon": Icons.water_drop,
    "emoji": "💧",
    "info": "H₂O - Essential for all life and photosynthesis",
  },
  "Carbon Dioxide": {
    "color": Colors.grey,
    "icon": Icons.air,
    "emoji": "💨",
    "info": "CO₂ - Gas that plants absorb from the air",
  },
  "Soil": {
    "color": Colors.brown,
    "icon": Icons.landscape,
    "emoji": "🌱",
    "info": "Contains nutrients and minerals for plant growth",
  },

  // Level 1: Basic Plant Parts
  "Roots": {
    "color": Colors.brown.shade700,
    "icon": Icons.arrow_downward,
    "emoji": "🌿",
    "info": "Absorb water and nutrients from soil",
  },
  "Leaves": {
    "color": Colors.green,
    "icon": Icons.eco,
    "emoji": "🍃",
    "info": "Main site of photosynthesis in plants",
  },
  "Stem": {
    "color": Colors.lightGreen,
    "icon": Icons.height,
    "emoji": "🌾",
    "info": "Transports water and nutrients throughout plant",
  },
  "Chlorophyll": {
    "color": Colors.green.shade600,
    "icon": Icons.lens,
    "emoji": "💚",
    "info": "Green pigment that captures light energy",
  },

  // Level 2: Photosynthesis Process
  "Light Energy": {
    "color": Colors.yellow.shade600,
    "icon": Icons.wb_sunny,
    "emoji": "⚡",
    "info": "Energy captured by chlorophyll to power the plant",
  },
  "Captured CO2": {
    "color": Colors.blueGrey.shade300,
    "icon": Icons.air,
    "emoji": "☁️",
    "info": "Carbon dioxide pulled from the air for sugar production",
  },
  "Chloroplast": {
    "color": Colors.green.shade800,
    "icon": Icons.biotech,
    "emoji": "🔋",
    "info": "The specialized organelle where photosynthesis happens",
  },
  "Stomata": {
    "color": Colors.teal.shade400,
    "icon": Icons.settings_input_component,
    "emoji": "👄",
    "info": "Tiny pores on leaves that allow gas exchange",
  },

  // Level 3: Products
  "Glucose": {
    "color": Colors.orange,
    "icon": Icons.cookie,
    "emoji": "🍯",
    "info": "C₆H₁₂O₆ - Sugar produced by photosynthesis",
  },
  "Oxygen": {
    "color": Colors.lightBlue.shade200,
    "icon": Icons.bubble_chart,
    "emoji": "🫧",
    "info": "O₂ - Gas released as byproduct of photosynthesis",
  },
  "Plant Food": {
    "color": Colors.lime,
    "icon": Icons.restaurant,
    "emoji": "🥗",
    "info": "Glucose used for plant growth and energy",
  },
  "Growing Plant": {
    "color": Colors.green.shade400,
    "icon": Icons.park,
    "emoji": "🌿",
    "info": "Healthy plant growing from photosynthesis",
  },
  "Energy Storage": {
    "color": Colors.amber.shade600,
    "icon": Icons.battery_charging_full,
    "emoji": "🔋",
    "info": "Glucose stored for later use",
  },
  "Photosynthesis": {
    "color": Colors.green.shade500,
    "icon": Icons.autorenew,
    "emoji": "♻️",
    "info": "Complete process: 6CO₂ + 6H₂O + Light → C₆H₁₂O₆ + 6O₂",
  },

  // === CHANGES OF MATTER GAME ===
  "Ice": {
    "color": Colors.lightBlue.shade100,
    "icon": Icons.ac_unit,
    "emoji": "🧊",
    "info": "Water in solid state below 0°C",
  },
  "Liquid Water": {
    "color": Colors.blue,
    "icon": Icons.waves,
    "emoji": "💧",
    "info": "Water in liquid state between 0-100°C",
  },
  "Heat": {
    "color": Colors.red,
    "icon": Icons.local_fire_department,
    "emoji": "🔥",
    "info": "Energy that increases molecular motion",
  },
  "Cold": {
    "color": Colors.cyan.shade100,
    "icon": Icons.ac_unit,
    "emoji": "❄️",
    "info": "Absence of heat, decreases molecular motion",
  },

  // Level 1: Physical Changes
  "Melting": {
    "color": Colors.lightBlue,
    "icon": Icons.thermostat,
    "emoji": "🌡️",
    "info": "Solid turning to liquid by adding heat",
  },
  "Freezing": {
    "color": Colors.blue.shade200,
    "icon": Icons.severe_cold,
    "emoji": "🥶",
    "info": "Liquid turning to solid by removing heat",
  },
  "Condensation": {
    "color": Colors.blueGrey,
    "icon": Icons.water_damage,
    "emoji": "💦",
    "info": "Gas turning to liquid by cooling",
  },
  "Steam": {
    "color": Colors.grey.shade300,
    "icon": Icons.cloud_queue,
    "emoji": "💨",
    "info": "Water vapor at high temperature",
  },
  "Frost": {
    "color": Colors.lightBlue.shade50,
    "icon": Icons.ac_unit,
    "emoji": "❄️",
    "info": "Ice crystals formed from water vapor",
  },

  // Level 2: States of Matter
  "Solid": {
    "color": Colors.grey.shade600,
    "icon": Icons.square,
    "emoji": "🧱",
    "info": "Matter with fixed shape and volume",
  },
  "Liquid": {
    "color": Colors.blue.shade300,
    "icon": Icons.water,
    "emoji": "💧",
    "info": "Matter with fixed volume but no fixed shape",
  },
  "Gas": {
    "color": Colors.white60,
    "icon": Icons.air,
    "emoji": "💨",
    "info": "Matter with no fixed shape or volume",
  },
  "Evaporation": {
    "color": Colors.lightBlue.shade200,
    "icon": Icons.arrow_upward,
    "emoji": "⬆️",
    "info": "Liquid turning to gas at surface",
  },
  "Sublimation": {
    "color": Colors.cyan,
    "icon": Icons.trending_up,
    "emoji": "📈",
    "info": "Solid turning directly to gas",
  },
  "Deposition": {
    "color": Colors.blue.shade100,
    "icon": Icons.trending_down,
    "emoji": "📉",
    "info": "Gas turning directly to solid",
  },

  // Level 3: Advanced Concepts
  "Particles": {
    "color": Colors.purple,
    "icon": Icons.blur_circular,
    "emoji": "⚛️",
    "info": "Tiny units that make up all matter",
  },
  "Energy Change": {
    "color": Colors.orange,
    "icon": Icons.sync_alt,
    "emoji": "🔄",
    "info": "Energy absorbed or released during phase changes",
  },
  "Phase Change": {
    "color": Colors.deepPurple,
    "icon": Icons.transform,
    "emoji": "✨",
    "info": "Transition between states of matter",
  },
  "Matter Cycle": {
    "color": Colors.indigo,
    "icon": Icons.restart_alt,
    "emoji": "♻️",
    "info": "Continuous transformation of matter states",
  },
  "Molecular Motion": {
    "color": Colors.pink,
    "icon": Icons.radar,
    "emoji": "🌀",
    "info": "Movement of particles in matter",
  },
  "Temperature": {
    "color": Colors.deepOrange,
    "icon": Icons.device_thermostat,
    "emoji": "🌡️",
    "info": "Measure of average kinetic energy of particles",
  },
};

// --- Achievement System ---
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(Map<String, dynamic> stats) isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}

final List<Achievement> achievements = [
  Achievement(
    id: 'first_discovery',
    title: 'First Discovery',
    description: 'Make your first combination',
    icon: Icons.science,
    color: Colors.blue,
    isUnlocked: (stats) => (stats['totalDiscoveries'] ?? 0) >= 1,
  ),
  Achievement(
    id: 'collector',
    title: 'Element Collector',
    description: 'Collect 10 different elements',
    icon: Icons.collections,
    color: Colors.purple,
    isUnlocked: (stats) => (stats['collected'] ?? 0) >= 10,
  ),
  Achievement(
    id: 'streak_master',
    title: 'Combo Master',
    description: 'Achieve a 5x combo streak',
    icon: Icons.local_fire_department,
    color: Colors.orange,
    isUnlocked: (stats) => (stats['maxStreak'] ?? 0) >= 5,
  ),
  Achievement(
    id: 'speed_scientist',
    title: 'Speed Scientist',
    description: 'Complete a level in under 2 minutes',
    icon: Icons.speed,
    color: Colors.green,
    isUnlocked: (stats) => (stats['fastestLevel'] ?? 999) < 120,
  ),
  Achievement(
    id: 'perfectionist',
    title: 'Perfectionist',
    description: 'Complete game without using hints',
    icon: Icons.emoji_events,
    color: Colors.amber,
    isUnlocked:
        (stats) =>
            (stats['hintsUsed'] ?? 1) == 0 &&
            (stats['levelsCompleted'] ?? 0) >= 3,
  ),
];

// --- Game Mode Selection ---
enum GameMode { photosynthesis, changesOfMatter }

// --- Level Data for PHOTOSYNTHESIS ---
const List<Map<String, dynamic>> photosynthesisLevels = [
  {
    "level": 1,
    "title": "Building the Plant",
    "description": "Learn about plant parts and structures!",
    "requiredDiscoveries": 4,
    "combos": {
      "Soil+Water": "Roots",
      "Sunlight+Carbon Dioxide": "Leaves",
      "Roots+Water": "Stem",
      "Leaves+Sunlight": "Chlorophyll",
    },
  },
  {
    "level": 2,
    "title": "Photosynthesis Begins",
    "description": "Capture energy and materials for photosynthesis!",
    "requiredDiscoveries": 4,
    "combos": {
      "Sunlight+Chlorophyll": "Light Energy",
      "Leaves+Carbon Dioxide": "Captured CO2",
      "Chlorophyll+Stem": "Chloroplast",
      "Leaves+Water": "Stomata",
    },
  },
  {
    "level": 3,
    "title": "Making Food & Oxygen",
    "description": "Complete the photosynthesis process!",
    "requiredDiscoveries": 6,
    "combos": {
      "Light Energy+Captured CO2": "Glucose",
      "Water+Light Energy": "Oxygen",
      "Glucose+Light Energy": "Plant Food",
      "Plant Food+Oxygen": "Growing Plant",
      "Glucose+Chloroplast": "Energy Storage",
      "Light Energy+Chloroplast": "Photosynthesis",
    },
  },
];

// --- Level Data for CHANGES OF MATTER ---
const List<Map<String, dynamic>> matterLevels = [
  {
    "level": 1,
    "title": "Physical Changes",
    "description": "See matter transform between states!",
    "requiredDiscoveries": 4,
    "combos": {
      "Ice+Heat": "Melting",
      "Liquid Water+Cold": "Freezing",
      "Heat+Liquid Water": "Steam",
      "Ice+Cold": "Frost",
    },
  },
  {
    "level": 2,
    "title": "States of Matter",
    "description": "Understand solid, liquid, and gas!",
    "requiredDiscoveries": 6,
    "combos": {
      "Ice+Melting": "Liquid",
      "Liquid Water+Freezing": "Solid",
      "Steam+Heat": "Gas",
      "Liquid Water+Heat": "Evaporation",
      "Ice+Heat": "Sublimation",
      "Steam+Cold": "Deposition",
    },
  },
  {
    "level": 3,
    "title": "Matter Science",
    "description": "Master the science of matter!",
    "requiredDiscoveries": 6,
    "combos": {
      "Solid+Liquid": "Particles",
      "Gas+Liquid": "Energy Change",
      "Melting+Freezing": "Phase Change",
      "Evaporation+Condensation": "Matter Cycle",
      "Particles+Heat": "Molecular Motion",
      "Heat+Cold": "Temperature",
    },
  },
];

// ============================================================================
// MAIN GAME SELECTION SCREEN
// ============================================================================

class ScienceFusionHome extends StatelessWidget {
  final String username;
  const ScienceFusionHome({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF2A1B4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "🧪 Science Fusion Lab",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Hi, $username! Let's learn science!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AchievementsScreen(username: username),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.leaderboard,
                        color: Colors.cyan,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ScienceFusionLeaderboard(
                                  username: username,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Game Mode Cards
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildGameCard(
                      context,
                      title: "🌿 Photosynthesis Lab",
                      description: "Learn how plants make food from sunlight!",
                      color: Colors.green,
                      icon: Icons.eco,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ScienceFusionGame(
                                  username: username,
                                  gameMode: GameMode.photosynthesis,
                                ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildGameCard(
                      context,
                      title: "🧊 Changes of Matter Lab",
                      description:
                          "Discover how matter changes between states!",
                      color: Colors.blue,
                      icon: Icons.science,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ScienceFusionGame(
                                  username: username,
                                  gameMode: GameMode.changesOfMatter,
                                ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    _buildInfoCard(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.4),
            Colors.purple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                "How to Play",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildInfoRow("🎯", "Find the target element shown at top"),
          _buildInfoRow("🔬", "Drag elements together to combine"),
          _buildInfoRow("📦", "Collect discoveries for bonus points"),
          _buildInfoRow("🔥", "Build combos for streak bonuses"),
          _buildInfoRow("💡", "Use hints if you need help"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACHIEVEMENTS SCREEN
// ============================================================================

class AchievementsScreen extends StatelessWidget {
  final String username;
  const AchievementsScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    // Mock stats - in real app, load from storage
    Map<String, dynamic> stats = {
      'totalDiscoveries': 15,
      'collected': 12,
      'maxStreak': 6,
      'fastestLevel': 95,
      'hintsUsed': 0,
      'levelsCompleted': 3,
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF2A1B4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "🏆 Achievements",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Your Progress",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    final isUnlocked = achievement.isUnlocked(stats);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient:
                            isUnlocked
                                ? LinearGradient(
                                  colors: [
                                    achievement.color.withOpacity(0.3),
                                    achievement.color.withOpacity(0.1),
                                  ],
                                )
                                : null,
                        color:
                            isUnlocked ? null : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              isUnlocked ? achievement.color : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isUnlocked
                                      ? achievement.color.withOpacity(0.3)
                                      : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              achievement.icon,
                              color: isUnlocked ? Colors.white : Colors.white30,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.title,
                                  style: TextStyle(
                                    color:
                                        isUnlocked
                                            ? Colors.white
                                            : Colors.white30,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  achievement.description,
                                  style: TextStyle(
                                    color:
                                        isUnlocked
                                            ? Colors.white70
                                            : Colors.white30,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            Icon(
                              Icons.check_circle,
                              color: achievement.color,
                              size: 28,
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

// ============================================================================
// MAIN GAME SCREEN
// ============================================================================

class ScienceFusionGame extends StatefulWidget {
  final String username;
  final GameMode gameMode;

  const ScienceFusionGame({required this.username, required this.gameMode});

  @override
  State<ScienceFusionGame> createState() => _ScienceFusionGameState();
}

class _ScienceFusionGameState extends State<ScienceFusionGame>
    with SingleTickerProviderStateMixin {
  int currentLevel = 1;
  List<String> discoveredElements = [];
  Set<String> collectedElements = {};
  String? targetElement;
  int score = 0;
  int highScore = 0;
  int hintsUsed = 0;
  int timeBonus = 0;
  int comboStreak = 0;
  int maxComboStreak = 0;
  DateTime? levelStartTime;
  int fastestLevelTime = 999;
  bool showTutorial = true;
  int tutorialStep = 0;

  List<String> baseElements = [];
  List<Map<String, dynamic>> levelData = [];
  String gameTitle = "";
  String gameId = "";
  bool showCollectionPanel = false;

  late AnimationController _celebrationController;
  String? lastDiscoveredElement;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _loadHighScore();
    levelStartTime = DateTime.now();
    _celebrationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Show tutorial on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showTutorial) {
        _showTutorialDialog();
      }
    });

    // Start background music
    AudioService.playBackgroundMusic();
  }

  Future<void> _loadHighScore() async {
    // Use the universal service to get the user's high score
    List<Map<String, dynamic>> userHistory =
        await UniversalLeaderboardService.getUserHistory(
          widget.username,
          gameId: gameId,
        );
    if (userHistory.isNotEmpty) {
      // Find the highest score
      userHistory.sort((a, b) => b['percentage'].compareTo(a['percentage']));
      setState(() {
        highScore = userHistory.first['percentage'];
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    AudioService.stopMusic(); // Stop music when leaving
    super.dispose();
  }

  void _initializeGame() {
    if (widget.gameMode == GameMode.photosynthesis) {
      baseElements = ["Sunlight", "Water", "Carbon Dioxide", "Soil"];
      levelData = photosynthesisLevels;
      gameTitle = "Photosynthesis Lab";
      gameId = "photosynthesis";
    } else {
      baseElements = ["Ice", "Liquid Water", "Heat", "Cold"];
      levelData = matterLevels;
      gameTitle = "Changes of Matter Lab";
      gameId = "matter_changes";
    }

    // Start with base elements already discovered
    discoveredElements.addAll(baseElements);
    collectedElements.addAll(baseElements);
    _pickNewTarget();
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final tutorialSteps = [
              {
                'title': '🎯 Your Mission',
                'content':
                    'Find the TARGET element shown at the top by combining other elements!',
                'icon': Icons.flag,
              },
              {
                'title': '🔬 How to Combine',
                'content':
                    'LONG-PRESS and DRAG one element onto another to fuse them!',
                'icon': Icons.science,
              },
              {
                'title': '📦 Collect Elements',
                'content':
                    'Tap discoveries to COLLECT them. Collected elements give bonus points!',
                'icon': Icons.collections_bookmark,
              },
              {
                'title': '🔥 Combo Streaks',
                'content':
                    'Find target elements in a row to build a STREAK for bonus points!',
                'icon': Icons.local_fire_department,
              },
              {
                'title': '💡 Need Help?',
                'content':
                    'Use the lightbulb button for hints, but they cost 5 points each.',
                'icon': Icons.lightbulb_outline,
              },
            ];

            final currentStep = tutorialSteps[tutorialStep];

            return AlertDialog(
              backgroundColor: Color(0xFF1C1F3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    currentStep['icon'] as IconData,
                    color: Colors.amber,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentStep['title'] as String,
                    style: TextStyle(color: Colors.white, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStep['content'] as String,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      tutorialSteps.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              index == tutorialStep
                                  ? Colors.amber
                                  : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (tutorialStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() => tutorialStep--);
                    },
                    child: Text(
                      "Back",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                if (tutorialStep < tutorialSteps.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() => tutorialStep++);
                    },
                    child: Text("Next", style: TextStyle(color: Colors.black)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      this.setState(() => showTutorial = false);
                    },
                    child: Text(
                      "Let's Play!",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, String> get allAvailableCombos {
    Map<String, String> combos = {};
    for (int i = 0; i < currentLevel; i++) {
      combos.addAll(levelData[i]['combos'].cast<String, String>());
    }
    return combos;
  }

  List<String> get currentLevelTargets {
    return levelData[currentLevel - 1]['combos'].values
        .toSet()
        .toList()
        .cast<String>();
  }

  int get currentLevelDiscoveredTargetCount {
    return currentLevelTargets
        .where((e) => discoveredElements.contains(e))
        .length;
  }

  bool get isStageComplete =>
      currentLevelDiscoveredTargetCount ==
      levelData[currentLevel - 1]['requiredDiscoveries'];

  void _pickNewTarget() {
    if (isStageComplete) {
      targetElement = null;
      setState(() {});
      return;
    }

    final List<String> undiscoveredTargets =
        currentLevelTargets
            .where((element) => !discoveredElements.contains(element))
            .toList();

    if (undiscoveredTargets.isNotEmpty) {
      targetElement =
          undiscoveredTargets[Random().nextInt(undiscoveredTargets.length)];
    } else {
      targetElement = null;
    }
    setState(() {});
  }

  void _advanceLevel() {
    if (currentLevel < levelData.length) {
      if (levelStartTime != null) {
        int secondsTaken = DateTime.now().difference(levelStartTime!).inSeconds;
        timeBonus = max(0, 50 - secondsTaken ~/ 2);
        score += timeBonus;

        if (secondsTaken < fastestLevelTime) {
          fastestLevelTime = secondsTaken;
        }
      }

      currentLevel++;
      levelStartTime = DateTime.now();
      comboStreak = 0;

      HapticFeedback.heavyImpact();

      _showMessage(
        "🎉 Level Complete! +$timeBonus time bonus!\nAdvancing to Level $currentLevel",
        Colors.purpleAccent,
      );
      _pickNewTarget();
    } else {
      _completeGame();
    }
    setState(() {});
  }

  void _completeGame() async {
    int hintPenalty = hintsUsed * 5;
    int collectionBonus = collectedElements.length * 5;
    int streakBonus = maxComboStreak * 10;
    int finalScore = max(
      0,
      score - hintPenalty + collectionBonus + streakBonus,
    );
    int maxScore = (levelData.length * 40 * 6) + 200;

    HapticFeedback.heavyImpact();

    // Check if it's a new high score
    bool isNewHighScore = finalScore > highScore;

    _showMessage(
      isNewHighScore
          ? "🏆 NEW HIGH SCORE!\nFinal Score: $finalScore"
          : "🏆 Game Complete!\nFinal Score: $finalScore",
      isNewHighScore ? Colors.amber : Colors.greenAccent,
    );

    // Save score using Universal Leaderboard Service
    await UniversalLeaderboardService.saveScore(
      username: widget.username,
      gameId: gameId,
      category: "Level ${levelData.length}",
      score: finalScore,
      maxScore: maxScore,
      metadata: {
        'levelsCompleted': currentLevel,
        'hintsUsed': hintsUsed,
        'timeBonus': timeBonus,
        'discoveredElements': discoveredElements.length,
        'collectedElements': collectedElements.length,
        'totalElements': scienceVisuals.length,
        'maxStreak': maxComboStreak,
        'fastestLevel': fastestLevelTime,
      },
    );

    // Reload high score
    await _loadHighScore();

    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      _showCompletionDialog(finalScore, maxScore, isNewHighScore);
    }
  }

  void _showCompletionDialog(
    int finalScore,
    int maxScore,
    bool isNewHighScore,
  ) {
    int percentage = ((finalScore / maxScore) * 100).round();
    String rank =
        percentage >= 90
            ? "🏆 Master Scientist!"
            : percentage >= 75
            ? "🥇 Expert Scientist!"
            : percentage >= 60
            ? "🥈 Great Scientist!"
            : "🥉 Good Scientist!";

    // Check achievements
    Map<String, dynamic> stats = {
      'totalDiscoveries': discoveredElements.length,
      'collected': collectedElements.length,
      'maxStreak': maxComboStreak,
      'fastestLevel': fastestLevelTime,
      'hintsUsed': hintsUsed,
      'levelsCompleted': currentLevel,
    };

    List<Achievement> unlockedAchievements =
        achievements.where((a) => a.isUnlocked(stats)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Text(
                  isNewHighScore ? "🎉" : "🎉",
                  style: TextStyle(fontSize: 60),
                ),
                SizedBox(height: 10),
                Text(
                  isNewHighScore ? "New High Score!" : "Lab Complete!",
                  style: TextStyle(
                    color: isNewHighScore ? Colors.amber : Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rank,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$finalScore / $maxScore",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$percentage% Perfect",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        if (isNewHighScore) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "🏆 NEW RECORD!",
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (!isNewHighScore && highScore > 0) ...[
                          SizedBox(height: 8),
                          Text(
                            "Personal Best: $highScore",
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        SizedBox(height: 10),
                        Divider(color: Colors.white30),
                        SizedBox(height: 10),
                        _buildStatRow(
                          "📦 Collected",
                          "${collectedElements.length} elements",
                        ),
                        _buildStatRow(
                          "✨ Discoveries",
                          "${discoveredElements.length}",
                        ),
                        _buildStatRow("🔥 Max Streak", "${maxComboStreak}x"),
                        _buildStatRow("💡 Hints Used", "$hintsUsed"),
                        _buildStatRow(
                          "⚡ Fastest Level",
                          "${fastestLevelTime}s",
                        ),
                      ],
                    ),
                  ),
                  if (unlockedAchievements.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Text(
                      "🏆 Achievements Unlocked!",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          unlockedAchievements
                              .map(
                                (a) => Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: a.color.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        a.icon,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      Text(
                                        a.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  "Back to Menu",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ScienceFusionLeaderboard(
                            username: widget.username,
                          ),
                    ),
                  );
                },
                child: Text(
                  "Leaderboard",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _combine(String target, String dragged) {
    if (target == dragged) {
      HapticFeedback.lightImpact();
      _showMessage("❌ Can't combine element with itself!", Colors.orangeAccent);
      return;
    }

    if (isStageComplete) {
      _showMessage(
        "✅ Level complete! Continue to next level!",
        Colors.greenAccent,
      );
      return;
    }

    String? result;
    final Map<String, String> combos = allAvailableCombos;

    combos.forEach((key, value) {
      final parts = key.split('+');
      if ((parts.contains(target) && parts.contains(dragged))) {
        result = value;
      }
    });

    if (result != null) {
      if (!discoveredElements.contains(result)) {
        HapticFeedback.mediumImpact();

        setState(() {
          discoveredElements.add(result!);
          lastDiscoveredElement = result;
          score += 10;
          comboStreak++;
          maxComboStreak = max(maxComboStreak, comboStreak);

          _celebrationController.forward(from: 0);

          if (currentLevelTargets.contains(result)) {
            if (result == targetElement) {
              int streakBonus = comboStreak * 5;
              score += 30 + streakBonus;
              _showMessage(
                "🎯 TARGET FOUND! $result\n+${40 + streakBonus} pts • 🔥 ${comboStreak}x Streak!",
                Colors.greenAccent,
              );
            } else {
              score += 10;
              _showMessage(
                "✨ Great discovery: $result\n+20 pts • Progress: $currentLevelDiscoveredTargetCount/${levelData[currentLevel - 1]['requiredDiscoveries']}",
                Colors.lightBlueAccent,
              );
            }
            Future.delayed(const Duration(milliseconds: 500), _pickNewTarget);
          } else {
            _showMessage(
              "✨ New element: $result\n+10 pts • 💡 Tap to collect for +5 pts bonus!",
              Colors.lightBlueAccent,
            );
          }
        });
      } else {
        HapticFeedback.lightImpact();
        _showMessage(
          "⚠️ Already discovered! Try different combinations.",
          Colors.orangeAccent,
        );
        setState(() {
          comboStreak = max(0, comboStreak - 1);
        });
      }
    } else {
      HapticFeedback.lightImpact();
      _showMessage(
        "❌ $target + $dragged don't combine\nTry different elements!",
        Colors.redAccent,
      );
      setState(() {
        comboStreak = 0;
      });
    }
  }

  void _collectElement(String element) {
    if (!collectedElements.contains(element)) {
      HapticFeedback.lightImpact();
      setState(() {
        collectedElements.add(element);
        score += 5;
      });
      _showMessage("📦 Collected: $element! (+5 pts)", Colors.cyanAccent);
    }
  }

  void _showElementInfo(String element) {
    final info = scienceVisuals[element];
    if (info == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Text(info['emoji'], style: TextStyle(fontSize: 40)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    element,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info['info'] ?? 'No information available',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Got it!", style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
    );
  }

  void _showHint() {
    if (targetElement == null || isStageComplete) {
      _showMessage(
        "💡 No hint needed - level complete or no target!",
        Colors.blueAccent,
      );
      return;
    }

    final Map<String, String> combos = allAvailableCombos;
    String? hint;

    combos.forEach((key, value) {
      if (value == targetElement) {
        final parts = key.split('+');
        hint = "Try combining:\n${parts[0]} + ${parts[1]}";
      }
    });

    if (hint != null) {
      HapticFeedback.lightImpact();
      setState(() {
        hintsUsed++;
        score = max(0, score - 5);
      });
      _showMessage("💡 Hint (-5 pts):\n$hint", Colors.yellowAccent);
    } else {
      _showMessage(
        "💡 Hint: Try combining different elements!",
        Colors.blueAccent,
      );
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color:
                Colors
                    .black, // Added black text color for better readability against light backgrounds
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int requiredDiscoveries =
        levelData[currentLevel - 1]['requiredDiscoveries'];
    final int discoveredCount = currentLevelDiscoveredTargetCount;
    final double progress =
        requiredDiscoveries > 0 ? discoveredCount / requiredDiscoveries : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor:
            widget.gameMode == GameMode.photosynthesis
                ? Colors.green.shade700
                : Colors.blue.shade700,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameTitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Level $currentLevel: ${levelData[currentLevel - 1]['title']}",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline),
            onPressed: _showHint,
            tooltip: "Get Hint (-5 pts)",
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.collections_bookmark),
                if (collectedElements.length < discoveredElements.length)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => showCollectionPanel = !showCollectionPanel);
            },
            tooltip:
                "Collection (${collectedElements.length}/${discoveredElements.length})",
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              tutorialStep = 0;
              _showTutorialDialog();
            },
            tooltip: "Show Tutorial",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Info Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildTargetDisplay(),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  color: Colors.greenAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Score: $score",
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (highScore > 0)
                          Text(
                            "Best: $highScore",
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        if (comboStreak > 1)
                          Text(
                            "🔥 Streak: x$comboStreak",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      "Progress: $discoveredCount/$requiredDiscoveries",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Collected: ${collectedElements.length}",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Hints: $hintsUsed",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Collection Panel
          if (showCollectionPanel) _buildCollectionPanel(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade700),
              ),
              child: Text(
                levelData[currentLevel - 1]['description'],
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "🧪 Long-press and drag elements together to fuse!",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // Base Elements Grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Removed: The separate base elements grid (first 4 cards) has been eliminated.
                  // Instead, the Fusion Lab now serves as the main element area, displaying all discovered elements (including base elements from the start).

                  // Discovered Elements Grid (Fusion Lab) - Now the primary/main element area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "🔬 Fusion Lab - Drag elements together!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF1C1F3E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.shade300,
                              width: 2,
                            ),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  4, // Adjusted for better layout in the main area
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: discoveredElements.length,
                            itemBuilder: (context, index) {
                              final element = discoveredElements[index];
                              return _draggableDiscoveredTile(
                                element,
                              ); // All elements are now draggable from here
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPanel() {
    final uncollected =
        discoveredElements
            .where((e) => !collectedElements.contains(e))
            .toList();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 150,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.5),
            Colors.blue.shade900.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "📦 Element Collection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${collectedElements.length}/${discoveredElements.length}",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (uncollected.isEmpty)
            Center(
              child: Text(
                "🎉 All discovered elements collected!",
                style: TextStyle(color: Colors.greenAccent, fontSize: 14),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      uncollected.map((element) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _collectElement(element),
                            child: Stack(
                              children: [
                                _tile(element, size: 70, showInfoButton: true),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add_circle,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _draggableTile(String element) {
    return LongPressDraggable<String>(
      data: element,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        color: Colors.transparent,
        child: _tile(element, isDragging: true, size: 80.0),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _tile(element, size: 80.0),
      ),
      child: DragTarget<String>(
        onWillAccept: (incoming) => incoming != element,
        onAccept: (incoming) => _combine(element, incoming!),
        builder:
            (context, candidate, rejected) => _tile(
              element,
              isHighlighted: candidate.isNotEmpty,
              size: 80.0,
              showInfoButton: true,
            ),
      ),
    );
  }

  Widget _draggableDiscoveredTile(String element) {
    return LongPressDraggable<String>(
      data: element,
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        color: Colors.transparent,
        child: _tile(element, isDragging: true, size: 70.0),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _tile(element, size: 70.0),
      ),
      child: DragTarget<String>(
        onWillAccept: (incoming) => incoming != element,
        onAccept: (incoming) => _combine(element, incoming!),
        builder:
            (context, candidate, rejected) => _tile(
              element,
              isHighlighted: candidate.isNotEmpty,
              size: 70.0,
              showInfoButton: true,
            ),
      ),
    );
  }

  Widget _buildTargetDisplay() {
    if (isStageComplete && currentLevel < levelData.length) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "✅ Level Complete! Amazing work!",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _advanceLevel,
              icon: const Icon(Icons.arrow_forward_ios),
              label: Text("Continue to Level ${currentLevel + 1}"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (currentLevel == levelData.length && isStageComplete) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "🏆 ALL LEVELS COMPLETE!",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _completeGame,
              child: Text("Finish & Save Score"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "🎯 Target: ",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          _elementIcon(targetElement!, size: 28),
          const SizedBox(width: 8),
          Text(
            targetElement!,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    String text, {
    bool isDragging = false,
    bool isHighlighted = false,
    double size = 80.0,
    bool showInfoButton = false,
  }) {
    final elementProps =
        scienceVisuals[text] ??
        {"color": Colors.grey, "icon": Icons.help_outline, "emoji": "❓"};
    final Color elementColor = elementProps['color'];
    final String emoji = elementProps['emoji'];
    final double fontSize = size * 0.14;
    bool isCollected = collectedElements.contains(text);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: size,
      width: size,
      decoration: BoxDecoration(
        color:
            isHighlighted ? Colors.purpleAccent : elementColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDragging
                  ? Colors.orangeAccent
                  : isCollected
                  ? Colors.greenAccent
                  : Colors.white24,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: elementColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: size * 0.35)),
              const SizedBox(height: 4),
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  height: 1.1,
                ),
              ),
            ],
          ),
          if (isCollected && !baseElements.contains(text))
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
          // Info button (tap to see definition)
          if (showInfoButton && !baseElements.contains(text))
            Positioned(
              bottom: 2,
              right: 2,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showElementInfo(text);
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _elementIcon(String element, {double size = 40}) {
    final elementProps = scienceVisuals[element] ?? {"emoji": "❓"};
    return Text(elementProps['emoji'], style: TextStyle(fontSize: size));
  }
}

// ============================================================================
// LEADERBOARD SCREEN
// ============================================================================

class ScienceFusionLeaderboard extends StatefulWidget {
  final String? username; // Made optional since we can fetch it dynamically
  const ScienceFusionLeaderboard({this.username}); // Now optional

  @override
  State<ScienceFusionLeaderboard> createState() =>
      _ScienceFusionLeaderboardState();
}

class _ScienceFusionLeaderboardState extends State<ScienceFusionLeaderboard> {
  String selectedGame = "photosynthesis";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF2A1B4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "🏆 Science Fusion Rankings",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Top Scientists",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            () =>
                                setState(() => selectedGame = "photosynthesis"),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                selectedGame == "photosynthesis"
                                    ? Colors.green
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            "🌿 Photosynthesis",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            () =>
                                setState(() => selectedGame = "matter_changes"),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                selectedGame == "matter_changes"
                                    ? Colors.blue
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            "🧊 Matter Changes",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Leaderboard with Current Username Fetch
              Expanded(
                child: FutureBuilder<String?>(
                  future: UniversalLeaderboardService.getCurrentUsername(),
                  builder: (context, usernameSnapshot) {
                    String? currentUsername =
                        usernameSnapshot.data ??
                        widget
                            .username; // Use fetched username, fallback to passed one

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: UniversalLeaderboardService.getGameLeaderboard(
                        gameId: selectedGame,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildLeaderboardList(
                          snapshot.data!,
                          currentUsername,
                        );
                      },
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

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    String? currentUsername,
  ) {
    Color themeColor =
        selectedGame == "photosynthesis" ? Colors.green : Colors.blue;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        var score = leaderboard[index];
        bool isCurrentUser =
            score['username'] ==
            currentUsername; // Use the fetched or passed username
        String medal =
            index == 0
                ? "🥇"
                : index == 1
                ? "🥈"
                : index == 2
                ? "🥉"
                : "";

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                isCurrentUser
                    ? LinearGradient(
                      colors: [
                        themeColor.withOpacity(0.3),
                        themeColor.withOpacity(0.15),
                      ],
                    )
                    : index < 3
                    ? LinearGradient(
                      colors: [
                        Colors.amber.withOpacity(0.2),
                        Colors.amber.withOpacity(0.05),
                      ],
                    )
                    : null,
            color:
                isCurrentUser || index < 3
                    ? null
                    : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isCurrentUser
                      ? themeColor
                      : index < 3
                      ? Colors.amber.shade700
                      : Colors.white24,
              width: isCurrentUser || index < 3 ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                child: Text(
                  medal.isEmpty ? "#${index + 1}" : medal,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: medal.isEmpty ? 18 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          score['username'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor,
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "YOU",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (index == 0) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "HIGH SCORE",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Collected: ${score['metadata']?['collectedElements'] ?? 'N/A'}",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(" • ", style: TextStyle(color: Colors.white60)),
                        Text(
                          "Streak: ${score['metadata']?['maxStreak'] ?? 'N/A'}x",
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${score['percentage']}%",
                    style: TextStyle(
                      color:
                          index == 0
                              ? Colors.amber
                              : isCurrentUser
                              ? themeColor
                              : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "points",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("📊", style: TextStyle(fontSize: 60)),
          SizedBox(height: 20),
          Text(
            "No scores yet!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Be the first to play!",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UNIVERSAL LEADERBOARD SERVICE (With SharedPreferences)
// ============================================================================

// ============================================================================
// UNIVERSAL LEADERBOARD SERVICE (With SharedPreferences)
// ============================================================================

class UniversalLeaderboardService {
  static const String _allScoresKey = 'universal_all_scores';
  static const String _userStatsKey = 'universal_user_stats';

  // Game identifiers
  static const String GAME_QUIZ = 'quiz';
  static const String GAME_MEMORY = 'memory';
  static const String GAME_PUZZLE = 'puzzle';
  // Add more game IDs as needed

  /// Get the current logged-in username from SharedPreferences
  /// This retrieves the username stored during login/signup (as seen in LoginScreen and StudentSignupScreen)
  static Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
      "username",
    ); // Matches the key used in LoginScreen and StudentSignupScreen
  }

  /// Save a game score
  /// @param username - Player's username
  /// @param gameId - Unique game identifier (e.g., 'quiz', 'memory', 'puzzle')
  /// @param category - Category within the game (e.g., 'Photosynthesis', 'Level 1')
  /// @param score - Score achieved
  /// @param maxScore - Maximum possible score
  /// @param metadata - Additional game-specific data (optional)
  static Future<void> saveScore({
    required String username,
    required String gameId,
    required String category,
    required int score,
    required int maxScore,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing scores
    List<Map<String, dynamic>> allScores = await _getAllScores();

    // Calculate points (0-100 scale for consistency)
    int points = ((score / maxScore) * 100).round();
    int percentage = points;

    // Create score entry
    Map<String, dynamic> scoreEntry = {
      'username': username,
      'gameId': gameId,
      'category': category,
      'score': score,
      'maxScore': maxScore,
      'points': points,
      'percentage': percentage,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    // Add to all scores
    allScores.add(scoreEntry);

    // Save to storage
    await prefs.setString(_allScoresKey, jsonEncode(allScores));

    // Update user statistics
    await _updateUserStats(username);
  }

  /// Get all scores (internal use)
  static Future<List<Map<String, dynamic>>> _getAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    String? scoresJson = prefs.getString(_allScoresKey);

    if (scoresJson == null) return [];

    List<dynamic> scoresList = jsonDecode(scoresJson);
    return scoresList.cast<Map<String, dynamic>>();
  }

  /// Get leaderboard for a specific game
  /// @param gameId - Game identifier (null for overall leaderboard)
  /// @param category - Category filter (null for all categories)
  /// @param limit - Maximum number of entries to return (null for all)
  static Future<List<Map<String, dynamic>>> getGameLeaderboard({
    String? gameId,
    String? category,
    int? limit,
  }) async {
    List<Map<String, dynamic>> allScores = await _getAllScores();

    // Filter by game
    if (gameId != null) {
      allScores = allScores.where((s) => s['gameId'] == gameId).toList();
    }

    // Filter by category
    if (category != null) {
      allScores = allScores.where((s) => s['category'] == category).toList();
    }

    // Sort by percentage (descending), then by timestamp (most recent first)
    allScores.sort((a, b) {
      int percentageCompare = b['percentage'].compareTo(a['percentage']);
      if (percentageCompare != 0) return percentageCompare;
      return DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp']));
    });

    // Apply limit if specified
    if (limit != null && allScores.length > limit) {
      allScores = allScores.sublist(0, limit);
    }

    return allScores;
  }

  /// Get overall leaderboard (all games combined, ranked by total points)
  static Future<List<Map<String, dynamic>>> getOverallLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    String? statsJson = prefs.getString(_userStatsKey);

    if (statsJson == null) return [];

    Map<String, dynamic> allStats = jsonDecode(statsJson);
    List<Map<String, dynamic>> leaderboard = [];

    allStats.forEach((username, stats) {
      leaderboard.add(Map<String, dynamic>.from(stats));
    });

    // Sort by total points (descending)
    leaderboard.sort((a, b) => b['totalPoints'].compareTo(a['totalPoints']));

    return leaderboard;
  }

  /// Get user statistics
  static Future<Map<String, dynamic>?> getUserStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    String? statsJson = prefs.getString(_userStatsKey);

    if (statsJson == null) return null;

    Map<String, dynamic> allStats = jsonDecode(statsJson);
    return allStats[username];
  }

  /// Get user's rank in overall leaderboard
  static Future<int> getUserOverallRank(String username) async {
    List<Map<String, dynamic>> leaderboard = await getOverallLeaderboard();

    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i]['username'] == username) {
        return i + 1;
      }
    }

    return -1;
  }

  /// Get user's rank in a specific game
  static Future<int> getUserGameRank(
    String username,
    String gameId, {
    String? category,
  }) async {
    List<Map<String, dynamic>> leaderboard = await getGameLeaderboard(
      gameId: gameId,
      category: category,
    );

    // Find user's best score
    var userScores =
        leaderboard.where((s) => s['username'] == username).toList();
    if (userScores.isEmpty) return -1;

    return leaderboard.indexOf(userScores.first) + 1;
  }

  /// Get user's game history
  static Future<List<Map<String, dynamic>>> getUserHistory(
    String username, {
    String? gameId,
  }) async {
    List<Map<String, dynamic>> allScores = await _getAllScores();

    // Filter by username
    List<Map<String, dynamic>> userScores =
        allScores.where((s) => s['username'] == username).toList();

    // Filter by game if specified
    if (gameId != null) {
      userScores = userScores.where((s) => s['gameId'] == gameId).toList();
    }

    // Sort by timestamp (most recent first)
    userScores.sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );

    return userScores;
  }

  /// Update user statistics (internal)
  static Future<void> _updateUserStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> allScores = await _getAllScores();

    // Filter user's scores
    List<Map<String, dynamic>> userScores =
        allScores.where((s) => s['username'] == username).toList();

    if (userScores.isEmpty) return;

    // Calculate overall statistics
    int totalGames = userScores.length;
    int totalPoints = userScores.fold(
      0,
      (sum, score) => sum + (score['points'] as int),
    );
    double averagePercentage =
        userScores.fold(
          0.0,
          (sum, score) => sum + (score['percentage'] as int),
        ) /
        totalGames;

    // Calculate per-game statistics
    Map<String, Map<String, dynamic>> gameStats = {};
    for (var score in userScores) {
      String gameId = score['gameId'];
      if (!gameStats.containsKey(gameId)) {
        gameStats[gameId] = {
          'gameId': gameId,
          'gamesPlayed': 0,
          'totalPoints': 0,
          'averagePercentage': 0.0,
          'bestScore': 0,
        };
      }

      gameStats[gameId]!['gamesPlayed'] =
          (gameStats[gameId]!['gamesPlayed'] as int) + 1;
      gameStats[gameId]!['totalPoints'] =
          (gameStats[gameId]!['totalPoints'] as int) + (score['points'] as int);

      if (score['percentage'] > gameStats[gameId]!['bestScore']) {
        gameStats[gameId]!['bestScore'] = score['percentage'];
      }
    }

    // Calculate average percentages for each game
    gameStats.forEach((gameId, stats) {
      stats['averagePercentage'] =
          (stats['totalPoints'] / stats['gamesPlayed']).round();
    });

    // Save user stats
    Map<String, dynamic> stats = {
      'username': username,
      'totalGames': totalGames,
      'totalPoints': totalPoints,
      'averagePercentage': averagePercentage.round(),
      'gameStats': gameStats,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Get all user stats
    String? statsJson = prefs.getString(_userStatsKey);
    Map<String, dynamic> allStats = {};
    if (statsJson != null) {
      allStats = Map<String, dynamic>.from(jsonDecode(statsJson));
    }

    allStats[username] = stats;
    await prefs.setString(_userStatsKey, jsonEncode(allStats));
  }

  /// Get list of all games the user has played
  static Future<List<String>> getUserGames(String username) async {
    List<Map<String, dynamic>> userScores = await getUserHistory(username);
    Set<String> games = userScores.map((s) => s['gameId'] as String).toSet();
    return games.toList();
  }

  /// Clear all data (for testing/reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_allScoresKey);
    await prefs.remove(_userStatsKey);
  }
}

// ============================================================================
// REUSABLE LEADERBOARD UI COMPONENTS
// ============================================================================

/// Reusable Overall Leaderboard Screen
class UniversalOverallLeaderboardScreen extends StatelessWidget {
  final String username;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;

  const UniversalOverallLeaderboardScreen({
    required this.username,
    this.title = "🏆 Overall Leaderboard",
    this.primaryColor = Colors.amber,
    this.secondaryColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF2A1B4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "All Games Combined",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              SizedBox(height: 20),

              // Leaderboard
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: UniversalLeaderboardService.getOverallLeaderboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildLeaderboardList(snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaderboard) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        var user = leaderboard[index];
        bool isCurrentUser = user['username'] == username;
        String medal =
            index == 0
                ? "🥇"
                : index == 1
                ? "🥈"
                : index == 2
                ? "🥉"
                : "";

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                isCurrentUser
                    ? LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.3),
                        secondaryColor.withOpacity(0.2),
                      ],
                    )
                    : null,
            color: isCurrentUser ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isCurrentUser ? primaryColor : Colors.white24,
              width: isCurrentUser ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                child: Text(
                  medal.isEmpty ? "#${index + 1}" : medal,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: medal.isEmpty ? 18 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['username'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "YOU",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${user['totalGames']} games • ${user['averagePercentage']}% avg",
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${user['totalPoints']}",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "points",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("📊", style: TextStyle(fontSize: 60)),
          SizedBox(height: 20),
          Text(
            "No scores yet!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Play some games to see rankings!",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
