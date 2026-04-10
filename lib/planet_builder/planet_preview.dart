import 'dart:math';
import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';

class PlanetPreview extends StatelessWidget {
  final PlanetModel planet;
  final AnimationController rotationController;
  final AnimationController pulseController;

  const PlanetPreview({
    Key? key,
    required this.planet,
    required this.rotationController,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotationController, pulseController]),
      builder: (context, child) {
        final glow = 0.6 + pulseController.value * 0.4;
        return CustomPaint(
          painter: PlanetPainter(
            planet: planet,
            rotation: rotationController.value,
            glowIntensity: glow,
            pulseValue: pulseController.value,
          ),
          size: const Size(220, 220),
        );
      },
    );
  }
}

class PlanetPainter extends CustomPainter {
  final PlanetModel planet;
  final double rotation;
  final double glowIntensity;
  final double pulseValue;

  PlanetPainter({
    required this.planet,
    required this.rotation,
    required this.glowIntensity,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 50.0 + planet.size * 50.0;

    // 1. Star ambient glow (behind everything)
    _drawStarGlow(canvas, center, baseRadius);

    // 2. Atmosphere outer glow
    if (planet.atmosphere != AtmosphereType.none) {
      _drawAtmosphereGlow(canvas, center, baseRadius);
    }

    // 3. Aurora (magnetic field effect) — behind planet
    if (planet.magneticField) {
      _drawAurora(canvas, center, baseRadius, front: false);
    }

    // 4. Rings behind
    if (planet.hasRings) {
      _drawRings(canvas, center, baseRadius, front: false);
    }

    // 5. Planet body
    _drawPlanetBody(canvas, center, baseRadius);

    // 6. Surface details based on surface type
    _drawSurfaceDetails(canvas, center, baseRadius);

    // 7. Cloud layer
    if (planet.cloudCoverage > 10) {
      _drawClouds(canvas, center, baseRadius);
    }

    // 8. Rings in front
    if (planet.hasRings) {
      _drawRings(canvas, center, baseRadius, front: true);
    }

    // 9. Aurora in front
    if (planet.magneticField) {
      _drawAurora(canvas, center, baseRadius, front: true);
    }

    // 10. Moons
    _drawMoons(canvas, center, baseRadius);

    // 11. Shine
    _drawShine(canvas, center, baseRadius);
  }

  // ── Star ambient glow ─────────────────────────────────────────────────

  void _drawStarGlow(Canvas canvas, Offset center, double radius) {
    final starColor = _starGlowColor();
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              starColor.withOpacity(0.0),
              starColor.withOpacity(0.06 * glowIntensity),
              starColor.withOpacity(0.0),
            ],
            stops: const [0.3, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2));
    canvas.drawCircle(center, radius * 2.2, paint);
  }

  // ── Atmosphere glow ───────────────────────────────────────────────────

  void _drawAtmosphereGlow(Canvas canvas, Offset center, double radius) {
    final atmColor = _atmosphereColor();
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              atmColor.withOpacity(0.0),
              atmColor.withOpacity(0.12 * glowIntensity),
              atmColor.withOpacity(0.28 * glowIntensity),
              atmColor.withOpacity(0.0),
            ],
            stops: const [0.5, 0.72, 0.88, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.5, paint);
  }

  // ── Aurora ────────────────────────────────────────────────────────────

  void _drawAurora(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool front,
  }) {
    final auroraColors = [
      const Color(0xFF69FF8A), // green
      const Color(0xFF4FFEF5), // cyan
      const Color(0xFFAB47BC), // purple
    ];

    canvas.save();
    if (front) {
      canvas.clipRect(Rect.fromLTWH(0, center.dy - radius * 0.15, 9999, 9999));
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, 9999, center.dy + radius * 0.15));
    }

    for (int i = 0; i < 3; i++) {
      final aColor = auroraColors[i % auroraColors.length];
      final expand = 1.15 + i * 0.08 + pulseValue * 0.04;
      final auroraRect = Rect.fromCenter(
        center: center,
        width: radius * 2 * expand,
        height: radius * 0.3 + i * radius * 0.05,
      );
      final aurPaint =
          Paint()
            ..color = aColor.withOpacity((0.22 - i * 0.05) * glowIntensity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 - i * 0.5;
      canvas.drawOval(auroraRect, aurPaint);
    }
    canvas.restore();
  }

  // ── Planet body ───────────────────────────────────────────────────────

  void _drawPlanetBody(Canvas canvas, Offset center, double radius) {
    final baseColor = _planetColorValue();
    final surfaceColor = _surfaceBaseColor();

    // Blend planet color with surface color
    final blended = Color.lerp(baseColor, surfaceColor, 0.4)!;
    final darkColor =
        HSLColor.fromColor(blended)
            .withLightness(
              (HSLColor.fromColor(blended).lightness - 0.2).clamp(0.0, 1.0),
            )
            .toColor();

    final paint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [blended.withOpacity(1), darkColor],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Clip future drawings to planet shape
  }

  // ── Surface details ───────────────────────────────────────────────────

  void _drawSurfaceDetails(Canvas canvas, Offset center, double radius) {
    canvas.save();
    // Clip to planet circle
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    switch (planet.surfaceType) {
      case SurfaceType.oceanic:
        _drawOceanicSurface(canvas, center, radius);
        break;
      case SurfaceType.volcanic:
        _drawVolcanicSurface(canvas, center, radius);
        break;
      case SurfaceType.frozen:
        _drawFrozenSurface(canvas, center, radius);
        break;
      case SurfaceType.forest:
        _drawForestSurface(canvas, center, radius);
        break;
      case SurfaceType.desert:
        _drawDesertSurface(canvas, center, radius);
        break;
      case SurfaceType.rocky:
        _drawRockySurface(canvas, center, radius);
        break;
    }
    canvas.restore();

    // Animated bands (always present, on top of surface)
    _drawAtmosphericBands(canvas, center, radius);
  }

  void _drawOceanicSurface(Canvas canvas, Offset center, double radius) {
    final r = Random(7);
    // Deep ocean base swirls
    final wavePaint =
        Paint()
          ..color = const Color(0xFF0D47A1).withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.12;
    for (int i = 0; i < 5; i++) {
      final yOff = -radius + (i / 4) * radius * 2;
      final hw =
          sqrt(max(0, radius * radius - yOff * yOff)) *
          (0.7 + r.nextDouble() * 0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(r.nextDouble() * 10 - 5, yOff),
          width: hw * 2,
          height: radius * 0.18,
        ),
        wavePaint,
      );
    }
    // Small continent patches
    final landPaint =
        Paint()
          ..color = const Color(0xFF2E7D32).withOpacity(0.55)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final angle = (r.nextDouble() * 2 - 1) * pi * 0.6;
      final dist = r.nextDouble() * radius * 0.5;
      final cx = center.dx + cos(angle) * dist;
      final cy = center.dy + sin(angle) * dist * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: radius * (0.2 + r.nextDouble() * 0.3),
          height: radius * (0.12 + r.nextDouble() * 0.15),
        ),
        landPaint,
      );
    }
  }

  void _drawVolcanicSurface(Canvas canvas, Offset center, double radius) {
    final r = Random(13);
    // Dark cracked surface
    final crackPaint =
        Paint()
          ..color = const Color(0xFFFF6D00).withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    for (int i = 0; i < 12; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist1 = r.nextDouble() * radius * 0.5;
      final dist2 = dist1 + radius * (0.15 + r.nextDouble() * 0.3);
      canvas.drawLine(
        center.translate(cos(angle) * dist1, sin(angle) * dist1 * 0.6),
        center.translate(cos(angle + 0.3) * dist2, sin(angle) * dist2 * 0.6),
        crackPaint,
      );
    }
    // Lava pools
    final lavaPaint =
        Paint()
          ..color = const Color(0xFFFF3D00).withOpacity(0.7 + pulseValue * 0.2)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.65;
      canvas.drawCircle(
        center.translate(cos(angle) * dist, sin(angle) * dist * 0.55),
        radius * (0.03 + r.nextDouble() * 0.05),
        lavaPaint,
      );
    }
  }

  void _drawFrozenSurface(Canvas canvas, Offset center, double radius) {
    final r = Random(21);
    // Ice caps at poles
    final icePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..style = PaintingStyle.fill;
    // North pole cap
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -radius * 0.72),
        width: radius * 0.7,
        height: radius * 0.3,
      ),
      icePaint,
    );
    // South pole cap
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.72),
        width: radius * 0.5,
        height: radius * 0.22,
      ),
      icePaint,
    );
    // Random ice patches
    final patchPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.6;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(cos(angle) * dist, sin(angle) * dist * 0.6),
          width: radius * (0.08 + r.nextDouble() * 0.15),
          height: radius * (0.05 + r.nextDouble() * 0.1),
        ),
        patchPaint,
      );
    }
  }

  void _drawForestSurface(Canvas canvas, Offset center, double radius) {
    final r = Random(33);
    // Green patches
    for (int i = 0; i < 7; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.7;
      final shade =
          r.nextBool() ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32);
      final paint =
          Paint()
            ..color = shade.withOpacity(0.55)
            ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(cos(angle) * dist, sin(angle) * dist * 0.6),
          width: radius * (0.18 + r.nextDouble() * 0.28),
          height: radius * (0.12 + r.nextDouble() * 0.18),
        ),
        paint,
      );
    }
    // Blue water patches
    final waterPaint =
        Paint()
          ..color = const Color(0xFF1565C0).withOpacity(0.40)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(cos(angle) * dist, sin(angle) * dist * 0.6),
          width: radius * (0.1 + r.nextDouble() * 0.18),
          height: radius * (0.07 + r.nextDouble() * 0.12),
        ),
        waterPaint,
      );
    }
  }

  void _drawDesertSurface(Canvas canvas, Offset center, double radius) {
    final r = Random(45);
    // Dune bands
    final dunePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.08;
    for (int i = 0; i < 6; i++) {
      final yOff = -radius * 0.7 + (i / 5) * radius * 1.4;
      dunePaint.color = (i.isEven
              ? const Color(0xFFF57F17)
              : const Color(0xFFE65100))
          .withOpacity(0.3);
      final hw = sqrt(max(0, radius * radius - yOff * yOff));
      if (hw > 0) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(r.nextDouble() * 6 - 3, yOff),
            width: hw * 1.8,
            height: radius * 0.1,
          ),
          dunePaint,
        );
      }
    }
    // Rocky formations
    final rockPaint =
        Paint()
          ..color = const Color(0xFFBF360C).withOpacity(0.4)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.55;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(cos(angle) * dist, sin(angle) * dist * 0.6),
          width: radius * (0.06 + r.nextDouble() * 0.1),
          height: radius * (0.04 + r.nextDouble() * 0.07),
        ),
        rockPaint,
      );
    }
  }

  void _drawRockySurface(Canvas canvas, Offset center, double radius) {
    final r = Random(55);
    // Craters
    final craterPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill;
    final craterRim =
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final angle = r.nextDouble() * 2 * pi;
      final dist = r.nextDouble() * radius * 0.7;
      final cr = radius * (0.04 + r.nextDouble() * 0.08);
      final pos = center.translate(cos(angle) * dist, sin(angle) * dist * 0.6);
      canvas.drawCircle(pos, cr, craterPaint);
      canvas.drawCircle(pos, cr, craterRim);
    }
  }

  void _drawAtmosphericBands(Canvas canvas, Offset center, double radius) {
    if (planet.atmosphere == AtmosphereType.none) return;

    // Clip to planet
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final bandPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.16;

    final offsets = [-0.35, 0.0, 0.35];
    for (final offset in offsets) {
      final yPos = center.dy + offset * radius;
      final hw = sqrt(
        max(0.0, radius * radius - (offset * radius) * (offset * radius)),
      );
      if (hw > 0) {
        bandPaint.color = Colors.white.withOpacity(0.055);
        canvas.drawLine(
          Offset(center.dx - hw, yPos),
          Offset(center.dx + hw, yPos),
          bandPaint,
        );
      }
    }
    canvas.restore();
  }

  // ── Cloud layer ───────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final coverage = planet.cloudCoverage / 100.0;
    final r = Random(66);
    final cloudPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.22 * coverage)
          ..style = PaintingStyle.fill;

    final count = (coverage * 10).round();
    for (int i = 0; i < count; i++) {
      // Drift with rotation
      final baseAngle = (i / count) * 2 * pi;
      final driftAngle = baseAngle + rotation * 2 * pi * 0.3;
      final dist = r.nextDouble() * radius * 0.65;
      final cx = center.dx + cos(driftAngle) * dist;
      final cy = center.dy + sin(driftAngle) * dist * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: radius * (0.18 + r.nextDouble() * 0.25),
          height: radius * (0.06 + r.nextDouble() * 0.08),
        ),
        cloudPaint,
      );
    }
    canvas.restore();
  }

  // ── Rings ──────────────────────────────────────────────────────────────

  void _drawRings(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool front,
  }) {
    final ringColor = _ringColor();

    final ringPaint =
        Paint()
          ..color = ringColor.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.13;

    final ringRect = Rect.fromCenter(
      center: center,
      width: radius * 2.8,
      height: radius * 0.6,
    );

    canvas.save();
    if (front) {
      canvas.clipRect(Rect.fromLTWH(0, center.dy, 9999, 9999));
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, 9999, center.dy));
    }

    canvas.drawOval(ringRect, ringPaint);

    // Second ring
    final ringPaint2 =
        Paint()
          ..color = ringColor.withOpacity(0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.07;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 3.3,
        height: radius * 0.75,
      ),
      ringPaint2,
    );

    // Third thin ring
    final ringPaint3 =
        Paint()
          ..color = ringColor.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.04;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * 3.8,
        height: radius * 0.88,
      ),
      ringPaint3,
    );

    canvas.restore();
  }

  // ── Moons ──────────────────────────────────────────────────────────────

  void _drawMoons(Canvas canvas, Offset center, double radius) {
    final moonPaint = Paint()..color = const Color(0xFFB0BEC5);
    final moonShadow = Paint()..color = Colors.black.withOpacity(0.4);

    for (int i = 0; i < planet.moonCount; i++) {
      final angle = (rotation * 2 * pi) + (i * 2 * pi / planet.moonCount);
      final orbitRadius = radius + 28.0 + i * 16.0;
      final moonRadius = 5.0 + i * 1.5;
      final mx = center.dx + cos(angle) * orbitRadius;
      final my = center.dy + sin(angle) * orbitRadius * 0.42;

      // Shadow
      canvas.drawCircle(Offset(mx, my), moonRadius + 1, moonShadow);
      canvas.drawCircle(Offset(mx, my), moonRadius, moonPaint);

      // Highlight
      canvas.drawCircle(
        Offset(mx - moonRadius * 0.3, my - moonRadius * 0.3),
        moonRadius * 0.4,
        Paint()..color = Colors.white.withOpacity(0.45),
      );
    }
  }

  // ── Shine ──────────────────────────────────────────────────────────────

  void _drawShine(Canvas canvas, Offset center, double radius) {
    final shinePaint =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.5, -0.5),
            colors: [
              Colors.white.withOpacity(0.32),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.6],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, shinePaint);
  }

  // ── Color helpers ──────────────────────────────────────────────────────

  Color _planetColorValue() {
    switch (planet.color) {
      case PlanetColor.blue:
        return const Color(0xFF1565C0);
      case PlanetColor.red:
        return const Color(0xFFC62828);
      case PlanetColor.green:
        return const Color(0xFF2E7D32);
      case PlanetColor.purple:
        return const Color(0xFF6A1B9A);
      case PlanetColor.orange:
        return const Color(0xFFE65100);
      case PlanetColor.teal:
        return const Color(0xFF00695C);
      case PlanetColor.white:
        return const Color(0xFFB0BEC5);
      case PlanetColor.gold:
        return const Color(0xFFF9A825);
    }
  }

  Color _surfaceBaseColor() {
    switch (planet.surfaceType) {
      case SurfaceType.oceanic:
        return const Color(0xFF0D47A1);
      case SurfaceType.volcanic:
        return const Color(0xFF3E2723);
      case SurfaceType.frozen:
        return const Color(0xFFE3F2FD);
      case SurfaceType.forest:
        return const Color(0xFF1B5E20);
      case SurfaceType.desert:
        return const Color(0xFFE65100);
      case SurfaceType.rocky:
        return const Color(0xFF546E7A);
    }
  }

  Color _atmosphereColor() {
    switch (planet.atmosphere) {
      case AtmosphereType.earth:
        return const Color(0xFF4FC3F7);
      case AtmosphereType.toxic:
        return const Color(0xFF76FF03);
      case AtmosphereType.thick:
        return const Color(0xFFFFF176);
      case AtmosphereType.thin:
        return const Color(0xFFB0BEC5);
      case AtmosphereType.none:
        return Colors.transparent;
    }
  }

  Color _starGlowColor() {
    switch (planet.starType) {
      case StarType.redDwarf:
        return const Color(0xFFFF5722);
      case StarType.yellowStar:
        return const Color(0xFFFFEB3B);
      case StarType.blueGiant:
        return const Color(0xFF90CAF9);
      case StarType.binaryStar:
        return const Color(0xFFFFCC02);
      case StarType.neutronStar:
        return const Color(0xFF80DEEA);
    }
  }

  Color _ringColor() {
    switch (planet.ringType) {
      case RingType.ice:
        return const Color(0xFFB3E5FC);
      case RingType.rocky:
        return const Color(0xFF8D6E63);
      case RingType.dust:
        return const Color(0xFFD7CCC8);
      case RingType.none:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(PlanetPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.glowIntensity != glowIntensity ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.planet.size != planet.size ||
      oldDelegate.planet.surfaceType != planet.surfaceType ||
      oldDelegate.planet.starType != planet.starType ||
      oldDelegate.planet.magneticField != planet.magneticField ||
      oldDelegate.planet.cloudCoverage != planet.cloudCoverage;
}
