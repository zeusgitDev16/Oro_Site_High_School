import 'package:flutter/material.dart';

/// Reusable classroom editor header widget
///
/// This widget provides the header section for classroom editor including:
/// - Mode indicator (CREATE MODE / EDIT MODE)
/// - Action buttons (Create New, Save/Update)
/// - Loading states
///
/// **Usage Example:**
/// ```dart
/// ClassroomEditorHeader(
///   currentMode: _currentMode,
///   isSaving: _isSavingClassroom,
///   canCreate: true, // Based on user role
///   canEdit: true,
///   onCreateNew: () {
///     setState(() {
///       _currentMode = 'create';
///       _titleController.clear();
///       _selectedAdvisoryTeacher = null;
///     });
///   },
///   onSave: () async {
///     await _saveClassroom();
///   },
/// )
/// ```
class ClassroomEditorHeader extends StatelessWidget {
  /// Current mode: 'create' or 'edit'
  final String currentMode;

  /// Whether the save operation is in progress
  final bool isSaving;

  /// Whether the user can create new classrooms
  final bool canCreate;

  /// Whether the user can edit existing classrooms
  final bool canEdit;

  /// Callback when "Create New" button is pressed
  final VoidCallback? onCreateNew;

  /// Callback when "Save" button is pressed
  final VoidCallback? onSave;

  const ClassroomEditorHeader({
    super.key,
    required this.currentMode,
    required this.isSaving,
    this.canCreate = true,
    this.canEdit = true,
    this.onCreateNew,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Mode indicator
          _buildModeIndicator(),
          const Spacer(),
          // Action buttons
          if (currentMode == 'edit' && canCreate) ...[
            _buildCreateNewButton(),
            const SizedBox(width: 8),
          ],
          _buildSaveButton(),
        ],
      ),
    );
  }

  /// Build mode indicator badge
  Widget _buildModeIndicator() {
    final isCreateMode = currentMode == 'create';
    final color = isCreateMode ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCreateMode ? Icons.add_circle_outline : Icons.edit_outlined,
            size: 14,
            color: color.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isCreateMode ? 'CREATE MODE' : 'EDIT MODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Build "Create New" button
  Widget _buildCreateNewButton() {
    return InkWell(
      onTap: onCreateNew,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(
              'Create New',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Save" button (Create/Update)
  Widget _buildSaveButton() {
    final isCreateMode = currentMode == 'create';
    final buttonText = isSaving
        ? 'Saving...'
        : (isCreateMode ? 'Create' : 'Update');

    return InkWell(
      onTap: isSaving ? null : onSave,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSaving ? Colors.grey.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSaving ? Colors.grey.shade200 : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSaving
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                    ),
                  )
                : Icon(Icons.save, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              buttonText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isSaving ? Colors.grey.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
