import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeEntryDialog extends StatefulWidget {
  final String studentName;
  final String studentLrn;
  final Map<String, int> currentGrades;
  final Function(Map<String, int>) onSave;

  const GradeEntryDialog({
    super.key,
    required this.studentName,
    required this.studentLrn,
    required this.currentGrades,
    required this.onSave,
  });

  @override
  State<GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<GradeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  final List<Map<String, String>> _subjects = [
    {'key': 'mathematics', 'label': 'Mathematics'},
    {'key': 'science', 'label': 'Science'},
    {'key': 'english', 'label': 'English'},
    {'key': 'filipino', 'label': 'Filipino'},
    {'key': 'socialStudies', 'label': 'Social Studies'},
    {'key': 'mapeh', 'label': 'MAPEH'},
    {'key': 'tle', 'label': 'TLE'},
    {'key': 'values', 'label': 'Values Education'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current grades
    for (var subject in _subjects) {
      final key = subject['key']!;
      _controllers[key] = TextEditingController(
        text: widget.currentGrades[key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Grades'),
          const SizedBox(height: 4),
          Text(
            widget.studentName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            'LRN: ${widget.studentLrn}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      Expanded(
                        child: Text(
                          'DepEd Grading Scale: 75-100 (75 is passing)',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._subjects.map((subject) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: _controllers[subject['key']],
                      decoration: InputDecoration(
                        labelText: subject['label'],
                        border: const OutlineInputBorder(),
                        suffixText: '/100',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Grade is required';
                        }
                        final grade = int.tryParse(value);
                        if (grade == null) {
                          return 'Invalid grade';
                        }
                        if (grade < 0 || grade > 100) {
                          return 'Grade must be between 0-100';
                        }
                        if (grade > 0 && grade < 75) {
                          return 'Warning: Below passing grade (75)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Auto-calculate average
                        setState(() {});
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildAverageDisplay(),
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
          onPressed: _isSaving ? null : _saveGrades,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Grades'),
        ),
      ],
    );
  }

  Widget _buildAverageDisplay() {
    double total = 0;
    int count = 0;

    for (var controller in _controllers.values) {
      if (controller.text.isNotEmpty) {
        final grade = int.tryParse(controller.text);
        if (grade != null) {
          total += grade;
          count++;
        }
      }
    }

    final average = count > 0 ? total / count : 0;
    final isPassing = average >= 75;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPassing ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPassing ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Average Grade:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPassing ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
          Text(
            average.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPassing ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGrades() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Collect grades
    final grades = <String, int>{};
    for (var subject in _subjects) {
      final key = subject['key']!;
      final value = _controllers[key]!.text;
      if (value.isNotEmpty) {
        grades[key] = int.parse(value);
      }
    }

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      widget.onSave(grades);
      Navigator.pop(context);
    }
  }
}
