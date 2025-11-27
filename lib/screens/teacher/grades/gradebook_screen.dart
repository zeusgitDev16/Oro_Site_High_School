import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/grade_coordinator_service.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
import 'package:oro_site_high_school/widgets/gradebook/gradebook_subject_list.dart';
import 'package:oro_site_high_school/widgets/gradebook/gradebook_grid_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// **Phase 4: Teacher Gradebook Screen**
/// 
/// 3-Panel Layout:
/// - Left: Grade level tree sidebar (reused from classroom)
/// - Middle: Subjects assigned to teacher
/// - Right: Gradebook grid with students and assignments
/// 
/// Flow: Select Classroom → Select Subject → View Gradebook Grid
class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  final ClassroomService _classroomService = ClassroomService();
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  final GradeCoordinatorService _coordinatorService = GradeCoordinatorService();

  String? _teacherId;
  List<Classroom> _allClassrooms = [];
  Classroom? _selectedClassroom;
  List<ClassroomSubject> _subjects = [];
  ClassroomSubject? _selectedSubject;

  bool _isLoadingClassrooms = true;
  bool _isLoadingSubjects = false;

  // Grade level coordinator support
  bool _isCoordinator = false;
  int? _coordinatorGradeLevel;

  // Sidebar state
  Map<int, bool> _expandedGrades = {};

  void _handleGradeToggle(int grade) {
    setState(() {
      _expandedGrades[grade] = !(_expandedGrades[grade] ?? false);
    });
  }

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
        
        // Check coordinator status
        await _checkCoordinatorStatus();
        
        // Load classrooms
        await _loadClassrooms();
      }
    } catch (e) {
      print('❌ Error initializing teacher: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  Future<void> _checkCoordinatorStatus() async {
    if (_teacherId == null) return;

    try {
      final gradeLevel = await _coordinatorService.getTeacherCurrentGradeAssignment(_teacherId!);
      setState(() {
        _isCoordinator = gradeLevel != null;
        _coordinatorGradeLevel = gradeLevel;
      });
    } catch (e) {
      print('❌ Error checking coordinator status: $e');
    }
  }

  Future<void> _loadClassrooms() async {
    if (_teacherId == null) return;
    
    setState(() => _isLoadingClassrooms = true);
    
    try {
      final classrooms = await _classroomService.getTeacherClassrooms(_teacherId!);
      setState(() {
        _allClassrooms = classrooms;
        _isLoadingClassrooms = false;
      });
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _allClassrooms = [];
        _isLoadingClassrooms = false;
      });
    }
  }

  /// Phase 2 Task 2.6: Load subjects with role-based filtering
  Future<void> _loadSubjects(String classroomId) async {
    if (_teacherId == null) return;

    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      _selectedSubject = null;
    });

    try {
      // Use role-based filtering for teachers
      final subjects = await _subjectService.getSubjectsByClassroomForTeacher(
        classroomId: classroomId,
        teacherId: _teacherId!,
      );

      setState(() {
        _subjects = subjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
      print('❌ Error loading subjects: $e');
      setState(() {
        _subjects = [];
        _isLoadingSubjects = false;
      });
    }
  }

  void _handleClassroomSelected(Classroom classroom) {
    setState(() {
      _selectedClassroom = classroom;
      _selectedSubject = null;
    });
    _loadSubjects(classroom.id);
  }

  void _handleSubjectSelected(ClassroomSubject subject) {
    setState(() => _selectedSubject = subject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gradebook'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left Panel: Grade Level Tree Sidebar
          ClassroomLeftSidebarStateful(
            title: 'GRADEBOOK',
            expandedGrades: _expandedGrades,
            onGradeToggle: _handleGradeToggle,
            allClassrooms: _allClassrooms,
            selectedClassroom: _selectedClassroom,
            onClassroomSelected: _handleClassroomSelected,
            gradeCoordinators: const {},
            schoolYears: const [],
            userRole: 'teacher',
            isCoordinator: _isCoordinator,
            coordinatorGradeLevel: _coordinatorGradeLevel,
          ),
          
          // Middle Panel: Subject List
          GradebookSubjectList(
            subjects: _subjects,
            selectedSubject: _selectedSubject,
            onSubjectSelected: _handleSubjectSelected,
            isLoading: _isLoadingSubjects,
          ),
          
          // Right Panel: Gradebook Grid
          Expanded(
            child: _selectedSubject != null && _selectedClassroom != null
                ? GradebookGridPanel(
                    classroom: _selectedClassroom!,
                    subject: _selectedSubject!,
                    teacherId: _teacherId!,
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
          Icon(Icons.grade, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Select a classroom and subject to view gradebook',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

