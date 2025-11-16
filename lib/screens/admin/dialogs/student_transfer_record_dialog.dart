import 'package:flutter/material.dart';

import 'package:oro_site_high_school/models/student_transfer_record.dart';
import 'package:oro_site_high_school/services/student_transfer_record_service.dart';

class StudentTransferRecordDialog extends StatefulWidget {
  const StudentTransferRecordDialog({
    super.key,
    required this.students,
    this.record,
    this.student,
    this.initialSchoolYear,
    this.onSaved,
  });

  final List<Map<String, dynamic>> students;
  final StudentTransferRecord? record;
  final Map<String, dynamic>? student;
  final String? initialSchoolYear;
  final void Function(StudentTransferRecord record)? onSaved;

  @override
  State<StudentTransferRecordDialog> createState() =>
      _StudentTransferRecordDialogState();
}

class _StudentTransferRecordDialogState
    extends State<StudentTransferRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final StudentTransferRecordService _service = StudentTransferRecordService();

  late final TextEditingController _studentFieldController;
  late final TextEditingController _schoolYearController;
  late final TextEditingController _eligibilityController;
  late final TextEditingController _admittedGradeController;
  late final TextEditingController _admittedSectionController;
  late final TextEditingController _fromSchoolController;
  late final TextEditingController _toSchoolController;
  late final TextEditingController _canceledInController;

  String? _selectedStudentId;
  DateTime? _admissionDate;
  DateTime? _cancellationDate;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    final student = widget.student;

    _selectedStudentId = record?.studentId ?? student?['id']?.toString();
    _isActive = record?.isActive ?? true;

    _studentFieldController = TextEditingController(
      text: _buildStudentDisplay(student),
    );
    _schoolYearController = TextEditingController(
      text: record?.schoolYear ?? (widget.initialSchoolYear ?? ''),
    );
    _eligibilityController = TextEditingController(
      text: record?.eligibilityForAdmissionGrade ?? '',
    );
    _admittedGradeController = TextEditingController(
      text: record?.admittedGrade?.toString() ?? '',
    );
    _admittedSectionController = TextEditingController(
      text: record?.admittedSection ?? '',
    );
    _fromSchoolController = TextEditingController(
      text: record?.fromSchool ?? '',
    );
    _toSchoolController = TextEditingController(text: record?.toSchool ?? '');
    _canceledInController = TextEditingController(
      text: record?.canceledIn ?? '',
    );

    _admissionDate = record?.admissionDate;
    _cancellationDate = record?.cancellationDate;
  }

  String _buildStudentDisplay(Map<String, dynamic>? student) {
    if (student == null) return '';
    final name = student['display_name'] as String? ?? '';
    final lrn = student['lrn'] as String? ?? '';
    if (lrn.isEmpty) return name;
    return '$name ($lrn)';
  }

  @override
  void dispose() {
    _studentFieldController.dispose();
    _schoolYearController.dispose();
    _eligibilityController.dispose();
    _admittedGradeController.dispose();
    _admittedSectionController.dispose();
    _fromSchoolController.dispose();
    _toSchoolController.dispose();
    _canceledInController.dispose();
    super.dispose();
  }

  Future<void> _pickAdmissionDate() async {
    if (!mounted) return;
    final initial = _admissionDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _admissionDate = picked);
  }

  Future<void> _pickCancellationDate() async {
    if (!mounted) return;
    final initial = _cancellationDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _cancellationDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a student.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final admittedGrade = int.tryParse(_admittedGradeController.text.trim());
      final record = await _service.saveTransferRecord(
        studentId: _selectedStudentId!,
        schoolYear: _schoolYearController.text.trim(),
        eligibilityForAdmissionGrade: _eligibilityController.text.trim().isEmpty
            ? null
            : _eligibilityController.text.trim(),
        admittedGrade: admittedGrade,
        admittedSection: _admittedSectionController.text.trim().isEmpty
            ? null
            : _admittedSectionController.text.trim(),
        admissionDate: _admissionDate,
        fromSchool: _fromSchoolController.text.trim().isEmpty
            ? null
            : _fromSchoolController.text.trim(),
        toSchool: _toSchoolController.text.trim().isEmpty
            ? null
            : _toSchoolController.text.trim(),
        canceledIn: _canceledInController.text.trim().isEmpty
            ? null
            : _canceledInController.text.trim(),
        cancellationDate: _cancellationDate,
        isActive: _isActive,
      );
      widget.onSaved?.call(record);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Transfer record saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.record != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Transfer Record' : 'New Transfer Record'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentField(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _schoolYearController,
                  decoration: const InputDecoration(
                    labelText: 'School Year *',
                    hintText: 'e.g., 2024-2025',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'School year is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _eligibilityController,
                        decoration: const InputDecoration(
                          labelText: 'Eligibility for Admission',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _admittedGradeController,
                        decoration: const InputDecoration(
                          labelText: 'Admitted Grade',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _admittedSectionController,
                        decoration: const InputDecoration(
                          labelText: 'Admitted Section',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickAdmissionDate,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _admissionDate == null
                              ? 'Select Admission Date'
                              : '${_admissionDate!.year}-${_admissionDate!.month.toString().padLeft(2, '0')}-${_admissionDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickCancellationDate,
                        icon: const Icon(Icons.event_busy),
                        label: Text(
                          _cancellationDate == null
                              ? 'Select Cancellation Date'
                              : '${_cancellationDate!.year}-${_cancellationDate!.month.toString().padLeft(2, '0')}-${_cancellationDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fromSchoolController,
                        decoration: const InputDecoration(
                          labelText: 'From School',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _toSchoolController,
                        decoration: const InputDecoration(
                          labelText: 'To School',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _canceledInController,
                  decoration: const InputDecoration(
                    labelText: 'Cancelled In (e.g., Q3)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active record'),
                  subtitle: const Text(
                    'Only one active record per school year is typically expected.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: const Icon(Icons.save, size: 18),
          label: Text(isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildStudentField() {
    final isEdit = widget.record != null;
    if (isEdit) {
      final label = _buildStudentDisplay(widget.student);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Student'),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              label.isEmpty ? 'Unknown student' : label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student *'),
        const SizedBox(height: 4),
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => _buildStudentDisplay(option),
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.toLowerCase();
            if (query.isEmpty) {
              return widget.students;
            }
            return widget.students.where((s) {
              final name = (s['display_name'] as String? ?? '').toLowerCase();
              final lrn = (s['lrn'] as String? ?? '').toLowerCase();
              return name.contains(query) || lrn.contains(query);
            });
          },
          onSelected: (option) {
            setState(() {
              _selectedStudentId = option['id']?.toString();
              _studentFieldController.text = _buildStudentDisplay(option);
            });
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.text = _studentFieldController.text;
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or LRN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
        ),
      ],
    );
  }
}
