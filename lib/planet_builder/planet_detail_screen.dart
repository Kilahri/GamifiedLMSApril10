import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';
import 'package:elearningapp_flutter/planet_builder/solar_planet_data.dart';
import 'package:elearningapp_flutter/planet_builder/score_service.dart';
import 'package:elearningapp_flutter/planet_builder/planet_chemistry_screen.dart';

/// Shows full detail for either a solar system planet or a user-created planet.
/// [solarData] is non-null for built-in planets (read-only).
/// [customPlanet] + [customName] are non-null for user planets.
class PlanetDetailScreen extends StatefulWidget {
  final SolarPlanetData? solarData;
  final PlanetModel? customPlanet;
  final String? customName;
  final String? customDocId;
  final String userId;
  final String ownerUsername;
  final VoidCallback? onDeleted;

  const PlanetDetailScreen({
    Key? key,
    this.solarData,
    this.customPlanet,
    this.customName,
    this.customDocId,
    required this.userId,
    required this.ownerUsername,
    this.onDeleted,
  }) : assert(solarData != null || customPlanet != null),
       super(key: key);

  @override
  State<PlanetDetailScreen> createState() => _PlanetDetailScreenState();
}

class _PlanetDetailScreenState extends State<PlanetDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  // Press-feedback scale for the planet tap
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnimation;

  bool _deleting = false;

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entryController.forward();

    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.87).animate(
      CurvedAnimation(parent: _tapScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    _tapScaleController.dispose();
    super.dispose();
  }

  PlanetModel get _planet => widget.solarData?.model ?? widget.customPlanet!;
  String get _name =>
      widget.solarData?.name ?? widget.customName ?? 'My Planet';
  bool get _isSolar => widget.solarData != null;

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Opens PlanetChemistryScreen with a smooth fade transition.
  /// Only available for solar planets (which have element/chemistry data).
  Future<void> _openChemistry() async {
    if (!_isSolar) return;

    await _tapScaleController.forward();
    await _tapScaleController.reverse();
    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, a, __) => PlanetChemistryScreen(planet: widget.solarData!),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteCustomPlanet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Planet?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "$_name"? This cannot be undone.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFEF5350)),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    await ScoreService.deleteCustomPlanet(
      docId: widget.customDocId!,
      ownerUserId: widget.userId,
      ownerUsername: widget.ownerUsername,
    );
    widget.onDeleted?.call();
    if (mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final solar = widget.solarData;
    final planet = _planet;

    return Scaffold(
      backgroundColor: const Color(0xFF040D21),
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: const Color(0xFF040D21),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isSolar && widget.customDocId != null)
                  IconButton(
                    icon:
                        _deleting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                            : const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF5350),
                            ),
                    onPressed: _deleting ? null : _deleteCustomPlanet,
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Starfield
                    CustomPaint(
                      painter: _StarBg(),
                      child: const SizedBox.expand(),
                    ),

                    // ── Tappable planet ───────────────────────────────────
                    // Solar planets navigate to chemistry; custom planets are
                    // non-interactive (no chemistry data available).
                    GestureDetector(
                      onTap: _isSolar ? _openChemistry : null,
                      child: ScaleTransition(
                        scale: _tapScaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing glow ring — tap affordance (solar only)
                            if (_isSolar)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, __) {
                                  final opacity =
                                      0.08 + _pulseController.value * 0.12;
                                  return Container(
                                    width: 165,
                                    height: 165,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4FC3F7,
                                        ).withOpacity(opacity),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Planet widget
                            PlanetPreview(
                              planet: planet,
                              rotationController: _rotationController,
                              pulseController: _pulseController,
                            ),

                            // "View Chemistry" hint label (solar only)
                            if (_isSolar)
                              Positioned(
                                bottom: 44,
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder:
                                      (_, __) => Opacity(
                                        opacity:
                                            0.5 + _pulseController.value * 0.4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF4FC3F7,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF4FC3F7,
                                              ).withOpacity(0.35),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.science_outlined,
                                                color: Color(0xFF4FC3F7),
                                                size: 11,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'View Chemistry',
                                                style: TextStyle(
                                                  color: Color(0xFF4FC3F7),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom gradient fade
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF040D21), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),

                    // Subtitle / type
                    const SizedBox(height: 4),
                    Text(
                      solar?.subtitle ?? planet.planetType,
                      style: const TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick stats
                    _statsRow(planet, solar),

                    const SizedBox(height: 24),

                    // Chemistry banner — solar planets only
                    if (_isSolar) ...[
                      _chemistryBannerButton(),
                      const SizedBox(height: 24),
                    ],

                    // Solar facts or custom score breakdown
                    if (solar != null) ...[
                      _sectionHeader('📖 About ${solar.name}'),
                      const SizedBox(height: 10),
                      Text(
                        solar.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _funFactCard(solar.funFact),
                      const SizedBox(height: 24),
                      _sectionHeader('🔭 Quick Facts'),
                      const SizedBox(height: 12),
                      _factsGrid(solar),
                      const SizedBox(height: 24),
                      _sectionHeader('✨ Key Characteristics'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            solar.keyFacts.map((f) => _factChip(f)).toList(),
                      ),
                    ] else ...[
                      _sectionHeader('🌍 Planet Stats'),
                      const SizedBox(height: 12),
                      _customStatsCard(planet),
                      const SizedBox(height: 24),
                      _sectionHeader('📊 Score Breakdown'),
                      const SizedBox(height: 12),
                      _scoreBreakdownCard(planet),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chemistry banner button ───────────────────────────────────────────────

  Widget _chemistryBannerButton() {
    return GestureDetector(
      onTap: _openChemistry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7C4DFF).withOpacity(0.3),
              const Color(0xFF4FC3F7).withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFFCE93D8),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Chemistry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Discover the elements that make up this planet',
                    style: TextStyle(color: Color(0xFFCE93D8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFCE93D8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat row ──────────────────────────────────────────────────────────────

  Widget _statsRow(PlanetModel planet, SolarPlanetData? solar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.25),
            const Color(0xFF4FC3F7).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCell(
            '🌍',
            'Gravity',
            solar != null ? '—' : '${planet.gravity.toStringAsFixed(1)}g',
          ),
          _vDivider(),
          _statCell('🌱', 'Life', '${planet.lifeChance}%'),
          _vDivider(),
          _statCell('⛈', 'Weather', planet.weatherSeverity),
          _vDivider(),
          _statCell('🌙', 'Moons', '${planet.moonCount}'),
        ],
      ),
    );
  }

  Widget _statCell(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1));

  // ── Shared section helpers ────────────────────────────────────────────────

  Widget _sectionHeader(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _funFactCard(String fact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fun Fact',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factsGrid(SolarPlanetData solar) {
    final facts = [
      ['☀️ Distance from Sun', solar.distanceFromSun],
      ['🔄 Orbital Period', solar.orbitalPeriod],
      ['📏 Diameter', solar.diameter],
      ['🌡 Temperature', solar.temperature],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: facts.map((f) => _factCard(f[0], f[1])).toList(),
    );
  }

  Widget _factCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 12),
      ),
    );
  }

  Widget _customStatsCard(PlanetModel planet) {
    final attrs = [
      ['Size', _sizeName(planet.size)],
      ['Atmosphere', _atmName(planet.atmosphere)],
      ['Rings', planet.hasRings ? 'Yes' : 'No'],
      ['Moons', '${planet.moonCount}'],
      ['Planet Type', planet.planetType],
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children:
            attrs
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          a[0],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          a[1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _scoreBreakdownCard(PlanetModel planet) {
    final breakdown = ScoreService.getBreakdown(planet);
    final total = ScoreService.calculateScore(planet);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.2),
            const Color(0xFF4FC3F7).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ...breakdown.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
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
                    '+${e.value}',
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
          const Divider(color: Color(0x22FFFFFF), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Score',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$total pts',
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
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _sizeName(double size) {
    if (size < 0.25) return 'Tiny';
    if (size < 0.45) return 'Small';
    if (size < 0.65) return 'Medium';
    if (size < 0.85) return 'Large';
    return 'Giant';
  }

  String _atmName(AtmosphereType type) {
    switch (type) {
      case AtmosphereType.none:
        return 'None';
      case AtmosphereType.thin:
        return 'Thin';
      case AtmosphereType.earth:
        return 'Earthlike';
      case AtmosphereType.thick:
        return 'Thick';
      case AtmosphereType.toxic:
        return 'Toxic';
    }
  }
}

// ── Star background painter ────────────────────────────────────────────────

class _StarBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    int s = 77;
    double rng() {
      s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (s & 0xFFFF) / 65535.0;
    }

    for (int i = 0; i < 80; i++) {
      paint.color = Colors.white.withOpacity(rng() * 0.5 + 0.1);
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
