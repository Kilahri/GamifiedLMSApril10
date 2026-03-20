import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TeacherAnnouncementManagementScreen extends StatefulWidget {
  final String currentUsername;

  const TeacherAnnouncementManagementScreen({
    super.key,
    required this.currentUsername,
  });

  @override
  State<TeacherAnnouncementManagementScreen> createState() =>
      _TeacherAnnouncementManagementScreenState();
}

class _TeacherAnnouncementManagementScreenState
    extends State<TeacherAnnouncementManagementScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _teacherName = "";

  final Color _primaryAccentColor = const Color(0xFF415A77);
  final Color _sectionTitleColor = const Color(0xFF98C1D9);

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
    _loadAnnouncements();
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName =
          prefs.getString("teacher_name_${widget.currentUsername}") ??
          widget.currentUsername;
    });
  }

  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final announcementsJson = prefs.getString('announcements') ?? '[]';
    final List<dynamic> decoded = jsonDecode(announcementsJson);

    setState(() {
      _announcements =
          decoded
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
              .cast<Map<String, dynamic>>();
      // Sort by date (newest first)
      _announcements.sort((a, b) => b['date'].compareTo(a['date']));
      _isLoading = false;
    });
  }

  Future<void> _saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('announcements', jsonEncode(_announcements));

    // Update unread count for all students (simplified - increments count)
    final currentCount = prefs.getInt('unread_announcements_global') ?? 0;
    await prefs.setInt('unread_announcements_global', currentCount + 1);
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedPriority = 'Low';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1B263B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Create Announcement",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Title",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _primaryAccentColor.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _sectionTitleColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: messageController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: "Message",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _primaryAccentColor.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _sectionTitleColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Priority",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _primaryAccentColor.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: selectedPriority,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1B263B),
                            style: const TextStyle(color: Colors.white),
                            underline: const SizedBox(),
                            items:
                                ['Low', 'Medium', 'High'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  selectedPriority = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            messageController.text.isNotEmpty) {
                          final newAnnouncement = {
                            'id':
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            'title': titleController.text,
                            'message': messageController.text,
                            'priority': selectedPriority,
                            'teacherName': _teacherName,
                            'teacherUsername': widget.currentUsername,
                            'date': DateTime.now().toIso8601String(),
                          };

                          setState(() {
                            _announcements.insert(0, newAnnouncement);
                          });

                          await _saveAnnouncements();

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Announcement posted successfully!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryAccentColor,
                      ),
                      child: const Text(
                        "Post",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteAnnouncement(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            title: const Text(
              "Delete Announcement",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to delete this announcement?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _announcements.removeWhere((a) => a['id'] == id);
                  });
                  await _saveAnnouncements();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Announcement deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _getTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return _sectionTitleColor;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.error_outline;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.announcement;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: const Text(
          "Manage Announcements",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddAnnouncementDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF98C1D9)),
              )
              : Column(
                children: [
                  // Stats Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B263B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          "Total",
                          _announcements.length.toString(),
                          Icons.announcement,
                          _sectionTitleColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          "High Priority",
                          _announcements
                              .where(
                                (a) => a['priority']?.toLowerCase() == 'high',
                              )
                              .length
                              .toString(),
                          Icons.priority_high,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // Announcements List
                  Expanded(
                    child:
                        _announcements.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.announcement_outlined,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No announcements yet",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap + to create one",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement = _announcements[index];
                                final priorityColor = _getPriorityColor(
                                  announcement['priority'] ?? 'low',
                                );

                                return Card(
                                  color: const Color(0xFF1B263B),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: priorityColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: priorityColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getPriorityIcon(
                                                  announcement['priority'] ??
                                                      'low',
                                                ),
                                                color: priorityColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    announcement['title'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _getTimeAgo(
                                                      announcement['date'] ??
                                                          DateTime.now()
                                                              .toIso8601String(),
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.6),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: priorityColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                announcement['priority']
                                                        ?.toUpperCase() ??
                                                    'LOW',
                                                style: TextStyle(
                                                  color: priorityColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          announcement['message'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.visibility,
                                                  size: 16,
                                                  color: _sectionTitleColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Visible to all students",
                                                  style: TextStyle(
                                                    color: _sectionTitleColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () => _deleteAnnouncement(
                                                    announcement['id'],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAnnouncementDialog,
        backgroundColor: _primaryAccentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ],
    );
  }
}
