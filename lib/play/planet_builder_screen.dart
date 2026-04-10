import 'dart:math';
import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/score_service.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';
import 'package:elearningapp_flutter/planet_builder/slider_card.dart';
import 'package:elearningapp_flutter/leaderboard/combined_leaderboard_screen.dart';
import 'package:elearningapp_flutter/planet_builder/result_screen.dart';

// ── Tab categories ─────────────────────────────────────────────────────────
enum _Tab { core, environment, orbit, features }

class PlanetBuilderScreen extends StatefulWidget {
  final String userId;
  final String username;

  const PlanetBuilderScreen({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<PlanetBuilderScreen> createState() => _PlanetBuilderScreenState();
}

class _PlanetBuilderScreenState extends State<PlanetBuilderScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _tabSlideController;

  // ── Planet properties ─────────────────────────────────────────────────
  double _size = 0.5;
  AtmosphereType _atmosphere = AtmosphereType.earth;
  bool _hasRings = false;
  RingType _ringType = RingType.none;
  int _moonCount = 1;
  PlanetColor _planetColor = PlanetColor.blue;

  // NEW
  SurfaceType _surfaceType = SurfaceType.rocky;
  StarType _starType = StarType.yellowStar;
  bool _magneticField = false;
  int _tectonicActivity = 2;
  double _dayLength = 1.0;
  double _orbitalDistance = 1.0;
  bool _hasOceans = false;
  int _cloudCoverage = 30;

  _Tab _activeTab = _Tab.core;

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
    _tabSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _tabSlideController.dispose();
    super.dispose();
  }

  PlanetModel get _currentPlanet => PlanetModel(
    size: _size,
    atmosphere: _atmosphere,
    hasRings: _hasRings,
    ringType: _hasRings ? _ringType : RingType.none,
    moonCount: _moonCount,
    color: _planetColor,
    ownerId: widget.userId,
    ownerName: widget.username,
    surfaceType: _surfaceType,
    starType: _starType,
    magneticField: _magneticField,
    tectonicActivity: _tectonicActivity,
    dayLength: _dayLength,
    orbitalDistance: _orbitalDistance,
    hasOceans: _hasOceans,
    cloudCoverage: _cloudCoverage,
  );

