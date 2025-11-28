import 'package:flutter/material.dart';
import '../../models/classroom_subject.dart';
import '../../models/teacher.dart';
import '../../services/classroom_subject_service.dart';
import '../../services/teacher_service.dart';

/// MAPEH Sub-Subject Manager Widget
/// 
/// Displays the 4 hardcoded MAPEH sub-subjects (Music, Arts, PE, Health)
/// and allows teacher assignment for each sub-subject.
/// 
/// **Features:**
/// - Display 4 MAPEH sub-subjects in a list
/// - Teacher assignment dropdown for each sub-subject
/// - Lock icon to prevent deletion (MAPEH sub-subjects cannot be deleted)
/// - Loading states and error handling
/// - Design matches existing classroom UI patterns
class MAPEHSubSubjectManager extends StatefulWidget {
  final String classroomId;
  final String mapehParentId;
  final VoidCallback? onSubjectUpdated;

  const MAPEHSubSubjectManager({
    super.key,
    required this.classroomId,
    required this.mapehParentId,
    this.onSubjectUpdated,
  });

  @override
  State<MAPEHSubSubjectManager> createState() => _MAPEHSubSubjectManagerState();
}

class _MAPEHSubSubjectManagerState extends State<MAPEHSubSubjectManager> {
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  final TeacherService _teacherService = TeacherService();

  bool _isLoading = false;
  bool _isLoadingTeachers = false;
  List<ClassroomSubject> _mapehSubSubjects = [];
  List<Teacher> _availableTeachers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load MAPEH sub-subjects and available teachers
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📚 [MAPEHManager] Loading MAPEH sub-subjects for parent: ${widget.mapehParentId}');
      
      // Load sub-subjects and teachers in parallel
      await Future.wait([
        _loadMAPEHSubSubjects(),
        _loadTeachers(),
      ]);

      print('✅ [MAPEHManager] Data loaded successfully');
    } catch (e) {
      print('❌ [MAPEHManager] Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load MAPEH sub-subjects. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load MAPEH sub-subjects from database
  Future<void> _loadMAPEHSubSubjects() async {
    try {
      final subSubjects = await _subjectService.getSubSubjects(
        parentSubjectId: widget.mapehParentId,
      );

      if (mounted) {
        setState(() {
          _mapehSubSubjects = subSubjects;
        });
      }

      print('✅ [MAPEHManager] Loaded ${subSubjects.length} MAPEH sub-subjects');
    } catch (e) {
      print('❌ [MAPEHManager] Error loading MAPEH sub-subjects: $e');
      rethrow;
    }
  }

  /// Load available teachers
  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final teachers = await _teacherService.getAllTeachers();

      if (mounted) {
        setState(() {
          _availableTeachers = teachers;
          _isLoadingTeachers = false;
        });
      }

      print('✅ [MAPEHManager] Loaded ${teachers.length} teachers');
    } catch (e) {
      print('❌ [MAPEHManager] Error loading teachers: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeachers = false;
        });
      }
    }
  }

  /// Assign teacher to a MAPEH sub-subject
  Future<void> _assignTeacher(ClassroomSubject subSubject, String? teacherId) async {
    try {
      print('👨‍🏫 [MAPEHManager] Assigning teacher $teacherId to ${subSubject.subjectName}');

      await _subjectService.updateSubject(
        subjectId: subSubject.id,
        teacherId: teacherId,
      );

      print('✅ [MAPEHManager] Teacher assigned successfully');

      // Reload data
      await _loadMAPEHSubSubjects();

      // Notify parent widget
      widget.onSubjectUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher assigned to ${subSubject.subjectName}'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [MAPEHManager] Error assigning teacher: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign teacher: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return _buildContent();
  }

  /// Build loading state
  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading MAPEH sub-subjects...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Sub-subjects list
          if (_mapehSubSubjects.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _mapehSubSubjects.length,
                itemBuilder: (context, index) {
                  return _buildSubSubjectItem(_mapehSubSubjects[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Build header
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.music_note,
          size: 20,
          color: Colors.blue.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          'MAPEH Sub-Subjects',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 0.5,
            ),
          ),
          child: Text(
            '${_mapehSubSubjects.length}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No MAPEH sub-subjects found',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MAPEH sub-subjects should be auto-created',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sub-subject item
  Widget _buildSubSubjectItem(ClassroomSubject subSubject) {
    // Get icon for sub-subject
    IconData subjectIcon;
    switch (subSubject.subjectName) {
      case 'Music':
        subjectIcon = Icons.music_note;
        break;
      case 'Arts':
        subjectIcon = Icons.palette;
        break;
      case 'Physical Education (PE)':
        subjectIcon = Icons.sports_basketball;
        break;
      case 'Health':
        subjectIcon = Icons.favorite;
        break;
      default:
        subjectIcon = Icons.insert_drive_file;
    }

    // Get assigned teacher name
    Teacher? assignedTeacher;
    if (subSubject.teacherId != null) {
      try {
        assignedTeacher = _availableTeachers.firstWhere(
          (t) => t.id == subSubject.teacherId,
        );
      } catch (e) {
        // Teacher not found in list
        assignedTeacher = null;
      }
    }

    final teacherName = assignedTeacher != null
        ? assignedTeacher.displayName
        : 'No teacher assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Sub-subject icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              subjectIcon,
              size: 20,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),

          // Sub-subject info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subSubject.subjectName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lock icon (cannot delete MAPEH sub-subjects)
                    Tooltip(
                      message: 'MAPEH sub-subjects cannot be deleted',
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Teacher dropdown
                _buildTeacherDropdown(subSubject, teacherName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build teacher dropdown
  Widget _buildTeacherDropdown(ClassroomSubject subSubject, String currentTeacherName) {
    if (_isLoadingTeachers) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Loading teachers...',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: subSubject.teacherId,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        isDense: true,
        prefixIcon: Icon(
          Icons.person,
          size: 16,
          color: Colors.grey.shade600,
        ),
      ),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.black87,
      ),
      dropdownColor: Colors.white,
      items: [
        // Unassigned option
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'Unassigned',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        // Teacher options
        ..._availableTeachers.map((teacher) {
          return DropdownMenuItem<String?>(
            value: teacher.id,
            child: Text(
              teacher.displayName,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (String? newTeacherId) {
        _assignTeacher(subSubject, newTeacherId);
      },
      hint: Text(
        'Select teacher',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
