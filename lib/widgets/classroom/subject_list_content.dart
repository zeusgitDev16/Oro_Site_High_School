import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_resources_content.dart';

/// Reusable widget that displays the list of subjects and shows SubjectResourcesContent when clicked
/// This is Content 1 - the main content area that displays Content 2 (SubjectResourcesContent)
class SubjectListContent extends StatefulWidget {
  final String? classroomId;

  const SubjectListContent({super.key, this.classroomId});

  @override
  State<SubjectListContent> createState() => _SubjectListContentState();
}

class _SubjectListContentState extends State<SubjectListContent> {
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  Map<String, List<ClassroomSubject>> _subjects = {};
  ClassroomSubject? _selectedSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void didUpdateWidget(SubjectListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload subjects if classroomId changed
    if (oldWidget.classroomId != widget.classroomId) {
      _loadSubjects();
    }
  }

  /// Load subjects based on mode (CREATE or EDIT)
  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.classroomId == null) {
        // CREATE mode - load from SharedPreferences
        await _loadTemporarySubjects();
      } else {
        // EDIT mode - load from database
        await _loadDatabaseSubjects();
      }
    } catch (e) {
      print('❌ Error loading subjects: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load temporary subjects from SharedPreferences (CREATE mode)
  Future<void> _loadTemporarySubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subjectsJson = prefs.getString('temp_classroom_subjects');

      if (subjectsJson != null) {
        final Map<String, dynamic> decoded = json.decode(subjectsJson);

        if (mounted) {
          setState(() {
            _subjects.clear();
            for (final entry in decoded.entries) {
              final subjectName = entry.key;
              final List<dynamic> subjectsList = entry.value;

              _subjects[subjectName] = subjectsList
                  .map((json) => ClassroomSubject.fromJson(json))
                  .toList();
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error loading temporary subjects: $e');
    }
  }

  /// Load subjects from database (EDIT mode)
  Future<void> _loadDatabaseSubjects() async {
    try {
      final subjects = await _subjectService.getSubjectsByClassroom(
        widget.classroomId!,
      );

      if (mounted) {
        setState(() {
          _subjects.clear();
          // Group subjects by subject name
          for (final subject in subjects) {
            if (!_subjects.containsKey(subject.subjectName)) {
              _subjects[subject.subjectName] = [];
            }
            _subjects[subject.subjectName]!.add(subject);
          }
        });
      }
    } catch (e) {
      print('❌ Error loading database subjects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no subject selected, show subject list
    if (_selectedSubject == null) {
      return _buildSubjectList();
    }

    // If subject selected, show SubjectResourcesContent (Content 2)
    return _buildSubjectResourcesView();
  }

  /// Build the subject list view
  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects added yet',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    // Get all parent subjects (subjects without parentSubjectId)
    final parentSubjects = <ClassroomSubject>[];
    for (final subjects in _subjects.values) {
      for (final subject in subjects) {
        if (subject.parentSubjectId == null) {
          parentSubjects.add(subject);
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parentSubjects.length,
      itemBuilder: (context, index) {
        final subject = parentSubjects[index];
        return _buildSubjectCard(subject);
      },
    );
  }

  /// Build a subject card
  Widget _buildSubjectCard(ClassroomSubject subject) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Subject icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.book, size: 20, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            // Subject info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subject.teacherName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Teacher: ${subject.teacherName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Build the subject resources view (Content 2)
  Widget _buildSubjectResourcesView() {
    // Get current user info from Supabase
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    return Column(
      children: [
        // Back button header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade100, width: 1),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubject = null;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedSubject!.subjectName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Subject resources content (Content 2)
        Expanded(
          child: FutureBuilder<String?>(
            future: _getUserRole(currentUser?.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userRole = snapshot.data;
              // Check if user has admin-like permissions
              // Includes: admin, ict_coordinator, hybrid
              final isAdmin = _hasAdminPermissions(userRole);

              return SubjectResourcesContent(
                subject: _selectedSubject!,
                classroomId: widget.classroomId ?? 'temp',
                isCreateMode: widget.classroomId == null,
                isAdmin: isAdmin,
                currentUserId: currentUser?.id,
                userRole: userRole,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Get user role from database
  Future<String?> _getUserRole(String? userId) async {
    if (userId == null) {
      print('⚠️ [ROLE] User ID is null');
      return null;
    }

    try {
      print('🔍 [ROLE] Fetching role for user: $userId');
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', userId)
          .maybeSingle();

      print('📊 [ROLE] Response: $response');
      final roleName = response?['roles']?['name'];
      print('✅ [ROLE] Role name: $roleName');
      return roleName;
    } catch (e) {
      print('❌ Error fetching user role: $e');
      return null;
    }
  }

  /// Check if user has admin-like permissions
  /// Includes: admin, ict_coordinator, hybrid
  bool _hasAdminPermissions(String? userRole) {
    final role = userRole?.toLowerCase();
    final hasPermission =
        role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
    print('🔐 [SUBJECT LIST] _hasAdminPermissions()');
    print('   userRole: $userRole');
    print('   role (lowercase): $role');
    print('   result: $hasPermission');
    return hasPermission;
  }
}