  void _finishAndSubmit() async {
    final planetName = await _askPlanetName();
    if (planetName == null) return;

    final planet = _currentPlanet;
    final score = ScoreService.calculateScore(planet);

    try {
      await ScoreService.saveCustomPlanet(
        userId: widget.userId,
        username: widget.username,
        planetName: planetName,
        planet: planet,
      );
    } catch (e) {
      debugPrint('⚠️ saveCustomPlanet failed: $e');
      // Optionally show a snackbar, but still navigate
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => ResultScreen(
                planet: planet,
                score: score,
                username: widget.username,
                userId: widget.userId,
              ),
        ),
      );
    }
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombinedLeaderboardScreen(currentUserId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planet = _currentPlanet;
    final score = ScoreService.calculateScore(planet);

    return Scaffold(
      backgroundColor: const Color(0xFF040D21),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(score),
            _buildHabitabilityBar(planet),
            Expanded(
              child: Row(
                children: [
                  // ── Left: planet preview ──────────────────────────────
                  Expanded(
                    flex: 5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildStarfield(),
                        PlanetPreview(
                          planet: planet,
                          rotationController: _rotationController,
                          pulseController: _pulseController,
                        ),
                        Positioned(
                          bottom: 12,
                          child: _buildPlanetStats(planet),
                        ),
                      ],
                    ),
                  ),
                  // ── Right: controls ───────────────────────────────────
                  Expanded(flex: 5, child: _buildControls(planet)),
                ],
              ),
            ),
            _buildBottomBar(score),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: Color(0xFF4FC3F7), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Planet Builder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openLeaderboard,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.leaderboard, color: Color(0xFFFFD54F), size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF4FC3F7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⭐ $score pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Habitability bar ────────────────────────────────────────────────────

  Widget _buildHabitabilityBar(PlanetModel planet) {
    final lc = planet.lifeChance;
    final frac = lc / 100.0;

    Color barColor;
    String label;
    if (lc >= 70) {
      barColor = const Color(0xFF66BB6A);
      label = '🌱 Highly Habitable';
    } else if (lc >= 45) {
      barColor = const Color(0xFF4FC3F7);
      label = '💧 Moderately Habitable';
    } else if (lc >= 20) {
      barColor = const Color(0xFFFFD54F);
      label = '🌡 Marginally Habitable';
    } else if (lc > 0) {
      barColor = const Color(0xFFFF7043);
      label = '☠️ Barely Survivable';
    } else {
      barColor = Colors.white24;
      label = '💀 Lifeless';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: barColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0, end: frac),
                builder:
                    (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$lc%',
            style: TextStyle(
              color: barColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            planet.temperatureString,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Planet stats strip ─────────────────────────────────────────────────

  Widget _buildPlanetStats(PlanetModel planet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statChip('🌍', 'Gravity', '${planet.gravity.toStringAsFixed(1)}g'),
          const SizedBox(width: 14),
          _statChip('⛈', 'Weather', planet.weatherSeverity),
          const SizedBox(width: 14),
          _statChip('☢️', 'Radiation', planet.radiationLevel),
          const SizedBox(width: 14),
          _statChip('🏙', 'Civs', planet.civilizationPotential),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 9),
        ),
      ],
    );
  }

  // ── Controls panel with tabs ────────────────────────────────────────────

  Widget _buildControls(PlanetModel planet) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildTabContent(key: ValueKey(_activeTab)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children:
            _Tab.values.map((tab) {
              final selected = _activeTab == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? const Color(0xFF4FC3F7).withOpacity(0.18)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected
                                ? const Color(0xFF4FC3F7).withOpacity(0.5)
                                : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _tabIcon(tab),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tabLabel(tab),
                          style: TextStyle(
                            color:
                                selected
                                    ? const Color(0xFF4FC3F7)
                                    : Colors.white38,
                            fontSize: 9,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTabContent({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.all(12),
      children: [
        if (_activeTab == _Tab.core) ..._coreControls(),
        if (_activeTab == _Tab.environment) ..._environmentControls(),
        if (_activeTab == _Tab.orbit) ..._orbitControls(),
        if (_activeTab == _Tab.features) ..._featureControls(),
        const SizedBox(height: 10),
        _buildScoreBreakdown(),
      ],
    );
  }

  // ── Tab: Core ──────────────────────────────────────────────────────────

  List<Widget> _coreControls() => [
    _sectionLabel('🪐 Core Planet'),
    const SizedBox(height: 8),
    SliderCard(
      icon: '🪐',
      label: 'Planet Size',
      value: _size,
      min: 0.1,
      max: 1.0,
      divisions: 9,
      displayValue: _sizeName(_size),
      subtitle: 'Affects gravity & mass',
      onChanged: (v) => setState(() => _size = v),
    ),
    const SizedBox(height: 10),
    _buildColorPicker(),
    const SizedBox(height: 10),
    _buildSurfaceTypeSelector(),
    const SizedBox(height: 10),
    _buildToggleCard(
      icon: '🌊',
      label: 'Surface Oceans',
      subtitle:
          _hasOceans
              ? 'Liquid water present • +15% life chance'
              : 'No liquid water',
      value: _hasOceans,
      onChanged: (v) => setState(() => _hasOceans = v),
    ),
  ];

  // ── Tab: Environment ────────────────────────────────────────────────────

  List<Widget> _environmentControls() => [
    _sectionLabel('🌫 Atmosphere & Climate'),
    const SizedBox(height: 8),
    _buildAtmosphereSelector(),
    const SizedBox(height: 10),
    SliderCard(
      icon: '☁️',
      label: 'Cloud Coverage',
      value: _cloudCoverage.toDouble(),
      min: 0,
      max: 100,
      divisions: 10,
      displayValue: '$_cloudCoverage%',
      subtitle: 'Higher coverage = more storms',
      onChanged: (v) => setState(() => _cloudCoverage = v.round()),
    ),
    const SizedBox(height: 10),
    _buildToggleCard(
      icon: '🧲',
      label: 'Magnetic Field',
      subtitle:
          _magneticField
              ? '+18% life chance • Radiation shield'
              : 'No radiation protection',
      value: _magneticField,
      onChanged: (v) => setState(() => _magneticField = v),
      activeColor: const Color(0xFF69FF8A),
    ),
    const SizedBox(height: 10),
    SliderCard(
      icon: '🌋',
      label: 'Tectonic Activity',
      value: _tectonicActivity.toDouble(),
      min: 0,
      max: 5,
      divisions: 5,
      displayValue: _tectonicLabel(_tectonicActivity),
      subtitle: 'Moderate activity is best for life',
      activeColor: _tectonicColor(_tectonicActivity),
      onChanged: (v) => setState(() => _tectonicActivity = v.round()),
    ),
  ];

  // ── Tab: Orbit ──────────────────────────────────────────────────────────

  List<Widget> _orbitControls() => [
    _sectionLabel('☀️ Star & Orbit'),
    const SizedBox(height: 8),
    _buildStarTypeSelector(),
    const SizedBox(height: 10),
    SliderCard(
      icon: '🌌',
      label: 'Orbital Distance',
      value: _orbitalDistance,
      min: 0.3,
      max: 3.5,
      divisions: 16,
      displayValue: '${_orbitalDistance.toStringAsFixed(1)} AU',
      subtitle: _orbitalZoneLabel(_orbitalDistance),
      activeColor: _orbitalZoneColor(_orbitalDistance),
      onChanged:
          (v) => setState(
            () => _orbitalDistance = double.parse(v.toStringAsFixed(1)),
          ),
    ),
    const SizedBox(height: 10),
    SliderCard(
      icon: '⏱',
      label: 'Day Length',
      value: _dayLength,
      min: 0.1,
      max: 3.0,
      divisions: 29,
      displayValue: _dayLengthDisplay(_dayLength),
      subtitle: 'Affects temperature extremes',
      onChanged:
          (v) =>
              setState(() => _dayLength = double.parse(v.toStringAsFixed(1))),
    ),
  ];

  // ── Tab: Features ────────────────────────────────────────────────────────

  List<Widget> _featureControls() => [
    _sectionLabel('💫 Rings & Moons'),
    const SizedBox(height: 8),
    _buildToggleCard(
      icon: '💫',
      label: 'Planetary Rings',
      subtitle:
          _hasRings ? 'Ring type: ${_ringTypeName(_ringType)}' : 'No rings',
      value: _hasRings,
      onChanged: (v) {
        setState(() {
          _hasRings = v;
          if (v && _ringType == RingType.none) {
            _ringType = RingType.ice;
          }
        });
      },
    ),
    if (_hasRings) ...[const SizedBox(height: 8), _buildRingTypeSelector()],
    const SizedBox(height: 10),
    SliderCard(
      icon: '🌙',
      label: 'Moons',
      value: _moonCount.toDouble(),
      min: 0,
      max: 5,
      divisions: 5,
      displayValue: '$_moonCount moon${_moonCount != 1 ? 's' : ''}',
      subtitle: 'Stabilizes axial tilt',
      onChanged: (v) => setState(() => _moonCount = v.round()),
    ),
  ];

  // ── Selector widgets ────────────────────────────────────────────────────

  Widget _buildAtmosphereSelector() {
    return _buildChipSelector<AtmosphereType>(
      title: '🌫 Atmosphere',
      values: AtmosphereType.values,
      selected: _atmosphere,
      labelFn: _atmosphereName,
      emojiFn: _atmosphereEmoji,
      onSelect: (t) => setState(() => _atmosphere = t),
    );
  }

  Widget _buildSurfaceTypeSelector() {
    return _buildChipSelector<SurfaceType>(
      title: '🗺 Surface Type',
      values: SurfaceType.values,
      selected: _surfaceType,
      labelFn: _surfaceName,
      emojiFn: _surfaceEmoji,
      onSelect: (t) => setState(() => _surfaceType = t),
    );
  }

  Widget _buildStarTypeSelector() {
    return _buildChipSelector<StarType>(
      title: '☀️ Star Type',
      values: StarType.values,
      selected: _starType,
      labelFn: _starName,
      emojiFn: _starEmoji,
      onSelect: (t) => setState(() => _starType = t),
      highlightColor: _starHighlightColor(_starType),
    );
  }

  Widget _buildRingTypeSelector() {
    return _buildChipSelector<RingType>(
      title: '💫 Ring Composition',
      values: RingType.values.where((t) => t != RingType.none).toList(),
      selected: _ringType,
      labelFn: _ringTypeName,
      emojiFn: _ringTypeEmoji,
      onSelect: (t) => setState(() => _ringType = t),
    );
  }

  Widget _buildChipSelector<T>({
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) labelFn,
    required String Function(T) emojiFn,
    required ValueChanged<T> onSelect,
    Color? highlightColor,
  }) {
    final accent = highlightColor ?? const Color(0xFF4FC3F7);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                values.map((type) {
                  final sel = selected == type;
                  return GestureDetector(
                    onTap: () => onSelect(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            sel
                                ? accent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? accent : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        '${emojiFn(type)} ${labelFn(type)}',
                        style: TextStyle(
                          color: sel ? accent : Colors.white60,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Planet Color',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                PlanetColor.values.map((color) {
                  final sel = _planetColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _planetColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colorValue(color),
                        border: Border.all(
                          color: sel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow:
                            sel
                                ? [
                                  BoxShadow(
                                    color: _colorValue(color).withOpacity(0.7),
                                    blurRadius: 8,
                                  ),
                                ]
                                : [],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor ?? const Color(0xFF4FC3F7),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final breakdown = ScoreService.getBreakdown(_currentPlanet);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.18),
            const Color(0xFF4FC3F7).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Score Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          ...breakdown.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '+${e.value}',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0x22FFFFFF), height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ScoreService.scoreLabel(
                  ScoreService.calculateScore(_currentPlanet),
                ),
                style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11),
              ),
              Text(
                '${ScoreService.calculateScore(_currentPlanet)} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return CustomPaint(
      painter: StarfieldPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildBottomBar(int score) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_currentPlanet.planetType} • ${widget.username}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _finishAndSubmit,
            icon: const Icon(Icons.rocket_launch, size: 17),
            label: const Text('Launch Planet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: const Color(0xFF040D21),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Planet name dialog ──────────────────────────────────────────────────

  Future<String?> _askPlanetName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Name Your Planet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentPlanet.planetType}  •  Life: ${_currentPlanet.lifeChance}%',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'e.g. Zorbax Prime',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    counterStyle: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) Navigator.pop(context, name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF040D21),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Launch 🚀',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  // ── Section label helper ───────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── Tab helpers ────────────────────────────────────────────────────────

  String _tabIcon(_Tab t) {
    switch (t) {
      case _Tab.core:
        return '🪐';
      case _Tab.environment:
        return '🌫';
      case _Tab.orbit:
        return '☀️';
      case _Tab.features:
        return '💫';
    }
  }

  String _tabLabel(_Tab t) {
    switch (t) {
      case _Tab.core:
        return 'Core';
      case _Tab.environment:
        return 'Atmos';
      case _Tab.orbit:
        return 'Orbit';
      case _Tab.features:
        return 'Extras';
    }
  }

  // ── Name/label helpers ─────────────────────────────────────────────────

  String _sizeName(double s) {
    if (s < 0.25) return 'Tiny';
    if (s < 0.45) return 'Small';
    if (s < 0.65) return 'Medium';
    if (s < 0.85) return 'Large';
    return 'Giant';
  }

  String _atmosphereName(AtmosphereType t) {
    switch (t) {
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

  String _atmosphereEmoji(AtmosphereType t) {
    switch (t) {
      case AtmosphereType.none:
        return '🚫';
      case AtmosphereType.thin:
        return '💨';
      case AtmosphereType.earth:
        return '🌤';
      case AtmosphereType.thick:
        return '☁️';
      case AtmosphereType.toxic:
        return '☠️';
    }
  }

  String _surfaceName(SurfaceType t) {
    switch (t) {
      case SurfaceType.rocky:
        return 'Rocky';
      case SurfaceType.oceanic:
        return 'Ocean';
      case SurfaceType.volcanic:
        return 'Volcanic';
      case SurfaceType.frozen:
        return 'Frozen';
      case SurfaceType.desert:
        return 'Desert';
      case SurfaceType.forest:
        return 'Forest';
    }
  }

  String _surfaceEmoji(SurfaceType t) {
    switch (t) {
      case SurfaceType.rocky:
        return '🪨';
      case SurfaceType.oceanic:
        return '🌊';
      case SurfaceType.volcanic:
        return '🌋';
      case SurfaceType.frozen:
        return '🧊';
      case SurfaceType.desert:
        return '🏜';
      case SurfaceType.forest:
        return '🌿';
    }
  }

  String _starName(StarType t) {
    switch (t) {
      case StarType.redDwarf:
        return 'Red Dwarf';
      case StarType.yellowStar:
        return 'Yellow Star';
      case StarType.blueGiant:
        return 'Blue Giant';
      case StarType.binaryStar:
        return 'Binary';
      case StarType.neutronStar:
        return 'Neutron';
    }
  }

  String _starEmoji(StarType t) {
    switch (t) {
      case StarType.redDwarf:
        return '🔴';
      case StarType.yellowStar:
        return '🌟';
      case StarType.blueGiant:
        return '🔵';
      case StarType.binaryStar:
        return '✨';
      case StarType.neutronStar:
        return '💀';
    }
  }

  Color _starHighlightColor(StarType t) {
    switch (t) {
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

  String _ringTypeName(RingType t) {
    switch (t) {
      case RingType.none:
        return 'None';
      case RingType.dust:
        return 'Dust';
      case RingType.ice:
        return 'Ice';
      case RingType.rocky:
        return 'Rocky';
    }
  }

  String _ringTypeEmoji(RingType t) {
    switch (t) {
      case RingType.none:
        return '🚫';
      case RingType.dust:
        return '💨';
      case RingType.ice:
        return '🧊';
      case RingType.rocky:
        return '🪨';
    }
  }

  String _tectonicLabel(int v) {
    switch (v) {
      case 0:
        return 'Dead';
      case 1:
        return 'Quiet';
      case 2:
        return 'Mild';
      case 3:
        return 'Active';
      case 4:
        return 'Intense';
      default:
        return 'Hellish';
    }
  }

  Color _tectonicColor(int v) {
    if (v <= 1) return Colors.white54;
    if (v <= 3) return const Color(0xFF66BB6A);
    if (v == 4) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5722);
  }

  String _orbitalZoneLabel(double au) {
    if (au < 0.5) return '🔥 Too hot — inner zone';
    if (au < 0.7) return '♨️ Very hot';
    if (au <= 1.5) return '✅ Habitable zone';
    if (au <= 2.5) return '🥶 Getting cold';
    return '❄️ Frozen outer zone';
  }

  Color _orbitalZoneColor(double au) {
    if (au < 0.5) return const Color(0xFFFF5722);
    if (au < 0.7) return const Color(0xFFFFD54F);
    if (au <= 1.5) return const Color(0xFF66BB6A);
    if (au <= 2.5) return const Color(0xFF4FC3F7);
    return const Color(0xFF90CAF9);
  }

  String _dayLengthDisplay(double dl) {
    if (dl < 0.3) return '${(dl * 24).toStringAsFixed(0)}h (fast)';
    if (dl < 1.2) return '${(dl * 24).toStringAsFixed(0)}h';
    return '${dl.toStringAsFixed(1)}x Earth day';
  }

  Color _colorValue(PlanetColor color) {
    switch (color) {
      case PlanetColor.blue:
        return const Color(0xFF4FC3F7);
      case PlanetColor.red:
        return const Color(0xFFEF5350);
      case PlanetColor.green:
        return const Color(0xFF66BB6A);
      case PlanetColor.purple:
        return const Color(0xFFAB47BC);
      case PlanetColor.orange:
        return const Color(0xFFFFA726);
      case PlanetColor.teal:
        return const Color(0xFF26C6DA);
      case PlanetColor.white:
        return const Color(0xFFECEFF1);
      case PlanetColor.gold:
        return const Color(0xFFFFD54F);
    }
  }
}

class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);
    for (int i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 1.6;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.15);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
