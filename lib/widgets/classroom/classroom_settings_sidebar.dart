import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable classroom settings sidebar widget
///
/// This widget provides the right sidebar for classroom settings including:
/// - School Level selection (JHS/SHS)
/// - Quarter/Semester indicators
/// - Grade Level selection
/// - Student Limit input
///
/// **Usage Example:**
/// ```dart
/// ClassroomSettingsSidebar(
///   selectedSchoolLevel: _selectedSchoolLevel,
///   selectedQuarter: _selectedQuarter,
///   selectedSemester: _selectedSemester,
///   selectedGradeLevel: _selectedGradeLevel,
///   maxStudents: _maxStudents,
///   canEdit: true, // Based on user role
///   onSchoolLevelChanged: (value) {
///     setState(() => _selectedSchoolLevel = value);
///   },
///   onQuarterChanged: (value) {
///     setState(() => _selectedQuarter = value);
///   },
///   onSemesterChanged: (value) {
///     setState(() => _selectedSemester = value);
///   },
///   onGradeLevelChanged: (value) {
///     setState(() => _selectedGradeLevel = value);
///   },
///   onMaxStudentsChanged: (value) {
///     setState(() => _maxStudents = value);
///   },
/// )
/// ```
class ClassroomSettingsSidebar extends StatelessWidget {
  /// Currently selected school level (Junior High School or Senior High School)
  final String selectedSchoolLevel;

  /// Currently selected quarter (1-4) for JHS, null if not selected
  final int? selectedQuarter;

  /// Currently selected semester (1-2) for SHS, null if not selected
  final int? selectedSemester;

  /// Currently selected grade level (7-12), null if not selected
  final int? selectedGradeLevel;

  /// Currently selected academic track for SHS (ABM, STEM, HUMSS, GAS), null if not selected
  final String? selectedAcademicTrack;

  /// Maximum number of students allowed in the classroom (1-100)
  final int maxStudents;

  /// Whether the user can edit these settings
  final bool canEdit;

  /// Callback when school level changes
  final ValueChanged<String> onSchoolLevelChanged;

  /// Callback when quarter changes
  final ValueChanged<int?> onQuarterChanged;

  /// Callback when semester changes
  final ValueChanged<int?> onSemesterChanged;

  /// Callback when grade level changes
  final ValueChanged<int?> onGradeLevelChanged;

  /// Callback when academic track changes
  final ValueChanged<String?> onAcademicTrackChanged;

  /// Callback when max students changes
  final ValueChanged<int> onMaxStudentsChanged;

