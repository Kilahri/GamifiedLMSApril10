enum AtmosphereType { none, thin, earth, thick, toxic }

enum PlanetColor { blue, red, green, purple, orange, teal, white, gold }

enum SurfaceType { rocky, oceanic, volcanic, frozen, desert, forest }

enum StarType { redDwarf, yellowStar, blueGiant, binaryStar, neutronStar }

enum RingType { none, dust, ice, rocky }

class PlanetModel {
  final double size; // 0.1 – 1.0
  final AtmosphereType atmosphere;
  final bool hasRings;
  final RingType ringType;
  final int moonCount; // 0 – 5
  final PlanetColor color;
  final String ownerId;
  final String ownerName;

  // ── NEW FIELDS ─────────────────────────────────────────────────────────
  final SurfaceType surfaceType;
  final StarType starType;
  final bool magneticField;
  final int tectonicActivity; // 0–5
  final double dayLength; // 0.1–3.0 (Earth = 1.0)
  final double orbitalDistance; // 0.5–3.0 (Earth = 1.0 AU)
  final bool hasOceans;
  final int cloudCoverage; // 0–100 %

  PlanetModel({
    required this.size,
    required this.atmosphere,
    this.hasRings = false,
    this.ringType = RingType.none,
    required this.moonCount,
    required this.color,
    required this.ownerId,
    required this.ownerName,
    this.surfaceType = SurfaceType.rocky,
    this.starType = StarType.yellowStar,
    this.magneticField = false,
    this.tectonicActivity = 2,
    this.dayLength = 1.0,
    this.orbitalDistance = 1.0,
    this.hasOceans = false,
    this.cloudCoverage = 30,
  });

  // ── COMPUTED PROPERTIES ────────────────────────────────────────────────

  /// Gravity in g (Earth = 1.0g at size 0.5)
  double get gravity => (size * 2.0).clamp(0.1, 3.0);

  /// Approximate average surface temperature (°C)
  double get avgTemperature {
    double base;
    switch (starType) {
      case StarType.redDwarf:
        base = -60;
        break;
      case StarType.yellowStar:
        base = 15;
        break;
      case StarType.blueGiant:
        base = 200;
        break;
      case StarType.binaryStar:
        base = 80;
        break;
      case StarType.neutronStar:
        base = 500;
        break;
    }

    // Orbital distance: further = colder
    base -= (orbitalDistance - 1.0) * 70;

    // Atmosphere greenhouse effect
    switch (atmosphere) {
      case AtmosphereType.thick:
        base += 50;
        break;
      case AtmosphereType.toxic:
        base += 80;
        break;
      case AtmosphereType.earth:
        base += 15;
        break;
      case AtmosphereType.thin:
        base -= 10;
        break;
      case AtmosphereType.none:
        base -= 30;
        break;
    }

    // Magnetic field regulates slightly
    if (magneticField) base -= 8;

    // Oceans moderate temperature
    if (hasOceans) base = base * 0.85;

    // Cloud coverage reflects sunlight
    base -= (cloudCoverage / 100) * 15;

    return base;
  }

  String get temperatureString {
    final t = avgTemperature.toInt();
    if (t > 400) return '$t°C 💀';
    if (t > 100) return '$t°C 🔥';
    if (t > 40) return '$t°C ☀️';
    if (t >= -10) return '$t°C 🌡';
    if (t >= -60) return '$t°C 🥶';
    return '$t°C ❄️';
  }

  /// Life chance % (0–100)
  int get lifeChance {
    if (atmosphere == AtmosphereType.none) return 0;
    if (atmosphere == AtmosphereType.toxic && !magneticField) return 2;

    int base = 0;
    switch (atmosphere) {
      case AtmosphereType.earth:
        base = 60;
        break;
      case AtmosphereType.thin:
        base = 12;
        break;
      case AtmosphereType.thick:
        base = 20;
        break;
      case AtmosphereType.toxic:
        base = 5;
        break;
      case AtmosphereType.none:
        base = 0;
        break;
    }

    // Size sweet spot
    if (size >= 0.3 && size <= 0.7) base += 15;

    // Moons stabilize axial tilt
    if (moonCount >= 1) base += 8;
    if (moonCount >= 2) base += 4;

    // Magnetic field shields from radiation
    if (magneticField) {
      base += 18;
    } else {
      switch (starType) {
        case StarType.blueGiant:
          base -= 25;
          break;
        case StarType.neutronStar:
          base -= 40;
          break;
        case StarType.binaryStar:
          base -= 8;
          break;
        default:
          base -= 5;
      }
    }

    // Star type
    switch (starType) {
      case StarType.yellowStar:
        base += 12;
        break;
      case StarType.redDwarf:
        base += 4;
        break;
      case StarType.blueGiant:
        base -= 15;
        break;
      case StarType.neutronStar:
        base -= 35;
        break;
      case StarType.binaryStar:
        base -= 3;
        break;
    }

    // Temperature sweet spot (-20 to 60°C)
    final t = avgTemperature;
    if (t >= -20 && t <= 60) {
      base += 20;
    } else if (t >= -50 && t < -20) {
      base += 5;
    } else if (t > 60 && t <= 100) {
      base -= 10;
    } else {
      base -= 30;
    }

    // Tectonic activity (moderate = good for nutrient cycling)
    if (tectonicActivity == 2 || tectonicActivity == 3) {
      base += 12;
    } else if (tectonicActivity >= 5) {
      base -= 20;
    } else if (tectonicActivity == 0) {
      base -= 5;
    }

    // Surface type
    switch (surfaceType) {
      case SurfaceType.oceanic:
        base += 20;
        break;
      case SurfaceType.forest:
        base += 25;
        break;
      case SurfaceType.volcanic:
        base -= 15;
        break;
      case SurfaceType.frozen:
        base -= 8;
        break;
      case SurfaceType.desert:
        base -= 5;
        break;
      case SurfaceType.rocky:
        break;
    }

    // Oceans are critical for life
    if (hasOceans) base += 15;

    // Orbital distance (habitable zone ~0.7–1.5 AU for yellow star)
    if (orbitalDistance >= 0.7 && orbitalDistance <= 1.5) base += 10;

    return base.clamp(0, 100);
  }

