import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/solar_planet_data.dart';
import 'package:elearningapp_flutter/planet_builder/planet_detail_screen.dart';
import 'package:elearningapp_flutter/play/planet_builder_screen.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';

class PlanetGalleryScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTab;

  const PlanetGalleryScreen({
    Key? key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<PlanetGalleryScreen> createState() => _PlanetGalleryScreenState();
}

class _PlanetGalleryScreenState extends State<PlanetGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
      animationDuration: const Duration(milliseconds: 300), // smooth
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PlanetBuilderScreen(
              userId: widget.userId,
              username: widget.username,
            ),
      ),
    );
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
          '🪐 Planet Explorer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4FC3F7),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4FC3F7),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '☀️  Solar System'),
            Tab(text: '🛸  My Planets'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: const Color(0xFF4FC3F7),
        foregroundColor: const Color(0xFF040D21),
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Planet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // add this:
        children: [
          _SolarSystemTab(userId: widget.userId, username: widget.username),
          _MyPlanetsTab(userId: widget.userId, username: widget.username),
        ],
      ),
    );
  }
}

// ── Solar System Tab ──────────────────────────────────────────────────────────

class _SolarSystemTab extends StatefulWidget {
  // change to StatefulWidget
  final String userId;
  final String username;

  const _SolarSystemTab({required this.userId, required this.username});

  @override
  State<_SolarSystemTab> createState() => _SolarSystemTabState();
}

class _SolarSystemTabState extends State<_SolarSystemTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by mixin
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: solarSystemPlanets.length,
      itemBuilder: (context, index) {
        final planet = solarSystemPlanets[index];
        return _SolarPlanetCard(data: planet, userId: widget.userId);
      },
    );
  }
}

class _SolarPlanetCard extends StatefulWidget {
  final SolarPlanetData data;
  final String userId;

  const _SolarPlanetCard({required this.data, required this.userId});

  @override
  State<_SolarPlanetCard> createState() => _SolarPlanetCardState();
}

class _SolarPlanetCardState extends State<_SolarPlanetCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) =>
                      PlanetDetailScreen(solarData: d, userId: widget.userId),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: PlanetPreview(
                planet: d.model,
                rotationController: _rotationController,
                pulseController: _pulseController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    d.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniChip('🌙 ${d.model.moonCount}'),
                      const SizedBox(width: 6),
                      _miniChip(d.model.hasRings ? '💫 Rings' : '⭕ No rings'),
                      const SizedBox(width: 6),
                      _miniChip('🌡 ${d.temperature}'),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
      ),
    );
  }
}

// ── My Planets Tab ────────────────────────────────────────────────────────────

class _MyPlanetsTab extends StatefulWidget {
  final String userId;
  final String username;

  const _MyPlanetsTab({required this.userId, required this.username});

  @override
  State<_MyPlanetsTab> createState() => _MyPlanetsTabState();
}

class _MyPlanetsTabState extends State<_MyPlanetsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Stream<QuerySnapshot> get _stream {
    return FirebaseFirestore.instance
        .collection('user_planets')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by mixin
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('MyPlanets error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading planets.\nCheck the debug console for an index creation link.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌌', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text(
                  'No planets yet!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Create Planet" to build your first world.',
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

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final planet = PlanetModel.fromMap(data);
            final name = data['planetName'] as String? ?? 'My Planet';
            return _CustomPlanetCard(
              planet: planet,
              name: name,
              docId: doc.id,
              userId: widget.userId,
            );
          },
        );
      },
    );
  }
}

class _CustomPlanetCard extends StatefulWidget {
  final PlanetModel planet;
  final String name;
  final String docId;
  final String userId;

  const _CustomPlanetCard({
    required this.planet,
    required this.name,
    required this.docId,
    required this.userId,
  });

  @override
  State<_CustomPlanetCard> createState() => _CustomPlanetCardState();
}

class _CustomPlanetCardState extends State<_CustomPlanetCard>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => PlanetDetailScreen(
                    customPlanet: widget.planet,
                    customName: widget.name,
                    customDocId: widget.docId,
                    userId: widget.userId,
                  ),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _MiniStars(widget.docId.hashCode),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.planet.planetType,
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStars extends CustomPainter {
  final int seed;
  _MiniStars(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    int s = seed.abs() % 9999 + 1;
    double rng() {
      s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (s & 0xFFFF) / 65535.0;
    }

    for (int i = 0; i < 30; i++) {
      paint.color = Colors.white.withOpacity(rng() * 0.4 + 0.1);
      canvas.drawCircle(
        Offset(rng() * size.width, rng() * size.height),
        rng() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
