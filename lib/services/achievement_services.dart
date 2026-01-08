import 'package:flutter/material.dart';

// ============================================================================
// ACHIEVEMENT & ANALYTICS SERVICE - COMPLETE IMPLEMENTATION
// ============================================================================

/// Represents a single achievement/badge
class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final String level;
  final IconData icon;
  final Color color;
  final int requiredPoints;
  final bool isCompleted;
  final int currentProgress;
  final String emoji;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.icon,
    required this.color,
    required this.requiredPoints,
    this.isCompleted = false,
    this.currentProgress = 0,
    required this.emoji,
  });

  Achievement copyWith({bool? isCompleted, int? currentProgress}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      category: category,
      level: level,
      icon: icon,
      color: color,
      requiredPoints: requiredPoints,
      isCompleted: isCompleted ?? this.isCompleted,
      currentProgress: currentProgress ?? this.currentProgress,
      emoji: emoji,
    );
  }

  String get progressPercentage {
    if (isCompleted) return "100%";
    if (requiredPoints == 0) return "0%";
    return "${((currentProgress / requiredPoints) * 100).toInt()}%";
  }

  double get progressValue {
    if (isCompleted) return 1.0;
    if (requiredPoints == 0) return 0.0;
    return currentProgress / requiredPoints;
  }
}

/// Comprehensive analytics for a student
class StudentAnalytics {
  final String username;
  final int totalScore;
  final int totalGamesPlayed;
  final int totalAchievements;
  final Map<String, int> gameScores;
  final Map<String, int> gameAttempts;
  final Map<String, double> gameAverages;
  final List<Achievement> achievements;
  final String masteryLevel;
  final DateTime lastPlayed;

  StudentAnalytics({
    required this.username,
    required this.totalScore,
    required this.totalGamesPlayed,
    required this.totalAchievements,
    required this.gameScores,
    required this.gameAttempts,
    required this.gameAverages,
    required this.achievements,
    required this.masteryLevel,
    required this.lastPlayed,
  });

  int get unlockedBadges => achievements.where((a) => a.isCompleted).length;

  String get masteryLevelEmoji {
    switch (masteryLevel) {
      case "Star Scientist":
        return "⭐";
      case "Senior Scientist":
        return "🥈";
      case "Junior Scientist":
        return "🥉";
      default:
        return "🔰";
    }
  }

  double get completionRate {
    if (achievements.isEmpty) return 0.0;
    return unlockedBadges / achievements.length;
  }
}

