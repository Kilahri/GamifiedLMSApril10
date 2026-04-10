import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/cms/game_cms.dart';
import 'package:elearningapp_flutter/play/quiz_screen.dart';
import 'package:elearningapp_flutter/play/trivia_screen.dart';
import 'package:elearningapp_flutter/play/puzzle_screen.dart';
import 'package:elearningapp_flutter/play/cross_word.dart';
import 'package:elearningapp_flutter/planet_builder/planet_gallery_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayScreen extends StatelessWidget {
  final String role;
  final String username;
  const PlayScreen({super.key, required this.role, required this.username});

  @override
  Widget build(BuildContext context) {
    // PlanetBuilderScreen needs userId from FirebaseAuth
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D102C),
        automaticallyImplyLeading: false,
        title: const Text(
          "PLAY",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (role == "teacher" || role == "parent" || role == "admin")
            IconButton(
              icon: const Icon(Icons.edit, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameCMS(role: role)),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Category Buttons ---
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

            // --- 3. Feature Banner → Planet Builder ---
            _featureBanner(
              context,
              "Planet Builder",
              "lib/assets/spaceExplorer.jpg",
              PlanetGalleryScreen(userId: userId, username: username),
            ),

            // --- 4. Play Games Section Title ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childAspectRatio: 0.85,
              children: [
                _gameCard(
                  context,
                  "Science Quiz",
                  "lib/assets/quiz.jpg",
                  QuizScreenWithAchievements(role: role, username: username),
                  Icons.lightbulb,
                ),
                _gameCard(
                  context,
                  "Element Fusion",
                  "lib/assets/puzzle.jpg",
                  ScienceFusionHome(username: "Student"),
                  Icons.extension,
                ),
                // ✅ Planet Builder replaces Adventure Quest
                _gameCard(
                  context,
                  "Space Explorer",
                  "lib/assets/spaceExplorer.jpg",
                  PlanetGalleryScreen(userId: userId, username: username),
                  Icons.public,
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
                  "Science Crossword",
                  "lib/assets/popularPlay.png",
                  ScienceCrosswordScreen(role: role), // ← new
                  Icons.grid_on,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // --- WIDGET HELPER FUNCTIONS ---
  // --------------------------------------------------------------------------

  Widget _categoryButton(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B5998),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF0A0C22),
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
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey.shade700,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
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
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => screen),
                          ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text("Start Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
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
          color: const Color(0xFF1C1F3E),
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
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: Colors.grey.shade700,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF0D102C),
                        size: 20,
                      ),
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
