import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_resources_content.dart';
import 'package:oro_site_high_school/widgets/classroom/subject_list_content.dart';

/// Custom formatter to capitalize the first letter
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Capitalize the first letter
    final String capitalizedText =
        newValue.text[0].toUpperCase() + newValue.text.substring(1);

    return TextEditingValue(
      text: capitalizedText,
      selection: newValue.selection,
    );
  }
}

/// Configuration for classroom editor permissions and behavior
class ClassroomEditorConfig {
  /// Whether the user can create new classrooms
  final bool canCreate;

  /// Whether the user can edit existing classrooms
  final bool canEdit;

  /// Whether the user can delete classrooms
  final bool canDelete;

  /// Whether the user can assign advisory teachers
  final bool canAssignAdvisory;

  /// Whether to show the advisory teacher selector
  final bool showAdvisorySelector;

  /// Whether to show the classroom title field
  final bool showTitleField;

  /// User role for permission checks (admin, teacher, student, etc.)
  final String userRole;

  const ClassroomEditorConfig({
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.canAssignAdvisory = true,
    this.showAdvisorySelector = true,
    this.showTitleField = true,
    this.userRole = 'admin',
  });

  /// Factory constructor for admin role (full permissions)
  factory ClassroomEditorConfig.admin() {
    return const ClassroomEditorConfig(
      canCreate: true,
      canEdit: true,
      canDelete: true,
      canAssignAdvisory: true,
      showAdvisorySelector: true,
      showTitleField: true,
      userRole: 'admin',
    );
  }

  /// Factory constructor for teacher role (limited permissions)
  factory ClassroomEditorConfig.teacher() {
    return const ClassroomEditorConfig(
      canCreate: false,
      canEdit: true,
      canDelete: false,
      canAssignAdvisory: false,
      showAdvisorySelector: true,
      showTitleField: true,
      userRole: 'teacher',
    );
  }

  /// Factory constructor for student role (read-only)
  factory ClassroomEditorConfig.student() {
    return const ClassroomEditorConfig(
      canCreate: false,
      canEdit: false,
      canDelete: false,
      canAssignAdvisory: false,
      showAdvisorySelector: true,
      showTitleField: true,
      userRole: 'student',
    );
  }
}

/// Reusable classroom editor widget that can be used across different role dashboards
///
/// This widget provides the main content area for creating/editing classrooms.
/// It can be configured with different permissions based on user role.
///
/// **Usage Example:**
/// ```dart
/// ClassroomEditorWidget(
///   config: ClassroomEditorConfig.admin(), // or .teacher() or .student()
///   titleController: _titleController,
///   selectedAdvisoryTeacher: _selectedAdvisoryTeacher,
///   availableTeachers: _teachers,
///   isMenuOpen: _isMenuOpen,
///   layerLink: _layerLink,
///   buttonKey: _buttonKey,
///   onToggleMenu: _toggleMenu,
///   onAdvisoryTeacherChanged: (teacher) {
///     setState(() => _selectedAdvisoryTeacher = teacher);
///   },
/// )
/// ```
class ClassroomEditorWidget extends StatefulWidget {
  /// Configuration for permissions and behavior
  final ClassroomEditorConfig config;

  /// Controller for the classroom title text field
  final TextEditingController titleController;

  /// Currently selected advisory teacher (null if none selected)
  final Teacher? selectedAdvisoryTeacher;

  /// List of all available teachers
  final List<Teacher> availableTeachers;

  /// Whether the advisory teacher menu is currently open
  final bool isMenuOpen;

  /// LayerLink for positioning the overlay menu
  final LayerLink layerLink;

  /// GlobalKey for the button to calculate overlay position
  final GlobalKey buttonKey;

  /// Callback to toggle the advisory teacher menu
  final VoidCallback onToggleMenu;

  /// Callback when the advisory teacher selection changes
  final ValueChanged<Teacher?> onAdvisoryTeacherChanged;

  /// Selected school level from right sidebar
  final String? selectedSchoolLevel;

  /// Selected grade level from right sidebar
  final int? selectedGradeLevel;

  /// Selected quarter from right sidebar
  final String? selectedQuarter;

  /// Selected semester from right sidebar
  final String? selectedSemester;

  /// Selected academic track from right sidebar
  final String? selectedAcademicTrack;

  /// Classroom ID (null if in create mode, non-null if editing existing classroom)
  final String? classroomId;

  const ClassroomEditorWidget({
    super.key,
    required this.config,
    required this.titleController,
    required this.selectedAdvisoryTeacher,
    required this.availableTeachers,
    required this.isMenuOpen,
    required this.layerLink,
    required this.buttonKey,
    required this.onToggleMenu,
    required this.onAdvisoryTeacherChanged,
    this.selectedSchoolLevel,
    this.selectedGradeLevel,
    this.selectedQuarter,
    this.selectedSemester,
    this.selectedAcademicTrack,
    this.classroomId,
  });

  @override
  State<ClassroomEditorWidget> createState() => _ClassroomEditorWidgetState();
}

