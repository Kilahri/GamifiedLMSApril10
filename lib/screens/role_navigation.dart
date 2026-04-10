import 'package:flutter/material.dart';

// ... your existing imports ...
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
import 'package:elearningapp_flutter/leaderboard/combined_leaderboard_screen.dart';

const Color kStudentColor = Color(0xFFFFC107);
const Color kTeacherColor = Color(0xFF42A5F5);
const Color kDarkGradientStart = Color(0xFF0D102C);
const Color kDarkGradientEnd = Color(0xFF1A1D3A);
const double kIconSize = 24.0;

class RoleNavigation extends StatefulWidget {
  final String role;
  final String username;

  const RoleNavigation({super.key, required this.role, required this.username});

  @override
  State<RoleNavigation> createState() => _RoleNavigationState();
}

class _RoleNavigationState extends State<RoleNavigation> {
  int _selectedIndex = 0;

  bool get _isTeacherOrAdmin {
    final r = widget.role.toLowerCase();
    return r == 'teacher' || r == 'admin';
  }

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(role: widget.role, username: widget.username),
      PlayScreen(role: widget.role, username: widget.username),
      const LessonSelectionScreen(),
      ReadScreen(userId: widget.username),
      CombinedLeaderboardScreen(currentUserId: widget.username),
      SettingsScreen(currentUsername: widget.username),
      const TeacherCMSPage(),
      const ProgressTrackingView(),
      const TeacherContentManagementScreen(),
      const TeacherMessagesScreen(),
      TeacherSettingsScreen(currentUsername: widget.username),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  int _getPageMapIndex(int index) {
    if (_isTeacherOrAdmin) {
      switch (index) {
        case 0:
          return 8;
        case 1:
          return 9;
        case 2:
          return 10;
        default:
          return 8;
      }
    }
    return index;
  }

  List<BottomNavigationBarItem> _getNavItems() {
    if (_isTeacherOrAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_stories_outlined),
          activeIcon: Icon(Icons.auto_stories),
          label: 'Content',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_outlined),
          activeIcon: Icon(Icons.forum_rounded),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'My Zone',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.sports_esports_outlined),
        activeIcon: Icon(Icons.sports_esports),
        label: 'Play',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.play_circle_outline),
        activeIcon: Icon(Icons.play_circle_fill),
        label: 'Watch',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book_rounded),
        label: 'Read',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events_outlined),
        activeIcon: Icon(Icons.emoji_events),
        label: 'Rankings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
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
        child: IndexedStack(
          index: _getPageMapIndex(_selectedIndex),
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildNavBar(themeColor),
    );
  }

  Widget _buildNavBar(Color themeColor) {
    final items = _getNavItems();

    return Container(
      decoration: BoxDecoration(
        color: kDarkGradientEnd,
        // Glow line at the top
        border: Border(
          top: BorderSide(color: themeColor.withOpacity(0.35), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isActive = _selectedIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pill indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isActive ? 24 : 0,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon
                      IconTheme(
                        data: IconThemeData(
                          size: kIconSize,
                          color:
                              isActive
                                  ? themeColor
                                  : Colors.white.withOpacity(0.35),
                        ),
                        child:
                            isActive ? item.activeIcon ?? item.icon : item.icon,
                      ),
                      const SizedBox(height: 3),
                      // Label
                      Text(
                        item.label ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isActive
                                  ? themeColor
                                  : Colors.white.withOpacity(0.35),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
