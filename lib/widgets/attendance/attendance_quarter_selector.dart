import 'package:flutter/material.dart';

/// Compact chip selector for quarters (Q1-Q4)
///
/// **Features:**
/// - 4 chips for Q1, Q2, Q3, Q4
/// - Selected chip highlighted
/// - Compact size
/// - Tooltip with quarter date range
///
/// **Usage:**
/// ```dart
/// AttendanceQuarterSelector(
///   selectedQuarter: 1,
///   onQuarterSelected: (quarter) {
///     setState(() => _selectedQuarter = quarter);
///   },
/// )
/// ```
class AttendanceQuarterSelector extends StatelessWidget {
  final int selectedQuarter;
  final Function(int quarter) onQuarterSelected;

  const AttendanceQuarterSelector({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuarterChip(1),
        const SizedBox(width: 4),
        _buildQuarterChip(2),
        const SizedBox(width: 4),
        _buildQuarterChip(3),
        const SizedBox(width: 4),
        _buildQuarterChip(4),
      ],
    );
  }

  /// Build individual quarter chip
  Widget _buildQuarterChip(int quarter) {
    final isSelected = selectedQuarter == quarter;

    return Tooltip(
      message: _getQuarterTooltip(quarter),
      child: InkWell(
        onTap: () => onQuarterSelected(quarter),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'Q$quarter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get tooltip text for quarter
  String _getQuarterTooltip(int quarter) {
    switch (quarter) {
      case 1:
        return 'Quarter 1 (Aug - Oct)';
      case 2:
        return 'Quarter 2 (Nov - Jan)';
      case 3:
        return 'Quarter 3 (Feb - Apr)';
      case 4:
        return 'Quarter 4 (May - Jul)';
      default:
        return 'Quarter $quarter';
    }
  }
}

