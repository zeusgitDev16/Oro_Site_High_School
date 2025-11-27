import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_permission_service.dart';

/// Reusable middle panel widget for displaying classroom subjects
/// 
/// This widget displays a list of subjects for a selected classroom with RBAC support.
/// - **Admin/Teacher**: Can add new subjects (if they own the classroom)
/// - **Student**: Read-only view
/// 
/// **Usage:**
/// ```dart
/// ClassroomSubjectsPanel(
///   selectedClassroom: _selectedClassroom!,
///   subjects: _subjects,
///   selectedSubject: _selectedSubject,
///   onSubjectSelected: (subject) {
///     setState(() => _selectedSubject = subject);
///   },
///   userRole: 'teacher',
///   userId: _teacherId!,
///   isLoading: _isLoadingSubjects,
///   onAddSubject: _canAddSubject ? _showAddSubjectDialog : null,
/// )
/// ```
class ClassroomSubjectsPanel extends StatelessWidget {
  final Classroom selectedClassroom;
  final List<ClassroomSubject> subjects;
  final ClassroomSubject? selectedSubject;
  final Function(ClassroomSubject subject) onSubjectSelected;
  final String? userRole;
  final String? userId;
  final bool isLoading;
  final VoidCallback? onAddSubject;

  const ClassroomSubjectsPanel({
    super.key,
    required this.selectedClassroom,
    required this.subjects,
    this.selectedSubject,
    required this.onSubjectSelected,
    this.userRole,
    this.userId,
    this.isLoading = false,
    this.onAddSubject,
  });

  bool get _canAddSubjects {
    final permissionService = ClassroomPermissionService();
    return permissionService.canCreateSubjects(
      userRole: userRole,
      userId: userId,
      classroomTeacherId: selectedClassroom.teacherId,
      classroomAdvisoryTeacherId: selectedClassroom.advisoryTeacherId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBJECTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_canAddSubjects && onAddSubject != null)
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: onAddSubject,
                    tooltip: 'Add Subject',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Subject List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : subjects.isEmpty
                    ? _buildEmptyState()
                    : _buildSubjectList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No subjects yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (_canAddSubjects && onAddSubject != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onAddSubject,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Subject'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    return ListView.builder(
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final isSelected = selectedSubject?.id == subject.id;

        // Phase 2 Task 2.5: Check if current teacher is assigned to this subject
        final isSubjectTeacher = userRole == 'teacher' &&
            userId != null &&
            subject.teacherId == userId;

        return Material(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          child: InkWell(
            onTap: () => onSubjectSelected(subject),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subject.subjectName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Phase 2 Task 2.5: Teacher badge or "No teacher assigned" indicator
                  if (isSubjectTeacher) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 7,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'TEACHER',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (subject.teacherName != null) ...[
                    // Show teacher name if assigned but not current user
                    Text(
                      subject.teacherName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    // Show "No teacher assigned" indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 10,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

