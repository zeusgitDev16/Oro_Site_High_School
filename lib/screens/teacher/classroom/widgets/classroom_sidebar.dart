import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';

class MyClassroomSidebar extends StatelessWidget {
  const MyClassroomSidebar({
    super.key,
    required this.isLoading,
    required this.classrooms,
    required this.enrollmentCounts,
    required this.selectedClassroom,
    required this.onBack,
    required this.onEditClassroom,
    required this.onDeleteClassroom,
    required this.onSelectClassroom,
    required this.onCreateClassroom,
  });

  final bool isLoading;
  final List<Classroom> classrooms;
  final Map<String, int> enrollmentCounts;
  final Classroom? selectedClassroom;

  final VoidCallback onBack;
  final void Function(Classroom c) onEditClassroom;
  final void Function(Classroom c) onDeleteClassroom;
  final void Function(Classroom c) onSelectClassroom;
  final VoidCallback onCreateClassroom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLASSROOM MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Classroom Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              isLoading
                  ? 'Loading...'
                  : 'you have ${classrooms.length} classroom${classrooms.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),

          const Divider(height: 1),

          // Classroom List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : classrooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'start creating classrooms!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: classrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = classrooms[index];
                      final isSelected = selectedClassroom?.id == classroom.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            classroom.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${classroom.schoolLevel} • Grade ${classroom.gradeLevel} • ${(enrollmentCounts[classroom.id] ?? classroom.currentStudents)}/${classroom.maxStudents} students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: Colors.blue.shade600,
                                ),
                                onPressed: () => onEditClassroom(classroom),
                                tooltip: 'Edit classroom',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () => onDeleteClassroom(classroom),
                                tooltip: 'Delete classroom',
                              ),
                            ],
                          ),
                          onTap: () => onSelectClassroom(classroom),
                        ),
                      );
                    },
                  ),
          ),

          // Create Class Button (Always visible at bottom)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCreateClassroom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'create class',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
