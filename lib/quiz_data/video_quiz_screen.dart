// video_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/data/video_data.dart';

class VideoQuizScreen extends StatefulWidget {
  final ScienceLesson lesson;

  const VideoQuizScreen({super.key, required this.lesson});

  @override
  State<VideoQuizScreen> createState() => _VideoQuizScreenState();
}

class _VideoQuizScreenState extends State<VideoQuizScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool showExplanation = false;
  int correctAnswers = 0;
  bool quizCompleted = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void checkAnswer() {
    setState(() {
      showExplanation = true;
      if (selectedAnswer ==
          widget.lesson.quizQuestions[currentQuestionIndex].correctAnswer) {
        correctAnswers++;
        _animationController.forward().then(
          (_) => _animationController.reverse(),
        );
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < widget.lesson.quizQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showExplanation = false;
      });
    } else {
      setState(() {
        quizCompleted = true;
      });
    }
  }

  void restartQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswer = null;
      showExplanation = false;
      correctAnswers = 0;
      quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (quizCompleted) {
      return _buildResultsScreen();
    }

    final question = widget.lesson.quizQuestions[currentQuestionIndex];
    final progress =
        (currentQuestionIndex + 1) / widget.lesson.quizQuestions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Quiz Time! 🎯",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "${currentQuestionIndex + 1}/${widget.lesson.quizQuestions.length}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7B4DFF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${currentQuestionIndex + 1} of ${widget.lesson.quizQuestions.length}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Score: $correctAnswers/${currentQuestionIndex + (showExplanation ? 1 : 0)}",
                      style: const TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question emoji and text
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B4DFF), Color(0xFF9E7CFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B4DFF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          question.emoji,
                          style: const TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Answer Options
                  ...List.generate(question.options.length, (index) {
                    final isSelected = selectedAnswer == index;
                    final isCorrect = index == question.correctAnswer;
                    Color buttonColor = const Color(0xFF1C1F3E);
                    Color borderColor = Colors.transparent;

                    if (showExplanation) {
                      if (isCorrect) {
                        buttonColor = const Color(0xFF4CAF50);
                        borderColor = const Color(0xFF66BB6A);
                      } else if (isSelected && !isCorrect) {
                        buttonColor = const Color(0xFFF44336);
                        borderColor = const Color(0xFFE57373);
                      }
                    } else if (isSelected) {
                      buttonColor = const Color(0xFF7B4DFF);
                      borderColor = const Color(0xFF9E7CFF);
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              showExplanation
                                  ? null
                                  : () {
                                    setState(() {
                                      selectedAnswer = index;
                                    });
                                  },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow:
                                  isSelected && !showExplanation
                                      ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7B4DFF,
                                          ).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (showExplanation && isCorrect)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 28,
                                  )
                                else if (showExplanation &&
                                    isSelected &&
                                    !isCorrect)
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Check Answer Button
                  if (!showExplanation && selectedAnswer != null)
                    AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Check Answer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Explanation
                  if (showExplanation) ...[
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              selectedAnswer == question.correctAnswer
                                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                                  : const Color(0xFFF44336).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selectedAnswer == question.correctAnswer
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFF44336),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selectedAnswer == question.correctAnswer
                                      ? Icons.celebration
                                      : Icons.info_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedAnswer == question.correctAnswer
                                        ? "🎉 Awesome! You got it right!"
                                        : "💡 Not quite, but you're learning!",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              question.explanation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: nextQuestion,
                      icon: Icon(
                        currentQuestionIndex <
                                widget.lesson.quizQuestions.length - 1
                            ? Icons.arrow_forward
                            : Icons.emoji_events,
                      ),
                      label: Text(
                        currentQuestionIndex <
                                widget.lesson.quizQuestions.length - 1
                            ? "Next Question"
                            : "See Results",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = widget.lesson.quizQuestions.length;
    final percentage = (correctAnswers / totalQuestions * 100).round();
    final earnedPoints = (percentage / 100 * 30).round();

    String emoji;
    String message;
    Color color;

    if (percentage >= 80) {
      emoji = "🌟";
      message = "Outstanding! You're a science superstar!";
      color = const Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      emoji = "👍";
      message = "Great job! You're learning so much!";
      color = const Color(0xFF7B4DFF);
    } else {
      emoji = "💪";
      message = "Keep practicing! You'll get better!";
      color = const Color(0xFFFFC107);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 100)),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Your Score",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$correctAnswers / $totalQuestions",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$percentage%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFC107),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+$earnedPoints Points Earned!",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: restartQuiz,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  "Try Again",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B4DFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, earnedPoints),
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  "Back to Lesson",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54, width: 2),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
