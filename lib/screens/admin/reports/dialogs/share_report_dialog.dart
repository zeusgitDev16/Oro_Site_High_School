import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/report_service.dart';
import 'package:oro_site_high_school/services/notification_trigger_service.dart';

/// Share Report Dialog
/// Allows admin to share reports with selected teachers
/// UI-only component following OSHS architecture
class ShareReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final String reportType;

  const ShareReportDialog({
    super.key,
    required this.report,
    required this.reportType,
  });

  @override
  State<ShareReportDialog> createState() => _ShareReportDialogState();
}

class _ShareReportDialogState extends State<ShareReportDialog> {
  final ReportService _reportService = ReportService();
  final NotificationTriggerService _notificationTrigger = NotificationTriggerService();
  
  // Mock teacher list
  final List<Map<String, dynamic>> _teachers = [
    {'id': 'teacher-1', 'name': 'Maria Santos', 'role': 'Grade Level Coordinator'},
    {'id': 'teacher-2', 'name': 'Juan Reyes', 'role': 'Teacher'},
    {'id': 'teacher-3', 'name': 'Ana Cruz', 'role': 'Teacher'},
    {'id': 'teacher-4', 'name': 'Pedro Garcia', 'role': 'Teacher'},
    {'id': 'teacher-5', 'name': 'Rosa Mendoza', 'role': 'Teacher'},
  ];

  final Set<String> _selectedTeachers = {};
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Share Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Select teachers to share this report with:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _teachers.length,
                itemBuilder: (context, index) {
                  final teacher = _teachers[index];
                  final isSelected = _selectedTeachers.contains(teacher['id']);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTeachers.add(teacher['id']);
                        } else {
                          _selectedTeachers.remove(teacher['id']);
                        }
                      });
                    },
                    title: Text(
                      teacher['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      teacher['role'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        teacher['name'].split(' ').map((n) => n[0]).join(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedTeachers.length == _teachers.length) {
                        _selectedTeachers.clear();
                      } else {
                        _selectedTeachers.addAll(_teachers.map((t) => t['id'] as String));
                      }
                    });
                  },
                  child: Text(
                    _selectedTeachers.length == _teachers.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedTeachers.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedTeachers.isEmpty || _isSharing
                      ? null
                      : _handleShare,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: Text(_isSharing ? 'Sharing...' : 'Share Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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

  Future<void> _handleShare() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Share report with selected teachers
      await _reportService.shareReportWithTeachers(
        widget.report,
        _selectedTeachers.toList(),
      );

      // Trigger notifications for each teacher
      for (final teacherId in _selectedTeachers) {
        final teacher = _teachers.firstWhere((t) => t['id'] == teacherId);
        await _notificationTrigger.triggerAnnouncement(
          userId: teacherId,
          userRole: 'teacher',
          title: 'Report Shared',
          message: 'Admin shared a ${widget.reportType} report with you',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report shared with ${_selectedTeachers.length} teacher(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
