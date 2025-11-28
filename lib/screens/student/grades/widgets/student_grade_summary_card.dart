import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// **Phase 2 Task 2.4: Student Grade Summary Card**
/// 
/// Displays grade summary: transmuted grade, initial grade, weights, plus/extra points.
/// Extracted from student_grade_viewer_screen.dart with modern styling.
class StudentGradeSummaryCard extends StatelessWidget {
  final Map<String, dynamic> gradeData;
  final int quarter;

  const StudentGradeSummaryCard({
    super.key,
    required this.gradeData,
    required this.quarter,
  });

  @override
  Widget build(BuildContext context) {
    final transmutedGrade = (gradeData['transmuted_grade'] as num?)?.toDouble() ?? 0.0;
    final initialGrade = (gradeData['initial_grade'] as num?)?.toDouble() ?? 0.0;
    final adjustedGrade = (gradeData['adjusted_grade'] as num?)?.toDouble();
    final plusPoints = (gradeData['plus_points'] as num?)?.toDouble() ?? 0.0;
    final extraPoints = (gradeData['extra_points'] as num?)?.toDouble() ?? 0.0;
    final wwWeight = (gradeData['ww_weight_override'] as num?)?.toDouble();
    final ptWeight = (gradeData['pt_weight_override'] as num?)?.toDouble();
    final qaWeight = (gradeData['qa_weight_override'] as num?)?.toDouble();
    final computedAt = gradeData['computed_at'] as String?;

    // Default weights (DepEd standard)
    final wwWeightDisplay = wwWeight ?? 0.30;
    final ptWeightDisplay = ptWeight ?? 0.50;
    final qaWeightDisplay = qaWeight ?? 0.20;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.grade, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Grade Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Transmuted Grade (Large Display)
            Center(
              child: Column(
                children: [
                  Text(
                    'Quarter $quarter Grade',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _getGradeColor(transmutedGrade).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getGradeColor(transmutedGrade),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      transmutedGrade.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(transmutedGrade),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGradeRemark(transmutedGrade),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getGradeColor(transmutedGrade),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grade Details
            _buildDetailRow('Initial Grade', initialGrade.toStringAsFixed(2)),
            
            if (adjustedGrade != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Adjusted Grade', adjustedGrade.toStringAsFixed(2)),
            ],

            if (plusPoints > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Plus Points', '+${plusPoints.toStringAsFixed(2)}', Colors.green),
            ],

            if (extraPoints > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Extra Points', '+${extraPoints.toStringAsFixed(2)}', Colors.green),
            ],

            const SizedBox(height: 20),

            // Component Weights
            const Text(
              'Component Weights',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildWeightChip(
                    'WW',
                    wwWeightDisplay,
                    Colors.blue,
                    wwWeight != null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeightChip(
                    'PT',
                    ptWeightDisplay,
                    Colors.orange,
                    ptWeight != null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeightChip(
                    'QA',
                    qaWeightDisplay,
                    Colors.purple,
                    qaWeight != null,
                  ),
                ),
              ],
            ),

            if (computedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Computed: ${_formatDate(computedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChip(String label, double weight, Color color, bool isOverride) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(weight * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (isOverride) ...[
            const SizedBox(height: 2),
            Icon(
              Icons.edit,
              size: 10,
              color: color.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 85) return Colors.blue;
    if (grade >= 80) return Colors.orange;
    if (grade >= 75) return Colors.deepOrange;
    return Colors.red;
  }

  String _getGradeRemark(double grade) {
    if (grade >= 90) return 'Outstanding';
    if (grade >= 85) return 'Very Satisfactory';
    if (grade >= 80) return 'Satisfactory';
    if (grade >= 75) return 'Fairly Satisfactory';
    return 'Did Not Meet Expectations';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}


