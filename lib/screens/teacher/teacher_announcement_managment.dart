import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/teacher_content_management.dart';

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

  // ── Firestore reference ──────────────────────────────────────────────────
  final _col = FirebaseFirestore.instance.collection('announcements');

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
    _loadAnnouncements();
  }

  Future<void> _loadTeacherInfo() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      setState(() {
        _teacherName =
            doc.data()?['name'] ??
            doc.data()?['username'] ??
            widget.currentUsername;
      });
    } catch (_) {
      setState(() => _teacherName = widget.currentUsername);
    }
  }

  // ── Load all announcements posted by this teacher ────────────────────────
  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await _col
              .where('teacherUsername', isEqualTo: widget.currentUsername)
              .orderBy('date', descending: true)
              .get();

      setState(() {
        _announcements =
            snapshot.docs
                .map((doc) => {'docId': doc.id, ...doc.data()})
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Failed to load announcements: $e', Colors.red);
    }
  }

  // ── Save new or updated announcement to Firestore ────────────────────────
  Future<void> _saveAnnouncement(
    Map<String, dynamic> announcement, {
    String? docId,
  }) async {
    try {
      if (docId != null) {
        // Edit existing
        await _col.doc(docId).update(announcement);
      } else {
        // Create new
        await _col.add(announcement);
      }
    } catch (e) {
      _snack('Failed to save: $e', Colors.red);
      rethrow;
    }
  }

  // ── Delete from Firestore ────────────────────────────────────────────────
  Future<void> _deleteFromFirestore(String docId) async {
    try {
      await _col.doc(docId).delete();
    } catch (e) {
      _snack('Failed to delete: $e', Colors.red);
      rethrow;
    }
  }

  void _showAddAnnouncementDialog({
    Map<String, dynamic>? existingAnnouncement,
    int? index,
  }) {
    final isEdit = existingAnnouncement != null;
    final titleController = TextEditingController(
      text: existingAnnouncement?['title'] ?? '',
    );
    final messageController = TextEditingController(
      text: existingAnnouncement?['message'] ?? '',
    );
    String selectedPriority = existingAnnouncement?['priority'] ?? 'Low';
    List<String> selectedSections = List<String>.from(
      existingAnnouncement?['sections'] ?? [],
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1B263B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    isEdit ? "Edit Announcement" : "Create Announcement",
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section Selector ──────────────────────────────────
                        SectionSelector(
                          selected: selectedSections,
                          onChanged:
                              (v) => setDialogState(() => selectedSections = v),
                        ),
                        const SizedBox(height: 16),

                        // ── Title ─────────────────────────────────────────────
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

                        // ── Message ───────────────────────────────────────────
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

                        // ── Priority ──────────────────────────────────────────
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
                                    child: Row(
                                      children: [
                                        Icon(
                                          value == 'High'
                                              ? Icons.priority_high
                                              : value == 'Medium'
                                              ? Icons.error_outline
                                              : Icons.info_outline,
                                          color:
                                              value == 'High'
                                                  ? Colors.red
                                                  : value == 'Medium'
                                                  ? Colors.orange
                                                  : Colors.blue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(value),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setDialogState(
                                  () => selectedPriority = newValue,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                // ── Validation ──────────────────────────────────
                                if (titleController.text.trim().isEmpty) {
                                  _snack('Please enter a title', Colors.red);
                                  return;
                                }
                                if (messageController.text.trim().isEmpty) {
                                  _snack('Please enter a message', Colors.red);
                                  return;
                                }
                                if (selectedSections.isEmpty) {
                                  _snack(
                                    'Please select at least one section',
                                    Colors.red,
                                  );
                                  return;
                                }

                                setDialogState(() => isSaving = true);

                                final data = {
                                  'title': titleController.text.trim(),
                                  'message': messageController.text.trim(),
                                  'priority': selectedPriority,
                                  'sections': selectedSections,
                                  'teacherName': _teacherName,
                                  'teacherUsername': widget.currentUsername,
                                  'date':
                                      isEdit
                                          ? existingAnnouncement!['date']
                                          : DateTime.now().toIso8601String(),
                                };

                                try {
                                  await _saveAnnouncement(
                                    data,
                                    docId:
                                        isEdit
                                            ? existingAnnouncement!['docId']
                                            : null,
                                  );

                                  // ── Refresh local list ───────────────────────
                                  await _loadAnnouncements();

                                  if (mounted) {
                                    Navigator.pop(context);
                                    final sectionLabel =
                                        selectedSections.length ==
                                                kAllSections.length
                                            ? 'all sections'
                                            : selectedSections.join(', ');
                                    _snack(
                                      isEdit
                                          ? 'Announcement updated!'
                                          : 'Posted to $sectionLabel!',
                                      Colors.green,
                                    );
                                  }
                                } catch (_) {
                                  setDialogState(() => isSaving = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryAccentColor,
                      ),
                      child:
                          isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                isEdit ? "Update" : "Post",
                                style: const TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _deleteAnnouncement(String docId, String localId) {
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
                  try {
                    await _deleteFromFirestore(docId);
                    setState(() {
                      _announcements.removeWhere((a) => a['docId'] == docId);
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _snack('Announcement deleted', Colors.orange);
                    }
                  } catch (_) {}
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
    } catch (_) {
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

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
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
          // ── Refresh button ───────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnnouncements,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddAnnouncementDialog(),
            tooltip: 'New Announcement',
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
                  // ── Stats Card ───────────────────────────────────────────
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
                                (a) =>
                                    (a['priority'] ?? '').toLowerCase() ==
                                    'high',
                              )
                              .length
                              .toString(),
                          Icons.priority_high,
                          Colors.red,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        _buildStatItem(
                          "Sections",
                          _announcements
                              .expand(
                                (a) => List<String>.from(a['sections'] ?? []),
                              )
                              .toSet()
                              .length
                              .toString(),
                          Icons.class_,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // ── Announcements List ───────────────────────────────────
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
                                final sections = List<String>.from(
                                  announcement['sections'] ?? [],
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
                                        // ── Header ───────────────────────
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

                                        // ── Message ──────────────────────
                                        Text(
                                          announcement['message'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // ── Section chips ─────────────────
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children:
                                              sections.isEmpty
                                                  ? [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.05),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'No sections assigned',
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                  : sections.map((s) {
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _sectionTitleColor
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              _sectionTitleColor
                                                                  .withOpacity(
                                                                    0.4,
                                                                  ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.class_,
                                                            size: 12,
                                                            color:
                                                                _sectionTitleColor,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            s,
                                                            style: TextStyle(
                                                              color:
                                                                  _sectionTitleColor,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                        ),
                                        const SizedBox(height: 12),

                                        // ── Bottom row ────────────────────
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: _sectionTitleColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  announcement['teacherName'] ??
                                                      '',
                                                  style: TextStyle(
                                                    color: _sectionTitleColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          _showAddAnnouncementDialog(
                                                            existingAnnouncement:
                                                                announcement,
                                                            index: index,
                                                          ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      () => _deleteAnnouncement(
                                                        announcement['docId'],
                                                        announcement['docId'],
                                                      ),
                                                ),
                                              ],
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
        onPressed: () => _showAddAnnouncementDialog(),
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
