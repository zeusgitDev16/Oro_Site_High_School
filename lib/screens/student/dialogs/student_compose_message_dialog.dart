import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/messages/student_messages_state.dart';

/// Student Compose Message Dialog
/// Allows student to send messages to teachers
class StudentComposeMessageDialog extends StatefulWidget {
  final StudentMessagesState state;

  const StudentComposeMessageDialog({
    super.key,
    required this.state,
  });

  @override
  State<StudentComposeMessageDialog> createState() =>
      _StudentComposeMessageDialogState();
}

class _StudentComposeMessageDialogState
    extends State<StudentComposeMessageDialog> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final List<User> _selectedUsers = [];

  // Mock available teachers
  final List<User> _availableTeachers = [
    User(id: 't1', name: 'Maria Santos (Math Teacher)', initials: 'MS'),
    User(id: 't2', name: 'Juan Cruz (Science Teacher)', initials: 'JC'),
    User(id: 't3', name: 'Ana Reyes (English Teacher)', initials: 'AR'),
    User(id: 't4', name: 'Pedro Santos (Filipino Teacher)', initials: 'PS'),
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  bool _canSend() {
    return _selectedUsers.isNotEmpty &&
        _subjectCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'New message',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // To field
                    const Text(
                      'To',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._selectedUsers.map((user) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            label: Text(user.name),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                              });
                            },
                          );
                        }).toList(),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Add teacher'),
                          onPressed: _showTeacherPicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Subject
                    const Text(
                      'Subject',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter subject',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    // Message body
                    const Text(
                      'Message',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Write your message here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send'),
                    onPressed: _canSend() ? () => _sendMessage() : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Teacher'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableTeachers.length,
            itemBuilder: (context, index) {
              final teacher = _availableTeachers[index];
              final isSelected = _selectedUsers.contains(teacher);
              return CheckboxListTile(
                value: isSelected,
                title: Text(teacher.name),
                secondary: CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: Text(
                    teacher.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedUsers.add(teacher);
                    } else {
                      _selectedUsers.remove(teacher);
                    }
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    widget.state.createNewThread(
      subject: _subjectCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      recipients: _selectedUsers,
      labels: {'l1'}, // Teachers label
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent to ${_selectedUsers.length} teacher(s)'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
