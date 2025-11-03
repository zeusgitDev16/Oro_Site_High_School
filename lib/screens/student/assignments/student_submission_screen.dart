import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_assignments_logic.dart';
import 'package:intl/intl.dart';

/// Student Submission Screen
/// Interface for submitting assignment work
/// UI only - logic in StudentAssignmentsLogic
class StudentSubmissionScreen extends StatefulWidget {
  final int assignmentId;
  final StudentAssignmentsLogic logic;

  const StudentSubmissionScreen({
    super.key,
    required this.assignmentId,
    required this.logic,
  });

  @override
  State<StudentSubmissionScreen> createState() => _StudentSubmissionScreenState();
}

class _StudentSubmissionScreenState extends State<StudentSubmissionScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSubmission();
  }

  void _loadExistingSubmission() {
    final submission = widget.logic.getSubmission(widget.assignmentId);
    if (submission != null) {
      _textController.text = submission['textContent'] ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.logic.getAssignmentById(widget.assignmentId);

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment Not Found')),
        body: const Center(child: Text('Assignment not found')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(assignment),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssignmentInfo(assignment),
              const SizedBox(height: 24),
              _buildSubmissionForm(assignment),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(assignment),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> assignment) {
    return AppBar(
      title: const Text('Submit Assignment'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        ListenableBuilder(
          listenable: widget.logic,
          builder: (context, _) {
            final submission = widget.logic.getSubmission(assignment['id']);
            if (submission != null && submission['lastSaved'] != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Saved ${_getTimeAgo(submission['lastSaved'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAssignmentInfo(Map<String, dynamic> assignment) {
    final dueDate = assignment['dueDate'] as DateTime;
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final daysUntilDue = difference.inDays;

    Color dueDateColor = Colors.grey.shade700;
    if (daysUntilDue < 0) {
      dueDateColor = Colors.red;
    } else if (daysUntilDue <= 1) {
      dueDateColor = Colors.red;
    } else if (daysUntilDue <= 3) {
      dueDateColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment['title'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.book, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  assignment['course'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${assignment['pointsPossible']} points',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: dueDateColor),
                const SizedBox(width: 6),
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dueDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: dueDateColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (daysUntilDue >= 0)
                  Text(
                    '(${daysUntilDue == 0 ? 'Due Today' : daysUntilDue == 1 ? 'Due Tomorrow' : '$daysUntilDue days'})',
                    style: TextStyle(
                      fontSize: 13,
                      color: dueDateColor,
                    ),
                  )
                else
                  Text(
                    '(Overdue)',
                    style: TextStyle(
                      fontSize: 13,
                      color: dueDateColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm(Map<String, dynamic> assignment) {
    final submissionTypes = assignment['submissionTypes'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Submission',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (submissionTypes.contains('text')) ...[
          _buildTextSubmission(),
          const SizedBox(height: 24),
        ],
        if (submissionTypes.contains('file')) ...[
          _buildFileSubmission(assignment),
          const SizedBox(height: 24),
        ],
        if (submissionTypes.contains('link')) ...[
          _buildLinkSubmission(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTextSubmission() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Text Response',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Type your response here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSubmission(Map<String, dynamic> assignment) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        final submission = widget.logic.getSubmission(assignment['id']);
        final files = submission?['files'] as List? ?? [];

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'File Upload',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Drag and drop files here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'or',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _pickFile(assignment),
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Browse Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Max size: ${assignment['maxFileSize']} MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Allowed: ${(assignment['allowedFileTypes'] as List).join(', ')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (files.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Uploaded Files',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...files.map((file) => _buildFileItem(file, assignment['id'])),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file, int assignmentId) {
    final extension = (file['name'] as String).split('.').last.toUpperCase();
    Color color = Colors.blue;
    IconData icon = Icons.insert_drive_file;

    if (extension == 'PDF') {
      color = Colors.red;
      icon = Icons.picture_as_pdf;
    } else if (extension == 'DOC' || extension == 'DOCX') {
      color = Colors.blue;
      icon = Icons.description;
    } else if (extension == 'JPG' || extension == 'PNG') {
      color = Colors.green;
      icon = Icons.image;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          file['name'],
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          '${file['size']} MB • Uploaded ${_getTimeAgo(file['uploadedAt'])}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () {
            widget.logic.removeFile(assignmentId, file['name']);
            setState(() {
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLinkSubmission() {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        final submission = widget.logic.getSubmission(widget.assignmentId);
        final links = submission?['links'] as List? ?? [];

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: Colors.purple.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'Website Links',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _addLink,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ],
                ),
                if (links.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Added Links',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...links.map((link) => _buildLinkItem(link)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkItem(String link) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.link, color: Colors.purple, size: 24),
        ),
        title: Text(
          link,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          onPressed: () {
            widget.logic.removeLink(widget.assignmentId, link);
            setState(() {
              _hasUnsavedChanges = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> assignment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _saveDraft(assignment),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Draft'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ListenableBuilder(
              listenable: widget.logic,
              builder: (context, _) {
                return ElevatedButton.icon(
                  onPressed: widget.logic.isSubmitting ? null : () => _submitAssignment(assignment),
                  icon: widget.logic.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(widget.logic.isSubmitting ? 'Submitting...' : 'Submit Assignment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickFile(Map<String, dynamic> assignment) {
    // Simulate file picker
    final mockFile = {
      'name': 'my_assignment_${DateTime.now().millisecondsSinceEpoch}.pdf',
      'size': 2.3,
      'type': 'application/pdf',
      'uploadedAt': DateTime.now(),
    };

    widget.logic.addFile(assignment['id'], mockFile);
    setState(() {
      _hasUnsavedChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File "${mockFile['name']}" added'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.logic.addLink(widget.assignmentId, link);
    _linkController.clear();
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveDraft(Map<String, dynamic> assignment) async {
    final success = await widget.logic.saveSubmissionDraft(
      assignmentId: assignment['id'],
      textContent: _textController.text,
    );

    if (success) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submitAssignment(Map<String, dynamic> assignment) async {
    // Validate submission
    final submission = widget.logic.getSubmission(assignment['id']);
    final hasContent = _textController.text.trim().isNotEmpty ||
        (submission?['files'] as List?)?.isNotEmpty == true ||
        (submission?['links'] as List?)?.isNotEmpty == true;

    if (!hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: const Text(
          'Are you sure you want to submit this assignment? You may not be able to edit it after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Save current content first
    await widget.logic.saveSubmissionDraft(
      assignmentId: assignment['id'],
      textContent: _textController.text,
    );

    // Submit
    final success = await widget.logic.submitAssignment(assignment['id']);

    if (success && mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              final assignment = widget.logic.getAssignmentById(widget.assignmentId);
              if (assignment != null) {
                await _saveDraft(assignment);
              }
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
