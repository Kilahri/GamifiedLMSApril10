import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';
import 'package:elearningapp_flutter/services/audio_service.dart';
import 'package:elearningapp_flutter/services/game_achievement_service.dart';

// ============================================================================
// MISSIONS PANEL
// ============================================================================

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
// NOTIFICATION TOAST
// ============================================================================

class _NotificationToast extends StatefulWidget {
  final String text;
  final Color color;
  final bool isError;
  final Animation<double>? shakeAnimation;
  final VoidCallback onDismiss;

  const _NotificationToast({
    required this.text,
    required this.color,
    required this.isError,
    required this.onDismiss,
    this.shakeAnimation,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 2500), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _slideController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  double _shakeOffset(double t) => sin(t * pi * 3) * (1 - t) * 10;

  @override
  Widget build(BuildContext context) {
    final IconData icon =
        widget.isError
            ? Icons.error_outline_rounded
            : widget.text.startsWith('🎯')
            ? Icons.flag_rounded
            : widget.text.startsWith('✅')
            ? Icons.check_circle_outline_rounded
            : Icons.auto_awesome_rounded;

    Widget toast = SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color.lerp(
                widget.color.withOpacity(0.15),
                const Color(0xFF1C1F3E),
                0.55,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.color.withOpacity(0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isError && widget.shakeAnimation != null) {
      toast = AnimatedBuilder(
        animation: widget.shakeAnimation!,
        builder:
            (_, child) => Transform.translate(
              offset: Offset(_shakeOffset(widget.shakeAnimation!.value), 0),
              child: child,
            ),
        child: toast,
      );
    }

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Material(color: Colors.transparent, child: toast),
    );
  }
}

// ============================================================================
// ELEMENT VISUALS
// ============================================================================

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

// ============================================================================
// GAME MODE
// ============================================================================

enum GameMode { photosynthesis, changesOfMatter }

// ============================================================================
// LEVEL DATA
// ============================================================================

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
// HOME SCREEN
// ============================================================================

class ScienceFusionHome extends StatelessWidget {
  final String username;
  const ScienceFusionHome({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        AudioService.stopBackgroundMusic();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            "🧪 Science Fusion Lab",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Hi, $username! Let's learn science!",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ScienceFusionAchievementsScreen(
                                    username: username,
                                  ),
                            ),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.leaderboard,
                        color: Colors.cyan,
                        size: 28,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ScienceFusionLeaderboard(
                                    username: username,
                                  ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildGameCard(
                      context,
                      title: "🌿 Photosynthesis Lab",
                      description: "Learn how plants make food from sunlight!",
                      color: Colors.green,
                      icon: Icons.eco,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ScienceFusionGame(
                                    username: username,
                                    gameMode: GameMode.photosynthesis,
                                  ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildGameCard(
                      context,
                      title: "🧊 Changes of Matter Lab",
                      description:
                          "Discover how matter changes between states!",
                      color: Colors.blue,
                      icon: Icons.science,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ScienceFusionGame(
                                    username: username,
                                    gameMode: GameMode.changesOfMatter,
                                  ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
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
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
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
          const SizedBox(height: 12),
          _infoRow("🎯", "Find the target element shown at top"),
          _infoRow("🔬", "Drag elements together to combine"),
          _infoRow("📦", "Collect discoveries for bonus points"),
          _infoRow("🔥", "Build combos for streak bonuses"),
          _infoRow("💡", "Use hints if you need help"),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACHIEVEMENTS SCREEN — loads real data from Firestore via GameAchievementService
// ============================================================================

class ScienceFusionAchievementsScreen extends StatefulWidget {
  final String username;
  const ScienceFusionAchievementsScreen({required this.username});

  @override
  State<ScienceFusionAchievementsScreen> createState() =>
      _ScienceFusionAchievementsScreenState();
}

class _ScienceFusionAchievementsScreenState
    extends State<ScienceFusionAchievementsScreen> {
  Set<String> _unlockedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await GameAchievementService.loadUnlocked(
      username: widget.username,
      gameId: GameAchievementService.GAME_FUSION,
    );
    if (mounted)
      setState(() {
        _unlockedIds = ids;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final allAchs = GameAchievementService.achievementsFor(
      GameAchievementService.GAME_FUSION,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
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
                            "Science Fusion Lab",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: allAchs.length,
                    itemBuilder: (context, index) {
                      final ach = allAchs[index];
                      final isUnlocked = _unlockedIds.contains(ach.id);
                      final tierLabel =
                          ach.tier == AchievementTier.gold
                              ? '🥇 Gold'
                              : ach.tier == AchievementTier.silver
                              ? '🥈 Silver'
                              : '🥉 Bronze';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient:
                              isUnlocked
                                  ? LinearGradient(
                                    colors: [
                                      ach.color.withOpacity(0.3),
                                      ach.color.withOpacity(0.1),
                                    ],
                                  )
                                  : null,
                          color:
                              isUnlocked
                                  ? null
                                  : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isUnlocked ? ach.color : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color:
                                    isUnlocked
                                        ? ach.color.withOpacity(0.3)
                                        : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  ach.emoji,
                                  style: TextStyle(
                                    fontSize: isUnlocked ? 28 : 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ach.title,
                                    style: TextStyle(
                                      color:
                                          isUnlocked
                                              ? Colors.white
                                              : Colors.white30,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ach.description,
                                    style: TextStyle(
                                      color:
                                          isUnlocked
                                              ? Colors.white70
                                              : Colors.white30,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tierLabel,
                                    style: TextStyle(
                                      color:
                                          isUnlocked
                                              ? ach.color
                                              : Colors.white24,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isUnlocked)
                              Icon(
                                Icons.check_circle,
                                color: ach.color,
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
    with TickerProviderStateMixin {
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

  // ── Session stats tracked for missions & achievements ──
  // Keys match the statKey values in _fusionMissions and _fusionAchievements
  final Map<String, dynamic> _sessionStats = {
    'sessionDiscoveries': 0, // total new combos found
    'sessionMaxStreak': 0, // highest combo streak this session
    'sessionCollected': 0, // elements tapped-collected
    'sessionTargetsFound': 0, // times the target element was found
    'sessionLevelReached': 1, // highest level reached
    // Achievement keys (GameAchievementService._fusionAchievements)
    'totalDiscoveries': 0,
    'collected': 0,
    'maxStreak': 0,
    'hintsUsed': 0,
    'levelsCompleted': 0,
    'fastestLevel': 999,
    'photoCompleted': false,
    'matterCompleted': false,
  };

  List<String> baseElements = [];
  List<Map<String, dynamic>> levelData = [];
  String gameTitle = "";
  String gameId = "";
  bool showCollectionPanel = false;
  bool _isPaused = false;

  late AnimationController _celebrationController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  OverlayEntry? _activeNotification;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _loadHighScore();
    levelStartTime = DateTime.now();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showTutorial) _showTutorialDialog();
    });

    AudioService.playBackgroundMusic('puzzle.mp3');
  }

  Future<void> _loadHighScore() async {
    final best = await FirebaseLeaderboardService.getPersonalBest(
      FirebaseLeaderboardService.GAME_SCIENCE_FUSION,
    );
    if (mounted) setState(() => highScore = best);
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      AudioService.pauseBackgroundMusic();
    } else {
      AudioService.resumeBackgroundMusic();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _shakeController.dispose();
    _activeNotification?.remove();
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
    discoveredElements.addAll(baseElements);
    collectedElements.addAll(baseElements);
    _pickNewTarget();
  }

  Map<String, String> get allAvailableCombos {
    final Map<String, String> combos = {};
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
    final undiscovered =
        currentLevelTargets
            .where((e) => !discoveredElements.contains(e))
            .toList();
    targetElement =
        undiscovered.isNotEmpty
            ? undiscovered[Random().nextInt(undiscovered.length)]
            : null;
    setState(() {});
  }

  // ── Called when the level-complete prompt is shown ──
  // Shows a dialog asking the player to Quit (save score) or Continue
  void _showLevelCompleteOptions() {
    if (levelStartTime != null) {
      final secondsTaken = DateTime.now().difference(levelStartTime!).inSeconds;
      timeBonus = max(0, 50 - secondsTaken ~/ 2);
      score += timeBonus;
      if (secondsTaken < fastestLevelTime) {
        fastestLevelTime = secondsTaken;
        _sessionStats['fastestLevel'] = fastestLevelTime;
      }
    }

    HapticFeedback.heavyImpact();

    final accentColor =
        widget.gameMode == GameMode.photosynthesis
            ? Colors.green.shade400
            : Colors.blue.shade400;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: [
                const Text("🎉", style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                Text(
                  "Level $currentLevel Complete!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (timeBonus > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.6)),
                    ),
                    child: Text(
                      "⏱️ Time Bonus: +$timeBonus pts",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow("🏅 Current Score", "$score pts"),
                      _buildStatRow("🔥 Max Streak", "${maxComboStreak}x"),
                      _buildStatRow(
                        "📦 Collected",
                        "${collectedElements.length}",
                      ),
                      if (currentLevel < levelData.length) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Next: Level ${currentLevel + 1} — ${levelData[currentLevel]['title']}",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "What would you like to do?",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              // ── QUIT: save score and go back to menu ──
              OutlinedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text("Save & Quit"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  _saveAndQuit();
                },
              ),
              // ── CONTINUE ──
              if (currentLevel < levelData.length)
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: Text("Level ${currentLevel + 1}"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    _advanceToNextLevel();
                  },
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.emoji_events),
                  label: const Text("Finish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _completeGame();
                  },
                ),
            ],
          ),
    );
  }

  // ── Save current score and return to menu ──
  Future<void> _saveAndQuit() async {
    final int finalScore = _calcFinalScore();
    final bool isNewHighScore = finalScore > highScore;

    // Update session stats before saving
    _syncSessionStats();

    await _saveScoreToFirebase(finalScore);
    await _checkAndShowAchievements();
    await _loadHighScore();

    if (!mounted) return;

    _showMessage(
      isNewHighScore
          ? "🏆 NEW HIGH SCORE! $finalScore pts saved!"
          : "✅ Score saved: $finalScore pts",
      isNewHighScore ? Colors.amber : Colors.greenAccent,
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      AudioService.stopBackgroundMusic();
      Navigator.pop(context);
    }
  }

  // ── Move to the next level, keeping score ──
  void _advanceToNextLevel() {
    setState(() {
      currentLevel++;
      levelStartTime = DateTime.now();
      comboStreak = 0;
      _sessionStats['sessionLevelReached'] = currentLevel;
    });
    _pickNewTarget();
    _showMessage(
      "🚀 Level $currentLevel started! Keep going!",
      Colors.purpleAccent,
    );
  }

  int _calcFinalScore() {
    final int hintPenalty = hintsUsed * 5;
    final int collectionBonus = collectedElements.length * 5;
    final int streakBonus = maxComboStreak * 10;
    return max(0, score - hintPenalty + collectionBonus + streakBonus);
  }

  void _syncSessionStats() {
    _sessionStats['totalDiscoveries'] = _sessionStats['sessionDiscoveries'];
    _sessionStats['collected'] = collectedElements.length;
    _sessionStats['maxStreak'] = maxComboStreak;
    _sessionStats['hintsUsed'] = hintsUsed;
    _sessionStats['levelsCompleted'] = currentLevel;
    _sessionStats['fastestLevel'] = fastestLevelTime;
    if (widget.gameMode == GameMode.photosynthesis) {
      _sessionStats['photoCompleted'] =
          isStageComplete || currentLevel > levelData.length;
    } else {
      _sessionStats['matterCompleted'] =
          isStageComplete || currentLevel > levelData.length;
    }
  }

  Future<void> _saveScoreToFirebase(int finalScore) async {
    await FirebaseLeaderboardService.saveScore(
      gameName: FirebaseLeaderboardService.GAME_SCIENCE_FUSION,
      score: finalScore,
      metadata: {
        'gameMode': widget.gameMode.name,
        'levelsCompleted': currentLevel,
        'discoveredElements': discoveredElements.length,
        'collectedElements': collectedElements.length,
        'maxStreak': maxComboStreak,
        'hintsUsed': hintsUsed,
        'fastestLevel': fastestLevelTime,
      },
    );
  }

  Future<void> _checkAndShowAchievements() async {
    _syncSessionStats();
    final newAchs = await GameAchievementService.checkNewAchievements(
      username: widget.username,
      gameId: GameAchievementService.GAME_FUSION,
      stats: Map<String, dynamic>.from(_sessionStats),
    );

    if (newAchs.isNotEmpty && mounted) {
      _showAchievementUnlockBanner(newAchs);
    }
  }

  void _showAchievementUnlockBanner(List<GameAchievement> achs) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Text("🏆", style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text(
                  "Achievements Unlocked!",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
                  achs
                      .map(
                        (a) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: a.color.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: a.color.withOpacity(0.6),
                                ),
                              ),
                              child: Text(
                                a.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Awesome!"),
              ),
            ],
          ),
    );
  }

  void _completeGame() async {
    final int finalScore = _calcFinalScore();
    final bool isNewHighScore = finalScore > highScore;
    final int maxScore = (levelData.length * 40 * 6) + 200;

    HapticFeedback.heavyImpact();

    _syncSessionStats();
    await _saveScoreToFirebase(finalScore);
    await _checkAndShowAchievements();
    await _loadHighScore();

    if (!mounted) return;

    _showMessage(
      isNewHighScore
          ? "🏆 NEW HIGH SCORE!\nFinal Score: $finalScore"
          : "🏆 Game Complete!\nFinal Score: $finalScore",
      isNewHighScore ? Colors.amber : Colors.greenAccent,
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _showCompletionDialog(finalScore, maxScore, isNewHighScore);
  }

  void _showCompletionDialog(
    int finalScore,
    int maxScore,
    bool isNewHighScore,
  ) {
    final int percentage = ((finalScore / maxScore) * 100).round();
    final String rank =
        percentage >= 90
            ? "🏆 Master Scientist!"
            : percentage >= 75
            ? "🥇 Expert Scientist!"
            : percentage >= 60
            ? "🥈 Great Scientist!"
            : "🥉 Good Scientist!";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                const Text("🎉", style: TextStyle(fontSize: 60)),
                const SizedBox(height: 10),
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
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$finalScore / $maxScore",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$percentage% Perfect",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        if (isNewHighScore) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
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
                          const SizedBox(height: 8),
                          Text(
                            "Personal Best: $highScore",
                            style: TextStyle(
                              color: Colors.amber.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white30),
                        const SizedBox(height: 10),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  AudioService.stopBackgroundMusic();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
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
                child: const Text(
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      _showMessage(
        "❌ Can't combine element with itself!",
        Colors.orangeAccent,
        isError: true,
      );
      return;
    }

    if (isStageComplete) {
      _showMessage(
        "✅ Level complete! Choose to quit or continue!",
        Colors.greenAccent,
      );
      return;
    }

    String? result;
    allAvailableCombos.forEach((key, value) {
      final parts = key.split('+');
      if (parts.contains(target) && parts.contains(dragged)) result = value;
    });

    if (result != null) {
      if (!discoveredElements.contains(result)) {
        HapticFeedback.mediumImpact();
        AudioService.playSoundEffect('pop.wav');

        setState(() {
          discoveredElements.add(result!);
          score += 10;
          comboStreak++;
          maxComboStreak = max(maxComboStreak, comboStreak);
          _celebrationController.forward(from: 0);

          // Update session stats
          _sessionStats['sessionDiscoveries'] =
              (_sessionStats['sessionDiscoveries'] as int) + 1;
          _sessionStats['totalDiscoveries'] =
              _sessionStats['sessionDiscoveries'];
          _sessionStats['sessionMaxStreak'] = maxComboStreak;
          _sessionStats['maxStreak'] = maxComboStreak;

          if (currentLevelTargets.contains(result)) {
            if (result == targetElement) {
              final int streakBonus = comboStreak * 5;
              score += 30 + streakBonus;
              _sessionStats['sessionTargetsFound'] =
                  (_sessionStats['sessionTargetsFound'] as int) + 1;
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
            Future.delayed(const Duration(milliseconds: 500), () {
              if (isStageComplete) {
                _showLevelCompleteOptions();
              } else {
                _pickNewTarget();
              }
            });
          } else {
            _showMessage(
              "✨ New element: $result\n+10 pts • 💡 Tap to collect for +5 pts bonus!",
              Colors.lightBlueAccent,
            );
          }
        });
      } else {
        HapticFeedback.lightImpact();
        AudioService.playSoundEffect('hardpop.wav');
        _showMessage(
          "⚠️ Already discovered! Try different combinations.",
          Colors.orangeAccent,
          isError: true,
        );
        setState(() {
          comboStreak = max(0, comboStreak - 1);
        });
      }
    } else {
      HapticFeedback.lightImpact();
      AudioService.playSoundEffect('hardpop.wav');
      _showMessage(
        "❌ $target + $dragged don't combine\nTry different elements!",
        Colors.redAccent,
        isError: true,
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
        _sessionStats['sessionCollected'] =
            (_sessionStats['sessionCollected'] as int) + 1;
        _sessionStats['collected'] = collectedElements.length;
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
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Text(info['emoji'], style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    element,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (info['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                info['info'] ?? 'No information available',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Got it!",
                  style: TextStyle(color: Colors.amber),
                ),
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
    String? hint;
    allAvailableCombos.forEach((key, value) {
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
        _sessionStats['hintsUsed'] = hintsUsed;
      });
      AudioService.playSoundEffect('hint.wav');
      _showMessage("💡 Hint (-5 pts):\n$hint", Colors.yellowAccent);
    } else {
      _showMessage(
        "💡 Hint: Try combining different elements!",
        Colors.blueAccent,
      );
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final steps = [
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
            final step = steps[tutorialStep];
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1F3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(step['icon'] as IconData, color: Colors.amber, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    step['title'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step['content'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              i == tutorialStep ? Colors.amber : Colors.white24,
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
                    onPressed: () => setDialogState(() => tutorialStep--),
                    child: const Text(
                      "Back",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                if (tutorialStep < steps.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => setDialogState(() => tutorialStep++),
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.black),
                    ),
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
                      setState(() => showTutorial = false);
                    },
                    child: const Text(
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

  void _showMessage(String text, Color color, {bool isError = false}) {
    _activeNotification?.remove();
    _activeNotification = null;
    if (isError) {
      HapticFeedback.lightImpact();
      _shakeController.forward(from: 0);
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (ctx) => _NotificationToast(
            text: text,
            color: color,
            isError: isError,
            shakeAnimation: isError ? _shakeAnimation : null,
            onDismiss: () {
              entry.remove();
              if (_activeNotification == entry) _activeNotification = null;
            },
          ),
    );
    _activeNotification = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final int requiredDiscoveries =
        levelData[currentLevel - 1]['requiredDiscoveries'];
    final int discoveredCount = currentLevelDiscoveredTargetCount;
    final double progress =
        requiredDiscoveries > 0 ? discoveredCount / requiredDiscoveries : 0.0;
    final Color appBarColor =
        widget.gameMode == GameMode.photosynthesis
            ? Colors.green.shade700
            : Colors.blue.shade700;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            AudioService.stopBackgroundMusic();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Level $currentLevel: ${levelData[currentLevel - 1]['title']}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _isPaused ? "Resume" : "Pause",
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _isPaused ? null : _showHint,
            tooltip: "Get Hint (-5 pts)",
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.collections_bookmark),
                if (collectedElements.length < discoveredElements.length)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
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
            onPressed:
                _isPaused
                    ? null
                    : () => setState(
                      () => showCollectionPanel = !showCollectionPanel,
                    ),
            tooltip:
                "Collection (${collectedElements.length}/${discoveredElements.length})",
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              tutorialStep = 0;
              _showTutorialDialog();
            },
            tooltip: "Show Tutorial",
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
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
                              style: const TextStyle(
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
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          "Progress: $discoveredCount/$requiredDiscoveries",
                          style: const TextStyle(
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
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Hints: $hintsUsed",
                              style: const TextStyle(
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
              if (showCollectionPanel) _buildCollectionPanel(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade700),
                  ),
                  child: Text(
                    levelData[currentLevel - 1]['description'],
                    style: const TextStyle(
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
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1F3E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.shade300,
                              width: 2,
                            ),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: discoveredElements.length,
                            itemBuilder:
                                (context, index) => _draggableDiscoveredTile(
                                  discoveredElements[index],
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // PAUSE OVERLAY
          if (_isPaused)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(28),
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
                        "Paused",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          onPressed: _togglePause,
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
                            setState(() => _isPaused = false);
                            AudioService.stopBackgroundMusic();
                            Navigator.pop(context);
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

  Widget _buildTargetDisplay() {
    // If stage complete but there's a next level, the dialog handles it —
    // just show a waiting message while the dialog is about to appear.
    if (isStageComplete) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "✅ Level Complete!",
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (targetElement == null) {
      return const SizedBox.shrink();
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

  Widget _buildCollectionPanel() {
    final uncollected =
        discoveredElements
            .where((e) => !collectedElements.contains(e))
            .toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
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
              const Text(
                "📦 Element Collection",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${collectedElements.length}/${discoveredElements.length}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (uncollected.isEmpty)
            const Center(
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
                      uncollected
                          .map(
                            (element) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _collectElement(element),
                                child: Stack(
                                  children: [
                                    _tile(
                                      element,
                                      size: 70,
                                      showInfoButton: true,
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Center(
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
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
        ],
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
    final bool isCollected = collectedElements.contains(text);

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
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: size * 0.28)),
                const SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showInfoButton ? 6 : 2,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.12,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCollected && !baseElements.contains(text))
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          if (showInfoButton && !baseElements.contains(text))
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showElementInfo(text);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 11,
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
  final String? username;
  const ScienceFusionLeaderboard({this.username});

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
        decoration: const BoxDecoration(
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                selectedGame == "photosynthesis"
                                    ? Colors.green
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Text(
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                selectedGame == "matter_changes"
                                    ? Colors.blue
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Text(
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
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<String?>(
                  future: UniversalLeaderboardService.getCurrentUsername(),
                  builder: (context, usernameSnapshot) {
                    final currentUsername =
                        usernameSnapshot.data ?? widget.username;
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: UniversalLeaderboardService.getGameLeaderboard(
                        gameId: selectedGame,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
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
    final Color themeColor =
        selectedGame == "photosynthesis" ? Colors.green : Colors.blue;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final score = leaderboard[index];
        final bool isCurrentUser = score['username'] == currentUsername;
        final String medal =
            index == 0
                ? "🥇"
                : index == 1
                ? "🥈"
                : index == 2
                ? "🥉"
                : "";
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
              SizedBox(
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
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          score['username'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Collected: ${score['metadata']?['collectedElements'] ?? 'N/A'}",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          " • ",
                          style: TextStyle(color: Colors.white60),
                        ),
                        Text(
                          "Streak: ${score['metadata']?['maxStreak'] ?? 'N/A'}x",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
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
                  const Text(
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
    return const Center(
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
// UNIVERSAL LEADERBOARD SERVICE
// ============================================================================

class UniversalLeaderboardService {
  static const String _allScoresKey = 'universal_all_scores';
  static const String _userStatsKey = 'universal_user_stats';

  static Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("username");
  }

  static Future<void> saveScore({
    required String username,
    required String gameId,
    required String category,
    required int score,
    required int maxScore,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final allScores = await _getAllScores();
    final int points = ((score / maxScore) * 100).round();
    allScores.add({
      'username': username,
      'gameId': gameId,
      'category': category,
      'score': score,
      'maxScore': maxScore,
      'points': points,
      'percentage': points,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    });
    await prefs.setString(_allScoresKey, jsonEncode(allScores));
    await _updateUserStats(username);
  }

  static Future<List<Map<String, dynamic>>> _getAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_allScoresKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getGameLeaderboard({
    String? gameId,
    String? category,
    int? limit,
  }) async {
    var scores = await _getAllScores();
    if (gameId != null)
      scores = scores.where((s) => s['gameId'] == gameId).toList();
    if (category != null)
      scores = scores.where((s) => s['category'] == category).toList();
    scores.sort((a, b) {
      final int c = b['percentage'].compareTo(a['percentage']);
      if (c != 0) return c;
      return DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp']));
    });
    if (limit != null && scores.length > limit)
      scores = scores.sublist(0, limit);
    return scores;
  }

  static Future<List<Map<String, dynamic>>> getOverallLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_userStatsKey);
    if (json == null) return [];
    final Map<String, dynamic> all = jsonDecode(json);
    final list = all.values.map((v) => Map<String, dynamic>.from(v)).toList();
    list.sort((a, b) => b['totalPoints'].compareTo(a['totalPoints']));
    return list;
  }

  static Future<Map<String, dynamic>?> getUserStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_userStatsKey);
    if (json == null) return null;
    return (jsonDecode(json) as Map<String, dynamic>)[username];
  }

  static Future<void> _updateUserStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final scores =
        (await _getAllScores())
            .where((s) => s['username'] == username)
            .toList();
    if (scores.isEmpty) return;
    final int total = scores.fold(0, (s, e) => s + (e['points'] as int));
    final double avg = total / scores.length;
    final String? statsJson = prefs.getString(_userStatsKey);
    final Map<String, dynamic> all =
        statsJson != null
            ? Map<String, dynamic>.from(jsonDecode(statsJson))
            : {};
    all[username] = {
      'username': username,
      'totalGames': scores.length,
      'totalPoints': total,
      'averagePercentage': avg.round(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_userStatsKey, jsonEncode(all));
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_allScoresKey);
    await prefs.remove(_userStatsKey);
  }
}
