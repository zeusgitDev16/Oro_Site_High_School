import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/grade_coordinator_service.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_subjects_panel.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_content_tabs.dart';
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';

/// Teacher Classroom Screen V2 (NEW IMPLEMENTATION)
///
/// Unified classroom screen using reusable widgets from admin.
/// Uses the new classroom_subjects system instead of legacy courses.
///
/// **Features:**
/// - Three-panel layout (classrooms | subjects | content)
/// - Reusable widgets from admin screen
/// - Teacher-specific filtering (only assigned classrooms)
/// - Grade level coordinator support with badge
/// - RBAC-based permissions
/// - Real-time updates
/// - Backward compatible via feature flag
class MyClassroomScreenV2 extends StatefulWidget {
  const MyClassroomScreenV2({super.key});

  @override
  State<MyClassroomScreenV2> createState() => _MyClassroomScreenV2State();
}

class _MyClassroomScreenV2State extends State<MyClassroomScreenV2> {
  final ClassroomService _classroomService = ClassroomService();
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  final GradeCoordinatorService _coordinatorService = GradeCoordinatorService();

  // State
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  List<ClassroomSubject> _subjects = [];
  ClassroomSubject? _selectedSubject;
  bool _isLoadingClassrooms = true;
  bool _isLoadingSubjects = false;
  String? _teacherId;

  // Phase 1: Grade level coordinator support
  bool _isCoordinator = false;
  int? _coordinatorGradeLevel;
  bool _isLoadingCoordinator = false;

  @override
  void initState() {
    super.initState();
    _initializeTeacher();
  }

  Future<void> _initializeTeacher() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() => _teacherId = user.id);

        // Phase 1: Check coordinator status
        await _checkCoordinatorStatus();

        // Load classrooms
        await _loadClassrooms();
      } else {
        setState(() => _isLoadingClassrooms = false);
      }
    } catch (e) {
      print('❌ Error initializing teacher: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  /// Phase 1: Check if teacher is a grade level coordinator
  Future<void> _checkCoordinatorStatus() async {
    if (_teacherId == null) return;

    setState(() => _isLoadingCoordinator = true);

    try {
      // Check if teacher has an active coordinator assignment
      final gradeLevel = await _coordinatorService.getTeacherCurrentGradeAssignment(_teacherId!);

      setState(() {
        _isCoordinator = gradeLevel != null;
        _coordinatorGradeLevel = gradeLevel;
        _isLoadingCoordinator = false;
      });

      if (_isCoordinator) {
        print('✅ Teacher is Grade $gradeLevel Coordinator');
      } else {
        print('ℹ️ Teacher is not a coordinator');
      }
    } catch (e) {
      print('❌ Error checking coordinator status: $e');
      setState(() => _isLoadingCoordinator = false);
    }
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClassrooms = true);

    try {
      // getTeacherClassrooms already fetches:
      // 1. Owned classrooms (teacher_id)
      // 2. Advisory teacher classrooms (advisory_teacher_id)
      // 3. Co-teacher classrooms (classroom_teachers)
      // 4. Subject teacher classrooms (classroom_subjects)
      final classrooms = await _classroomService.getTeacherClassrooms(_teacherId!);

      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;

        // Auto-select first classroom
        if (_classrooms.isNotEmpty && _selectedClassroom == null) {
          _selectedClassroom = _classrooms.first;
          _loadSubjects();
        }
      });

      print('✅ Loaded ${_classrooms.length} classrooms for teacher');
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  /// Phase 2 Task 2.6: Load subjects with role-based filtering
  Future<void> _loadSubjects() async {
    if (_selectedClassroom == null || _teacherId == null) return;

    setState(() => _isLoadingSubjects = true);

    try {
      // Use role-based filtering for teachers
      final subjects =
          await _subjectService.getSubjectsByClassroomForTeacher(
        classroomId: _selectedClassroom!.id,
        teacherId: _teacherId!,
      );

      setState(() {
        _subjects = subjects;
        _isLoadingSubjects = false;

        // Auto-select first subject
        if (_subjects.isNotEmpty && _selectedSubject == null) {
          _selectedSubject = _subjects.first;
        }
      });
    } catch (e) {
      print('❌ Error loading subjects: $e');
      setState(() => _isLoadingSubjects = false);
    }
  }

  void _onClassroomSelected(Classroom classroom) {
    setState(() {
      _selectedClassroom = classroom;
      _selectedSubject = null;
      _subjects = [];
    });
    _loadSubjects();
  }

  void _onSubjectSelected(ClassroomSubject subject) {
    setState(() {
      _selectedSubject = subject;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('My Classrooms'),
            // Phase 1: Show coordinator badge in app bar
            if (_isCoordinator && _coordinatorGradeLevel != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Grade $_coordinatorGradeLevel Coordinator',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const TeacherDashboardScreen(),
              ),
            );
          },
        ),
      ),
      body: Row(
        children: [
          // Left Sidebar - Classrooms (Teacher View)
          // Phase 1: Pass userRole: 'teacher' for filtering
          ClassroomLeftSidebarStateful(
            title: 'MY CLASSROOMS',
            onBackPressed: null,
            expandedGrades: {}, // Not used for teacher view
            onGradeToggle: (_) {}, // Not used for teacher view
            allClassrooms: _classrooms,
            selectedClassroom: _selectedClassroom,
            onClassroomSelected: _onClassroomSelected,
            gradeCoordinators: {}, // Not used for teacher view
            schoolYears: [], // Not used for teacher view
            selectedSchoolYear: null,
            canManageCoordinators: false,
            canManageSchoolYears: false,
            userRole: 'teacher', // ✅ PHASE 1: Enable teacher filtering
            isCoordinator: _isCoordinator, // ✅ PHASE 1: Pass coordinator status
            coordinatorGradeLevel: _coordinatorGradeLevel, // ✅ PHASE 1: Pass coordinator grade
          ),

          // Middle Panel - Subjects
          if (_selectedClassroom != null)
            ClassroomSubjectsPanel(
              selectedClassroom: _selectedClassroom!,
              subjects: _subjects,
              selectedSubject: _selectedSubject,
              onSubjectSelected: _onSubjectSelected,
              userRole: 'teacher',
              userId: _teacherId,
              isLoading: _isLoadingSubjects,
            ),

          // Right Content - Subject Details
          Expanded(
            child: _selectedSubject != null && _selectedClassroom != null
                ? SubjectContentTabs(
                    subject: _selectedSubject!,
                    classroomId: _selectedClassroom!.id,
                    userRole: 'teacher',
                    userId: _teacherId,
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedClassroom == null
                ? 'Select a classroom to get started'
                : 'No subjects in this classroom yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

