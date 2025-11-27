import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/models/school_year_simple.dart';

/// Reusable left sidebar for classroom management
/// Can be used across admin, teacher, and student screens with RLS filtering
///
/// **Role-Based Filtering:**
/// - **Student**: Only shows grade levels and classrooms where student is enrolled
/// - **Teacher/Admin**: Shows all grade levels and classrooms (existing behavior)
class ClassroomLeftSidebar extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Map<int, bool> expandedGrades;
  final Function(int grade) onGradeToggle;
  final List<Classroom> allClassrooms;
  final Classroom? selectedClassroom;
  final Function(Classroom classroom) onClassroomSelected;
  final Map<int, Teacher?> gradeCoordinators;
  final Function(int grade)? onSetGradeCoordinator;
  final List<SchoolYearSimple> schoolYears;
  final String? selectedSchoolYear;
  final Function(String year)? onSchoolYearChanged;
  final VoidCallback? onAddSchoolYear;
  final bool canManageCoordinators;
  final bool canManageSchoolYears;

  /// User role for conditional UI rendering
  /// - 'student': Shows only enrolled classrooms
  /// - 'teacher', 'admin', or null: Shows all classrooms (backward compatible)
  final String? userRole;

  const ClassroomLeftSidebar({
    super.key,
    required this.title,
    this.onBackPressed,
    required this.expandedGrades,
    required this.onGradeToggle,
    required this.allClassrooms,
    this.selectedClassroom,
    required this.onClassroomSelected,
    required this.gradeCoordinators,
    this.onSetGradeCoordinator,
    required this.schoolYears,
    this.selectedSchoolYear,
    this.onSchoolYearChanged,
    this.onAddSchoolYear,
    this.canManageCoordinators = false,
    this.canManageSchoolYears = false,
    this.userRole,
  });

  /// Check if current user is a student
  bool get _isStudent => userRole?.toLowerCase() == 'student';

  /// Get list of grade levels where student has enrolled classrooms
  /// Returns all grades (7-12) for non-students (backward compatible)
  List<int> get _visibleGrades {
    if (!_isStudent) {
      // Admin/Teacher: Show all grades (backward compatible)
      return [7, 8, 9, 10, 11, 12];
    }

    // Student: Only show grades where they have enrolled classrooms
    final enrolledGrades = allClassrooms
        .map((c) => c.gradeLevel)
        .toSet()
        .toList()
      ..sort();

    return enrolledGrades;
  }

  /// Check if a grade level should be visible
  bool _isGradeVisible(int grade) {
    return _visibleGrades.contains(grade);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (onBackPressed != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBackPressed,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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

          // Grade level list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Junior High School Section (Grades 7-10)
                if (_visibleGrades.any((g) => g >= 7 && g <= 10)) ...[
                  _buildSectionHeader('JUNIOR HIGH SCHOOL', isJHS: true),
                  for (int grade = 7; grade <= 10; grade++)
                    if (_isGradeVisible(grade)) _buildGradeItem(context, grade),
                ],

                const SizedBox(height: 8),

                // Senior High School Section (Grades 11-12)
                if (_visibleGrades.any((g) => g >= 11 && g <= 12)) ...[
                  _buildSectionHeader('SENIOR HIGH SCHOOL', isJHS: false),
                  for (int grade = 11; grade <= 12; grade++)
                    if (_isGradeVisible(grade)) _buildGradeItem(context, grade),
                ],

                const SizedBox(height: 16),

                // School Year Selector
                _buildSchoolYearSelector(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool isJHS}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // Light blue
            Color(0xFFBBDEFB), // Slightly darker light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildGradeItem(BuildContext context, int grade) {
    final isExpanded = expandedGrades[grade] ?? false;
    // Filter classrooms for this grade level
    final classrooms = allClassrooms
        .where((c) => c.gradeLevel == grade)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onGradeToggle(grade),
          hoverColor: Colors.grey.shade100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Grade $grade',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),

                // Plus button for grade level coordinator (only if permission)
                if (canManageCoordinators && onSetGradeCoordinator != null)
                  GestureDetector(
                    onTap: () {
                      // Stop event propagation to parent InkWell
                      onSetGradeCoordinator!(grade);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Tooltip(
                      message: 'Set grade coordinator',
                      textStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      waitDuration: const Duration(milliseconds: 500),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                          ),
                          // Badge indicator when coordinator is set
                          if (gradeCoordinators[grade] != null)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Classroom count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: classrooms.isEmpty
                        ? Colors.grey.shade200
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: classrooms.isEmpty
                          ? Colors.grey.shade300
                          : Colors.blue.shade200,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${classrooms.length}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: classrooms.isEmpty
                          ? Colors.grey.shade600
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded classroom list
        if (isExpanded && classrooms.isNotEmpty)
          ...classrooms.map((classroom) => _buildClassroomItem(classroom)),
      ],
    );
  }

  Widget _buildClassroomItem(Classroom classroom) {
    final isSelected = selectedClassroom?.id == classroom.id;

    return InkWell(
      onTap: () => onClassroomSelected(classroom),
      hoverColor: Colors.blue.shade50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : null,
          border: isSelected
              ? Border(left: BorderSide(color: Colors.blue.shade700, width: 2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.class_,
              size: 12,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                classroom.title,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolYearSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'SCHOOL YEAR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Add School Year Button (only if permission)
          if (canManageSchoolYears && onAddSchoolYear != null)
            InkWell(
              onTap: onAddSchoolYear,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.purple.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Add school year',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (canManageSchoolYears && onAddSchoolYear != null)
            const SizedBox(height: 8),

          // School Year Dropdown (simplified - actual selection handled by parent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purple.shade300, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedSchoolYear ?? 'Select school year',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selectedSchoolYear != null
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selectedSchoolYear != null
                          ? Colors.purple.shade900
                          : Colors.purple.shade400,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.purple.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
