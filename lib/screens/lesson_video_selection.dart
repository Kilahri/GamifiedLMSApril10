// lesson_selection_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/data/video_data.dart';
import 'package:elearningapp_flutter/screens/watch_screen.dart';

class LessonSelectionScreen extends StatefulWidget {
  const LessonSelectionScreen({super.key});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen> {
  Set<int> completedLessons = {};
  int totalPoints = 0;

  // NEW: Store loaded lessons from SharedPreferences
  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    _loadLessonsFromStorage();
  }

  // NEW: Load lessons from SharedPreferences
  Future<void> _loadLessonsFromStorage() async {
    setState(() => _isLoadingLessons = true);
    final prefs = await SharedPreferences.getInstance();

    // Load default lessons
    List<Map<String, dynamic>> defaultLessons = [];
    int index = 0;
    for (var lesson in scienceLessons) {
      String videoId = 'default_video_$index';
      defaultLessons.add(_lessonToMap(lesson, isDefault: true, id: videoId));
      index++;
    }

    // Load teacher-created videos
    String? videosJson = prefs.getString('teacher_videos');
    List<Map<String, dynamic>> teacherVideos = [];
    if (videosJson != null) {
      try {
        teacherVideos = List<Map<String, dynamic>>.from(jsonDecode(videosJson));
      } catch (e) {
        teacherVideos = [];
      }
    }

    // Load modified default videos
    String? modifiedJson = prefs.getString('modified_default_videos');
    Map<String, dynamic> modifiedVideos = {};
    if (modifiedJson != null) {
      try {
        modifiedVideos = Map<String, dynamic>.from(jsonDecode(modifiedJson));
        for (int i = 0; i < defaultLessons.length; i++) {
          String id = defaultLessons[i]['id'] as String;
          if (modifiedVideos.containsKey(id)) {
            defaultLessons[i] = modifiedVideos[id] as Map<String, dynamic>;
            defaultLessons[i]['isDefault'] = true;
            defaultLessons[i]['id'] = id;
          }
        }
      } catch (e) {
        modifiedVideos = {};
      }
    }

    // Load deleted default videos
    String? deletedJson = prefs.getString('deleted_default_videos');
    List<String> deletedIds = [];
    if (deletedJson != null) {
      try {
        deletedIds = List<String>.from(jsonDecode(deletedJson));
      } catch (e) {
        deletedIds = [];
      }
    }

    defaultLessons =
        defaultLessons
            .where((video) => !deletedIds.contains(video['id']))
            .toList();

    setState(() {
      allLessons = [...defaultLessons, ...teacherVideos];
      _isLoadingLessons = false;
    });
  }

  // NEW: Convert ScienceLesson to Map
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

  @override
  Widget build(BuildContext context) {
    // NEW: Show loading state
    if (_isLoadingLessons) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F3E),
          elevation: 0,
          title: const Text(
            'Choose Your Lesson',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF7B4DFF)),
              SizedBox(height: 16),
              Text(
                "Loading lessons...",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // NEW: Use allLessons instead of scienceLessons
    final totalLessons = allLessons.length;
    final progress =
        totalLessons > 0 ? completedLessons.length / totalLessons : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        title: const Text(
          'Choose Your Lesson',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Refresh button to reload lessons
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadLessonsFromStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lessons refreshed!'),
                  backgroundColor: Color(0xFF7B4DFF),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Lessons',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          allLessons.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.video_library,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No lessons available',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contact your teacher to add lessons',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadLessonsFromStorage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Progress Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1C1F3E), Color(0xFF0D102C)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${completedLessons.length}/$totalLessons Completed',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lesson Categories
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildCategoryChip('All Lessons', true),
                        const SizedBox(width: 8),
                        _buildCategoryChip('In Progress', false),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Completed', false),
                      ],
                    ),
                  ),

                  // Lesson List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allLessons.length,
                      itemBuilder: (context, index) {
                        // NEW: Use allLessons instead of scienceLessons
                        final lesson = allLessons[index];
                        final isCompleted = completedLessons.contains(index);
                        final isDefault = lesson['isDefault'] == true;

                        return Card(
                          color: const Color(0xFF1C1F3E),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => WatchScreen(
                                        initialLessonIndex: index,
                                      ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Lesson Icon
                                      Stack(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color:
                                                  isCompleted
                                                      ? const Color(0xFF4CAF50)
                                                      : const Color(0xFF7B4DFF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                lesson['emoji'] as String,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Show badge for teacher-created content
                                          if (!isDefault)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFFC107),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),

                                      // Lesson Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    lesson['title'] as String,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (isCompleted)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFF4CAF50),
                                                    size: 24,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  color: Colors.white54,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  lesson['duration'] as String,
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Icon(
                                                  Icons.book,
                                                  color: Colors.white54,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Lesson ${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (!isDefault) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFC107,
                                                      ).withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'NEW',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFFFFC107,
                                                        ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    lesson['description'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Action Button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => WatchScreen(
                                                      initialLessonIndex: index,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            isCompleted
                                                ? Icons.replay
                                                : Icons.play_arrow,
                                          ),
                                          label: Text(
                                            isCompleted
                                                ? 'Watch Again'
                                                : 'Start Lesson',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF7B4DFF,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF7B4DFF) : const Color(0xFF1C1F3E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF7B4DFF) : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
