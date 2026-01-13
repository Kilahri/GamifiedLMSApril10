import 'package:flutter/material.dart';

// Screen Imports
import 'home_screen.dart';
import 'play_screen.dart';
import 'watch_screen.dart';
import 'package:elearningapp_flutter/screens/lesson_video_selection.dart'; // NEW IMPORT
import 'read_screen.dart';
import 'settings_screen.dart';
import 'teacher_cms_page.dart' show TeacherCMSPage;
import 'teacher_content_management.dart'
    show TeacherContentManagementScreen, TeacherMessagesScreen;
import 'progress_tracking_view.dart';
import 'package:elearningapp_flutter/leaderboard/leaderboard.dart';
import 'package:elearningapp_flutter/screens/teacher/teacher_settings_screen.dart';

// 🎨 Theme Constants
const Color kStudentColor = Color(0xFFFFC107); // Amber
const Color kTeacherColor = Color(0xFF42A5F5); // Blue
const Color kDarkGradientStart = Color(0xFF0D102C);
const Color kDarkGradientEnd = Color(0xFF1E2152);
const double kIconSize = 28.0;

class RoleNavigation extends StatefulWidget {
  final String role;
  final String username;

  const RoleNavigation({super.key, required this.role, required this.username});

  @override
  State<RoleNavigation> createState() => _RoleNavigationState();
}

class _RoleNavigationState extends State<RoleNavigation> {
  int _selectedIndex = 0;

  // Helper to check role case-insensitively
  bool get _isTeacherOrAdmin {
    final r = widget.role.toLowerCase();
    return r == 'teacher' || r == 'admin';
  }

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(role: widget.role, username: widget.username), // 0
      PlayScreen(role: widget.role, username: widget.username), // 1
      const LessonSelectionScreen(), // 2 - CHANGED from WatchScreen to LessonSelectionScreen
      const ReadScreen(), // 3
      UniversalOverallLeaderboardScreen(username: widget.username), // 4
      SettingsScreen(currentUsername: widget.username), // 5
      const TeacherCMSPage(), // 6
      const ProgressTrackingView(), // 7
      const TeacherContentManagementScreen(), // 8
      const TeacherMessagesScreen(), // 9
      TeacherSettingsScreen(currentUsername: widget.username), // 10
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Maps the BottomNavBar index to the correct page in the [_pages] list
  int _getPageMapIndex(int index) {
    if (_isTeacherOrAdmin) {
      switch (index) {
        case 0:
          return 8; // Content -> TeacherContentManagementScreen
        case 1:
          return 9; // Messages -> TeacherMessagesScreen
        case 2:
          return 10; // Profile -> TeacherSettingsScreen
        default:
          return 8;
      }
    } else {
      return index; // Students follow 0-5 mapping directly
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_isTeacherOrAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories, size: kIconSize),
          label: "Content",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_rounded, size: kIconSize),
          label: "Messages",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: kIconSize),
          label: "Settings",
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded, size: kIconSize),
          label: "My Zone",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_esports, size: kIconSize),
          label: "Play",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_fill, size: kIconSize),
          label: "Watch",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_rounded, size: kIconSize),
          label: "Read",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events, size: kIconSize),
          label: "Rankings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: kIconSize),
          label: "Settings",
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = _isTeacherOrAdmin ? kTeacherColor : kStudentColor;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDarkGradientStart, kDarkGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Use an IndexedStack to keep page states alive when switching tabs
        child: IndexedStack(
          index: _getPageMapIndex(_selectedIndex),
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: themeColor.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: kDarkGradientEnd,
          selectedItemColor: themeColor,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: _getNavItems(),
        ),
      ),
    );
  }
}
