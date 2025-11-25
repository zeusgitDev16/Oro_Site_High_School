import 'package:flutter/material.dart';

/// Small, minimalist quarter selector widget
/// Displays 4 quarter tabs with subtle styling
class QuarterSelectorWidget extends StatelessWidget {
  final int selectedQuarter;
  final ValueChanged<int> onQuarterChanged;

  const QuarterSelectorWidget({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Quarter:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(4, (index) {
            final quarter = index + 1;
            final isSelected = selectedQuarter == quarter;
            
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => onQuarterChanged(quarter),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade700 : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Q$quarter',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

