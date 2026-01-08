import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ============================================================================
// SAVED NOTES SCREEN
// ============================================================================

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> videoNotes = [];
  List<Map<String, dynamic>> bookNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Load video notes
    String? videoNotesJson = prefs.getString('video_notes');
    if (videoNotesJson != null) {
      try {
        videoNotes = List<Map<String, dynamic>>.from(
          jsonDecode(videoNotesJson),
        );
      } catch (e) {
        videoNotes = [];
      }
    }

    // Load book notes
    String? bookNotesJson = prefs.getString('book_notes');
    if (bookNotesJson != null) {
      try {
        bookNotes = List<Map<String, dynamic>>.from(jsonDecode(bookNotesJson));
      } catch (e) {
        bookNotes = [];
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteVideoNote(int index) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Note?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this note?',
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
                  setState(() {
                    videoNotes.removeAt(index);
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('video_notes', jsonEncode(videoNotes));

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted!'),
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

  Future<void> _deleteBookNote(int index) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Note?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this note?',
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
                  setState(() {
                    bookNotes.removeAt(index);
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('book_notes', jsonEncode(bookNotes));

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted!'),
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

  void _viewNoteDetails(Map<String, dynamic> note, bool isVideo) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVideo ? Icons.play_circle : Icons.menu_book,
                        color: const Color(0xFF7B4DFF),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          note['title'] ?? 'Untitled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note['date'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: Text(
                        note['content'] ?? 'No content',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, int index, bool isVideo) {
    return Card(
      color: const Color(0xFF1C1F3E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewNoteDetails(note, isVideo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B4DFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isVideo ? Icons.play_circle : Icons.menu_book,
                      color: const Color(0xFF7B4DFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note['title'] ?? 'Untitled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white54,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note['date'] ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (isVideo) {
                        _deleteVideoNote(index);
                      } else {
                        _deleteBookNote(index);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note['content'] ?? 'No content',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Tap to view full note',
                    style: TextStyle(
                      color: const Color(0xFF7B4DFF).withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: const Color(0xFF7B4DFF).withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No $type notes yet',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take notes while learning to save them here!',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        title: const Text('Saved Notes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B4DFF),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              icon: const Icon(Icons.play_circle),
              text: 'Video Notes (${videoNotes.length})',
            ),
            Tab(
              icon: const Icon(Icons.menu_book),
              text: 'Book Notes (${bookNotes.length})',
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  // Video Notes Tab
                  videoNotes.isEmpty
                      ? _buildEmptyState('video', Icons.play_circle_outline)
                      : RefreshIndicator(
                        color: const Color(0xFF7B4DFF),
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: videoNotes.length,
                          itemBuilder: (context, index) {
                            return _buildNoteCard(
                              videoNotes[index],
                              index,
                              true,
                            );
                          },
                        ),
                      ),

                  // Book Notes Tab
                  bookNotes.isEmpty
                      ? _buildEmptyState('book', Icons.menu_book_outlined)
                      : RefreshIndicator(
                        color: const Color(0xFF7B4DFF),
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookNotes.length,
                          itemBuilder: (context, index) {
                            return _buildNoteCard(
                              bookNotes[index],
                              index,
                              false,
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
// NOTES HELPER CLASS
// ============================================================================

class NotesHelper {
  /// Save a video note
  static Future<void> saveVideoNote({
    required String title,
    required String content,
    String? lessonEmoji,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Load existing notes
    String? notesJson = prefs.getString('video_notes');
    List<Map<String, dynamic>> notes = [];
    if (notesJson != null) {
      try {
        notes = List<Map<String, dynamic>>.from(jsonDecode(notesJson));
      } catch (e) {
        notes = [];
      }
    }

    // Add new note
    notes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': lessonEmoji != null ? '$lessonEmoji $title' : title,
      'content': content,
      'date': _formatDate(DateTime.now()),
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Save back to preferences
    await prefs.setString('video_notes', jsonEncode(notes));
  }

  /// Save a book note
  static Future<void> saveBookNote({
    required String bookTitle,
    required String chapterTitle,
    required String content,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Load existing notes
    String? notesJson = prefs.getString('book_notes');
    List<Map<String, dynamic>> notes = [];
    if (notesJson != null) {
      try {
        notes = List<Map<String, dynamic>>.from(jsonDecode(notesJson));
      } catch (e) {
        notes = [];
      }
    }

    // Add new note
    notes.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': '$bookTitle - $chapterTitle',
      'content': content,
      'date': _formatDate(DateTime.now()),
      'timestamp': DateTime.now().toIso8601String(),
      'bookTitle': bookTitle,
      'chapterTitle': chapterTitle,
    });

    // Save back to preferences
    await prefs.setString('book_notes', jsonEncode(notes));
  }

  /// Update existing video note
  static Future<void> updateVideoNote({
    required String noteId,
    required String content,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? notesJson = prefs.getString('video_notes');

    if (notesJson != null) {
      List<Map<String, dynamic>> notes = List<Map<String, dynamic>>.from(
        jsonDecode(notesJson),
      );

      for (int i = 0; i < notes.length; i++) {
        if (notes[i]['id'] == noteId) {
          notes[i]['content'] = content;
          notes[i]['date'] = _formatDate(DateTime.now());
          notes[i]['timestamp'] = DateTime.now().toIso8601String();
          break;
        }
      }

      await prefs.setString('video_notes', jsonEncode(notes));
    }
  }

  /// Get note for current lesson (if exists)
  static Future<String?> getVideoNoteForLesson(String lessonTitle) async {
    final prefs = await SharedPreferences.getInstance();
    String? notesJson = prefs.getString('video_notes');

    if (notesJson != null) {
      List<Map<String, dynamic>> notes = List<Map<String, dynamic>>.from(
        jsonDecode(notesJson),
      );

      for (var note in notes) {
        if (note['title']?.contains(lessonTitle) ?? false) {
          return note['content'];
        }
      }
    }

    return null;
  }

  /// Format date helper
  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================================
// UPDATED WATCH SCREEN INTEGRATION
// ============================================================================

// Add this method to your WatchScreen's _WatchScreenState class:

/*
// Replace the existing notes saving functionality with this:

Future<void> _saveNotes() async {
  if (_notesController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please write something before saving!'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final lesson = scienceLessons[currentLessonIndex];
  
  await NotesHelper.saveVideoNote(
    title: lesson.title,
    content: _notesController.text.trim(),
    lessonEmoji: lesson.emoji,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Notes saved successfully! ✓'),
      backgroundColor: Color(0xFF4CAF50),
      duration: Duration(seconds: 2),
    ),
  );
}

// Update the Save Notes button onPressed to:
ElevatedButton.icon(
  onPressed: _saveNotes,
  icon: const Icon(Icons.save),
  label: const Text("Save Notes"),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF7B4DFF),
    minimumSize: const Size(double.infinity, 45),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
*/

// ============================================================================
// SETTINGS SCREEN INTEGRATION
// ============================================================================

// Add this to your settings screen build method:

/*
_buildSettingsTile(
  icon: Icons.bookmark_border,
  title: 'Saved Items & Notes',
  subtitle: 'Review your saved lessons and notes',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedNotesScreen(),
      ),
    );
  },
),
*/
