import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- MAIN WIDGET ---
class TeacherCMSPage extends StatefulWidget {
  const TeacherCMSPage({super.key});

  @override
  State<TeacherCMSPage> createState() => _TeacherCMSPageState();
}

class _TeacherCMSPageState extends State<TeacherCMSPage> {
  int _selectedIndex = 0;

  final Color primaryDark = const Color(0xFF0D102C);
  final Color cardColor = const Color(0xFF1E2140);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);

  // Define all views here
  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const ContentManagementView(),
      const ProgressTrackingView(),
      CommunicationView(onRefresh: () => setState(() {})),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text(
          "Science CMS & Teacher Hub",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {},
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Content',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: primaryDark,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- CONTENT MANAGEMENT VIEW (Tab 0) ---
class ContentManagementView extends StatelessWidget {
  const ContentManagementView({super.key});

  final Color cardColor = const Color(0xFF1E2140);
  final Color accentColor = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and Create Button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Content Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Button is now compact for mobile
                ElevatedButton.icon(
                  onPressed: () {
                    // Mock function to create new content
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Key Metrics Cards (Changed from 4-column to 2-column grid for mobile)
          GridView.count(
            crossAxisCount: 2, // Optimized for mobile screen width
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                title: 'Live Lessons',
                value: '142',
                icon: Icons.check_circle_outline,
                color: accentColor,
                cardColor: cardColor,
              ),
              _MetricCard(
                title: 'Drafts in Progress',
                value: '7',
                icon: Icons.edit_note,
                color: Colors.blueAccent,
                cardColor: cardColor,
              ),
              _MetricCard(
                title: 'Pending Admin Review',
                value: '2',
                icon: Icons.pending_actions,
                color: Colors.orange,
                cardColor: cardColor,
              ),
              _MetricCard(
                title: 'Total Questions in Bank',
                value: '850',
                icon: Icons.help_outline,
                color: Colors.purpleAccent,
                cardColor: cardColor,
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Detailed Content List
          Text(
            'Recent Activity & Lesson Status',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildContentStatusList(cardColor, accentColor),
        ],
      ),
    );
  }

  // Refactored table to a mobile-friendly list view
  Widget _buildContentStatusList(Color cardColor, Color accentColor) {
    final List<Map<String, String>> data = [
      {
        'title': 'The Water Cycle',
        'grade': 'Grade 5',
        'status': 'Live',
        'date': 'Oct 25',
      },
      {
        'title': 'Simple Machines Quiz',
        'grade': 'Grade 4',
        'status': 'Draft',
        'date': 'Nov 18',
      },
      {
        'title': 'Planetary Systems',
        'grade': 'Grade 6',
        'status': 'Pending Review',
        'date': 'Nov 19',
      },
      {
        'title': 'Video: Cell Biology',
        'grade': 'Grade 6',
        'status': 'Live',
        'date': 'Sep 01',
      },
    ];

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              item['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item['grade']! + ' | Last Edit: ' + item['date']!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusPill(status: item['status']!, accentColor: accentColor),
                const SizedBox(width: 8),
                const Icon(Icons.edit, color: Colors.grey, size: 20),
              ],
            ),
            onTap: () {
              // Action to open lesson editor
            },
          );
        },
      ),
    );
  }
}

// --- PROGRESS TRACKING VIEW (Tab 1) ---
class ProgressTrackingView extends StatelessWidget {
  const ProgressTrackingView({super.key});
  final Color cardColor = const Color(0xFF1E2140);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          // Key Analytics Cards (Changed from 3-column to 2-column grid for mobile)
          GridView.count(
            crossAxisCount: 2, // Optimized for mobile screen width
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
              // Empty spacer card for alignment
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 30),

          // Student Roster with Metrics
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

  // Refactored table to a mobile-friendly list view
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
              vertical: 4,
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
              // Action to view student details
            },
          );
        },
      ),
    );
  }
}

// --- COMMUNICATION VIEW (Tab 2) - ENHANCED WITH ANNOUNCEMENTS ---
class CommunicationView extends StatefulWidget {
  final VoidCallback onRefresh;

  const CommunicationView({super.key, required this.onRefresh});

  @override
  State<CommunicationView> createState() => _CommunicationViewState();
}

class _CommunicationViewState extends State<CommunicationView> {
  final Color cardColor = const Color(0xFF1E2140);
  final Color accentColor = const Color(0xFF4CAF50);
  final Color warningColor = const Color(0xFFFF9800);

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementContentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String? messagesJson = prefs.getString('admin_messages');