// ============================================================================
// ACHIEVEMENT SERVICE (Singleton)
// ============================================================================

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  // In-memory storage (replace with actual database/storage in production)
  final Map<String, StudentAnalytics> _studentData = {};
  final Map<String, List<Achievement>> _studentAchievements = {};

  // Game ID Constants
  static const String GAME_QUIZ = "quiz";
  static const String GAME_TRIVIA = "trivia";
  static const String GAME_FUSION_PHOTO = "photosynthesis";
  static const String GAME_FUSION_MATTER = "matter_changes";
  static const String GAME_WORDCONNECT = "wordconnect";

  // Achievement Definitions
  static final List<Achievement> _allAchievements = [
    // ========== QUIZ ACHIEVEMENTS ==========
    Achievement(
      id: "quiz_first_perfect",
      title: "Quiz Master",
      description: "Score 100% on any quiz",
      category: "quiz",
      level: "Junior",
      icon: Icons.emoji_events,
      color: Colors.amber,
      requiredPoints: 1,
      emoji: "🏆",
    ),
    Achievement(
      id: "quiz_5_perfect",
      title: "Quiz Champion",
      description: "Score 100% on 5 different quizzes",
      category: "quiz",
      level: "Senior",
      icon: Icons.military_tech,
      color: Colors.orange,
      requiredPoints: 5,
      emoji: "🥇",
    ),
    Achievement(
      id: "quiz_all_topics",
      title: "Science Scholar",
      description: "Complete all quiz topics",
      category: "quiz",
      level: "Star",
      icon: Icons.star,
      color: Colors.purple,
      requiredPoints: 5,
      emoji: "⭐",
    ),

    // ========== TRIVIA ACHIEVEMENTS ==========
    Achievement(
      id: "trivia_level_5",
      title: "Trivia Novice",
      description: "Complete 5 levels in matching game",
      category: "trivia",
      level: "Junior",
      icon: Icons.emoji_events,
      color: Colors.green,
      requiredPoints: 5,
      emoji: "🎯",
    ),
    Achievement(
      id: "trivia_level_10",
      title: "Trivia Expert",
      description: "Complete all 10 levels",
      category: "trivia",
      level: "Senior",
      icon: Icons.military_tech,
      color: Colors.teal,
      requiredPoints: 10,
      emoji: "🧠",
    ),
    Achievement(
      id: "trivia_speed",
      title: "Speed Thinker",
      description: "Complete a level in under 20 seconds",
      category: "trivia",
      level: "Star",
      icon: Icons.flash_on,
      color: Colors.yellow,
      requiredPoints: 1,
      emoji: "⚡",
    ),

    // ========== SCIENCE FUSION ACHIEVEMENTS ==========
    Achievement(
      id: "fusion_photosynthesis",
      title: "Plant Expert",
      description: "Complete Photosynthesis Lab",
      category: "fusion",
      level: "Junior",
      icon: Icons.eco,
      color: Colors.green,
      requiredPoints: 1,
      emoji: "🌱",
    ),
    Achievement(
      id: "fusion_matter",
      title: "Matter Master",
      description: "Complete Changes of Matter Lab",
      category: "fusion",
      level: "Junior",
      icon: Icons.science,
      color: Colors.blue,
      requiredPoints: 1,
      emoji: "🧪",
    ),
    Achievement(
      id: "fusion_both_perfect",
      title: "Lab Genius",
      description: "Complete both labs with 90%+ score",
      category: "fusion",
      level: "Star",
      icon: Icons.star,
      color: Colors.deepPurple,
      requiredPoints: 2,
      emoji: "🔬",
    ),

    // ========== WORD CONNECT ACHIEVEMENTS ==========
    Achievement(
      id: "word_level_5",
      title: "Word Finder",
      description: "Complete 5 word connect levels",
      category: "wordconnect",
      level: "Junior",
      icon: Icons.emoji_events,
      color: Colors.indigo,
      requiredPoints: 5,
      emoji: "📖",
    ),
    Achievement(
      id: "word_all_levels",
      title: "Word Master",
      description: "Complete all 20 levels",
      category: "wordconnect",
      level: "Senior",
      icon: Icons.military_tech,
      color: Colors.deepPurple,
      requiredPoints: 20,
      emoji: "📚",
    ),
    Achievement(
      id: "word_high_score",
      title: "Word Champion",
      description: "Score 200+ points in one game",
      category: "wordconnect",
      level: "Star",
      icon: Icons.star,
      color: Colors.pink,
      requiredPoints: 200,
      emoji: "👑",
    ),

    // ========== CROSS-GAME ACHIEVEMENTS ==========
    Achievement(
      id: "play_all_games",
      title: "Game Explorer",
      description: "Play all 4 different games",
      category: "general",
      level: "Junior",
      icon: Icons.explore,
      color: Colors.cyan,
      requiredPoints: 4,
      emoji: "🎮",
    ),
    Achievement(
      id: "total_score_500",
      title: "Point Collector",
      description: "Earn 500 total points",
      category: "general",
      level: "Senior",
      icon: Icons.stars,
      color: Colors.amber,
      requiredPoints: 500,
      emoji: "💎",
    ),
    Achievement(
      id: "total_score_1000",
      title: "Legend",
      description: "Earn 1000 total points",
      category: "general",
      level: "Star",
      icon: Icons.whatshot,
      color: Colors.red,
      requiredPoints: 1000,
      emoji: "🔥",
    ),
  ];

  /// Initialize student data if not exists
  void initializeStudent(String username) {
    if (!_studentData.containsKey(username)) {
      _studentData[username] = StudentAnalytics(
        username: username,
        totalScore: 0,
        totalGamesPlayed: 0,
        totalAchievements: 0,
        gameScores: {},
        gameAttempts: {},
        gameAverages: {},
        achievements: List.from(_allAchievements),
        masteryLevel: "Novice Scientist",
        lastPlayed: DateTime.now(),
      );
      _studentAchievements[username] = List.from(_allAchievements);
    }
  }

  /// Record game completion and check for new achievements
  Future<List<Achievement>> recordGameCompletion({
    required String username,
    required String gameId,
    required int score,
    required int maxScore,
    Map<String, dynamic>? metadata,
  }) async {
    initializeStudent(username);

    final data = _studentData[username]!;
    final achievements = _studentAchievements[username]!;
    final newlyUnlocked = <Achievement>[];

    // Update game statistics
    data.gameScores[gameId] = (data.gameScores[gameId] ?? 0) + score;
    data.gameAttempts[gameId] = (data.gameAttempts[gameId] ?? 0) + 1;
    data.gameAverages[gameId] =
        data.gameScores[gameId]! / data.gameAttempts[gameId]!;

    // Update totals
    final totalScore = data.totalScore + score;
    final totalGamesPlayed = data.totalGamesPlayed + 1;

    // Check achievements
    for (int i = 0; i < achievements.length; i++) {
      if (achievements[i].isCompleted) continue;

      bool shouldUnlock = false;
      int progress = achievements[i].currentProgress;

      switch (achievements[i].id) {
        // ========== Quiz Achievements ==========
        case "quiz_first_perfect":
          if (gameId == GAME_QUIZ && score == maxScore) {
            progress = 1;
            shouldUnlock = true;
          }
          break;

        case "quiz_5_perfect":
          if (gameId == GAME_QUIZ && score == maxScore) {
            progress++;
            if (progress >= 5) shouldUnlock = true;
          }
          break;

        case "quiz_all_topics":
          if (gameId == GAME_QUIZ) {
            progress = metadata?['topicsCompleted'] ?? progress;
            if (progress >= 5) shouldUnlock = true;
          }
          break;

        // ========== Trivia Achievements ==========
        case "trivia_level_5":
          if (gameId == GAME_TRIVIA) {
            progress = metadata?['levelsCompleted'] ?? progress;
            if (progress >= 5) shouldUnlock = true;
          }
          break;

        case "trivia_level_10":
          if (gameId == GAME_TRIVIA) {
            progress = metadata?['levelsCompleted'] ?? progress;
            if (progress >= 10) shouldUnlock = true;
          }
          break;

        case "trivia_speed":
          if (gameId == GAME_TRIVIA && (metadata?['fastCompletion'] ?? false)) {
            progress = 1;
            shouldUnlock = true;
          }
          break;

        // ========== Fusion Achievements ==========
        case "fusion_photosynthesis":
          if (gameId == GAME_FUSION_PHOTO) {
            progress = 1;
            shouldUnlock = true;
          }
          break;

        case "fusion_matter":
          if (gameId == GAME_FUSION_MATTER) {
            progress = 1;
            shouldUnlock = true;
          }
          break;

        case "fusion_both_perfect":
          if ((gameId == GAME_FUSION_PHOTO || gameId == GAME_FUSION_MATTER) &&
              (score / maxScore) >= 0.9) {
            progress++;
            if (progress >= 2) shouldUnlock = true;
          }
          break;

        // ========== Word Connect Achievements ==========
        case "word_level_5":
          if (gameId == GAME_WORDCONNECT) {
            progress = metadata?['levelsCompleted'] ?? progress;
            if (progress >= 5) shouldUnlock = true;
          }
          break;

        case "word_all_levels":
          if (gameId == GAME_WORDCONNECT) {
            progress = metadata?['levelsCompleted'] ?? progress;
            if (progress >= 20) shouldUnlock = true;
          }
          break;

        case "word_high_score":
          if (gameId == GAME_WORDCONNECT && score >= 200) {
            progress = score;
            shouldUnlock = true;
          }
          break;

        // ========== General Achievements ==========
        case "play_all_games":
          final uniqueGames = data.gameScores.keys.length;
          progress = uniqueGames;
          if (progress >= 4) shouldUnlock = true;
          break;

        case "total_score_500":
          progress = totalScore;
          if (progress >= 500) shouldUnlock = true;
          break;

        case "total_score_1000":
          progress = totalScore;
          if (progress >= 1000) shouldUnlock = true;
          break;
      }

      // Update achievement
      achievements[i] = achievements[i].copyWith(
        currentProgress: progress,
        isCompleted: shouldUnlock,
      );

      if (shouldUnlock) {
        newlyUnlocked.add(achievements[i]);
      }
    }

    // Update mastery level
    final totalAchievements = achievements.where((a) => a.isCompleted).length;
    String masteryLevel = _calculateMasteryLevel(totalAchievements, totalScore);

    // Save updated data
    _studentData[username] = StudentAnalytics(
      username: username,
      totalScore: totalScore,
      totalGamesPlayed: totalGamesPlayed,
      totalAchievements: totalAchievements,
      gameScores: data.gameScores,
      gameAttempts: data.gameAttempts,
      gameAverages: data.gameAverages,
      achievements: achievements,
      masteryLevel: masteryLevel,
      lastPlayed: DateTime.now(),
    );

    _studentAchievements[username] = achievements;

    return newlyUnlocked;
  }

  /// Calculate mastery level based on achievements and score
  String _calculateMasteryLevel(int achievements, int totalScore) {
    if (achievements >= 12 && totalScore >= 1000) return "Star Scientist";
    if (achievements >= 8 && totalScore >= 500) return "Senior Scientist";
    if (achievements >= 4 && totalScore >= 200) return "Junior Scientist";
    return "Novice Scientist";
  }

  /// Get student analytics
  StudentAnalytics? getStudentAnalytics(String username) {
    return _studentData[username];
  }

  /// Get achievements for a student
  List<Achievement> getAchievements(String username) {
    initializeStudent(username);
    return _studentAchievements[username] ?? [];
  }

  /// Check if content is unlocked based on achievements
  bool isContentUnlocked(String username, String contentId) {
    initializeStudent(username);
    final achievements = _studentAchievements[username]!;

    switch (contentId) {
      case "trivia_hard":
        return achievements.any(
          (a) => a.id == "trivia_level_5" && a.isCompleted,
        );

      case "fusion_matter":
        return achievements.any(
          (a) => a.id == "fusion_photosynthesis" && a.isCompleted,
        );

      case "wordconnect_advanced":
        return achievements.any((a) => a.id == "word_level_5" && a.isCompleted);

      default:
        return true; // Content is unlocked by default
    }
  }

  /// Get required achievement description for locked content
  String? getRequiredAchievement(String contentId) {
    switch (contentId) {
      case "trivia_hard":
        return "Complete 5 trivia levels to unlock Hard mode";
      case "fusion_matter":
        return "Complete Photosynthesis Lab to unlock Matter Lab";
      case "wordconnect_advanced":
        return "Complete 5 word levels to unlock advanced levels";
      default:
        return null;
    }
  }

  /// Get progress summary for a specific game
  Map<String, dynamic> getGameProgress(String username, String gameId) {
    initializeStudent(username);
    final data = _studentData[username]!;

    return {
      'score': data.gameScores[gameId] ?? 0,
      'attempts': data.gameAttempts[gameId] ?? 0,
      'average': data.gameAverages[gameId] ?? 0.0,
      'achievements':
          _studentAchievements[username]!
              .where((a) => a.category == gameId && a.isCompleted)
              .length,
    };
  }

  /// Reset all data for a student (for testing)
  void resetStudent(String username) {
    _studentData.remove(username);
    _studentAchievements.remove(username);
  }

  /// Get all students (for admin/teacher view)
  List<String> getAllStudents() {
    return _studentData.keys.toList();
  }

  /// Get leaderboard data
  List<Map<String, dynamic>> getLeaderboard({int limit = 10}) {
    final students = _studentData.values.toList();
    students.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return students
        .take(limit)
        .map(
          (student) => {
            'username': student.username,
            'totalScore': student.totalScore,
            'achievements': student.totalAchievements,
            'masteryLevel': student.masteryLevel,
            'lastPlayed': student.lastPlayed,
          },
        )
        .toList();
  }
}
