import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_editor_header.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_editor_widget.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_viewer_widget.dart';

/// Reusable classroom main content area widget
///
/// This widget supports three modes:
/// - **create**: Shows the classroom editor for creating a new classroom
/// - **view**: Shows the classroom viewer for viewing an existing classroom
/// - **edit**: Shows the classroom editor for editing an existing classroom
///
/// It provides the complete main content area for classroom management including:
/// - Header with mode indicator and action buttons
/// - Classroom editor form (create/edit mode)
/// - Classroom viewer (view mode)
///
/// **Usage Example:**
/// ```dart
/// ClassroomMainContent(
///   currentMode: _currentMode, // 'create', 'view', or 'edit'
///   isSaving: _isSavingClassroom,
///   config: ClassroomEditorConfig.admin(),
///   titleController: _titleController,
///   selectedAdvisoryTeacher: _selectedAdvisoryTeacher,
///   selectedClassroom: _selectedClassroom, // For view/edit mode
///   availableTeachers: _teachers,
///   isMenuOpen: _isMenuOpen,
///   layerLink: _layerLink,
///   buttonKey: _buttonKey,
///   onToggleMenu: _toggleMenu,
///   onCreateNew: () {
///     setState(() {
///       _currentMode = 'create';
///       _titleController.clear();
///       _selectedAdvisoryTeacher = null;
///       _selectedClassroom = null;
///     });
///   },
///   onSave: () async {
///     await _saveClassroom();
///   },
///   onEdit: () {
///     setState(() => _currentMode = 'edit');
///   },
///   onAdvisoryTeacherChanged: (teacher) {
///     setState(() => _selectedAdvisoryTeacher = teacher);
///   },
/// )
/// ```
class ClassroomMainContent extends StatelessWidget {
  /// Current mode: 'create', 'view', or 'edit'
  final String currentMode;

  /// Whether the save operation is in progress
  final bool isSaving;

  /// Configuration for editor permissions
  final ClassroomEditorConfig config;

  /// Text controller for classroom title
  final TextEditingController titleController;

  /// Currently selected advisory teacher
  final Teacher? selectedAdvisoryTeacher;

  /// Currently selected classroom (for view/edit mode)
  final Classroom? selectedClassroom;

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

  /// Callback when "Create New" button is pressed
  final VoidCallback? onCreateNew;

  /// Callback when "Save" button is pressed
  final VoidCallback? onSave;

  /// Callback when "Edit" button is pressed (in view mode)
  final VoidCallback? onEdit;

  /// Callback when advisory teacher is changed
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

  const ClassroomMainContent({
    super.key,
    required this.currentMode,
    required this.isSaving,
    required this.config,
    required this.titleController,
    this.selectedAdvisoryTeacher,
    this.selectedClassroom,
    required this.availableTeachers,
    required this.isMenuOpen,
    required this.layerLink,
    required this.buttonKey,
    required this.onToggleMenu,
    this.onCreateNew,
    this.onSave,
    this.onEdit,
    required this.onAdvisoryTeacherChanged,
    this.selectedSchoolLevel,
    this.selectedGradeLevel,
    this.selectedQuarter,
    this.selectedSemester,
    this.selectedAcademicTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with mode indicator and action buttons
          ClassroomEditorHeader(
            currentMode: currentMode,
            isSaving: isSaving,
            canCreate: config.canCreate,
            canEdit: config.canEdit,
            onCreateNew: onCreateNew,
            onSave: onSave,
          ),
          // Content based on mode
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Build content based on current mode
  Widget _buildContent() {
    switch (currentMode) {
      case 'view':
        // View mode: Show classroom viewer
        if (selectedClassroom == null) {
          return _buildEmptyState('No classroom selected');
        }
        return ClassroomViewerWidget(
          classroom: selectedClassroom!,
          advisoryTeacher: selectedAdvisoryTeacher,
          onEdit: onEdit,
          canEdit: config.canEdit,
        );

      case 'create':
      case 'edit':
        // Create/Edit mode: Show classroom editor with settings indicators
        return ClassroomEditorWidget(
          config: config,
          titleController: titleController,
          selectedAdvisoryTeacher: selectedAdvisoryTeacher,
          availableTeachers: availableTeachers,
          isMenuOpen: isMenuOpen,
          layerLink: layerLink,
          buttonKey: buttonKey,
          onToggleMenu: onToggleMenu,
          onAdvisoryTeacherChanged: onAdvisoryTeacherChanged,
          selectedSchoolLevel: selectedSchoolLevel,
          selectedGradeLevel: selectedGradeLevel,
          selectedQuarter: selectedQuarter,
          selectedSemester: selectedSemester,
          selectedAcademicTrack: selectedAcademicTrack,
          classroomId: currentMode == 'edit' ? selectedClassroom?.id : null,
        );

      default:
        return _buildEmptyState('Invalid mode: $currentMode');
    }
  }

  /// Build empty state message
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
