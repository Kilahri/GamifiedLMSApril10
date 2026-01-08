// watch_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:elearningapp_flutter/quiz_data/video_quiz_screen.dart';
import 'package:elearningapp_flutter/data/video_data.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late TabController _tabController;

  int currentLessonIndex = 0;
  bool _isInitialized = false;
  bool _showControls = true;
  final TextEditingController _notesController = TextEditingController();

  // Track completion and points
  Set<int> completedLessons = {};
  Map<int, int> lessonPoints = {};
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVideo(scienceLessons[currentLessonIndex].videoUrl);
    _loadExistingNote();
  }

  void _loadVideo(String url) {
    if (url.startsWith('lib/assets/videos/')) {
      // Local asset video
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
      // Network video
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
    final lesson = scienceLessons[currentLessonIndex];
    final existingNote = await NotesHelper.getVideoNoteForLesson(lesson.title);

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

    // Show completion dialog
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                VideoQuizScreen(lesson: scienceLessons[currentLessonIndex]),
      ),
    );

    if (result != null && result is int) {
      setState(() {
        totalPoints += result;
        lessonPoints[currentLessonIndex] =
            (lessonPoints[currentLessonIndex] ?? 0) + result;
      });
    }
  }

  void _changeLesson(int newIndex) {
    if (newIndex >= 0 && newIndex < scienceLessons.length) {
      setState(() {
        currentLessonIndex = newIndex;
        _isInitialized = false;
        _videoController.dispose();
        _loadVideo(scienceLessons[currentLessonIndex].videoUrl);
        _loadExistingNote(); // Load notes for new lesson
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
            // Center play/pause button
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
            // Bottom controls
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
                    onPressed: () {
                      // Fullscreen functionality
                    },
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
    final lesson = scienceLessons[currentLessonIndex];
    final totalLessons = scienceLessons.length;
    final progress = completedLessons.length / totalLessons;
    final isCompleted = completedLessons.contains(currentLessonIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
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
              child: SafeArea(
                bottom: false,
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
          ),

          // Content Area
          Expanded(
            child: Column(
              children: [
                // Header with title and points
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
                                  lesson.emoji + " " + lesson.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Lesson ${currentLessonIndex + 1} of $totalLessons • ${lesson.duration}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
                      const SizedBox(height: 12),
                      // Progress bar
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
                              lesson.description,
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
                            ...lesson.keyTopics.map(
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
                                        topic,
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
                        itemCount: scienceLessons.length,
                        itemBuilder: (context, index) {
                          final lessonItem = scienceLessons[index];
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
                                    lessonItem.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              title: Text(
                                lessonItem.title,
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
                                      lessonItem.duration,
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
                                          lesson.funFact,
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
                            ...lesson.moreFacts.asMap().entries.map((entry) {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        entry.value,
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
                currentLessonIndex < scienceLessons.length - 1)
              const SizedBox(width: 12),
            if (currentLessonIndex < scienceLessons.length - 1)
              Expanded(
                flex: currentLessonIndex == 0 ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: () => _changeLesson(currentLessonIndex + 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    "Next Lesson",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4DFF),
                    foregroundColor: Colors.white,
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
