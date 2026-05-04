import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/game_achievement_service.dart';

void showAchievementUnlockDialog(
  BuildContext context,
  List<GameAchievement> achievements,
) {
  if (achievements.isEmpty) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => Dialog(
          backgroundColor: const Color(0xFF1C1F3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text(
                  achievements.length == 1
                      ? 'Achievement Unlocked!'
                      : '${achievements.length} Achievements Unlocked!',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...achievements.map(
                  (a) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: a.color.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                a.description,
                                style: const TextStyle(
                                  color: Colors.white60,
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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

Color _tierColor(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return Colors.brown;
    case AchievementTier.silver:
      return Colors.blueGrey;
    case AchievementTier.gold:
      return Colors.amber;
  }
}

String _tierLabel(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return '🥉 Bronze';
    case AchievementTier.silver:
      return '🥈 Silver';
    case AchievementTier.gold:
      return '🥇 Gold';
  }
}
