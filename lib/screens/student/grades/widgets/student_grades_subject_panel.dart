import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';

/// **Phase 2 Task 2.2: Student Grades Subject Panel (Middle Panel)**
/// 
/// Displays subjects in selected classroom for student.
/// Adapted from GradebookSubjectList with student-specific styling.
class StudentGradesSubjectPanel extends StatelessWidget {
  final List<ClassroomSubject> subjects;
  final ClassroomSubject? selectedSubject;
  final Function(ClassroomSubject) onSubjectSelected;
  final bool isLoading;

  const StudentGradesSubjectPanel({
    super.key,
    required this.subjects,
    required this.selectedSubject,
    required this.onSubjectSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
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
              children: [
                Icon(Icons.subject, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'SUBJECTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final isSelected = selectedSubject?.id == subject.id;
                          
                          return _buildSubjectCard(subject, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(ClassroomSubject subject, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSubjectSelected(subject),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name
              Text(
                subject.subjectName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.blue.shade900 : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              // Teacher name (if available)
              if (subject.teacherName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 11,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subject.teacherName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Subject code (if available)
              if (subject.subjectCode != null && subject.subjectCode!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subject.subjectCode!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subject, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No subjects available',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Select a classroom to view subjects',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

