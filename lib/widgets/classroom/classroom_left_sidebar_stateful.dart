import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/models/school_year_simple.dart';

/// Stateful wrapper for ClassroomLeftSidebar that handles school year dropdown overlay
///
/// **Role-Based Filtering:**
/// - Pass `userRole: 'student'` to show only enrolled classrooms
/// - Pass `userRole: 'teacher'` to show only assigned classrooms
/// - Pass `userRole: 'admin'` or `userRole: null` to show all classrooms (backward compatible)
///
/// **Grade Level Coordinator Support:**
/// - Pass `isCoordinator: true` and `coordinatorGradeLevel` to show coordinator badge
class ClassroomLeftSidebarStateful extends StatefulWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Map<int, bool> expandedGrades;
  final Function(int grade) onGradeToggle;
  final List<Classroom> allClassrooms;
  final Classroom? selectedClassroom;
  final Function(Classroom classroom) onClassroomSelected;
  final Map<int, Teacher?> gradeCoordinators;
  final Function(int grade)? onSetGradeCoordinator;
  final Map<int, GlobalKey>? gradeButtonKeys;
  final Map<int, LayerLink>? gradeLayerLinks;
  final List<SchoolYearSimple> schoolYears;
  final String? selectedSchoolYear;
  final Function(String year)? onSchoolYearChanged;
  final VoidCallback? onAddSchoolYear;
  final bool canManageCoordinators;
  final bool canManageSchoolYears;

  /// User role for conditional UI rendering
  /// - 'student': Shows only enrolled classrooms
  /// - 'teacher': Shows only assigned classrooms
  /// - 'admin', or null: Shows all classrooms (backward compatible)
  final String? userRole;

  /// Grade level coordinator status (for teachers)
  final bool? isCoordinator;
  final int? coordinatorGradeLevel;

  const ClassroomLeftSidebarStateful({
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
    this.gradeButtonKeys,
    this.gradeLayerLinks,
    required this.schoolYears,
    this.selectedSchoolYear,
    this.onSchoolYearChanged,
    this.onAddSchoolYear,
    this.canManageCoordinators = false,
    this.canManageSchoolYears = false,
    this.userRole,
    this.isCoordinator,
    this.coordinatorGradeLevel,
  });

  @override
  State<ClassroomLeftSidebarStateful> createState() =>
      _ClassroomLeftSidebarStatefulState();
}

