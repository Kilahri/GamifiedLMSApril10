// watch_screen.dart - WITH YOUTUBE SUPPORT
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/quiz_data/video_quiz_screen.dart';
import 'package:elearningapp_flutter/data/video_data.dart';
import 'dart:io';
import 'package:elearningapp_flutter/helpers/video_upload_helper.dart';

class WatchScreen extends StatefulWidget {
  final int initialLessonIndex;

  const WatchScreen({super.key, this.initialLessonIndex = 0});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen>
    with TickerProviderStateMixin {
  // ── Regular video player (for assets / network mp4 / local files) ──
  VideoPlayerController? _videoController;

  // ── YouTube player (for YouTube URLs) ──
  YoutubePlayerController? _youtubeController;

  late TabController _tabController;

  late int currentLessonIndex;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isYouTube = false;
  final TextEditingController _notesController = TextEditingController();

  Set<int> completedLessons = {};
  Map<int, int> lessonPoints = {};
  int totalPoints = 0;

  List<Map<String, dynamic>> allLessons = [];
  bool _isLoadingLessons = true;

  @override
  void initState() {
    super.initState();
    currentLessonIndex = widget.initialLessonIndex;
    _tabController = TabController(length: 4, vsync: this);
    _loadLessonsFromStorage();
  }

  // ─────────────────────────────────────────────
  // Load lessons
  // ─────────────────────────────────────────────
  Future<void> _loadLessonsFromStorage() async {
    setState(() => _isLoadingLessons = true);
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> defaultLessons = [];
    int index = 0;
    for (var lesson in scienceLessons) {
      String videoId = 'default_video_$index';
      defaultLessons.add(_lessonToMap(lesson, isDefault: true, id: videoId));
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
    if (modifiedJson != null) {
      try {
        final modifiedVideos = Map<String, dynamic>.from(
          jsonDecode(modifiedJson),
        );
        for (int i = 0; i < defaultLessons.length; i++) {
          String id = defaultLessons[i]['id'] as String;
          if (modifiedVideos.containsKey(id)) {
            defaultLessons[i] = modifiedVideos[id] as Map<String, dynamic>;
            defaultLessons[i]['isDefault'] = true;
            defaultLessons[i]['id'] = id;
          }
        }
      } catch (_) {}
    }

    String? deletedJson = prefs.getString('deleted_default_videos');
    List<String> deletedIds = [];
    if (deletedJson != null) {
      try {
        deletedIds = List<String>.from(jsonDecode(deletedJson));
      } catch (_) {}
    }

    defaultLessons =
        defaultLessons
            .where((video) => !deletedIds.contains(video['id']))
            .toList();

    setState(() {
      allLessons = [...defaultLessons, ...teacherVideos];
      _isLoadingLessons = false;
    });

    if (allLessons.isNotEmpty) {
      _loadVideo(allLessons[currentLessonIndex]['videoUrl'] as String);
      _loadExistingNote();
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

  // ─────────────────────────────────────────────
  // Load / switch video
  // ─────────────────────────────────────────────
  void _loadVideo(String url) {
    _disposeAllControllers();

    final sourceType = VideoUploadHelper.getVideoSourceType(url);

    setState(() {
      _isInitialized = false;
      _isYouTube = sourceType == VideoSourceType.youtube;
    });

    if (_isYouTube) {
      _initYouTubePlayer(url);
    } else {
      _initRegularPlayer(url, sourceType);
    }
  }

  void _disposeAllControllers() {
    _videoController?.dispose();
    _videoController = null;
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  // ── YouTube ──
  void _initYouTubePlayer(String url) {
    final videoId = VideoUploadHelper.extractYoutubeId(url);
    if (videoId == null) {
      _showVideoErrorDialog('Could not extract YouTube video ID from the URL.');
      return;
    }

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        forceHD: false,
      ),
    )..addListener(_youtubeListener);

    setState(() => _isInitialized = true);
  }

  void _youtubeListener() {
    if (!mounted) return;
    final ctrl = _youtubeController;
    if (ctrl == null) return;

    // Mark complete when 90% watched
    if (ctrl.value.isReady &&
        ctrl.metadata.duration.inSeconds > 0 &&
        ctrl.value.position.inSeconds >
            ctrl.metadata.duration.inSeconds * 0.9 &&
        !completedLessons.contains(currentLessonIndex)) {
      _markLessonComplete();
    }
    setState(() {});
  }

  // ── Regular (asset / network / file) ──
  void _initRegularPlayer(String url, VideoSourceType sourceType) {
    VideoPlayerController ctrl;

    switch (sourceType) {
      case VideoSourceType.asset:
        ctrl = VideoPlayerController.asset(url);
        break;
      case VideoSourceType.network:
        ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
        break;
      case VideoSourceType.file:
        final file = File(url);
        if (!file.existsSync()) {
          _showVideoErrorDialog('Video file not found on device.');
          return;
        }
        ctrl = VideoPlayerController.file(file);
        break;
      default:
        _showVideoErrorDialog('Unsupported video source.');
        return;
    }

    _videoController = ctrl;

    ctrl
        .initialize()
        .then((_) {
          if (mounted) setState(() => _isInitialized = true);
        })
        .catchError((error) {
          print('Video init error: $error');
          if (mounted) {
            _showVideoErrorDialog(
              'Failed to load video. Please check the URL or file.',
            );
          }
        });

    ctrl.addListener(_regularVideoListener);
  }

  void _regularVideoListener() {
    if (!mounted) return;
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (ctrl.value.position.inSeconds > ctrl.value.duration.inSeconds * 0.9 &&
        !completedLessons.contains(currentLessonIndex)) {
      _markLessonComplete();
    }
    setState(() {});
  }

  void _showVideoErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Video Error', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF7B4DFF)),
                ),
              ),
            ],
          ),
    );
  }

  // ─────────────────────────────────────────────
  // Lesson completion
  // ─────────────────────────────────────────────
  void _markLessonComplete() {
    if (completedLessons.contains(currentLessonIndex)) return;
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

  // ─────────────────────────────────────────────
  // Quiz
  // ─────────────────────────────────────────────
  void _navigateToQuiz() async {
    if (allLessons.isEmpty) return;
    final lessonMap = allLessons[currentLessonIndex];
    final lesson = _mapToLesson(lessonMap);

    // Guard: no quiz questions for this lesson
    if (lesson.quizQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No quiz available for this lesson yet.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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

  ScienceLesson _mapToLesson(Map<String, dynamic> map) {
    // Safely parse quizQuestions — teacher videos may have none
    List<QuizQuestion> parsedQuestions = [];
    try {
      final rawQuestions = map['quizQuestions'];
      if (rawQuestions != null &&
          rawQuestions is List &&
          rawQuestions.isNotEmpty) {
        parsedQuestions =
            rawQuestions.map((q) {
              final qMap = q as Map<String, dynamic>;
              return QuizQuestion(
                question: (qMap['question'] ?? '') as String,
                options: List<String>.from(qMap['options'] ?? []),
                correctAnswer: (qMap['correctAnswer'] ?? 0) as int,
                explanation: (qMap['explanation'] ?? '') as String,
                emoji: (qMap['emoji'] ?? '❓') as String,
              );
            }).toList();
      }
    } catch (e) {
      print('Error parsing quiz questions: $e');
      parsedQuestions = [];
    }

    return ScienceLesson(
      title: (map['title'] ?? 'Untitled') as String,
      emoji: (map['emoji'] ?? '🎥') as String,
      description: (map['description'] ?? '') as String,
      videoUrl: (map['videoUrl'] ?? '') as String,
      duration: (map['duration'] ?? '0 min') as String,
      keyTopics: List<String>.from(map['keyTopics'] ?? []),
      funFact: (map['funFact'] ?? '') as String,
      moreFacts: List<String>.from(map['moreFacts'] ?? []),
      topic: (map['topic'] ?? 'changes_of_matter') as String,
      quizQuestions: parsedQuestions,
    );
  }

  // ─────────────────────────────────────────────
  // Notes
  // ─────────────────────────────────────────────
  Future<void> _loadExistingNote() async {
    if (allLessons.isEmpty) return;
    final lesson = allLessons[currentLessonIndex];
    final existingNote = await NotesHelper.getVideoNoteForLesson(
      lesson['title'] as String,
    );
    setState(() {
      if (existingNote != null) {
        _notesController.text = existingNote;
      } else {
        _notesController.clear();
      }
    });
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

  // ─────────────────────────────────────────────
  // Change lesson
  // ─────────────────────────────────────────────
  void _changeLesson(int newIndex) {
    if (newIndex >= 0 && newIndex < allLessons.length) {
      setState(() {
        currentLessonIndex = newIndex;
        _isInitialized = false;
      });
      _loadVideo(allLessons[newIndex]['videoUrl'] as String);
      _loadExistingNote();
    }
  }

  @override
  void dispose() {
    _disposeAllControllers();
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Video widget
  // ─────────────────────────────────────────────

  /// Builds the correct player widget based on video type
  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7B4DFF)),
                SizedBox(height: 12),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── YouTube Player ──
    if (_isYouTube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF7B4DFF),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF7B4DFF),
          handleColor: Color(0xFF7B4DFF),
          bufferedColor: Colors.white38,
          backgroundColor: Colors.white24,
        ),
        onReady: () {
          setState(() {});
        },
        onEnded: (data) {
          _markLessonComplete();
        },
      );
    }

    // ── Regular Player ──
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(color: Colors.black),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: Stack(
          children: [VideoPlayer(ctrl), _buildRegularControls(ctrl)],
        ),
      ),
    );
  }

  Widget _buildRegularControls(VideoPlayerController ctrl) {
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
            const SizedBox(),
            Center(
              child: IconButton(
                icon: Icon(
                  ctrl.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 80,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    _formatDuration(ctrl.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VideoProgressIndicator(
                      ctrl,
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
                    _formatDuration(ctrl.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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

    // Wrap in YoutubePlayerBuilder so the YouTube player works correctly
    // when the screen rotates or is in full-screen mode.
    Widget body = _buildBody(lesson, totalLessons, progress, isCompleted);

    if (_isYouTube && _youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF7B4DFF),
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFF7B4DFF),
            handleColor: Color(0xFF7B4DFF),
            bufferedColor: Colors.white38,
            backgroundColor: Colors.white24,
          ),
          onEnded: (data) => _markLessonComplete(),
        ),
        builder:
            (context, player) => _buildScaffold(
              lesson,
              totalLessons,
              progress,
              isCompleted,
              playerWidget: player,
            ),
      );
    }

    return _buildScaffold(
      lesson,
      totalLessons,
      progress,
      isCompleted,
      playerWidget: Container(color: Colors.black, child: _buildVideoPlayer()),
    );
  }

  Widget _buildBody(
    Map<String, dynamic> lesson,
    int totalLessons,
    double progress,
    bool isCompleted,
  ) {
    return const SizedBox.shrink(); // placeholder — not used directly
  }

  Scaffold _buildScaffold(
    Map<String, dynamic> lesson,
    int totalLessons,
    double progress,
    bool isCompleted, {
    required Widget playerWidget,
  }) {
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
          // ── Video area ──
          playerWidget,

          // ── Content ──
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

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // About
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

                      // Notes
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
                                      "• What did you find most interesting?\n• What questions do you have?",
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

                      // Lessons list
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
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    "Lesson ${index + 1} • ${lessonItem['duration']}",
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

                      // Fun Facts
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

// ─────────────────────────────────────────────────────────────────────────────
// NOTES HELPER
// ─────────────────────────────────────────────────────────────────────────────
class NotesHelper {
  static Future<void> saveVideoNote({
    required String title,
    required String content,
    String? lessonEmoji,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? notesJson = prefs.getString('video_notes');
    List<Map<String, dynamic>> notes = [];
    if (notesJson != null) {
      try {
        notes = List<Map<String, dynamic>>.from(jsonDecode(notesJson));
      } catch (_) {}
    }

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
      notes[existingIndex] = noteData;
    } else {
      notes.add(noteData);
    }

    await prefs.setString('video_notes', jsonEncode(notes));
  }

  static Future<String?> getVideoNoteForLesson(String lessonTitle) async {
    final prefs = await SharedPreferences.getInstance();
    String? notesJson = prefs.getString('video_notes');
    if (notesJson != null) {
      final notes = List<Map<String, dynamic>>.from(jsonDecode(notesJson));
      for (var note in notes) {
        if (note['title']?.contains(lessonTitle) ?? false) {
          return note['content'];
        }
      }
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    const months = [
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
