import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/achievement_services.dart';

// ============================================================================
// INTEGRATED ANALYTICS & BADGE SCREEN - COMPLETE IMPLEMENTATION
// ============================================================================

class IntegratedAnalyticsScreen extends StatefulWidget {
  final String username;

  const IntegratedAnalyticsScreen({super.key, required this.username});

  @override
  State<IntegratedAnalyticsScreen> createState() =>
      _IntegratedAnalyticsScreenState();
}

class _IntegratedAnalyticsScreenState extends State<IntegratedAnalyticsScreen> {
  final AchievementService _achievementService = AchievementService();
  late StudentAnalytics analytics;
  String selectedCategory = "All";

  static const Color backgroundColor = Color(0xFF0D102C);
  static const Color cardColor = Color(0xFF1C1F3E);
  static const Color accentColor = Color(0xFF7B4DFF);

  @override
  void initState() {
    super.initState();
    _achievementService.initializeStudent(widget.username);
    _loadAnalytics();
  }

  void _loadAnalytics() {
    final data = _achievementService.getStudentAnalytics(widget.username);
    if (data != null) {
      setState(() {
        analytics = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 4,
        title: const Text(
          "My Progress & Achievements",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAnalytics();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Progress refreshed!"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Mastery Card
            _buildMasteryCard(),
            const SizedBox(height: 30),

            // Performance Stats
            _buildSectionTitle("Performance Overview"),
            const SizedBox(height: 12),
            _buildPerformanceGrid(),
            const SizedBox(height: 30),

            // Game-Specific Analytics
            _buildSectionTitle("Game Analytics"),
            const SizedBox(height: 12),
            _buildGameAnalytics(),
            const SizedBox(height: 30),

            // Achievements & Badges
            _buildSectionTitle("Achievements & Badges 🏆"),
            const SizedBox(height: 12),
            _buildCategoryFilter(),
            const SizedBox(height: 16),
            _buildAchievementGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 120,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryCard() {
    final totalAchievements = analytics.achievements.length;
    final unlockedAchievements = analytics.unlockedBadges;
    final progress = unlockedAchievements / totalAchievements;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4DFF), Color(0xFF5E35B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B4DFF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Progress Ring
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amber,
                      ),
                      strokeWidth: 8,
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          analytics.masteryLevelEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            analytics.masteryLevel,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$unlockedAchievements / $totalAchievements Achievements",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${analytics.totalScore} Total Points",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.games,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${analytics.totalGamesPlayed} Games Played",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          "Games Played",
          "${analytics.totalGamesPlayed}",
          Icons.sports_esports,
          Colors.blue,
        ),
        _buildStatCard(
          "Total Score",
          "${analytics.totalScore}",
          Icons.stars,
          Colors.amber,
        ),
        _buildStatCard(
          "Achievements",
          "${analytics.unlockedBadges}",
          Icons.emoji_events,
          Colors.green,
        ),
        _buildStatCard(
          "Mastery",
          "${(analytics.completionRate * 100).toInt()}%",
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameAnalytics() {
    final gameData = [
      {'name': 'Quiz', 'id': 'quiz', 'icon': '🧪', 'color': Colors.deepPurple},
      {
        'name': 'Trivia Matching',
        'id': 'trivia',
        'icon': '🎯',
        'color': Colors.green,
      },
      {
        'name': 'Photosynthesis Lab',
        'id': 'photosynthesis',
        'icon': '🌱',
        'color': Colors.lightGreen,
      },
      {
        'name': 'Matter Lab',
        'id': 'matter_changes',
        'icon': '🧊',
        'color': Colors.blue,
      },
      {
        'name': 'Word Connect',
        'id': 'wordconnect',
        'icon': '📖',
        'color': Colors.orange,
      },
    ];

    return Column(
      children:
          gameData.map((game) {
            final attempts = analytics.gameAttempts[game['id']] ?? 0;
            final score = analytics.gameScores[game['id']] ?? 0;
            final average = analytics.gameAverages[game['id']] ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      attempts > 0
                          ? (game['color'] as Color).withOpacity(0.3)
                          : Colors.white10,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (game['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game['icon'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attempts > 0
                              ? "$attempts plays • $score pts • ${average.toStringAsFixed(1)} avg"
                              : "Not played yet",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (attempts > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: game['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$score",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      "All",
      "quiz",
      "trivia",
      "fusion",
      "wordconnect",
      "general",
    ];
    final categoryLabels = {
      "All": "All",
      "quiz": "Quiz",
      "trivia": "Trivia",
      "fusion": "Fusion",
      "wordconnect": "Word",
      "general": "General",
    };

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Text(
                  categoryLabels[category]!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementGrid() {
    final filteredAchievements =
        selectedCategory == "All"
            ? analytics.achievements
            : analytics.achievements
                .where((a) => a.category == selectedCategory)
                .toList();

    if (filteredAchievements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(
                "No achievements in this category",
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Group by level
    final grouped = <String, List<Achievement>>{};
    for (var achievement in filteredAchievements) {
      if (!grouped.containsKey(achievement.level)) {
        grouped[achievement.level] = [];
      }
      grouped[achievement.level]!.add(achievement);
    }

    // Sort levels
    final levelOrder = ["Star", "Senior", "Junior", "None"];
    final sortedLevels = levelOrder.where(grouped.containsKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          sortedLevels.map((level) {
            final achievements = grouped[level]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        level == "Star"
                            ? Icons.star
                            : level == "Senior"
                            ? Icons.military_tech
                            : level == "Junior"
                            ? Icons.emoji_events
                            : Icons.lock,
                        color:
                            level == "Star"
                                ? Colors.amber
                                : level == "Senior"
                                ? Colors.orange
                                : level == "Junior"
                                ? Colors.green
                                : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$level Achievements",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(${achievements.where((a) => a.isCompleted).length}/${achievements.length})",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementCard(achievements[index]);
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isCompleted = achievement.isCompleted;
    final progress = achievement.progressValue;

    return GestureDetector(
      onTap: () {
        _showAchievementDetail(achievement);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? achievement.color : Colors.white10,
            width: isCompleted ? 2.5 : 1.0,
          ),
          boxShadow:
              isCompleted
                  ? [
                    BoxShadow(
                      color: achievement.color.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Title
            Column(
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 36,
                    color: isCompleted ? null : Colors.white24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Progress
            Column(
              children: [
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: achievement.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "🏆 UNLOCKED",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  )
                else if (progress > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          achievement.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${achievement.currentProgress}/${achievement.requiredPoints}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    "🔒 LOCKED",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(achievement.emoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    achievement.title,
                    style: TextStyle(
                      color: achievement.color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: achievement.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${achievement.level} Achievement",
                      style: TextStyle(
                        color: achievement.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    achievement.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (achievement.isCompleted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Achievement Unlocked!",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                "Progress: ${achievement.progressPercentage}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: achievement.progressValue,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: achievement.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
