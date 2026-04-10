import 'dart:math';
import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';
import 'package:elearningapp_flutter/planet_builder/solar_planet_data.dart';

/// Full-screen chemistry breakdown for a solar-system planet.
/// Tap any element card to flip it and read the kid-friendly explanation.
class PlanetChemistryScreen extends StatefulWidget {
  final SolarPlanetData planet;

  const PlanetChemistryScreen({Key? key, required this.planet})
    : super(key: key);

  @override
  State<PlanetChemistryScreen> createState() => _PlanetChemistryScreenState();
}

class _PlanetChemistryScreenState extends State<PlanetChemistryScreen>
    with TickerProviderStateMixin {
  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _heroCtrl; // zoom-in entrance
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  // ── State ─────────────────────────────────────────────────────────────────
  int? _flippedIndex; // which element card is showing its explanation

  @override
  void initState() {
    super.initState();

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heroScale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.elasticOut));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeIn);

    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = widget.planet;
    return Scaffold(
      backgroundColor: const Color(0xFF040D21),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildZoomedPlanet(),
                    const SizedBox(height: 16),
                    _buildChemistryNote(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('🧪 What\'s it made of?'),
                    const SizedBox(height: 10),
                    _buildCompositionBar(),
                    const SizedBox(height: 20),
                    _buildSectionHeader('👆 Tap each element to learn more!'),
                    const SizedBox(height: 10),
                    _buildElementGrid(),
                    const SizedBox(height: 20),
                    _buildFunFactCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.planet.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Chemistry Explorer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Grade badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF26C6DA)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎓 Grade 6',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zoomed planet with entrance animation ──────────────────────────────────

  Widget _buildZoomedPlanet() {
    return FadeTransition(
      opacity: _heroFade,
      child: ScaleTransition(
        scale: _heroScale,
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Star background
              CustomPaint(
                painter: _ChemStarfield(),
                child: const SizedBox.expand(),
              ),
              // Glowing halo
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final glow = 0.15 + _pulseCtrl.value * 0.1;
                  return Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _planetGlowColor().withOpacity(glow),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Planet
              PlanetPreview(
                planet: widget.planet.model,
                rotationController: _rotationCtrl,
                pulseController: _pulseCtrl,
              ),
              // Floating element labels around the planet
              ..._buildOrbitingLabels(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrbitingLabels() {
    final elements = widget.planet.elements;
    const radius = 105.0;
    final count = elements.length.clamp(0, 5);
    return List.generate(count, (i) {
      final angle = (2 * pi / count) * i - pi / 2;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      final el = elements[i];
      return Positioned(
        left: 110 + x - 20,
        top: 110 + y - 14,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + i * 120),
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: el.displayColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: el.displayColor.withOpacity(0.6)),
            ),
            child: Text(
              el.symbol,
              style: TextStyle(
                color: el.displayColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Chemistry note banner ─────────────────────────────────────────────────

  Widget _buildChemistryNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _planetGlowColor().withOpacity(0.18),
            _planetGlowColor().withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _planetGlowColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('🔬', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.planet.chemistryNote,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Composition bar chart ─────────────────────────────────────────────────

  Widget _buildCompositionBar() {
    final elements =
        widget.planet.elements.where((e) => e.percentage > 0).toList();
    if (elements.isEmpty) return const SizedBox.shrink();

    final total = elements.fold<double>(0, (s, e) => s + e.percentage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                builder:
                    (_, v, __) => Row(
                      children:
                          elements.map((e) {
                            final fraction = (e.percentage / total) * v;
                            return Expanded(
                              flex: (fraction * 1000).round(),
                              child: Tooltip(
                                message: '${e.name}: ${e.percentage}%',
                                child: Container(color: e.displayColor),
                              ),
                            );
                          }).toList(),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children:
                elements.map((e) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.displayColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${e.symbol} ${e.percentage.toStringAsFixed(e.percentage < 1 ? 2 : 0)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Element cards grid (flip on tap) ─────────────────────────────────────

  Widget _buildElementGrid() {
    final elements = widget.planet.elements;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: elements.length,
      itemBuilder: (_, i) {
        final el = elements[i];
        final isFlipped = _flippedIndex == i;
        return GestureDetector(
          onTap: () => setState(() => _flippedIndex = isFlipped ? null : i),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child: isFlipped ? _elementBack(el, i) : _elementFront(el, i),
          ),
        );
      },
    );
  }

  Widget _elementFront(PlanetElement el, int i) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('front_$i'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + i * 80),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: el.displayColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: el.displayColor.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(el.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              el.symbol,
              style: TextStyle(
                color: el.displayColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              el.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (el.percentage > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${el.percentage.toStringAsFixed(el.percentage < 1 ? 2 : 0)}%',
                style: TextStyle(
                  color: el.displayColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.white30, size: 12),
                const SizedBox(width: 3),
                Text(
                  'tap to learn',
                  style: TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _elementBack(PlanetElement el, int i) {
    return Container(
      key: ValueKey('back_$i'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: el.displayColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: el.displayColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(el.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                el.kidFriendly,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '✕ tap to close',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Fun fact card ─────────────────────────────────────────────────────────

  Widget _buildFunFactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤯', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Did You Know?',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.planet.funFact,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _planetGlowColor() {
    switch (widget.planet.model.color) {
      case PlanetColor.blue:
        return const Color(0xFF4FC3F7);
      case PlanetColor.red:
        return const Color(0xFFEF5350);
      case PlanetColor.green:
        return const Color(0xFF66BB6A);
      case PlanetColor.orange:
        return const Color(0xFFFFA726);
      case PlanetColor.teal:
        return const Color(0xFF26C6DA);
      case PlanetColor.purple:
        return const Color(0xFFAB47BC);
      case PlanetColor.gold:
        return const Color(0xFFFFD54F);
      default:
        return const Color(0xFF4FC3F7);
    }
  }
}

// ── How to open this screen ──────────────────────────────────────────────────
//
// From your existing solar-system planet list / detail screen, add:
//
//   Navigator.push(
//     context,
//     PageRouteBuilder(
//       pageBuilder: (_, a, __) =>
//           PlanetChemistryScreen(planet: selectedPlanet),
//       transitionsBuilder: (_, anim, __, child) =>
//           FadeTransition(opacity: anim, child: child),
//     ),
//   );
//
// ─────────────────────────────────────────────────────────────────────────────

class _ChemStarfield extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rng = Random(99);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4;
      paint.color = Colors.white.withOpacity(rng.nextDouble() * 0.5 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
