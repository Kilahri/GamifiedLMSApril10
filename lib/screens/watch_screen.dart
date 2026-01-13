// watch_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/quiz_data/video_quiz_screen.dart';
import 'package:elearningapp_flutter/data/video_data.dart';

class WatchScreen extends StatefulWidget {
  final int initialLessonIndex;

  const WatchScreen({super.key, this.initialLessonIndex = 0});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late TabController _tabController;

  late int currentLessonIndex;
  bool _isInitialized = false;
  bool _showControls = true;
  final TextEditingController _notesController = TextEditingController();

  // Track completion and points
  Set<int> completedLessons = {};
  Map<int, int> lessonPoints = {};
  int totalPoints = 0;

  // NEW: Store loaded lessons from SharedPreferences
  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    currentLessonIndex = widget.initialLessonIndex;
    _tabController = TabController(length: 4, vsync: this);
    _loadLessonsFromStorage(); // Load lessons first
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

    // Load video after lessons are loaded
    if (allLessons.isNotEmpty) {
      _loadVideo(allLessons[currentLessonIndex]['videoUrl'] as String);
      _loadExistingNote();
    }
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

  void _loadVideo(String url) {
    if (url.startsWith('lib/assets/videos/')) {
      _videoController =
          VideoPlayerController.asset(url)
            ..initialize().then((_) {
              setState(() {
                _isInitialized = true;
              });
            })
            ..addListener(() {
              if (mounted) {
                setState(() {
                  if (_videoController.value.position.inSeconds >
                          (_videoController.value.duration.inSeconds * 0.9) &&
                      !completedLessons.contains(currentLessonIndex)) {
                    _markLessonComplete();
                  }
                });
              }
            });
    } else {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(url))
            ..initialize().then((_) {
              setState(() {
                _isInitialized = true;
              });
            })
            ..addListener(() {
              if (mounted) {
                setState(() {
                  if (_videoController.value.position.inSeconds >
                          (_videoController.value.duration.inSeconds * 0.9) &&
                      !completedLessons.contains(currentLessonIndex)) {
                    _markLessonComplete();
                  }
                });
              }
            });
    }
  }

  Future<void> _loadExistingNote() async {
    if (allLessons.isEmpty) return;
    final lesson = allLessons[currentLessonIndex];
    final existingNote = await NotesHelper.getVideoNoteForLesson(
      lesson['title'] as String,
    );

    if (existingNote != null) {
      setState(() {
        _notesController.text = existingNote;
      });
    } else {
      setState(() {
        _notesController.clear();
      });
    }
  }

  void _markLessonComplete() {
    setState(() {
      completedLessons.add(currentLessonIndex);
      lessonPoints[currentLessonIndex] = 20;
      totalPoints += 20;
    });
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.celebration, color: Color(0xFFFFC107), size: 32),
                SizedBox(width: 10),
                Text("Great Job!", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "You completed this lesson!",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B4DFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFC107), size: 40),
                      SizedBox(height: 8),
                      Text(
                        "+20 Points!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Continue Learning",
                  style: TextStyle(color: Color(0xFF7B4DFF)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToQuiz();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                child: const Text("Take Quiz +30 pts"),
              ),
            ],
          ),
    );
  }

  void _navigateToQuiz() async {
    if (allLessons.isEmpty) return;

    // Convert Map to ScienceLesson for quiz screen
    final lessonMap = allLessons[currentLessonIndex];
    final lesson = _mapToLesson(lessonMap);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoQuizScreen(lesson: lesson)),
    );

    if (result != null && result is int) {
      setState(() {
        totalPoints += result;
        lessonPoints[currentLessonIndex] =
            (lessonPoints[currentLessonIndex] ?? 0) + result;
      });
    }
  }

  // NEW: Convert Map back to ScienceLesson for quiz
  ScienceLesson _mapToLesson(Map<String, dynamic> map) {
    return ScienceLesson(
      title: map['title'] as String,
      emoji: map['emoji'] as String,
      description: map['description'] as String,
      videoUrl: map['videoUrl'] as String,
      duration: map['duration'] as String,
      keyTopics: List<String>.from(map['keyTopics'] ?? []),
      funFact: map['funFact'] as String,
      moreFacts: List<String>.from(map['moreFacts'] ?? []),
      quizQuestions:
          (map['quizQuestions'] as List)
              .map(
                (q) => QuizQuestion(
                  question: q['question'] as String,
                  options: List<String>.from(q['options']),
                  correctAnswer: q['correctAnswer'] as int,
                  explanation: q['explanation'] as String,
                  emoji: q['emoji'] as String,
                ),
              )
              .toList(),
    );
  }

  void _changeLesson(int newIndex) {
    if (newIndex >= 0 && newIndex < allLessons.length) {
      setState(() {
        currentLessonIndex = newIndex;
        _isInitialized = false;
        _videoController.dispose();
        _loadVideo(allLessons[currentLessonIndex]['videoUrl'] as String);
        _loadExistingNote();
      });
    }
  }

  Future<void> _saveNotes() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before saving!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (allLessons.isEmpty) return;
    final lesson = allLessons[currentLessonIndex];
    await NotesHelper.saveVideoNote(
      title: lesson['title'] as String,
      content: _notesController.text.trim(),
      lessonEmoji: lesson['emoji'] as String?,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notes saved successfully! ✓'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildVideoControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: IconButton(
                icon: Icon(
                  _videoController.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 80,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _videoController.value.isPlaying
                        ? _videoController.pause()
                        : _videoController.play();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    _formatDuration(_videoController.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VideoProgressIndicator(
                      _videoController,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF7B4DFF),
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_videoController.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Show loading while lessons are being loaded
    if (_isLoadingLessons || allLessons.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D102C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Video Lesson',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child:
              _isLoadingLessons
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF7B4DFF)),
                      SizedBox(height: 16),
                      Text(
                        "Loading lessons...",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                  : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No lessons available',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
        ),
      );
    }

    final lesson = allLessons[currentLessonIndex];
    final totalLessons = allLessons.length;
    final progress = completedLessons.length / totalLessons;
    final isCompleted = completedLessons.contains(currentLessonIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Lesson Selection',
        ),
        title: const Text(
          'Video Lesson',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
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
          // Video Player
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio:
                    _isInitialized
                        ? _videoController.value.aspectRatio
                        : 16 / 9,
                child: Stack(
                  children: [
                    Center(
                      child:
                          _isInitialized
                              ? VideoPlayer(_videoController)
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF7B4DFF),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Loading video...",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                    ),
                    if (_isInitialized) _buildVideoControls(),
                  ],
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1C1F3E), Color(0xFF0D102C)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${lesson['emoji']} ${lesson['title']}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Lesson ${currentLessonIndex + 1} of $totalLessons • ${lesson['duration']}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "${completedLessons.length} of $totalLessons lessons completed",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Completed!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF7B4DFF),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: "📖 About"),
                    Tab(text: "📝 Notes"),
                    Tab(text: "📚 Lessons"),
                    Tab(text: "💡 Fun Facts"),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // About Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "What You'll Learn:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lesson['description'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Key Topics:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(lesson['keyTopics'] as List).map(
                              (topic) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        topic as String,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToQuiz,
                              icon: const Icon(Icons.quiz),
                              label: const Text(
                                "Take Quiz & Earn 30 Points!",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notes Tab
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: Color(0xFFFFC107),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Your Learning Notes",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Write down important things you learned!",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7B4DFF,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF7B4DFF),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.save,
                                        color: Color(0xFF7B4DFF),
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Auto-saved',
                                        style: TextStyle(
                                          color: Color(0xFF7B4DFF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TextField(
                                controller: _notesController,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      "• What did you find most interesting?\n• What questions do you have?\n• What would you like to learn more about?",
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1C1F3E),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                          ],
                        ),
                      ),

                      // Lessons Tab
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: allLessons.length,
                        itemBuilder: (context, index) {
                          final lessonItem = allLessons[index];
                          final isCurrent = index == currentLessonIndex;
                          final isLessonCompleted = completedLessons.contains(
                            index,
                          );

                          return Card(
                            color:
                                isCurrent
                                    ? const Color(0xFF7B4DFF).withOpacity(0.2)
                                    : const Color(0xFF1C1F3E),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    isCurrent
                                        ? const Color(0xFF7B4DFF)
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              onTap: () => _changeLesson(index),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color:
                                      isLessonCompleted
                                          ? const Color(0xFF4CAF50)
                                          : (isCurrent
                                              ? const Color(0xFF7B4DFF)
                                              : const Color(0xFF2A2D4E)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    lessonItem['emoji'] as String,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              title: Text(
                                lessonItem['title'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      "Lesson ${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      " • ",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                    Text(
                                      lessonItem['duration'] as String,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isLessonCompleted) ...[
                                      const Text(
                                        " • ",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF4CAF50),
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing:
                                  isCurrent
                                      ? const Icon(
                                        Icons.play_circle_fill,
                                        color: Color(0xFF7B4DFF),
                                        size: 32,
                                      )
                                      : const Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.white54,
                                        size: 28,
                                      ),
                            ),
                          );
                        },
                      ),

                      // Fun Facts Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8E8E),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Did You Know?",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson['funFact'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "More Amazing Facts:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(lesson['moreFacts'] as List)
                                .asMap()
                                .entries
                                .map((entry) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1F3E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF7B4DFF,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF7B4DFF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "${entry.key + 1}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            entry.value as String,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1F3E),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            if (currentLessonIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _changeLesson(currentLessonIndex - 1),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Previous"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (currentLessonIndex > 0 &&
                currentLessonIndex < allLessons.length - 1)
              const SizedBox(width: 12),
            if (currentLessonIndex < allLessons.length - 1)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _changeLesson(currentLessonIndex + 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
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

    // Check if note already exists for this lesson
    int existingIndex = -1;
    for (int i = 0; i < notes.length; i++) {
      if (notes[i]['title']?.contains(title) ?? false) {
        existingIndex = i;
        break;
      }
    }

    final noteData = {
      'id':
          existingIndex >= 0
              ? notes[existingIndex]['id']
              : DateTime.now().millisecondsSinceEpoch.toString(),
      'title': lessonEmoji != null ? '$lessonEmoji $title' : title,
      'content': content,
      'date': _formatDate(DateTime.now()),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (existingIndex >= 0) {
      // Update existing note
      notes[existingIndex] = noteData;
    } else {
      // Add new note
      notes.add(noteData);
    }

    // Save back to preferences
    await prefs.setString('video_notes', jsonEncode(notes));
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
