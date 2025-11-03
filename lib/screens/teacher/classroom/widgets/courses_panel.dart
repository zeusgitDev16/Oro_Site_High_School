import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/course.dart';

class MyClassroomCoursesPanel extends StatelessWidget {
  const MyClassroomCoursesPanel({
    super.key,
    required this.isLoading,
    required this.courses,
    required this.selectedCourse,
    required this.onSelectCourse,
    required this.onRemoveCourse,
  });

  final bool isLoading;
  final List<Course> courses;
  final Course? selectedCourse;
  final void Function(Course c) onSelectCourse;
  final void Function(Course c) onRemoveCourse;

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'courses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Divider(height: 1),

          // Courses List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : courses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No courses added yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          final isSelected = selectedCourse?.id == course.id;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                course.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () => onRemoveCourse(course),
                                tooltip: 'Remove course from classroom',
                              ),
                              onTap: () => onSelectCourse(course),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
