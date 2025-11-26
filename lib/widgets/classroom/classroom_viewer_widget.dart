import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_students_dialog.dart';

/// Reusable classroom viewer widget for displaying classroom details
///
/// This widget shows the details of an existing classroom in read-only mode.
/// It displays all classroom information in a clean, organized layout.
///
/// **Usage Example:**
/// ```dart
/// ClassroomViewerWidget(
///   classroom: _selectedClassroom,
///   advisoryTeacher: _advisoryTeacher,
///   onEdit: () {
///     setState(() => _currentMode = 'edit');
///   },
/// )
/// ```
class ClassroomViewerWidget extends StatelessWidget {
  /// The classroom to display
  final Classroom classroom;

  /// The advisory teacher (if any)
  final Teacher? advisoryTeacher;

  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  /// Whether the user can edit this classroom
  final bool canEdit;

  /// Callback when students are changed (for refreshing classroom data)
  final VoidCallback? onStudentsChanged;

  const ClassroomViewerWidget({
    super.key,
    required this.classroom,
    this.advisoryTeacher,
    this.onEdit,
    this.canEdit = true,
    this.onStudentsChanged,
  });

  void _showStudentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClassroomStudentsDialog(
        classroomId: classroom.id,
        onStudentsChanged: onStudentsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and edit button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grade ${classroom.gradeLevel} • ${classroom.schoolLevel}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit && onEdit != null)
                  ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Classroom details
            _buildDetailSection('Basic Information', [
              _buildDetailRow('School Year', classroom.schoolYear),
              _buildDetailRow('Grade Level', 'Grade ${classroom.gradeLevel}'),
              _buildDetailRow('School Level', classroom.schoolLevel),
              _buildDetailRow(
                'Advisory Teacher',
                advisoryTeacher?.displayName ?? 'Not assigned',
              ),
            ]),
            const SizedBox(height: 24),

            _buildDetailSection('Capacity', [
              _buildDetailRow('Max Students', '${classroom.maxStudents}'),
              _buildDetailRow(
                'Current Students',
                '${classroom.currentStudents}',
              ),
              _buildDetailRow('Available Slots', '${classroom.availableSlots}'),
              _buildDetailRow(
                'Occupancy',
                '${classroom.occupancyPercentage.toStringAsFixed(1)}%',
              ),
            ]),
            const SizedBox(height: 12),

            // Manage Students Button
            if (canEdit)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showStudentsDialog(context),
                  icon: const Icon(Icons.people, size: 18),
                  label: const Text('Manage Students'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _buildDetailSection('Status', [
              _buildDetailRow(
                'Active',
                classroom.isActive ? 'Yes' : 'No',
                valueColor: classroom.isActive ? Colors.green : Colors.red,
              ),
              _buildDetailRow('Access Code', classroom.accessCode ?? 'N/A'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
