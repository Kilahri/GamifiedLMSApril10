import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/planet_builder/planet_model.dart';
import 'package:elearningapp_flutter/planet_builder/solar_planet_data.dart';
import 'package:elearningapp_flutter/planet_builder/planet_detail_screen.dart';
import 'package:elearningapp_flutter/play/planet_builder_screen.dart';
import 'package:elearningapp_flutter/planet_builder/planet_preview.dart';
import 'package:elearningapp_flutter/planet_builder/rating_service.dart';
import 'package:elearningapp_flutter/planet_builder/planet_rating_leaderboard_screen.dart';
import 'package:elearningapp_flutter/planet_builder/score_service.dart';

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
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openBuilder() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('user_planets')
            .where('userId', isEqualTo: widget.userId)
            .get();

    if (snap.docs.length >= 5) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: const Color(0xFF0D1B3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                '🪐 Planet Limit Reached',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Text(
                'You can have a maximum of 5 planets. '
                'Delete an existing planet to create a new one.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    foregroundColor: const Color(0xFF040D21),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
      );
      return;
    }
    if (!mounted) return;
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
        actions: [
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PlanetRatingLeaderboardScreen(
                          currentUserId: widget.userId,
                        ),
                  ),
                ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Rankings',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4FC3F7),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4FC3F7),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '☀️  Solar'),
            Tab(text: '🌍  Community'),
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
        children: [
          _SolarSystemTab(userId: widget.userId, username: widget.username),
          _CommunityTab(userId: widget.userId, username: widget.username),
          _MyPlanetsTab(userId: widget.userId, username: widget.username),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOLAR TAB
// ─────────────────────────────────────────────────────────────────────────────

class _SolarSystemTab extends StatefulWidget {
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
    super.build(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: solarSystemPlanets.length,
      itemBuilder:
          (_, i) => _SolarPlanetCard(
            data: solarSystemPlanets[i],
            userId: widget.userId,
            username: widget.username,
          ),
    );
  }
}

class _SolarPlanetCard extends StatefulWidget {
  final SolarPlanetData data;
  final String userId;
  final String username;
  const _SolarPlanetCard({
    required this.data,
    required this.userId,
    required this.username,
  });

  @override
  State<_SolarPlanetCard> createState() => _SolarPlanetCardState();
}

