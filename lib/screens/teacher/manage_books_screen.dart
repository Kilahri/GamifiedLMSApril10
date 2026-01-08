import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Import your Book model (adjust path as needed)
// Assuming Book, BookChapter, QuizQuestion classes are in read_screen.dart

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  List<Map<String, dynamic>> books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    String? booksJson = prefs.getString('teacher_books');

    if (booksJson != null) {
      List<dynamic> decoded = jsonDecode(booksJson);
      setState(() {
        books = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_books', jsonEncode(books));
  }

  void _showAddEditDialog({Map<String, dynamic>? book, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddEditBookScreen(
              book: book,
              onSave: (newBook) {
                setState(() {
                  if (index != null) {
                    books[index] = newBook;
                  } else {
                    books.add(newBook);
                  }
                });
                _saveBooks();
              },
            ),
      ),
    );
  }

  void _deleteBook(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Delete Book',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this book and all its chapters? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    books.removeAt(index);
                  });
                  _saveBooks();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book deleted!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case "Biology":
        return Colors.lightGreenAccent;
      case "Chemistry":
        return Colors.purpleAccent;
      case "Earth Science":
        return Colors.blueAccent;
      case "Physics":
        return Colors.cyanAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      body:
          books.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No books yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first educational book',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Create Book',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header with Add button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${books.length} ${books.length == 1 ? 'Book' : 'Books'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Create Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Books List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1F3E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getThemeColor(
                                book['theme'] ?? 'General',
                              ).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.orange,
                                size: 32,
                              ),
                            ),
                            title: Text(
                              book['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                if (book['author']?.isNotEmpty ?? false)
                                  Text(
                                    'by ${book['author']}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                Row(
                                  children: [
                                    if (book['theme']?.isNotEmpty ?? false)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 4,
                                          right: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getThemeColor(
                                            book['theme'],
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          book['theme'] ?? '',
                                          style: TextStyle(
                                            color: _getThemeColor(
                                              book['theme'],
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (book['chapters'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${book['chapters'].length} chapters',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (book['summary']?.isNotEmpty ?? false)
                                  Text(
                                    book['summary'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
                                      () => _showAddEditDialog(
                                        book: book,
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
              ),
    );
  }
}

// Separate screen for adding/editing books with chapters
class AddEditBookScreen extends StatefulWidget {
  final Map<String, dynamic>? book;
  final Function(Map<String, dynamic>) onSave;

  const AddEditBookScreen({super.key, this.book, required this.onSave});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _authorController = TextEditingController();
  final _funFactController = TextEditingController();
  final _imageController = TextEditingController();
  int _readTime = 15;
  String _selectedTheme = 'Chemistry';
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!['title'] ?? '';
      _summaryController.text = widget.book!['summary'] ?? '';
      _authorController.text = widget.book!['author'] ?? '';
      _funFactController.text = widget.book!['funFact'] ?? '';
      _imageController.text = widget.book!['image'] ?? '';
      _readTime = widget.book!['readTime'] ?? 15;
      _selectedTheme = widget.book!['theme'] ?? 'Chemistry';
      _chapters = List<Map<String, dynamic>>.from(
        widget.book!['chapters'] ?? [],
      );
    }
  }

  void _addChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddEditChapterScreen(
              onSave: (chapter) {
                setState(() {
                  _chapters.add(chapter);
                });
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
            (context) => AddEditChapterScreen(
              chapter: _chapters[index],
              onSave: (chapter) {
                setState(() {
                  _chapters[index] = chapter;
                });
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
              'Delete Chapter',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Remove this chapter?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() => _chapters.removeAt(index));
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _saveBook() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookData = {
      'title': _titleController.text,
      'image':
          _imageController.text.isEmpty
              ? 'lib/assets/book_default.png'
              : _imageController.text,
      'summary': _summaryController.text,
      'theme': _selectedTheme,
      'chapters': _chapters,
      'author': _authorController.text,
      'readTime': _readTime,
      'funFact': _funFactController.text,
    };

    widget.onSave(bookData);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.book == null ? 'Book created!' : 'Book updated!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        title: Text(widget.book == null ? 'Create Book' : 'Edit Book'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveBook),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_titleController, 'Book Title *', Icons.title),
            const SizedBox(height: 12),
            _buildTextField(_authorController, 'Author', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(
              _summaryController,
              'Summary',
              Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(_imageController, 'Image Path', Icons.image),
            const SizedBox(height: 12),

            // Theme Dropdown
            DropdownButtonFormField<String>(
              value: _selectedTheme,
              dropdownColor: const Color(0xFF1C1F3E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Theme',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.category, color: Colors.orange),
                filled: true,
                fillColor: const Color(0xFF1C1F3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  [
                        'Chemistry',
                        'Biology',
                        'Earth Science',
                        'Physics',
                        'General',
                      ]
                      .map(
                        (theme) =>
                            DropdownMenuItem(value: theme, child: Text(theme)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedTheme = value!),
            ),

            const SizedBox(height: 12),

            // Read Time Slider
            Text(
              'Read Time: $_readTime minutes',
              style: const TextStyle(color: Colors.white70),
            ),
            Slider(
              value: _readTime.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: Colors.orange,
              label: '$_readTime min',
              onChanged: (value) => setState(() => _readTime = value.toInt()),
            ),

            const SizedBox(height: 12),
            _buildTextField(
              _funFactController,
              'Fun Fact',
              Icons.lightbulb,
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),

            // Chapters Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chapters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addChapter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Chapter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_chapters.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No chapters yet. Add your first chapter!',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ..._chapters.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> chapter = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      chapter['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${chapter['keyPoints']?.length ?? 0} key points',
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
                            size: 20,
                          ),
                          onPressed: () => _editChapter(index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteChapter(index),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: const Color(0xFF1C1F3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }
}

// Screen for adding/editing individual chapters
class AddEditChapterScreen extends StatefulWidget {
  final Map<String, dynamic>? chapter;
  final Function(Map<String, dynamic>) onSave;

  const AddEditChapterScreen({super.key, this.chapter, required this.onSave});

  @override
  State<AddEditChapterScreen> createState() => _AddEditChapterScreenState();
}

class _AddEditChapterScreenState extends State<AddEditChapterScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _didYouKnowController = TextEditingController();
  final List<TextEditingController> _keyPointControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.chapter != null) {
      _titleController.text = widget.chapter!['title'] ?? '';
      _contentController.text = widget.chapter!['content'] ?? '';
      _didYouKnowController.text = widget.chapter!['didYouKnow'] ?? '';

      final keyPoints = widget.chapter!['keyPoints'] as List? ?? [];
      for (var point in keyPoints) {
        final controller = TextEditingController(text: point);
        _keyPointControllers.add(controller);
      }
    }

    if (_keyPointControllers.isEmpty) {
      _addKeyPoint();
    }
  }

  void _addKeyPoint() {
    setState(() {
      _keyPointControllers.add(TextEditingController());
    });
  }

  void _removeKeyPoint(int index) {
    setState(() {
      _keyPointControllers[index].dispose();
      _keyPointControllers.removeAt(index);
    });
  }

  void _save() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and content are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final keyPoints =
        _keyPointControllers
            .map((c) => c.text)
            .where((text) => text.isNotEmpty)
            .toList();

    final chapterData = {
      'title': _titleController.text,
      'content': _contentController.text,
      'keyPoints': keyPoints,
      'didYouKnow': _didYouKnowController.text,
      'quizQuestions': [], // Teachers can add quiz questions later if needed
    };

    widget.onSave(chapterData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        title: Text(widget.chapter == null ? 'Add Chapter' : 'Edit Chapter'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_titleController, 'Chapter Title *', Icons.title),
            const SizedBox(height: 12),
            _buildTextField(
              _contentController,
              'Content *',
              Icons.article,
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _didYouKnowController,
              'Did You Know?',
              Icons.lightbulb,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Key Points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addKeyPoint,
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._keyPointControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Key point ${index + 1}',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1C1F3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (_keyPointControllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeKeyPoint(index),
                      ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Chapter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: const Color(0xFF1C1F3E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _didYouKnowController.dispose();
    for (var controller in _keyPointControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
