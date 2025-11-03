import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';

/// Admin Broadcast Dialog
/// Allows admin to send broadcast messages to multiple roles
class AdminBroadcastDialog extends StatefulWidget {
  final MessagesState state;

  const AdminBroadcastDialog({super.key, required this.state});

  @override
  State<AdminBroadcastDialog> createState() => _AdminBroadcastDialogState();
}

class _AdminBroadcastDialogState extends State<AdminBroadcastDialog> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final Set<String> _selectedRoles = {};
  bool _disableReplies = true;
  bool _requireAck = false;
  DateTime? _scheduleAt;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.campaign, color: Colors.teal, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Broadcast Message',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Target Roles
            const Text(
              'Send to:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _roleChip('All Students', Icons.school, Colors.blue),
                _roleChip('All Teachers', Icons.person, Colors.green),
                _roleChip('All Parents', Icons.family_restroom, Colors.purple),
                _roleChip('All Administrators', Icons.admin_panel_settings, Colors.red),
                _roleChip('All Managers', Icons.business, Colors.orange),
                _roleChip('All Staff', Icons.badge, Colors.teal),
              ],
            ),
            const SizedBox(height: 20),

            // Subject
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.subject),
              ),
            ),
            const SizedBox(height: 16),

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
              const SizedBox(height: 16),
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
                    hintText: 'Write your broadcast message here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Row(
              children: [
                Checkbox(
                  value: _disableReplies,
                  onChanged: (v) =>
                      setState(() => _disableReplies = v ?? false),
                ),
                const Text('Disable replies (announcement only)'),
                const SizedBox(width: 24),
                Checkbox(
                  value: _requireAck,
                  onChanged: (v) => setState(() => _requireAck = v ?? false),
                ),
                const Text('Require acknowledgment'),
              ],
            ),
            const SizedBox(height: 8),

            // Schedule
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _scheduleAt == null
                      ? 'Send immediately'
                      : 'Scheduled: ${_formatDateTime(_scheduleAt!)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _scheduleAt = DateTime.now().add(const Duration(hours: 1));
                    });
                  },
                  icon: const Icon(Icons.add_alarm, size: 16),
                  label: const Text('Schedule +1h'),
                ),
                if (_scheduleAt != null)
                  TextButton(
                    onPressed: () => setState(() => _scheduleAt = null),
                    child: const Text('Clear'),
                  ),
              ],
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
                  icon: const Icon(Icons.campaign, size: 18),
                  label: Text(_scheduleAt == null ? 'Send Broadcast' : 'Schedule Broadcast'),
                  onPressed: _canSend() ? () => _sendBroadcast() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

  Widget _roleChip(String role, IconData icon, Color color) {
    final selected = _selectedRoles.contains(role);
    return FilterChip(
      avatar: Icon(icon, size: 16, color: selected ? color : Colors.grey),
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
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  bool _canSend() {
    return _selectedRoles.isNotEmpty &&
        _subjectCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty;
  }

  void _sendBroadcast() {
    final targets = BroadcastTargets();
    targets.roles.addAll(_selectedRoles);

    Navigator.pop(
      context,
      BroadcastResult(
        subject: _subjectCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        disableReplies: _disableReplies,
        requireAck: _requireAck,
        targets: targets,
        scheduleAt: _scheduleAt,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
