import 'package:flutter/material.dart';
import 'content_management_view.dart';
import 'progress_tracking_view.dart';
import 'communication_view.dart';
import 'profile_view.dart';

const double kIconSize = 30.0;
const double kSelectedFontSize = 14.0;

/// Colors
const Color kTeacherColor = Color(0xFF42A5F5);
const Color kDarkGradientStart = Color(0xFF0D102C);
const Color kDarkGradientEnd = Color(0xFF1E2152);

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _selectedIndex = 0;

  final List<Widget> _teacherPages = const [
    ContentManagementView(),
    ProgressTrackingView(), // ← FIXED: Your full analytics UI is now connected
    CommunicationView(),
    ProfileView(),
  ];

  final List<BottomNavigationBarItem> _teacherTabs = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book, size: kIconSize),
      label: "Content",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics, size: kIconSize),
      label: "Progress",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.forum, size: kIconSize),
      label: "Communication",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person, size: kIconSize),
      label: "Profile",
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kDarkGradientStart, kDarkGradientEnd],
          ),
        ),
        child: SafeArea(child: _teacherPages[_selectedIndex]),
      ),

      // bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kTeacherColor,
        unselectedItemColor: kTeacherColor.withOpacity(0.5),
        backgroundColor: kDarkGradientEnd,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: kSelectedFontSize,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: _teacherTabs,
      ),
    );
  }
}
