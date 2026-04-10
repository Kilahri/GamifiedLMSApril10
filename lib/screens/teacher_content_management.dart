import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/read_screen.dart'
    show scienceBooks, spaceBooks, Book;
import 'package:elearningapp_flutter/data/video_data.dart'
    show scienceLessons, ScienceLesson;
import 'package:elearningapp_flutter/helpers/video_upload_helper.dart';
import 'package:elearningapp_flutter/helpers/image_upload_helper.dart';
import 'package:elearningapp_flutter/helpers/content_cache.dart';
import 'package:elearningapp_flutter/helpers/content_fetcher.dart';
import 'package:elearningapp_flutter/helpers/section_helpers.dart'; //

/// Comprehensive Teacher Content Management Screen
/// Allows teachers to Create, Read, Update, and Delete content for:
/// - Read (Books) - including default books from read_screen
/// - Watch (Videos/Lessons) - including default videos from video_data
/// - Play (Games) - including default quiz topics from quiz_screen
/// - Messages - View messages from students sent via Contact Support
/// All available sections in the app
const List<String> kAllSections = ['Section A', 'Section B', 'Section C'];

/// Small reusable widget – multi-select section chips
class SectionSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const SectionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4DFF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B4DFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group, color: Color(0xFF7B4DFF), size: 18),
              SizedBox(width: 8),
              Text(
                'Assign to Sections *',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose which sections can see this content',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children:
                kAllSections.map((section) {
                  final isSelected = selected.contains(section);
                  return FilterChip(
                    label: Text(section),
                    selected: isSelected,
                    onSelected: (val) {
                      final updated = List<String>.from(selected);
                      if (val) {
                        updated.add(section);
                      } else {
                        updated.remove(section);
                      }
                      onChanged(updated);
                    },
                    selectedColor: const Color(0xFF7B4DFF),
                    checkmarkColor: Colors.white,
                    backgroundColor: const Color(0xFF1C1F3E),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected ? const Color(0xFF7B4DFF) : Colors.white24,
                    ),
                  );
                }).toList(),
          ),
          if (selected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade300,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Please select at least one section',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherContentManagementScreen extends StatefulWidget {
  const TeacherContentManagementScreen({super.key});

  @override
  State<TeacherContentManagementScreen> createState() =>
      _TeacherContentManagementScreenState();
}

class _TeacherContentManagementScreenState
    extends State<TeacherContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('🔑 TEACHER UID: ${FirebaseService.currentUser!.uid}'); // ✅ copy this
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        title: const Text(
          "Content Management",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D102C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B4DFF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: "Read"),
            Tab(icon: Icon(Icons.play_circle), text: "Watch"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ReadContentManagement(), WatchContentManagement()],
      ),
    );
  }
}

/// Standalone Teacher Messages Screen for Bottom Navigation
class TeacherMessagesScreen extends StatelessWidget {
  const TeacherMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        title: const Text(
          "Student Messages",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D102C),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: const TeacherMessagesTab(),
    );
  }
}

// ============================================================================
// TEACHER MESSAGES TAB
// ============================================================================

class TeacherMessagesTab extends StatefulWidget {
  const TeacherMessagesTab({super.key});

  @override
  State<TeacherMessagesTab> createState() => _TeacherMessagesTabState();
}

