import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';

class CombinedLeaderboardScreen extends StatefulWidget {
  final String currentUserId;
  const CombinedLeaderboardScreen({required this.currentUserId});

  @override
  State<CombinedLeaderboardScreen> createState() =>
      _CombinedLeaderboardScreenState();
}

class _CombinedLeaderboardScreenState extends State<CombinedLeaderboardScreen> {
  String? _selectedGame;
  int _refreshKey = 0;
  bool _isRefreshing = false;

  final _games = [
    null,
    FirebaseLeaderboardService.GAME_SCIENCE_FUSION,
    FirebaseLeaderboardService.GAME_QUIZ,
    FirebaseLeaderboardService.GAME_MATCHING,
    FirebaseLeaderboardService.GAME_CROSSWORD,
  ];

  String _gameLabel(String? g) {
    if (g == null) return 'All Games';
    if (g == FirebaseLeaderboardService.GAME_SCIENCE_FUSION)
      return '🌿 Science Fusion';
    if (g == FirebaseLeaderboardService.GAME_QUIZ) return '📝 Quiz';
    if (g == FirebaseLeaderboardService.GAME_MATCHING) return '🧩 Matching';
    if (g == FirebaseLeaderboardService.GAME_CROSSWORD) return '🔤 Crossword';
    return g;
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    if (_selectedGame == null) {
      return await FirebaseLeaderboardService.getOverallLeaderboard();
    }
    return await FirebaseLeaderboardService.getGameLeaderboard(
      gameName: _selectedGame!,
    );
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _refreshKey++;
      _isRefreshing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Leaderboard refreshed!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Helper: section pill widget ──────────────────────────────────────────
  Widget? _buildSectionPill(String? section) {
    if (section == null || section.trim().isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.6)),
      ),
      child: Text(
        section,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Avatar widget with initials fallback ──────────────────────────────────
  Widget _buildAvatar(Map<String, dynamic> e, {double size = 46}) {
    final photoUrl = e['photoUrl'] as String?;
    final name =
        (e['leaderboardName'] as String?)?.isNotEmpty == true
            ? e['leaderboardName'] as String
            : (e['displayName'] as String?)?.isNotEmpty == true
            ? e['displayName'] as String
            : (e['username'] as String?) ?? '?';

    final initials =
        name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    final colors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.indigo,
      Colors.green.shade700,
      Colors.blue.shade700,
      Colors.orange.shade700,
      Colors.pink.shade700,
    ];
    final colorIndex = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    final avatarColor = colors[colorIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child:
            photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          _initialsAvatar(initials, avatarColor, size),
                )
                : _initialsAvatar(initials, avatarColor, size),
      ),
    );
  }

  Widget _initialsAvatar(String initials, Color color, double size) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          '🏆 Combined Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isRefreshing
              ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh scores',
                onPressed: _refresh,
              ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children:
                  _games.map((g) {
                    final selected = _selectedGame == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              _selectedGame = g;
                              _refreshKey++;
                            }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? Colors.amber
                                    : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: selected ? Colors.amber : Colors.white38,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            _gameLabel(g),
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.amber,
              backgroundColor: const Color(0xFF1C1F3E),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchLeaderboard(),
                key: ValueKey('$_selectedGame-$_refreshKey'),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  }
                  final entries = snap.data ?? [];
                  if (entries.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Text('📊', style: TextStyle(fontSize: 60)),
                              SizedBox(height: 16),
                              Text(
                                'No scores yet!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Play some games to appear here!',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final isMe = e['userId'] == widget.currentUserId;
                      final score =
                          _selectedGame == null ? e['totalScore'] : e['score'];
                      final section = e['section'] as String?;

                      // Resolve display name
                      final name =
                          (e['leaderboardName'] as String?)?.isNotEmpty == true
                              ? e['leaderboardName'] as String
                              : (e['displayName'] as String?)?.isNotEmpty ==
                                  true
                              ? e['displayName'] as String
                              : (e['username'] as String?) ?? '—';

                      // ── Top 3 podium cards ────────────────────────────────
                      if (i < 3) {
                        final medals = ['🥇', '🥈', '🥉'];
                        final podiumColors = [
                          const Color(0xFFFFD700), // gold
                          const Color(0xFFC0C0C0), // silver
                          const Color(0xFFCD7F32), // bronze
                        ];
                        final sectionPill = _buildSectionPill(section);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                podiumColors[i].withOpacity(0.25),
                                podiumColors[i].withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isMe
                                      ? Colors.amber
                                      : podiumColors[i].withOpacity(0.6),
                              width: isMe ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Medal
                              Text(
                                medals[i],
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 12),
                              // Avatar
                              _buildAvatar(e, size: 50),
                              const SizedBox(width: 14),
                              // Name + section + subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name row
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
                                              color: Colors.amber,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Section pill
                                    if (sectionPill != null) ...[
                                      sectionPill,
                                      const SizedBox(height: 3),
                                    ],
                                    // Games played subtitle
                                    if (_selectedGame == null &&
                                        e['gamesPlayed'] != null)
                                      Text(
                                        '${e['gamesPlayed']} game${(e['gamesPlayed'] as int) == 1 ? '' : 's'} played',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
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
                                    '$score',
                                    style: TextStyle(
                                      color:
                                          isMe ? Colors.amber : podiumColors[i],
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'pts',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      // ── Regular entries (4th place onwards) ──────────────
                      final sectionPill = _buildSectionPill(section);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? Colors.amber.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMe ? Colors.amber : Colors.white12,
                            width: isMe ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank number
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Avatar
                            _buildAvatar(e, size: 40),
                            const SizedBox(width: 12),
                            // Name + section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name row
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                            color: Colors.amber,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Section pill
                                  if (sectionPill != null) ...[
                                    sectionPill,
                                    const SizedBox(height: 2),
                                  ],
                                  // Games played subtitle
                                  if (_selectedGame == null &&
                                      e['gamesPlayed'] != null)
                                    Text(
                                      '${e['gamesPlayed']} game${(e['gamesPlayed'] as int) == 1 ? '' : 's'} played',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Score
                            Text(
                              '$score pts',
                              style: TextStyle(
                                color: isMe ? Colors.amber : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
