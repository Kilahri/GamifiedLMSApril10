import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/cms/game_cms.dart';
import 'package:elearningapp_flutter/play/quiz_screen.dart';
import 'package:elearningapp_flutter/play/trivia_screen.dart';
import 'package:elearningapp_flutter/play/adventure_screen.dart';
import 'package:elearningapp_flutter/play/puzzle_screen.dart';
// ✅ Import with aliases to avoid conflicts
import 'package:elearningapp_flutter/play/Word_Connect.dart' as wordconnect;

class PlayScreen extends StatelessWidget {
  final String role;
  final String username;
  const PlayScreen({super.key, required this.role, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎨 Use a slightly lighter primary color for better contrast with cards
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        // ⭐ REMOVED BACK BUTTON: Set automaticallyImplyLeading to false
        automaticallyImplyLeading: false,
        title: const Text(
          "PLAY",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ), // Bigger title
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (role == "teacher" || role == "parent" || role == "admin")
            IconButton(
              icon: const Icon(Icons.edit, size: 28), // Slightly bigger icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameCMS(role: role)),
                );
              },
            ),
          const SizedBox(width: 8), // Add a little spacing
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Category Buttons (Horizontal Scroll) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryButton(Icons.local_fire_department, "Trending"),
                    _categoryButton(Icons.star, "Popular"),
                    _categoryButton(Icons.sports_esports, "New"),
                  ],
                ),
              ),
            ),

            // --- 2. Feature Section Title ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "🔥 Daily Feature",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // --- 3. Feature Banner (Enhanced with Overlay) ---
            _featureBanner(
              context,
              "Space Explorer Adventure",
              "lib/assets/spaceExplorer.jpg",
              AdventureScreen(role: role),
            ),

            // --- 4. Play Games Section Title ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ), // Increased vertical padding
              child: Text(
                "🎮 Play Games",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // --- 5. Game Cards Grid ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ), // Added vertical padding
              childAspectRatio:
                  0.85, // Adjust aspect ratio for better card shape
              children: [
                _gameCard(
                  context,
                  "Daily Quiz",
                  "lib/assets/quiz.jpg",
                  QuizScreenWithAchievements(
                    role: role,
                    username: username, // ✅ Add this
                  ),
                  Icons.lightbulb,
                ),
                _gameCard(
                  context,
                  "Jigsaw Puzzle",
                  "lib/assets/puzzle.jpg",
                  ScienceFusionHome(username: "Student"),
                  Icons.extension,
                ),
                _gameCard(
                  context,
                  "Adventure Quest",
                  "lib/assets/spaceExplorer.jpg",
                  AdventureScreen(role: role),
                  Icons.rocket_launch,
                ),
                _gameCard(
                  context,
                  "Matching Game",
                  "lib/assets/popularRead.png",
                  TriviaScreen(role: role),
                  Icons.compare_arrows,
                ),
                _gameCard(
                  context,
                  "Word Connect",
                  "lib/assets/popularPlay.png",
                  wordconnect.WordConnectScreen(role: role),
                  Icons.sort_by_alpha,
                ),

                // Added a dummy card for demonstration
              ],
            ),
            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // --- WIDGET HELPER FUNCTIONS ---
  // --------------------------------------------------------------------------

  /// Styled Category Button
  Widget _categoryButton(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          // 🎨 More vibrant button color
          backgroundColor: const Color(0xFF3B5998),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // More rounded
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          elevation: 0,
        ),
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Enhanced Feature Banner with Overlay Text
  Widget _featureBanner(
    BuildContext context,
    String title,
    String imagePath,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180, // Slightly taller banner
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0C22), // Darker, more cohesive shadow
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade700,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Dark Gradient Overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Text and Button Overlay
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text("Start Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFFCC00,
                        ), // Accent color
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
  }

  /// Game Card with a more modern, minimal design and icon
  Widget _gameCard(
    BuildContext context,
    String title,
    String imagePath,
    Widget screen,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(
            0xFF1C1F3E,
          ), // Solid background color for structure
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade700,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Text and Icon Section
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFCC00,
                        ), // Accent icon background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Color(0xFF0D102C), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