  /// Weather severity label
  String get weatherSeverity {
    if (atmosphere == AtmosphereType.none) return 'None';
    if (tectonicActivity >= 5) return 'Catastrophic';
    if (atmosphere == AtmosphereType.toxic) return 'Extreme';
    if (atmosphere == AtmosphereType.thick || cloudCoverage > 70)
      return 'Stormy';
    if (atmosphere == AtmosphereType.earth) {
      return moonCount > 0 ? 'Moderate' : 'Variable';
    }
    return 'Mild';
  }

  /// Radiation level label
  String get radiationLevel {
    if (magneticField) {
      if (starType == StarType.neutronStar) return 'High';
      return 'Protected';
    }
    switch (starType) {
      case StarType.neutronStar:
        return 'Lethal';
      case StarType.blueGiant:
        return 'Extreme';
      case StarType.binaryStar:
        return 'High';
      case StarType.yellowStar:
        return 'Moderate';
      case StarType.redDwarf:
        return 'Low';
    }
  }

  /// Civilization potential
  String get civilizationPotential {
    final lc = lifeChance;
    if (lc >= 75) return 'Advanced';
    if (lc >= 55) return 'Emerging';
    if (lc >= 35) return 'Primitive';
    if (lc >= 15) return 'Microbial';
    return 'None';
  }

  /// Day length label
  String get dayLengthLabel {
    if (dayLength < 0.3) return 'Ultra-Short';
    if (dayLength < 0.7) return 'Short';
    if (dayLength < 1.4) return 'Earth-like';
    if (dayLength < 2.0) return 'Long';
    return 'Ultra-Long';
  }

  /// Descriptive planet type
  String get planetType {
    if (atmosphere == AtmosphereType.none && size < 0.3)
      return 'Barren Asteroid';
    if (starType == StarType.neutronStar) return 'Irradiated Ruin';
    if (surfaceType == SurfaceType.volcanic && tectonicActivity >= 4)
      return 'Volcanic Hellscape';
    if (surfaceType == SurfaceType.frozen && avgTemperature < -80)
      return 'Frozen Wasteland';
    if (atmosphere == AtmosphereType.earth && lifeChance > 60)
      return 'Habitable World';
    if (atmosphere == AtmosphereType.toxic) return 'Toxic Hellscape';
    if (size > 0.8 && atmosphere == AtmosphereType.thick) return 'Gas Giant';
    if (surfaceType == SurfaceType.oceanic && lifeChance > 30)
      return 'Ocean World';
    if (surfaceType == SurfaceType.forest && lifeChance > 40)
      return 'Jungle World';
    if (surfaceType == SurfaceType.desert) return 'Desert World';
    if (atmosphere == AtmosphereType.thick) return 'Clouded World';
    if (moonCount >= 3) return 'Moon-Rich Planet';
    if (ringType != RingType.none) return 'Ringed World';
    if (starType == StarType.binaryStar) return 'Binary Star World';
    return 'Rocky Planet';
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'atmosphere': atmosphere.name,
      'hasRings': hasRings,
      'ringType': ringType.name,
      'moonCount': moonCount,
      'color': color.name,
      'gravity': gravity,
      'lifeChance': lifeChance,
      'weatherSeverity': weatherSeverity,
      'planetType': planetType,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'surfaceType': surfaceType.name,
      'starType': starType.name,
      'magneticField': magneticField,
      'tectonicActivity': tectonicActivity,
      'dayLength': dayLength,
      'orbitalDistance': orbitalDistance,
      'hasOceans': hasOceans,
      'cloudCoverage': cloudCoverage,
      'avgTemperature': avgTemperature,
      'radiationLevel': radiationLevel,
      'civilizationPotential': civilizationPotential,
    };
  }

  factory PlanetModel.fromMap(Map<String, dynamic> map) {
    return PlanetModel(
      size: (map['size'] as num).toDouble(),
      atmosphere: AtmosphereType.values.firstWhere(
        (e) => e.name == map['atmosphere'],
        orElse: () => AtmosphereType.none,
      ),
      hasRings: map['hasRings'] ?? false,
      ringType: RingType.values.firstWhere(
        (e) => e.name == (map['ringType'] ?? 'none'),
        orElse: () => RingType.none,
      ),
      moonCount: map['moonCount'] ?? 0,
      color: PlanetColor.values.firstWhere(
        (e) => e.name == map['color'],
        orElse: () => PlanetColor.blue,
      ),
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      surfaceType: SurfaceType.values.firstWhere(
        (e) => e.name == (map['surfaceType'] ?? 'rocky'),
        orElse: () => SurfaceType.rocky,
      ),
      starType: StarType.values.firstWhere(
        (e) => e.name == (map['starType'] ?? 'yellowStar'),
        orElse: () => StarType.yellowStar,
      ),
      magneticField: map['magneticField'] ?? false,
      tectonicActivity: map['tectonicActivity'] ?? 2,
      dayLength: (map['dayLength'] as num?)?.toDouble() ?? 1.0,
      orbitalDistance: (map['orbitalDistance'] as num?)?.toDouble() ?? 1.0,
      hasOceans: map['hasOceans'] ?? false,
      cloudCoverage: map['cloudCoverage'] ?? 30,
    );
  }
}
