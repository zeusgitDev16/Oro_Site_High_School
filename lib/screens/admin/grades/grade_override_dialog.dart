import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeOverrideDialog extends StatefulWidget {
  final String studentName;
  final String studentLrn;
  final String subject;
  final int currentGrade;
  final Function(int newGrade, String reason) onOverride;

  const GradeOverrideDialog({
    super.key,
    required this.studentName,
    required this.studentLrn,
    required this.subject,
    required this.currentGrade,
    required this.onOverride,
  });

  @override
  State<GradeOverrideDialog> createState() => _GradeOverrideDialogState();
}

class _GradeOverrideDialogState extends State<GradeOverrideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newGradeController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _confirmOverride = false;
  bool _isSaving = false;

  // Mock override history
  final List<Map<String, dynamic>> _overrideHistory = [
    {
      'date': '2024-01-15',
      'originalGrade': 85,
      'newGrade': 88,
      'reason': 'Corrected calculation error',
      'overriddenBy': 'Principal Maria Santos',
    },
  ];

  @override
  void dispose() {
    _newGradeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text('Override Grade'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.studentName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            'LRN: ${widget.studentLrn} • ${widget.subject}',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grade overrides are logged and require justification. Use this feature responsibly.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Original grade display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Original Grade:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.currentGrade.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // New grade input
                TextFormField(
                  controller: _newGradeController,
                  decoration: InputDecoration(
                    labelText: 'New Grade *',
                    hintText: 'Enter new grade (75-100)',
                    border: const OutlineInputBorder(),
                    suffixText: '/100',
                    helperText: 'DepEd Grading Scale: 75-100',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New grade is required';
                    }
                    final grade = int.tryParse(value);
                    if (grade == null) {
                      return 'Invalid grade';
                    }
                    if (grade < 75 || grade > 100) {
                      return 'Grade must be between 75-100';
                    }
                    if (grade == widget.currentGrade) {
                      return 'New grade must be different from original';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                // Grade change indicator
                if (_newGradeController.text.isNotEmpty)
                  _buildGradeChangeIndicator(),
                const SizedBox(height: 16),
                // Reason input
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Override *',
                    hintText: 'Provide a detailed justification...',
                    border: OutlineInputBorder(),
                    helperText: 'Minimum 10 characters',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Reason is required';
                    }
                    if (value.length < 10) {
                      return 'Reason must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirmation checkbox
                CheckboxListTile(
                  value: _confirmOverride,
                  onChanged: (value) {
                    setState(() {
                      _confirmOverride = value ?? false;
                    });
                  },
                  title: const Text(
                    'I confirm that this grade override is justified and necessary',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                // Override history
                if (_overrideHistory.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Previous Overrides',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._overrideHistory.map((override) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  override['date'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${override['originalGrade']} → ${override['newGrade']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              override['reason'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: ${override['overriddenBy']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
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
          onPressed: (_isSaving || !_confirmOverride) ? null : _saveOverride,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Override Grade'),
        ),
      ],
    );
  }

  Widget _buildGradeChangeIndicator() {
    final newGrade = int.tryParse(_newGradeController.text);
    if (newGrade == null) return const SizedBox.shrink();

    final difference = newGrade - widget.currentGrade;
    final isIncrease = difference > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isIncrease ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncrease ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncrease ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isIncrease
                ? 'Grade will increase by $difference points'
                : 'Grade will decrease by ${difference.abs()} points',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isIncrease ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOverride() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_confirmOverride) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the override'),
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

      final newGrade = int.parse(_newGradeController.text);
      final reason = _reasonController.text;

      widget.onOverride(newGrade, reason);
      Navigator.pop(context);
    }
  }
}
