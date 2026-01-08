import 'package:flutter/material.dart';

class BookContentEditorScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final Function(Map<String, dynamic>) onSave;

  const BookContentEditorScreen({
    super.key,
    required this.book,
    required this.onSave,
  });

  @override
  State<BookContentEditorScreen> createState() =>
      _BookContentEditorScreenState();
}

class _BookContentEditorScreenState extends State<BookContentEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<dynamic> _chapters;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book['title']);
    _descriptionController = TextEditingController(
      text: widget.book['description'],
    );
    // Create a deep copy of chapters so we don't modify the original until saved
    _chapters = List.from(widget.book['chapters'] ?? []);
  }

  void _save() {
    final updatedBook = Map<String, dynamic>.from(widget.book);
    updatedBook['title'] = _titleController.text;
    updatedBook['description'] = _descriptionController.text;
    updatedBook['chapters'] = _chapters;

    widget.onSave(updatedBook);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        title: const Text("Edit Book Content"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.greenAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Book Title",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Chapters",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color(0xFF1C1F3E),
                  child: ListTile(
                    title: Text(
                      _chapters[index]['title'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Tap to edit content",
                      style: TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      color: Colors.purpleAccent,
                    ),
                    onTap: () => _editChapterContent(index),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editChapterContent(int index) {
    // This could open another screen specifically for editing the long text of a chapter
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController chapterContentController = TextEditingController(
          text: _chapters[index]['content'],
        );
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1F3E),
          title: Text("Edit ${_chapters[index]['title']}"),
          content: TextField(
            controller: chapterContentController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              fillColor: Color(0xFF0D102C),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _chapters[index]['content'] = chapterContentController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}
