import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';

/// NEO LMS-style Compose Message Dialog
/// Allows admin to send messages to individuals or broadcast to roles
class ComposeMessageDialog extends StatefulWidget {
  final MessagesState state;
  final Thread? replyTo;
  final Thread? forwardFrom;

  const ComposeMessageDialog({
    super.key,
    required this.state,
    this.replyTo,
    this.forwardFrom,
  });

  @override
  State<ComposeMessageDialog> createState() => _ComposeMessageDialogState();
}

class _ComposeMessageDialogState extends State<ComposeMessageDialog> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<User> _selectedUsers = [];
  final Set<String> _selectedRoles = {};
  bool _showUserPicker = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Pre-fill for reply
    if (widget.replyTo != null) {
      _subjectCtrl.text = 'Re: ${widget.replyTo!.subject}';
      _selectedUsers.addAll(widget.replyTo!.participants.where((p) => p.id != 'u1')); // Exclude self
    }
    
    // Pre-fill for forward
    if (widget.forwardFrom != null) {
      _subjectCtrl.text = 'Fwd: ${widget.forwardFrom!.subject}';
      if (widget.forwardFrom!.messages.isNotEmpty) {
        _bodyCtrl.text = '\n\n--- Forwarded message ---\n${widget.forwardFrom!.messages.first.body}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 750,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.replyTo != null
                      ? 'Reply'
                      : widget.forwardFrom != null
                          ? 'Forward'
                          : 'New message',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // To field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('To:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ..._selectedUsers.map((user) => Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(user.initials, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                          label: Text(user.name, style: const TextStyle(fontSize: 13)),
                          onDeleted: () => setState(() => _selectedUsers.remove(user)),
                          deleteIconColor: Colors.grey.shade600,
                        )),
                        ..._selectedRoles.map((role) => Chip(
                          avatar: const Icon(Icons.group, size: 16),
                          label: Text(role, style: const TextStyle(fontSize: 13)),
                          backgroundColor: Colors.teal.shade50,
                          onDeleted: () => setState(() => _selectedRoles.remove(role)),
                          deleteIconColor: Colors.grey.shade600,
                        )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Add recipient', style: TextStyle(fontSize: 13)),
                          onPressed: () => setState(() => _showUserPicker = !_showUserPicker),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User/Role picker (expandable)
            if (_showUserPicker) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Broadcast to roles:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _roleChip('All Students'),
                          _roleChip('All Teachers'),
                          _roleChip('All Parents'),
                          _roleChip('All Administrators'),
                          _roleChip('All Managers'),
                          _roleChip('All Staff'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Or select individual users:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      // Search bar
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Mock user list (filtered)
                      ..._getFilteredUsers().map((user) => CheckboxListTile(
                        dense: true,
                        value: _selectedUsers.contains(user),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedUsers.add(user);
                            } else {
                              _selectedUsers.remove(user);
                            }
                          });
                        },
                        title: Text(user.name, style: const TextStyle(fontSize: 13)),
                        secondary: CircleAvatar(
                          radius: 16,
                          child: Text(user.initials, style: const TextStyle(fontSize: 10)),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Cc field (optional, collapsed by default)
            // Bcc field (optional, collapsed by default)

            // Subject
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Message body
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Write your message here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Monitoring notice
            Text(
              '(your school monitors communications for offensive language)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send'),
                  onPressed: _canSend() ? () => _sendMessage() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    final selected = _selectedRoles.contains(role);
    return FilterChip(
      label: Text(role, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _selectedRoles.add(role);
          } else {
            _selectedRoles.remove(role);
          }
        });
      },
      selectedColor: Colors.teal.shade100,
      checkmarkColor: Colors.teal.shade700,
    );
  }

  bool _canSend() {
    return (_selectedUsers.isNotEmpty || _selectedRoles.isNotEmpty) &&
        _subjectCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty;
  }

  void _sendMessage() {
    // Collect all recipients
    final allRecipients = <User>[..._selectedUsers];
    
    // Add mock users for selected roles
    for (var role in _selectedRoles) {
      allRecipients.addAll(_getMockUsersForRole(role));
    }

    // Create thread
    final thread = Thread(
      id: UniqueKey().toString(),
      subject: _subjectCtrl.text.trim(),
      participants: allRecipients,
      messages: [
        Msg(
          id: UniqueKey().toString(),
          author: User(id: 'u1', name: 'Admin', initials: 'AD'),
          body: _bodyCtrl.text.trim(),
          createdAt: DateTime.now(),
        ),
      ],
      sentByAdmin: true,
      isAnnouncement: _selectedRoles.isNotEmpty, // Broadcast = announcement
    );

    widget.state.allThreads.insert(0, thread);
    widget.state.notifyListeners();

    Navigator.pop(context);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedRoles.isNotEmpty
              ? 'Broadcast sent to ${allRecipients.length} recipients'
              : 'Message sent to ${allRecipients.length} recipient(s)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<User> _getMockUsers() {
    return [
      User(id: 'u2', name: 'Ms. Cruz', initials: 'MC'),
      User(id: 'u3', name: 'Juan Dela Cruz', initials: 'JD'),
      User(id: 'u4', name: 'Maria Santos', initials: 'MS'),
      User(id: 'u5', name: 'Pedro Reyes', initials: 'PR'),
    ];
  }

  List<User> _getFilteredUsers() {
    final allUsers = _getMockUsers();
    if (_searchQuery.isEmpty) {
      return allUsers;
    }
    return allUsers.where((user) {
      return user.name.toLowerCase().contains(_searchQuery) ||
             user.initials.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<User> _getMockUsersForRole(String role) {
    // Mock: Generate users based on role
    // In real app, this would query the database
    final count = role.contains('Students') ? 1846 : 50;
    return List.generate(
      count,
      (i) => User(
        id: 'mock_$role\_$i',
        name: '$role Member $i',
        initials: 'U$i',
      ),
    );
  }
}
