import 'package:flutter/material.dart';
import 'dart:async';
import 'package:elearningapp_flutter/screens/analytics_screen.dart';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';
import 'package:elearningapp_flutter/services/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';

// ============================================================================
// QUIZ-SPECIFIC ACHIEVEMENT + MISSION MODELS
// ============================================================================

enum QuizAchievementTier { bronze, silver, gold }

class QuizAchievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final QuizAchievementTier tier;
  final Color color;
  final bool Function(Map<String, dynamic> stats) isUnlocked;

  const QuizAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.isUnlocked,
  });
}

class QuizMission {
  final String id;
  final String description;
  final int target;
  final String statKey;
  final int rewardPoints;

  const QuizMission({
    required this.id,
    required this.description,
    required this.target,
    required this.statKey,
    required this.rewardPoints,
  });
}

// ============================================================================
// QUIZ ACHIEVEMENTS (9 total — bronze / silver / gold tiers)
// ============================================================================

const List<QuizAchievement> kQuizAchievements = [
  QuizAchievement(
    id: 'quiz_first_answer',
    title: 'First Correct Answer',
    description: 'Answer your first question correctly',
    emoji: '✅',
    tier: QuizAchievementTier.bronze,
    color: Color(0xFFFF8C00),
    isUnlocked: _quizFirstAnswer,
  ),
  QuizAchievement(
    id: 'quiz_streak_3',
    title: 'On a Roll',
    description: 'Get 3 correct answers in a row',
    emoji: '🔥',
    tier: QuizAchievementTier.bronze,
    color: Color(0xFFFF5722),
    isUnlocked: _quizStreak3,
  ),
  QuizAchievement(
    id: 'quiz_streak_5',
    title: 'Hot Streak',
    description: 'Get 5 correct answers in a row',
    emoji: '🌟',
    tier: QuizAchievementTier.silver,
    color: Color(0xFFFFC107),
    isUnlocked: _quizStreak5,
  ),
  QuizAchievement(
    id: 'quiz_streak_10',
    title: 'Unstoppable',
    description: 'Get 10 correct answers in a row',
    emoji: '⚡',
    tier: QuizAchievementTier.gold,
    color: Color(0xFFFFEB3B),
    isUnlocked: _quizStreak10,
  ),
  QuizAchievement(
    id: 'quiz_perfect_topic',
    title: 'Topic Master',
    description: 'Score 100% on any topic',
    emoji: '🏆',
    tier: QuizAchievementTier.gold,
    color: Color(0xFFFFC107),
    isUnlocked: _quizPerfectTopic,
  ),
  QuizAchievement(
    id: 'quiz_all_topics',
    title: 'Science Scholar',
    description: 'Complete all 5 topics',
    emoji: '🎓',
    tier: QuizAchievementTier.gold,
    color: Color(0xFF9C27B0),
    isUnlocked: _quizAllTopics,
  ),
  QuizAchievement(
    id: 'quiz_speed_demon',
    title: 'Speed Demon',
    description: 'Answer a hard question in under 5 seconds',
    emoji: '💨',
    tier: QuizAchievementTier.silver,
    color: Color(0xFF03A9F4),
    isUnlocked: _quizSpeedDemon,
  ),
  QuizAchievement(
    id: 'quiz_hard_hero',
    title: 'Hard Mode Hero',
    description: 'Answer 5 hard questions correctly',
    emoji: '🦸',
    tier: QuizAchievementTier.silver,
    color: Color(0xFF3F51B5),
    isUnlocked: _quizHardHero,
  ),
  QuizAchievement(
    id: 'quiz_century',
    title: 'Century',
    description: 'Answer 100 questions correctly across all topics',
    emoji: '💯',
    tier: QuizAchievementTier.gold,
    color: Color(0xFF4CAF50),
    isUnlocked: _quizCentury,
  ),
];

bool _quizFirstAnswer(Map<String, dynamic> s) => (s['totalCorrect'] ?? 0) >= 1;
bool _quizStreak3(Map<String, dynamic> s) => (s['maxStreak'] ?? 0) >= 3;
bool _quizStreak5(Map<String, dynamic> s) => (s['maxStreak'] ?? 0) >= 5;
bool _quizStreak10(Map<String, dynamic> s) => (s['maxStreak'] ?? 0) >= 10;
bool _quizPerfectTopic(Map<String, dynamic> s) =>
    (s['perfectTopics'] ?? 0) >= 1;
bool _quizAllTopics(Map<String, dynamic> s) => (s['topicsCompleted'] ?? 0) >= 5;
bool _quizSpeedDemon(Map<String, dynamic> s) =>
    (s['fastHardAnswer'] ?? false) == true;
bool _quizHardHero(Map<String, dynamic> s) => (s['hardCorrect'] ?? 0) >= 5;
bool _quizCentury(Map<String, dynamic> s) => (s['totalCorrect'] ?? 0) >= 100;

// ============================================================================
// QUIZ MISSIONS (5 per session)
// ============================================================================

const List<QuizMission> kQuizMissions = [
  QuizMission(
    id: 'quiz_m1',
    description: 'Answer 3 questions correctly',
    target: 3,
    statKey: 'sessionCorrect',
    rewardPoints: 15,
  ),
  QuizMission(
    id: 'quiz_m2',
    description: 'Build a 3x streak',
    target: 3,
    statKey: 'sessionMaxStreak',
    rewardPoints: 20,
  ),
  QuizMission(
    id: 'quiz_m3',
    description: 'Answer 1 hard question correctly',
    target: 1,
    statKey: 'sessionHardCorrect',
    rewardPoints: 25,
  ),
  QuizMission(
    id: 'quiz_m4',
    description: 'Score 100% on a topic',
    target: 1,
    statKey: 'sessionPerfectTopics',
    rewardPoints: 50,
  ),
  QuizMission(
    id: 'quiz_m5',
    description: 'Answer 10 questions total',
    target: 10,
    statKey: 'sessionAnswered',
    rewardPoints: 30,
  ),
];

