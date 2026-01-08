import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/screens/read_screen.dart'
    show scienceBooks, spaceBooks, Book;
import 'package:elearningapp_flutter/data/video_data.dart'
    show scienceLessons, ScienceLesson;

/// Comprehensive Teacher Content Management Screen
/// Allows teachers to Create, Read, Update, and Delete content for:
/// - Read (Books) - including default books from read_screen
/// - Watch (Videos/Lessons) - including default videos from video_data
/// - Play (Games) - including default quiz topics from quiz_screen
/// - Messages - View messages from students sent via Contact Support
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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.sports_esports), text: "Play"),
            Tab(icon: Icon(Icons.message), text: "Messages"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReadContentManagement(),
          WatchContentManagement(),
          PlayContentManagement(),
          TeacherMessagesTab(),
        ],
      ),
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
    final prefs = await SharedPreferences.getInstance();
    String? messagesJson = prefs.getString('admin_messages');

    if (messagesJson != null) {
      List<dynamic> decoded = jsonDecode(messagesJson);
      List<Map<String, dynamic>> allMessages =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // Filter to show only messages sent to "Teacher"
      _messages = allMessages.where((m) => m['to'] == 'Teacher').toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveMessages(List<Map<String, dynamic>> allMessages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_messages', jsonEncode(allMessages));
  }

  void _markMessageAsRead(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    String? messagesJson = prefs.getString('admin_messages');

    if (messagesJson != null) {
      List<dynamic> decoded = jsonDecode(messagesJson);
      List<Map<String, dynamic>> allMessages =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // Find and update the message
      int index = allMessages.indexWhere((m) => m['id'] == message['id']);
      if (index != -1) {
        allMessages[index]['isRead'] = true;
        await _saveMessages(allMessages);
        setState(() {
          message['isRead'] = true;
        });
      }
    }
  }

  void _deleteMessage(Map<String, dynamic> message) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F3E),
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this message?',
          style: TextStyle(color: Colors.white70),
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
              final prefs = await SharedPreferences.getInstance();
              String? messagesJson = prefs.getString('admin_messages');

              if (messagesJson != null) {
                List<dynamic> decoded = jsonDecode(messagesJson);
                List<Map<String, dynamic>> allMessages =
                    decoded.map((e) => Map<String, dynamic>.from(e)).toList();

                allMessages.removeWhere((m) => m['id'] == message['id']);
                await _saveMessages(allMessages);

                setState(() {
                  _messages.remove(message);
                });
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message deleted'),
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

  void _viewMessageDetails(Map<String, dynamic> message) {
    _markMessageAsRead(message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          child: _messages.isEmpty
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
                                  isRead ? Colors.grey : const Color(0xFF7B4DFF),
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
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF2A1B4A),
                          onSelected: (value) {
                            if (value == 'view') {
                              _viewMessageDetails(message);
                            } else if (value == 'delete') {
                              _deleteMessage(message);
                            }
                          },
                          itemBuilder: (context) => [
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
                                  Icon(Icons.delete, color: Colors.red, size: 20),
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

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> defaultBooks = [];
    int index = 0;
    for (var book in [...scienceBooks, ...spaceBooks]) {
      String bookId = 'default_book_$index';
      defaultBooks.add(_bookToMap(book, isDefault: true, id: bookId));
      index++;
    }

    String? booksJson = prefs.getString('teacher_books');
    List<Map<String, dynamic>> teacherBooks = [];
    if (booksJson != null) {
      try {
        teacherBooks = List<Map<String, dynamic>>.from(jsonDecode(booksJson));
      } catch (e) {
        teacherBooks = [];
      }
    }

    String? modifiedJson = prefs.getString('modified_default_books');
    Map<String, dynamic> modifiedBooks = {};
    if (modifiedJson != null) {
      try {
        modifiedBooks = Map<String, dynamic>.from(jsonDecode(modifiedJson));
        for (int i = 0; i < defaultBooks.length; i++) {
          String id = defaultBooks[i]['id'] as String;
          if (modifiedBooks.containsKey(id)) {
            defaultBooks[i] = modifiedBooks[id] as Map<String, dynamic>;
            defaultBooks[i]['isDefault'] = true;
            defaultBooks[i]['id'] = id;
          }
        }
      } catch (e) {
        modifiedBooks = {};
      }
    }

    String? deletedJson = prefs.getString('deleted_default_books');
    List<String> deletedIds = [];
    if (deletedJson != null) {
      try {
        deletedIds = List<String>.from(jsonDecode(deletedJson));
      } catch (e) {
        deletedIds = [];
      }
    }

    defaultBooks =
        defaultBooks.where((book) => !deletedIds.contains(book['id'])).toList();

    setState(() {
      allBooks = [...defaultBooks, ...teacherBooks];
      _isLoading = false;
    });
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> teacherBooks = [];
    Map<String, dynamic> modifiedBooks = {};

    for (var book in allBooks) {
      if (book['isDefault'] == true) {
        modifiedBooks[book['id']] = book;
      } else {
        teacherBooks.add(book);
      }
    }

    await prefs.setString('teacher_books', jsonEncode(teacherBooks));
    await prefs.setString('modified_default_books', jsonEncode(modifiedBooks));
  }

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
    final imageController = TextEditingController(
      text: existingBook?['image'] ?? 'lib/assets/book_default.png',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Text(
              isEdit ? 'Edit Book' : 'Create New Book',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        const SizedBox(height: 8),
                        TextField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            hintText: 'Enter image URL or file path',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Examples:\n• https://example.com/cover.jpg\n• lib/assets/images/book_cover.png',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.4,
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a book title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (imageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an image URL or path'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final book = {
                    'id':
                        existingBook?['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'isDefault': existingBook?['isDefault'] ?? false,
                    'title': titleController.text,
                    'summary': summaryController.text,
                    'theme': themeController.text,
                    'author': authorController.text,
                    'readTime': int.tryParse(readTimeController.text) ?? 15,
                    'funFact': funFactController.text,
                    'image': imageController.text,
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
                  Navigator.pop(context);
                  await _loadBooks();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Book updated!' : 'Book created!'),
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

                  if (isDefault) {
                    final prefs = await SharedPreferences.getInstance();
                    String? deletedJson = prefs.getString(
                      'deleted_default_books',
                    );
                    List<String> deletedIds = [];
                    if (deletedJson != null) {
                      try {
                        deletedIds = List<String>.from(jsonDecode(deletedJson));
                      } catch (e) {
                        deletedIds = [];
                      }
                    }
                    deletedIds.add(book['id'] as String);
                    await prefs.setString(
                      'deleted_default_books',
                      jsonEncode(deletedIds),
                    );
                  }

                  await _saveBooks();
                  Navigator.pop(context);
                  await _loadBooks();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book deleted!'),
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

    List<Map<String, dynamic>> defaultBooksList =
        allBooks.where((b) => b['isDefault'] == true).toList();
    List<Map<String, dynamic>> teacherBooksList =
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
                    '${defaultBooksList.length} Default • ${teacherBooksList.length} Created',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No books available',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showCreateBookDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B4DFF),
                          ),
                          child: const Text('Create Your First Book'),
                        ),
                      ],
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

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> defaultVideos = [];
    int index = 0;
    for (var lesson in scienceLessons) {
      String videoId = 'default_video_$index';
      defaultVideos.add(_lessonToMap(lesson, isDefault: true, id: videoId));
      index++;
    }

    String? videosJson = prefs.getString('teacher_videos');
    List<Map<String, dynamic>> teacherVideos = [];
    if (videosJson != null) {
      try {
        teacherVideos = List<Map<String, dynamic>>.from(jsonDecode(videosJson));
      } catch (e) {
        teacherVideos = [];
      }
    }

    String? modifiedJson = prefs.getString('modified_default_videos');
    Map<String, dynamic> modifiedVideos = {};
    if (modifiedJson != null) {
      try {
        modifiedVideos = Map<String, dynamic>.from(jsonDecode(modifiedJson));
        for (int i = 0; i < defaultVideos.length; i++) {
          String id = defaultVideos[i]['id'] as String;
          if (modifiedVideos.containsKey(id)) {
            defaultVideos[i] = modifiedVideos[id] as Map<String, dynamic>;
            defaultVideos[i]['isDefault'] = true;
            defaultVideos[i]['id'] = id;
          }
        }
      } catch (e) {
        modifiedVideos = {};
      }
    }

    String? deletedJson = prefs.getString('deleted_default_videos');
    List<String> deletedIds = [];
    if (deletedJson != null) {
      try {
        deletedIds = List<String>.from(jsonDecode(deletedJson));
      } catch (e) {
        deletedIds = [];
      }
    }

    defaultVideos =
        defaultVideos
            .where((video) => !deletedIds.contains(video['id']))
            .toList();

    setState(() {
      allVideos = [...defaultVideos, ...teacherVideos];
      _isLoading = false;
    });
  }

  Future<void> _saveVideos() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> teacherVideos = [];
    Map<String, dynamic> modifiedVideos = {};

    for (var video in allVideos) {
      if (video['isDefault'] == true) {
        modifiedVideos[video['id']] = video;
      } else {
        teacherVideos.add(video);
      }
    }

    await prefs.setString('teacher_videos', jsonEncode(teacherVideos));
    await prefs.setString(
      'modified_default_videos',
      jsonEncode(modifiedVideos),
    );
  }

  void _showCreateVideoDialog({
    Map<String, dynamic>? existingVideo,
    int? index,
  }) {
    final isEdit = existingVideo != null;
    final titleController = TextEditingController(
      text: existingVideo?['title'] ?? '',
    );
    final emojiController = TextEditingController(
      text: existingVideo?['emoji'] ?? '🎥',
    );
    final descriptionController = TextEditingController(
      text: existingVideo?['description'] ?? '',
    );
    final videoUrlController = TextEditingController(
      text: existingVideo?['videoUrl'] ?? '',
    );
    final durationController = TextEditingController(
      text: existingVideo?['duration'] ?? '5 min',
    );
    final funFactController = TextEditingController(
      text: existingVideo?['funFact'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Text(
              isEdit ? 'Edit Video Lesson' : 'Create New Video Lesson',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    controller: emojiController,
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
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
                      color: const Color(0xFF7B4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF7B4DFF).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.video_library,
                              color: Color(0xFF7B4DFF),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Video Source',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: videoUrlController,
                          decoration: const InputDecoration(
                            hintText:
                                'Enter YouTube URL, video URL, or file path',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Examples:\n• https://www.youtube.com/watch?v=...\n• https://example.com/video.mp4\n• lib/assets/videos/science.mp4',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (e.g., 5 min)',
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
                ],
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
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a video title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (videoUrlController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a video URL or path'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final video = {
                    'id':
                        existingVideo?['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'isDefault': existingVideo?['isDefault'] ?? false,
                    'title': titleController.text,
                    'emoji': emojiController.text,
                    'description': descriptionController.text,
                    'videoUrl': videoUrlController.text,
                    'duration': durationController.text,
                    'funFact': funFactController.text,
                    'keyTopics': existingVideo?['keyTopics'] ?? [],
                    'moreFacts': existingVideo?['moreFacts'] ?? [],
                    'quizQuestions': existingVideo?['quizQuestions'] ?? [],
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
                  await _loadVideos();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Video updated!' : 'Video created!',
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
    );
  }

  void _deleteVideo(int index) async {
    final video = allVideos[index];
    final isDefault = video['isDefault'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Video?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to permanently delete "${video['title']}"?',
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
                    allVideos.removeAt(index);
                  });

                  if (isDefault) {
                    final prefs = await SharedPreferences.getInstance();
                    String? deletedJson = prefs.getString(
                      'deleted_default_videos',
                    );
                    List<String> deletedIds = [];
                    if (deletedJson != null) {
                      try {
                        deletedIds = List<String>.from(jsonDecode(deletedJson));
                      } catch (e) {
                        deletedIds = [];
                      }
                    }
                    deletedIds.add(video['id'] as String);
                    await prefs.setString(
                      'deleted_default_videos',
                      jsonEncode(deletedIds),
                    );
                  }

                  await _saveVideos();
                  Navigator.pop(context);
                  await _loadVideos();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video deleted!'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
      );
    }

    List<Map<String, dynamic>> defaultVideosList =
        allVideos.where((v) => v['isDefault'] == true).toList();
    List<Map<String, dynamic>> teacherVideosList =
        allVideos.where((v) => v['isDefault'] != true).toList();

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
                    'Video Lessons (${allVideos.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${defaultVideosList.length} Default • ${teacherVideosList.length} Created',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateVideoDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              allVideos.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No video lessons available',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showCreateVideoDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B4DFF),
                          ),
                          child: const Text('Create Your First Video'),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: allVideos.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final video = allVideos[index];
                      final isDefault = video['isDefault'] == true;
                      return Card(
                        color: const Color(0xFF1C1F3E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              Text(
                                video['emoji'] ?? '🎥',
                                style: const TextStyle(fontSize: 32),
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
                                  video['title'] ?? 'Untitled',
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
                                video['description'] ?? 'No description',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Duration: ${video['duration'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _showCreateVideoDialog(
                                      existingVideo: video,
                                      index: index,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteVideo(index),
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
// PLAY CONTENT MANAGEMENT
// ============================================================================

class PlayContentManagement extends StatefulWidget {
  const PlayContentManagement({super.key});

  @override
  State<PlayContentManagement> createState() => _PlayContentManagementState();
}

class _PlayContentManagementState extends State<PlayContentManagement>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allQuizTopics = [];
  List<Map<String, dynamic>> teacherGames = [];
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> get defaultQuizTopics => {
    "Changes of Matter": {
      "icon": "🧪",
      "color": {"r": 255, "g": 107, "b": 157},
      "questions": [
        {
          "question": "What happens when ice melts into water?",
          "options": [
            "Chemical change",
            "Physical change",
            "No change",
            "Nuclear change",
          ],
          "answer": "Physical change",
        },
        {
          "question": "Which is an example of a chemical change?",
          "options": [
            "Boiling water",
            "Cutting paper",
            "Burning wood",
            "Melting chocolate",
          ],
          "answer": "Burning wood",
        },
        {
          "question": "What are the three states of matter?",
          "options": [
            "Hot, cold, warm",
            "Solid, liquid, gas",
            "Big, small, tiny",
            "Fast, slow, still",
          ],
          "answer": "Solid, liquid, gas",
        },
      ],
    },
    "Photosynthesis": {
      "icon": "🌱",
      "color": {"r": 76, "g": 175, "b": 80},
      "questions": [
        {
          "question": "What do plants need for photosynthesis?",
          "options": [
            "Sunlight, water, CO2",
            "Only water",
            "Only sunlight",
            "Soil and air",
          ],
          "answer": "Sunlight, water, CO2",
        },
        {
          "question": "What gas do plants release during photosynthesis?",
          "options": ["Carbon dioxide", "Nitrogen", "Oxygen", "Hydrogen"],
          "answer": "Oxygen",
        },
      ],
    },
    "Solar System": {
      "icon": "🌍",
      "color": {"r": 33, "g": 150, "b": 243},
      "questions": [
        {
          "question": "Which planet is closest to the Sun?",
          "options": ["Venus", "Earth", "Mercury", "Mars"],
          "answer": "Mercury",
        },
        {
          "question": "Which planet is known as the Red Planet?",
          "options": ["Mars", "Venus", "Jupiter", "Saturn"],
          "answer": "Mars",
        },
      ],
    },
  };

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> defaultTopics = [];
    for (var entry in defaultQuizTopics.entries) {
      String topicId = 'default_topic_${entry.key}';
      Map<String, dynamic> topic = {
        'id': topicId,
        'isDefault': true,
        'name': entry.key,
        'icon': entry.value['icon'],
        'color': entry.value['color'],
        'questions': entry.value['questions'],
      };
      defaultTopics.add(topic);
    }

    String? topicsJson = prefs.getString('teacher_quiz_topics');
    List<Map<String, dynamic>> teacherTopics = [];
    if (topicsJson != null) {
      try {
        teacherTopics = List<Map<String, dynamic>>.from(jsonDecode(topicsJson));
      } catch (e) {
        teacherTopics = [];
      }
    }

    String? modifiedJson = prefs.getString('modified_quiz_topics');
    Map<String, dynamic> modifiedTopics = {};
    if (modifiedJson != null) {
      try {
        modifiedTopics = Map<String, dynamic>.from(jsonDecode(modifiedJson));
        for (int i = 0; i < defaultTopics.length; i++) {
          String id = defaultTopics[i]['id'] as String;
          if (modifiedTopics.containsKey(id)) {
            defaultTopics[i] = modifiedTopics[id] as Map<String, dynamic>;
            defaultTopics[i]['isDefault'] = true;
            defaultTopics[i]['id'] = id;
          }
        }
      } catch (e) {
        modifiedTopics = {};
      }
    }

    String? deletedJson = prefs.getString('deleted_quiz_topics');
    List<String> deletedIds = [];
    if (deletedJson != null) {
      try {
        deletedIds = List<String>.from(jsonDecode(deletedJson));
      } catch (e) {
        deletedIds = [];
      }
    }

    defaultTopics =
        defaultTopics
            .where((topic) => !deletedIds.contains(topic['id']))
            .toList();

    String? gamesJson = prefs.getString('teacher_games');
    if (gamesJson != null) {
      try {
        teacherGames = List<Map<String, dynamic>>.from(jsonDecode(gamesJson));
      } catch (e) {
        teacherGames = [];
      }
    }

    setState(() {
      allQuizTopics = [...defaultTopics, ...teacherTopics];
      _isLoading = false;
    });
  }

  Future<void> _saveGames() async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> teacherTopics = [];
    Map<String, dynamic> modifiedTopics = {};

    for (var topic in allQuizTopics) {
      if (topic['isDefault'] == true) {
        modifiedTopics[topic['id']] = topic;
      } else {
        teacherTopics.add(topic);
      }
    }

    await prefs.setString('teacher_quiz_topics', jsonEncode(teacherTopics));
    await prefs.setString('modified_quiz_topics', jsonEncode(modifiedTopics));
    await prefs.setString('teacher_games', jsonEncode(teacherGames));
  }

  void _showCreateGameDialog({Map<String, dynamic>? existingGame, int? index}) {
    final isEdit = existingGame != null;
    final titleController = TextEditingController(
      text: existingGame?['title'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingGame?['description'] ?? '',
    );
    final categoryController = TextEditingController(
      text: existingGame?['category'] ?? '',
    );
    final imageController = TextEditingController(
      text: existingGame?['image'] ?? 'lib/assets/play.png',
    );
    final gameTypeController = TextEditingController(
      text: existingGame?['gameType'] ?? 'quiz',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Text(
              isEdit ? 'Edit Game' : 'Create New Game',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Game Title',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category (e.g., Science, Math)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: gameTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Game Type (quiz, puzzle, adventure, etc.)',
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
                      color: const Color(0xFFFF6B9D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B9D).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: Color(0xFFFF6B9D),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Game Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            hintText: 'Enter image URL or file path',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Examples:\n• https://example.com/game.png\n• lib/assets/images/play.png',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.4,
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a game title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (imageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an image URL or path'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final game = {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'category': categoryController.text,
                    'gameType': gameTypeController.text,
                    'image': imageController.text,
                    'createdAt':
                        existingGame?['createdAt'] ??
                        DateTime.now().toIso8601String(),
                  };

                  setState(() {
                    if (isEdit && index != null) {
                      teacherGames[index] = game;
                    } else {
                      teacherGames.add(game);
                    }
                  });

                  await _saveGames();
                  Navigator.pop(context);
                  await _loadGames();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Game updated!' : 'Game created!'),
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
    );
  }

  void _deleteGame(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Game?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete "${teacherGames[index]['title']}"?',
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
                    teacherGames.removeAt(index);
                  });

                  await _saveGames();
                  Navigator.pop(context);
                  await _loadGames();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Game deleted!'),
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

  void _showCreateQuizTopicDialog({
    Map<String, dynamic>? existingTopic,
    int? index,
  }) {
    final isEdit = existingTopic != null;
    final nameController = TextEditingController(
      text: existingTopic?['name'] ?? '',
    );
    final iconController = TextEditingController(
      text: existingTopic?['icon'] ?? '🧪',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Text(
              isEdit ? 'Edit Quiz Topic' : 'Create Quiz Topic',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Topic Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icon (Emoji)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
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
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a topic name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final topic = {
                    'id':
                        existingTopic?['id'] ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    'isDefault': existingTopic?['isDefault'] ?? false,
                    'name': nameController.text,
                    'icon': iconController.text,
                    'color':
                        existingTopic?['color'] ??
                        {"r": 123, "g": 77, "b": 255},
                    'questions': existingTopic?['questions'] ?? [],
                  };

                  setState(() {
                    if (isEdit && index != null) {
                      allQuizTopics[index] = topic;
                    } else {
                      allQuizTopics.add(topic);
                    }
                  });

                  await _saveGames();
                  Navigator.pop(context);
                  await _loadGames();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Topic updated!' : 'Topic created!',
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
    );
  }

  void _deleteQuizTopic(int index) async {
    final topic = allQuizTopics[index];
    final isDefault = topic['isDefault'] == true;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Quiz Topic?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to permanently delete "${topic['name']}"?',
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
                    allQuizTopics.removeAt(index);
                  });

                  if (isDefault) {
                    final prefs = await SharedPreferences.getInstance();
                    String? deletedJson = prefs.getString(
                      'deleted_quiz_topics',
                    );
                    List<String> deletedIds = [];
                    if (deletedJson != null) {
                      try {
                        deletedIds = List<String>.from(jsonDecode(deletedJson));
                      } catch (e) {
                        deletedIds = [];
                      }
                    }
                    deletedIds.add(topic['id'] as String);
                    await prefs.setString(
                      'deleted_quiz_topics',
                      jsonEncode(deletedIds),
                    );
                  }

                  await _saveGames();
                  Navigator.pop(context);
                  await _loadGames();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Topic deleted!'),
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

  void _manageQuizQuestions(int topicIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizTopicQuestionsScreen(
              topic: allQuizTopics[topicIndex],
              onSave: (updatedTopic) {
                setState(() {
                  allQuizTopics[topicIndex] = updatedTopic;
                });
                _saveGames();
              },
            ),
      ),
    );
    if (result == true) {
      _loadGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF7B4DFF),
          tabs: const [
            Tab(text: 'Quiz Topics', icon: Icon(Icons.quiz)),
            Tab(text: 'Games', icon: Icon(Icons.sports_esports)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Quiz Topics Tab
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quiz Topics (${allQuizTopics.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateQuizTopicDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Topic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B4DFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        allQuizTopics.isEmpty
                            ? const Center(
                              child: Text(
                                'No quiz topics available',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                            : ListView.builder(
                              itemCount: allQuizTopics.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                final topic = allQuizTopics[index];
                                final isDefault = topic['isDefault'] == true;
                                final questionsCount =
                                    (topic['questions'] as List?)?.length ?? 0;
                                return Card(
                                  color: const Color(0xFF1C1F3E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Stack(
                                      children: [
                                        Text(
                                          topic['icon'] ?? '🧪',
                                          style: const TextStyle(fontSize: 32),
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
                                            topic['name'] ?? 'Untitled',
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
                                              color: Colors.orange.withOpacity(
                                                0.2,
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
                                    subtitle: Text(
                                      '$questionsCount questions',
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
                                            Icons.quiz,
                                            color: Colors.green,
                                          ),
                                          onPressed:
                                              () => _manageQuizQuestions(index),
                                          tooltip: 'Manage Questions',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _showCreateQuizTopicDialog(
                                                existingTopic: topic,
                                                index: index,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteQuizTopic(index),
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
              // Games Tab
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Games (${teacherGames.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateGameDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Game'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B4DFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        teacherGames.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sports_esports,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No games created yet',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _showCreateGameDialog(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B4DFF),
                                    ),
                                    child: const Text('Create Your First Game'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: teacherGames.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                final game = teacherGames[index];
                                return Card(
                                  color: const Color(0xFF1C1F3E),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.sports_esports,
                                      color: Color(0xFF7B4DFF),
                                    ),
                                    title: Text(
                                      game['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          game['category'] ?? 'No category',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          'Type: ${game['gameType'] ?? 'Unknown'}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _showCreateGameDialog(
                                                existingGame: game,
                                                index: index,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteGame(index),
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
        ),
      ],
    );
  }
}

// ============================================================================
// QUIZ TOPIC QUESTIONS MANAGEMENT SCREEN
// ============================================================================

class QuizTopicQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic> topic;
  final Function(Map<String, dynamic>) onSave;

  const QuizTopicQuestionsScreen({
    super.key,
    required this.topic,
    required this.onSave,
  });

  @override
  State<QuizTopicQuestionsScreen> createState() =>
      _QuizTopicQuestionsScreenState();
}

class _QuizTopicQuestionsScreenState extends State<QuizTopicQuestionsScreen> {
  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    questions = List<Map<String, dynamic>>.from(
      widget.topic['questions'] ?? [],
    );
  }

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizTopicQuestionEditorScreen(
              onSave: (question) {
                setState(() {
                  questions.add(question);
                });
                _saveChanges();
              },
            ),
      ),
    );
  }

  void _editQuestion(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizTopicQuestionEditorScreen(
              question: questions[index],
              onSave: (question) {
                setState(() {
                  questions[index] = question;
                });
                _saveChanges();
              },
            ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Question?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this question?',
              style: TextStyle(color: Colors.white70),
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
                    questions.removeAt(index);
                  });
                  _saveChanges();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question deleted!'),
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
    final updatedTopic = Map<String, dynamic>.from(widget.topic);
    updatedTopic['questions'] = questions;
    widget.onSave(updatedTopic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        title: Text(
          'Questions: ${widget.topic['name']}',
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
                  'Questions (${questions.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4DFF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                questions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.quiz,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No questions yet',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _addQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DFF),
                            ),
                            child: const Text('Add First Question'),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return Card(
                          color: const Color(0xFF1C1F3E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4CAF50),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              question['question'] ?? 'No question text',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Answer: ${question['answer'] ?? 'Not set'}',
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
                                  onPressed: () => _editQuestion(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteQuestion(index),
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
// QUIZ TOPIC QUESTION EDITOR SCREEN
// ============================================================================

class QuizTopicQuestionEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onSave;

  const QuizTopicQuestionEditorScreen({
    super.key,
    this.question,
    required this.onSave,
  });

  @override
  State<QuizTopicQuestionEditorScreen> createState() =>
      _QuizTopicQuestionEditorScreenState();
}

class _QuizTopicQuestionEditorScreenState
    extends State<QuizTopicQuestionEditorScreen> {
  late TextEditingController questionController;
  late TextEditingController answerController;
  late List<TextEditingController> optionControllers;

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController(
      text: widget.question?['question'] ?? '',
    );
    answerController = TextEditingController(
      text: widget.question?['answer'] ?? '',
    );

    List<String> options = List<String>.from(
      widget.question?['options'] ?? ['', '', '', ''],
    );
    if (options.length < 4) {
      options.addAll(List.filled(4 - options.length, ''));
    }

    optionControllers =
        options.map((opt) => TextEditingController(text: opt)).toList();
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
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

    if (answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the correct answer'),
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
      'answer': answerController.text,
    };

    widget.onSave(question);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question saved!'),
        backgroundColor: Colors.green,
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
          widget.question == null ? 'New Question' : 'Edit Question',
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
                    prefixIcon: const Icon(
                      Icons.circle_outlined,
                      color: Colors.white54,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Correct Answer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: answerController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'Enter the correct answer (must match one of the options)',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1F3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
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
                      'The correct answer must exactly match one of the options above',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}