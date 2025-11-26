import 'package:flutter/material.dart';
import 'package:oro_site_high_school/widgets/gradebook/grade_computation_dialog.dart';

/// **Phase 4: Bulk Compute Grades Dialog**
/// 
/// Shows list of students with checkboxes for bulk grade computation.
/// User can select students and compute their grades.
class BulkComputeGradesDialog extends StatefulWidget {
  final String classroomId;
  final String courseId;
  final int quarter;
  final List<Map<String, dynamic>> students;

  const BulkComputeGradesDialog({
    super.key,
    required this.classroomId,
    required this.courseId,
    required this.quarter,
    required this.students,
  });

  @override
  State<BulkComputeGradesDialog> createState() => _BulkComputeGradesDialogState();
}

class _BulkComputeGradesDialogState extends State<BulkComputeGradesDialog> {
  final Set<String> _selectedStudentIds = {};
  bool _selectAll = false;
  bool _isComputing = false;
  int _computedCount = 0;

  Future<void> _computeSelectedGrades() async {
    if (_selectedStudentIds.isEmpty) return;

    setState(() {
      _isComputing = true;
      _computedCount = 0;
    });

    int successCount = 0;
    int skipCount = 0;

    for (final studentId in _selectedStudentIds) {
      try {
        final student = widget.students.firstWhere((s) => s['id'].toString() == studentId);

        // Show individual grade computation dialog
        final saved = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => GradeComputationDialog(
            student: student,
            classroomId: widget.classroomId,
            courseId: widget.courseId,
            quarter: widget.quarter,
          ),
        );

        if (saved == true) {
          successCount++;
        } else {
          skipCount++;
        }

        setState(() => _computedCount++);
      } catch (e) {
        skipCount++;
        setState(() => _computedCount++);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error computing grade: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    setState(() => _isComputing = false);

    if (mounted) {
      // Show summary
      if (skipCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Computed $successCount grade(s), skipped $skipCount'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      Navigator.pop(context, successCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Compute Grades',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Select All checkbox
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: _isComputing ? null : (value) {
                      setState(() {
                        _selectAll = value ?? false;
                        if (_selectAll) {
                          _selectedStudentIds.addAll(
                            widget.students.map((s) => s['id'].toString()),
                          );
                        } else {
                          _selectedStudentIds.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select All (${widget.students.length} students)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  final studentId = student['id'].toString();
                  final fullName = student['full_name'] ?? 'Unknown';
                  final isSelected = _selectedStudentIds.contains(studentId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: _isComputing ? null : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedStudentIds.add(studentId);
                        } else {
                          _selectedStudentIds.remove(studentId);
                        }
                        _selectAll = _selectedStudentIds.length == widget.students.length;
                      });
                    },
                    title: Text(fullName, style: const TextStyle(fontSize: 12)),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  if (_isComputing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Computing... $_computedCount/${_selectedStudentIds.length}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ] else ...[
                    Text(
                      '${_selectedStudentIds.length} selected',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: _isComputing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isComputing || _selectedStudentIds.isEmpty
                        ? null
                        : _computeSelectedGrades,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Compute', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