    if (messagesJson != null) {
      List<dynamic> allMessages = jsonDecode(messagesJson);
      // Filter messages where recipient is "Teacher"
      _messages =
          allMessages
              .map((e) => Map<String, dynamic>.from(e))
              .where((msg) => msg['to'] == 'Teacher')
              .toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveMessages(List<Map<String, dynamic>> allMessages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_messages', jsonEncode(allMessages));
  }

  Future<void> _markAsRead(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    String? messagesJson = prefs.getString('admin_messages');

    if (messagesJson != null) {
      List<dynamic> allMessages = jsonDecode(messagesJson);

      // Find and update the message
      for (var msg in allMessages) {
        if (msg['id'] == message['id']) {
          msg['isRead'] = true;
          break;
        }
      }

      // Save back
      await prefs.setString('admin_messages', jsonEncode(allMessages));

      // Update local state
      setState(() {
        message['isRead'] = true;
      });
    }
  }

  void _deleteMessage(Map<String, dynamic> message) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'Delete Message',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this message?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  String? messagesJson = prefs.getString('admin_messages');

                  if (messagesJson != null) {
                    List<dynamic> decoded = jsonDecode(messagesJson);
                    List<Map<String, dynamic>> allMessages =
                        decoded
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList();

                    allMessages.removeWhere((m) => m['id'] == message['id']);
                    await _saveMessages(allMessages);

                    setState(() {
                      _messages.remove(message);
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _viewMessageDetails(Map<String, dynamic> message) {
    _markAsRead(message);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: Row(
              children: [
                Icon(Icons.person, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['subject'] ?? 'No Subject',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(Icons.person, 'From', '@${message['from']}'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time,
                    'Sent',
                    _formatTimestamp(message['timestamp']),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Text(
                    'Message:',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message['message'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showReplyDialog(message);
                },
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply'),
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              ),
            ],
          ),
    );
  }

  void _showReplyDialog(Map<String, dynamic> message) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              'Reply to @${message['from']}',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Re: ${message['subject']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: replyController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Your Reply',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    fillColor: const Color(0xFF2E3150),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reply sent to @${message['from']}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: accentColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: const Text(
                  'Send',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementTitleController.text.isEmpty ||
        _announcementContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? announcementsJson = prefs.getString('announcements');
    List<Map<String, dynamic>> announcements = [];

    if (announcementsJson != null) {
      try {
        announcements = List<Map<String, dynamic>>.from(
          jsonDecode(announcementsJson),
        );
      } catch (e) {
        announcements = [];
      }
    }

    final announcement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _announcementTitleController.text,
      'message': _announcementContentController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'from': 'Teacher',
      'isRead': false,
    };

    announcements.insert(0, announcement);
    await prefs.setString('announcements', jsonEncode(announcements));

    _announcementTitleController.clear();
    _announcementContentController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Announcement sent to all students!'),
        duration: const Duration(seconds: 2),
        backgroundColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _messages.where((m) => !(m['isRead'] ?? false)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Communication Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _loadMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Messages refreshed'),
                      backgroundColor: accentColor,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Refresh Messages',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student Messages Card
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Support Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount new',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2E3150), height: 30),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    )
                  else if (_messages.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.white24),
                            SizedBox(height: 8),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._messages.map(
                      (msg) => _MessageItem(
                        message: msg,
                        cardColor: cardColor,
                        accentColor: accentColor,
                        warningColor: warningColor,
                        onView: () => _viewMessageDetails(msg),
                        onDelete: () => _deleteMessage(msg),
                        formatTimestamp: _formatTimestamp,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Send Announcement Card
          Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign, color: accentColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Send New Announcement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _announcementTitleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      fillColor: const Color(0xFF2E3150),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _announcementContentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message Content',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      fillColor: const Color(0xFF2E3150),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _sendAnnouncement,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('Send to All Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MESSAGE ITEM WIDGET ---
class _MessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final Color cardColor;
  final Color accentColor;
  final Color warningColor;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final String Function(String) formatTimestamp;

  const _MessageItem({
    required this.message,
    required this.cardColor,
    required this.accentColor,
    required this.warningColor,
    required this.onView,
    required this.onDelete,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = message['isRead'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isRead
                ? cardColor.withOpacity(0.5)
                : warningColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRead ? const Color(0xFF2E3150) : warningColor,
          width: isRead ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        'From: @${message['from']}',
                        style: TextStyle(
                          color: isRead ? accentColor : warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatTimestamp(message['timestamp']),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Subject: ${message['subject'] ?? 'No Subject'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message['message'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text(
                  'View & Reply',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE HELPER WIDGETS ---

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
        padding: const EdgeInsets.all(16.0), // Reduced padding for mobile
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ), // Reduced font size
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color accentColor;

  const _StatusPill({required this.status, required this.accentColor});

  Color _getColor() {
    switch (status) {
      case 'Live':
        return accentColor;
      case 'Draft':
        return Colors.blue;
      case 'Pending Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getColor(), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getColor(),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