class _SolarPlanetCardState extends State<_SolarPlanetCard>
    with TickerProviderStateMixin {
  late AnimationController _rot, _pulse;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
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
                  (_) => PlanetDetailScreen(
                    solarData: d,
                    userId: widget.userId,
                    ownerUsername: widget.username, // add this
                  ),
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
                rotationController: _rot,
                pulseController: _pulse,
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
                      _chip('🌙 ${d.model.moonCount}'),
                      const SizedBox(width: 6),
                      _chip(d.model.hasRings ? '💫 Rings' : '⭕ No rings'),
                      const SizedBox(width: 6),
                      _chip('🌡 ${d.temperature}'),
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

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      t,
      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityTab extends StatefulWidget {
  final String userId;
  final String username;
  const _CommunityTab({required this.userId, required this.username});

  @override
  State<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<_CommunityTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _sort = 'newest'; // 'newest' | 'top_rated' | 'most_rated'

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Sort bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              _sortChip('newest', '🕒 Newest'),
              const SizedBox(width: 6),
              _sortChip('top_rated', '⭐ Top Rated'),
              const SizedBox(width: 6),
              _sortChip('most_rated', '👥 Most Rated'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('user_planets')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
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
                        'No community planets yet!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a planet to share with others.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final planet = PlanetModel.fromMap(data);
                  final name = data['planetName'] as String? ?? 'Unknown';
                  final ownerUserId = data['userId'] as String? ?? '';
                  final ownerUsername =
                      data['username'] as String? ?? 'Unknown';
                  return _CommunityPlanetCard(
                    docId: doc.id,
                    planet: planet,
                    planetName: name,
                    ownerUserId: ownerUserId,
                    ownerUsername: ownerUsername,
                    isOwn: ownerUserId == widget.userId,
                    currentUserId: widget.userId,
                    currentUsername: widget.username,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sortChip(String value, String label) {
    final sel = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              sel
                  ? const Color(0xFF4FC3F7).withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                sel
                    ? const Color(0xFF4FC3F7).withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? const Color(0xFF4FC3F7) : Colors.white54,
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Community Planet Card ─────────────────────────────────────────────────────

class _CommunityPlanetCard extends StatefulWidget {
  final String docId;
  final PlanetModel planet;
  final String planetName;
  final String ownerUserId;
  final String ownerUsername;
  final bool isOwn;
  final String currentUserId;
  final String currentUsername;

  const _CommunityPlanetCard({
    required this.docId,
    required this.planet,
    required this.planetName,
    required this.ownerUserId,
    required this.ownerUsername,
    required this.isOwn,
    required this.currentUserId,
    required this.currentUsername,
  });

  @override
  State<_CommunityPlanetCard> createState() => _CommunityPlanetCardState();
}

class _CommunityPlanetCardState extends State<_CommunityPlanetCard>
    with TickerProviderStateMixin {
  late AnimationController _rot, _pulse;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Color _ratingColor(double avg) {
    if (avg >= 80) return const Color(0xFF66BB6A);
    if (avg >= 60) return const Color(0xFF4FC3F7);
    if (avg >= 40) return const Color(0xFFFFD54F);
    return const Color(0xFFFF9800);
  }

  void _openDetail(BuildContext ctx, double avg, int count) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => CommunityPlanetDetailSheet(
            docId: widget.docId,
            planet: widget.planet,
            planetName: widget.planetName,
            ownerUserId: widget.ownerUserId,
            ownerUsername: widget.ownerUsername,
            isOwn: widget.isOwn,
            currentUserId: widget.currentUserId,
            currentUsername: widget.currentUsername,
            initialAvg: avg,
            initialCount: count,
          ),
    );
  }

  Future<void> _showRatingDialog(BuildContext ctx) async {
    final submitted = await showDialog<bool>(
      context: ctx,
      builder:
          (_) => _RatingDialog(
            planetName: widget.planetName,
            onSubmit: (rating) async {
              await RatingService.submitRating(
                planetDocId: widget.docId,
                raterId: widget.currentUserId,
                raterName: widget.currentUsername,
                ownerUserId: widget.ownerUserId,
                ownerUsername: widget.ownerUsername,
                planetName: widget.planetName,
                planetType: widget.planet.planetType,
                rating: rating,
              );
            },
          ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Rating submitted! ⭐',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF4FC3F7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: RatingService.ratingStream(widget.docId),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final avg = (data?['averageRating'] as num?)?.toDouble() ?? 0.0;
        final count = (data?['ratingCount'] as int?) ?? 0;
        final ratings = Map<String, dynamic>.from(data?['ratings'] ?? {});
        final myRating =
            (ratings[widget.currentUserId] as Map?)?['rating'] as int?;
        final hasRated = ratings.containsKey(widget.currentUserId);
        final qualifies = count >= 3;

        return GestureDetector(
          onTap: () => _openDetail(context, avg, count),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    widget.isOwn
                        ? const Color(0xFF4FC3F7).withOpacity(0.3)
                        : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              children: [
                // ── Top row ──
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Planet preview
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: PlanetPreview(
                          planet: widget.planet,
                          rotationController: _rot,
                          pulseController: _pulse,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.planetName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isOwn)
                                  _badge('MINE', const Color(0xFF4FC3F7)),
                              ],
                            ),
                            Text(
                              widget.planet.planetType,
                              style: const TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'by ${widget.ownerUsername}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Quick stats row
                            Row(
                              children: [
                                _miniStat('🌱', '${widget.planet.lifeChance}%'),
                                const SizedBox(width: 8),
                                _miniStat(
                                  '🌡',
                                  widget.planet.temperatureString,
                                ),
                                const SizedBox(width: 8),
                                _miniStat(
                                  '🌍',
                                  '${widget.planet.gravity.toStringAsFixed(1)}g',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // "View" chevron
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Rating bar ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Row(
                    children: [
                      // Stars display
                      if (qualifies) ...[
                        _starBar(avg),
                        const SizedBox(width: 8),
                        Text(
                          avg.toStringAsFixed(1),
                          style: TextStyle(
                            color: _ratingColor(avg),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($count)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11,
                          ),
                        ),
                      ] else ...[
                        const Text('⭐', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          count == 0 ? 'No ratings yet' : '$count/3 ratings',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (myRating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC3F7).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4FC3F7).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'You: $myRating',
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!widget.isOwn)
                        GestureDetector(
                          onTap:
                              hasRated
                                  ? null
                                  : () => _showRatingDialog(context),
                          child: AnimatedOpacity(
                            opacity: hasRated ? 0.4 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    hasRated
                                        ? Colors.white.withOpacity(0.05)
                                        : const Color(
                                          0xFF4FC3F7,
                                        ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      hasRated
                                          ? Colors.white.withOpacity(0.1)
                                          : const Color(
                                            0xFF4FC3F7,
                                          ).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                hasRated ? '✓ Rated' : '⭐ Rate',
                                style: TextStyle(
                                  color:
                                      hasRated
                                          ? Colors.white38
                                          : const Color(0xFF4FC3F7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _starBar(double avg) {
    final filled = (avg / 20).round(); // 0–5 stars out of 100
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < filled ? const Color(0xFFFFD54F) : Colors.white24,
          size: 14,
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String val) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 2),
      Text(
        val,
        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10),
      ),
    ],
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color:
            color == const Color(0xFF4FC3F7)
                ? const Color(0xFF040D21)
                : Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY PLANET DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPlanetDetailSheet extends StatefulWidget {
  final String docId;
  final PlanetModel planet;
  final String planetName;
  final String ownerUserId;
  final String ownerUsername;
  final bool isOwn;
  final String currentUserId;
  final String currentUsername;
  final double initialAvg;
  final int initialCount;

  const CommunityPlanetDetailSheet({
    Key? key,
    required this.docId,
    required this.planet,
    required this.planetName,
    required this.ownerUserId,
    required this.ownerUsername,
    required this.isOwn,
    required this.currentUserId,
    required this.currentUsername,
    required this.initialAvg,
    required this.initialCount,
  }) : super(key: key);

  @override
  State<CommunityPlanetDetailSheet> createState() =>
      _CommunityPlanetDetailSheetState();
}

class _CommunityPlanetDetailSheetState extends State<CommunityPlanetDetailSheet>
    with TickerProviderStateMixin {
  late AnimationController _rot, _pulse;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Color _ratingColor(double avg) {
    if (avg >= 80) return const Color(0xFF66BB6A);
    if (avg >= 60) return const Color(0xFF4FC3F7);
    if (avg >= 40) return const Color(0xFFFFD54F);
    return const Color(0xFFFF9800);
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

  String _surfaceName(SurfaceType t) {
    switch (t) {
      case SurfaceType.rocky:
        return 'Rocky';
      case SurfaceType.oceanic:
        return 'Ocean World';
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

  String _starName(StarType t) {
    switch (t) {
      case StarType.redDwarf:
        return 'Red Dwarf';
      case StarType.yellowStar:
        return 'Yellow Star';
      case StarType.blueGiant:
        return 'Blue Giant';
      case StarType.binaryStar:
        return 'Binary Star';
      case StarType.neutronStar:
        return 'Neutron Star';
    }
  }

  Color _lifeColor(int lc) {
    if (lc >= 70) return const Color(0xFF66BB6A);
    if (lc >= 45) return const Color(0xFF4FC3F7);
    if (lc >= 20) return const Color(0xFFFFD54F);
    if (lc > 0) return const Color(0xFFFF7043);
    return Colors.white38;
  }

  String _lifeLabel(int lc) {
    if (lc >= 70) return '🌱 Highly Habitable';
    if (lc >= 45) return '💧 Moderately Habitable';
    if (lc >= 20) return '🌡 Marginally Habitable';
    if (lc > 0) return '☠️ Barely Survivable';
    return '💀 Lifeless';
  }

  Future<void> _showRatingDialog() async {
    final submitted = await showDialog<bool>(
      context: context,
      builder:
          (_) => _RatingDialog(
            planetName: widget.planetName,
            onSubmit: (rating) async {
              await RatingService.submitRating(
                planetDocId: widget.docId,
                raterId: widget.currentUserId,
                raterName: widget.currentUsername,
                ownerUserId: widget.ownerUserId,
                ownerUsername: widget.ownerUsername,
                planetName: widget.planetName,
                planetType: widget.planet.planetType,
                rating: rating,
              );
            },
          ),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Rating submitted! ⭐',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF4FC3F7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.planet;
    final lc = p.lifeChance;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder:
          (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A1628),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.zero,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Planet preview ──
                Container(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: _SheetStarBg(),
                        child: const SizedBox.expand(),
                      ),
                      PlanetPreview(
                        planet: p,
                        rotationController: _rot,
                        pulseController: _pulse,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.planetName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  p.planetType,
                                  style: const TextStyle(
                                    color: Color(0xFF4FC3F7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created by ${widget.ownerUsername}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isOwn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FC3F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'MY PLANET',
                                style: TextStyle(
                                  color: Color(0xFF040D21),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Habitability bar ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _lifeColor(lc).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _lifeColor(lc).withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _lifeLabel(lc),
                                  style: TextStyle(
                                    color: _lifeColor(lc),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$lc%',
                                  style: TextStyle(
                                    color: _lifeColor(lc),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: lc / 100,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                valueColor: AlwaysStoppedAnimation(
                                  _lifeColor(lc),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Stats grid ──
                      const _SectionHeader('🔬 Planet Statistics'),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: [
                          _statCard(
                            '🌍 Gravity',
                            '${p.gravity.toStringAsFixed(2)}g',
                          ),
                          _statCard('🌡 Temperature', p.temperatureString),
                          _statCard('☢️ Radiation', p.radiationLevel),
                          _statCard('⛈ Weather', p.weatherSeverity),
                          _statCard('🏙 Civilization', p.civilizationPotential),
                          _statCard('🌙 Moons', '${p.moonCount}'),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Properties ──
                      const _SectionHeader('🪐 Properties'),
                      const SizedBox(height: 10),
                      _propRow('🌫 Atmosphere', _atmosphereName(p.atmosphere)),
                      _propRow('🗺 Surface', _surfaceName(p.surfaceType)),
                      _propRow('☀️ Star', _starName(p.starType)),
                      _propRow(
                        '🌌 Orbital Distance',
                        '${p.orbitalDistance.toStringAsFixed(1)} AU',
                      ),
                      _propRow(
                        '⏱ Day Length',
                        '${(p.dayLength * 24).toStringAsFixed(0)}h',
                      ),
                      _propRow('☁️ Cloud Coverage', '${p.cloudCoverage}%'),
                      _propRow(
                        '🧲 Magnetic Field',
                        p.magneticField ? '✅ Present' : '❌ Absent',
                      ),
                      _propRow(
                        '🌊 Oceans',
                        p.hasOceans ? '✅ Present' : '❌ None',
                      ),
                      _propRow(
                        '💫 Rings',
                        p.hasRings ? '✅ ${p.ringType.name}' : '❌ None',
                      ),
                      _propRow(
                        '🌋 Tectonic Activity',
                        _tectonicLabel(p.tectonicActivity),
                      ),
                      const SizedBox(height: 14),

                      // ── Community Rating ──
                      const _SectionHeader('⭐ Community Rating'),
                      const SizedBox(height: 10),
                      StreamBuilder<DocumentSnapshot>(
                        stream: RatingService.ratingStream(widget.docId),
                        builder: (context, snap) {
                          final data =
                              snap.data?.data() as Map<String, dynamic>?;
                          final avg =
                              (data?['averageRating'] as num?)?.toDouble() ??
                              0.0;
                          final count = (data?['ratingCount'] as int?) ?? 0;
                          final ratings = Map<String, dynamic>.from(
                            data?['ratings'] ?? {},
                          );
                          final hasRated = ratings.containsKey(
                            widget.currentUserId,
                          );
                          final qualifies = count >= 3;

                          return Column(
                            children: [
                              // Big rating display
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      qualifies
                                          ? _ratingColor(avg).withOpacity(0.08)
                                          : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        qualifies
                                            ? _ratingColor(
                                              avg,
                                            ).withOpacity(0.25)
                                            : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    qualifies
                                        ? Text(
                                          avg.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: _ratingColor(avg),
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                        : Text(
                                          '—',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (qualifies) ...[
                                            _starRowLarge(avg),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$count student${count != 1 ? 's' : ''} rated',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ] else ...[
                                            Text(
                                              count == 0
                                                  ? 'No ratings yet'
                                                  : 'Needs ${3 - count} more rating${3 - count != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Min. 3 ratings to show score',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Who rated (owner only or all if raters visible)
                              if (count > 0)
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: RatingService.getPlanetRaters(
                                    widget.docId,
                                  ),
                                  builder: (_, ratersSnap) {
                                    final raters = ratersSnap.data ?? [];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.07),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ratings from students',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...raters.take(10).map((r) {
                                            final rScore =
                                                r['rating'] as int? ?? 0;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person_outline,
                                                    color: Colors.white38,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      r['raterName']
                                                              as String? ??
                                                          'Unknown',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.6),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  // Mini star bar
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: List.generate(
                                                      5,
                                                      (i) => Icon(
                                                        i <
                                                                (rScore / 20)
                                                                    .round()
                                                            ? Icons.star_rounded
                                                            : Icons
                                                                .star_outline_rounded,
                                                        color:
                                                            i <
                                                                    (rScore /
                                                                            20)
                                                                        .round()
                                                                ? const Color(
                                                                  0xFFFFD54F,
                                                                )
                                                                : Colors
                                                                    .white24,
                                                        size: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _ratingColor(
                                                        rScore.toDouble(),
                                                      ).withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$rScore',
                                                      style: TextStyle(
                                                        color: _ratingColor(
                                                          rScore.toDouble(),
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                              const SizedBox(height: 12),

                              // Rate button
                              if (!widget.isOwn)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        hasRated ? null : _showRatingDialog,
                                    icon: Icon(
                                      hasRated
                                          ? Icons.check_circle
                                          : Icons.star_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      hasRated
                                          ? 'Already Rated'
                                          : 'Rate This Planet',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          hasRated
                                              ? Colors.white.withOpacity(0.08)
                                              : const Color(0xFF4FC3F7),
                                      foregroundColor:
                                          hasRated
                                              ? Colors.white38
                                              : const Color(0xFF040D21),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _starRowLarge(double avg) {
    final filled = (avg / 20).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < filled ? const Color(0xFFFFD54F) : Colors.white24,
          size: 20,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _propRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  String _tectonicLabel(int v) {
    const labels = ['Dead', 'Quiet', 'Mild', 'Active', 'Intense', 'Hellish'];
    return labels[v.clamp(0, labels.length - 1)];
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SheetStarBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    int s = 77;
    double rng() {
      s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (s & 0xFFFF) / 65535.0;
    }

    for (int i = 0; i < 60; i++) {
      paint.color = Colors.white.withOpacity(rng() * 0.45 + 0.1);
      canvas.drawCircle(
        Offset(rng() * size.width, rng() * size.height),
        rng() * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final String planetName;
  final Future<void> Function(int rating) onSubmit;

  const _RatingDialog({required this.planetName, required this.onSubmit});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 50;
  bool _submitting = false;
  String? _error; // shown inline if Firestore write fails

  Color get _col {
    if (_rating >= 80) return const Color(0xFF66BB6A);
    if (_rating >= 60) return const Color(0xFF4FC3F7);
    if (_rating >= 40) return const Color(0xFFFFD54F);
    return const Color(0xFFFF9800);
  }

  String get _emoji {
    if (_rating >= 80) return '🌟 Legendary';
    if (_rating >= 60) return '👍 Good';
    if (_rating >= 40) return '😐 Average';
    return '😕 Needs Work';
  }

  Future<void> _submit() async {
    // Prevent double-taps
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_rating);
      // Only pop if still mounted after the async Firestore write
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // ← THIS was the bug: without this catch, any Firestore error
      //   (missing index, permission denied, network timeout) left
      //   _submitting = true and the spinner ran forever.
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _friendlyError(e);
        });
      }
    }
    // No finally needed — success path pops the dialog,
    // error path resets _submitting in the catch block above.
  }

  /// Convert raw exceptions into readable messages for the student.
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('permission-denied') ||
        msg.contains('permission denied')) {
      return 'Permission denied. Ask your teacher to check Firebase rules.';
    }
    if (msg.contains('index') || msg.contains('requires an index')) {
      return 'Database index missing. Ask your teacher to check the Firebase console.';
    }
    if (msg.contains('network') || msg.contains('unavailable')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1B3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'Rate "${widget.planetName}"',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _emoji,
            style: TextStyle(
              color: _col,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_rating / 100',
            style: TextStyle(
              color: _col,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          // Star preview
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => Icon(
                i < (_rating / 20).round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color:
                    i < (_rating / 20).round()
                        ? const Color(0xFFFFD54F)
                        : Colors.white24,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _col,
              thumbColor: _col,
              overlayColor: _col.withOpacity(0.2),
              inactiveTrackColor: Colors.white12,
            ),
            child: Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              // Disable slider while submitting so user can't change mid-write
              onChanged:
                  _submitting
                      ? null
                      : (v) => setState(() => _rating = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          // ── Inline error message ──────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF5350),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          // Allow cancel even while submitting (in case user wants to abort)
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _submitting ? Colors.white24 : Colors.white54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: const Color(0xFF040D21),
            disabledBackgroundColor: const Color(0xFF4FC3F7).withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              _submitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF040D21),
                    ),
                  )
                  : const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// MY PLANETS TAB
// ─────────────────────────────────────────────────────────────────────────────

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

  Stream<QuerySnapshot> get _stream =>
      FirebaseFirestore.instance
          .collection('user_planets')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<void> _deletePlanet(
    BuildContext ctx,
    String docId,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Delete Planet?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Delete "$name"? This also removes its ratings and leaderboard entry.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
    if (ok != true) return;
    await ScoreService.deleteCustomPlanet(
      docId: docId,
      ownerUserId: widget.userId,
      ownerUsername: widget.username,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error loading planets',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
          );
        }
        final docs = snap.data?.docs ?? [];

        return Column(
          children: [
            // Slot bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  Text(
                    '${docs.length}/5 planets',
                    style: TextStyle(
                      color:
                          docs.length >= 5
                              ? const Color(0xFFFF9800)
                              : Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: docs.length / 5,
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(
                          docs.length >= 5
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF4FC3F7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            docs.isEmpty
                ? Expanded(
                  child: Center(
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
                        ),
                      ],
                    ),
                  ),
                )
                : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final planet = PlanetModel.fromMap(data);
                      final name = data['planetName'] as String? ?? 'My Planet';
                      return _MyPlanetCard(
                        planet: planet,
                        name: name,
                        docId: doc.id,
                        userId: widget.userId,
                        username: widget.username,
                        onDelete: () => _deletePlanet(context, doc.id, name),
                      );
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _MyPlanetCard extends StatefulWidget {
  final PlanetModel planet;
  final String name;
  final String docId;
  final String userId;
  final String username;
  final VoidCallback onDelete;

  const _MyPlanetCard({
    required this.planet,
    required this.name,
    required this.docId,
    required this.userId,
    required this.username,
    required this.onDelete,
  });

  @override
  State<_MyPlanetCard> createState() => _MyPlanetCardState();
}

class _MyPlanetCardState extends State<_MyPlanetCard>
    with TickerProviderStateMixin {
  late AnimationController _rot, _pulse;
  bool _showRaters = false;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rot.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Color _rc(double avg) {
    if (avg >= 80) return const Color(0xFF66BB6A);
    if (avg >= 60) return const Color(0xFF4FC3F7);
    if (avg >= 40) return const Color(0xFFFFD54F);
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: PlanetPreview(
                    planet: widget.planet,
                    rotationController: _rot,
                    pulseController: _pulse,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.planet.planetType,
                        style: const TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _miniStat('🌱 Life', '${widget.planet.lifeChance}%'),
                          const SizedBox(width: 10),
                          _miniStat('🌡', widget.planet.temperatureString),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white24,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),

          // Ratings
          StreamBuilder<DocumentSnapshot>(
            stream: RatingService.ratingStream(widget.docId),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final avg = (data?['averageRating'] as num?)?.toDouble() ?? 0.0;
              final count = (data?['ratingCount'] as int?) ?? 0;
              final qualifies = count >= 3;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap:
                          count > 0
                              ? () => setState(() => _showRaters = !_showRaters)
                              : null,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Star bar
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < (avg / 20).round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color:
                                      i < (avg / 20).round()
                                          ? const Color(0xFFFFD54F)
                                          : Colors.white24,
                                  size: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            qualifies
                                ? Text(
                                  '${avg.toStringAsFixed(1)} ($count)',
                                  style: TextStyle(
                                    color: _rc(avg),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                                : Text(
                                  count == 0
                                      ? 'No ratings yet'
                                      : '$count/3 (needs ${3 - count} more)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                            const Spacer(),
                            if (count > 0)
                              Icon(
                                _showRaters
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.white38,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_showRaters && count > 0)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: RatingService.getPlanetRaters(widget.docId),
                        builder: (_, s) {
                          final raters = s.data ?? [];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Column(
                              children:
                                  raters.map((r) {
                                    final rs = r['rating'] as int? ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            color: Colors.white38,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              r['raterName'] as String? ??
                                                  'Unknown',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.6,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _rc(
                                                rs.toDouble(),
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$rs / 100',
                                              style: TextStyle(
                                                color: _rc(rs.toDouble()),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String val) => Text(
    '$label: $val',
    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
  );
}
