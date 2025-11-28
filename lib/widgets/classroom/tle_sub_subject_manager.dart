import 'package:flutter/material.dart';
import '../../models/classroom_subject.dart';
import '../../models/teacher.dart';
import '../../services/classroom_subject_service.dart';
import '../../services/teacher_service.dart';
import '../../services/student_subject_enrollment_service.dart';

/// TLE Sub-Subject Manager Widget
/// 
/// Manages TLE sub-subjects (admin-configurable, not hardcoded like MAPEH).
/// Allows adding custom TLE sub-subjects, assigning teachers, and deleting
/// sub-subjects (only if no students are enrolled).
/// 
/// **Features:**
/// - Display list of TLE sub-subjects
/// - Add custom TLE sub-subject with name input
/// - Teacher assignment dropdown for each sub-subject
/// - Delete sub-subject (only if no students enrolled)
/// - Show student enrollment count per sub-subject
/// - Loading states and error handling
/// - Design matches existing classroom UI patterns
class TLESubSubjectManager extends StatefulWidget {
  final String classroomId;
  final String tleParentId;
  final VoidCallback? onSubjectUpdated;

  const TLESubSubjectManager({
    super.key,
    required this.classroomId,
    required this.tleParentId,
    this.onSubjectUpdated,
  });

  @override
  State<TLESubSubjectManager> createState() => _TLESubSubjectManagerState();
}

class _TLESubSubjectManagerState extends State<TLESubSubjectManager> {
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  final TeacherService _teacherService = TeacherService();
  final StudentSubjectEnrollmentService _enrollmentService = StudentSubjectEnrollmentService();
  final TextEditingController _subjectNameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingTeachers = false;
  bool _isAddingSubject = false;
  List<ClassroomSubject> _tleSubSubjects = [];
  List<Teacher> _availableTeachers = [];
  Map<String, int> _enrollmentCounts = {}; // subjectId -> count
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  /// Load TLE sub-subjects, teachers, and enrollment counts
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔧 [TLEManager] Loading TLE sub-subjects for parent: ${widget.tleParentId}');
      
      // Load sub-subjects and teachers in parallel
      await Future.wait([
        _loadTLESubSubjects(),
        _loadTeachers(),
      ]);

      // Load enrollment counts for each sub-subject
      await _loadEnrollmentCounts();

