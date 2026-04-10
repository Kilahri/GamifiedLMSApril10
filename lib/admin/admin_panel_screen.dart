import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';

// Theme Constants
const Color kPrimaryColor = Color(0xFF0D102C);
const Color kAccentColor = Color(0xFFFFC107);
const Color kButtonColor = Color(0xFF7B4DFF);

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _messages = [];
  int _selectedIndex = 0;

  // Admin settings
  String _adminUsername = "Admin_SciLearn";
  String _adminPassword = "Admin@2026";
  String _adminEmail = "admin@scilearn.com";
  bool _allowStudentSignup = true;
  bool _requireEmailVerification = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadAdminSettings();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('messages')
              .where('to', isEqualTo: 'Admin')
              .get(); // ← removed orderBy
      setState(() {
        _messages =
            snapshot.docs
                .map((doc) => {...doc.data(), 'docId': doc.id})
                .toList();
        // sort in memory instead
        _messages.sort(
          (a, b) =>
              (b['timestamp'] as String).compareTo(a['timestamp'] as String),
        );
      });
      debugPrint('✅ Messages: ${_messages.length}');
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  Future<void> _loadUsers() async {
    final teachers = await FirebaseService.getUsersByRole('teacher');
    final students = await FirebaseService.getUsersByRole('student');
    setState(() {
      _teachers = teachers;
      _students = students;
    });
  }

  Future<void> _loadAdminSettings() async {
    final uid = FirebaseService.currentUser!.uid;
    final profile = await FirebaseService.getUserProfile(uid);
    setState(() {
      _adminUsername = profile?['username'] ?? 'Admin_SciLearn';
      _adminEmail = profile?['email'] ?? 'admin@scilearn.com';
      // password never loaded — Firebase Auth handles it
      _allowStudentSignup = profile?['allowStudentSignup'] ?? true;
      _requireEmailVerification = profile?['requireEmailVerification'] ?? false;
    });
  }

  Future<void> _saveAdminSettings() async {
    final uid = FirebaseService.currentUser!.uid;
    await FirebaseService.updateUserProfile(uid, {
      'allowStudentSignup': _allowStudentSignup,
      'requireEmailVerification': _requireEmailVerification,
    });
  }

  void _markMessageAsRead(Map<String, dynamic> message) async {
    final docId = message['docId'] as String?;
    if (docId == null) return;
    await FirebaseFirestore.instance.collection('messages').doc(docId).update({
      'isRead': true,
    });
    setState(() => message['isRead'] = true);
  }

  void _deleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
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
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final docId = message['docId'] as String?;
                  if (docId != null) {
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .doc(docId)
                        .delete();
                  }
                  setState(() => _messages.remove(message));
                  Navigator.pop(context);
                  _showMessage('Message deleted');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Added missing _deleteUser method
  void _deleteUser(Map<String, dynamic> user, String userType) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: Text(
              'Delete $userType',
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to delete ${user['fullName'] ?? user['username']}?',
              style: const TextStyle(color: Colors.white70),
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
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user['uid'] as String)
                        .delete();
                    await _loadUsers();
                    Navigator.pop(context);
                    _showMessage('$userType deleted successfully');
                  } catch (e) {
                    _showMessage('Failed to delete $userType.');
                  }
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
            backgroundColor: const Color(0xFF1C1F3E),
            title: Row(
              children: [
                Icon(
                  message['to'] == 'Admin'
                      ? Icons.admin_panel_settings
                      : Icons.school,
                  color: kAccentColor,
                ),
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
                  _buildDetailRow(Icons.send_to_mobile, 'To', message['to']),
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
                      color: kAccentColor,
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
            ],
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kAccentColor, size: 18),
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

  Widget _buildMessagesTab() {
    final unreadCount = _messages.where((m) => !(m['isRead'] ?? false)).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Messages (${_messages.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount unread',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _loadMessages();
                  _showMessage('Messages refreshed');
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _messages.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Messages sent to Admin will appear here',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _messages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isRead = message['isRead'] ?? false;

                      return Card(
                        color: const Color(0xFF1C1F3E),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isRead ? Colors.grey : kButtonColor,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            message['subject'] ?? 'No Subject',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From: @${message['from']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: const Color(0xFF2A1B4A),
                            onSelected: (value) {
                              if (value == 'view') {
                                _viewMessageDetails(message);
                              } else if (value == 'delete') {
                                _deleteMessage(message);
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'View',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                          onTap: () => _viewMessageDetails(message),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showAddUserDialog(String userType) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final studentIdController = TextEditingController();
    final parentContactController = TextEditingController();
    String? selectedSection = userType == 'Student' ? 'Section A' : null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1F3E),
                  title: Text(
                    'Add New $userType',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDialogTextField(
                          fullNameController,
                          'Full Name',
                          Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          usernameController,
                          'Username',
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          passwordController,
                          'Password',
                          Icons.lock,
                          obscure: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          emailController,
                          'Email',
                          Icons.email,
                        ),
                        if (userType == 'Student') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedSection,
                            dropdownColor: const Color(0xFF2A1B4A),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Section',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              prefixIcon: const Icon(
                                Icons.group,
                                color: kAccentColor,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A1B4A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items:
                                ['Section A', 'Section B', 'Section C']
                                    .map(
                                      (section) => DropdownMenuItem(
                                        value: section,
                                        child: Text(section),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setDialogState(
                                  () => selectedSection = value,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            studentIdController,
                            'Student ID',
                            Icons.badge,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogTextField(
                            parentContactController,
                            'Parent Contact',
                            Icons.phone,
                          ),
                        ],
                      ],
                    ),
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
                      onPressed: () async {
                        if (usernameController.text.trim().isEmpty ||
                            passwordController.text.isEmpty ||
                            fullNameController.text.trim().isEmpty) {
                          _showMessage(
                            'Username, password, and full name are required',
                          );
                          return;
                        }

                        final username = usernameController.text.trim();
                        final role = userType.toLowerCase();

                        try {
                          await FirebaseService.adminCreateTeacher(
                            username: username,
                            password: passwordController.text.trim(),
                            profileData: {
                              'username': username,
                              'fullName':
                                  fullNameController.text.trim(), // ← add this
                              'displayName': fullNameController.text.trim(),
                              'email': emailController.text.trim(),
                              'role': role,
                              'isActive': true,
                              'createdAt': DateTime.now().toIso8601String(),
                              'source': 'admin',
                              if (role == 'student') ...{
                                'section': selectedSection ?? 'Section A',
                                'studentId': studentIdController.text.trim(),
                                'parentContact':
                                    parentContactController.text.trim(),
                              },
                            },
                          );
                          await _loadUsers();
                          Navigator.pop(context);
                          _showMessage('$userType added successfully');
                        } catch (e) {
                          _showMessage(
                            'Failed to create $userType. Username may already exist.',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user, String userType) {
    final usernameController = TextEditingController(text: user['username']);
    final passwordController = TextEditingController();
    final emailController = TextEditingController(text: user['email'] ?? '');

    final fullNameController = TextEditingController(
      text: user['fullName'] ?? '',
    );
    final studentIdController = TextEditingController(
      text: user['studentId'] ?? '',
    );
    final parentContactController = TextEditingController(
      text: user['parentContact'] ?? '',
    );
    String? selectedSection = user['section'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1F3E),
                  title: Text(
                    'Edit $userType',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full Name field
                        _buildDialogTextField(
                          fullNameController,
                          'Full Name',
                          Icons.person,
                        ),
                        const SizedBox(height: 12),

                        _buildDialogTextField(
                          usernameController,
                          'Username',
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 12),

                        _buildDialogTextField(
                          passwordController,
                          'Password',
                          Icons.lock,
                          obscure: true,
                        ),
                        const SizedBox(height: 12),

                        _buildDialogTextField(
                          emailController,
                          'Email',
                          Icons.email,
                        ),

                        // Display Name ONLY for Students
                        if (userType == 'Student') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedSection,
                            dropdownColor: const Color(0xFF2A1B4A),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Section',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              prefixIcon: const Icon(
                                Icons.group,
                                color: kAccentColor,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A1B4A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items:
                                ['Section A', 'Section B', 'Section C']
                                    .map(
                                      (section) => DropdownMenuItem(
                                        value: section,
                                        child: Text(section),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setDialogState(
                                  () => selectedSection = value,
                                ),
                          ),
                          const SizedBox(height: 12),

                          _buildDialogTextField(
                            studentIdController,
                            'Student ID',
                            Icons.badge,
                          ),
                          const SizedBox(height: 12),

                          _buildDialogTextField(
                            parentContactController,
                            'Parent Contact',
                            Icons.phone,
                          ),
                        ],
                      ],
                    ),
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
                      onPressed: () async {
                        final String uid = user['uid'] as String;
                        final String newPassword =
                            passwordController.text.trim();
                        final String originalUsername =
                            user['username'] as String;
                        final String newUsername =
                            usernameController.text.trim();

                        if (newUsername.contains(' ')) {
                          _showMessage('Username cannot contain spaces.');
                          return;
                        }

                        try {
                          // 1. Update Firestore profile
                          final updates = {
                            'fullName': fullNameController.text.trim(),
                            'displayName': fullNameController.text.trim(),
                            'username': newUsername,
                            'email': emailController.text.trim(),
                            if (userType == 'Student') ...{
                              'section': selectedSection,
                              'studentId': studentIdController.text.trim(),
                              'parentContact':
                                  parentContactController.text.trim(),
                            },
                          };
                          await FirebaseService.updateUserProfile(uid, updates);

                          // 2. Update password only if admin typed a new one
                          if (newPassword.isNotEmpty) {
                            if (newPassword.length < 6) {
                              _showMessage(
                                'Password must be at least 6 characters.',
                              );
                              return;
                            }

                            final profile =
                                await FirebaseService.getUserProfile(uid);
                            final storedPassword =
                                profile?['password'] as String? ?? '';

                            if (storedPassword.isEmpty) {
                              _showMessage(
                                'Cannot update password: stored password not found.',
                              );
                              return;
                            }

                            try {
                              await FirebaseService.adminUpdateUserPassword(
                                username: originalUsername,
                                currentPassword: storedPassword,
                                newPassword: newPassword,
                              );

                              // Sync new password to Firestore
                              await FirebaseService.updateUserProfile(uid, {
                                'password': newPassword,
                              });
                            } on FirebaseAuthException catch (e) {
                              if (e.code == 'invalid-credential' ||
                                  e.code == 'wrong-password' ||
                                  e.code == 'stored-password-mismatch') {
                                // Passwords are out of sync — just update Firestore
                                // so next login works, but warn admin
                                await FirebaseService.updateUserProfile(uid, {
                                  'password': newPassword,
                                });
                                await _loadUsers();
                                Navigator.pop(context);
                                _showMessage(
                                  '⚠️ Profile saved. Password storage updated but Firebase Auth '
                                  'may be out of sync. Ask the user to log out and log back in.',
                                );
                                return;
                              }
                              _showMessage(
                                'Failed to update password: ${e.message}',
                              );
                              return;
                            }
                          }

                          await _loadUsers();
                          Navigator.pop(context);
                          _showMessage('$userType updated successfully');
                        } catch (e) {
                          _showMessage('Failed to update $userType: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String userType) {
    final isActive = user['isActive'] ?? true;
    final fullName = user['displayName'] ?? user['username'];

    return Card(
      color: const Color(0xFF1C1F3E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? kButtonColor : Colors.grey,
          child: Icon(
            userType == 'Teacher' ? Icons.school : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          fullName,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user['username']}',
              style: TextStyle(
                color: isActive ? Colors.white70 : Colors.white24,
              ),
            ),

            // Show leaderboard name ONLY for students
            if (user['section'] != null)
              Text(
                '${user['section']}',
                style: TextStyle(
                  color: isActive ? Colors.white54 : Colors.white24,
                  fontSize: 12,
                ),
              ),
            if (user['email'] != null && user['email'].isNotEmpty)
              Text(
                user['email'],
                style: TextStyle(
                  color: isActive ? Colors.white54 : Colors.white24,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF2A1B4A),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditUserDialog(user, userType);
                break;
              case 'toggle':
                _toggleUserStatus(user);
                break;
              case 'delete':
                _deleteUser(user, userType);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Deactivate' : 'Activate',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) async {
    final uid = user['uid'] as String;
    final newStatus = !(user['isActive'] ?? true);
    await FirebaseService.setUserActive(uid, newStatus);
    await _loadUsers();
    _showMessage(newStatus ? 'User activated' : 'User deactivated');
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Change Admin Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    currentPasswordController,
                    'Current Password',
                    Icons.lock,
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    newPasswordController,
                    'New Password',
                    Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    confirmPasswordController,
                    'Confirm Password',
                    Icons.lock_outline,
                    obscure: true,
                  ),
                ],
              ),
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
                onPressed: () async {
                  if (currentPasswordController.text.isEmpty) {
                    _showMessage('Please enter your current password');
                    return;
                  }
                  if (newPasswordController.text.length < 6) {
                    _showMessage('New password must be at least 6 characters');
                    return;
                  }
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    _showMessage('Passwords do not match');
                    return;
                  }
                  try {
                    final user = FirebaseService.currentUser!;
                    final cred = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPasswordController.text);
                    Navigator.pop(context);
                    _showMessage('Password changed successfully');
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password') {
                      _showMessage('Current password is incorrect');
                    } else {
                      _showMessage('Failed to change password. Try again.');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kButtonColor),
                child: const Text('Change Password'),
              ),
            ],
          ),
    );
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: kAccentColor),
        filled: true,
        fillColor: const Color(0xFF2A1B4A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kButtonColor, width: 2),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kButtonColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1C1F3E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final activeTeachers = _teachers.where((t) => t['isActive'] ?? true).length;

    final unreadMessages =
        _messages.where((m) => !(m['isRead'] ?? false)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Teachers',
                _teachers.length,
                Icons.school,
                kAccentColor,
              ),
              _buildStatCard(
                'Total Students',
                _students.length,
                Icons.people,
                kButtonColor,
              ),
              _buildStatCard(
                'Active Teachers',
                activeTeachers,
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Unread Messages',
                unreadMessages,
                Icons.mail,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog('Teacher'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog('Student'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String userType) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$userType List (${users.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(userType),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              users.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          userType == 'Teacher' ? Icons.school : Icons.people,
                          size: 80,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${userType}s yet',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(users[index], userType);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF1C1F3E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: kAccentColor),
                      SizedBox(width: 8),
                      Text(
                        'Admin Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.white70),
                    title: const Text(
                      'Username',
                      style: TextStyle(color: Colors.white70),
                    ),
                    subtitle: Text(
                      _adminUsername,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.white70),
                    title: const Text(
                      'Email',
                      style: TextStyle(color: Colors.white70),
                    ),
                    subtitle: Text(
                      _adminEmail,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF1C1F3E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: kAccentColor),
                      SizedBox(width: 8),
                      Text(
                        'Application Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.person_add,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Allow Student Signup',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Enable new students to create accounts',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: _allowStudentSignup,
                    activeColor: kButtonColor,
                    onChanged: (value) {
                      setState(() {
                        _allowStudentSignup = value;
                      });
                      _saveAdminSettings();
                      _showMessage('Setting updated');
                    },
                  ),
                  const Divider(color: Colors.white24),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.verified_user,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Require Email Verification',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'New users must verify their email',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: _requireEmailVerification,
                    activeColor: kButtonColor,
                    onChanged: (value) {
                      setState(() {
                        _requireEmailVerification = value;
                      });
                      _saveAdminSettings();
                      _showMessage('Setting updated');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF1C1F3E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: kAccentColor),
                      SizedBox(width: 8),
                      Text(
                        'System Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.apps, color: Colors.white70),
                    title: Text(
                      'App Version',
                      style: TextStyle(color: Colors.white70),
                    ),
                    subtitle: Text(
                      '1.0.0',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.school, color: Colors.white70),
                    title: Text(
                      'Platform',
                      style: TextStyle(color: Colors.white70),
                    ),
                    subtitle: Text(
                      'SciLearn - Science Learning Platform',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1C1F3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Colors.white10,
                            width: 1,
                          ),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text(
                              "Logout",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        content: const Text(
                          "Are you sure you want to logout? You will need to sign in again to access the panel.",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 8.0,
                              bottom: 8.0,
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await FirebaseService.signOut();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(
                                  0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                "LOGOUT FROM SESSION",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _messages.where((m) => !(m['isRead'] ?? false)).length;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F3E),
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildUserList(_teachers, 'Teacher'),
          _buildUserList(_students, 'Student'),
          _buildMessagesTab(),
          _buildSettings(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 3) {
            _loadMessages();
          }
        },
        backgroundColor: const Color(0xFF1C1F3E),
        selectedItemColor: kAccentColor,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Teachers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.message),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
