import 'package:flutter/material.dart';

/// Parent Calendar Widget - Mini calendar for right sidebar
/// Shows current month with highlighted dates
class ParentCalendarWidget extends StatelessWidget {
  const ParentCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: Text(
                _getMonthYear(now),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCalendarGrid(now),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCalendarGrid(DateTime now) {
    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days (simplified - showing current week)
        _buildWeekRow(now),
      ],
    );
  }

  Widget _buildWeekRow(DateTime now) {
    final startOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = startOfMonth.weekday % 7; // 0 = Sunday
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = index - firstWeekday + 1;
            final isCurrentDay = day == now.day;
            final isValidDay = day > 0 && day <= _getDaysInMonth(now);
            
            return SizedBox(
              width: 28,
              height: 28,
              child: isValidDay
                  ? Container(
                      decoration: BoxDecoration(
                        color: isCurrentDay ? Colors.orange : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrentDay ? Colors.white : Colors.black87,
                            fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          }),
        ),
      ],
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _buildLegendItem(Colors.green, 'Present'),
        const SizedBox(height: 4),
        _buildLegendItem(Colors.orange, 'Late'),
        const SizedBox(height: 4),
        _buildLegendItem(Colors.red, 'Absent'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
