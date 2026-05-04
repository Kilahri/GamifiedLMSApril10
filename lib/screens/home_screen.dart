import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';
import 'package:elearningapp_flutter/screens/play_screen.dart';
import 'package:elearningapp_flutter/screens/watch_screen.dart';
import 'package:elearningapp_flutter/screens/read_screen.dart';
import 'package:elearningapp_flutter/screens/settings_screen.dart';
import 'package:elearningapp_flutter/screens/student_announcement_screen.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';
import 'package:elearningapp_flutter/services/firebase_leaderboard_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF07091A);
const Color _kSurface = Color(0xFF0F1230);
const Color _kCard = Color(0xFF131629);
const Color _kAccent = Color(0xFF7B4DFF);
const Color _kAccentLt = Color(0xFF9D77FF);
const Color _kGold = Color(0xFFFFBF3C);
const Color _kTeal = Color(0xFF1DB8A0);
const Color _kCoral = Color(0xFFFF6B6B);
const Color _kBorder = Color(0xFF1E2248);
const Color _kMuted = Color(0xFF5A5D7A);
const Color _kText = Color(0xFFE8E9F5);
const Color _kTextSub = Color(0xFF9496B0);

class HomeScreen extends StatefulWidget {
  final String role;
  final String username;

  const HomeScreen({super.key, required this.role, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _unreadCount = 0;

  // ── Stats state ───────────────────────────────────────────────────────────
  int _streakDays = 0;
  int _totalPoints = 0;
  int _rank = 0; // 0 = not yet loaded
  bool _statsLoaded = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadStats();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final studentSection = await StudentCache.getSection();
      final snapshot =
          await FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('date', descending: true)
              .get();
      final prefs = await SharedPreferences.getInstance();
      final lastReadTimestamp = prefs.getString(
        'last_read_announcement_${widget.username}',
      );
      final filtered =
          snapshot.docs.map((doc) => {'docId': doc.id, ...doc.data()}).where((
            a,
          ) {
            final sections = List<String>.from(a['sections'] ?? []);
            return sections.isEmpty ||
                (studentSection != null && sections.contains(studentSection));
          }).toList();

      int unread = 0;
      if (lastReadTimestamp == null) {
        unread = filtered.length;
      } else {
        unread =
            filtered.where((a) {
              final date = a['date'] as String? ?? '';
              return date.compareTo(lastReadTimestamp) > 0;
            }).length;
      }
      setState(() => _unreadCount = unread < 0 ? 0 : unread);
    } catch (_) {
      setState(() => _unreadCount = 0);
    }
  }

  // ── Load stats: rank, points, streak ─────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // ── 1. Rank from overall leaderboard ─────────────────────────────────
      final lb = await FirebaseLeaderboardService.getOverallLeaderboard();
      int rank = 0;
      for (int i = 0; i < lb.length; i++) {
        if (lb[i]['userId'] == uid) {
          rank = i + 1;
          break;
        }
      }

