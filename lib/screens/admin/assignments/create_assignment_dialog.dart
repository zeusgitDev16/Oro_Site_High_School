import 'package:flutter/material.dart';

class CreateAssignmentDialog extends StatefulWidget {
  final Map<String, dynamic>? assignment;
  final VoidCallback onSave;

  const CreateAssignmentDialog({
    super.key,
    this.assignment,
    required this.onSave,
  });

  @override
  State<CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  
  String? _selectedCourse;
  String? _selectedType;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _allowLateSubmission = true;
  bool _isSaving = false;

  final List<String> _courses = [
    'Mathematics 7',
    'Science 8',
    'English 9',
    'Filipino 10',
  ];

  final List<String> _types = [
    'Problem Set',
    'Essay',
    'Lab Report',
    'Project',
    'Quiz',
    'Exam',
    'Analysis',
    'Presentation',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.assignment != null) {
      _titleController.text = widget.assignment!['title'];
      _descriptionController.text = widget.assignment!['description'] ?? '';
      _selectedCourse = widget.assignment!['course'];
      _selectedType = widget.assignment!['type'];
      // Parse due date if needed
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.assignment != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Assignment' : 'Create New Assignment'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title *',
                    hintText: 'e.g., Algebra Problem Set 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCourse,
                        decoration: const InputDecoration(
                          labelText: 'Course *',
                          border: OutlineInputBorder(),
                        ),
                        items: _courses.map((course) {
                          return DropdownMenuItem(value: course, child: Text(course));
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Course is required';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedCourse = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        validator: (value) {
                          if (value == null) {
                            return 'Type is required';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide instructions and details...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDueDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _dueDate != null
                              ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                              : 'Select Due Date *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDueTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          _dueTime != null
                              ? _dueTime!.format(context)
                              : 'Select Time *',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Total Points',
                    hintText: '100',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Allow Late Submission'),
                  subtitle: Text(
                    _allowLateSubmission
                        ? 'Students can submit after due date'
                        : 'Submissions locked after due date',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _allowLateSubmission,
                  onChanged: (value) {
                    setState(() {
                      _allowLateSubmission = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Students will be notified when the assignment is created',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAssignment,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dueDate == null || _dueTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select due date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      Navigator.pop(context);
      widget.onSave();
    }
  }
}
