import 'package:flutter/material.dart';

/// Inline date picker showing selected date with change button
///
/// **Features:**
/// - Display selected date
/// - Change button to open date picker
/// - Compact layout
/// - Calendar icon
///
/// **Usage:**
/// ```dart
/// AttendanceDatePicker(
///   selectedDate: _selectedDate,
///   onDateChanged: (date) {
///     setState(() => _selectedDate = date);
///   },
/// )
/// ```
class AttendanceDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime date) onDateChanged;

  const AttendanceDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  /// Format date as "MMM DD, YYYY"
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get day of week
  String _getDayOfWeek(DateTime date) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.weekday % 7];
  }

  /// Show date picker dialog
  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow future dates
      helpText: 'Select Attendance Date',
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getDayOfWeek(selectedDate),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showDatePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

