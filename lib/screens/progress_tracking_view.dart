import 'package:flutter/material.dart';

// --- PROGRESS TRACKING VIEW (Tab 1) ---
class ProgressTrackingView extends StatelessWidget {
  const ProgressTrackingView({super.key});

  final Color cardColor = const Color(0xFF1E2140);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Progress Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          /// 🔹 Key Analytics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                title: 'Class Average Score',
                value: '84.5%',
                icon: Icons.trending_up,
                color: accentColor,
                cardColor: cardColor,
              ),
              _MetricCard(
                title: 'Students Needing Help',
                value: '5',
                icon: Icons.person_search,
                color: warningColor,
                cardColor: cardColor,
              ),
              _MetricCard(
                title: 'Assignments Completed',
                value: '32',
                icon: Icons.assignment_turned_in,
                color: Colors.cyan,
                cardColor: cardColor,
              ),

              /// Empty card to maintain layout alignment
              const SizedBox.shrink(),
            ],
          ),

          const SizedBox(height: 30),

          /// 🔹 Student Roster
          Text(
            'Roster & Individual Performance',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _buildRosterList(cardColor, accentColor, warningColor),
        ],
      ),
    );
  }

  /// 🔹 Student Performance List
  Widget _buildRosterList(
    Color cardColor,
    Color accentColor,
    Color warningColor,
  ) {
    final List<Map<String, dynamic>> students = [
      {'name': 'Alice Johnson', 'avg': 92, 'alerts': 0},
      {'name': 'Ben Carter', 'avg': 68, 'alerts': 2},
      {'name': 'Chloe Davis', 'avg': 81, 'alerts': 0},
      {'name': 'David Lee', 'avg': 73, 'alerts': 1},
    ];

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final scoreColor = student['avg'] > 75 ? accentColor : warningColor;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            leading: CircleAvatar(
              backgroundColor: scoreColor.withOpacity(0.2),
              child: Text(
                student['name'][0],
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            title: Text(
              student['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: Text(
              'Avg. Score: ${student['avg']}%',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
            ),

            trailing:
                student['alerts'] > 0
                    ? Icon(Icons.error, color: warningColor, size: 20)
                    : const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),

            onTap: () {
              // TODO: Add "View Full Student Report" page
            },
          );
        },
      ),
    );
  }
}

/// 🔹 Small UI Card Component
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
