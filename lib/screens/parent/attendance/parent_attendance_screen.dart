import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_attendance_logic.dart';
import 'package:oro_site_high_school/screens/parent/widgets/attendance_calendar_widget.dart';
import 'package:oro_site_high_school/screens/parent/dialogs/report_export_dialog.dart';

/// Parent Attendance Screen - View children's attendance records
/// UI only - interactive logic in ParentAttendanceLogic
class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  final ParentAttendanceLogic _logic = ParentAttendanceLogic();

  @override
  void initState() {
    super.initState();
    _logic.loadAttendance('student123', DateTime.now());
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export Attendance',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          if (_logic.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildMonthSelector(),
                _buildAttendanceSummaryCard(),
                _buildCalendarSection(),
                _buildTimeRecordsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Records',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Juan Dela Cruz - Grade 7 Diamond',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _logic.previousMonth();
              _logic.loadAttendance('student123', _logic.selectedMonth);
            },
            tooltip: 'Previous Month',
          ),
          Text(
            _getMonthYear(_logic.selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _logic.nextMonth();
              _logic.loadAttendance('student123', _logic.selectedMonth);
            },
            tooltip: 'Next Month',
          ),
        ],
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

  Widget _buildAttendanceSummaryCard() {
    final summary = _logic.getAttendanceSummary();
    final percentage = _logic.calculateAttendancePercentage();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Present',
                    '${summary['present']}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildSummaryItem(
                    'Late',
                    '${summary['late']}',
                    Colors.orange,
                    Icons.access_time,
                  ),
                  _buildSummaryItem(
                    'Absent',
                    '${summary['absent']}',
                    Colors.red,
                    Icons.cancel,
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${summary['totalDays']}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Total Days',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.green.shade200,
                  ),
                  Column(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Attendance Rate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.orange.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Monthly Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AttendanceCalendarWidget(
                selectedMonth: _logic.selectedMonth,
                attendanceRecords: _logic.attendanceRecords,
                onDateSelected: (date) {
                  _showDateDetail(date);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRecordsSection() {
    final records = _logic.attendanceRecords;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Time In/Out Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecordsTable(records),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsTable(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No attendance records for this month'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columns: const [
          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Time In', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Time Out', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: records.map((record) {
          final status = record['status'] as String;
          final color = _logic.getStatusColor(status);
          
          return DataRow(
            cells: [
              DataCell(Text(record['date'])),
              DataCell(Text(record['timeIn'] ?? '-')),
              DataCell(Text(record['timeOut'] ?? '-')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_logic.getStatusIcon(status), size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(record['notes'] ?? '-')),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showDateDetail(DateTime date) {
    final record = _logic.getAttendanceRecord(date);
    
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance record for this date'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record['date'],
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', record['status'].toString().toUpperCase()),
            const SizedBox(height: 12),
            _buildDetailRow('Time In', record['timeIn'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow('Time Out', record['timeOut'] ?? 'N/A'),
            if (record['notes'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Notes', record['notes']),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ReportExportDialog(
        reportType: 'Attendance Report',
        onExport: (format, options) {
          _logic.exportAttendanceReport().then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exporting attendance as $format...'),
                backgroundColor: Colors.green,
              ),
            );
          });
        },
      ),
    );
  }
}