class _ClassroomLeftSidebarStatefulState
    extends State<ClassroomLeftSidebarStateful> {
  OverlayEntry? _schoolYearOverlay;
  final GlobalKey _schoolYearButtonKey = GlobalKey();
  final TextEditingController _schoolYearSearchController =
      TextEditingController();
  String _schoolYearSearchQuery = '';

  @override
  void dispose() {
    _closeSchoolYearMenu();
    _schoolYearSearchController.dispose();
    super.dispose();
  }

  void _openSchoolYearMenu() {
    if (_schoolYearOverlay != null) return;

    final RenderBox? renderBox =
        _schoolYearButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _schoolYearOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to detect clicks outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeSchoolYearMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Menu positioned below the button
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(6),
              child: _buildSchoolYearMenuContent(),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_schoolYearOverlay!);
  }

  void _closeSchoolYearMenu() {
    _schoolYearOverlay?.remove();
    _schoolYearOverlay = null;
    _schoolYearSearchQuery = '';
    _schoolYearSearchController.clear();
  }

  /// Check if current user is a student
  bool get _isStudent => widget.userRole?.toLowerCase() == 'student';

  /// Check if current user is a teacher
  bool get _isTeacher => widget.userRole?.toLowerCase() == 'teacher';

  /// Check if current user has admin-like permissions (can manage school years)
  /// Includes: admin, ict_coordinator, hybrid, null (backward compatible for admin screens)
  /// Excludes: teacher, student, parent, grade_coordinator
  bool get _hasAdminPermissions {
    final role = widget.userRole?.toLowerCase();
    // If userRole is null, assume admin (backward compatible)
    if (role == null) return true;
    return role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
  }

  /// Get list of grade levels to display based on user role
  ///
  /// **Role-Based Filtering:**
  /// - **Student**: Only show grades where they have enrolled classrooms
  /// - **Teacher**: Only show grades where they have assigned classrooms
  /// - **Admin** or **null**: Show all grades (7-12) - backward compatible
  List<int> get _visibleGrades {
    if (_isStudent) {
      // Student: Only show grades where they have enrolled classrooms
      final enrolledGrades = widget.allClassrooms
          .map((c) => c.gradeLevel)
          .toSet()
          .toList()
        ..sort();
      return enrolledGrades;
    }

    if (_isTeacher) {
      // Teacher: Only show grades where they have assigned classrooms
      // This is already filtered by ClassroomService.getTeacherClassrooms()
      final assignedGrades = widget.allClassrooms
          .map((c) => c.gradeLevel)
          .toSet()
          .toList()
        ..sort();
      return assignedGrades;
    }

    // Admin or null: Show all grades (backward compatible)
    return [7, 8, 9, 10, 11, 12];
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onBackPressed != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBackPressed,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                // Phase 1: Show coordinator badge in sidebar
                if (widget.isCoordinator == true && widget.coordinatorGradeLevel != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Grade ${widget.coordinatorGradeLevel} Coordinator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Grade level list with role-based filtering
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Junior High School Section (Grades 7-10)
                if (_visibleGrades.any((g) => g >= 7 && g <= 10)) ...[
                  _buildSectionHeader('JUNIOR HIGH SCHOOL', isJHS: true),
                  for (int grade = 7; grade <= 10; grade++)
                    if (_isGradeVisible(grade)) _buildGradeItem(grade),
                ],

                const SizedBox(height: 8),

                // Senior High School Section (Grades 11-12)
                if (_visibleGrades.any((g) => g >= 11 && g <= 12)) ...[
                  _buildSectionHeader('SENIOR HIGH SCHOOL', isJHS: false),
                  for (int grade = 11; grade <= 12; grade++)
                    if (_isGradeVisible(grade)) _buildGradeItem(grade),
                ],

                const SizedBox(height: 16),

                // School Year Selector
                _buildSchoolYearSelector(),
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

  Widget _buildGradeItem(int grade) {
    final isExpanded = widget.expandedGrades[grade] ?? false;
    final classrooms = widget.allClassrooms
        .where((c) => c.gradeLevel == grade)
        .toList();

    // Phase 2 Task 2.2: Check if current teacher is coordinator for this grade
    final isCoordinatorForThisGrade = widget.isCoordinator == true &&
        widget.coordinatorGradeLevel == grade;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => widget.onGradeToggle(grade),
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

                // Phase 2 Task 2.2: Coordinator badge
                if (isCoordinatorForThisGrade) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 8,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'COORDINATOR',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Plus button for grade level coordinator with badge
                if (widget.canManageCoordinators &&
                    widget.onSetGradeCoordinator != null)
                  CompositedTransformTarget(
                    link: widget.gradeLayerLinks?[grade] ?? LayerLink(),
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
                          InkWell(
                            key: widget.gradeButtonKeys?[grade],
                            onTap: () {
                              widget.onSetGradeCoordinator!(grade);
                            },
                            borderRadius: BorderRadius.circular(3),
                            child: Container(
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
                          ),
                          // Badge indicator when coordinator is set
                          if (widget.gradeCoordinators[grade] != null)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
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
        if (isExpanded) ...[
          if (classrooms.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 12, bottom: 8),
              child: Text(
                'No classrooms yet',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...classrooms.map((classroom) => _buildClassroomItem(classroom)),
        ],
      ],
    );
  }

  Widget _buildClassroomItem(Classroom classroom) {
    final isSelected = widget.selectedClassroom?.id == classroom.id;

    // Phase 2 Task 2.4: Check if current teacher is advisor for this classroom
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAdvisor = widget.userRole == 'teacher' &&
        currentUserId != null &&
        classroom.advisoryTeacherId == currentUserId;

    return InkWell(
      onTap: () => widget.onClassroomSelected(classroom),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    classroom.title,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Phase 2 Task 2.4: Advisor badge
                  if (isAdvisor) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school,
                            size: 7,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'ADVISOR',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolYearSelector() {
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

          // Conditional UI: Admin vs Non-Admin
          if (_hasAdminPermissions) ...[
            // ADMIN VIEW: Full dropdown with add button
            // Add School Year Button
            if (widget.canManageSchoolYears && widget.onAddSchoolYear != null)
              InkWell(
                onTap: widget.onAddSchoolYear,
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

            if (widget.canManageSchoolYears && widget.onAddSchoolYear != null)
              const SizedBox(height: 8),

            // School Year Dropdown (clickable)
            InkWell(
              key: _schoolYearButtonKey,
              onTap: _openSchoolYearMenu,
              child: Container(
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
                        widget.selectedSchoolYear ?? 'Select school year',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: widget.selectedSchoolYear != null
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.selectedSchoolYear != null
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
            ),
          ] else ...[
            // NON-ADMIN VIEW: Read-only display of current school year
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: Colors.purple.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.selectedSchoolYear ?? 'No school year set',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.selectedSchoolYear != null
                            ? Colors.purple.shade900
                            : Colors.purple.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchoolYearMenuContent() {
    return StatefulBuilder(
      builder: (context, setMenuState) {
        // Filter school years based on search query
        final filteredYears = widget.schoolYears.where((year) {
          final query = _schoolYearSearchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;
          return year.yearLabel.toLowerCase().contains(query);
        }).toList();

        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select School Year',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      onPressed: _closeSchoolYearMenu,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Search field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _schoolYearSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search year...',
                    hintStyle: TextStyle(
                      fontSize: 9,
                      color: Colors.purple.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 14,
                      color: Colors.purple.shade400,
                    ),
                    suffixIcon: _schoolYearSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 14,
                              color: Colors.purple.shade400,
                            ),
                            onPressed: () {
                              _schoolYearSearchController.clear();
                              setMenuState(() {
                                _schoolYearSearchQuery = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade500),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 10),
                  onChanged: (value) {
                    setMenuState(() {
                      _schoolYearSearchQuery = value;
                    });
                  },
                ),
              ),
              const Divider(height: 1),

              // School year list
              if (filteredYears.isEmpty &&
                  _schoolYearSearchQuery.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'School year not found',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.schoolYears.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No school years available',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a school year to get started',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredYears.length,
                    itemBuilder: (context, index) {
                      final year = filteredYears[index];
                      final isSelected =
                          widget.selectedSchoolYear == year.yearLabel;

                      return InkWell(
                        onTap: () {
                          _closeSchoolYearMenu();
                          if (widget.onSchoolYearChanged != null) {
                            widget.onSchoolYearChanged!(year.yearLabel);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.shade50
                                : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: Colors.purple.shade700,
                                      width: 2,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: isSelected
                                    ? Colors.purple.shade700
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  year.yearLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.purple.shade900
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.purple.shade700,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
