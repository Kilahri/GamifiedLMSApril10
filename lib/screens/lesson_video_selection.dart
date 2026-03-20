// lesson_selection_screen.dart - TOPIC-BASED VERSION
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

  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;

  // Topic definitions
  final List<Map<String, dynamic>> topics = [
    {
      'id': 'changes_of_matter',
      'title': 'Changes of Matter',
      'emoji': '🧪',
      'description': 'Learn about physical and chemical changes',
      'color': Color(0xFF7B4DFF),
    },
    {
      'id': 'water_cycle',
      'title': 'Water Cycle',
      'emoji': '💧',
      'description': 'Explore how water moves through Earth',
      'color': Color(0xFF2196F3),
    },
    {
      'id': 'photosynthesis',
      'title': 'Photosynthesis',
      'emoji': '🌱',
      'description': 'Discover how plants make food',
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'solar_system',
      'title': 'Solar System',
      'emoji': '🪐',
      'description': 'Journey through space and planets',
      'color': Color(0xFFFF9800),
    },
    {
      'id': 'ecosystem_food_web',
      'title': 'Ecosystem & Food Web',
      'emoji': '🦁',
      'description': 'Understand nature\'s connections',
      'color': Color(0xFF8BC34A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLessonsFromStorage();
  }

  Future<void> _loadLessonsFromStorage() async {
    setState(() => _isLoadingLessons = true);
    final prefs = await SharedPreferences.getInstance();

    // Load default lessons
    List<Map<String, dynamic>> defaultLessons = [];
    int index = 0;
    for (var lesson in scienceLessons) {
      String videoId = 'default_video_$index';
      final lessonMap = _lessonToMap(lesson, isDefault: true, id: videoId);
      defaultLessons.add(lessonMap);

      // DEBUG: Print each lesson as it's loaded
      print(
        'Loading lesson $index: ${lessonMap['title']} with topic: ${lessonMap['topic']}',
      );
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
            // Make sure topic is preserved
            if (!defaultLessons[i].containsKey('topic')) {
              defaultLessons[i]['topic'] = scienceLessons[i].topic;
            }
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

    // DEBUG: Print final lesson count
    print('=== TOTAL LESSONS LOADED: ${allLessons.length} ===');
    for (var i = 0; i < allLessons.length; i++) {
      print(
        'Final Lesson $i: ${allLessons[i]['title']} - Topic: ${allLessons[i]['topic']}',
      );
    }
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
      'topic': lesson.topic, // Use topic directly from lesson
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

  // Get lessons count for a specific topic
  int _getLessonCountForTopic(String topicId) {
    return allLessons.where((lesson) => lesson['topic'] == topicId).length;
  }

  // Navigate to topic lessons
  void _navigateToTopicLessons(String topicId, String topicTitle) {
    final topicLessons =
        allLessons
            .asMap()
            .entries
            .where((entry) => entry.value['topic'] == topicId)
            .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TopicLessonsScreen(
              topicId: topicId,
              topicTitle: topicTitle,
              lessons: topicLessons,
              allLessons: allLessons,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLessons) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F3E),
          elevation: 0,
          title: const Text(
            'Science Topics',
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
                "Loading topics...",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final totalLessons = allLessons.length;
    final progress =
        totalLessons > 0 ? completedLessons.length / totalLessons : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        title: const Text(
          'Science Topics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadLessonsFromStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Topics refreshed!'),
                  backgroundColor: Color(0xFF7B4DFF),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Topics',
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
      body: Column(
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
                      '${completedLessons.length}/$totalLessons Lessons',
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

          // Topic Categories Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.category, color: Color(0xFF7B4DFF), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Choose a Topic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Topics Grid
          Expanded(
            child:
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
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Contact your teacher to add lessons',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
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
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        final lessonCount = _getLessonCountForTopic(
                          topic['id'] as String,
                        );

                        return Card(
                          color: const Color(0xFF1C1F3E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (lessonCount > 0) {
                                _navigateToTopicLessons(
                                  topic['id'] as String,
                                  topic['title'] as String,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No lessons in this topic yet',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    (topic['color'] as Color).withOpacity(0.2),
                                    (topic['color'] as Color).withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: topic['color'] as Color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (topic['color'] as Color)
                                              .withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        topic['emoji'] as String,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    topic['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    topic['description'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          lessonCount > 0
                                              ? topic['color'] as Color
                                              : Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color:
                                              lessonCount > 0
                                                  ? Colors.white
                                                  : Colors.white54,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$lessonCount ${lessonCount == 1 ? 'video' : 'videos'}',
                                          style: TextStyle(
                                            color:
                                                lessonCount > 0
                                                    ? Colors.white
                                                    : Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
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
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOPIC LESSONS SCREEN
// ============================================================================

class TopicLessonsScreen extends StatelessWidget {
  final String topicId;
  final String topicTitle;
  final List<MapEntry<int, Map<String, dynamic>>> lessons;
  final List<Map<String, dynamic>> allLessons;

  const TopicLessonsScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.lessons,
    required this.allLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          topicTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Topic Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1F3E), Color(0xFF0D102C)],
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.video_library,
                  color: Color(0xFF7B4DFF),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '${lessons.length} ${lessons.length == 1 ? 'Lesson' : 'Lessons'} Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Lessons List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lessonEntry = lessons[index];
                final lesson = lessonEntry.value;
                final globalIndex = lessonEntry.key;
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
                              (context) =>
                                  WatchScreen(initialLessonIndex: globalIndex),
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
                                      color: const Color(0xFF7B4DFF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        lesson['emoji'] as String,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                  if (!isDefault)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson['title'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                        if (!isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFFC107,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(
                                                color: Color(0xFFFFC107),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
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
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => WatchScreen(
                                        initialLessonIndex: globalIndex,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Lesson',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 45),
                            ),
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
