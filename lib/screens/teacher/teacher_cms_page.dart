import 'package:flutter/material.dart';
import 'manage_books_screen.dart';
// Import your other screens here once they are created:
// import 'manage_videos_screen.dart';
// import 'manage_assignments_screen.dart';

class TeacherCMSPage extends StatefulWidget {
  const TeacherCMSPage({super.key});

  @override
  State<TeacherCMSPage> createState() => _TeacherCMSPageState();
}

class _TeacherCMSPageState extends State<TeacherCMSPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Length is 3 to match Videos, Books, and Assignments
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D102C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.terminal_rounded, color: Color(0xFF42A5F5), size: 28),
            SizedBox(width: 12),
            Text(
              "CMS Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF42A5F5),
          indicatorWeight: 3,
          labelColor: const Color(0xFF42A5F5),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: "Videos"),
            Tab(icon: Icon(Icons.menu_book), text: "Books"),
            Tab(icon: Icon(Icons.assignment), text: "Tasks"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Videos Placeholder
          _buildPlaceholderView(
            Icons.video_collection,
            "Video Management coming soon",
          ),

          // Tab 2: Actual Books Screen
          const ManageBooksScreen(),

          // Tab 3: Assignments Placeholder
          _buildPlaceholderView(
            Icons.task_alt,
            "Assignment Management coming soon",
          ),
        ],
      ),
    );
  }

  /// Helper widget to show while your other screens are under construction
  Widget _buildPlaceholderView(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
