import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CommunicationView extends StatefulWidget {
  const CommunicationView({super.key});

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
      List<dynamic> decoded = jsonDecode(messagesJson);
      List<Map<String, dynamic>> allMessages =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // Filter to show only messages sent to "Teacher"
      _messages = allMessages.where((m) => m['to'] == 'Teacher').toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveMessages(List<Map<String, dynamic>> allMessages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_messages', jsonEncode(allMessages));
  }

  void _markMessageAsRead(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    String? messagesJson = prefs.getString('admin_messages');

    if (messagesJson != null) {
      List<dynamic> decoded = jsonDecode(messagesJson);
      List<Map<String, dynamic>> allMessages =
          decoded.map((e) => Map<String, dynamic>.from(e)).toList();

      // Find and update the message
      int index = allMessages.indexWhere((m) => m['id'] == message['id']);
      if (index != -1) {
        allMessages[index]['isRead'] = true;
        await _saveMessages(allMessages);
        setState(() {
          message['isRead'] = true;
        });
      }
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
    _markMessageAsRead(message);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['subject'] ?? 'No Subject',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
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
                  const Text(
                    'Message:',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
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
    final unreadCount =
        _messages.where((msg) => !(msg['isRead'] ?? false)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Student Support Messages Card
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
                      (msg) => SupportMessageItem(
                        cardColor: cardColor,
                        from: msg['from'] ?? 'unknown',
                        subject: msg['subject'] ?? 'No Subject',
                        message: msg['message'] ?? '',
                        date: _formatTimestamp(msg['timestamp'] ?? ''),
                        isUnread: !(msg['isRead'] ?? false),
                        warningColor: warningColor,
                        accentColor: accentColor,
                        onView: () => _viewMessageDetails(msg),
                        onDelete: () => _deleteMessage(msg),
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

// --- SUPPORT MESSAGE ITEM WIDGET ---
class SupportMessageItem extends StatelessWidget {
  final Color cardColor;
  final String from;
  final String subject;
  final String message;
  final String date;
  final bool isUnread;
  final Color warningColor;
  final Color accentColor;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const SupportMessageItem({
    super.key,
    required this.cardColor,
    required this.from,
    required this.subject,
    required this.message,
    required this.date,
    required this.isUnread,
    required this.warningColor,
    required this.accentColor,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isUnread
                ? warningColor.withOpacity(0.15)
                : cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnread ? warningColor : const Color(0xFF2E3150),
          width: isUnread ? 2 : 1,
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
                    if (isUnread)
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
                        'From: @$from',
                        style: TextStyle(
                          color: isUnread ? warningColor : accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Subject: $subject',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
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
