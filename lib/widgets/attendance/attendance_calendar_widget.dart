import 'package:flutter/material.dart';

/// Compact monthly calendar with marked dates indicator
///
/// **Features:**
/// - Monthly view with navigation
/// - Marked dates with colored dots
/// - Selected date highlighting
/// - Disabled future dates
///
/// **Usage:**
/// ```dart
/// AttendanceCalendarWidget(
///   selectedDate: _selectedDate,
///   markedDates: _markedDates,
///   onDateSelected: (date) {
///     setState(() => _selectedDate = date);
///   },
/// )
/// ```
class AttendanceCalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> markedDates;
  final Function(DateTime date) onDateSelected;

  const AttendanceCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.markedDates,
    required this.onDateSelected,
  });

  @override
  State<AttendanceCalendarWidget> createState() =>
      _AttendanceCalendarWidgetState();
}

class _AttendanceCalendarWidgetState extends State<AttendanceCalendarWidget> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  /// Navigate to previous month
  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  /// Navigate to next month
  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  /// Check if date is marked
  bool _isMarked(DateTime date) {
    return widget.markedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  /// Check if date is selected
  bool _isSelected(DateTime date) {
    return widget.selectedDate.year == date.year &&
        widget.selectedDate.month == date.month &&
        widget.selectedDate.day == date.day;
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  /// Check if date is in the future
  bool _isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildWeekdayLabels(),
          const SizedBox(height: 4),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  /// Build calendar header with month/year and navigation
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: _previousMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Previous month',
        ),
        Text(
          _getMonthYearLabel(_displayedMonth),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: _nextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Next month',
        ),
      ],
    );
  }

  /// Build weekday labels (S M T W T F S)
  Widget _buildWeekdayLabels() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return SizedBox(
          width: 32,
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build calendar grid
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Add cells for each day of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      dayWidgets.add(_buildDayCell(date));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: dayWidgets,
    );
  }

  /// Build individual day cell
  Widget _buildDayCell(DateTime date) {
    final isSelected = _isSelected(date);
    final isToday = _isToday(date);
    final isMarked = _isMarked(date);
    final isFuture = _isFuture(date);

    return InkWell(
      onTap: isFuture ? null : () => widget.onDateSelected(date),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade700
              : isToday
                  ? Colors.blue.shade50
                  : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade700
                : isToday
                    ? Colors.blue.shade300
                    : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isFuture
                      ? Colors.grey.shade400
                      : isSelected
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
            ),

            // Marked indicator (green dot)
            if (isMarked && !isSelected)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get month/year label
  String _getMonthYearLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