class _ClassroomEditorWidgetState extends State<ClassroomEditorWidget> {
  /// PHASE 3: Callback to refresh SubjectListContent
  VoidCallback? _refreshSubjectList;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16), // Reduced from 24 to 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Settings Indicators (upper right corner)
          if (widget.selectedSchoolLevel != null ||
              widget.selectedGradeLevel != null ||
              widget.selectedQuarter != null ||
              widget.selectedSemester != null ||
              widget.selectedAcademicTrack != null)
            _buildSettingsIndicators(),

          // Compact form section at the top
          _buildCompactFormSection(),

          // PHASE 1: Subject List Preview (Content 1)
          // Shows subjects with Content 2 in CREATE mode (temporary storage)
          // This is a preview - actual save happens when Create button is clicked
          const SizedBox(height: 12), // Reduced spacing
          Expanded(
            child: SubjectListContent(
              classroomId:
                  widget.classroomId, // null in CREATE mode, ID in EDIT mode
              // PHASE 3: Pass refresh callback
              onRefreshReady: (refresh) {
                _refreshSubjectList = refresh;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact form section with all inputs in a horizontal row
  Widget _buildCompactFormSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Classroom Title Section
        if (widget.config.showTitleField) ...[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Classroom Title*',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          'Enter only the section name (e.g., "Diamond", "Sapphire").\nDo not include grade levels or numbers.',
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: widget.titleController,
                  placeholder: 'Enter classroom title',
                  style: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [CapitalizeFirstLetterFormatter()],
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabled: widget.config.canEdit,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Advisory Teacher Selector
        if (widget.config.showAdvisorySelector) ...[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advisory Teacher',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                CompositedTransformTarget(
                  link: widget.layerLink,
                  child: GestureDetector(
                    key: widget.buttonKey,
                    onTap: widget.config.canAssignAdvisory
                        ? widget.onToggleMenu
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: widget.isMenuOpen
                              ? CupertinoColors.activeBlue
                              : Colors.grey.shade300,
                          width: widget.isMenuOpen ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              widget.selectedAdvisoryTeacher?.displayName ??
                                  'Select advisory teacher',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.selectedAdvisoryTeacher != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            widget.isMenuOpen
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Add Subjects Button
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Subjects',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  _openAddSubjectDialog(context, widget.classroomId);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build settings indicators showing current selections from right sidebar
  Widget _buildSettingsIndicators() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // School Level Indicator
          if (widget.selectedSchoolLevel != null)
            _buildIndicatorChip(
              label: widget.selectedSchoolLevel == 'Junior High School'
                  ? 'JHS'
                  : 'SHS',
              color: widget.selectedSchoolLevel == 'Junior High School'
                  ? Colors.blue.shade700
                  : Colors.purple.shade700,
              tooltip: widget.selectedSchoolLevel!,
            ),

          // Grade Level Indicator
          if (widget.selectedGradeLevel != null) ...[
            const SizedBox(width: 8),
            _buildIndicatorChip(
              label: 'Grade ${widget.selectedGradeLevel}',
              color: Colors.green.shade700,
              tooltip: 'Grade Level: ${widget.selectedGradeLevel}',
            ),
          ],

          // Quarter Indicator (JHS)
          if (widget.selectedQuarter != null) ...[
            const SizedBox(width: 8),
            _buildIndicatorChip(
              label: widget.selectedQuarter!,
              color: Colors.orange.shade700,
              tooltip: 'Quarter: ${widget.selectedQuarter}',
            ),
          ],

          // Semester Indicator (SHS)
          if (widget.selectedSemester != null) ...[
            const SizedBox(width: 8),
            _buildIndicatorChip(
              label: widget.selectedSemester!,
              color: Colors.teal.shade700,
              tooltip: 'Semester: ${widget.selectedSemester}',
            ),
          ],

          // Academic Track Indicator (SHS)
          if (widget.selectedAcademicTrack != null) ...[
            const SizedBox(width: 8),
            _buildIndicatorChip(
              label: widget.selectedAcademicTrack!,
              color: Colors.indigo.shade700,
              tooltip: 'Academic Track: ${widget.selectedAcademicTrack}',
            ),
          ],
        ],
      ),
    );
  }

  /// Build a single indicator chip
  Widget _buildIndicatorChip({
    required String label,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Open add subject dialog based on school level
  /// PHASE 3: Now triggers refresh after dialog closes
  void _openAddSubjectDialog(BuildContext context, String? classroomId) async {
    // Determine if JHS or SHS based on selectedSchoolLevel
    final bool isJHS = widget.selectedSchoolLevel == 'Junior High School';
    final bool isSHS = widget.selectedSchoolLevel == 'Senior High School';

    // Determine if we're in CREATE mode (no classroom ID) or EDIT mode (has classroom ID)
    final bool isCreateMode = classroomId == null;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddSubjectDialog(
          isJHS: isJHS,
          isSHS: isSHS,
          classroomId: classroomId,
          isCreateMode: isCreateMode,
        );
      },
    );

    // PHASE 3: Refresh subject list after dialog closes
    print('🔄 [PHASE 3] Add Subject Dialog closed, triggering refresh...');
    if (_refreshSubjectList != null) {
      _refreshSubjectList!();
    } else {
      print('⚠️ [PHASE 3] Refresh callback not available yet');
    }
  }
}

/// Stateful dialog for adding subjects
class _AddSubjectDialog extends StatefulWidget {
  final bool isJHS;
  final bool isSHS;
  final String? classroomId; // Nullable for CREATE mode
  final bool isCreateMode; // True if in CREATE mode, false if in EDIT mode

  const _AddSubjectDialog({
    required this.isJHS,
    required this.isSHS,
    required this.classroomId,
    required this.isCreateMode,
  });

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final ClassroomSubjectService _subjectService = ClassroomSubjectService();

  // JHS subjects in order
  final List<String> _jhsSubjects = [
    'Filipino',
    'English',
    'Mathematics',
    'Science',
    'Araling Panlipunan (AP)',
    'Edukasyon sa Pagpapakatao (EsP)',
    'Technology and Livelihood Education (TLE)',
    'MAPEH',
  ];

  // Track expanded state for each subject
  final Map<String, bool> _expandedSubjects = {};

  // Track existing subjects from database
  final Map<String, List<ClassroomSubject>> _existingSubjects = {};

  // Loading state
  bool _isLoading = true;

  // Teacher assignment overlay state
  OverlayEntry? _teacherOverlayEntry;
  String? _currentAssigningSubject;
  final Map<String, GlobalKey> _subjectButtonKeys = {};
  final TextEditingController _teacherSearchController =
      TextEditingController();
  String _teacherSearchQuery = '';
  List<Teacher> _availableTeachers = [];
  bool _isLoadingTeachers = false;
  bool _isDisposing = false;

  // Main content area state
  String? _selectedSubject; // Currently selected subject for main content
  String _mainContentMode = 'empty'; // 'empty', 'subject_details', 'add_module'

  @override
  void initState() {
    super.initState();

    print('🚀 [INIT] Dialog initializing...');
    print('🚀 [INIT] Mode: ${widget.isCreateMode ? "CREATE" : "EDIT"}');
    print('🚀 [INIT] Classroom ID: ${widget.classroomId ?? "none"}');

    // Initialize all subjects as collapsed and create GlobalKeys
    print('🚀 [INIT] Initializing ${_jhsSubjects.length} JHS subjects...');
    for (final subject in _jhsSubjects) {
      _expandedSubjects[subject] = false;
      _existingSubjects[subject] = [];
      _subjectButtonKeys[subject] = GlobalKey();
    }
    print(
      '🚀 [INIT] _existingSubjects initialized with ${_existingSubjects.length} empty entries',
    );

    // Load available teachers
    _loadTeachers();

    // Only load from database if in EDIT mode
    if (!widget.isCreateMode && widget.classroomId != null) {
      print('🚀 [INIT] EDIT mode - loading from database...');
      _loadExistingSubjects();
    } else {
      // CREATE mode - load from SharedPreferences
      print('🚀 [INIT] CREATE mode - loading from SharedPreferences...');
      _loadTemporarySubjects();
    }
  }

  @override
  void dispose() {
    // Set flag to prevent clearing controller after disposal
    _isDisposing = true;
    // Remove overlay first without clearing controller
    _teacherOverlayEntry?.remove();
    _teacherOverlayEntry = null;
    // Then dispose controller
    _teacherSearchController.dispose();
    super.dispose();
  }

  /// Load available teachers for assignment
  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final teacherService = TeacherService();
      final teachers = await teacherService.getAllTeachers();

      if (mounted) {
        setState(() {
          _availableTeachers = teachers;
          _isLoadingTeachers = false;
        });
      }
    } catch (e) {
      print('❌ Error loading teachers: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeachers = false;
        });
      }
    }
  }

  /// Load temporary subjects from SharedPreferences (CREATE mode only)
  Future<void> _loadTemporarySubjects() async {
    print('📦 [LOAD] Starting load from SharedPreferences...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subjectsJson = prefs.getString('temp_classroom_subjects');

      if (subjectsJson != null) {
        print('📦 [LOAD] Found saved data in SharedPreferences');
        final Map<String, dynamic> decoded = json.decode(subjectsJson);
        print('📦 [LOAD] Decoded ${decoded.length} subject keys from JSON');

        if (mounted) {
          int totalLoaded = 0;
          int parentSubjects = 0;
          int subSubjects = 0;

          setState(() {
            // Reconstruct _existingSubjects from JSON
            for (final entry in decoded.entries) {
              final subjectName = entry.key;
              final List<dynamic> subjectsList = entry.value;

              _existingSubjects[subjectName] = subjectsList
                  .map((json) => ClassroomSubject.fromJson(json))
                  .toList();

              totalLoaded += _existingSubjects[subjectName]!.length;

              // Detailed logging for each loaded subject
              for (final subject in _existingSubjects[subjectName]!) {
                if (subject.parentSubjectId == null) {
                  parentSubjects++;
                  print(
                    '   📥 [LOAD] Parent: "$subjectName" | ID: ${subject.id} | Teacher: ${subject.teacherId ?? "none"}',
                  );
                } else {
                  subSubjects++;
                  print(
                    '   📥 [LOAD] Sub-Subject: "$subjectName" | ID: ${subject.id} | Parent ID: ${subject.parentSubjectId} | Teacher: ${subject.teacherId ?? "none"}',
                  );
                }
              }
            }
            _isLoading = false;
          });

          print('📦 [LOAD] ✅ Successfully loaded from SharedPreferences');
          print(
            '📦 [LOAD] Summary: $totalLoaded total ($parentSubjects parents, $subSubjects sub-subjects)',
          );

          // Verify sub-subjects can find their parents
          print('📦 [LOAD] Verifying parent-child relationships...');
          for (final entry in _existingSubjects.entries) {
            for (final subject in entry.value) {
              if (subject.parentSubjectId != null) {
                // Try to find parent
                bool parentFound = false;
                for (final parentEntry in _existingSubjects.entries) {
                  for (final potentialParent in parentEntry.value) {
                    if (potentialParent.id == subject.parentSubjectId) {
                      parentFound = true;
                      print(
                        '   ✅ [LOAD] Sub-subject "${subject.subjectName}" found parent "${potentialParent.subjectName}"',
                      );
                      break;
                    }
                  }
                  if (parentFound) break;
                }
                if (!parentFound) {
                  print(
                    '   ⚠️ [LOAD] WARNING: Sub-subject "${subject.subjectName}" cannot find parent with ID: ${subject.parentSubjectId}',
                  );
                }
              }
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print('📦 [LOAD] ℹ️ No temporary subjects found in storage');
      }
    } catch (e) {
      print('❌ [LOAD] Error loading temporary subjects: $e');
      print('❌ [LOAD] Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Save temporary subjects to SharedPreferences (CREATE mode only)
  Future<void> _saveTemporarySubjects() async {
    if (!widget.isCreateMode) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      print('💾 [SAVE] Starting save to SharedPreferences...');
      print(
        '💾 [SAVE] Total subject keys in _existingSubjects: ${_existingSubjects.length}',
      );

      // Convert _existingSubjects to JSON
      final Map<String, dynamic> toSave = {};
      int totalSubjects = 0;
      int parentSubjects = 0;
      int subSubjects = 0;

      for (final entry in _existingSubjects.entries) {
        if (entry.value.isNotEmpty) {
          toSave[entry.key] = entry.value.map((s) => s.toJson()).toList();
          totalSubjects += entry.value.length;

          // Detailed logging for each subject
          for (final subject in entry.value) {
            if (subject.parentSubjectId == null) {
              parentSubjects++;
              print(
                '   📝 [SAVE] Parent: "${entry.key}" | ID: ${subject.id} | Teacher: ${subject.teacherId ?? "none"}',
              );
            } else {
              subSubjects++;
              print(
                '   📝 [SAVE] Sub-Subject: "${entry.key}" | ID: ${subject.id} | Parent ID: ${subject.parentSubjectId} | Teacher: ${subject.teacherId ?? "none"}',
              );
            }
          }
        }
      }

      await prefs.setString('temp_classroom_subjects', json.encode(toSave));
      print('💾 [SAVE] ✅ Successfully saved to SharedPreferences');
      print(
        '💾 [SAVE] Summary: $totalSubjects total ($parentSubjects parents, $subSubjects sub-subjects)',
      );
    } catch (e) {
      print('❌ [SAVE] Error saving temporary subjects: $e');
      print('❌ [SAVE] Stack trace: ${StackTrace.current}');
    }
  }

  /// Load existing subjects from database (EDIT mode only)
  Future<void> _loadExistingSubjects() async {
    try {
      print(
        '📚 Loading existing subjects for classroom: ${widget.classroomId}',
      );

      final subjects = await _subjectService.getSubjectsByClassroom(
        widget.classroomId!,
      );

      if (mounted) {
        setState(() {
          // Group subjects by subject name
          for (final subject in subjects) {
            if (!_existingSubjects.containsKey(subject.subjectName)) {
              _existingSubjects[subject.subjectName] = [];
            }
            _existingSubjects[subject.subjectName]!.add(subject);
          }
          _isLoading = false;
        });
      }

      print('✅ Loaded ${subjects.length} existing subjects');
    } catch (e) {
      print('❌ Error loading subjects: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Add a subject (CREATE mode: temporary state, EDIT mode: save to database)
  /// Sub-subject tree enhancement: Auto-initialize MAPEH sub-subjects
  Future<void> _addSubject(String subjectName) async {
    // Sub-subject tree enhancement: Determine subject type
    SubjectType subjectType = SubjectType.standard;
    if (subjectName == 'MAPEH') {
      subjectType = SubjectType.mapehParent;
    } else if (subjectName == 'Technology and Livelihood Education (TLE)') {
      subjectType = SubjectType.tleParent;
    }

    if (widget.isCreateMode) {
      // CREATE MODE: Add to temporary state only (no database save)
      print('➕ [CREATE MODE] Adding subject to temporary state: $subjectName');
      print('   Subject type: ${subjectType.toDbString()}');

      if (mounted) {
        setState(() {
          if (!_existingSubjects.containsKey(subjectName)) {
            _existingSubjects[subjectName] = [];
          }

          // Check if subject already exists (e.g., from teacher assignment)
          if (_existingSubjects[subjectName]!.isEmpty) {
            // Create a temporary subject object (no ID yet)
            final tempSubject = ClassroomSubject(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              classroomId: 'temp',
              subjectName: subjectName,
              subjectType: subjectType, // Sub-subject tree enhancement
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _existingSubjects[subjectName]!.add(tempSubject);
            print('   ✅ Created new subject entry');

            // Sub-subject tree enhancement: Auto-initialize MAPEH sub-subjects
            if (subjectType == SubjectType.mapehParent) {
              _initializeMAPEHSubSubjects(tempSubject.id);
            }
          } else {
            print(
              '   ℹ️ Subject already exists (possibly from teacher assignment)',
            );
          }
        });

        // Save to SharedPreferences
        _saveTemporarySubjects();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$subjectName added (will save when classroom is created)',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      // EDIT MODE: Save to database immediately
      try {
        print('➕ [EDIT MODE] Adding subject to database: $subjectName');
        print('   Subject type: ${subjectType.toDbString()}');

        // Sub-subject tree enhancement: Use appropriate service method
        ClassroomSubject newSubject;
        if (subjectType == SubjectType.mapehParent) {
          // Use addMAPEHSubject which auto-initializes sub-subjects
          newSubject = await _subjectService.addMAPEHSubject(
            classroomId: widget.classroomId!,
          );
          print('✅ MAPEH subject added with auto-initialized sub-subjects');
        } else if (subjectType == SubjectType.tleParent) {
          // Use addTLESubject
          newSubject = await _subjectService.addTLESubject(
            classroomId: widget.classroomId!,
          );
          print('✅ TLE subject added');
        } else {
          // Standard subject
          newSubject = await _subjectService.addSubject(
            classroomId: widget.classroomId!,
            subjectName: subjectName,
          );
          print('✅ Standard subject added');
        }

        if (mounted) {
          setState(() {
            if (!_existingSubjects.containsKey(subjectName)) {
              _existingSubjects[subjectName] = [];
            }
            _existingSubjects[subjectName]!.add(newSubject);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$subjectName added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        print('✅ Subject added successfully');
      } catch (e) {
        print('❌ Error adding subject: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding subject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Sub-subject tree enhancement: Initialize MAPEH sub-subjects (CREATE mode)
  void _initializeMAPEHSubSubjects(String mapehParentId) {
    print('🎵 [MAPEH] Initializing MAPEH sub-subjects for parent ID: $mapehParentId');

    final mapehSubSubjects = ['Music', 'Arts', 'Physical Education (PE)', 'Health'];

    for (final subSubjectName in mapehSubSubjects) {
      final tempSubSubject = ClassroomSubject(
        id: 'temp_mapeh_sub_${DateTime.now().millisecondsSinceEpoch}_$subSubjectName',
        classroomId: 'temp',
        subjectName: subSubjectName,
        parentSubjectId: mapehParentId,
        subjectType: SubjectType.mapehSub,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store sub-subject under its own name key
      if (!_existingSubjects.containsKey(subSubjectName)) {
        _existingSubjects[subSubjectName] = [];
      }
      _existingSubjects[subSubjectName]!.add(tempSubSubject);

      // Create GlobalKey for sub-subject
      if (!_subjectButtonKeys.containsKey(tempSubSubject.id)) {
        _subjectButtonKeys[tempSubSubject.id] = GlobalKey();
      }

      print('   ✅ Created MAPEH sub-subject: $subSubjectName');
    }

    // Save to SharedPreferences
    _saveTemporarySubjects();
    print('🎵 [MAPEH] All 4 sub-subjects initialized and saved');
  }

  /// Add a sub-subject under a parent subject
  Future<void> _addSubSubject(String parentSubjectName) async {
    print(
      '🌳 [SUB-SUBJECT] Starting add sub-subject flow for parent: $parentSubjectName',
    );

    // Show dialog to enter sub-subject name
    final TextEditingController subSubjectController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Sub-Subject under $parentSubjectName',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: subSubjectController,
              decoration: InputDecoration(
                labelText: 'Sub-Subject Name',
                hintText: 'e.g., Music, Arts, PE, Health',
                labelStyle: const TextStyle(fontSize: 12),
                hintStyle: const TextStyle(fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                if (subSubjectController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(subSubjectController.text.trim());
                }
              },
              child: const Text('Add', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      print('🌳 [SUB-SUBJECT] User entered sub-subject name: $result');

      // Get or create parent subject
      String parentSubjectId;

      final parentSubjects = _existingSubjects[parentSubjectName];
      if (parentSubjects == null || parentSubjects.isEmpty) {
        // Parent doesn't exist yet - create it temporarily
        print(
          '🌳 [SUB-SUBJECT] Parent "$parentSubjectName" does not exist, creating temporary parent...',
        );

        final tempParentSubject = ClassroomSubject(
          id: 'temp_parent_${DateTime.now().millisecondsSinceEpoch}',
          classroomId: widget.isCreateMode ? 'temp' : widget.classroomId!,
          subjectName: parentSubjectName,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (!_existingSubjects.containsKey(parentSubjectName)) {
          _existingSubjects[parentSubjectName] = [];
        }
        _existingSubjects[parentSubjectName]!.add(tempParentSubject);
        parentSubjectId = tempParentSubject.id;

        print('🌳 [SUB-SUBJECT] Created parent with ID: $parentSubjectId');

        // Create GlobalKey for parent if it doesn't exist
        if (!_subjectButtonKeys.containsKey(parentSubjectName)) {
          _subjectButtonKeys[parentSubjectName] = GlobalKey();
        }

        // Save to SharedPreferences if in CREATE mode
        if (widget.isCreateMode) {
          await _saveTemporarySubjects();
          print('🌳 [SUB-SUBJECT] Saved parent to SharedPreferences');
        }
      } else {
        parentSubjectId = parentSubjects.first.id;
        print(
          '🌳 [SUB-SUBJECT] Parent "$parentSubjectName" exists with ID: $parentSubjectId',
        );
      }

      if (widget.isCreateMode) {
        // CREATE MODE: Add to temporary state
        print(
          '🌳 [SUB-SUBJECT] CREATE MODE: Adding sub-subject "$result" under parent ID: $parentSubjectId',
        );

        if (mounted) {
          // Create temporary sub-subject
          final tempSubSubject = ClassroomSubject(
            id: 'temp_sub_${DateTime.now().millisecondsSinceEpoch}',
            classroomId: 'temp',
            subjectName: result,
            parentSubjectId: parentSubjectId,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          print('🌳 [SUB-SUBJECT] Created sub-subject object:');
          print('   - ID: ${tempSubSubject.id}');
          print('   - Name: ${tempSubSubject.subjectName}');
          print('   - Parent ID: ${tempSubSubject.parentSubjectId}');

          setState(() {
            // Store sub-subject under its own name key (not parent's key)
            if (!_existingSubjects.containsKey(result)) {
              _existingSubjects[result] = [];
            }
            _existingSubjects[result]!.add(tempSubSubject);

            // Create GlobalKey for sub-subject using unique ID
            if (!_subjectButtonKeys.containsKey(tempSubSubject.id)) {
              _subjectButtonKeys[tempSubSubject.id] = GlobalKey();
            }

            print('🌳 [SUB-SUBJECT] Added to _existingSubjects["$result"]');
          });

          // Save to SharedPreferences AFTER setState completes
          await _saveTemporarySubjects();
          print('🌳 [SUB-SUBJECT] Saved to SharedPreferences');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$result added under $parentSubjectName'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // EDIT MODE: Save to database
        try {
          print(
            '➕ [EDIT MODE] Adding sub-subject: $result under $parentSubjectName',
          );

          final newSubSubject = await _subjectService.addSubject(
            classroomId: widget.classroomId!,
            subjectName: result,
            parentSubjectId: parentSubjectId,
          );

          if (mounted) {
            setState(() {
              // Store sub-subject under its own name key
              if (!_existingSubjects.containsKey(result)) {
                _existingSubjects[result] = [];
              }
              _existingSubjects[result]!.add(newSubSubject);

              // Create GlobalKey for sub-subject using unique ID
              if (!_subjectButtonKeys.containsKey(newSubSubject.id)) {
                _subjectButtonKeys[newSubSubject.id] = GlobalKey();
              }

              print(
                '✅ Sub-subject saved to DB: $result (parent: $parentSubjectId)',
              );
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$result added under $parentSubjectName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('❌ Error adding sub-subject: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding sub-subject: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  /// Edit a sub-subject
  Future<void> _editSubSubject(
    ClassroomSubject subSubject,
    String parentName,
  ) async {
    final TextEditingController editController = TextEditingController(
      text: subSubject.subjectName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Sub-Subject',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: 'Sub-Subject Name',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                if (editController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(editController.text.trim());
                }
              },
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );

    if (result != null &&
        result.isNotEmpty &&
        result != subSubject.subjectName) {
      if (widget.isCreateMode) {
        // CREATE MODE: Update in temporary state
        if (mounted) {
          setState(() {
            // Remove from old key
            final oldSubjects = _existingSubjects[subSubject.subjectName];
            if (oldSubjects != null) {
              oldSubjects.removeWhere((s) => s.id == subSubject.id);
              if (oldSubjects.isEmpty) {
                _existingSubjects.remove(subSubject.subjectName);
              }
            }

            // Add to new key with updated name
            final updatedSubject = subSubject.copyWith(
              subjectName: result,
              updatedAt: DateTime.now(),
            );
            if (!_existingSubjects.containsKey(result)) {
              _existingSubjects[result] = [];
            }
            _existingSubjects[result]!.add(updatedSubject);
          });

          // Save to SharedPreferences
          _saveTemporarySubjects();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated to "$result"'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // EDIT MODE: Update in database
        try {
          final updatedSubject = await _subjectService.updateSubject(
            subjectId: subSubject.id,
            subjectName: result,
          );

          if (mounted) {
            setState(() {
              // Remove from old key
              final oldSubjects = _existingSubjects[subSubject.subjectName];
              if (oldSubjects != null) {
                oldSubjects.removeWhere((s) => s.id == subSubject.id);
                if (oldSubjects.isEmpty) {
                  _existingSubjects.remove(subSubject.subjectName);
                }
              }

              // Add to new key
              if (!_existingSubjects.containsKey(result)) {
                _existingSubjects[result] = [];
              }
              _existingSubjects[result]!.add(updatedSubject);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated to "$result"'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating sub-subject: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  /// Delete a sub-subject
  Future<void> _deleteSubSubject(
    ClassroomSubject subSubject,
    String parentName,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Sub-Subject',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${subSubject.subjectName}"?',
            style: const TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (widget.isCreateMode) {
        // CREATE MODE: Remove from temporary state
        if (mounted) {
          setState(() {
            final subSubjects = _existingSubjects[subSubject.subjectName];
            if (subSubjects != null) {
              subSubjects.removeWhere((s) => s.id == subSubject.id);
              if (subSubjects.isEmpty) {
                _existingSubjects.remove(subSubject.subjectName);
              }
            }
          });

          // Save to SharedPreferences
          _saveTemporarySubjects();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${subSubject.subjectName}" removed'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // EDIT MODE: Delete from database
        try {
          await _subjectService.deleteSubject(subSubject.id);

          if (mounted) {
            setState(() {
              final subSubjects = _existingSubjects[subSubject.subjectName];
              if (subSubjects != null) {
                subSubjects.removeWhere((s) => s.id == subSubject.id);
                if (subSubjects.isEmpty) {
                  _existingSubjects.remove(subSubject.subjectName);
                }
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${subSubject.subjectName}" deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting sub-subject: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  /// Assign teacher to a subject
  void _assignTeacher(String subjectName) {
    setState(() {
      _currentAssigningSubject = subjectName;
    });
    _openTeacherOverlay(subjectName);
  }

  /// Open teacher assignment overlay
  void _openTeacherOverlay(String subjectName) {
    if (_teacherOverlayEntry != null) {
      _closeTeacherOverlay();
    }

    final buttonKey = _subjectButtonKeys[subjectName];
    if (buttonKey == null || buttonKey.currentContext == null) {
      print('❌ Button key not found for subject: $subjectName');
      return;
    }

    final RenderBox? renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _teacherOverlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeTeacherOverlay,
        child: Stack(
          children: [
            // Transparent background
            Positioned.fill(child: Container(color: Colors.transparent)),
            // The actual menu
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              width: 250,
              child: GestureDetector(
                onTap: () {
                  // Prevent closing when clicking inside the menu
                },
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: _buildTeacherMenuContent(subjectName),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_teacherOverlayEntry!);
  }

  /// Close teacher assignment overlay
  void _closeTeacherOverlay() {
    _teacherOverlayEntry?.remove();
    _teacherOverlayEntry = null;
    // Only clear if widget is still mounted and not disposing
    if (mounted && !_isDisposing) {
      _teacherSearchController.clear();
      _teacherSearchQuery = '';
      _currentAssigningSubject = null;
    }
  }

  /// Build teacher selection menu content
  Widget _buildTeacherMenuContent(String subjectName) {
    return StatefulBuilder(
      builder: (context, setMenuState) {
        // Get currently assigned teacher for this subject
        final subjects = _existingSubjects[subjectName];
        final currentTeacherId =
            subjects != null &&
                subjects.isNotEmpty &&
                subjects.first.teacherId != null
            ? subjects.first.teacherId
            : null;

        // Filter teachers based on search query
        final filteredTeachers = _teacherSearchQuery.isEmpty
            ? _availableTeachers
            : _availableTeachers.where((teacher) {
                final name = teacher.displayName.toLowerCase();
                return name.contains(_teacherSearchQuery.toLowerCase());
              }).toList();

        return Container(
          width: 250,
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(6),
                child: TextField(
                  controller: _teacherSearchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Search teachers...',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setMenuState(() {
                      _teacherSearchQuery = value;
                    });
                  },
                ),
              ),
              const Divider(height: 1),
              // Teacher list
              if (_isLoadingTeachers)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    children: [
                      // Show all teachers
                      ...filteredTeachers.map((teacher) {
                        return _buildTeacherItem(
                          teacher,
                          subjectName,
                          currentTeacherId,
                        );
                      }),
                      // No results message
                      if (filteredTeachers.isEmpty &&
                          _teacherSearchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'No teachers found',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual teacher item
  Widget _buildTeacherItem(
    Teacher teacher,
    String subjectName,
    String? currentTeacherId,
  ) {
    final isAssigned = teacher.id == currentTeacherId;

    return InkWell(
      onTap: () async {
        if (isAssigned) {
          // Remove teacher assignment
          await _removeTeacherFromSubject(subjectName);
        } else {
          // Assign teacher
          await _assignTeacherToSubject(teacher, subjectName);
        }
        _closeTeacherOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: isAssigned ? Colors.blue.shade50 : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                teacher.displayName,
                style: TextStyle(
                  fontSize: 11,
                  color: isAssigned ? Colors.blue.shade700 : Colors.black87,
                  fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isAssigned)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Assign teacher to subject
  Future<void> _assignTeacherToSubject(
    Teacher teacher,
    String subjectName,
  ) async {
    if (widget.isCreateMode) {
      // CREATE MODE: Update temporary state
      print(
        '➕ [CREATE MODE] Assigning teacher ${teacher.displayName} to $subjectName',
      );

      // Check if subject exists in _existingSubjects
      if (!_existingSubjects.containsKey(subjectName) ||
          _existingSubjects[subjectName]!.isEmpty) {
        // Auto-create the subject entry if it doesn't exist
        print('   Creating temporary subject entry for $subjectName');
        _existingSubjects[subjectName] = [
          ClassroomSubject(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            classroomId: 'temp',
            subjectName: subjectName,
            teacherId: teacher.id, // Assign teacher immediately
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      } else {
        // Update existing subject's teacher ID
        print('   Updating existing subject entry for $subjectName');
        final updatedSubject = _existingSubjects[subjectName]!.first.copyWith(
          teacherId: teacher.id,
          updatedAt: DateTime.now(),
        );
        _existingSubjects[subjectName]![0] = updatedSubject;
      }

      print(
        '   ✅ Teacher assigned: ${_existingSubjects[subjectName]!.first.teacherId}',
      );

      // Save to SharedPreferences FIRST (before setState)
      await _saveTemporarySubjects();

      // Then update UI
      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${teacher.displayName} assigned to $subjectName'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // EDIT MODE: Update in database
      try {
        final subjects = _existingSubjects[subjectName];
        if (subjects != null && subjects.isNotEmpty) {
          final subjectId = subjects.first.id;

          await _subjectService.updateSubject(
            subjectId: subjectId,
            teacherId: teacher.id,
          );

          if (mounted) {
            setState(() {
              final updatedSubject = subjects.first.copyWith(
                teacherId: teacher.id,
                updatedAt: DateTime.now(),
              );
              _existingSubjects[subjectName]![0] = updatedSubject;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${teacher.displayName} assigned to $subjectName',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error assigning teacher: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error assigning teacher: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Remove teacher from subject
  Future<void> _removeTeacherFromSubject(String subjectName) async {
    print('🗑️ [REMOVE] Attempting to remove teacher from $subjectName');

    if (widget.isCreateMode) {
      // CREATE MODE: Update temporary state
      print('➕ [CREATE MODE] Removing teacher from temporary state');

      final subjects = _existingSubjects[subjectName];
      if (subjects != null && subjects.isNotEmpty) {
        print('   Current teacher ID: ${subjects.first.teacherId}');

        if (mounted) {
          // Remove teacher ID using clearTeacherId flag
          final updatedSubject = subjects.first.copyWith(
            clearTeacherId: true, // Use the special flag to clear teacherId
            updatedAt: DateTime.now(),
          );
          print('   🔍 Updated subject teacherId: ${updatedSubject.teacherId}');

          _existingSubjects[subjectName]![0] = updatedSubject;
          print(
            '   ✅ Teacher removed, teacherId in map is now: ${_existingSubjects[subjectName]![0].teacherId}',
          );
          print('   🔍 subjects.first.teacherId: ${subjects.first.teacherId}');

          // Save to SharedPreferences FIRST (before setState)
          await _saveTemporarySubjects();
          print('   💾 Saved to SharedPreferences');

          // Then update UI
          if (mounted) {
            setState(() {});

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Teacher removed from $subjectName'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        print('   ⚠️ No subject found in _existingSubjects for $subjectName');
      }
    } else {
      // EDIT MODE: Update in database
      print('📝 [EDIT MODE] Removing teacher from database');

      try {
        final subjects = _existingSubjects[subjectName];
        if (subjects != null && subjects.isNotEmpty) {
          final subjectId = subjects.first.id;
          print('   Subject ID: $subjectId');

          await _subjectService.updateSubject(
            subjectId: subjectId,
            teacherId: null,
          );

          if (mounted) {
            setState(() {
              final updatedSubject = subjects.first.copyWith(
                clearTeacherId: true, // Use the special flag to clear teacherId
                updatedAt: DateTime.now(),
              );
              _existingSubjects[subjectName]![0] = updatedSubject;
            });

            print('   ✅ Teacher removed from database');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Teacher removed from $subjectName'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error removing teacher: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing teacher: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.85; // 85% of screen width
    final dialogHeight = screenSize.height * 0.85; // 85% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Header with mode indicator and close button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.isCreateMode
                            ? Icons.add_circle_outline
                            : Icons.edit_outlined,
                        size: 20,
                        color: widget.isCreateMode
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isCreateMode
                            ? 'Create Classroom'
                            : 'Edit Classroom',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isCreateMode
                              ? Colors.green.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // School level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isJHS
                              ? Colors.blue.shade50
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isJHS
                                ? Colors.blue.shade200
                                : Colors.purple.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.isJHS
                              ? 'JHS'
                              : widget.isSHS
                              ? 'SHS'
                              : '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.isJHS
                                ? Colors.blue.shade700
                                : Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Two-panel layout: Left sidebar + Right main content
            Expanded(
              child: Row(
                children: [
                  // LEFT SIDEBAR - Subject List
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildLeftSidebar(),
                  ),

                  // RIGHT MAIN CONTENT - Subject Details
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build left sidebar with subject list
  Widget _buildLeftSidebar() {
    if (widget.isJHS) {
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final subject in _jhsSubjects) _buildSubjectItem(subject),
            ],
          ),
        ),
      );
    } else if (widget.isSHS) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'SHS subjects coming soon...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Build main content area (right side)
  Widget _buildMainContent() {
    if (_selectedSubject == null) {
      // Empty state - no subject selected
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Select a subject to view details',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Subject selected - show details
    return _buildSubjectDetails(_selectedSubject!);
  }

  /// Build subject details view
  Widget _buildSubjectDetails(String subjectName) {
    final subjects = _existingSubjects[subjectName];
    ClassroomSubject subject;

    // If subject doesn't exist yet, create a temporary one for display
    if (subjects == null || subjects.isEmpty) {
      print(
        '⚠️ [SUBJECT DETAILS] Subject "$subjectName" not in _existingSubjects, creating temporary subject',
      );

      final now = DateTime.now();
      // Create a temporary subject for display purposes
      subject = ClassroomSubject(
        id: 'temp_${now.millisecondsSinceEpoch}',
        classroomId: widget.classroomId ?? 'temp',
        subjectName: subjectName,
        teacherId: null,
        parentSubjectId: null,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      print('   Created temporary subject with ID: ${subject.id}');
    } else {
      subject = subjects.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject resources content (Content 2) - ALWAYS RENDER
        Expanded(
          child: FutureBuilder<String?>(
            future: _getUserRoleOnce(),
            builder: (context, snapshot) {
              // Show loading only briefly
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              // Handle error case
              if (snapshot.hasError) {
                print(
                  '⚠️ [ROLE FETCH] Error fetching user role: ${snapshot.error}',
                );
                return Center(
                  child: Text(
                    'Error loading user permissions',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
                );
              }

              final userRole = snapshot.data;
              final isAdmin = _isAdminRole(userRole);

              print('✅ [SUBJECT DETAILS] Rendering SubjectResourcesContent');
              print('   Subject: ${subject.subjectName}');
              print('   User Role: $userRole');
              print('   Is Admin: $isAdmin');

              return SubjectResourcesContent(
                subject: subject,
                classroomId: widget.classroomId ?? 'temp',
                isCreateMode: widget.classroomId == null,
                isAdmin: isAdmin,
                currentUserId: Supabase.instance.client.auth.currentUser?.id,
                userRole: userRole,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectItem(String subject) {
    final isExpanded = _expandedSubjects[subject] ?? false;
    final subSubjects = _getSubSubjects(subject);
    final isSelected = _selectedSubject == subject;

    // Check if teacher is assigned
    final subjects = _existingSubjects[subject];
    final hasTeacher =
        subjects != null &&
        subjects.isNotEmpty &&
        subjects.first.teacherId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              // Select this subject to show in main content
              _selectedSubject = subject;
              _mainContentMode = 'subject_details';
            });
          },
          hoverColor: Colors.grey.shade100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                // Expand/collapse icon
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSubjects[subject] = !isExpanded;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subject,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blue.shade900
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                // Sub-subject button (account_tree icon)
                Tooltip(
                  message: 'Add sub-subject',
                  child: InkWell(
                    onTap: () {
                      _addSubSubject(subject);
                    },
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.account_tree,
                        size: 10,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Teacher assignment button (person icon) with badge
                Tooltip(
                  message: 'Assign teacher',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        key: _subjectButtonKeys[subject],
                        onTap: () {
                          _assignTeacher(subject);
                        },
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      // Green checkmark badge when teacher is assigned
                      if (hasTeacher)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Plus button (add module)
                Tooltip(
                  message: 'Add subject',
                  child: InkWell(
                    onTap: () {
                      _addSubject(subject);
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
                ),
                const SizedBox(width: 8),
                // Count badge showing number of existing subjects
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_existingSubjects[subject]?.length ?? 0}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded content - show sub-subjects in nested tree
        if (isExpanded && subSubjects.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final subSubject in subSubjects)
                  _buildSubSubjectItem(subSubject, subject),
              ],
            ),
          ),
      ],
    );
  }

  /// Build a sub-subject item (nested under parent)
  Widget _buildSubSubjectItem(ClassroomSubject subSubject, String parentName) {
    final subSubjectKey = '${parentName}_${subSubject.subjectName}';
    final isExpanded = _expandedSubjects[subSubjectKey] ?? false;
    final isSelected = _selectedSubject == subSubject.subjectName;

    // Check if teacher is assigned to this sub-subject
    final hasTeacher = subSubject.teacherId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              // Select this sub-subject to show in main content
              _selectedSubject = subSubject.subjectName;
              _mainContentMode = 'subject_details';
            });
          },
          hoverColor: Colors.grey.shade100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(left: 20, bottom: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                // Expand/collapse icon
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSubjects[subSubjectKey] = !isExpanded;
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subSubject.subjectName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.blue.shade900
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                // Edit button
                Tooltip(
                  message: 'Edit sub-subject',
                  child: InkWell(
                    onTap: () {
                      _editSubSubject(subSubject, parentName);
                    },
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 9,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                Tooltip(
                  message: 'Delete sub-subject',
                  child: InkWell(
                    onTap: () {
                      _deleteSubSubject(subSubject, parentName);
                    },
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.delete,
                        size: 9,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Teacher assignment for sub-subject with badge
                Tooltip(
                  message: 'Assign teacher',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        key: _subjectButtonKeys[subSubject.id],
                        onTap: () {
                          _assignTeacher(subSubject.subjectName);
                        },
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 9,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      // Green checkmark badge when teacher is assigned
                      if (hasTeacher)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Module count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '0',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded content for sub-subject (placeholder for modules, etc.)
        if (isExpanded)
          Container(
            padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
            child: Text(
              'Modules and content for ${subSubject.subjectName}...',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Get sub-subjects for a parent subject
  List<ClassroomSubject> _getSubSubjects(String parentSubjectName) {
    print('🔍 [GET-SUBS] Looking for sub-subjects of "$parentSubjectName"');

    final parentSubjects = _existingSubjects[parentSubjectName];
    if (parentSubjects == null || parentSubjects.isEmpty) {
      print(
        '🔍 [GET-SUBS] Parent "$parentSubjectName" not found in _existingSubjects',
      );
      return [];
    }

    final parentSubjectId = parentSubjects.first.id;
    print('🔍 [GET-SUBS] Parent ID: $parentSubjectId');

    // Find all subjects that have this parent
    final List<ClassroomSubject> subSubjects = [];
    for (final subjects in _existingSubjects.values) {
      for (final subject in subjects) {
        if (subject.parentSubjectId == parentSubjectId) {
          subSubjects.add(subject);
          print(
            '🔍 [GET-SUBS] Found sub-subject: "${subject.subjectName}" (ID: ${subject.id})',
          );
        }
      }
    }

    print('🔍 [GET-SUBS] Total sub-subjects found: ${subSubjects.length}');
    return subSubjects;
  }

  /// Get user role once (simple, no caching needed - AuthGate already handles this)
  Future<String?> _getUserRoleOnce() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('id', userId)
          .maybeSingle();

      return response?['roles']?['name'];
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  /// Simple check if user has admin-like permissions
  bool _isAdminRole(String? userRole) {
    if (userRole == null) return false;
    final role = userRole.toLowerCase();
    return role == 'admin' || role == 'ict_coordinator' || role == 'hybrid';
  }
}
