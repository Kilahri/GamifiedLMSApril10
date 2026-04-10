import 'package:flutter/material.dart';

class TeacherGuidelinesScreen extends StatefulWidget {
  final String currentUsername;

  const TeacherGuidelinesScreen({super.key, required this.currentUsername});

  @override
  State<TeacherGuidelinesScreen> createState() =>
      _TeacherGuidelinesScreenState();
}

class _TeacherGuidelinesScreenState extends State<TeacherGuidelinesScreen> {
  static const Color _accentColor = Color(0xFF42A5F5);
  static const Color _bgDark = Color(0xFF0D102C);
  static const Color _bgCard = Color(0xFF1B263B);

  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Getting Started',
    'Content Management',
    'Sections & Students',
    'Grading & Quizzes',
    'Communication',
    'Settings & Profile',
    'Troubleshooting',
  ];

  final List<Map<String, dynamic>> _guidelines = [
    // ── Getting Started ──────────────────────────────────────────
    {
      'title': 'Platform overview',
      'category': 'Getting Started',
      'type': 'Guide',
      'desc':
          'A full walkthrough of the teacher dashboard — tabs, navigation, and where everything lives.',
      'detail':
          'The teacher dashboard has three main tabs in the bottom nav: Content (manage books and videos), Messages (student inbox), and Settings (your profile). Use the Content tab to create or edit lessons assigned to your sections.',
      'icon': Icons.explore_outlined,
      'color': Color(0xFF42A5F5),
    },
    {
      'title': 'First day checklist',
      'category': 'Getting Started',
      'type': 'Checklist',
      'desc':
          'Essential steps before your first class: set up sections, assign default content, and verify your profile.',
      'detail':
          '1. Go to Settings → update your display name and subject.\n2. Open Content → confirm default books and videos are visible.\n3. Assign at least one section to any custom content you create.\n4. Send a test message to yourself via Messages.',
      'icon': Icons.checklist_rounded,
      'color': Color(0xFF4CAF50),
    },

    // ── Content Management ────────────────────────────────────────
    {
      'title': 'Creating a book',
      'category': 'Content Management',
      'type': 'Guide',
      'desc':
          'How to create a new reading resource, upload a cover image, and assign it to sections.',
      'detail':
          'Tap Content → Read → Create Book. Fill in Title, Summary, Theme, and Author. Select a topic category, upload a cover image (required), then choose which sections can see this book. You can add chapters after saving.',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFF42A5F5),
    },
    {
      'title': 'Managing chapters',
      'category': 'Content Management',
      'type': 'Guide',
      'desc':
          'Add, reorder, and edit chapters — including key points, content text, and quiz questions.',
      'detail':
          'From the book list tap the chapters icon. Drag the handle to reorder. Each chapter has three tabs: Content (text + fun fact), Key Points (bullet takeaways), and Quiz (up to 4-option questions with explanations).',
      'icon': Icons.library_books_outlined,
      'color': Color(0xFF42A5F5),
    },
    {
      'title': 'Uploading a video lesson',
      'category': 'Content Management',
      'type': 'Guide',
      'desc':
          'Create a video lesson by uploading a file or pasting a YouTube URL, then attach quiz questions.',
      'detail':
          'Tap Content → Watch → Create. Add an emoji, title, and description. Either upload a video file or paste a YouTube/direct URL. Set duration and a fun fact. Then add quiz questions students answer after watching — each question needs 4 options and an explanation.',
      'icon': Icons.video_call_outlined,
      'color': Color(0xFF7B4DFF),
    },
    {
      'title': 'Default vs. created content',
      'category': 'Content Management',
      'type': 'Tip',
      'desc':
          'Understand the difference between built-in default content and content you create from scratch.',
      'detail':
          'Default content (marked with a star badge) is pre-loaded by the platform. You can edit or delete it — deletions are tracked so they don\'t reappear. Content you create is private to your account and only visible to sections you assign.',
      'icon': Icons.info_outline,
      'color': Color(0xFFFFC107),
    },

    // ── Sections & Students ───────────────────────────────────────
    {
      'title': 'What are sections?',
      'category': 'Sections & Students',
      'type': 'Guide',
      'desc':
          'Sections (A, B, C) let you control which class group sees specific content.',
      'detail':
          'When creating custom books or videos, you must assign at least one section. Students are enrolled in a section by the admin. Only content assigned to their section appears in their app. Default content is visible to all sections.',
      'icon': Icons.group_outlined,
      'color': Color(0xFF42A5F5),
    },
    {
      'title': 'Assigning content to sections',
      'category': 'Sections & Students',
      'type': 'Guide',
      'desc':
          'Use the section selector chips when creating or editing any custom book or video.',
      'detail':
          'The section selector appears at the top of the Create/Edit dialog for any non-default content. Tap one or more section chips (A, B, C). An orange warning appears if none are selected — you cannot save without choosing at least one.',
      'icon': Icons.group_add_outlined,
      'color': Color(0xFF42A5F5),
    },

    // ── Grading & Quizzes ─────────────────────────────────────────
    {
      'title': 'Quiz question best practices',
      'category': 'Grading & Quizzes',
      'type': 'Guide',
      'desc':
          'Tips for writing clear, fair questions that help students learn — not trick them.',
      'detail':
          'Keep questions focused on a single concept. Write 4 distinct options — avoid "all of the above". Always fill in the explanation field: students see it after answering. Use the emoji field for visual context. Aim for 3–5 questions per chapter or video.',
      'icon': Icons.quiz_outlined,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Student points system',
      'category': 'Grading & Quizzes',
      'type': 'Info',
      'desc':
          'Students earn +30 pts for completing a video quiz. Leaderboard rankings update automatically.',
      'detail':
          'Points are awarded automatically when a student submits a quiz after watching a video. The combined leaderboard is visible to both students and teachers. You cannot manually adjust points from the teacher dashboard in the current version.',
      'icon': Icons.emoji_events_outlined,
      'color': Color(0xFFFFC107),
    },

    // ── Communication ─────────────────────────────────────────────
    {
      'title': 'Reading student messages',
      'category': 'Communication',
      'type': 'Guide',
      'desc':
          'How to view, mark as read, and delete messages sent by students via Contact Support.',
      'detail':
          'Open the Messages tab. Unread messages show a red dot. Tap a message to open the detail view — this automatically marks it as read. Use the ⋮ menu to view or delete. Tap the refresh icon to pull the latest messages.',
      'icon': Icons.forum_outlined,
      'color': Color(0xFF42A5F5),
    },
    {
      'title': 'Message response workflow',
      'category': 'Communication',
      'type': 'Tip',
      'desc':
          'In-app messages are one-way. Use your school\'s email or LMS to reply to students.',
      'detail':
          'Students send messages through the Contact Support form in their Settings tab. You receive them here but cannot reply in-app. Note the student\'s @username shown in the message detail and respond through your school\'s official communication channel.',
      'icon': Icons.reply_outlined,
      'color': Color(0xFFFFC107),
    },

    // ── Settings & Profile ────────────────────────────────────────
    {
      'title': 'Updating your profile',
      'category': 'Settings & Profile',
      'type': 'Guide',
      'desc':
          'Change your display name, subject, or password from the Settings tab.',
      'detail':
          'Go to Settings (bottom nav, gear icon). You can update your display name and subject area. Password changes require your current password. Profile changes are saved to Firebase and reflected immediately across the app.',
      'icon': Icons.manage_accounts_outlined,
      'color': Color(0xFF9C27B0),
    },

    // ── Troubleshooting ───────────────────────────────────────────
    {
      'title': 'Content not showing for students',
      'category': 'Troubleshooting',
      'type': 'FAQ',
      'desc':
          'If students can\'t see a book or video you created, check section assignment and save status.',
      'detail':
          '1. Open the content item and tap Edit.\n2. Confirm at least one section is selected — the orange badge means it\'s unassigned.\n3. Tap Save (even if unchanged) to force a re-sync.\n4. Ask the student to pull-to-refresh on their Watch or Read screen.',
      'icon': Icons.visibility_off_outlined,
      'color': Color(0xFFEF5350),
    },
    {
      'title': 'Recovering deleted default content',
      'category': 'Troubleshooting',
      'type': 'FAQ',
      'desc':
          'Accidentally deleted a default book or video? Here\'s how to restore it.',
      'detail':
          'Deleted default content is tracked by ID in your teacher_content Firestore document. To restore, contact your platform admin who can remove the entry from the deleted_default_books or deleted_default_videos array. A self-service restore button is planned for a future release.',
      'icon': Icons.restore_outlined,
      'color': Color(0xFFEF5350),
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _guidelines.where((g) {
      final matchCat =
          _selectedCategory == 'All' || g['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchQ =
          q.isEmpty ||
          (g['title'] as String).toLowerCase().contains(q) ||
          (g['desc'] as String).toLowerCase().contains(q) ||
          (g['category'] as String).toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
  }

  void _openDetail(Map<String, dynamic> g) {
    final Color color = g['color'] as Color;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B263B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        g['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              g['type'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 0.5,
                  color: Colors.white12,
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                Text(
                  g['detail'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Category: ',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    Text(
                      g['category'] as String,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'App Guidelines',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Everything you need to teach effectively',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _accentColor.withOpacity(0.2)),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar
          Container(
            color: _bgCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search guidelines...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                        : null,
                filled: true,
                fillColor: _bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Category chips
          Container(
            height: 52,
            color: _bgCard,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isActive = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? _accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isActive
                                  ? _accentColor
                                  : _accentColor.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color:
                              isActive
                                  ? const Color(0xFF0D102C)
                                  : Colors.white54,
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} guideline${filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ── List
          Expanded(
            child:
                filtered.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No guidelines found',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final g = filtered[i];
                        final Color color = g['color'] as Color;
                        return Card(
                          color: _bgCard,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.06),
                              width: 0.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openDetail(g),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      g['icon'] as IconData,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          g['desc'] as String,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            height: 1.45,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                g['type'] as String,
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              g['category'] as String,
                                              style: const TextStyle(
                                                color: Colors.white30,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white24,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