      // ── 2. Points: reading_progress + watch lesson progress ──────────────
      int readPts = 0;
      try {
        final readDoc =
            await FirebaseFirestore.instance
                .collection('reading_progress')
                .doc(uid)
                .get();
        if (readDoc.exists) {
          for (final entry in (readDoc.data() ?? {}).entries) {
            if (entry.key.endsWith('_quizBonus')) continue;
            final v = entry.value;
            if (v is Map) readPts += (v['points'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}

      int watchPts = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('lesson_progress_$uid');
        if (raw != null) {
          final map = Map<String, dynamic>.from(jsonDecode(raw));
          watchPts = (map['points'] as int?) ?? 0;
        }
      } catch (_) {}

      // ── 3. Streak: count consecutive days with lesson activity ───────────
      int streak = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('lesson_progress_$uid');
        final List<String> activityDays = [];

        // Pull timestamps from reading_progress Firestore
        final readDoc =
            await FirebaseFirestore.instance
                .collection('reading_progress')
                .doc(uid)
                .get();
        if (readDoc.exists) {
          for (final entry in (readDoc.data() ?? {}).entries) {
            if (entry.key.endsWith('_quizBonus')) continue;
            final v = entry.value;
            if (v is Map) {
              final ts = v['lastRead'];
              if (ts is Timestamp) {
                activityDays.add(
                  ts.toDate().toIso8601String().substring(0, 10),
                );
              }
            }
          }
        }

        // Pull from leaderboard timestamps
        for (final entry in lb) {
          if (entry['userId'] == uid) {
            final ts = entry['lastUpdated'];
            if (ts is Timestamp) {
              activityDays.add(ts.toDate().toIso8601String().substring(0, 10));
            }
            break;
          }
        }

        // Also use SharedPrefs watch progress if available
        if (raw != null) {
          // watch_screen saves progress but no timestamp; use today
          activityDays.add(DateTime.now().toIso8601String().substring(0, 10));
        }

        final uniqueDays = activityDays.toSet().toList()..sort();
        if (uniqueDays.isNotEmpty) {
          streak = 1;
          for (int i = uniqueDays.length - 1; i > 0; i--) {
            final a = DateTime.parse(uniqueDays[i]);
            final b = DateTime.parse(uniqueDays[i - 1]);
            if (a.difference(b).inDays == 1) {
              streak++;
            } else {
              break;
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _rank = rank;
          _totalPoints = readPts + watchPts;
          _streakDays = streak;
          _statsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    resetReadingState();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _displayName {
    final n = widget.username;
    return n.isNotEmpty ? n[0].toUpperCase() + n.substring(1) : n;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── background glow orbs ────────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: _GlowOrb(size: 300, color: _kAccent.withOpacity(0.13)),
          ),
          Positioned(
            top: 340,
            left: -60,
            child: _GlowOrb(size: 220, color: _kTeal.withOpacity(0.09)),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _GlowOrb(size: 180, color: _kGold.withOpacity(0.07)),
          ),

          // ── scrollable content ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // sticky header
                  SliverToBoxAdapter(child: _buildHeader()),

                  // hero banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: _buildHeroBanner(),
                    ),
                  ),

                  // quick stats row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildStatsRow(),
                    ),
                  ),

                  // section: activities
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      child: _SectionHeader(title: 'Activities'),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildActivityCards()),

                  // section: explore
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      child: _SectionHeader(title: 'Explore'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _popularItem(
                          title: 'Games & Quizzes',
                          subtitle: 'Puzzle, Matching, Trivia and more',
                          tag: 'PLAY',
                          icon: Icons.sports_esports_rounded,
                          accent: _kAccent,
                          imagePath: 'lib/assets/popularPlay.png',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PlayScreen(
                                        role: widget.role,
                                        username: widget.username,
                                      ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _popularItem(
                          title: 'Science Videos',
                          subtitle: 'Earth, Space and Life Sciences',
                          tag: 'WATCH',
                          icon: Icons.play_circle_outline_rounded,
                          accent: _kTeal,
                          imagePath: 'lib/assets/video.png',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WatchScreen(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        _popularItem(
                          title: 'Books & Articles',
                          subtitle: 'Science reading for curious minds',
                          tag: 'READ',
                          icon: Icons.menu_book_rounded,
                          accent: _kGold,
                          imagePath: 'lib/assets/popularRead.png',
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          ReadScreen(userId: widget.username),
                                ),
                              ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // avatar circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B4DFF), Color(0xFF4B3DAA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: _kAccent.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.username.isNotEmpty
                              ? widget.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: TextStyle(
                            color: _kMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // action buttons
          Row(
            children: [
              // SciLearn logo chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.science_rounded,
                      color: _kAccentLt,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    ShaderMask(
                      shaderCallback:
                          (b) => const LinearGradient(
                            colors: [Color(0xFFFFBF3C), Color(0xFFFF9500)],
                          ).createShader(b),
                      child: const Text(
                        'SciLearn',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // notifications (students only)
              if (widget.role.toLowerCase() == 'student')
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: _kTextSub,
                        size: 22,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => StudentAnnouncementsScreen(
                                  currentUsername: widget.username,
                                ),
                          ),
                        );
                        _loadUnreadCount();
                      },
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: _kCoral,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBg, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: _kTextSub,
                  size: 22,
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SettingsScreen(
                              currentUsername: widget.username,
                            ),
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero banner ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1FA8), Color(0xFF6B3DFF), Color(0xFF9D5FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 60,
            top: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // dot pattern overlay
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          // content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🚀  Start Learning Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Explore Science',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Play • Watch • Read',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // owl / mascot
                Image.asset(
                  'lib/assets/mascot.png',
                  height: 150,
                  width: 140,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.science_rounded,
                          color: Colors.white54,
                          size: 44,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick stats ───────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    // Show skeleton shimmer while loading
    if (!_statsLoaded) {
      return Row(
        children: [
          _StatChipSkeleton(),
          const SizedBox(width: 10),
          _StatChipSkeleton(),
          const SizedBox(width: 10),
          _StatChipSkeleton(),
        ],
      );
    }

    final streakLabel =
        _streakDays == 0
            ? 'No streak'
            : _streakDays == 1
            ? '1 day'
            : '$_streakDays days';
    final pointsLabel =
        _totalPoints >= 1000
            ? '${(_totalPoints / 1000).toStringAsFixed(1)}k'
            : '$_totalPoints';
    final rankLabel = _rank == 0 ? 'Unranked' : '#$_rank';

    return Row(
      children: [
        _StatChip(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: streakLabel,
          color: _streakDays > 0 ? _kCoral : _kMuted,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.star_rounded,
          label: 'Points',
          value: pointsLabel,
          color: _kGold,
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.emoji_events_rounded,
          label: 'Rank',
          value: rankLabel,
          color: _rank > 0 ? _kTeal : _kMuted,
        ),
      ],
    );
  }

  // ── Activity cards (horizontal scroll) ───────────────────────────────────
  Widget _buildActivityCards() {
    final cards = [
      _ActivityData(
        label: 'Play',
        sub: 'Games & Quizzes',
        icon: Icons.sports_esports_rounded,
        gradient: [const Color(0xFF5B2ECC), const Color(0xFF8B5FFF)],
        imagePath: 'lib/assets/play.png',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PlayScreen(
                      role: widget.role,
                      username: widget.username,
                    ),
              ),
            ),
      ),
      _ActivityData(
        label: 'Watch',
        sub: 'Science Videos',
        icon: Icons.play_circle_fill_rounded,
        gradient: [const Color(0xFF0D6E62), const Color(0xFF1DB8A0)],
        imagePath: 'lib/assets/video.png',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WatchScreen()),
            ),
      ),
      _ActivityData(
        label: 'Read',
        sub: 'Books & Articles',
        icon: Icons.menu_book_rounded,
        gradient: [const Color(0xFF8B5500), const Color(0xFFFFBF3C)],
        imagePath: 'lib/assets/popularRead.png',
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReadScreen(userId: widget.username),
              ),
            ),
      ),
    ];

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildActivityCard(cards[i]),
      ),
    );
  }

  Widget _buildActivityCard(_ActivityData data) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient.last.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // watermark image
            Positioned(
              bottom: -10,
              right: -10,
              child: Image.asset(
                data.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                color: Colors.white.withOpacity(0.12),
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    data.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.sub,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular item ──────────────────────────────────────────────────────────
  Widget _popularItem({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required Color accent,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Row(
          children: [
            // thumbnail
            Container(
              width: 76,
              height: 84,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        color: accent.withOpacity(0.3),
                        size: 36,
                      ),
                    ),
                    Image.asset(
                      imagePath,
                      width: 76,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),

            // text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // arrow
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ActivityData {
  final String label, sub, imagePath;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActivityData({
    required this.label,
    required this.sub,
    required this.icon,
    required this.gradient,
    required this.imagePath,
    required this.onTap,
  });
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: _kMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle dot pattern for the hero card
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.fill;
    const spacing = 18.0;
    const r = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Loading skeleton for a stat chip while data is being fetched
class _StatChipSkeleton extends StatelessWidget {
  const _StatChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _kBorder.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
