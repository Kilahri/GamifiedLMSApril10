import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/score_service.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';
import 'package:elearningapp_flutter/leaderboard/combined_leaderboard_screen.dart';
import 'package:elearningapp_flutter/play/planet_builder_screen.dart';
import 'package:elearningapp_flutter/planet_builder/planet_gallery_screen.dart'; // ← NEW

class ResultScreen extends StatefulWidget {
  final PlanetModel planet;
  final int score;
  final String username;
  final String userId;

  const ResultScreen({
    Key? key,
    required this.planet,
    required this.score,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  int? _userRank;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
    _loadRank();
  }

  void _loadRank() async {
    final rank = await ScoreService.getUserRank(widget.userId);
    if (mounted) setState(() => _userRank = rank);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _goToLeaderboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CombinedLeaderboardScreen(currentUserId: widget.userId),
      ),
    );
  }

  void _buildAgain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) => PlanetBuilderScreen(
              userId: widget.userId,
              username: widget.username,
            ),
      ),
      (route) => false,
    );
  }

  void _viewMyPlanets() {
    debugPrint('🔍 userId being passed to gallery: ${widget.userId}'); // ← ADD
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (_) => PlanetGalleryScreen(
              userId: widget.userId,
              username: widget.username,
              initialTab: 1,
            ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = ScoreService.getBreakdown(widget.planet);

    return Scaffold(
      backgroundColor: const Color(0xFF040D21),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '🚀 Planet Launched!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.planet.planetType,
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Planet preview
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: _StarBg(),
                          child: const SizedBox.expand(),
                        ),
                        PlanetPreview(
                          planet: widget.planet,
                          rotationController: _rotationController,
                          pulseController: _pulseController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Score / rank / life row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1565C0).withOpacity(0.3),
                          const Color(0xFF4FC3F7).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4FC3F7).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bigStat('⭐', 'Score', '${widget.score}'),
                        _divider(),
                        _bigStat(
                          '🏆',
                          'Rank',
                          _userRank != null ? '#$_userRank' : '…',
                        ),
                        _divider(),
                        _bigStat('🌱', 'Life', '${widget.planet.lifeChance}%'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Score breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score Breakdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...breakdown.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '+${e.value} pts',
                                  style: const TextStyle(
                                    color: Color(0xFF4FC3F7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: Color(0x22FFFFFF), height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${widget.score} pts',
                              style: const TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Action buttons row ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToLeaderboard,
                          icon: const Icon(
                            Icons.leaderboard,
                            color: Color(0xFFFFD54F),
                          ),
                          label: const Text(
                            'Leaderboard',
                            style: TextStyle(color: Colors.white70),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _buildAgain,
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Build Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FC3F7),
                            foregroundColor: const Color(0xFF040D21),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ← NEW: View My Planets button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _viewMyPlanets,
                      icon: const Icon(Icons.public, size: 18),
                      label: const Text('View My Planets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2A4A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: const Color(0xFF4FC3F7).withOpacity(0.4),
                          ),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigStat(String emoji, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1));
}

class _StarBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    int s = 42;
    double rng() {
      s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (s & 0xFFFF) / 65535.0;
    }

    for (int i = 0; i < 60; i++) {
      paint.color = Colors.white.withOpacity(rng() * 0.5 + 0.15);
      canvas.drawCircle(
        Offset(rng() * size.width, rng() * size.height),
        rng() * 1.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
