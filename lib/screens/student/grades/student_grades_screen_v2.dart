import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/student_grades_service.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
import 'package:oro_site_high_school/screens/student/grades/widgets/student_grades_subject_panel.dart';
import 'package:oro_site_high_school/screens/student/grades/widgets/student_grades_content_panel.dart';
import 'package:oro_site_high_school/screens/student/grades/student_report_card_screen.dart';

/// **Phase 2: Student Grades Screen V2**
/// 
/// 3-Panel Layout:
/// - Left: Grade level tree sidebar (enrolled classrooms)
/// - Middle: Subjects in selected classroom
/// - Right: Grade display with quarter selector
/// 
/// Flow: Select Classroom → Select Subject → View Grades by Quarter
class StudentGradesScreenV2 extends StatefulWidget {
  const StudentGradesScreenV2({super.key});

  @override
  State<StudentGradesScreenV2> createState() => _StudentGradesScreenV2State();
}

class _StudentGradesScreenV2State extends State<StudentGradesScreenV2> {
  final ClassroomService _classroomService = ClassroomService();
  final StudentGradesService _gradesService = StudentGradesService();

  String? _studentId;
  RealtimeChannel? _gradesChannel;

  // Left panel: Classrooms
  List<Classroom> _enrolledClassrooms = [];
  Classroom? _selectedClassroom;
  bool _isLoadingClassrooms = true;
  Map<int, bool> _expandedGrades = {};

  // Middle panel: Subjects
  List<ClassroomSubject> _subjects = [];
  ClassroomSubject? _selectedSubject;
  bool _isLoadingSubjects = false;

  // Right panel: Grades
  Map<int, Map<String, dynamic>> _quarterGrades = {};
  int _selectedQuarter = 1;
  Map<String, dynamic>? _explanation;
  bool _isLoadingGrades = false;
  bool _isLoadingExplanation = false;

  @override
  void initState() {
    super.initState();
    _initializeStudent();
  }

  @override
  void dispose() {
    _gradesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initializeStudent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() => _studentId = user.id);
        _subscribeGradesRealtime();
        await _loadEnrolledClassrooms();
      }
    } catch (e) {
      print('❌ Error initializing student: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  void _subscribeGradesRealtime() {
    _gradesChannel?.unsubscribe();
    final studentId = _studentId;
    if (studentId == null) return;

    final supabase = Supabase.instance.client;
    _gradesChannel = supabase
        .channel('student-grades:$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_grades',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (_) => _refreshGradesIfSelected(),
        )
        .subscribe();
  }

  Future<void> _loadEnrolledClassrooms() async {
    final studentId = _studentId;
    if (studentId == null) return;

    setState(() => _isLoadingClassrooms = true);

    try {
      final classrooms = await _classroomService.getStudentClassrooms(studentId);

      setState(() {
        _enrolledClassrooms = classrooms;
        _isLoadingClassrooms = false;
      });
    } catch (e) {
      print('❌ Error loading enrolled classrooms: $e');
      setState(() {
        _enrolledClassrooms = [];
        _isLoadingClassrooms = false;
      });
      _showErrorSnackBar('Failed to load classrooms. Please try again.');
    }
  }

  Future<void> _loadSubjects(String classroomId) async {
    final studentId = _studentId;
    if (studentId == null) return;

    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      _selectedSubject = null;
    });

    try {
      final subjects = await _gradesService.getClassroomSubjects(
        classroomId: classroomId,
        studentId: studentId,
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
      _showErrorSnackBar('Failed to load subjects. Please try again.');
    }
  }

  Future<void> _loadGrades() async {
    final studentId = _studentId;
    final classroom = _selectedClassroom;
    final subject = _selectedSubject;

    if (studentId == null || classroom == null || subject == null) return;

    setState(() {
      _isLoadingGrades = true;
      _quarterGrades = {};
    });

    try {
      final grades = await _gradesService.getSubjectGrades(
        studentId: studentId,
        classroomId: classroom.id,
        subjectId: subject.id,
      );

      if (mounted) {
        setState(() {
          _quarterGrades = grades;
          _isLoadingGrades = false;
        });
        await _loadExplanation();
      }
    } catch (e) {
      print('❌ Error loading grades: $e');
      if (mounted) {
        setState(() {
          _quarterGrades = {};
          _isLoadingGrades = false;
        });
        _showErrorSnackBar('Failed to load grades. Please try again.');
      }
    }
  }

  Future<void> _loadExplanation() async {
    final studentId = _studentId;
    final classroom = _selectedClassroom;
    final subject = _selectedSubject;
    final quarter = _selectedQuarter;

    if (studentId == null || classroom == null || subject == null) return;

    setState(() {
      _isLoadingExplanation = true;
      _explanation = null;
    });

    try {
      final explanation = await _gradesService.getQuarterBreakdown(
        studentId: studentId,
        classroomId: classroom.id,
        subjectId: subject.id,
        quarter: quarter,
      );

      if (mounted) {
        setState(() {
          _explanation = explanation;
          _isLoadingExplanation = false;
        });
      }
    } catch (e) {
      print('❌ Error loading explanation: $e');
      if (mounted) {
        setState(() {
          _explanation = null;
          _isLoadingExplanation = false;
        });
        _showErrorSnackBar('Failed to load grade breakdown. Please try again.');
      }
    }
  }

  void _refreshGradesIfSelected() {
    if (_selectedClassroom != null && _selectedSubject != null) {
      _loadGrades();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _handleGradeToggle(int grade) {
    setState(() {
      _expandedGrades[grade] = !(_expandedGrades[grade] ?? false);
    });
  }

  void _handleClassroomSelected(Classroom classroom) {
    setState(() {
      _selectedClassroom = classroom;
      _selectedSubject = null;
      _quarterGrades = {};
      _explanation = null;
    });
    _loadSubjects(classroom.id);
  }

  void _handleSubjectSelected(ClassroomSubject subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedQuarter = 1; // Reset to Q1
    });
    _loadGrades();
  }

  void _handleQuarterSelected(int quarter) {
    setState(() => _selectedQuarter = quarter);
    _loadExplanation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentReportCardScreen(),
              ),
            ),
            icon: const Icon(Icons.table_chart, size: 18, color: Colors.white),
            label: const Text(
              'View Report Card',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Grade Level Tree Sidebar
          ClassroomLeftSidebarStateful(
            title: 'MY GRADES',
            expandedGrades: _expandedGrades,
            onGradeToggle: _handleGradeToggle,
            allClassrooms: _enrolledClassrooms,
            selectedClassroom: _selectedClassroom,
            onClassroomSelected: _handleClassroomSelected,
            gradeCoordinators: const {},
            schoolYears: const [],
            userRole: 'student',
            isCoordinator: false,
            coordinatorGradeLevel: null,
          ),

          // Middle Panel: Subject List
          StudentGradesSubjectPanel(
            subjects: _subjects,
            selectedSubject: _selectedSubject,
            onSubjectSelected: _handleSubjectSelected,
            isLoading: _isLoadingSubjects,
          ),

          // Right Panel: Grades Content
          Expanded(
            child: _selectedSubject != null && _selectedClassroom != null
                ? StudentGradesContentPanel(
                    subject: _selectedSubject!,
                    selectedQuarter: _selectedQuarter,
                    onQuarterSelected: _handleQuarterSelected,
                    quarterGrades: _quarterGrades,
                    explanation: _explanation,
                    isLoadingGrades: _isLoadingGrades,
                    isLoadingExplanation: _isLoadingExplanation,
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_selectedClassroom == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Select a classroom to view grades',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_selectedSubject == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subject, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Select a subject to view grades',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}


