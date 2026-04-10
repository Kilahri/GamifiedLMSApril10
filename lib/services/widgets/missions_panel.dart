import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/game_achievement_service.dart';

/// Compact collapsible missions panel — embed in any game screen.
/// Pass [sessionStats] as a reactive map; the panel auto-updates progress.
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
          // Header row — tap to collapse
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
          // Status circle
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
