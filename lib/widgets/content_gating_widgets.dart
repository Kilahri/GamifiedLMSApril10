import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/achievement_services.dart';
import 'package:elearningapp_flutter/screens/analytics_screen.dart';

// ============================================================================
// CONTENT GATING UI COMPONENTS - COMPLETE IMPLEMENTATION
// ============================================================================

/// Dialog shown when trying to access locked content
class LockedContentDialog extends StatelessWidget {
  final String contentName;
  final String requiredAchievementId;
  final String description;
  final String username;

  const LockedContentDialog({
    super.key,
    required this.contentName,
    required this.requiredAchievementId,
    required this.description,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1F3E), Color(0xFF2A2D5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon with Animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withOpacity(0.2),
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 60,
                      color: Colors.amber,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              "$contentName Locked",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Unlock Requirement:",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  IntegratedAnalyticsScreen(username: username),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "View Progress",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying locked content in lists/grids
class LockedContentCard extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final String lockReason;
  final VoidCallback onTap;

  const LockedContentCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.lockReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Background Card (Greyed out)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 35)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lockReason,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock, color: Colors.amber, size: 28),
                ],
              ),
            ),

            // Lock Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Positioned Lock Icon
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.amber, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to manage content gating
class ContentGatingHelper {
  final AchievementService _achievementService = AchievementService();

  /// Check if content is unlocked and show dialog if not
  void attemptToAccessContent({
    required BuildContext context,
    required String username,
    required String contentId,
    required String contentName,
    required VoidCallback onUnlocked,
  }) {
    _achievementService.initializeStudent(username);

    if (_achievementService.isContentUnlocked(username, contentId)) {
      // Content is unlocked, allow access
      onUnlocked();
    } else {
      // Content is locked, show dialog
      final requirement = _achievementService.getRequiredAchievement(contentId);

      showDialog(
        context: context,
        builder:
            (_) => LockedContentDialog(
              contentName: contentName,
              requiredAchievementId: contentId,
              description:
                  requirement ?? "Complete previous challenges to unlock!",
              username: username,
            ),
      );
    }
  }

  /// Build a card that can be locked or unlocked
  Widget buildGameCard({
    required BuildContext context,
    required String username,
    required String title,
    required String icon,
    required Color color,
    required String description,
    String? contentId,
    required VoidCallback onTap,
  }) {
    _achievementService.initializeStudent(username);

    final bool isLocked =
        contentId != null &&
        !_achievementService.isContentUnlocked(username, contentId);

    if (isLocked) {
      return LockedContentCard(
        title: title,
        icon: icon,
        color: color,
        lockReason: description,
        onTap: () {
          attemptToAccessContent(
            context: context,
            username: username,
            contentId: contentId!,
            contentName: title,
            onUnlocked: onTap,
          );
        },
      );
    }

    // Unlocked card
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 35)),
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE USAGE SCREEN
// ============================================================================

class GameMenuWithGatingExample extends StatelessWidget {
  final String username;
  final ContentGatingHelper _gatingHelper = ContentGatingHelper();

  GameMenuWithGatingExample({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        title: const Text("Game Menu", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IntegratedAnalyticsScreen(username: username),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF2A1B4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Choose Your Game",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Complete challenges to unlock more content!",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Always Unlocked Content
            _gatingHelper.buildGameCard(
              context: context,
              username: username,
              title: "Easy Mode",
              icon: "😊",
              color: Colors.green,
              description: "Start your journey here!",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Starting Easy Mode!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            // Locked Content Example 1 - Trivia Hard Mode
            _gatingHelper.buildGameCard(
              context: context,
              username: username,
              title: "Hard Mode",
              icon: "🔥",
              color: Colors.red,
              description: "For expert players only",
              contentId: 'trivia_hard',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Starting Hard Mode!"),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),

            // Locked Content Example 2 - Matter Lab
            _gatingHelper.buildGameCard(
              context: context,
              username: username,
              title: "Changes of Matter Lab",
              icon: "🧊",
              color: Colors.blue,
              description: "Advanced chemistry experiments",
              contentId: 'fusion_matter',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Starting Matter Lab!"),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),

            // Locked Content Example 3 - Advanced Word Connect
            _gatingHelper.buildGameCard(
              context: context,
              username: username,
              title: "Advanced Word Puzzles",
              icon: "⭐",
              color: Colors.amber,
              description: "Challenging vocabulary games",
              contentId: 'wordconnect_advanced',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Starting Advanced Puzzles!"),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
