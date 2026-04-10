import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';

// ============================================================================
// GAME-SPECIFIC ACHIEVEMENT + MISSION SYSTEM
// Each game has its own isolated achievements and missions.
// Call GameAchievementService.forGame(gameId) to get the right instance.
// ============================================================================

enum AchievementTier { bronze, silver, gold }

class GameAchievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final Color color;
  final bool Function(Map<String, dynamic> stats) isUnlocked;

  const GameAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.color,
    required this.isUnlocked,
  });
}

class GameMission {
  final String id;
  final String description;
  final int target;
  final String statKey; // key in stats map to check
  final int rewardPoints;

  const GameMission({
    required this.id,
    required this.description,
    required this.target,
    required this.statKey,
    required this.rewardPoints,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ ACHIEVEMENTS & MISSIONS
// ─────────────────────────────────────────────────────────────────────────────

final List<GameAchievement> _quizAchievements = [
  GameAchievement(
    id: 'quiz_first_answer',
    title: 'First Correct Answer',
    description: 'Answer your first question correctly',
    emoji: '✅',
    tier: AchievementTier.bronze,
    color: Colors.orange,
    isUnlocked: (s) => (s['totalCorrect'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'quiz_streak_3',
    title: 'On a Roll',
    description: 'Get 3 correct answers in a row',
    emoji: '🔥',
    tier: AchievementTier.bronze,
    color: Colors.deepOrange,
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 3,
  ),
  GameAchievement(
    id: 'quiz_streak_5',
    title: 'Hot Streak',
    description: 'Get 5 correct answers in a row',
    emoji: '🌟',
    tier: AchievementTier.silver,
    color: Colors.amber,
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'quiz_streak_10',
    title: 'Unstoppable',
    description: 'Get 10 correct answers in a row',
    emoji: '⚡',
    tier: AchievementTier.gold,
    color: Colors.yellow,
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 10,
  ),
  GameAchievement(
    id: 'quiz_perfect_topic',
    title: 'Topic Master',
    description: 'Score 100% on any topic',
    emoji: '🏆',
    tier: AchievementTier.gold,
    color: Colors.amber,
    isUnlocked: (s) => (s['perfectTopics'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'quiz_all_topics',
    title: 'Science Scholar',
    description: 'Complete all 5 topics',
    emoji: '🎓',
    tier: AchievementTier.gold,
    color: Colors.purple,
    isUnlocked: (s) => (s['topicsCompleted'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'quiz_speed_demon',
    title: 'Speed Demon',
    description: 'Answer a hard question in under 5 seconds',
    emoji: '💨',
    tier: AchievementTier.silver,
    color: Colors.lightBlue,
    isUnlocked: (s) => (s['fastHardAnswer'] ?? false) == true,
  ),
  GameAchievement(
    id: 'quiz_no_hints_hard',
    title: 'Hard Mode Hero',
    description: 'Answer all 5 hard questions without a hint',
    emoji: '🦸',
    tier: AchievementTier.silver,
    color: Colors.indigo,
    isUnlocked: (s) => (s['hardQuestionsNoHint'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'quiz_total_100',
    title: 'Century',
    description: 'Answer 100 questions correctly across all topics',
    emoji: '💯',
    tier: AchievementTier.gold,
    color: Colors.green,
    isUnlocked: (s) => (s['totalCorrect'] ?? 0) >= 100,
  ),
];

final List<GameMission> _quizMissions = [
  GameMission(
    id: 'quiz_m1',
    description: 'Answer 3 questions correctly',
    target: 3,
    statKey: 'sessionCorrect',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'quiz_m2',
    description: 'Build a 3x streak',
    target: 3,
    statKey: 'sessionMaxStreak',
    rewardPoints: 20,
  ),
  GameMission(
    id: 'quiz_m3',
    description: 'Answer 1 hard question correctly',
    target: 1,
    statKey: 'sessionHardCorrect',
    rewardPoints: 25,
  ),
  GameMission(
    id: 'quiz_m4',
    description: 'Score 100% on a topic',
    target: 1,
    statKey: 'sessionPerfectTopics',
    rewardPoints: 50,
  ),
  GameMission(
    id: 'quiz_m5',
    description: 'Answer 10 questions total',
    target: 10,
    statKey: 'sessionAnswered',
    rewardPoints: 30,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MATCHING GAME ACHIEVEMENTS & MISSIONS
// ─────────────────────────────────────────────────────────────────────────────

final List<GameAchievement> _matchingAchievements = [
  GameAchievement(
    id: 'match_first_pair',
    title: 'First Match',
    description: 'Match your first pair of cards',
    emoji: '🃏',
    tier: AchievementTier.bronze,
    color: Colors.blue,
    isUnlocked: (s) => (s['totalMatches'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'match_10_pairs',
    title: 'Pair Pro',
    description: 'Match 10 pairs total',
    emoji: '👏',
    tier: AchievementTier.bronze,
    color: Colors.blue,
    isUnlocked: (s) => (s['totalMatches'] ?? 0) >= 10,
  ),
  GameAchievement(
    id: 'match_flawless',
    title: 'Flawless',
    description: 'Complete a level without a single wrong flip',
    emoji: '✨',
    tier: AchievementTier.gold,
    color: Colors.amber,
    isUnlocked: (s) => (s['flawlessLevels'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'match_speed_3',
    title: 'Speed Flipper',
    description: 'Match 3 pairs in under 10 seconds',
    emoji: '⚡',
    tier: AchievementTier.silver,
    color: Colors.orange,
    isUnlocked: (s) => (s['speedMatches'] ?? false) == true,
  ),
  GameAchievement(
    id: 'match_all_topics',
    title: 'Topic Explorer',
    description: 'Play all 5 science topics',
    emoji: '🌍',
    tier: AchievementTier.silver,
    color: Colors.green,
    isUnlocked: (s) => (s['topicsPlayed'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'match_hard_complete',
    title: 'Hard Mode Champion',
    description: 'Complete all 10 levels on Hard difficulty',
    emoji: '🔥',
    tier: AchievementTier.gold,
    color: Colors.red,
    isUnlocked: (s) => (s['hardLevelsCompleted'] ?? 0) >= 10,
  ),
  GameAchievement(
    id: 'match_score_500',
    title: 'High Scorer',
    description: 'Score 500 points in a single game',
    emoji: '🏅',
    tier: AchievementTier.silver,
    color: Colors.purple,
    isUnlocked: (s) => (s['bestScore'] ?? 0) >= 500,
  ),
  GameAchievement(
    id: 'match_no_penalty',
    title: 'Perfect Memory',
    description: 'Complete a game without any wrong attempts',
    emoji: '🧠',
    tier: AchievementTier.gold,
    color: Colors.teal,
    isUnlocked: (s) => (s['gamesWithNoPenalty'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'match_easy_medium_hard',
    title: 'Versatile',
    description: 'Win at least one game on each difficulty',
    emoji: '🎯',
    tier: AchievementTier.gold,
    color: Colors.indigo,
    isUnlocked:
        (s) =>
            (s['easyWins'] ?? 0) >= 1 &&
            (s['mediumWins'] ?? 0) >= 1 &&
            (s['hardWins'] ?? 0) >= 1,
  ),
];

final List<GameMission> _matchingMissions = [
  GameMission(
    id: 'match_m1',
    description: 'Match 3 pairs this game',
    target: 3,
    statKey: 'sessionMatches',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'match_m2',
    description: 'Complete 1 level without wrong flips',
    target: 1,
    statKey: 'sessionFlawlessLevels',
    rewardPoints: 30,
  ),
  GameMission(
    id: 'match_m3',
    description: 'Reach level 3',
    target: 3,
    statKey: 'sessionCurrentLevel',
    rewardPoints: 20,
  ),
  GameMission(
    id: 'match_m4',
    description: 'Score 100 points',
    target: 100,
    statKey: 'sessionScore',
    rewardPoints: 25,
  ),
  GameMission(
    id: 'match_m5',
    description: 'Match pairs in 3 different topics',
    target: 3,
    statKey: 'sessionTopicsPlayed',
    rewardPoints: 40,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// CROSSWORD ACHIEVEMENTS & MISSIONS
// ─────────────────────────────────────────────────────────────────────────────

final List<GameAchievement> _crosswordAchievements = [
  GameAchievement(
    id: 'cross_first_word',
    title: 'First Word',
    description: 'Solve your first crossword word',
    emoji: '📝',
    tier: AchievementTier.bronze,
    color: Colors.purple,
    isUnlocked: (s) => (s['totalWordsSolved'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'cross_5_words',
    title: 'Word Collector',
    description: 'Solve 5 words in a single puzzle',
    emoji: '📚',
    tier: AchievementTier.bronze,
    color: Colors.purple,
    isUnlocked: (s) => (s['sessionWordsSolved'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'cross_no_hints',
    title: 'Purist',
    description: 'Complete a puzzle without using any hints',
    emoji: '🎯',
    tier: AchievementTier.gold,
    color: Colors.amber,
    isUnlocked:
        (s) => (s['hintsUsed'] ?? 1) == 0 && (s['puzzlesCompleted'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'cross_all_words',
    title: 'Completionist',
    description: 'Solve every word in a puzzle',
    emoji: '🏆',
    tier: AchievementTier.gold,
    color: Colors.amber,
    isUnlocked: (s) => (s['fullPuzzlesCompleted'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'cross_swift',
    title: 'Swift Solver',
    description: 'Complete a puzzle with 2+ minutes remaining',
    emoji: '⏱️',
    tier: AchievementTier.silver,
    color: Colors.green,
    isUnlocked: (s) => (s['timeRemainingOnWin'] ?? 0) >= 120,
  ),
  GameAchievement(
    id: 'cross_hard_complete',
    title: 'Wordsmith',
    description: 'Complete a Hard puzzle',
    emoji: '🔤',
    tier: AchievementTier.gold,
    color: Colors.indigo,
    isUnlocked: (s) => (s['hardPuzzlesCompleted'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'cross_all_topics',
    title: 'All-rounder',
    description: 'Complete a puzzle for all 5 topics',
    emoji: '🌟',
    tier: AchievementTier.gold,
    color: Colors.orange,
    isUnlocked: (s) => (s['topicsCompleted'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'cross_no_wrong',
    title: 'Spell Perfect',
    description: 'Solve 5 words with no wrong attempts',
    emoji: '✨',
    tier: AchievementTier.silver,
    color: Colors.teal,
    isUnlocked: (s) => (s['wordsWithNoWrong'] ?? 0) >= 5,
  ),
];

final List<GameMission> _crosswordMissions = [
  GameMission(
    id: 'cross_m1',
    description: 'Solve 2 words this puzzle',
    target: 2,
    statKey: 'sessionWordsSolved',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'cross_m2',
    description: 'Solve a word without wrong attempts',
    target: 1,
    statKey: 'sessionPerfectWords',
    rewardPoints: 20,
  ),
  GameMission(
    id: 'cross_m3',
    description: 'Solve a Down clue',
    target: 1,
    statKey: 'sessionDownSolved',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'cross_m4',
    description: 'Solve an Across clue',
    target: 1,
    statKey: 'sessionAcrossSolved',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'cross_m5',
    description: 'Complete the puzzle with hints remaining',
    target: 1,
    statKey: 'sessionCompletedWithHints',
    rewardPoints: 35,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SCIENCE FUSION ACHIEVEMENTS & MISSIONS
// ─────────────────────────────────────────────────────────────────────────────

final List<GameAchievement> _fusionAchievements = [
  GameAchievement(
    id: 'fusion_first_discovery',
    title: 'First Discovery',
    description: 'Make your first element combination',
    emoji: '🔬',
    tier: AchievementTier.bronze,
    color: Colors.green,
    isUnlocked: (s) => (s['totalDiscoveries'] ?? 0) >= 1,
  ),
  GameAchievement(
    id: 'fusion_collector_5',
    title: 'Curious Collector',
    description: 'Collect 5 different elements',
    emoji: '📦',
    tier: AchievementTier.bronze,
    color: Colors.cyan,
    isUnlocked: (s) => (s['collected'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'fusion_collector_10',
    title: 'Element Collector',
    description: 'Collect 10 different elements',
    emoji: '🗃️',
    tier: AchievementTier.silver,
    color: Colors.cyan,
    isUnlocked: (s) => (s['collected'] ?? 0) >= 10,
  ),
  GameAchievement(
    id: 'fusion_streak_3',
    title: 'Chain Reaction',
    description: 'Achieve a 3x combo streak',
    emoji: '⛓️',
    tier: AchievementTier.bronze,
    color: Colors.orange,
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 3,
  ),
  GameAchievement(
    id: 'fusion_streak_5',
    title: 'Combo Master',
    description: 'Achieve a 5x combo streak',
    emoji: '🔥',
    tier: AchievementTier.silver,
    color: Colors.orange,
    isUnlocked: (s) => (s['maxStreak'] ?? 0) >= 5,
  ),
  GameAchievement(
    id: 'fusion_no_hints',
    title: 'Perfectionist',
    description: 'Complete all levels without using hints',
    emoji: '🏅',
    tier: AchievementTier.gold,
    color: Colors.amber,
    isUnlocked:
        (s) => (s['hintsUsed'] ?? 1) == 0 && (s['levelsCompleted'] ?? 0) >= 3,
  ),
  GameAchievement(
    id: 'fusion_speed',
    title: 'Speed Scientist',
    description: 'Complete a level in under 2 minutes',
    emoji: '⚡',
    tier: AchievementTier.silver,
    color: Colors.green,
    isUnlocked: (s) => (s['fastestLevel'] ?? 999) < 120,
  ),
  GameAchievement(
    id: 'fusion_all_levels',
    title: 'Lab Graduate',
    description: 'Complete all 3 levels in a game mode',
    emoji: '🎓',
    tier: AchievementTier.gold,
    color: Colors.purple,
    isUnlocked: (s) => (s['levelsCompleted'] ?? 0) >= 3,
  ),
  GameAchievement(
    id: 'fusion_both_modes',
    title: 'Dual Scientist',
    description: 'Complete both Photosynthesis and Matter labs',
    emoji: '🧫',
    tier: AchievementTier.gold,
    color: Colors.teal,
    isUnlocked:
        (s) =>
            (s['photoCompleted'] ?? false) == true &&
            (s['matterCompleted'] ?? false) == true,
  ),
];

final List<GameMission> _fusionMissions = [
  GameMission(
    id: 'fusion_m1',
    description: 'Make 3 new combinations',
    target: 3,
    statKey: 'sessionDiscoveries',
    rewardPoints: 15,
  ),
  GameMission(
    id: 'fusion_m2',
    description: 'Build a 3x combo streak',
    target: 3,
    statKey: 'sessionMaxStreak',
    rewardPoints: 25,
  ),
  GameMission(
    id: 'fusion_m3',
    description: 'Collect 5 elements',
    target: 5,
    statKey: 'sessionCollected',
    rewardPoints: 20,
  ),
  GameMission(
    id: 'fusion_m4',
    description: 'Find the target element 3 times',
    target: 3,
    statKey: 'sessionTargetsFound',
    rewardPoints: 30,
  ),
  GameMission(
    id: 'fusion_m5',
    description: 'Complete Level 2',
    target: 2,
    statKey: 'sessionLevelReached',
    rewardPoints: 40,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE CLASS
// ─────────────────────────────────────────────────────────────────────────────

class GameAchievementService {
  static const String GAME_QUIZ = 'quiz';
  static const String GAME_MATCHING = 'matching';
  static const String GAME_CROSSWORD = 'crossword';
  static const String GAME_FUSION = 'fusion';

  static List<GameAchievement> achievementsFor(String gameId) {
    switch (gameId) {
      case GAME_QUIZ:
        return _quizAchievements;
      case GAME_MATCHING:
        return _matchingAchievements;
      case GAME_CROSSWORD:
        return _crosswordAchievements;
      case GAME_FUSION:
        return _fusionAchievements;
      default:
        return [];
    }
  }

  static List<GameMission> missionsFor(String gameId) {
    switch (gameId) {
      case GAME_QUIZ:
        return _quizMissions;
      case GAME_MATCHING:
        return _matchingMissions;
      case GAME_CROSSWORD:
        return _crosswordMissions;
      case GAME_FUSION:
        return _fusionMissions;
      default:
        return [];
    }
  }

  /// Check which achievements were newly unlocked. Returns only NEW ones.
  static Future<List<GameAchievement>> checkNewAchievements({
    required String username,
    required String gameId,
    required Map<String, dynamic> stats,
  }) async {
    final userId = await StudentCache.getUserId() ?? '';
    if (userId.isEmpty) return [];

    final doc = FirebaseFirestore.instance
        .collection('achievements')
        .doc(userId);

    final snap = await doc.get();
    final existing = (snap.data()?['unlocked_$gameId'] as List<dynamic>?) ?? [];

    final allAchs = achievementsFor(gameId);
    final newlyUnlocked = <GameAchievement>[];

    for (final ach in allAchs) {
      if (!existing.contains(ach.id) && ach.isUnlocked(stats)) {
        newlyUnlocked.add(ach);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      final updated = [...existing, ...newlyUnlocked.map((a) => a.id)];
      await doc.set({'unlocked_$gameId': updated}, SetOptions(merge: true));
    }

    return newlyUnlocked;
  }

  /// Load which achievements are already unlocked for a game.
  static Future<Set<String>> loadUnlocked({
    required String username,
    required String gameId,
  }) async {
    final userId = await StudentCache.getUserId() ?? '';
    if (userId.isEmpty) return {};

    final snap =
        await FirebaseFirestore.instance
            .collection('achievements')
            .doc(userId)
            .get();

    final list = (snap.data()?['unlocked_$gameId'] as List<dynamic>?) ?? [];
    return list.cast<String>().toSet();
  }
}