class _TeacherMessagesTabState extends State<TeacherMessagesTab> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('messages')
              .where('to', isEqualTo: 'Teacher')
              .get();
      _messages =
          snapshot.docs.map((doc) => {...doc.data(), 'docId': doc.id}).toList();

      _messages.sort(
        (a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String),
      );
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _markMessageAsRead(Map<String, dynamic> message) async {
    final docId = message['docId'] as String?;
    if (docId == null) return;
    await FirebaseFirestore.instance.collection('messages').doc(docId).update({
      'isRead': true,
    });
    setState(() => message['isRead'] = true);
  }

  void _deleteMessage(Map<String, dynamic> message) async {
    // inside the existing showDialog confirm button, replace the SharedPreferences block with:
    final docId = message['docId'] as String?;
    if (docId != null) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(docId)
          .delete();
    }
    setState(() => _messages.remove(message));
  }

  void _viewMessageDetails(Map<String, dynamic> message) {
    _markMessageAsRead(message);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF7B4DFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['subject'] ?? 'No Subject',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(Icons.person, 'From', '@${message['from']}'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time,
                    'Sent',
                    _formatTimestamp(message['timestamp']),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  const Text(
                    'Message:',
                    style: TextStyle(
                      color: Color(0xFF7B4DFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message['message'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7B4DFF), size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
      );
    }

    final unreadCount = _messages.where((m) => !(m['isRead'] ?? false)).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Messages (${_messages.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount unread',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _loadMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Messages refreshed'),
                      backgroundColor: Color(0xFF7B4DFF),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _messages.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Messages from students will appear here',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _messages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isRead = message['isRead'] ?? false;

                      return Card(
                        color: const Color(0xFF1C1F3E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isRead
                                        ? Colors.grey
                                        : const Color(0xFF7B4DFF),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            message['subject'] ?? 'No Subject',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From: @${message['from']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: const Color(0xFF2A1B4A),
                            onSelected: (value) {
                              if (value == 'view') {
                                _viewMessageDetails(message);
                              } else if (value == 'delete') {
                                _deleteMessage(message);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                          onTap: () => _viewMessageDetails(message),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ============================================================================
// READ CONTENT MANAGEMENT
// ============================================================================

class ReadContentManagement extends StatefulWidget {
  const ReadContentManagement({super.key});

  @override
  State<ReadContentManagement> createState() => _ReadContentManagementState();
}

class _ReadContentManagementState extends State<ReadContentManagement> {
  List<Map<String, dynamic>> allBooks = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> bookTopics = [
    {'id': 'changes_of_matter', 'title': 'Changes of Matter', 'emoji': '🧪'},
    {'id': 'water_cycle', 'title': 'Water Cycle', 'emoji': '💧'},
    {'id': 'photosynthesis', 'title': 'Photosynthesis', 'emoji': '🌱'},
    {'id': 'solar_system', 'title': 'Solar System', 'emoji': '🪐'},
    {
      'id': 'ecosystem_food_web',
      'title': 'Ecosystem & Food Web',
      'emoji': '🦁',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Map<String, dynamic> _bookToMap(
    Book book, {
    bool isDefault = false,
    String? id,
  }) {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'isDefault': isDefault,
      'title': book.title,
      'summary': book.summary,
      'theme': book.theme,
      'author': book.author,
      'readTime': book.readTime,
      'funFact': book.funFact,
      'image': book.image,
      'chapters':
          book.chapters
              .map(
                (ch) => {
                  'title': ch.title,
                  'content': ch.content,
                  'keyPoints': ch.keyPoints,
                  'didYouKnow': ch.didYouKnow,
                  'quizQuestions':
                      ch.quizQuestions
                          .map(
                            (q) => {
                              'question': q.question,
                              'options': q.options,
                              'correctAnswer': q.correctAnswer,
                              'explanation': q.explanation,
                            },
                          )
                          .toList(),
                },
              )
              .toList(),
    };
  }

  String get _teacherUid => FirebaseService.currentUser!.uid;

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('teacher_content')
              .doc(_teacherUid)
              .get();

      final data = doc.data() ?? {};
      final teacherBooks = List<Map<String, dynamic>>.from(
        (data['teacher_books'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
      final modifiedMap = Map<String, dynamic>.from(
        data['modified_default_books'] ?? {},
      );
      final deletedIds = List<String>.from(data['deleted_default_books'] ?? []);

      List<Map<String, dynamic>> defaultBooks = [];
      int index = 0;
      for (var book in [...scienceBooks, ...spaceBooks]) {
        String bookId = 'default_book_$index';
        var bookMap = _bookToMap(book, isDefault: true, id: bookId);
        if (modifiedMap.containsKey(bookId)) {
          bookMap = Map<String, dynamic>.from(modifiedMap[bookId]);
          bookMap['isDefault'] = true;
          bookMap['id'] = bookId;
        }
        if (!deletedIds.contains(bookId)) defaultBooks.add(bookMap);
        index++;
      }

      setState(() {
        allBooks = [...defaultBooks, ...teacherBooks];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBooks() async {
    // ContentCache.invalidate();
    // ContentFetcher.invalidate();

    List<Map<String, dynamic>> teacherBooks = [];
    Map<String, dynamic> modifiedBooks = {};

    for (var book in allBooks) {
      if (book['isDefault'] == true) {
        modifiedBooks[book['id'] as String] = book;
      } else {
        teacherBooks.add(book);
      }
    }

    await FirebaseFirestore.instance
        .collection('teacher_content')
        .doc(_teacherUid)
        .set({
          'teacher_books': teacherBooks,
          'modified_default_books': modifiedBooks,
        }, SetOptions(merge: true));
  }

  // REPLACE the _showCreateBookDialog method in ReadContentManagement
  // Add this import at the top of teacher_content_management_screen.dart:
  // import 'package:elearningapp_flutter/helpers/image_upload_helper.dart';

  void _showCreateBookDialog({Map<String, dynamic>? existingBook, int? index}) {
    final isEdit = existingBook != null;
    final titleController = TextEditingController(
      text: existingBook?['title'] ?? '',
    );
    final summaryController = TextEditingController(
      text: existingBook?['summary'] ?? '',
    );
    final themeController = TextEditingController(
      text: existingBook?['theme'] ?? '',
    );
    final authorController = TextEditingController(
      text: existingBook?['author'] ?? '',
    );
    final readTimeController = TextEditingController(
      text: existingBook?['readTime']?.toString() ?? '15',
    );
    final funFactController = TextEditingController(
      text: existingBook?['funFact'] ?? '',
    );

    String selectedTopic = existingBook?['topic'] ?? 'changes_of_matter';
    bool isUploading = false;
    String uploadedImagePath = existingBook?['image'] ?? '';

    final bool isDefaultBook = existingBook?['isDefault'] == true;
    List<String> selectedSections = List<String>.from(
      existingBook?['sections'] ?? [],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1F3E),
                  title: Text(
                    isEdit ? 'Edit Book' : 'Create New Book',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDefaultBook) ...[
                          SectionSelector(
                            selected: selectedSections,
                            onChanged:
                                (v) =>
                                    setDialogState(() => selectedSections = v),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: summaryController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Summary',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Topic Category',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: selectedTopic,
                                dropdownColor: const Color(0xFF1C1F3E),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF2A2D4E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                items:
                                    bookTopics.map((topic) {
                                      return DropdownMenuItem<String>(
                                        value: topic['id'] as String,
                                        child: Row(
                                          children: [
                                            Text(
                                              topic['emoji'] as String,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              topic['title'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    (value) => setDialogState(
                                      () => selectedTopic = value!,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        TextField(
                          controller: themeController,
                          decoration: const InputDecoration(
                            labelText: 'Theme (e.g., Biology, Chemistry)',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: authorController,
                          decoration: const InputDecoration(
                            labelText: 'Author',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: readTimeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Read Time (minutes)',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextField(
                          controller: funFactController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Fun Fact',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Book Cover Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed:
                                    isUploading
                                        ? null
                                        : () async {
                                          setDialogState(
                                            () => isUploading = true,
                                          );
                                          final imagePath =
                                              await ImageUploadHelper.pickImageFromDevice();
                                          setDialogState(
                                            () => isUploading = false,
                                          );
                                          if (imagePath != null) {
                                            setDialogState(
                                              () =>
                                                  uploadedImagePath = imagePath,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Image uploaded! ✓',
                                                ),
                                                backgroundColor: Color(
                                                  0xFF4CAF50,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                icon:
                                    isUploading
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Icon(Icons.upload_file),
                                label: Text(
                                  isUploading
                                      ? 'Uploading...'
                                      : 'Upload Cover Image',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (uploadedImagePath.isNotEmpty)
                                Text(
                                  '✓ Image selected',
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const Text(
                                  'Please upload a cover image',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isUploading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    if (isEdit && index != null)
                      TextButton(
                        onPressed:
                            isUploading
                                ? null
                                : () {
                                  Navigator.pop(context);
                                  _manageChapters(index);
                                },
                        child: const Text(
                          'Manage Chapters',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ElevatedButton(
                      onPressed:
                          isUploading
                              ? null
                              : () async {
                                if (titleController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a book title',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (uploadedImagePath.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please upload a cover image',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (!isDefaultBook &&
                                    selectedSections.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select at least one section',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final book = {
                                  'id':
                                      existingBook?['id'] ??
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                  'isDefault':
                                      existingBook?['isDefault'] ?? false,
                                  'title': titleController.text,
                                  'summary': summaryController.text,
                                  'theme': themeController.text,
                                  'author': authorController.text,
                                  'readTime':
                                      int.tryParse(readTimeController.text) ??
                                      15,
                                  'funFact': funFactController.text,
                                  'image': uploadedImagePath,
                                  'topic': selectedTopic,
                                  'sections':
                                      isDefaultBook ? [] : selectedSections,
                                  'chapters': existingBook?['chapters'] ?? [],
                                };

                                setState(() {
                                  if (isEdit && index != null) {
                                    allBooks[index] = book;
                                  } else {
                                    allBooks.add(book);
                                  }
                                });

                                await _saveBooks();
                                if (context.mounted) Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'Book updated!'
                                          : 'Book created!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteBook(int index) async {
    final book = allBooks[index];
    final isDefault = book['isDefault'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Book?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to permanently delete "${book['title']}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    allBooks.removeAt(index);
                  });

                  // REMOVE the SharedPreferences block, REPLACE with:
                  if (isDefault) {
                    await FirebaseFirestore.instance
                        .collection('teacher_content')
                        .doc(_teacherUid)
                        .set({
                          'deleted_default_books': FieldValue.arrayUnion([
                            book['id'] as String,
                          ]),
                        }, SetOptions(merge: true));
                  }

                  await _saveBooks();
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _manageChapters(int bookIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChapterManagementScreen(
              book: allBooks[bookIndex],
              onSave: (updatedBook) {
                setState(() {
                  allBooks[bookIndex] = updatedBook;
                });
                _saveBooks();
              },
            ),
      ),
    );
    if (result == true) {
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
      );
    }

    final defaultBooksList =
        allBooks.where((b) => b['isDefault'] == true).toList();
    final teacherBooksList =
        allBooks.where((b) => b['isDefault'] != true).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Books (${allBooks.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${defaultBooksList.length} Default • ${teacherBooksList.length} Created by you',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateBookDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              allBooks.isEmpty
                  ? Center(
                    child: ElevatedButton(
                      onPressed: () => _showCreateBookDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                      child: const Text('Create Your First Book'),
                    ),
                  )
                  : ListView.builder(
                    itemCount: allBooks.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final book = allBooks[index];
                      final isDefault = book['isDefault'] == true;
                      final chapterCount =
                          (book['chapters'] as List?)?.length ?? 0;
                      final sections = List<String>.from(
                        book['sections'] ?? [],
                      );

                      return Card(
                        color: const Color(0xFF1C1F3E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              Icon(
                                Icons.menu_book,
                                color:
                                    isDefault
                                        ? Colors.orange
                                        : const Color(0xFF7B4DFF),
                                size: 32,
                              ),
                              if (isDefault)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  book['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book['theme'] ?? 'No theme',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'By ${book['author'] ?? 'Unknown'} • ${book['readTime'] ?? 15} min • $chapterCount chapters',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              if (!isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children:
                                        sections.isEmpty
                                            ? [
                                              const Text(
                                                'No sections assigned',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ]
                                            : sections.map((s) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF7B4DFF,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  s,
                                                  style: const TextStyle(
                                                    color: Color(0xFF7B4DFF),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.library_books,
                                  color: Colors.green,
                                ),
                                onPressed: () => _manageChapters(index),
                                tooltip: 'Manage Chapters',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _showCreateBookDialog(
                                      existingBook: book,
                                      index: index,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteBook(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ============================================================================
// CHAPTER MANAGEMENT SCREEN
// ============================================================================

class ChapterManagementScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final Function(Map<String, dynamic>) onSave;

  const ChapterManagementScreen({
    super.key,
    required this.book,
    required this.onSave,
  });

  @override
  State<ChapterManagementScreen> createState() =>
      _ChapterManagementScreenState();
}

class _ChapterManagementScreenState extends State<ChapterManagementScreen> {
  late List<Map<String, dynamic>> chapters;

  @override
  void initState() {
    super.initState();
    chapters = List<Map<String, dynamic>>.from(widget.book['chapters'] ?? []);
  }

  void _addChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChapterEditorScreen(
              onSave: (chapter) {
                setState(() {
                  chapters.add(chapter);
                });
                _saveChanges();
              },
            ),
      ),
    );
  }

  void _editChapter(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChapterEditorScreen(
              chapter: chapters[index],
              onSave: (chapter) {
                setState(() {
                  chapters[index] = chapter;
                });
                _saveChanges();
              },
            ),
      ),
    );
  }

  void _deleteChapter(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Chapter?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${chapters[index]['title']}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    chapters.removeAt(index);
                  });
                  _saveChanges();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chapter deleted!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _saveChanges() {
    final updatedBook = Map<String, dynamic>.from(widget.book);
    updatedBook['chapters'] = chapters;
    widget.onSave(updatedBook);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        title: Text(
          'Chapters: ${widget.book['title']}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              Navigator.pop(context, true);
            },
            tooltip: 'Done',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapters (${chapters.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addChapter,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Chapter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4DFF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                chapters.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.library_books,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No chapters yet',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _addChapter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DFF),
                            ),
                            child: const Text('Add First Chapter'),
                          ),
                        ],
                      ),
                    )
                    : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: chapters.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = chapters.removeAt(oldIndex);
                          chapters.insert(newIndex, item);
                        });
                        _saveChanges();
                      },
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final quizCount =
                            (chapter['quizQuestions'] as List?)?.length ?? 0;
                        final keyPointsCount =
                            (chapter['keyPoints'] as List?)?.length ?? 0;
                        return Card(
                          key: ValueKey(index),
                          color: const Color(0xFF1C1F3E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.drag_handle,
                                  color: Colors.white54,
                                ),
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              chapter['title'] ?? 'Untitled Chapter',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$quizCount quiz questions • $keyPointsCount key points',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editChapter(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteChapter(index),
                                ),
                              ],
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

// ============================================================================
// CHAPTER EDITOR SCREEN
// ============================================================================

class ChapterEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? chapter;
  final Function(Map<String, dynamic>) onSave;

  const ChapterEditorScreen({super.key, this.chapter, required this.onSave});

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController didYouKnowController;
  late List<String> keyPoints;
  late List<Map<String, dynamic>> quizQuestions;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    titleController = TextEditingController(
      text: widget.chapter?['title'] ?? '',
    );
    contentController = TextEditingController(
      text: widget.chapter?['content'] ?? '',
    );
    didYouKnowController = TextEditingController(
      text: widget.chapter?['didYouKnow'] ?? '',
    );
    keyPoints = List<String>.from(widget.chapter?['keyPoints'] ?? []);
    quizQuestions = List<Map<String, dynamic>>.from(
      widget.chapter?['quizQuestions'] ?? [],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    titleController.dispose();
    contentController.dispose();
    didYouKnowController.dispose();
    super.dispose();
  }

  void _saveChapter() {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a chapter title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final chapter = {
      'title': titleController.text,
      'content': contentController.text,
      'didYouKnow': didYouKnowController.text,
      'keyPoints': keyPoints,
      'quizQuestions': quizQuestions,
    };

    widget.onSave(chapter);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chapter saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addKeyPoint() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1F3E),
          title: const Text(
            'Add Key Point',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter key point...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    keyPoints.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B4DFF),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addQuizQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizQuestionEditorScreen(
              onSave: (question) {
                setState(() {
                  quizQuestions.add(question);
                });
              },
            ),
      ),
    );
  }

  void _editQuizQuestion(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizQuestionEditorScreen(
              question: quizQuestions[index],
              onSave: (question) {
                setState(() {
                  quizQuestions[index] = question;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        title: Text(
          widget.chapter == null ? 'New Chapter' : 'Edit Chapter',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _saveChapter,
            tooltip: 'Save Chapter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF7B4DFF),
          tabs: const [
            Tab(text: 'Content', icon: Icon(Icons.article)),
            Tab(text: 'Key Points', icon: Icon(Icons.list)),
            Tab(text: 'Quiz', icon: Icon(Icons.quiz)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chapter Title',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Introduction to Photosynthesis',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1C1F3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chapter Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  maxLines: 15,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write your chapter content here...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1C1F3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Did You Know? (Fun Fact)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: didYouKnowController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add an interesting fact...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1C1F3E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Key Points Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Key Points (${keyPoints.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addKeyPoint,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    keyPoints.isEmpty
                        ? const Center(
                          child: Text(
                            'No key points yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: keyPoints.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: const Color(0xFF1C1F3E),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF7B4DFF),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  keyPoints[index],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      keyPoints.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),

          // Quiz Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quiz Questions (${quizQuestions.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addQuizQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    quizQuestions.isEmpty
                        ? const Center(
                          child: Text(
                            'No quiz questions yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: quizQuestions.length,
                          itemBuilder: (context, index) {
                            final question = quizQuestions[index];
                            return Card(
                              color: const Color(0xFF1C1F3E),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  child: Text(
                                    'Q${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  question['question'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${(question['options'] as List?)?.length ?? 0} options',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editQuizQuestion(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          quizQuestions.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUIZ QUESTION EDITOR SCREEN (FOR BOOK CHAPTERS)
// ============================================================================

class QuizQuestionEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onSave;

  const QuizQuestionEditorScreen({
    super.key,
    this.question,
    required this.onSave,
  });

  @override
  State<QuizQuestionEditorScreen> createState() =>
      _QuizQuestionEditorScreenState();
}

class _QuizQuestionEditorScreenState extends State<QuizQuestionEditorScreen> {
  late TextEditingController questionController;
  late TextEditingController explanationController;
  late List<TextEditingController> optionControllers;
  int correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController(
      text: widget.question?['question'] ?? '',
    );
    explanationController = TextEditingController(
      text: widget.question?['explanation'] ?? '',
    );

    List<String> options = List<String>.from(
      widget.question?['options'] ?? ['', '', '', ''],
    );
    if (options.length < 4) {
      options.addAll(List.filled(4 - options.length, ''));
    }

    optionControllers =
        options.map((opt) => TextEditingController(text: opt)).toList();
    correctAnswerIndex = widget.question?['correctAnswer'] ?? 0;
  }

  @override
  void dispose() {
    questionController.dispose();
    explanationController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveQuestion() {
    if (questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final options =
        optionControllers
            .map((c) => c.text)
            .where((text) => text.isNotEmpty)
            .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 2 options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final question = {
      'question': questionController.text,
      'options': options,
      'correctAnswer': correctAnswerIndex,
      'explanation': explanationController.text,
    };

    widget.onSave(question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        title: Text(
          widget.question == null ? 'New Quiz Question' : 'Edit Quiz Question',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _saveQuestion,
            tooltip: 'Save Question',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: questionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your question...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1F3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Answer Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          correctAnswerIndex = value ?? 0;
                        });
                      },
                      activeColor: const Color(0xFF4CAF50),
                    ),
                    Expanded(
                      child: TextField(
                        controller: optionControllers[index],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Option ${index + 1}',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1C1F3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            correctAnswerIndex == index
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                correctAnswerIndex == index
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select the radio button to mark the correct answer',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Explanation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: explanationController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Explain why this is the correct answer...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1F3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WATCH CONTENT MANAGEMENT
// ============================================================================
class WatchContentManagement extends StatefulWidget {
  const WatchContentManagement({super.key});

  @override
  State<WatchContentManagement> createState() => _WatchContentManagementState();
}

class _WatchContentManagementState extends State<WatchContentManagement> {
  List<Map<String, dynamic>> allVideos = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> topics = [
    {'id': 'changes_of_matter', 'title': 'Changes of Matter', 'emoji': '🧪'},
    {'id': 'water_cycle', 'title': 'Water Cycle', 'emoji': '💧'},
    {'id': 'photosynthesis', 'title': 'Photosynthesis', 'emoji': '🌱'},
    {'id': 'solar_system', 'title': 'Solar System', 'emoji': '🪐'},
    {
      'id': 'ecosystem_food_web',
      'title': 'Ecosystem & Food Web',
      'emoji': '🦁',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Map<String, dynamic> _lessonToMap(
    ScienceLesson lesson, {
    bool isDefault = false,
    String? id,
  }) {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'isDefault': isDefault,
      'title': lesson.title,
      'emoji': lesson.emoji,
      'description': lesson.description,
      'videoUrl': lesson.videoUrl,
      'duration': lesson.duration,
      'funFact': lesson.funFact,
      'keyTopics': lesson.keyTopics,
      'moreFacts': lesson.moreFacts,
      'topic': lesson.topic,
      'quizQuestions':
          lesson.quizQuestions
              .map(
                (q) => {
                  'question': q.question,
                  'options': q.options,
                  'correctAnswer': q.correctAnswer,
                  'explanation': q.explanation,
                  'emoji': q.emoji,
                },
              )
              .toList(),
    };
  }

  String get _teacherUid => FirebaseService.currentUser!.uid;

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('teacher_content')
              .doc(_teacherUid)
              .get();

      final data = doc.data() ?? {};
      final teacherVideos = List<Map<String, dynamic>>.from(
        (data['teacher_videos'] as List? ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      );
      final modifiedMap = Map<String, dynamic>.from(
        data['modified_default_videos'] ?? {},
      );
      final deletedIds = List<String>.from(
        data['deleted_default_videos'] ?? [],
      );

      List<Map<String, dynamic>> defaultVideos = [];
      int index = 0;
      for (var lesson in scienceLessons) {
        String id = 'default_video_$index';
        var videoMap = _lessonToMap(lesson, isDefault: true, id: id);
        if (modifiedMap.containsKey(id)) {
          videoMap = Map<String, dynamic>.from(modifiedMap[id]);
          videoMap['isDefault'] = true;
          videoMap['id'] = id;
        }
        if (!deletedIds.contains(id)) defaultVideos.add(videoMap);
        index++;
      }

      setState(() {
        allVideos = [...defaultVideos, ...teacherVideos];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVideos() async {
    // ContentCache.invalidate();
    // ContentFetcher.invalidate();

    List<Map<String, dynamic>> teacherVideos = [];
    Map<String, dynamic> modifiedVideos = {};

    for (var video in allVideos) {
      if (video['isDefault'] == true) {
        modifiedVideos[video['id'] as String] = video;
      } else {
        teacherVideos.add(video);
      }
    }

    await FirebaseFirestore.instance
        .collection('teacher_content')
        .doc(_teacherUid)
        .set({
          'teacher_videos': teacherVideos,
          'modified_default_videos': modifiedVideos,
        }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────
  // Quiz question sub-dialog
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> _showQuizQuestionDialog({
    Map<String, dynamic>? existing,
  }) async {
    final questionCtrl = TextEditingController(
      text: existing?['question'] ?? '',
    );
    final option0Ctrl = TextEditingController(
      text: (existing?['options'] as List?)?.elementAtOrNull(0) ?? '',
    );
    final option1Ctrl = TextEditingController(
      text: (existing?['options'] as List?)?.elementAtOrNull(1) ?? '',
    );
    final option2Ctrl = TextEditingController(
      text: (existing?['options'] as List?)?.elementAtOrNull(2) ?? '',
    );
    final option3Ctrl = TextEditingController(
      text: (existing?['options'] as List?)?.elementAtOrNull(3) ?? '',
    );
    final explanationCtrl = TextEditingController(
      text: existing?['explanation'] ?? '',
    );
    final emojiCtrl = TextEditingController(text: existing?['emoji'] ?? '❓');
    int selectedCorrect = existing?['correctAnswer'] ?? 0;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setQ) => Dialog(
                  backgroundColor: const Color(0xFF12153A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFC107,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.quiz,
                                color: Color(0xFFFFC107),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              existing != null
                                  ? 'Edit Question'
                                  : 'New Question',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Emoji + Question row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: _styledField(
                                controller: emojiCtrl,
                                label: 'Emoji',
                                hint: '❓',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _styledField(
                                controller: questionCtrl,
                                label: 'Question',
                                hint: 'Type the question here…',
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Options
                        _sectionLabel(
                          'Answer Options',
                          Icons.list_alt,
                          const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(4, (i) {
                          final ctrl =
                              [
                                option0Ctrl,
                                option1Ctrl,
                                option2Ctrl,
                                option3Ctrl,
                              ][i];
                          final isCorrect = selectedCorrect == i;
                          return GestureDetector(
                            onTap: () => setQ(() => selectedCorrect = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color:
                                    isCorrect
                                        ? const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.15)
                                        : const Color(0xFF1C1F3E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isCorrect
                                          ? const Color(0xFF4CAF50)
                                          : Colors.white24,
                                  width: isCorrect ? 1.5 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  // Letter badge
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          isCorrect
                                              ? const Color(0xFF4CAF50)
                                              : Colors.white12,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        ['A', 'B', 'C', 'D'][i],
                                        style: TextStyle(
                                          color:
                                              isCorrect
                                                  ? Colors.white
                                                  : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: ctrl,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Option ${['A', 'B', 'C', 'D'][i]}',
                                        hintStyle: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Correct answer hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.touch_app,
                                color: Color(0xFF4CAF50),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tap an option to mark it as the correct answer  •  Currently: ${['A', 'B', 'C', 'D'][selectedCorrect]}',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Explanation
                        _sectionLabel(
                          'Explanation',
                          Icons.info_outline,
                          const Color(0xFF7B4DFF),
                        ),
                        const SizedBox(height: 10),
                        _styledField(
                          controller: explanationCtrl,
                          label: 'Explain the correct answer',
                          hint: 'Why is this the correct answer?',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white54,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Validate
                                  if (questionCtrl.text.trim().isEmpty) {
                                    _snack(
                                      'Please enter the question text',
                                      Colors.red,
                                    );
                                    return;
                                  }
                                  final opts = [
                                    option0Ctrl.text.trim(),
                                    option1Ctrl.text.trim(),
                                    option2Ctrl.text.trim(),
                                    option3Ctrl.text.trim(),
                                  ];
                                  if (opts.any((o) => o.isEmpty)) {
                                    _snack(
                                      'Please fill in all 4 options',
                                      Colors.red,
                                    );
                                    return;
                                  }
                                  if (explanationCtrl.text.trim().isEmpty) {
                                    _snack(
                                      'Please add an explanation',
                                      Colors.red,
                                    );
                                    return;
                                  }
                                  Navigator.pop(context, {
                                    'question': questionCtrl.text.trim(),
                                    'options': opts,
                                    'correctAnswer': selectedCorrect,
                                    'explanation': explanationCtrl.text.trim(),
                                    'emoji':
                                        emojiCtrl.text.trim().isEmpty
                                            ? '❓'
                                            : emojiCtrl.text.trim(),
                                  });
                                },
                                icon: const Icon(Icons.check),
                                label: const Text(
                                  'Save Question',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC107),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ─────────────────────────────────────────────
  // Main create/edit video dialog
  // ─────────────────────────────────────────────
  void _showCreateVideoDialog({
    Map<String, dynamic>? existingVideo,
    int? index,
  }) {
    final isEdit = existingVideo != null;

    final titleCtrl = TextEditingController(
      text: existingVideo?['title'] ?? '',
    );
    final emojiCtrl = TextEditingController(
      text: existingVideo?['emoji'] ?? '🎥',
    );
    final descriptionCtrl = TextEditingController(
      text: existingVideo?['description'] ?? '',
    );
    final videoUrlCtrl = TextEditingController(
      text: existingVideo?['videoUrl'] ?? '',
    );
    final durationCtrl = TextEditingController(
      text: existingVideo?['duration'] ?? '5 min',
    );
    final funFactCtrl = TextEditingController(
      text: existingVideo?['funFact'] ?? '',
    );

    String selectedTopic = existingVideo?['topic'] ?? 'changes_of_matter';
    bool isUploading = false;
    String uploadedVideoPath = existingVideo?['videoUrl'] ?? '';

    final bool isDefaultVideo = existingVideo?['isDefault'] == true;
    List<String> selectedSections = List<String>.from(
      existingVideo?['sections'] ?? [],
    );

    List<Map<String, dynamic>> quizQuestions = [];
    try {
      final raw = existingVideo?['quizQuestions'];
      if (raw != null && raw is List) {
        quizQuestions = List<Map<String, dynamic>>.from(
          raw.map((q) => Map<String, dynamic>.from(q as Map)),
        );
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialog) => Dialog(
                  backgroundColor: const Color(0xFF0D102C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C1F3E),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B4DFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isEdit ? Icons.edit_note : Icons.video_call,
                                color: const Color(0xFF7B4DFF),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? 'Edit Video Lesson'
                                    : 'Create Video Lesson',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed:
                                  isUploading
                                      ? null
                                      : () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isDefaultVideo) ...[
                                SectionSelector(
                                  selected: selectedSections,
                                  onChanged:
                                      (v) =>
                                          setDialog(() => selectedSections = v),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 75,
                                    child: _styledField(
                                      controller: emojiCtrl,
                                      label: 'Emoji',
                                      hint: '🎥',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _styledField(
                                      controller: titleCtrl,
                                      label: 'Lesson Title *',
                                      hint: 'e.g. The Water Cycle',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _sectionLabel(
                                'Topic Category',
                                Icons.category,
                                const Color(0xFF4CAF50),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F3E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedTopic,
                                    dropdownColor: const Color(0xFF1C1F3E),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white),
                                    items:
                                        topics.map((t) {
                                          return DropdownMenuItem<String>(
                                            value: t['id'] as String,
                                            child: Row(
                                              children: [
                                                Text(
                                                  t['emoji'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  t['title'] as String,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged:
                                        (v) =>
                                            setDialog(() => selectedTopic = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              _styledField(
                                controller: descriptionCtrl,
                                label: 'Description',
                                hint: 'What will students learn?',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),

                              _sectionLabel(
                                'Video Source',
                                Icons.video_library,
                                const Color(0xFF7B4DFF),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F3E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                          isUploading
                                              ? null
                                              : () async {
                                                setDialog(
                                                  () => isUploading = true,
                                                );
                                                setDialog(
                                                  () => isUploading = false,
                                                );
                                              },
                                      icon:
                                          isUploading
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : const Icon(Icons.upload_file),
                                      label: Text(
                                        isUploading
                                            ? 'Uploading…'
                                            : 'Upload from Device',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF7B4DFF,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          44,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: const [
                                        Expanded(
                                          child: Divider(color: Colors.white12),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(color: Colors.white12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: videoUrlCtrl,
                                      enabled: !isUploading,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Paste YouTube or video URL',
                                        hintStyle: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.link,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF0D102C),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 12,
                                            ),
                                      ),
                                      onChanged:
                                          (v) => setDialog(
                                            () => uploadedVideoPath = v,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: _styledField(
                                      controller: durationCtrl,
                                      label: 'Duration',
                                      hint: '5 min',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _styledField(
                                      controller: funFactCtrl,
                                      label: 'Fun Fact',
                                      hint: 'An interesting fact…',
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F3E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFC107,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFFC107,
                                        ).withOpacity(0.08),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.quiz,
                                            color: Color(0xFFFFC107),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Quiz Questions',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  'Students earn +30 pts for completing the quiz',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  quizQuestions.isNotEmpty
                                                      ? const Color(0xFFFFC107)
                                                      : Colors.white12,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${quizQuestions.length} Q',
                                              style: TextStyle(
                                                color:
                                                    quizQuestions.isNotEmpty
                                                        ? Colors.black
                                                        : Colors.white38,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (quizQuestions.isNotEmpty)
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          0,
                                        ),
                                        itemCount: quizQuestions.length,
                                        separatorBuilder:
                                            (_, __) =>
                                                const SizedBox(height: 8),
                                        itemBuilder: (context, qi) {
                                          final q = quizQuestions[qi];
                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D102C),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  q['emoji'] ?? '❓',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Q${qi + 1}: ${q['question'] ?? ''}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                    size: 18,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () async {
                                                    final updated =
                                                        await _showQuizQuestionDialog(
                                                          existing: q,
                                                        );
                                                    if (updated != null)
                                                      setDialog(
                                                        () =>
                                                            quizQuestions[qi] =
                                                                updated,
                                                      );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 18,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed:
                                                      () => setDialog(
                                                        () => quizQuestions
                                                            .removeAt(qi),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final newQ =
                                              await _showQuizQuestionDialog();
                                          if (newQ != null)
                                            setDialog(
                                              () => quizQuestions.add(newQ),
                                            );
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFFFFC107),
                                          size: 18,
                                        ),
                                        label: Text(
                                          quizQuestions.isEmpty
                                              ? 'Add First Question'
                                              : 'Add Another Question',
                                          style: const TextStyle(
                                            color: Color(0xFFFFC107),
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFFFFC107),
                                            width: 1.2,
                                          ),
                                          minimumSize: const Size(
                                            double.infinity,
                                            44,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C1F3E),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    isUploading
                                        ? null
                                        : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white54,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isUploading
                                        ? null
                                        : () async {
                                          if (titleCtrl.text.trim().isEmpty) {
                                            _snack(
                                              'Please enter a title',
                                              Colors.red,
                                            );
                                            return;
                                          }
                                          if (videoUrlCtrl.text
                                              .trim()
                                              .isEmpty) {
                                            _snack(
                                              'Please add a video URL',
                                              Colors.red,
                                            );
                                            return;
                                          }
                                          if (!isDefaultVideo &&
                                              selectedSections.isEmpty) {
                                            _snack(
                                              'Please select at least one section',
                                              Colors.red,
                                            );
                                            return;
                                          }

                                          final video = {
                                            'id':
                                                existingVideo?['id'] ??
                                                DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString(),
                                            'isDefault':
                                                existingVideo?['isDefault'] ??
                                                false,
                                            'title': titleCtrl.text.trim(),
                                            'emoji':
                                                emojiCtrl.text.trim().isEmpty
                                                    ? '🎥'
                                                    : emojiCtrl.text.trim(),
                                            'description':
                                                descriptionCtrl.text.trim(),
                                            'videoUrl':
                                                videoUrlCtrl.text.trim(),
                                            'duration':
                                                durationCtrl.text.trim(),
                                            'funFact': funFactCtrl.text.trim(),
                                            'topic': selectedTopic,
                                            'keyTopics':
                                                existingVideo?['keyTopics'] ??
                                                [],
                                            'moreFacts':
                                                existingVideo?['moreFacts'] ??
                                                [],
                                            'quizQuestions': quizQuestions,
                                            'sections':
                                                isDefaultVideo
                                                    ? []
                                                    : selectedSections,
                                          };

                                          setState(() {
                                            if (isEdit && index != null) {
                                              allVideos[index] = video;
                                            } else {
                                              allVideos.add(video);
                                            }
                                          });

                                          await _saveVideos();
                                          Navigator.pop(context);
                                          _snack(
                                            isEdit
                                                ? '✓ Lesson updated!'
                                                : '✓ Lesson created!',
                                            const Color(0xFF4CAF50),
                                          );
                                        },
                                icon: const Icon(Icons.save),
                                label: Text(
                                  isEdit ? 'Save Changes' : 'Create Lesson',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B4DFF),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
          ),
    );
  }

  // ─────────────────────────────────────────────
  // Delete video
  // ─────────────────────────────────────────────
  void _deleteVideo(int index) {
    final video = allVideos[index];
    final isDefault = video['isDefault'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Video?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${video['title']}"? This cannot be undone.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => allVideos.removeAt(index));

                  if (isDefault) {
                    await FirebaseFirestore.instance
                        .collection('teacher_content')
                        .doc(_teacherUid)
                        .set({
                          'deleted_default_videos': FieldValue.arrayUnion([
                            video['id'] as String,
                          ]),
                        }, SetOptions(merge: true));
                  }

                  await _saveVideos();
                  Navigator.pop(context);
                  // REMOVE: await _loadVideos();
                  _snack('Video deleted', Colors.red);
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Shared styled text field widget
  Widget _styledField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1C1F3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B4DFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
      );
    }

    final defaultCount = allVideos.where((v) => v['isDefault'] == true).length;
    final teacherCount = allVideos.length - defaultCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Lessons (${allVideos.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$defaultCount Default  •  $teacherCount Created by you',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateVideoDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              allVideos.isEmpty
                  ? Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateVideoDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Lesson'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: allVideos.length,
                    itemBuilder: (context, i) {
                      final video = allVideos[i];
                      final isDefault = video['isDefault'] == true;
                      final quizCount =
                          (video['quizQuestions'] as List?)?.length ?? 0;
                      final sections = List<String>.from(
                        video['sections'] ?? [],
                      );

                      return Card(
                        color: const Color(0xFF1C1F3E),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2D4E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        video['emoji'] ?? '🎥',
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                                  if (isDefault)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          size: 9,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            video['title'] ?? 'Untitled',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      video['description'] ?? 'No description',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white38,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          video['duration'] ?? 'N/A',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                quizCount > 0
                                                    ? const Color(
                                                      0xFFFFC107,
                                                    ).withOpacity(0.15)
                                                    : Colors.white.withOpacity(
                                                      0.05,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color:
                                                  quizCount > 0
                                                      ? const Color(
                                                        0xFFFFC107,
                                                      ).withOpacity(0.4)
                                                      : Colors.white12,
                                            ),
                                          ),
                                          child: Text(
                                            '$quizCount quiz Q',
                                            style: TextStyle(
                                              color:
                                                  quizCount > 0
                                                      ? const Color(0xFFFFC107)
                                                      : Colors.white24,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isDefault)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 4,
                                          children:
                                              sections.isEmpty
                                                  ? [
                                                    const Text(
                                                      'No sections',
                                                      style: TextStyle(
                                                        color: Colors.orange,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ]
                                                  : sections
                                                      .map(
                                                        (s) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFF7B4DFF,
                                                            ).withOpacity(0.2),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            s,
                                                            style:
                                                                const TextStyle(
                                                                  color: Color(
                                                                    0xFF7B4DFF,
                                                                  ),
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF64B5F6),
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _showCreateVideoDialog(
                                          existingVideo: video,
                                          index: i,
                                        ),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  const SizedBox(height: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFEF5350),
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteVideo(i),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// Helper extension used above
extension ListExtension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
