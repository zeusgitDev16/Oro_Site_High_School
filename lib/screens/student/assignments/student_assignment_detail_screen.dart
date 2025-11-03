import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_assignments_logic.dart';
import 'package:oro_site_high_school/screens/student/assignments/student_submission_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

/// Student Assignment Detail Screen
/// Shows assignment details, instructions, and submission status
/// UI only - logic in StudentAssignmentsLogic
class StudentAssignmentDetailScreen extends StatefulWidget {
  final int assignmentId;
  final StudentAssignmentsLogic logic;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.logic,
  });

  @override
  State<StudentAssignmentDetailScreen> createState() => _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState extends State<StudentAssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load submission after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.logic.loadSubmission(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.logic.getAssignmentById(widget.assignmentId);

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Assignment Not Found'),
        ),
        body: const Center(
          child: Text('Assignment not found'),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(assignment),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentHeader(assignment),
            _buildAssignmentContent(assignment),
            _buildSubmissionSection(assignment),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> assignment) {
    final status = assignment['status'] as String;
    Color statusColor = Colors.grey;
    String statusText = 'Not Started';

    switch (status) {
      case 'draft':
        statusColor = Colors.blue;
        statusText = 'Draft Saved';
        break;
      case 'submitted':
        statusColor = Colors.purple;
        statusText = 'Submitted';
        break;
      case 'graded':
        statusColor = Colors.green;
        statusText = 'Graded';
        break;
      case 'missing':
        statusColor = Colors.red;
        statusText = 'Missing';
        break;
    }

    return AppBar(
      title: const Text('Assignment Details'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                status == 'graded' ? Icons.grade : Icons.circle,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentHeader(Map<String, dynamic> assignment) {
    final dueDate = assignment['dueDate'] as DateTime;
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    final daysUntilDue = difference.inDays;
    final status = assignment['status'] as String;

    Color dueDateColor = Colors.grey.shade700;
    if (status != 'graded' && status != 'submitted') {
      if (daysUntilDue < 0) {
        dueDateColor = Colors.red;
      } else if (daysUntilDue <= 1) {
        dueDateColor = Colors.red;
      } else if (daysUntilDue <= 3) {
        dueDateColor = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment['title'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.book, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                assignment['course'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.person, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                assignment['teacher'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(dueDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(dueDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment['pointsPossible']}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentContent(Map<String, dynamic> assignment) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: MarkdownBody(
                data: assignment['description'] ?? 'No instructions provided',
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  p: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
                  listBullet: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (assignment['attachments'] != null && (assignment['attachments'] as List).isNotEmpty) ...[
            const Text(
              'Attachments from Teacher',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(assignment['attachments'] as List).map((attachment) => _buildAttachmentCard(attachment)),
            const SizedBox(height: 24),
          ],
          _buildRequirements(assignment),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(String filename) {
    final extension = filename.split('.').last.toUpperCase();
    Color color = Colors.blue;
    IconData icon = Icons.insert_drive_file;

    if (extension == 'PDF') {
      color = Colors.red;
      icon = Icons.picture_as_pdf;
    } else if (extension == 'DOC' || extension == 'DOCX') {
      color = Colors.blue;
      icon = Icons.description;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          filename,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          extension,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Downloading $filename...'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequirements(Map<String, dynamic> assignment) {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Submission Requirements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildRequirementRow(
              Icons.upload_file,
              'Submission Types',
              (assignment['submissionTypes'] as List).join(', ').toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              Icons.storage,
              'Max File Size',
              '${assignment['maxFileSize']} MB',
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              Icons.description,
              'Allowed File Types',
              (assignment['allowedFileTypes'] as List).join(', '),
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              Icons.refresh,
              'Resubmission',
              assignment['allowResubmission'] ? 'Allowed' : 'Not Allowed',
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              Icons.schedule,
              'Late Submission',
              assignment['allowLateSubmission'] ? 'Allowed' : 'Not Allowed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionSection(Map<String, dynamic> assignment) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        final submission = widget.logic.getSubmission(assignment['id']);
        final status = assignment['status'] as String;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
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
              if (status == 'graded' && submission != null && submission['grade'] != null)
                _buildGradeCard(submission['grade'])
              else if (status == 'submitted' && submission != null)
                _buildSubmittedCard(submission)
              else if (status == 'draft' && submission != null)
                _buildDraftCard(submission, assignment)
              else if (status == 'missing')
                _buildMissingCard(assignment)
              else
                _buildNotStartedCard(assignment),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> grade) {
    final percentage = grade['percentage'] as int;
    Color gradeColor = Colors.green;
    if (percentage < 75) {
      gradeColor = Colors.red;
    } else if (percentage < 85) {
      gradeColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.grade, color: gradeColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Graded',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${grade['score']}/${grade['pointsPossible']}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: gradeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (grade['feedback'] != null) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.comment, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Teacher Feedback',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      grade['feedback'],
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Graded by ${grade['gradedBy']} on ${DateFormat('MMM dd, yyyy').format(grade['gradedAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedCard(Map<String, dynamic> submission) {
    return Card(
      elevation: 2,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.purple, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Submitted Successfully',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted on ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format(submission['submittedAt'])}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your teacher will grade this assignment soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> submission, Map<String, dynamic> assignment) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Draft Saved',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last saved: ${DateFormat('MMM dd, yyyy \'at\' h:mm a').format(submission['lastSaved'])}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentSubmissionScreen(
                        assignmentId: assignment['id'],
                        logic: widget.logic,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Continue Editing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingCard(Map<String, dynamic> assignment) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Missing Assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This assignment was not submitted by the due date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            if (assignment['allowLateSubmission']) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentSubmissionScreen(
                          assignmentId: assignment['id'],
                          logic: widget.logic,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Submit Late'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotStartedCard(Map<String, dynamic> assignment) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentSubmissionScreen(
                assignmentId: assignment['id'],
                logic: widget.logic,
              ),
            ),
          );
        },
        icon: const Icon(Icons.upload, size: 24),
        label: const Text('Start Submission', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
