import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_subjects_panel.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_content_tabs.dart';
import 'package:oro_site_high_school/screens/student/dashboard/student_dashboard_screen.dart';

/// Student Classroom Screen V2 (NEW IMPLEMENTATION)
/// 
/// Unified classroom screen using reusable widgets from admin.
/// Uses the new classroom_subjects system instead of legacy courses.
/// 
/// **Features:**
/// - Three-panel layout (classrooms | subjects | content)
/// - Reusable widgets from admin screen
/// - Read-only view with submission capabilities
/// - Real-time updates
/// - Backward compatible via feature flag
class StudentClassroomScreenV2 extends StatefulWidget {
  const StudentClassroomScreenV2({super.key});

  @override
  State<StudentClassroomScreenV2> createState() => _StudentClassroomScreenV2State();
}

class _StudentClassroomScreenV2State extends State<StudentClassroomScreenV2> {
  final ClassroomService _classroomService = ClassroomService();
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  final TeacherService _teacherService = TeacherService();

  // State
  List<Classroom> _classrooms = [];
  Classroom? _selectedClassroom;
  List<ClassroomSubject> _subjects = [];
  ClassroomSubject? _selectedSubject;
  bool _isLoadingClassrooms = true;
  bool _isLoadingSubjects = false;
  String? _studentId;

  // Phase 2: Classroom details
  Teacher? _advisoryTeacher;
  Map<String, Teacher> _subjectTeachers = {}; // subjectId -> Teacher
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _initializeStudent();
  }

  Future<void> _initializeStudent() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() => _studentId = user.id);
        await _loadClassrooms();
      } else {
        setState(() => _isLoadingClassrooms = false);
      }
    } catch (e) {
      print('❌ Error initializing student: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClassrooms = true);

    try {
      final classrooms = await _classroomService.getStudentClassrooms(_studentId!);
      
      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;
        
        // Auto-select first classroom
        if (_classrooms.isNotEmpty && _selectedClassroom == null) {
          _selectedClassroom = _classrooms.first;
          _loadSubjects();
        }
      });
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() => _isLoadingClassrooms = false);
    }
  }

  Future<void> _loadSubjects() async {
    if (_selectedClassroom == null) return;

    setState(() => _isLoadingSubjects = true);

    try {
      final subjects = await _subjectService.getSubjectsByClassroom(
        _selectedClassroom!.id,
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

  /// Phase 2: Load teacher information for selected classroom
  Future<void> _loadTeacherInfo(Classroom classroom) async {
    setState(() {
      _isLoadingTeachers = true;
      _advisoryTeacher = null;
      _subjectTeachers.clear();
    });

    try {
      // Load advisory teacher if assigned
      if (classroom.advisoryTeacherId != null) {
        final teacher = await _teacherService.getTeacherById(
          classroom.advisoryTeacherId!,
        );
        if (mounted && teacher != null) {
          setState(() => _advisoryTeacher = teacher);
        }
      }

      // Load subject teachers
      final subjects = await _subjectService.getSubjectsByClassroom(classroom.id);
      final teacherIds = subjects
          .where((s) => s.teacherId != null)
          .map((s) => s.teacherId!)
          .toSet();

      for (final teacherId in teacherIds) {
        final teacher = await _teacherService.getTeacherById(teacherId);
        if (teacher != null) {
          // Map teacher to all subjects they teach
          for (final subject in subjects) {
            if (subject.teacherId == teacherId) {
              _subjectTeachers[subject.id] = teacher;
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isLoadingTeachers = false);
      }
    } catch (e) {
      print('❌ Error loading teacher info: $e');
      if (mounted) {
        setState(() => _isLoadingTeachers = false);
      }
    }
  }

  void _onClassroomSelected(Classroom classroom) {
    setState(() {
      _selectedClassroom = classroom;
      _selectedSubject = null;
      _subjects = [];
    });
    _loadSubjects();
    _loadTeacherInfo(classroom); // Phase 2: Load teacher information
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
        title: const Text('My Classrooms'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentDashboardScreen(),
              ),
            );
          },
        ),
      ),
      body: Row(
        children: [
          // Left Sidebar - Classrooms (Student View)
          // Only shows grade levels and classrooms where student is enrolled
          ClassroomLeftSidebarStateful(
            title: 'MY CLASSROOMS',
            onBackPressed: null,
            expandedGrades: {}, // Not used for student view
            onGradeToggle: (_) {}, // Not used for student view
            allClassrooms: _classrooms,
            selectedClassroom: _selectedClassroom,
            onClassroomSelected: _onClassroomSelected,
            gradeCoordinators: {}, // Not used for student view
            schoolYears: [], // Not used for student view
            selectedSchoolYear: null,
            canManageCoordinators: false,
            canManageSchoolYears: false,
            userRole: 'student', // ✅ PHASE 1: Enable student filtering
          ),

          // Middle Panel - Subjects
          if (_selectedClassroom != null)
            ClassroomSubjectsPanel(
              selectedClassroom: _selectedClassroom!,
              subjects: _subjects,
              selectedSubject: _selectedSubject,
              onSubjectSelected: _onSubjectSelected,
              userRole: 'student',
              userId: _studentId,
              isLoading: _isLoadingSubjects,
            ),

          // Right Content - Subject Details or Classroom Details
          Expanded(
            child: _selectedSubject != null && _selectedClassroom != null
                ? SubjectContentTabs(
                    subject: _selectedSubject!,
                    classroomId: _selectedClassroom!.id,
                    userRole: 'student',
                    userId: _studentId,
                  )
                : _selectedClassroom != null
                    ? _buildClassroomDetailsView() // Phase 2: Show classroom details
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  /// Phase 2: Build classroom details view for students
  Widget _buildClassroomDetailsView() {
    if (_selectedClassroom == null) return _buildEmptyState();

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClassroom!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grade ${_selectedClassroom!.gradeLevel} • ${_selectedClassroom!.schoolLevel}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Basic Information
            _buildDetailSection('Basic Information', [
              _buildDetailRow('School Year', _selectedClassroom!.schoolYear),
              _buildDetailRow('Grade Level', 'Grade ${_selectedClassroom!.gradeLevel}'),
              _buildDetailRow('School Level', _selectedClassroom!.schoolLevel),
              if (_selectedClassroom!.academicTrack != null)
                _buildDetailRow('Academic Track', _selectedClassroom!.academicTrack!),
            ]),
            const SizedBox(height: 24),

            // Advisory Teacher
            _buildDetailSection('Advisory Teacher', [
              _isLoadingTeachers
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _buildTeacherCard(
                      _advisoryTeacher?.displayName ?? 'Not assigned',
                      _advisoryTeacher?.email,
                      'Advisory Teacher',
                    ),
            ]),
            const SizedBox(height: 24),

            // Subject Teachers
            if (_subjects.isNotEmpty) ...[
              _buildDetailSection('Subject Teachers', [
                _isLoadingTeachers
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Column(
                        children: _subjects.map((subject) {
                          final teacher = _subjectTeachers[subject.id];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTeacherCard(
                              teacher?.displayName ?? 'Not assigned',
                              teacher?.email,
                              subject.subjectName,
                            ),
                          );
                        }).toList(),
                      ),
              ]),
              const SizedBox(height: 24),
            ],

            // Enrollment Info
            _buildDetailSection('Enrollment', [
              _buildDetailRow('Status', 'Enrolled', valueColor: Colors.green),
              _buildDetailRow(
                'Class Size',
                '${_selectedClassroom!.currentStudents}/${_selectedClassroom!.maxStudents} students',
              ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(String name, String? email, String role) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase(),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
            'Select a classroom to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

