import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW DATA IS FETCHED
// ─────────────────────────────────────────────────────────────────────────────
//
// Your app does NOT use a 'users' Firestore collection for students.
// Students authenticate via Firebase Auth (uid) + SharedPreferences (username).
//
// FirebaseLeaderboardService.saveScore() writes to ONE document per student:
//
//   leaderboard/{uid}  →  Map of game entries keyed by game name constant:
//     {
//       "matching":        { "score": int, "username": str, "displayName": str,
//                            "timestamp": Timestamp, "metadata": {...} }
//       "crossword":       { "score": int, "username": str, ... }
//       "science_fusion":  { "score": int, "username": str, ... }
//       "quiz":            { "score": int, "username": str, ... }
//     }
//
//   planet_leaderboard/{uid}  →  { "score": int, "username": str, ... }
//
//   quiz_scores/{uid}  →  {
//     "Changes of Matter": { "bestScore": int, "maxScore": int, "lastPlayed": Timestamp }
//     "Photosynthesis":    { ... }
//     ...
//   }
//
//   reading_progress/{uid}  →  {
//     "Book Title": { "points": int, "completedChapters": [...], "lastRead": Timestamp }
//     "Book Title_quizBonus": true   ← skip these
//   }
//
//   quiz_achievements/{uid}  →  { "unlocked": ["quiz_first_answer", ...] }
//
// STRATEGY: scan the 'leaderboard' collection to discover all student UIDs
// and their usernames (the username is embedded in each game entry).
// Then fetch supporting collections for each UID.
//
// FIREBASE RULES needed (add to your rules if not present):
//   match /leaderboard/{uid}       { allow read: if request.auth != null; }
//   match /quiz_scores/{uid}       { allow read: if request.auth != null; }
//   match /planet_leaderboard/{uid}{ allow read: if request.auth != null; }
//   match /reading_progress/{uid}  { allow read: if request.auth != null; }
//   match /quiz_achievements/{uid} { allow read: if request.auth != null; }

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class StudentAnalyticsData {
  final String userId;
  final String username;
  final String displayName;
  final String section;

  // Raw game scores (as saved by FirebaseLeaderboardService)
  final int quizScore; // sum of quiz topic bestScores (max ~75)
  final int matchingScore; // leaderboard['matching']['score']
  final int crosswordScore; // leaderboard['crossword']['score']
  final int fusionScore; // leaderboard['science_fusion']['score']
  final int planetScore; // planet_leaderboard['score']

  // Reading
  final int readingPoints;
  final int chaptersCompleted;
  final int booksRead;

  // Achievements
  final int achievementsUnlocked;

  // Per-topic quiz breakdown
  final Map<String, int> topicScores;

  // Last active (from any leaderboard timestamp)
  final DateTime? lastActive;

  const StudentAnalyticsData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.section,
    required this.quizScore,
    required this.matchingScore,
    required this.crosswordScore,
    required this.fusionScore,
    required this.planetScore,
    required this.readingPoints,
    required this.chaptersCompleted,
    required this.booksRead,
    required this.achievementsUnlocked,
    required this.topicScores,
    this.lastActive,
  });

  int get totalScore =>
      quizScore + matchingScore + crosswordScore + fusionScore + planetScore;

  // Status based on raw total (max ≈ 75+200+300+500+300 = 1375)
  String get status {
    if (totalScore >= 700) return 'Excellent';
    if (totalScore >= 350) return 'On track';
    if (totalScore >= 100) return 'Needs help';
    return 'At risk';
  }

  Color get statusColor {
    switch (status) {
      case 'Excellent':
        return const Color(0xFF3B6D11);
      case 'On track':
        return const Color(0xFF185FA5);
      case 'Needs help':
        return const Color(0xFF854F0B);
      default:
        return const Color(0xFFA32D2D);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case 'Excellent':
        return const Color(0xFFEAF3DE);
      case 'On track':
        return const Color(0xFFE6F1FB);
      case 'Needs help':
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFFCEBEB);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TeacherStudentAnalyticsScreen extends StatefulWidget {
  final String teacherUsername;

  const TeacherStudentAnalyticsScreen({
    super.key,
    required this.teacherUsername,
  });

  @override
  State<TeacherStudentAnalyticsScreen> createState() =>
      _TeacherStudentAnalyticsScreenState();
}

class _TeacherStudentAnalyticsScreenState
    extends State<TeacherStudentAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<StudentAnalyticsData> _allStudents = [];
  List<StudentAnalyticsData> _filteredStudents = [];

  String _selectedSection = 'All';
  String _sortBy = 'total';
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();

  // ── Game name keys (must match FirebaseLeaderboardService constants) ────────
  static const String _kMatching = 'matching';
  static const String _kCrossword = 'crossword';
  static const String _kFusion = 'science_fusion';
  static const String _kQuiz = 'quiz';

  static const List<String> _quizTopics = [
    'Changes of Matter',
    'Photosynthesis',
    'Solar System',
    'Ecosystem & Food Web',
    'Water Cycle',
  ];

  // Game max scores for bar normalisation
  static const Map<String, int> _gameMeta = {
    'Science Quiz': 75,
    'Matching Game': 200,
    'Crossword': 300,
    'Science Fusion': 500,
    'Planet Builder': 300,
  };

  // Colors
  static const _bg = Color(0xFF0D102C);
  static const _surface = Color(0xFF1B263B);
  static const _surface2 = Color(0xFF252850);
  static const _accent = Color(0xFF98C1D9);

  static const Map<String, Color> _gameColors = {
    'Science Quiz': Color(0xFF378ADD),
    'Matching Game': Color(0xFF1D9E75),
    'Crossword': Color(0xFF534AB7),
    'Science Fusion': Color(0xFFEF9F27),
    'Planet Builder': Color(0xFFD4537E),
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = FirebaseFirestore.instance;

      // ── Fetch all collections in parallel ──────────────────────────────────
      final results2 = await Future.wait([
        db.collection('leaderboard').get(),
        db.collection('planet_leaderboard').get(),
        db.collection('users').get(),
      ]);

      final lbSnap = results2[0];
      final planetSnap = results2[1];
      final usersSnap = results2[2];

      debugPrint('=== leaderboard docs: ${lbSnap.docs.length}');
      for (final doc in lbSnap.docs) {
        debugPrint('  lb UID: ${doc.id} | keys: ${doc.data().keys.toList()}');
      }
      debugPrint('=== planet_leaderboard docs: ${planetSnap.docs.length}');
      debugPrint('=== users docs: ${usersSnap.docs.length}');

      // Build lookup maps
      final Map<String, Map<String, dynamic>> usersMap = {
        for (final doc in usersSnap.docs)
          if ((doc.data()['role'] as String?) != 'admin' &&
              (doc.data()['role'] as String?) != 'teacher')
            doc.id: doc.data(),
      };
      final Map<String, int> planetScores = {
        for (final doc in planetSnap.docs)
          doc.id: (doc.data()['score'] as num?)?.toInt() ?? 0,
      };

      // All unique student UIDs
      final Set<String> studentUids = usersMap.keys.toSet();

      final Set<String> allUids = {
        ...lbSnap.docs.map((d) => d.id).where((id) => studentUids.contains(id)),
        ...planetSnap.docs
            .map((d) => d.id)
            .where((id) => studentUids.contains(id)),
        ...studentUids,
      };

      final List<StudentAnalyticsData> results = [];

      for (final uid in allUids) {
        final lbDoc = lbSnap.docs.where((d) => d.id == uid).firstOrNull;
        final lbData = lbDoc?.data() ?? <String, dynamic>{};

        // ── Resolve username — priority: users collection > leaderboard entries > uid
        String username = uid;
        String displayName = '';
        String section = '—';
        DateTime? lastActive;

        // 1) users collection (most reliable)
        final userDoc = usersMap[uid];
        debugPrint(
          '=== UID: $uid | userDoc exists: ${userDoc != null} | fields: ${userDoc?.keys.toList()}',
        );
        if (userDoc != null) {
          debugPrint('    games field: ${userDoc['games']}');
          debugPrint('    totalScore: ${userDoc['totalScore']}');
          debugPrint('    role: ${userDoc['role']}');
        }
        if (userDoc != null) {
          final u = (userDoc['username'] as String?) ?? '';
          final dn =
              (userDoc['leaderboardName'] as String?) ??
              ''; // ← was 'displayName'
          final sec = (userDoc['section'] as String?) ?? '';
          if (u.isNotEmpty) username = u;
          if (dn.isNotEmpty) displayName = dn;
          if (sec.isNotEmpty) section = sec;
        }

        // 2) leaderboard game entries (fallback + lastActive)
        if (lbDoc != null) {
          final u = (lbData['username'] as String?) ?? '';
          final dn =
              (lbData['leaderboardName'] as String?) ??
              (lbData['displayName'] as String?) ??
              '';
          final sec = (lbData['section'] as String?) ?? '';
          final ts = lbData['lastUpdated'] as Timestamp?;
          if (u.isNotEmpty && username == uid) username = u;
          if (dn.isNotEmpty && displayName.isEmpty) displayName = dn;
          if (sec.isNotEmpty && section == '—') section = sec;
          if (ts != null) {
            final dt = ts.toDate();
            if (lastActive == null || dt.isAfter(lastActive)) lastActive = dt;
          }
        }

        // 3) planet_leaderboard (fallback)
        final planetDoc = planetSnap.docs.where((d) => d.id == uid).firstOrNull;
        if (planetDoc != null) {
          final pu = (planetDoc.data()['username'] as String?) ?? '';
          final pd = (planetDoc.data()['displayName'] as String?) ?? '';
          final ps = (planetDoc.data()['section'] as String?) ?? '';
          final pts = planetDoc.data()['timestamp'] as Timestamp?;
          if (pu.isNotEmpty && username == uid) username = pu;
          if (pd.isNotEmpty && displayName.isEmpty) displayName = pd;
          if (ps.isNotEmpty && section == '—') section = ps;
          if (pts != null) {
            final dt = pts.toDate();
            if (lastActive == null || dt.isAfter(lastActive)) lastActive = dt;
          }
        }

        // ── Game scores ────────────────────────────────────────────────────────
        final matchingScore = _scoreFrom(lbData, _kMatching);
        final crosswordScore = _scoreFrom(lbData, _kCrossword);
        final fusionScore = _scoreFrom(lbData, _kFusion);
        final planetScore = planetScores[uid] ?? 0;

        // ── Quiz scores ────────────────────────────────────────────────────────
        int quizTotalScore = 0;
        final Map<String, int> topicScores = {};
        try {
          final quizSnap = await db.collection('quiz_scores').doc(uid).get();
          if (quizSnap.exists) {
            final qData = quizSnap.data() ?? {};
            for (final topic in _quizTopics) {
              final best =
                  ((qData[topic] as Map?)?['bestScore'] as num?)?.toInt() ?? 0;
              topicScores[topic] = best;
              quizTotalScore += best;
            }
          }
        } catch (_) {}
        if (quizTotalScore == 0) quizTotalScore = _scoreFrom(lbData, _kQuiz);

        // ── Reading progress ───────────────────────────────────────────────────
        int readingPoints = 0, chaptersCompleted = 0, booksRead = 0;
        try {
          final readSnap =
              await db.collection('reading_progress').doc(uid).get();
          if (readSnap.exists) {
            for (final entry in (readSnap.data() ?? {}).entries) {
              if (entry.key.endsWith('_quizBonus')) continue;
              final b = entry.value;
              if (b is Map) {
                readingPoints += (b['points'] as num?)?.toInt() ?? 0;
                final chaps = (b['completedChapters'] as List?)?.length ?? 0;
                chaptersCompleted += chaps;
                if (chaps > 0) booksRead++;
              }
            }
          }
        } catch (_) {}

        // ── Achievements ───────────────────────────────────────────────────────
        int achievementsUnlocked = 0;
        try {
          final achSnap =
              await db.collection('quiz_achievements').doc(uid).get();
          if (achSnap.exists) {
            achievementsUnlocked =
                (achSnap.data()?['unlocked'] as List?)?.length ?? 0;
          }
        } catch (_) {}

        // Pull scores from users doc as fallback

        results.add(
          StudentAnalyticsData(
            userId: uid,
            username: username,
            displayName: displayName.isNotEmpty ? displayName : username,
            section: section,
            quizScore: quizTotalScore,
            matchingScore: matchingScore,
            crosswordScore: crosswordScore,
            fusionScore: fusionScore,
            planetScore: planetScore,
            readingPoints: readingPoints,
            chaptersCompleted: chaptersCompleted,
            booksRead: booksRead,
            achievementsUnlocked: achievementsUnlocked,
            topicScores: topicScores,
            lastActive:
                lastActive ??
                (usersMap[uid]?['lastUpdated'] as Timestamp?)?.toDate(),
          ),
        );
      }

      results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      setState(() {
        _allStudents = results;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Analytics load error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Read the 'score' int from leaderboard[gameKey]['score']
  int _scoreFrom(Map<String, dynamic> lbData, String gameKey) {
    final games = lbData['games'] as Map<String, dynamic>?;
    final entry = games?[gameKey] as Map<String, dynamic>?;
    return (entry?['score'] as num?)?.toInt() ?? 0;
  }

  void _applyFilters() {
    List<StudentAnalyticsData> data = [..._allStudents];

    if (_selectedSection != 'All') {
      data = data.where((s) => s.section == _selectedSection).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      data =
          data
              .where(
                (s) =>
                    s.username.toLowerCase().contains(q) ||
                    s.displayName.toLowerCase().contains(q),
              )
              .toList();
    }

    data.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a.username.compareTo(b.username);
        case 'quiz':
          return b.quizScore.compareTo(a.quizScore);
        case 'reading':
          return b.readingPoints.compareTo(a.readingPoints);
        default:
          return b.totalScore.compareTo(a.totalScore);
      }
    });

    setState(() => _filteredStudents = data);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<String> get _sections {
    final secs = _allStudents.map((s) => s.section).toSet().toList()..sort();
    return ['All', ...secs];
  }

  double _classAvg(int Function(StudentAnalyticsData) fn) {
    if (_filteredStudents.isEmpty) return 0;
    return _filteredStudents.map(fn).reduce((a, b) => a + b) /
        _filteredStudents.length;
  }

  Color _avatarBg(int i) {
    const colors = [
      Color(0xFF3C3489),
      Color(0xFF085041),
      Color(0xFF712B13),
      Color(0xFF72243E),
      Color(0xFF0C447C),
      Color(0xFF27500A),
      Color(0xFF633806),
    ];
    return colors[i % colors.length];
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Analytics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              '${_filteredStudents.length} students',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.sports_esports, size: 15), text: 'Games'),
            Tab(icon: Icon(Icons.menu_book, size: 15), text: 'Reading'),
            Tab(icon: Icon(Icons.bar_chart, size: 15), text: 'Overview'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _errorMessage != null
              ? _buildError()
              : Column(
                children: [
                  _buildFilterBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGamesTab(),
                        _buildReadingTab(),
                        _buildOverviewTab(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your Firebase rules allow teachers to read:\n'
              '  /leaderboard/{uid}\n'
              '  /quiz_scores/{uid}\n'
              '  /planet_leaderboard/{uid}\n'
              '  /reading_progress/{uid}\n'
              '  /quiz_achievements/{uid}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _bg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _dropdown(
            value: _selectedSection,
            items: _sections,
            onChanged: (v) {
              _selectedSection = v!;
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _dropdown(
            value: _sortBy,
            items: const ['total', 'quiz', 'reading', 'name'],
            labels: const ['Total pts', 'Quiz pts', 'Reading pts', 'Name'],
            onChanged: (v) {
              _sortBy = v!;
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white38,
                  size: 18,
                ),
                filled: true,
                fillColor: _surface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    List<String>? labels,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _surface,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          items:
              items
                  .asMap()
                  .entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(labels != null ? labels[e.key] : e.value),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Games Tab ─────────────────────────────────────────────────────────────────

  Widget _buildGamesTab() {
    if (_filteredStudents.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _filteredStudents.length,
      itemBuilder: (_, i) => _buildGameCard(_filteredStudents[i], i),
    );
  }

  Widget _buildGameCard(StudentAnalyticsData s, int idx) {
    final games = [
      ('Science Quiz', s.quizScore, 75),
      ('Matching Game', s.matchingScore, 200),
      ('Crossword', s.crosswordScore, 300),
      ('Science Fusion', s.fusionScore, 500),
      ('Planet Builder', s.planetScore, 300),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _avatar(s.username, idx),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _chip(s.section, Colors.white24, Colors.white60),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(s.lastActive),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${s.totalScore} pts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _statusBadge(s),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score bars
          ...games.map((g) {
            final (name, score, max) = g;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _scoreBar(name, score, max, _gameColors[name] ?? _accent),
            );
          }),
          // Achievements row
          if (s.achievementsUnlocked > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${s.achievementsUnlocked} achievements',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBar(String label, int score, int max, Color color) {
    final frac = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── Reading Tab ───────────────────────────────────────────────────────────────

  Widget _buildReadingTab() {
    if (_filteredStudents.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _filteredStudents.length,
      itemBuilder: (_, i) {
        final s = _filteredStudents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              _avatar(s.username, i),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(
                          '${s.booksRead} books',
                          const Color(0xFF185FA5).withOpacity(0.2),
                          const Color(0xFF85B7EB),
                        ),
                        _chip(
                          '${s.chaptersCompleted} chapters',
                          const Color(0xFF3B6D11).withOpacity(0.2),
                          const Color(0xFF97C459),
                        ),
                        _chip(
                          '${s.readingPoints} pts',
                          Colors.amber.withOpacity(0.15),
                          Colors.amber,
                        ),
                      ],
                    ),
                    // Quiz topic progress
                    if (s.topicScores.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...s.topicScores.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: _scoreBar(
                            e.key,
                            e.value,
                            15,
                            const Color(0xFF378ADD),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    if (_filteredStudents.isEmpty) return _buildEmpty();

    final excellent =
        _filteredStudents.where((s) => s.status == 'Excellent').length;
    final onTrack =
        _filteredStudents.where((s) => s.status == 'On track').length;
    final needsHelp =
        _filteredStudents.where((s) => s.status == 'Needs help').length;
    final atRisk = _filteredStudents.where((s) => s.status == 'At risk').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Students',
                  '${_filteredStudents.length}',
                  'total',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Avg total',
                  '${_classAvg((s) => s.totalScore).round()}',
                  'pts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Avg quiz',
                  '${_classAvg((s) => s.quizScore).round()}',
                  'correct answers',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Excellent',
                  '$excellent',
                  'of ${_filteredStudents.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status breakdown
          _sectionLabel('Status breakdown'),
          const SizedBox(height: 8),
          _statusBar(
            'Excellent',
            excellent,
            const Color(0xFF3B6D11),
            const Color(0xFFEAF3DE),
          ),
          _statusBar(
            'On track',
            onTrack,
            const Color(0xFF185FA5),
            const Color(0xFFE6F1FB),
          ),
          _statusBar(
            'Needs help',
            needsHelp,
            const Color(0xFF854F0B),
            const Color(0xFFFAEEDA),
          ),
          _statusBar(
            'At risk',
            atRisk,
            const Color(0xFFA32D2D),
            const Color(0xFFFCEBEB),
          ),
          const SizedBox(height: 20),

          // Game averages
          _sectionLabel('Class average by game'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                _scoreBar(
                  'Science Quiz',
                  _classAvg((s) => s.quizScore).round(),
                  75,
                  const Color(0xFF378ADD),
                ),
                const SizedBox(height: 8),
                _scoreBar(
                  'Matching Game',
                  _classAvg((s) => s.matchingScore).round(),
                  200,
                  const Color(0xFF1D9E75),
                ),
                const SizedBox(height: 8),
                _scoreBar(
                  'Crossword',
                  _classAvg((s) => s.crosswordScore).round(),
                  300,
                  const Color(0xFF534AB7),
                ),
                const SizedBox(height: 8),
                _scoreBar(
                  'Science Fusion',
                  _classAvg((s) => s.fusionScore).round(),
                  500,
                  const Color(0xFFEF9F27),
                ),
                const SizedBox(height: 8),
                _scoreBar(
                  'Planet Builder',
                  _classAvg((s) => s.planetScore).round(),
                  300,
                  const Color(0xFFD4537E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quiz topic averages
          _sectionLabel('Quiz topic averages (class)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children:
                  _quizTopics.map((topic) {
                    final avg =
                        _filteredStudents.isEmpty
                            ? 0.0
                            : _filteredStudents
                                    .map((s) => s.topicScores[topic] ?? 0)
                                    .reduce((a, b) => a + b) /
                                _filteredStudents.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _scoreBar(
                        topic,
                        avg.round(),
                        15,
                        const Color(0xFF378ADD),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // At-risk list
          if (atRisk > 0 || needsHelp > 0) ...[
            _sectionLabel('Students needing attention'),
            const SizedBox(height: 8),
            ..._filteredStudents
                .where((s) => s.status == 'At risk' || s.status == 'Needs help')
                .map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA32D2D).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFA32D2D).withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE24B4A),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Total: ${s.totalScore} pts · '
                                'Last active: ${_timeAgo(s.lastActive)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(s),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────────

  Widget _metricCard(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statusBar(String label, int count, Color fg, Color bg) {
    final frac =
        _filteredStudents.isEmpty
            ? 0.0
            : (count / _filteredStudents.length).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: frac,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(fg),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: _accent,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
    ),
  );

  Widget _avatar(String name, int idx) {
    final initials =
        name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
    final color = _avatarBg(idx);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(StudentAnalyticsData s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: s.statusBgColor,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      s.status,
      style: TextStyle(
        color: s.statusColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, color: Colors.white24, size: 48),
        SizedBox(height: 12),
        Text(
          'No students found',
          style: TextStyle(color: Colors.white38, fontSize: 15),
        ),
      ],
    ),
  );
}
