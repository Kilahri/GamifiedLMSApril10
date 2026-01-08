import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'play_screen.dart';
import 'watch_screen.dart';
import 'read_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;
  final String username;

  const HomeScreen({super.key, required this.role, required this.username});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D102C), Color(0xFF1E2152)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with App Name and Settings
                _buildHeader(context),

                const SizedBox(height: 12),

                // Hero Banner
                _buildHeroBanner(),

                const SizedBox(height: 30),

                // Activities Section
                _sectionTitle("Activities", "View all"),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _activityCard(
                        title: "PLAY",
                        subtitle: "Games & Quizzes",
                        color: Colors.deepPurple,
                        imagePath: "lib/assets/play.png",
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (ctx) => PlayScreen(
                                      role: role,
                                      username: username,
                                    ),
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      _activityCard(
                        title: "WATCH",
                        subtitle: "Science Videos",
                        color: Colors.teal,
                        imagePath: "lib/assets/video.png",
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const WatchScreen(),
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      _activityCard(
                        title: "READ",
                        subtitle: "Articles & Books",
                        color: Colors.orange,
                        imagePath: "lib/assets/popularRead.png",
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const ReadScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Popular Section
                _sectionTitle("Popular", "View all"),
                const SizedBox(height: 16),

                _popularItem(
                  title: "Puzzle, Matching Game, Quizzes and more",
                  tag: "GAMES",
                  color: Colors.deepPurple,
                  imagePath: "lib/assets/popularPlay.png",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (ctx) =>
                                  PlayScreen(role: role, username: username),
                        ),
                      ),
                ),
                _popularItem(
                  title: "Science Videos - Earth, Space and Life",
                  tag: "VIDEOS",
                  color: Colors.teal,
                  imagePath: "lib/assets/video.png",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const WatchScreen(),
                        ),
                      ),
                ),
                _popularItem(
                  title: "Science Books & Articles",
                  tag: "READ",
                  color: Colors.orange,
                  imagePath: "lib/assets/popularRead.png",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const ReadScreen()),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.science, color: Color(0xFFFFC107), size: 28),
                SizedBox(width: 6),
                Text(
                  "SciLearn",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsScreen(
                          currentUsername: username, // ✅ FIX: Pass the username
                        ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Welcome $role 👋",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4DFF), Color(0xFF5B36C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Explore Science",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Play • Watch • Read\nLearn and enjoy everyday!",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Removed Icons.school error placeholder
          Image.asset(
            "lib/assets/owl.png",
            height: 100,
            width: 100,
            errorBuilder:
                (context, error, stackTrace) =>
                    const SizedBox.shrink(), // Displays nothing if image fails
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String viewAllText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            viewAllText,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _activityCard({
    required String title,
    required String subtitle,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Image.asset(
                  imagePath,
                  height: 40,
                  width: 40,
                  errorBuilder:
                      (ctx, err, stack) =>
                          const Icon(Icons.broken_image, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _popularItem({
    required String title,
    required String tag,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1C1F3E),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                color: Colors.white10,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (ctx, err, stack) =>
                          const Icon(Icons.image, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
