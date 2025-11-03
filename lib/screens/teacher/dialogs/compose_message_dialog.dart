import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/teacher/messages/messages_state.dart';

/// Teacher Compose Message Dialog
/// Allows teacher to send messages to students, parents, or other teachers
class TeacherComposeMessageDialog extends StatefulWidget {
  final TeacherMessagesState state;
  final Thread? replyTo;

  const TeacherComposeMessageDialog({
    super.key,
    required this.state,
    this.replyTo,
  });

  @override
  State<TeacherComposeMessageDialog> createState() =>
      _TeacherComposeMessageDialogState();
}

class _TeacherComposeMessageDialogState
    extends State<TeacherComposeMessageDialog> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<User> _selectedUsers = [];
  final Set<String> _selectedLabels = {};
  bool _showUserPicker = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Pre-fill for reply
    if (widget.replyTo != null) {
      _subjectCtrl.text = 'Re: ${widget.replyTo!.subject}';
      _selectedUsers.addAll(widget.replyTo!.participants
          .where((p) => p.id != 'u1')); // Exclude self
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.replyTo != null ? 'Reply' : 'New message',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                  child: Text('To:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                                child: Text(user.initials,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white)),
                              ),
                              label: Text(user.name,
                                  style: const TextStyle(fontSize: 13)),
                              onDeleted: () =>
                                  setState(() => _selectedUsers.remove(user)),
                              deleteIconColor: Colors.grey.shade600,
                            )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: const Text('Add recipient',
                              style: TextStyle(fontSize: 13)),
                          onPressed: () =>
                              setState(() => _showUserPicker = !_showUserPicker),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User picker (expandable)
            if (_showUserPicker) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search students, parents, teachers...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // User list (filtered)
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: _getFilteredUsers()
                            .map((user) => CheckboxListTile(
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
                                  title: Text(user.name,
                                      style: const TextStyle(fontSize: 13)),
                                  secondary: CircleAvatar(
                                    radius: 16,
                                    child: Text(user.initials,
                                        style: const TextStyle(fontSize: 10)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Subject
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: 'Subject',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Labels
            if (widget.state.labels.isNotEmpty) ...[
              const Text(
                'Labels (optional):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.state.labels.map((label) {
                  final selected = _selectedLabels.contains(label.id);
                  return FilterChip(
                    label: Text(label.name,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedLabels.add(label.id);
                        } else {
                          _selectedLabels.remove(label.id);
                        }
                      });
                    },
                    backgroundColor: label.color.withOpacity(0.1),
                    selectedColor: label.color.withOpacity(0.3),
                    checkmarkColor: label.color,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Templates
            if (widget.state.templates.isNotEmpty) ...[
              const Text(
                'Quick templates:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.state.templates.map((template) {
                  return ActionChip(
                    avatar: const Icon(Icons.note_add, size: 16),
                    label: Text(template.name,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        if (_bodyCtrl.text.isEmpty) {
                          _bodyCtrl.text = template.body;
                        } else {
                          _bodyCtrl.text =
                              '${_bodyCtrl.text}\n\n${template.body}';
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

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
              '(School monitors communications for appropriate content)',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canSend() {
    return _selectedUsers.isNotEmpty &&
        _subjectCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty;
  }

  void _sendMessage() {
    widget.state.createNewThread(
      subject: _subjectCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      recipients: _selectedUsers,
      labels: _selectedLabels,
    );

    Navigator.pop(context);

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent to ${_selectedUsers.length} recipient(s)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<User> _getMockUsers() {
    return [
      User(id: 'u2', name: 'Juan Dela Cruz (Student)', initials: 'JD'),
      User(id: 'u3', name: 'Pedro Garcia (Student)', initials: 'PG'),
      User(id: 'u4', name: 'Mrs. Maria Santos (Parent)', initials: 'MS'),
      User(id: 'u5', name: 'Prof. Ana Reyes (Teacher)', initials: 'AR'),
      User(id: 'u6', name: 'Mr. Jose Rizal (Parent)', initials: 'JR'),
      User(id: 'u7', name: 'Maria Clara (Student)', initials: 'MC'),
      User(id: 'u8', name: 'Jose Protacio (Student)', initials: 'JP'),
      User(id: 'u9', name: 'Mrs. Andres Bonifacio (Parent)', initials: 'AB'),
      User(id: 'u10', name: 'Prof. Emilio Aguinaldo (Teacher)', initials: 'EA'),
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
}
