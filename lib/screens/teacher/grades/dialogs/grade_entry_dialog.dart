import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradeEntryDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final String course;
  final String quarter;
  final Function(Map<String, double>) onSave;

  const GradeEntryDialog({
    super.key,
    required this.student,
    required this.course,
    required this.quarter,
    required this.onSave,
  });

  @override
  State<GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends State<GradeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wwController;
  late TextEditingController _ptController;
  late TextEditingController _qaController;
  double? _finalGrade;

  @override
  void initState() {
    super.initState();
    _wwController = TextEditingController(
      text: widget.student['writtenWorks']?.toStringAsFixed(1) ?? '',
    );
    _ptController = TextEditingController(
      text: widget.student['performanceTasks']?.toStringAsFixed(1) ?? '',
    );
    _qaController = TextEditingController(
      text: widget.student['quarterlyAssessment']?.toStringAsFixed(1) ?? '',
    );
    _computeFinalGrade();
  }

  @override
  void dispose() {
    _wwController.dispose();
    _ptController.dispose();
    _qaController.dispose();
    super.dispose();
  }

  void _computeFinalGrade() {
    final ww = double.tryParse(_wwController.text);
    final pt = double.tryParse(_ptController.text);
    final qa = double.tryParse(_qaController.text);

    if (ww != null && pt != null && qa != null) {
      setState(() {
        _finalGrade = (ww * 0.30) + (pt * 0.50) + (qa * 0.20);
      });
    } else {
      setState(() {
        _finalGrade = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentInfo(),
                      const SizedBox(height: 24),
                      _buildGradeInputs(),
                      const SizedBox(height: 24),
                      _buildFinalGrade(),
                      const SizedBox(height: 24),
                      _buildGradingScale(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.grade, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Text(
            'Enter Grade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  widget.student['name'].toString().substring(0, 1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'LRN: ${widget.student['lrn']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.school, widget.course),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.calendar_today, widget.quarter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade Components',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildGradeField(
          'Written Works (30%)',
          _wwController,
          Icons.edit_note,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildGradeField(
          'Performance Tasks (50%)',
          _ptController,
          Icons.assignment,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildGradeField(
          'Quarterly Assessment (20%)',
          _qaController,
          Icons.quiz,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildGradeField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixText: '/ 100',
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final grade = double.tryParse(value);
        if (grade == null) {
          return 'Invalid number';
        }
        if (grade < 0 || grade > 100) {
          return 'Must be 0-100';
        }
        return null;
      },
      onChanged: (_) => _computeFinalGrade(),
    );
  }

  Widget _buildFinalGrade() {
    final isPassing = _finalGrade != null && _finalGrade! >= 75;
    final gradeColor = _finalGrade == null
        ? Colors.grey
        : isPassing
            ? Colors.green
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradeColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: gradeColor),
              const SizedBox(width: 12),
              const Text(
                'Final Grade',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _finalGrade?.toStringAsFixed(2) ?? '--',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_finalGrade != null)
            Text(
              _getGradeRemark(_finalGrade!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: gradeColor,
              ),
            ),
        ],
      ),
    );
  }

  String _getGradeRemark(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  Widget _buildGradingScale() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'DepEd Grading Scale',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildScaleItem('90-100', 'Outstanding', Colors.green),
          _buildScaleItem('85-89', 'Very Satisfactory', Colors.blue),
          _buildScaleItem('80-84', 'Satisfactory', Colors.orange),
          _buildScaleItem('75-79', 'Fairly Satisfactory', Colors.amber),
          _buildScaleItem('Below 75', 'Did Not Meet', Colors.red),
        ],
      ),
    );
  }

  Widget _buildScaleItem(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$range: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _finalGrade != null ? _saveGrade : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  void _saveGrade() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'writtenWorks': double.parse(_wwController.text),
        'performanceTasks': double.parse(_ptController.text),
        'quarterlyAssessment': double.parse(_qaController.text),
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grade saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