// ============================================================================
// QUIZ ACHIEVEMENT SERVICE
// ============================================================================

class QuizAchievementService {
  Future<void> initializeStudent(String username) async {}

  Future<List<QuizAchievement>> recordGameCompletion({
    required String username,
    required int score,
    required int maxScore,
    required Map<String, dynamic> metadata,
  }) async {
    final userId = await StudentCache.getUserId() ?? '';
    if (userId.isEmpty) return [];

    final stats = {
      'totalCorrect': score,
      'maxStreak': metadata['maxStreak'] ?? 0,
      'topicsCompleted': metadata['topicsCompleted'] ?? 0,
      'perfectTopics': score == maxScore ? 1 : 0,
      'hardCorrect': metadata['hardCorrect'] ?? 0,
      'fastHardAnswer': metadata['fastHardAnswer'] ?? false,
      ...metadata,
    };

    final doc = FirebaseFirestore.instance
        .collection('quiz_achievements')
        .doc(userId);
    final snap = await doc.get();
    final existing = List<String>.from(snap.data()?['unlocked'] ?? []);

    final newlyUnlocked = <QuizAchievement>[];
    for (final ach in kQuizAchievements) {
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

  Future<Set<String>> loadUnlocked(String username) async {
    final userId = await StudentCache.getUserId() ?? '';
    if (userId.isEmpty) return {};
    final snap =
        await FirebaseFirestore.instance
            .collection('quiz_achievements')
            .doc(userId)
            .get();
    return Set<String>.from(snap.data()?['unlocked'] ?? []);
  }
}

// ============================================================================
// MISSIONS PANEL WIDGET (Quiz-specific)
// ============================================================================

class QuizMissionsPanel extends StatefulWidget {
  final Map<String, dynamic> sessionStats;
  const QuizMissionsPanel({Key? key, required this.sessionStats})
    : super(key: key);

  @override
  State<QuizMissionsPanel> createState() => _QuizMissionsPanelState();
}

class _QuizMissionsPanelState extends State<QuizMissionsPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final done =
        kQuizMissions.where((m) {
          final v = widget.sessionStats[m.statKey] ?? 0;
          return (v is int ? v : 0) >= m.target;
        }).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.4),
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
                  const Text('🎯', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  const Text(
                    'Missions',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$done/${kQuizMissions.length}',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                children: kQuizMissions.map((m) => _missionRow(m)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _missionRow(QuizMission mission) {
    final raw = widget.sessionStats[mission.statKey] ?? 0;
    final int current = raw is bool ? (raw ? mission.target : 0) : (raw as int);
    final bool isDone = current >= mission.target;
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
                    color: isDone ? Colors.white38 : Colors.white70,
                    fontSize: 12,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isDone) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      color: Colors.purpleAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isDone ? '✓' : '$current/${mission.target}',
            style: TextStyle(
              color: isDone ? Colors.greenAccent : Colors.white38,
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

enum QuizDifficulty { easy, medium, hard }

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final QuizDifficulty difficulty;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.difficulty = QuizDifficulty.easy,
  });
}

// ============================================================================
// QUIZ DATA — 15 questions per topic (easy × 5, medium × 5, hard × 5)
// ============================================================================

class QuizData {
  static const Map<String, Map<String, dynamic>> topics = {};