  const ClassroomSettingsSidebar({
    super.key,
    required this.selectedSchoolLevel,
    required this.selectedQuarter,
    required this.selectedSemester,
    required this.selectedGradeLevel,
    this.selectedAcademicTrack,
    required this.maxStudents,
    required this.canEdit,
    required this.onSchoolLevelChanged,
    required this.onQuarterChanged,
    required this.onSemesterChanged,
    required this.onGradeLevelChanged,
    required this.onAcademicTrackChanged,
    required this.onMaxStudentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CLASSROOM SETTINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // School Level Dropdown
            const Text(
              'School Level*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSchoolLevel,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey,
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  items: const [
                    DropdownMenuItem(
                      value: 'Junior High School',
                      child: Text('Junior High School'),
                    ),
                    DropdownMenuItem(
                      value: 'Senior High School',
                      child: Text('Senior High School'),
                    ),
                  ],
                  onChanged: canEdit
                      ? (String? newValue) {
                          if (newValue != null) {
                            onSchoolLevelChanged(newValue);
                            // Reset quarter/semester when school level changes
                            if (newValue == 'Senior High School') {
                              onQuarterChanged(null);
                            } else {
                              onSemesterChanged(null);
                            }
                          }
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quarter/Semester Indicators
            if (selectedSchoolLevel == 'Junior High School') ...[
              const Text(
                'Quarter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  final quarter = index + 1;
                  final isSelected = selectedQuarter == quarter;

                  return GestureDetector(
                    onTap: canEdit
                        ? () {
                            onQuarterChanged(isSelected ? null : quarter);
                          }
                        : null,
                    child: MouseRegion(
                      cursor: canEdit
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade400
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          'Q$quarter',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            if (selectedSchoolLevel == 'Senior High School') ...[
              const Text(
                'Semester',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(2, (index) {
                  final semester = index + 1;
                  final isSelected = selectedSemester == semester;

                  return GestureDetector(
                    onTap: canEdit
                        ? () {
                            onSemesterChanged(isSelected ? null : semester);
                          }
                        : null,
                    child: MouseRegion(
                      cursor: canEdit
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade400
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '${semester}st Sem',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            // Academic Track (only for SHS)
            if (selectedSchoolLevel == 'Senior High School') ...[
              const SizedBox(height: 16),
              const Text(
                'Academic Track',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['ABM', 'STEM', 'HUMSS', 'GAS'].map((track) {
                  final isSelected = selectedAcademicTrack == track;

                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: canEdit
                          ? () {
                              onAcademicTrackChanged(isSelected ? null : track);
                            }
                          : null,
                      child: MouseRegion(
                        cursor: canEdit
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.purple.shade400
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            track,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.purple.shade700
                                  : Colors.grey.shade600,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Grade Level Dropdown
            const Text(
              'Grade Level*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple.shade300),
                borderRadius: BorderRadius.circular(6),
                color: Colors.purple.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedGradeLevel,
                  isExpanded: true,
                  hint: Text(
                    'Select Grade *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade600,
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.purple.shade600,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  items:
                      (selectedSchoolLevel == 'Junior High School'
                              ? [7, 8, 9, 10]
                              : [11, 12])
                          .map((grade) {
                            return DropdownMenuItem(
                              value: grade,
                              child: Text('Grade $grade'),
                            );
                          })
                          .toList(),
                  onChanged: canEdit
                      ? (int? newValue) {
                          onGradeLevelChanged(newValue);
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Limit Field
            const Text(
              'Student Limit*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildStudentLimitField(),
          ],
        ),
      ),
    );
  }

  /// Build the student limit input field
  Widget _buildStudentLimitField() {
    return _StudentLimitFieldWidget(
      maxStudents: maxStudents,
      canEdit: canEdit,
      onMaxStudentsChanged: onMaxStudentsChanged,
    );
  }
}

/// Stateful widget for student limit field with text input
class _StudentLimitFieldWidget extends StatefulWidget {
  final int maxStudents;
  final bool canEdit;
  final ValueChanged<int> onMaxStudentsChanged;

  const _StudentLimitFieldWidget({
    required this.maxStudents,
    required this.canEdit,
    required this.onMaxStudentsChanged,
  });

  @override
  State<_StudentLimitFieldWidget> createState() =>
      _StudentLimitFieldWidgetState();
}

class _StudentLimitFieldWidgetState extends State<_StudentLimitFieldWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.maxStudents}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_StudentLimitFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text when maxStudents changes externally (e.g., from +/- buttons)
    if (widget.maxStudents != oldWidget.maxStudents && !_isEditing) {
      _controller.text = '${widget.maxStudents}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitValue();
    }
  }

  void _submitValue() {
    setState(() {
      _isEditing = false;
    });

    final text = _controller.text.trim();
    if (text.isEmpty) {
      // Reset to current value if empty
      _controller.text = '${widget.maxStudents}';
      return;
    }

    final value = int.tryParse(text);
    if (value == null) {
      // Invalid number, reset to current value
      _controller.text = '${widget.maxStudents}';
      return;
    }

    // Clamp value between 1 and 100
    final clampedValue = value.clamp(1, 100);
    _controller.text = '$clampedValue';

    if (clampedValue != widget.maxStudents) {
      widget.onMaxStudentsChanged(clampedValue);
    }
  }

  void _increment() {
    if (widget.maxStudents < 100) {
      widget.onMaxStudentsChanged(widget.maxStudents + 1);
    }
  }

  void _decrement() {
    if (widget.maxStudents > 1) {
      widget.onMaxStudentsChanged(widget.maxStudents - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Decrement button
          _buildAdjustButton(
            icon: CupertinoIcons.minus,
            onTap: widget.canEdit && widget.maxStudents > 1 ? _decrement : null,
          ),
          // Editable value field
          Expanded(
            child: GestureDetector(
              onTap: widget.canEdit
                  ? () {
                      setState(() {
                        _isEditing = true;
                      });
                      _focusNode.requestFocus();
                      _controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controller.text.length,
                      );
                    }
                  : null,
              child: MouseRegion(
                cursor: widget.canEdit
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.basic,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.canEdit,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submitValue(),
                    onChanged: (value) {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          // Increment button
          _buildAdjustButton(
            icon: CupertinoIcons.add,
            onTap: widget.canEdit && widget.maxStudents < 100
                ? _increment
                : null,
          ),
        ],
      ),
    );
  }

  /// Build increment/decrement button
  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isEnabled ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
