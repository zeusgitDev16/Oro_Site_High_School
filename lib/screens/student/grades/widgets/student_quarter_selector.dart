import 'package:flutter/material.dart';

/// **Phase 2 Task 2.4: Student Quarter Selector**
/// 
/// Chip-based quarter selector (Q1, Q2, Q3, Q4).
/// Shows which quarters have grades available.
class StudentQuarterSelector extends StatelessWidget {
  final int selectedQuarter;
  final Function(int) onQuarterSelected;
  final List<int> availableQuarters;

  const StudentQuarterSelector({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterSelected,
    this.availableQuarters = const [1, 2, 3, 4],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [1, 2, 3, 4].map((quarter) {
        final isSelected = quarter == selectedQuarter;
        final hasGrade = availableQuarters.contains(quarter);

        return ChoiceChip(
          label: Text('Q$quarter'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onQuarterSelected(quarter);
            }
          },
          backgroundColor: hasGrade ? Colors.white : Colors.grey.shade100,
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : hasGrade
                    ? Colors.black87
                    : Colors.grey.shade400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: isSelected
                ? Colors.blue
                : hasGrade
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          avatar: hasGrade && !isSelected
              ? Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.shade600,
                )
              : null,
        );
      }).toList(),
    );
  }
}

