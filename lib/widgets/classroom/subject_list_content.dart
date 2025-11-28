import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_resources_content.dart';

/// Reusable widget that displays the list of subjects and shows SubjectResourcesContent when clicked
/// This is Content 1 - the main content area that displays Content 2 (SubjectResourcesContent)
///
/// PHASE 4: Supports two modes:
/// - CREATE mode (classroomId == null): Subjects are in temporary storage, preview only
/// - CONSUME mode (classroomId != null): Subjects are saved, read-only with edit button
class SubjectListContent extends StatefulWidget {
  final String? classroomId;

  /// PHASE 3: Callback to expose refresh method to parent
  final void Function(VoidCallback refresh)? onRefreshReady;

  const SubjectListContent({super.key, this.classroomId, this.onRefreshReady});

  @override
  State<SubjectListContent> createState() => _SubjectListContentState();
}

class _SubjectListContentState extends State<SubjectListContent> {
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();
  Map<String, List<ClassroomSubject>> _subjects = {};
  ClassroomSubject? _selectedSubject;
  bool _isLoading = true;

  // Sub-subject tree enhancement: Track expanded parent subjects
  final Set<String> _expandedParentSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();

    // PHASE 3: Expose refresh method to parent
    if (widget.onRefreshReady != null) {
      widget.onRefreshReady!(_refreshSubjects);
    }
  }

  @override
  void didUpdateWidget(SubjectListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload subjects if classroomId changed
    if (oldWidget.classroomId != widget.classroomId) {
      _loadSubjects();
    }

    // PHASE 3: Update refresh callback if it changed
    if (oldWidget.onRefreshReady != widget.onRefreshReady) {
      if (widget.onRefreshReady != null) {
        widget.onRefreshReady!(_refreshSubjects);
      }
    }
  }

  /// PHASE 3: Public refresh method that can be called by parent
  void _refreshSubjects() {
    print('🔄 [PHASE 3] Refreshing subjects in SubjectListContent...');
    _loadSubjects();
  }

  /// PHASE 4: Determine if we're in CREATE mode or CONSUME mode
  bool get _isCreateMode => widget.classroomId == null;
  bool get _isConsumeMode => widget.classroomId != null;

  /// Load subjects based on mode (CREATE or CONSUME)
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
  /// Sub-subject tree enhancement: Group subjects by parent_subject_id
  Future<void> _loadTemporarySubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subjectsJson = prefs.getString('temp_classroom_subjects');

      if (subjectsJson != null) {
        final Map<String, dynamic> decoded = json.decode(subjectsJson);

        if (mounted) {
          setState(() {
            _subjects.clear();

            // Sub-subject tree enhancement: Reorganize by parent_subject_id
            final List<ClassroomSubject> allSubjects = [];
            for (final entry in decoded.entries) {
              final List<dynamic> subjectsList = entry.value;
              allSubjects.addAll(
                subjectsList.map((json) => ClassroomSubject.fromJson(json))
              );
            }

            // Group by parent_subject_id
            for (final subject in allSubjects) {
              if (subject.parentSubjectId != null) {
                // This is a sub-subject
                if (!_subjects.containsKey(subject.parentSubjectId!)) {
                  _subjects[subject.parentSubjectId!] = [];
                }
                _subjects[subject.parentSubjectId!]!.add(subject);
              } else {
                // This is a parent/standard subject - add to 'root'
                if (!_subjects.containsKey('root')) {
                  _subjects['root'] = [];
                }
                _subjects['root']!.add(subject);
              }
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error loading temporary subjects: $e');
    }
  }

  /// Load subjects from database (EDIT mode)
  /// Sub-subject tree enhancement: Group subjects by parent_subject_id
  Future<void> _loadDatabaseSubjects() async {
    try {
      final subjects = await _subjectService.getSubjectsByClassroom(
        widget.classroomId!,
      );

      if (mounted) {
        setState(() {
          _subjects.clear();

          // Sub-subject tree enhancement: Group subjects by parent_subject_id
          // Key = parent_subject_id (or 'root' for parent subjects)
          // Value = list of sub-subjects
          for (final subject in subjects) {
            if (subject.parentSubjectId != null) {
              // This is a sub-subject
              if (!_subjects.containsKey(subject.parentSubjectId!)) {
                _subjects[subject.parentSubjectId!] = [];
              }
              _subjects[subject.parentSubjectId!]!.add(subject);
            } else {
              // This is a parent/standard subject - add to 'root'
              if (!_subjects.containsKey('root')) {
                _subjects['root'] = [];
              }
              _subjects['root']!.add(subject);
            }
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
  /// Sub-subject tree enhancement: Get parent subjects from 'root' key
  Widget _buildSubjectList() {
    if (_subjects.isEmpty) {
      return Center(
        child: Text(
          'No subjects added yet',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    // Sub-subject tree enhancement: Get all parent subjects from 'root' key
    final parentSubjects = _subjects['root'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PHASE 4: Mode indicator at the top
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildModeIndicator(),
        ),

        // Subject list with always-scrollable physics
        // Sub-subject tree enhancement: Build tree structure
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            // Always scrollable - allows scrolling even with few items
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _calculateTotalItemCount(parentSubjects),
            itemBuilder: (context, index) {
              return _buildSubjectTreeItem(parentSubjects, index);
            },
          ),
        ),
      ],
    );
  }

  /// PHASE 4: Build mode indicator showing current state
  Widget _buildModeIndicator() {
    if (_isCreateMode) {
      // CREATE mode - temporary storage indicator
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              'Preview Mode - Changes will be saved when you click "Create"',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // CONSUME mode - saved classroom indicator
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 12,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Saved Classroom - Click Edit button to modify subjects',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Sub-subject tree enhancement: Calculate total item count including sub-subjects
  int _calculateTotalItemCount(List<ClassroomSubject> parentSubjects) {
    int count = 0;
    for (final subject in parentSubjects) {
      count++; // Parent subject
      if (subject.isParentSubject && _expandedParentSubjects.contains(subject.id)) {
        // Add sub-subjects if parent is expanded
        final subSubjects = _subjects[subject.id] ?? [];
        count += subSubjects.length;
      }
    }
    return count;
  }

  /// Sub-subject tree enhancement: Build subject tree item (parent or sub-subject)
  Widget _buildSubjectTreeItem(List<ClassroomSubject> parentSubjects, int index) {
    int currentIndex = 0;

    for (final subject in parentSubjects) {
      if (currentIndex == index) {
        // This is a parent subject
        return _buildSubjectCard(subject);
      }
      currentIndex++;

      // Check if this parent is expanded and has sub-subjects
      if (subject.isParentSubject && _expandedParentSubjects.contains(subject.id)) {
        final subSubjects = _subjects[subject.id] ?? [];
        for (final subSubject in subSubjects) {
          if (currentIndex == index) {
            // This is a sub-subject
            return _buildSubSubjectCard(subSubject, subject);
          }
          currentIndex++;
        }
      }
    }

    return const SizedBox.shrink();
  }

  /// Build a subject card
  /// PHASE 4: Updated to show visual distinction between CREATE and CONSUME modes
  /// Sub-subject tree enhancement: Added expand/collapse for parent subjects
  Widget _buildSubjectCard(ClassroomSubject subject) {
    // PHASE 4: Determine mode-specific styling
    final bool showEditButton = _isConsumeMode;
    final Color borderColor = _isCreateMode
        ? Colors.orange.shade200
        : Colors.grey.shade300;
    final Color iconBgColor = _isCreateMode
        ? Colors.orange.shade50
        : Colors.blue.shade50;
    final Color iconColor = _isCreateMode
        ? Colors.orange.shade700
        : Colors.blue.shade700;

    // Sub-subject tree enhancement: Check if this is a parent subject
    final bool isParent = subject.isParentSubject;
    final bool isExpanded = _expandedParentSubjects.contains(subject.id);
    final int subSubjectCount = _subjects[subject.id]?.length ?? 0;

    return InkWell(
      onTap: () {
        setState(() {
          // Sub-subject tree enhancement: Toggle expand/collapse for parent subjects
          if (isParent) {
            if (isExpanded) {
              _expandedParentSubjects.remove(subject.id);
            } else {
              _expandedParentSubjects.add(subject.id);
            }
          } else {
            _selectedSubject = subject;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
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
            // Subject icon with mode-specific styling
            // Sub-subject tree enhancement: Different icons for parent subjects
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isParent
                  ? (subject.isMAPEHParent ? Icons.music_note : Icons.construction)
                  : Icons.book,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            // Subject info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      // PHASE 4: Preview badge in CREATE mode
                      if (_isCreateMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'PREVIEW',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Teacher name or "No teacher assigned" indicator
                  if (subject.teacherName != null) ...[
                    Text(
                      'Teacher: ${subject.teacherName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    // Show "No teacher assigned" indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 10,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // PHASE 4: Edit button (only in CONSUME mode)
            if (showEditButton) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Edit subject',
                child: InkWell(
                  onTap: () {
                    _openSubjectEditorDialog(subject);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            ],
            // Arrow icon or expand/collapse icon
            // Sub-subject tree enhancement: Show expand/collapse for parent subjects
            const SizedBox(width: 8),
            if (isParent) ...[
              // Parent subject: Show expand/collapse icon
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.grey.shade600,
              ),
              if (subSubjectCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$subSubjectCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Regular subject: Show arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sub-subject tree enhancement: Build sub-subject card (indented under parent)
  Widget _buildSubSubjectCard(ClassroomSubject subSubject, ClassroomSubject parentSubject) {
    // Determine mode-specific styling
    final Color borderColor = _isCreateMode
        ? Colors.orange.shade100
        : Colors.grey.shade200;
    final Color iconColor = _isCreateMode
        ? Colors.orange.shade400
        : Colors.blue.shade400;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubject = subSubject;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 32), // Indented
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Indent indicator
            Icon(
              Icons.subdirectory_arrow_right,
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            // Sub-subject icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.insert_drive_file,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            // Sub-subject info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subSubject.subjectName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Teacher name or "No teacher assigned"
                  if (subSubject.teacherName != null) ...[
                    Text(
                      'Teacher: ${subSubject.teacherName}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 9,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'No teacher assigned',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// PHASE 2: Open Subject Editor dialog
  /// This dialog reuses Content 2 (SubjectResourcesContent) for editing a subject
  void _openSubjectEditorDialog(ClassroomSubject subject) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _SubjectEditorDialog(
          subject: subject,
          classroomId: widget.classroomId!,
          onSaved: () {
            // Reload subjects after editing
            _loadSubjects();
          },
        );
      },
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

/// PHASE 2: Subject Editor Dialog
/// This dialog reuses Content 2 (SubjectResourcesContent) for editing a subject after classroom is saved
class _SubjectEditorDialog extends StatefulWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final VoidCallback onSaved;

  const _SubjectEditorDialog({
    required this.subject,
    required this.classroomId,
    required this.onSaved,
  });

  @override
  State<_SubjectEditorDialog> createState() => _SubjectEditorDialogState();
}

class _SubjectEditorDialogState extends State<_SubjectEditorDialog> {
  @override
  Widget build(BuildContext context) {
    // Get current user info from Supabase
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Subject icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Subject',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subject.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: Colors.grey.shade600,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Content 2: Subject Resources Content
            Expanded(
              child: FutureBuilder<String?>(
                future: _getUserRole(currentUser?.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userRole = snapshot.data;
                  // Check if user has admin-like permissions
                  final isAdmin = _hasAdminPermissions(userRole);

                  return SubjectResourcesContent(
                    subject: widget.subject,
                    classroomId: widget.classroomId,
                    isCreateMode: false, // Always EDIT mode in this dialog
                    isAdmin: isAdmin,
                    currentUserId: currentUser?.id,
                    userRole: userRole,
                  );
                },
              ),
            ),

            // Footer
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Done button
                ElevatedButton(
                  onPressed: () {
                    widget.onSaved();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get user role from database
  Future<String?> _getUserRole(String? userId) async {
    if (userId == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', userId)
          .maybeSingle();

      return response?['roles']?['name'];
    } catch (e) {
      print('❌ Error fetching user role: $e');
      return null;
    }
  }

  /// Check if user has admin-like permissions
  bool _hasAdminPermissions(String? userRole) {
    if (userRole == null) return false;
    final role = userRole.toLowerCase();
    return role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
  }
}
