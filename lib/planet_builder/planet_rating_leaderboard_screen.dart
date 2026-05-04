import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/planet_builder/rating_service.dart';

class PlanetRatingLeaderboardScreen extends StatelessWidget {
  final String currentUserId;

  const PlanetRatingLeaderboardScreen({Key? key, required this.currentUserId})
    : super(key: key);

  Color _ratingColor(double avg) {
    if (avg >= 80) return const Color(0xFF66BB6A);
    if (avg >= 60) return const Color(0xFF4FC3F7);
    if (avg >= 40) return const Color(0xFFFFD54F);
    if (avg >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  String _ratingLabel(double avg) {
    if (avg >= 80) return '🌟 Legendary';
    if (avg >= 60) return '💎 Excellent';
    if (avg >= 40) return '👍 Good';
    if (avg >= 20) return '🌱 Developing';
    return '💫 New';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040D21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF040D21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🏆 Community Ratings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rankings are based on each student\'s highest-rated planet. '
                    'A minimum of 3 ratings is required to appear.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: RatingService.leaderboardStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
                  );
                }

                if (snapshot.hasError) {
                  // Show the actual error so it's debuggable
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.white38,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load leaderboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ── Sort client-side (replaces server-side orderBy) ──────────
                final docs = List<QueryDocumentSnapshot>.from(
                  snapshot.data?.docs ?? [],
                );
                docs.sort((a, b) {
                  final aR =
                      ((a.data() as Map<String, dynamic>)['averageRating']
                              as num?)
                          ?.toDouble() ??
                      0.0;
                  final bR =
                      ((b.data() as Map<String, dynamic>)['averageRating']
                              as num?)
                          ?.toDouble() ??
                      0.0;
                  return bR.compareTo(aR);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌌', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        const Text(
                          'No ratings yet!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to rate a planet in the Community tab.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['ownerUserId'] == currentUserId;
                    final avg =
                        (data['averageRating'] as num?)?.toDouble() ?? 0.0;
                    final count = (data['ratingCount'] as int?) ?? 0;
                    final username = data['username'] as String? ?? 'Unknown';
                    final planetName =
                        data['bestPlanetName'] as String? ?? 'Unknown';
                    final planetType = data['bestPlanetType'] as String? ?? '';

                    final medal =
                        index == 0
                            ? '🥇'
                            : index == 1
                            ? '🥈'
                            : index == 2
                            ? '🥉'
                            : null;

                    final ratingCol = _ratingColor(avg);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            isMe
                                ? const Color(0xFF4FC3F7).withOpacity(0.08)
                                : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isMe
                                  ? const Color(0xFF4FC3F7).withOpacity(0.35)
                                  : index < 3
                                  ? const Color(0xFFFFD54F).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.07),
                          width: isMe ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank
                          SizedBox(
                            width: 40,
                            child:
                                medal != null
                                    ? Text(
                                      medal,
                                      style: const TextStyle(fontSize: 24),
                                      textAlign: TextAlign.center,
                                    )
                                    : Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                          ),
                          const SizedBox(width: 10),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4FC3F7),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'YOU',
                                          style: TextStyle(
                                            color: Color(0xFF040D21),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '🪐 $planetName',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  planetType,
                                  style: const TextStyle(
                                    color: Color(0xFF4FC3F7),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _ratingLabel(avg),
                                  style: TextStyle(
                                    color: ratingCol,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Score
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                avg.toStringAsFixed(1),
                                style: TextStyle(
                                  color: ratingCol,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'avg / 100',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count rating${count != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