  static final Map<String, Map<String, dynamic>> allTopics = {
    "Changes of Matter": {
      "icon": "🧪",
      "color": Color(0xFFFF6B9D),
      "questions": <QuizQuestion>[
        QuizQuestion(
          question: "What are the three main states of matter?",
          options: [
            "Hot, cold, warm",
            "Solid, liquid, gas",
            "Big, small, tiny",
            "Fast, slow, still",
          ],
          answer: "Solid, liquid, gas",
          explanation:
              "Matter exists as solid (fixed shape), liquid (flows), or gas (fills space).",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What happens when ice melts into water?",
          options: [
            "Chemical change",
            "Physical change",
            "No change",
            "Nuclear change",
          ],
          answer: "Physical change",
          explanation:
              "Melting is a physical change — the water molecules stay the same, only the state changes.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which state of matter has a definite shape and volume?",
          options: ["Gas", "Liquid", "Solid", "Plasma"],
          answer: "Solid",
          explanation:
              "Solids have particles packed tightly together, giving them a fixed shape and volume.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is it called when a liquid turns into a gas?",
          options: ["Freezing", "Melting", "Evaporation", "Condensation"],
          answer: "Evaporation",
          explanation:
              "Evaporation occurs when liquid molecules gain enough energy to escape as gas.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which is an example of a physical change?",
          options: [
            "Burning wood",
            "Rusting iron",
            "Cutting paper",
            "Cooking an egg",
          ],
          answer: "Cutting paper",
          explanation:
              "Cutting paper only changes shape — no new substance is formed, making it physical.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which is an example of a chemical change?",
          options: [
            "Boiling water",
            "Cutting paper",
            "Burning wood",
            "Melting chocolate",
          ],
          answer: "Burning wood",
          explanation:
              "Burning wood creates new substances (ash, CO₂, water vapor) — a chemical change.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "When water vapor becomes water droplets, this is called?",
          options: ["Evaporation", "Condensation", "Freezing", "Melting"],
          answer: "Condensation",
          explanation:
              "Condensation is when water vapor cools and changes back into liquid water.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What happens to particles in matter when it is heated?",
          options: [
            "They stop moving",
            "They move faster",
            "They shrink",
            "They disappear",
          ],
          answer: "They move faster",
          explanation:
              "Heat gives particles more energy, causing them to vibrate and move faster.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What sign indicates a chemical change has occurred?",
          options: [
            "Change of shape",
            "Change of size",
            "Production of gas or new smell",
            "Change of location",
          ],
          answer: "Production of gas or new smell",
          explanation:
              "Chemical changes produce new substances — often seen as gas, color change, or new smell.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "Which process describes gas turning directly into a solid without becoming liquid?",
          options: ["Evaporation", "Condensation", "Deposition", "Sublimation"],
          answer: "Deposition",
          explanation:
              "Deposition is the reverse of sublimation — gas converts directly to solid (e.g., frost formation).",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "A substance changes from solid to gas without passing through liquid state. This is called?",
          options: ["Evaporation", "Sublimation", "Deposition", "Condensation"],
          answer: "Sublimation",
          explanation:
              "Sublimation skips the liquid phase — dry ice (solid CO₂) sublimates directly into gas.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Which best explains why a liquid takes the shape of its container?",
          options: [
            "Its particles are fixed in place",
            "Its particles move freely but stay close together",
            "Its particles are far apart and move randomly",
            "It has no definite volume",
          ],
          answer: "Its particles move freely but stay close together",
          explanation:
              "Liquid particles can slide past each other (taking container shape) but cohesion keeps volume fixed.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "What is the term for the energy required to change a solid into a liquid at its melting point?",
          options: [
            "Specific heat",
            "Latent heat of fusion",
            "Latent heat of vaporization",
            "Thermal energy",
          ],
          answer: "Latent heat of fusion",
          explanation:
              "Latent heat of fusion is absorbed during melting without changing temperature.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Iron rusting is a chemical change because:",
          options: [
            "Iron changes color only",
            "Iron changes shape",
            "A new substance (iron oxide) is formed",
            "Iron gets smaller",
          ],
          answer: "A new substance (iron oxide) is formed",
          explanation:
              "Rust (iron oxide Fe₂O₃) is a completely new compound — a classic chemical change.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Which of these is NOT a sign of a chemical change?",
          options: [
            "Color change",
            "Gas production",
            "Change of state",
            "Light or heat release",
          ],
          answer: "Change of state",
          explanation:
              "Change of state (melting, freezing) is a physical change — no new substance is formed.",
          difficulty: QuizDifficulty.hard,
        ),
      ],
    },

    "Photosynthesis": {
      "icon": "🌱",
      "color": Color(0xFF4CAF50),
      "questions": <QuizQuestion>[
        QuizQuestion(
          question: "What do plants need for photosynthesis?",
          options: [
            "Sunlight, water, CO₂",
            "Only water",
            "Only sunlight",
            "Soil and air",
          ],
          answer: "Sunlight, water, CO₂",
          explanation:
              "Plants combine sunlight (energy), water (H₂O), and carbon dioxide (CO₂) to make food.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What gas do plants release during photosynthesis?",
          options: ["Carbon dioxide", "Nitrogen", "Oxygen", "Hydrogen"],
          answer: "Oxygen",
          explanation:
              "Plants split water molecules during photosynthesis, releasing oxygen as a byproduct.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What gives plants their green color?",
          options: ["Water", "Chlorophyll", "Sunlight", "Roots"],
          answer: "Chlorophyll",
          explanation:
              "Chlorophyll is the green pigment in chloroplasts that captures light energy.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Where does photosynthesis mainly occur in plants?",
          options: ["Roots", "Stem", "Leaves", "Flowers"],
          answer: "Leaves",
          explanation:
              "Leaves are flat and wide to capture maximum sunlight, making them the main photosynthesis site.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question:
              "What is the main food product plants make during photosynthesis?",
          options: ["Water", "Oxygen", "Glucose", "Carbon dioxide"],
          answer: "Glucose",
          explanation:
              "Glucose (sugar) is the energy-rich food product that plants make and store.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is the role of chlorophyll in photosynthesis?",
          options: [
            "Absorb water",
            "Absorb light energy",
            "Release carbon dioxide",
            "Produce oxygen",
          ],
          answer: "Absorb light energy",
          explanation:
              "Chlorophyll absorbs red and blue light, reflecting green — which is why plants look green.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "Which part of the plant cell contains chlorophyll?",
          options: ["Mitochondria", "Nucleus", "Chloroplast", "Cell wall"],
          answer: "Chloroplast",
          explanation:
              "Chloroplasts are organelles that contain chlorophyll and are the site of photosynthesis.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "What gas do plants absorb from the air during photosynthesis?",
          options: ["Oxygen", "Nitrogen", "Carbon dioxide", "Hydrogen"],
          answer: "Carbon dioxide",
          explanation:
              "Plants take in CO₂ through tiny pores called stomata in their leaves.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What would happen to a plant kept in complete darkness?",
          options: [
            "It would grow faster",
            "It would photosynthesize more",
            "It would eventually die",
            "Nothing would happen",
          ],
          answer: "It would eventually die",
          explanation:
              "Without light, photosynthesis stops. The plant can't make food and will starve.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "Through which tiny pores do leaves take in CO₂ and release O₂?",
          options: ["Veins", "Stomata", "Roots", "Xylem"],
          answer: "Stomata",
          explanation:
              "Stomata are tiny pores on leaves controlled by guard cells — they regulate gas exchange.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "The chemical equation for photosynthesis is: 6CO₂ + 6H₂O + light → __ + 6O₂",
          options: ["C₆H₁₂O₆", "CO₂", "H₂O₂", "CH₄"],
          answer: "C₆H₁₂O₆",
          explanation:
              "C₆H₁₂O₆ is glucose — the sugar plants produce using carbon dioxide, water, and light energy.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Which two stages make up photosynthesis?",
          options: [
            "Day stage and night stage",
            "Light-dependent and light-independent reactions",
            "Absorption and release",
            "Growth and decay",
          ],
          answer: "Light-dependent and light-independent reactions",
          explanation:
              "Light reactions capture energy; the Calvin cycle (light-independent) uses it to fix CO₂ into glucose.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Why do leaves appear green to our eyes?",
          options: [
            "They absorb green light",
            "They reflect green light",
            "They produce green gas",
            "They contain green water",
          ],
          answer: "They reflect green light",
          explanation:
              "Chlorophyll absorbs red and blue light for energy, but reflects green light — which we see.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Which factor does NOT directly affect the rate of photosynthesis?",
          options: [
            "Light intensity",
            "CO₂ concentration",
            "Soil texture",
            "Temperature",
          ],
          answer: "Soil texture",
          explanation:
              "Light intensity, CO₂, and temperature all affect enzyme activity in photosynthesis. Soil texture does not.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Where in the chloroplast do the light-dependent reactions occur?",
          options: ["Stroma", "Thylakoid membrane", "Cell wall", "Vacuole"],
          answer: "Thylakoid membrane",
          explanation:
              "Thylakoids are membrane-bound compartments where chlorophyll captures light energy.",
          difficulty: QuizDifficulty.hard,
        ),
      ],
    },

    "Solar System": {
      "icon": "🌍",
      "color": Color(0xFF2196F3),
      "questions": <QuizQuestion>[
        QuizQuestion(
          question: "Which planet is closest to the Sun?",
          options: ["Venus", "Earth", "Mercury", "Mars"],
          answer: "Mercury",
          explanation:
              "Mercury is the innermost planet, completing one orbit around the Sun every 88 days.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which planet is known as the Red Planet?",
          options: ["Mars", "Venus", "Jupiter", "Saturn"],
          answer: "Mars",
          explanation:
              "Mars appears red due to iron oxide (rust) covering its surface.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is the largest planet in our solar system?",
          options: ["Saturn", "Neptune", "Jupiter", "Earth"],
          answer: "Jupiter",
          explanation:
              "Jupiter is so large that all other planets could fit inside it with room to spare.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "How many planets are in our solar system?",
          options: ["7", "8", "9", "10"],
          answer: "8",
          explanation:
              "There are 8 planets: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What do we call Earth's natural satellite?",
          options: ["The Sun", "The Moon", "A star", "An asteroid"],
          answer: "The Moon",
          explanation:
              "The Moon is Earth's only natural satellite, orbiting Earth every 27.3 days.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which planet has the most moons?",
          options: ["Jupiter", "Saturn", "Uranus", "Neptune"],
          answer: "Saturn",
          explanation:
              "Saturn has 146 confirmed moons as of 2024 — more than any other planet.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "What is the correct order of the inner planets from the Sun?",
          options: [
            "Mercury, Mars, Venus, Earth",
            "Mercury, Venus, Earth, Mars",
            "Venus, Mercury, Earth, Mars",
            "Earth, Venus, Mercury, Mars",
          ],
          answer: "Mercury, Venus, Earth, Mars",
          explanation:
              "The four inner (terrestrial) planets in order: Mercury, Venus, Earth, Mars.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is the Sun made of mainly?",
          options: [
            "Rock and metal",
            "Ice and dust",
            "Hydrogen and helium",
            "Carbon and oxygen",
          ],
          answer: "Hydrogen and helium",
          explanation:
              "The Sun is 73% hydrogen and 25% helium, fusing hydrogen into helium to produce energy.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "What is the name of the force that keeps planets in orbit around the Sun?",
          options: ["Magnetism", "Friction", "Gravity", "Electricity"],
          answer: "Gravity",
          explanation:
              "Gravity is the attractive force between masses — the Sun's gravity keeps planets in orbit.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "Which planet has a Great Red Spot?",
          options: ["Mars", "Saturn", "Neptune", "Jupiter"],
          answer: "Jupiter",
          explanation:
              "Jupiter's Great Red Spot is a massive storm that has lasted for hundreds of years.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is an astronomical unit (AU)?",
          options: [
            "The diameter of Earth",
            "The average distance from Earth to the Sun",
            "The distance light travels in one year",
            "The radius of the Milky Way",
          ],
          answer: "The average distance from Earth to the Sun",
          explanation:
              "1 AU = about 150 million km — used as a convenient unit for solar system distances.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Why does Mercury have extreme temperature differences between day and night?",
          options: [
            "It spins very fast",
            "It has no atmosphere to retain heat",
            "It is too close to the Sun",
            "It has too many craters",
          ],
          answer: "It has no atmosphere to retain heat",
          explanation:
              "Without an atmosphere, Mercury can't trap heat — day temps reach 430°C, nights drop to -180°C.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Which of these is classified as a dwarf planet?",
          options: ["Europa", "Titan", "Pluto", "Ganymede"],
          answer: "Pluto",
          explanation:
              "Pluto was reclassified as a dwarf planet in 2006 because it hasn't cleared its orbital neighborhood.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "What causes the seasons on Earth?",
          options: [
            "Earth's distance from the Sun",
            "The Moon's orbit",
            "Earth's axial tilt",
            "Sunspot activity",
          ],
          answer: "Earth's axial tilt",
          explanation:
              "Earth is tilted 23.5° — as it orbits the Sun, different hemispheres receive more direct sunlight.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "What is the Kuiper Belt?",
          options: [
            "A ring around Saturn",
            "A region of icy bodies beyond Neptune",
            "The asteroid belt between Mars and Jupiter",
            "A band of stars around the Milky Way",
          ],
          answer: "A region of icy bodies beyond Neptune",
          explanation:
              "The Kuiper Belt is a disk of icy objects beyond Neptune — the source of many short-period comets.",
          difficulty: QuizDifficulty.hard,
        ),
      ],
    },

    "Ecosystem & Food Web": {
      "icon": "🦁",
      "color": Color(0xFFFF9800),
      "questions": <QuizQuestion>[
        QuizQuestion(
          question: "What are organisms that make their own food called?",
          options: ["Consumers", "Producers", "Decomposers", "Predators"],
          answer: "Producers",
          explanation:
              "Producers (mainly plants) use photosynthesis to make their own food from sunlight.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Which organism breaks down dead plants and animals?",
          options: ["Producers", "Herbivores", "Decomposers", "Carnivores"],
          answer: "Decomposers",
          explanation:
              "Decomposers (fungi, bacteria) break down dead matter, recycling nutrients back to the soil.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "A rabbit eating grass is an example of a?",
          options: ["Carnivore", "Herbivore", "Omnivore", "Decomposer"],
          answer: "Herbivore",
          explanation:
              "Herbivores eat only plants. Rabbits are primary consumers that feed on grass.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Where does all energy in a food web start?",
          options: ["Animals", "The Sun", "Soil", "Water"],
          answer: "The Sun",
          explanation:
              "The Sun is the ultimate energy source — plants capture it and pass it up the food chain.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "An animal that hunts and eats other animals is called a?",
          options: ["Prey", "Herbivore", "Predator", "Producer"],
          answer: "Predator",
          explanation:
              "Predators hunt prey for food. Lions, eagles, and sharks are all predators.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is a food chain?",
          options: [
            "A restaurant menu",
            "Path of energy through organisms",
            "A type of plant",
            "A cooking method",
          ],
          answer: "Path of energy through organisms",
          explanation:
              "A food chain shows how energy flows from one organism to another through eating.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "Which level of a food chain has the most energy?",
          options: [
            "Top predators",
            "Secondary consumers",
            "Primary consumers",
            "Producers",
          ],
          answer: "Producers",
          explanation:
              "Only about 10% of energy transfers to the next level — producers have the most total energy.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What would happen if all decomposers disappeared?",
          options: [
            "Plants would grow faster",
            "Dead matter would pile up and nutrients wouldn't recycle",
            "Animals would multiply",
            "Nothing would change",
          ],
          answer: "Dead matter would pile up and nutrients wouldn't recycle",
          explanation:
              "Decomposers are essential for nutrient cycling — without them ecosystems would collapse.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "An animal that eats both plants and animals is called?",
          options: ["Herbivore", "Carnivore", "Omnivore", "Decomposer"],
          answer: "Omnivore",
          explanation:
              "Omnivores have flexible diets — humans, bears, and crows are common examples.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is a habitat?",
          options: [
            "What an animal eats",
            "The natural home of an organism",
            "A type of predator",
            "A food chain diagram",
          ],
          answer: "The natural home of an organism",
          explanation:
              "A habitat provides food, shelter, and other conditions an organism needs to survive.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What happens to 90% of energy at each trophic level?",
          options: [
            "It is stored",
            "It is lost as heat",
            "It is converted to protein",
            "It is recycled",
          ],
          answer: "It is lost as heat",
          explanation:
              "The 10% rule: only 10% of energy passes to the next trophic level; 90% is lost as heat.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "What is a niche in ecology?",
          options: [
            "A type of habitat",
            "The role and position an organism has in its ecosystem",
            "A food web diagram",
            "The number of organisms in a population",
          ],
          answer: "The role and position an organism has in its ecosystem",
          explanation:
              "A niche includes what an organism eats, where it lives, and how it interacts with others.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Which best describes a keystone species?",
          options: [
            "The most common species in an ecosystem",
            "A species whose removal causes dramatic ecosystem change",
            "The largest predator in an ecosystem",
            "A species that only eats plants",
          ],
          answer: "A species whose removal causes dramatic ecosystem change",
          explanation:
              "Keystone species have outsized impact relative to their abundance — e.g., sea otters controlling sea urchin populations.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "Mutualism in an ecosystem refers to?",
          options: [
            "One species benefits while the other is harmed",
            "Both species benefit from their relationship",
            "One species benefits while the other is unaffected",
            "Both species are harmed",
          ],
          answer: "Both species benefit from their relationship",
          explanation:
              "Mutualism: both benefit (e.g., clownfish and sea anemone). Compare with parasitism and commensalism.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "What is biomagnification?",
          options: [
            "Plants growing larger over time",
            "Increase of toxins at higher trophic levels",
            "Decomposers breaking down large organisms",
            "Animals migrating to new habitats",
          ],
          answer: "Increase of toxins at higher trophic levels",
          explanation:
              "Toxins (like mercury) accumulate and concentrate as they move up the food chain — apex predators are most affected.",
          difficulty: QuizDifficulty.hard,
        ),
      ],
    },

    "Water Cycle": {
      "icon": "💧",
      "color": Color(0xFF00BCD4),
      "questions": <QuizQuestion>[
        QuizQuestion(
          question: "What is it called when water turns into water vapor?",
          options: [
            "Condensation",
            "Precipitation",
            "Evaporation",
            "Collection",
          ],
          answer: "Evaporation",
          explanation:
              "Evaporation is when liquid water absorbs heat energy and changes into water vapor (gas).",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is rain, snow, sleet, and hail called?",
          options: [
            "Evaporation",
            "Condensation",
            "Precipitation",
            "Collection",
          ],
          answer: "Precipitation",
          explanation:
              "Precipitation is any form of water that falls from clouds to Earth's surface.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "Where does most evaporation on Earth occur?",
          options: ["Mountains", "Oceans", "Forests", "Cities"],
          answer: "Oceans",
          explanation:
              "Oceans cover 71% of Earth's surface and are responsible for about 90% of water evaporation.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What are clouds made of?",
          options: ["Cotton", "Water droplets", "Air", "Dust"],
          answer: "Water droplets",
          explanation:
              "Clouds form when water vapor cools and condenses around tiny dust particles to form droplets.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What powers the water cycle?",
          options: ["Wind", "The Sun", "Gravity", "Plants"],
          answer: "The Sun",
          explanation:
              "The Sun's heat energy drives evaporation, which is the first step of the water cycle.",
          difficulty: QuizDifficulty.easy,
        ),
        QuizQuestion(
          question: "What is transpiration in the water cycle?",
          options: [
            "Water falling as rain",
            "Water released by plants into the air",
            "Water flowing into rivers",
            "Water freezing into ice",
          ],
          answer: "Water released by plants into the air",
          explanation:
              "Transpiration is when plants release water vapor through their stomata — contributing to evapotranspiration.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is groundwater?",
          options: [
            "Water in rivers",
            "Water stored in clouds",
            "Water stored in rocks and soil underground",
            "Water on Earth's surface",
          ],
          answer: "Water stored in rocks and soil underground",
          explanation:
              "Groundwater fills pores in rocks and soil, forming aquifers — a major freshwater source.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question:
              "What happens to rainwater that doesn't soak into the ground?",
          options: [
            "It evaporates immediately",
            "It becomes runoff",
            "It turns into snow",
            "It stays in clouds",
          ],
          answer: "It becomes runoff",
          explanation:
              "Surface runoff flows over land into streams and rivers, eventually reaching the ocean.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is condensation in the water cycle?",
          options: [
            "Water vapor turning into liquid water",
            "Liquid water turning into gas",
            "Water soaking into soil",
            "Water falling as rain",
          ],
          answer: "Water vapor turning into liquid water",
          explanation:
              "When water vapor cools, it condenses into liquid droplets — forming clouds and dew.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is infiltration in the water cycle?",
          options: [
            "Water evaporating from oceans",
            "Water seeping into the ground",
            "Water falling from clouds",
            "Water freezing in glaciers",
          ],
          answer: "Water seeping into the ground",
          explanation:
              "Infiltration is the process where water moves down through soil and rock to recharge groundwater.",
          difficulty: QuizDifficulty.medium,
        ),
        QuizQuestion(
          question: "What is the residence time of water in the atmosphere?",
          options: [
            "About 9 days",
            "About 1 year",
            "About 100 years",
            "About 3,000 years",
          ],
          answer: "About 9 days",
          explanation:
              "On average, water molecules remain in the atmosphere for about 9 days before precipitating.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Which process returns the most water to the atmosphere over land?",
          options: [
            "Evaporation from soil",
            "River evaporation",
            "Evapotranspiration from vegetation",
            "Industrial emissions",
          ],
          answer: "Evapotranspiration from vegetation",
          explanation:
              "Plants transpire enormous amounts of water — in forests, transpiration exceeds evaporation from soil.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question: "What is an aquifer?",
          options: [
            "A type of cloud",
            "An underground layer of rock that holds water",
            "A river that flows underground",
            "A glacier in a valley",
          ],
          answer: "An underground layer of rock that holds water",
          explanation:
              "Aquifers are porous rock formations that store groundwater — many cities rely on them for drinking water.",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "How does deforestation most directly affect the water cycle?",
          options: [
            "Increases evaporation from oceans",
            "Reduces transpiration and increases runoff",
            "Increases precipitation globally",
            "Has no significant effect",
          ],
          answer: "Reduces transpiration and increases runoff",
          explanation:
              "Without trees, transpiration decreases (less moisture in air) and runoff increases (soil erosion and flooding).",
          difficulty: QuizDifficulty.hard,
        ),
        QuizQuestion(
          question:
              "Water that has been on Earth since dinosaurs still cycles today. Why?",
          options: [
            "New water is constantly created",
            "Water is continuously recycled through the water cycle",
            "Water comes from space regularly",
            "Underground water never evaporates",
          ],
          answer: "Water is continuously recycled through the water cycle",
          explanation:
              "Earth has a fixed amount of water — the water cycle continuously recycles the same water molecules.",
          difficulty: QuizDifficulty.hard,
        ),
      ],
    },
  };
}

