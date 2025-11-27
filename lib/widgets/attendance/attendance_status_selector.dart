import 'package:flutter/material.dart';

/// Compact dropdown for selecting attendance status
///
/// **Status Options:**
/// - Present (green)
/// - Absent (red)
/// - Late (orange)
/// - Excused (blue)
///
/// **Usage:**
/// ```dart
/// AttendanceStatusSelector(
///   status: 'present',
///   onStatusChanged: (status) {
///     setState(() => _status = status);
///   },
///   isEnabled: true,
/// )
/// ```
class AttendanceStatusSelector extends StatelessWidget {
  final String? status;
  final Function(String status) onStatusChanged;
  final bool isEnabled;

  const AttendanceStatusSelector({
    super.key,
    this.status,
    required this.onStatusChanged,
    this.isEnabled = true,
  });

  /// Get color for status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade600;
      case 'late':
        return Colors.orange.shade600;
      case 'excused':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Get display text for status
  String _getStatusText(String? status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'excused':
        return 'Excused';
      default:
        return 'Mark';
    }
  }

  /// Get icon for status
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_busy;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          hint: Row(
            children: [
              Icon(
                Icons.radio_button_unchecked,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Mark',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12),
          items: [
            _buildDropdownItem('present', 'Present'),
            _buildDropdownItem('absent', 'Absent'),
            _buildDropdownItem('late', 'Late'),
            _buildDropdownItem('excused', 'Excused'),
          ],
          onChanged: isEnabled
              ? (String? newValue) {
                  if (newValue != null) {
                    onStatusChanged(newValue);
                  }
                }
              : null,
          selectedItemBuilder: (BuildContext context) {
            return ['present', 'absent', 'late', 'excused'].map((String value) {
              return Row(
                children: [
                  Icon(
                    _getStatusIcon(value),
                    size: 14,
                    color: _getStatusColor(value),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusText(value),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(value),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Build dropdown menu item
  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            _getStatusIcon(value),
            size: 16,
            color: _getStatusColor(value),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(value),
            ),
          ),
        ],
      ),
    );
  }
}

