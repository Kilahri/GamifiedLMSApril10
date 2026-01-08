import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- Enhanced Book Data Model with Full Content ---
class Book {
  final String title;
  final String image;
  final String summary;
  final String theme;
  final List<BookChapter> chapters;
  final String author;
  final int readTime;
  final String funFact;

  Book({
    required this.title,
    required this.image,
    required this.summary,
    required this.theme,
    required this.chapters,
    required this.author,
    required this.readTime,
    required this.funFact,
  });
}

class BookChapter {
  final String title;
  final String content;
  final List<String> keyPoints;
  final String didYouKnow;
  final List<QuizQuestion> quizQuestions;

  BookChapter({
    required this.title,
    required this.content,
    required this.keyPoints,
    required this.didYouKnow,
    required this.quizQuestions,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

// --- Sample Book Data ---
final List<Book> scienceBooks = [
  Book(
    title: "Amazing Changes of Matter! 🔬",
    image: "lib/assets/statesofmatter.jpg",
    summary:
        "Discover the super cool properties of matter and how it magically changes between solid, liquid, and gas states!",
    theme: "Chemistry",
    author: "Prof. Alex Chen",
    readTime: 15,
    funFact:
        "Did you know? Water is the only substance on Earth that naturally exists in all three states at the same time!",
    chapters: [
      BookChapter(
        title: "🧊 Three States of Matter",
        content:
            """Imagine everything around you - your desk, the air you breathe, even the water you drink - they're all made of something called MATTER! Matter is like the building blocks of everything in the universe.

Matter comes in three main forms, kind of like ice cream comes in different flavors:

Solids are Super Strong! 💪
Solids keep their shape no matter what! Think about a rock, a book, or an ice cube. The tiny particles (we call them atoms and molecules) inside solids are packed together really tight, like students standing in a crowded hallway. They can only wiggle a tiny bit in place. That's why you can pick up a solid and it doesn't flow through your fingers!

Liquids Love to Flow! 💧
Liquids are the relaxed cousins of solids. They have a set volume (amount), but they'll take the shape of any container you put them in. Pour water into a cup - it becomes cup-shaped! Pour it into a bowl - now it's bowl-shaped! The particles in liquids are still close together, but they can slide past each other like people dancing at a party.

Gases are Free Spirits! 💨
Gases are the ultimate free spirits - they spread out to fill up any space they're in! The air around you is full of gases, but you can't see most of them. Gas particles zoom around super fast with lots of space between them, like kids running around in a huge playground.

The coolest part? The difference between these three states is all about how much energy the particles have and how close together they are!""",
        keyPoints: [
          "Solid = Particles packed tight, keeps its shape",
          "Liquid = Particles slide past each other, flows freely",
          "Gas = Particles spread far apart, fills any space",
          "It's all about particle arrangement and energy!",
        ],
        didYouKnow:
            "🌟 Fun Fact: Your pencil is a solid, but the graphite inside is made of the same element (carbon) as diamonds! The only difference is how the atoms are arranged.",
        quizQuestions: [
          QuizQuestion(
            question: "What happens to particles in a solid?",
            options: [
              "They fly around freely",
              "They vibrate in place",
              "They disappear",
              "They turn into liquid",
            ],
            correctAnswer: 1,
            explanation:
                "Great job! Solid particles are packed tightly and can only vibrate in their fixed positions.",
          ),
          QuizQuestion(
            question: "Which state of matter takes the shape of its container?",
            options: ["Solid", "Liquid", "Gas", "Both liquid and gas"],
            correctAnswer: 3,
            explanation:
                "Awesome! Both liquids and gases take the shape of their container - liquids flow to fit, and gases expand to fill the entire space!",
          ),
        ],
      ),
    ],
  ),
  Book(
    title: "Earth Day Every Day 🌍",
    image: "lib/assets/earthScience.png",
    summary:
        "Explore our amazing planet Earth from the inside out! Learn about its layers, rotation, seasons, and our place in the universe!",
    theme: "Earth Science",
    author: "Dr. Maria Stone",
    readTime: 20,
    funFact:
        "Earth is the only planet not named after a god - its name comes from the Old English word 'ertha' meaning ground!",
    chapters: [
      BookChapter(
        title: "🌍 Earth's Amazing Layers",
        content:
            """Imagine Earth is like a giant jawbreaker candy - it has different layers! Let's dig deep and discover what's under our feet.

The Crust: Where We Live! 🏠
The crust is Earth's outer shell - the ground you walk on! It's like the skin of an apple, super thin compared to the rest of Earth. Under the oceans, it's only about 5 kilometers thick, but under continents it can be up to 70 kilometers thick. All life on Earth lives on this thin rocky crust!

The Mantle: Earth's Gooey Middle! 🌋
Below the crust is the mantle - the thickest layer of Earth! It's made of hot, dense rock that's so hot it flows veeeery slowly, like super thick honey or lava lamp fluid. The mantle is about 2,900 kilometers thick! Even though it flows, it's not liquid - it's more like silly putty that moves over millions of years.

The mantle's movement is super important because it causes the crust above to shift and move, creating mountains, earthquakes, and volcanoes!""",
        keyPoints: [
          "Crust: Thin outer layer where we live (5-70 km)",
          "Mantle: Thickest layer, hot flowing rock (2,900 km)",
          "Outer Core: Liquid metal, creates magnetic field",
          "Inner Core: Solid metal ball at the center, super hot!",
        ],
        didYouKnow:
            "🌟 Fun Fact: If Earth were shrunk to the size of an apple, the crust would be thinner than the apple's skin! We literally live on a paper-thin shell!",
        quizQuestions: [
          QuizQuestion(
            question: "Which layer of Earth do we live on?",
            options: ["Mantle", "Crust", "Outer Core", "Inner Core"],
            correctAnswer: 1,
            explanation:
                "Correct! We live on the crust, the thin outer layer of Earth.",
          ),
        ],
      ),
    ],
  ),
];

final List<Book> spaceBooks = [
  Book(
    title: "Plant Power! 🌱",
    image: "lib/assets/plantScience.jpg",
    summary:
        "Discover the amazing world of plants! Learn how they grow, make their own food, and reproduce in super cool ways!",
    theme: "Biology",
    author: "Dr. Green Leaf",
    readTime: 22,
    funFact:
        "The largest living organism on Earth is a fungus in Oregon that covers 2,385 acres - that's bigger than 1,600 football fields!",
    chapters: [
      BookChapter(
        title: "🌿 Plant Parts: A Team That Works Together!",
        content:
            """Plants are like amazing living machines! Each part has its own special job, and they all work together to keep the plant alive and healthy. Let's meet the team!

Roots: The Underground Heroes! 🦸‍♂️
Roots live underground where you can't see them, but they're super important! They have two main jobs:

Job 1 - Anchor the Plant: Roots spread out underground like an anchor, holding the plant firmly in the soil so wind and rain can't knock it over. Strong roots = strong plant!

Job 2 - Drink Up!: Roots are like straws that suck up water and minerals from the soil. They have tiny root hairs (like little fingers) that increase the surface area and help them absorb even more!

Some plants, like carrots and sweet potatoes, also use their roots as storage containers for food!""",
        keyPoints: [
          "Roots: anchor plant + absorb water and minerals",
          "Stem: supports plant + transports water and food",
          "Leaves: make food through photosynthesis",
          "Flowers: reproductive parts that make seeds",
          "Seeds: contain baby plant + stored food",
        ],
        didYouKnow:
            "🌟 Fun Fact: The world's tallest trees (California Redwoods) can grow over 100 meters tall - that's as tall as a 30-story building! Yet they all started from tiny seeds!",
        quizQuestions: [
          QuizQuestion(
            question: "What is the main job of roots?",
            options: [
              "Make food",
              "Anchor plant and absorb water",
              "Make seeds",
              "Catch sunlight",
            ],
            correctAnswer: 1,
            explanation:
                "Correct! Roots anchor the plant in soil and absorb water and minerals that the plant needs!",
          ),
        ],
      ),
    ],
  ),
];

final featuredBook = scienceBooks[0];

// Reading progress tracking
Map<String, Set<int>> readingProgress = {};
Map<String, int> bookPoints = {};

// ------------------------------------------------------------------

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  String searchQuery = "";
  String selectedCategory = "All";
  List<Book> teacherBooks = []; // NEW: Store teacher-created books
  bool _isLoading = true; // NEW: Loading state

  @override
  void initState() {
    super.initState();
    _loadTeacherBooks(); // NEW: Load teacher books on init
  }

  // NEW: Load books created by teachers
  Future<void> _loadTeacherBooks() async {
    final prefs = await SharedPreferences.getInstance();
    String? booksJson = prefs.getString('teacher_books');

    if (booksJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(booksJson);
        setState(() {
          teacherBooks =
              decoded.map((bookMap) {
                // Convert the map back to Book object
                return Book(
                  title: bookMap['title'] ?? '',
                  image: bookMap['image'] ?? 'lib/assets/book_default.png',
                  summary: bookMap['summary'] ?? '',
                  theme: bookMap['theme'] ?? 'General',
                  author: bookMap['author'] ?? 'Unknown',
                  readTime: bookMap['readTime'] ?? 15,
                  funFact: bookMap['funFact'] ?? '',
                  chapters:
                      (bookMap['chapters'] as List?)?.map((chapterMap) {
                        return BookChapter(
                          title: chapterMap['title'] ?? '',
                          content: chapterMap['content'] ?? '',
                          keyPoints: List<String>.from(
                            chapterMap['keyPoints'] ?? [],
                          ),
                          didYouKnow: chapterMap['didYouKnow'] ?? '',
                          quizQuestions:
                              (chapterMap['quizQuestions'] as List?)?.map((q) {
                                return QuizQuestion(
                                  question: q['question'] ?? '',
                                  options: List<String>.from(
                                    q['options'] ?? [],
                                  ),
                                  correctAnswer: q['correctAnswer'] ?? 0,
                                  explanation: q['explanation'] ?? '',
                                );
                              }).toList() ??
                              [],
                        );
                      }).toList() ??
                      [],
                );
              }).toList();
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading teacher books: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int getTotalPoints() {
    return bookPoints.values.fold(0, (sum, points) => sum + points);
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Combine hardcoded books with teacher books
    List<Book> allBooks = [...scienceBooks, ...spaceBooks, ...teacherBooks];

    List<Book> filteredBooks =
        allBooks.where((book) {
          bool matchesSearch =
              book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              book.theme.toLowerCase().contains(searchQuery.toLowerCase());
          bool matchesCategory =
              selectedCategory == "All" || book.theme == selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

    // Get all unique themes for filter chips (including teacher book themes)
    Set<String> allThemes = {
      "All",
      ...allBooks.map((book) => book.theme).toSet(),
    };

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        automaticallyImplyLeading: false,
        title: const Text(
          "📚 READ & LEARN",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          // Points badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${getTotalPoints()} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // NEW: Refresh button to reload teacher books
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadTeacherBooks();
            },
            tooltip: 'Refresh books',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search books...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1C1F3E),
              ),
            ),
          ),

          // Category Filters - UPDATED to show all themes dynamically
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  allThemes
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (selected) {
                              setState(() => selectedCategory = category);
                            },
                            selectedColor: const Color(0xFF7B4DFF),
                            backgroundColor: const Color(0xFF1C1F3E),
                            labelStyle: TextStyle(
                              color:
                                  selectedCategory == category
                                      ? Colors.white
                                      : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Featured Book
          if (searchQuery.isEmpty && allBooks.isNotEmpty)
            _featuredBookBanner(context, allBooks.first),

          // Fun Fact Card
          if (searchQuery.isEmpty && allBooks.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      allBooks.first.funFact,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // NEW: Show count of teacher books if any
          if (teacherBooks.isNotEmpty && searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${teacherBooks.length} book${teacherBooks.length == 1 ? '' : 's'} created by teachers',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Books Grid
          if (filteredBooks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  "No books found",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            )
          else
            _bookGrid(context, filteredBooks),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _featuredBookBanner(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => BookReaderScreen(book: book)),
        );
        if (result == true) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B4DFF), Color(0xFF9E7CFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                book.image,
                height: 120,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 120,
                      width: 80,
                      color: const Color(0xFF9E7CFF),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "⭐ Featured Read",
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${book.readTime} min read",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _bookGrid(BuildContext context, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.70,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _bookCard(context, book);
        },
      ),
    );
  }

  Widget _bookCard(BuildContext context, Book book) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => BookReaderScreen(book: book)),
        );
        if (result == true) setState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F3E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                book.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 160,
                      color: Colors.grey.shade700,
                      child: const Center(
                        child: Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.theme,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getThemeColor(book.theme),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white54,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${book.readTime} min",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
}

// ------------------------------------------------------------------
// --- Interactive Book Reader Screen ---
// ------------------------------------------------------------------

class BookReaderScreen extends StatefulWidget {
  final Book book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  int currentChapterIndex = 0;
  double fontSize = 16.0;
  bool showKeyPoints = false;
  int currentQuizIndex = 0;
  int? selectedAnswer;
  bool showExplanation = false;

  @override
  void initState() {
    super.initState();
    // Initialize reading progress for this book
    if (!readingProgress.containsKey(widget.book.title)) {
      readingProgress[widget.book.title] = {};
    }
    if (!bookPoints.containsKey(widget.book.title)) {
      bookPoints[widget.book.title] = 0;
    }
  }

  void markChapterAsRead() {
    setState(() {
      if (!readingProgress[widget.book.title]!.contains(currentChapterIndex)) {
        readingProgress[widget.book.title]!.add(currentChapterIndex);
        bookPoints[widget.book.title] = bookPoints[widget.book.title]! + 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if book has chapters
    if (widget.book.chapters.isEmpty) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, true);
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0D102C),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D102C),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.book.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Chapters Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This book doesn\'t have any chapters yet.\nPlease add chapters to the book.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final chapter = widget.book.chapters[currentChapterIndex];
    final progress =
        widget.book.chapters.length > 0
            ? (currentChapterIndex + 1) / widget.book.chapters.length
            : 0.0;
    final isChapterRead =
        readingProgress[widget.book.title]?.contains(currentChapterIndex) ??
        false;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D102C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D102C),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.book.title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => _showFontSizeDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1C1F3E),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7B4DFF),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chapter completion badge
                    if (isChapterRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(height: 10),

                    // Chapter Info
                    Text(
                      "Chapter ${currentChapterIndex + 1} of ${widget.book.chapters.length}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content
                    Text(
                      chapter.content,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.7,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Did You Know Card
                    if (chapter.didYouKnow.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.emoji_objects,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                chapter.didYouKnow,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Key Points Section
                    if (chapter.keyPoints.isNotEmpty)
                      ExpansionTile(
                        title: const Text(
                          "🔑 Key Points",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white54,
                        children:
                            chapter.keyPoints.map((point) {
                              return ListTile(
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF7B4DFF),
                                  size: 20,
                                ),
                                title: Text(
                                  point,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Quiz Section - only if there are quiz questions
                    if (chapter.quizQuestions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1F3E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF7B4DFF),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.quiz,
                                  color: Color(0xFF7B4DFF),
                                  size: 28,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Test Your Knowledge!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildQuizQuestion(
                              chapter.quizQuestions[currentQuizIndex],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1F3E),
                border: Border(top: BorderSide(color: Color(0xFF2A2D4E))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed:
                        currentChapterIndex > 0
                            ? () {
                              setState(() {
                                currentChapterIndex--;
                                currentQuizIndex = 0;
                                selectedAnswer = null;
                                showExplanation = false;
                              });
                            }
                            : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Previous"),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          currentChapterIndex > 0
                              ? Colors.white
                              : Colors.white38,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${currentChapterIndex + 1} / ${widget.book.chapters.length}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isChapterRead)
                        TextButton(
                          onPressed: markChapterAsRead,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            "Mark Complete +10pts",
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed:
                        currentChapterIndex < widget.book.chapters.length - 1
                            ? () {
                              setState(() {
                                currentChapterIndex++;
                                currentQuizIndex = 0;
                                selectedAnswer = null;
                                showExplanation = false;
                              });
                            }
                            : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Next"),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          currentChapterIndex < widget.book.chapters.length - 1
                              ? Colors.white
                              : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Question ${currentQuizIndex + 1}:",
          style: const TextStyle(
            color: Color(0xFF7B4DFF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question.question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.options.length, (index) {
          final isSelected = selectedAnswer == index;
          final isCorrect = index == question.correctAnswer;
          Color buttonColor = const Color(0xFF2A2D4E);

          if (showExplanation) {
            if (isCorrect) {
              buttonColor = const Color(0xFF4CAF50);
            } else if (isSelected && !isCorrect) {
              buttonColor = const Color(0xFFF44336);
            }
          } else if (isSelected) {
            buttonColor = const Color(0xFF7B4DFF);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed:
                  showExplanation
                      ? null
                      : () {
                        setState(() {
                          selectedAnswer = index;
                        });
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (showExplanation && isCorrect)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    )
                  else if (showExplanation && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: Colors.white, size: 20),
                  if (showExplanation) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        if (!showExplanation && selectedAnswer != null)
          ElevatedButton(
            onPressed: () {
              setState(() {
                showExplanation = true;
                if (selectedAnswer == question.correctAnswer) {
                  bookPoints[widget.book.title] =
                      bookPoints[widget.book.title]! + 5;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B4DFF),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Check Answer",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (showExplanation) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  selectedAnswer == question.correctAnswer
                      ? const Color(0xFF4CAF50).withOpacity(0.2)
                      : const Color(0xFFF44336).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    selectedAnswer == question.correctAnswer
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selectedAnswer == question.correctAnswer
                          ? Icons.celebration
                          : Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedAnswer == question.correctAnswer
                          ? "Correct! +5 pts"
                          : "Not quite!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (currentQuizIndex <
              widget.book.chapters[currentChapterIndex].quizQuestions.length -
                  1)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentQuizIndex++;
                  selectedAnswer = null;
                  showExplanation = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B4DFF),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Next Question",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentQuizIndex = 0;
                  selectedAnswer = null;
                  showExplanation = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Retry Quiz",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              "Text Size",
              style: TextStyle(color: Colors.white),
            ),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Sample Text",
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: fontSize,
                      min: 12,
                      max: 24,
                      divisions: 12,
                      activeColor: const Color(0xFF7B4DFF),
                      label: fontSize.round().toString(),
                      onChanged: (value) {
                        setDialogState(() => fontSize = value);
                        setState(() => fontSize = value);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Done",
                  style: TextStyle(color: Color(0xFF7B4DFF)),
                ),
              ),
            ],
          ),
    );
  }
}