      print('✅ [TLEManager] Data loaded successfully');
    } catch (e) {
      print('❌ [TLEManager] Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load TLE sub-subjects. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load TLE sub-subjects from database
  Future<void> _loadTLESubSubjects() async {
    try {
      final subSubjects = await _subjectService.getSubSubjects(
        parentSubjectId: widget.tleParentId,
      );

      if (mounted) {
        setState(() {
          _tleSubSubjects = subSubjects;
        });
      }

      print('✅ [TLEManager] Loaded ${subSubjects.length} TLE sub-subjects');
    } catch (e) {
      print('❌ [TLEManager] Error loading TLE sub-subjects: $e');
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

      print('✅ [TLEManager] Loaded ${teachers.length} teachers');
    } catch (e) {
      print('❌ [TLEManager] Error loading teachers: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeachers = false;
        });
      }
    }
  }

  /// Load enrollment counts for each TLE sub-subject
  Future<void> _loadEnrollmentCounts() async {
    try {
      final counts = <String, int>{};

      // Get all enrollments for this classroom
      final allEnrollments = await _enrollmentService.getClassroomEnrollments(
        classroomId: widget.classroomId,
        tleParentId: widget.tleParentId,
      );

      // Count enrollments per sub-subject
      for (final subSubject in _tleSubSubjects) {
        final count = allEnrollments
            .where((e) => e.enrolledSubjectId == subSubject.id)
            .length;
        counts[subSubject.id] = count;
      }

      if (mounted) {
        setState(() {
          _enrollmentCounts = counts;
        });
      }

      print('✅ [TLEManager] Loaded enrollment counts: $counts');
    } catch (e) {
      print('❌ [TLEManager] Error loading enrollment counts: $e');
      // Don't rethrow - enrollment counts are not critical
    }
  }

  /// Add a new TLE sub-subject
  Future<void> _addTLESubSubject() async {
    final subjectName = _subjectNameController.text.trim();

    if (subjectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a subject name'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    setState(() {
      _isAddingSubject = true;
    });

    try {
      print('➕ [TLEManager] Adding TLE sub-subject: $subjectName');

      await _subjectService.addTLESubSubject(
        classroomId: widget.classroomId,
        tleParentId: widget.tleParentId,
        subjectName: subjectName,
      );

      // Clear input field
      _subjectNameController.clear();

      // Reload data
      await _loadData();

      // Notify parent widget
      widget.onSubjectUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TLE sub-subject "$subjectName" added successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      print('✅ [TLEManager] TLE sub-subject added successfully');
    } catch (e) {
      print('❌ [TLEManager] Error adding TLE sub-subject: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding TLE sub-subject: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingSubject = false;
        });
      }
    }
  }

  /// Assign teacher to a TLE sub-subject
  Future<void> _assignTeacher(ClassroomSubject subSubject, String? teacherId) async {
    try {
      print('👨‍🏫 [TLEManager] Assigning teacher to ${subSubject.subjectName}');

      await _subjectService.updateSubject(
        subjectId: subSubject.id,
        teacherId: teacherId,
      );

      // Reload data
      await _loadTLESubSubjects();

      // Notify parent widget
      widget.onSubjectUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teacher assigned to ${subSubject.subjectName}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      print('✅ [TLEManager] Teacher assigned successfully');
    } catch (e) {
      print('❌ [TLEManager] Error assigning teacher: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning teacher: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Delete a TLE sub-subject (only if no students enrolled)
  Future<void> _deleteTLESubSubject(ClassroomSubject subSubject) async {
    final enrollmentCount = _enrollmentCounts[subSubject.id] ?? 0;

    if (enrollmentCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete "${subSubject.subjectName}". $enrollmentCount student(s) are enrolled.',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete TLE Sub-Subject'),
        content: Text(
          'Are you sure you want to delete "${subSubject.subjectName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      print('🗑️ [TLEManager] Deleting TLE sub-subject: ${subSubject.subjectName}');

      await _subjectService.deleteSubject(subSubject.id);

      // Reload data
      await _loadData();

      // Notify parent widget
      widget.onSubjectUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TLE sub-subject "${subSubject.subjectName}" deleted'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }

      print('✅ [TLEManager] TLE sub-subject deleted successfully');
    } catch (e) {
      print('❌ [TLEManager] Error deleting TLE sub-subject: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting TLE sub-subject: $e'),
            backgroundColor: Colors.red.shade700,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading TLE sub-subjects...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildAddSubjectSection(),
        const SizedBox(height: 16),
        if (_tleSubSubjects.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: ListView.builder(
              itemCount: _tleSubSubjects.length,
              itemBuilder: (context, index) {
                return _buildSubSubjectItem(_tleSubSubjects[index]);
              },
            ),
          ),
      ],
    );
  }

  /// Build header with title and count badge
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.construction,
            size: 20,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'TLE Sub-Subjects',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_tleSubSubjects.length}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// Build add subject section
  Widget _buildAddSubjectSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _subjectNameController,
              decoration: InputDecoration(
                hintText: 'Enter TLE sub-subject name (e.g., Carpentry, Cooking)',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 12),
              enabled: !_isAddingSubject,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isAddingSubject ? null : _addTLESubSubject,
            icon: _isAddingSubject
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, size: 16),
            label: Text(
              _isAddingSubject ? 'Adding...' : 'Add',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No TLE sub-subjects yet',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add custom TLE sub-subjects using the form above',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build individual TLE sub-subject item
  Widget _buildSubSubjectItem(ClassroomSubject subSubject) {
    final enrollmentCount = _enrollmentCounts[subSubject.id] ?? 0;
    final canDelete = enrollmentCount == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.construction,
              size: 20,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          // Subject name and enrollment count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subSubject.subjectName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$enrollmentCount student${enrollmentCount != 1 ? 's' : ''} enrolled',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Teacher dropdown
          SizedBox(
            width: 180,
            child: _buildTeacherDropdown(subSubject),
          ),
          const SizedBox(width: 8),
          // Delete button
          Tooltip(
            message: canDelete
                ? 'Delete sub-subject'
                : 'Cannot delete: $enrollmentCount student(s) enrolled',
            child: IconButton(
              onPressed: canDelete ? () => _deleteTLESubSubject(subSubject) : null,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: canDelete ? Colors.red.shade700 : Colors.grey.shade400,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build teacher dropdown for a TLE sub-subject
  Widget _buildTeacherDropdown(ClassroomSubject subSubject) {
    if (_isLoadingTeachers) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: subSubject.teacherId,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        prefixIcon: const Icon(Icons.person, size: 16),
      ),
      style: const TextStyle(fontSize: 11, color: Colors.black87),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Unassigned'),
        ),
        ..._availableTeachers.map((teacher) {
          return DropdownMenuItem<String?>(
            value: teacher.id,
            child: Text(teacher.displayName),
          );
        }),
      ],
      onChanged: (newTeacherId) {
        _assignTeacher(subSubject, newTeacherId);
      },
    );
  }
}

