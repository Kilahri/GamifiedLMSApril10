import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/data/video_data.dart'
    show scienceLessons, ScienceLesson;

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