// ============================================================================
// QUIZ SCREEN WITH ACHIEVEMENTS
// ============================================================================

class QuizScreenWithAchievements extends StatefulWidget {
  final String role;
  final String username;

  const QuizScreenWithAchievements({
    Key? key,
    required this.role,
    required this.username,
  }) : super(key: key);

  @override
  State<QuizScreenWithAchievements> createState() =>
      _QuizScreenWithAchievementsState();
}

class _QuizScreenWithAchievementsState
    extends State<QuizScreenWithAchievements> {
  final QuizAchievementService _achievementService = QuizAchievementService();
  Set<String> completedTopics = {};
  Map<String, int> topicBestScores = {};

  // Session stats for missions panel
  final Map<String, dynamic> _sessionStats = {
    'sessionCorrect': 0,
    'sessionAnswered': 0,
    'sessionMaxStreak': 0,
    'sessionHardCorrect': 0,
    'sessionPerfectTopics': 0,
  };

  @override
  void initState() {
    super.initState();
    _achievementService.initializeStudent(widget.username);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAchievementDialog(List<QuizAchievement> newAchievements) {
    if (newAchievements.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🎉", style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    newAchievements.length == 1
                        ? "Achievement Unlocked!"
                        : "${newAchievements.length} Achievements Unlocked!",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...newAchievements.map(
                    (a) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: a.color, width: 2),
                      ),
                      child: Row(
                        children: [
                          Text(a.emoji, style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  a.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tierColor(a.tier).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _tierLabel(a.tier),
                                    style: TextStyle(
                                      color: _tierColor(a.tier),
                                      fontSize: 10,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Continue",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => IntegratedAnalyticsScreen(
                                      username: widget.username,
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Progress",
                            style: TextStyle(color: Colors.black, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _tierColor(QuizAchievementTier tier) {
    switch (tier) {
      case QuizAchievementTier.bronze:
        return Colors.brown;
      case QuizAchievementTier.silver:
        return Colors.blueGrey;
      case QuizAchievementTier.gold:
        return Colors.amber;
    }
  }

  String _tierLabel(QuizAchievementTier tier) {
    switch (tier) {
      case QuizAchievementTier.bronze:
        return '🥉 Bronze';
      case QuizAchievementTier.silver:
        return '🥈 Silver';
      case QuizAchievementTier.gold:
        return '🥇 Gold';
    }
  }

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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Text("🦉", style: TextStyle(fontSize: 46)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Grade 6 Science Quiz",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "15 questions per topic",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        AudioService.isMuted
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await AudioService.toggleMute();
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.analytics,
                        color: Colors.purple,
                        size: 28,
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => IntegratedAnalyticsScreen(
                                    username: widget.username,
                                  ),
                            ),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Missions panel
                QuizMissionsPanel(sessionStats: _sessionStats),
                const SizedBox(height: 12),

                // Topics
                Expanded(
                  child: ListView(
                    children:
                        QuizData.allTopics.entries.map((entry) {
                          final topicName = entry.key;
                          final questions =
                              entry.value["questions"] as List<QuizQuestion>;
                          final best = topicBestScores[topicName];
                          final isCompleted = completedTopics.contains(
                            topicName,
                          );

                          return _TopicCard(
                            title: topicName,
                            icon: entry.value["icon"] as String,
                            color: entry.value["color"] as Color,
                            questionCount: questions.length,
                            isCompleted: isCompleted,
                            bestScore: best,
                            onTap: () async {
                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => QuizPlayScreen(
                                        topic: topicName,
                                        questions: questions,
                                        color: entry.value["color"] as Color,
                                        role: widget.role,
                                        username: widget.username,
                                        onComplete: (
                                          score,
                                          max,
                                          maxStreak,
                                          hardCorrect,
                                          fastHardAnswer,
                                        ) async {
                                          if (score == max)
                                            completedTopics.add(topicName);
                                          if ((topicBestScores[topicName] ??
                                                  0) <
                                              score) {
                                            topicBestScores[topicName] = score;
                                          }

                                          // Update session stats for missions
                                          setState(() {
                                            _sessionStats['sessionCorrect'] =
                                                (_sessionStats['sessionCorrect']
                                                    as int) +
                                                score;
                                            _sessionStats['sessionAnswered'] =
                                                (_sessionStats['sessionAnswered']
                                                    as int) +
                                                max;
                                            _sessionStats['sessionMaxStreak'] = [
                                              _sessionStats['sessionMaxStreak']
                                                  as int,
                                              maxStreak,
                                            ].reduce((a, b) => a > b ? a : b);
                                            _sessionStats['sessionHardCorrect'] =
                                                (_sessionStats['sessionHardCorrect']
                                                    as int) +
                                                hardCorrect;
                                            if (score == max) {
                                              _sessionStats['sessionPerfectTopics'] =
                                                  (_sessionStats['sessionPerfectTopics']
                                                      as int) +
                                                  1;
                                            }
                                            if (fastHardAnswer)
                                              _sessionStats['fastHardAnswer'] =
                                                  true;
                                          });

                                          final userId =
                                              await StudentCache.getUserId() ??
                                              '';
                                          if (userId.isNotEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection('quiz_scores')
                                                .doc(userId)
                                                .set({
                                                  topicName: {
                                                    'bestScore': score,
                                                    'maxScore': max,
                                                    'lastPlayed':
                                                        FieldValue.serverTimestamp(),
                                                  },
                                                }, SetOptions(merge: true));
                                          }

                                          final newAchievements =
                                              await _achievementService
                                                  .recordGameCompletion(
                                                    username: widget.username,
                                                    score: score,
                                                    maxScore: max,
                                                    metadata: {
                                                      'topicsCompleted':
                                                          completedTopics
                                                              .length,
                                                      'topic': topicName,
                                                      'percentage':
                                                          ((score / max) * 100)
                                                              .toInt(),
                                                      'maxStreak': maxStreak,
                                                      'hardCorrect':
                                                          hardCorrect,
                                                      'fastHardAnswer':
                                                          fastHardAnswer,
                                                      'perfectTopics':
                                                          score == max ? 1 : 0,
                                                    },
                                                  );

                                          await FirebaseLeaderboardService.saveScore(
                                            gameName:
                                                FirebaseLeaderboardService
                                                    .GAME_QUIZ,
                                            score: score,
                                            metadata: {
                                              'topic': topicName,
                                              'maxScore': max,
                                              'percentage':
                                                  ((score / max) * 100).toInt(),
                                              'topicsCompleted':
                                                  completedTopics.length,
                                            },
                                          );

                                          if (newAchievements.isNotEmpty) {
                                            Future.delayed(
                                              const Duration(milliseconds: 500),
                                              () {
                                                if (mounted)
                                                  _showAchievementDialog(
                                                    newAchievements,
                                                  );
                                              },
                                            );
                                          }
                                        },
                                      ),
                                ),
                              );
                            },
                          );
                        }).toList(),
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

// ============================================================================
// TOPIC CARD
// ============================================================================

class _TopicCard extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final int questionCount;
  final bool isCompleted;
  final int? bestScore;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.questionCount,
    required this.onTap,
    this.isCompleted = false,
    this.bestScore,
  });

  String get _diffLabel =>
      questionCount >= 15 ? 'Easy · Medium · Hard' : '$questionCount Questions';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.55), color.withOpacity(0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "✓ 100%",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$questionCount Questions · $_diffLabel",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (bestScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Best: $bestScore/$questionCount pts",
                          style: TextStyle(
                            color: color.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUIZ PLAY SCREEN
// ============================================================================

class QuizPlayScreen extends StatefulWidget {
  final String topic;
  final List<QuizQuestion> questions;
  final Color color;
  final String role;
  final String username;
  final Function(
    int score,
    int maxScore,
    int maxStreak,
    int hardCorrect,
    bool fastHardAnswer,
  )
  onComplete;

  const QuizPlayScreen({
    required this.topic,
    required this.questions,
    required this.color,
    required this.role,
    required this.username,
    required this.onComplete,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _idx = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answerChecked = false;
  int _streak = 0;
  int _maxStreak = 0;
  int _timeLeft = 20;
  Timer? _timer;
  bool _timedOut = false;
  late AnimationController _timerAnim;
  int _hardCorrect = 0;
  bool _fastHardAnswer = false;
  int _questionStartTime = 0;
  bool _musicStartedHere = false;

  late final List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questions = [
      ...widget.questions.where((q) => q.difficulty == QuizDifficulty.easy),
      ...widget.questions.where((q) => q.difficulty == QuizDifficulty.medium),
      ...widget.questions.where((q) => q.difficulty == QuizDifficulty.hard),
    ];
    _timerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    AudioService.playBackgroundMusic('quiz.mp3');
    _musicStartedHere = true;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final q = _questions[_idx];
    _timeLeft =
        q.difficulty == QuizDifficulty.hard
            ? 30
            : q.difficulty == QuizDifficulty.medium
            ? 20
            : 15;
    _questionStartTime = _timeLeft;
    _timerAnim.duration = Duration(seconds: _timeLeft);
    _timerAnim.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        AudioService.playSoundEffect('timeout.mp3');
        setState(() {
          _timedOut = true;
          _answerChecked = true;
          _streak = 0;
        });
        Future.delayed(const Duration(seconds: 2), _advance);
      }
    });
  }

  void _selectAnswer(String answer) {
    if (_answerChecked) return;
    setState(() => _selectedAnswer = answer);
  }

  void _checkAnswer() {
    if (_selectedAnswer == null || _answerChecked) return;
    _timer?.cancel();
    _timerAnim.stop();
    final correct = _selectedAnswer == _questions[_idx].answer;
    final q = _questions[_idx];
    final timeUsed = _questionStartTime - _timeLeft;

    if (correct) {
      AudioService.playSoundEffect('correct.mp3');
    } else {
      AudioService.playSoundEffect('wrong.mp3');
    }

    setState(() {
      _answerChecked = true;
      _timedOut = false;
      if (correct) {
        _score += 1;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        if (q.difficulty == QuizDifficulty.hard) {
          _hardCorrect++;
          if (timeUsed < 5) _fastHardAnswer = true;
        }
      } else {
        _streak = 0;
      }
    });
    Future.delayed(const Duration(seconds: 2), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_idx < _questions.length - 1) {
      setState(() {
        _idx++;
        _selectedAnswer = null;
        _answerChecked = false;
        _timedOut = false;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      widget.onComplete(
        _score,
        _questions.length,
        _maxStreak,
        _hardCorrect,
        _fastHardAnswer,
      );
      _showResult();
    }
  }

  void _showResult() {
    final pct = (_score / _questions.length * 100).round().clamp(0, 100);
    final emoji =
        pct >= 80
            ? "🌟"
            : pct >= 60
            ? "🎉"
            : "💪";
    final msg =
        pct >= 80
            ? "Amazing work!"
            : pct >= 60
            ? "Great job!"
            : "Keep practicing!";

    if (!mounted) return;
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
                Text(emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  "Quiz Complete!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$_score / ${_questions.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$pct% Correct",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Best streak: $_maxStreak",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (pct == 100) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "🏆 Perfect Score!",
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  AudioService.stopBackgroundMusic();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  "Back to Topics",
                  style: TextStyle(color: widget.color, fontSize: 15),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _idx = 0;
                    _score = 0;
                    _selectedAnswer = null;
                    _answerChecked = false;
                    _streak = 0;
                    _maxStreak = 0;
                    _timedOut = false;
                    _hardCorrect = 0;
                    _fastHardAnswer = false;
                  });
                  _startTimer();
                },
                child: const Text(
                  "Try Again",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
    );
  }

  Color get _timerColor {
    if (_timeLeft > 10) return Colors.green;
    if (_timeLeft > 5) return Colors.orange;
    return Colors.red;
  }

  Color _difficultyColor(QuizDifficulty d) {
    switch (d) {
      case QuizDifficulty.easy:
        return Colors.green;
      case QuizDifficulty.medium:
        return Colors.orange;
      case QuizDifficulty.hard:
        return Colors.red;
    }
  }

  String _difficultyLabel(QuizDifficulty d) {
    switch (d) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_idx];
    final correctAnswer = q.answer;
    final maxTime =
        q.difficulty == QuizDifficulty.hard
            ? 30
            : q.difficulty == QuizDifficulty.medium
            ? 20
            : 15;

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        _timer?.cancel();
                        AudioService.stopBackgroundMusic();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        widget.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        AudioService.isMuted
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () async {
                        await AudioService.toggleMute();
                        setState(() {});
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "$_score pts",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress + streak
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: (_idx + 1) / _questions.length,
                            backgroundColor: Colors.white24,
                            color: widget.color,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Question ${_idx + 1} of ${_questions.length}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_streak >= 2) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$_streak streak!",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Timer + difficulty
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 10,
                            width:
                                MediaQuery.of(context).size.width *
                                (_timeLeft / maxTime).clamp(0.0, 1.0) *
                                0.7,
                            decoration: BoxDecoration(
                              color: _timerColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "$_timeLeft s",
                      style: TextStyle(
                        color: _timerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _difficultyColor(q.difficulty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _difficultyColor(
                            q.difficulty,
                          ).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _difficultyLabel(q.difficulty),
                        style: TextStyle(
                          color: _difficultyColor(q.difficulty),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F3E),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                if (_timedOut) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_off,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Time's up! Answer: $correctAnswer",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Options
                Expanded(
                  child: ListView(
                    children: [
                      ...q.options.map((opt) {
                        final isSelected = _selectedAnswer == opt;
                        final isCorrect = opt == correctAnswer;
                        final showCorrect = _answerChecked && isCorrect;
                        final showWrong =
                            _answerChecked && isSelected && !isCorrect;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectAnswer(opt),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      showCorrect
                                          ? Colors.green.withOpacity(0.25)
                                          : showWrong
                                          ? Colors.red.withOpacity(0.25)
                                          : isSelected
                                          ? widget.color.withOpacity(0.25)
                                          : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        showCorrect
                                            ? Colors.green
                                            : showWrong
                                            ? Colors.red
                                            : isSelected
                                            ? widget.color
                                            : Colors.white24,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (showCorrect)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                    if (showWrong)
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      if (_answerChecked && !_timedOut)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("💡 ", style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  q.explanation,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                if (!_answerChecked)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _selectedAnswer != null ? _checkAnswer : null,
                      child: const Text(
                        "Check Answer",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
