import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:oro_site_high_school/models/student_transfer_record.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/student_transfer_record_dialog.dart';
import 'package:oro_site_high_school/services/backend_service.dart';
import 'package:oro_site_high_school/services/student_transfer_record_service.dart';

class StudentTransferRecordsScreen extends StatefulWidget {
  const StudentTransferRecordsScreen({super.key});

  @override
  State<StudentTransferRecordsScreen> createState() =>
      _StudentTransferRecordsScreenState();
}

class _StudentTransferRecordsScreenState
    extends State<StudentTransferRecordsScreen> {
  final StudentTransferRecordService _transferService =
      StudentTransferRecordService();
  final BackendService _backendService = BackendService();

  RealtimeChannel? _channel;

  bool _isLoading = false;
  String? _loadError;

  String? _selectedSchoolYear;
  String _searchQuery = '';
  String _statusFilter = 'all';

  String _sortBy = 'admission_date';
  bool _sortAscending = false;
  int? _sortColumnIndex;

  List<Map<String, dynamic>> _records = [];
  List<String> _availableSchoolYears = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadRecords();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final rows = await _backendService.getStudents(isActive: true);
      if (!mounted) return;
      setState(() {
        _students = rows.map((row) {
          final firstName = (row['first_name'] as String?) ?? '';
          final middleName = (row['middle_name'] as String?) ?? '';
          final lastName = (row['last_name'] as String?) ?? '';
          final parts = <String>[];
          if (firstName.isNotEmpty) parts.add(firstName);
          if (middleName.isNotEmpty) parts.add(middleName);
          if (lastName.isNotEmpty) parts.add(lastName);
          final displayName = parts.join(' ');
          return <String, Object?>{
            'id': row['id']?.toString(),
            'lrn': row['lrn']?.toString() ?? '',
            'display_name': displayName,
            'section': row['section'] ?? '',
          };
        }).toList();
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('StudentTransferRecordsScreen._loadStudents error: $e\n$st');
    }
  }

  Future<void> _loadRecords() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      bool? isActiveParam;
      if (_statusFilter == 'active') {
        isActiveParam = true;
      } else if (_statusFilter == 'inactive') {
        isActiveParam = false;
      }

      final items = await _transferService.getAllTransferRecords(
        schoolYear: _selectedSchoolYear,
        searchQuery: _searchQuery.trim().isEmpty ? null : _searchQuery,
        isActive: isActiveParam,
        sortBy: _sortBy,
        ascending: _sortAscending,
      );

      if (!mounted) return;

      setState(() {
        _records = items;
        final years = <String>{..._availableSchoolYears};
        for (final item in items) {
          final record = item['record'] as StudentTransferRecord;
          if (record.schoolYear.isNotEmpty) {
            years.add(record.schoolYear);
          }
        }
        final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
        _availableSchoolYears = sortedYears;
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('StudentTransferRecordsScreen._loadRecords error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load transfer records.';
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to load transfer records: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToChanges() {
    _channel?.unsubscribe();
    final client = Supabase.instance.client;
    _channel = client
        .channel('admin-student-transfer-records')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_transfer_records',
          callback: (_) {
            _loadRecords();
          },
        )
        .subscribe();
  }

  void _onSort(String sortBy, int columnIndex, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _loadRecords();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusChip(bool isActive) {
    final color = isActive ? Colors.green.shade100 : Colors.grey.shade200;
    final borderColor = isActive ? Colors.green.shade700 : Colors.grey.shade600;
    final textColor = borderColor;
    final label = isActive ? 'ACTIVE' : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name or LRN...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadRecords();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedSchoolYear,
                  decoration: const InputDecoration(
                    labelText: 'School Year',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All School Years'),
                    ),
                    ..._availableSchoolYears.map(
                      (year) => DropdownMenuItem<String?>(
                        value: year,
                        child: Text(year),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSchoolYear = value;
                    });
                    _loadRecords();
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _statusFilter = value;
                    });
                    _loadRecords();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTable() {
    if (_isLoading && _records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _records.isEmpty) {
      return Center(child: Text(_loadError!));
    }

    if (_records.isEmpty) {
      return const Center(child: Text('No transfer records found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 900),
            child: DataTable(
              columnSpacing: 16,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                DataColumn(
                  label: const Text(
                    'Student Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSort: (index, ascending) =>
                      _onSort('student_name', index, ascending),
                ),
                DataColumn(
                  label: const Text(
                    'LRN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSort: (index, ascending) =>
                      _onSort('lrn', index, ascending),
                ),
                DataColumn(
                  label: const Text(
                    'School Year',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSort: (index, ascending) =>
                      _onSort('school_year', index, ascending),
                ),
                DataColumn(
                  label: const Text(
                    'Admission Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSort: (index, ascending) =>
                      _onSort('admission_date', index, ascending),
                ),
                DataColumn(
                  label: const Text(
                    'Cancellation Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSort: (index, ascending) =>
                      _onSort('cancellation_date', index, ascending),
                ),
                const DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _records.map<DataRow>(_buildDataRow).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> item) {
    final record = item['record'] as StudentTransferRecord;
    final student = item['student'] as Map<String, dynamic>? ?? {};
    final name = (student['display_name'] as String? ?? '').isEmpty
        ? 'Unknown'
        : student['display_name'] as String;
    final lrn = student['lrn'] as String? ?? '';

    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(Text(lrn)),
        DataCell(Text(record.schoolYear)),
        DataCell(Text(_formatDate(record.admissionDate))),
        DataCell(Text(_formatDate(record.cancellationDate))),
        DataCell(_buildStatusChip(record.isActive)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.edit),
                tooltip: 'Edit record',
                onPressed: () => _openEditDialog(item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateDialog() async {
    if (_students.isEmpty) {
      await _loadStudents();
      if (!mounted) return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StudentTransferRecordDialog(
          students: _students,
          initialSchoolYear: _selectedSchoolYear,
          onSaved: (_) => _loadRecords(),
        );
      },
    );
  }

  Future<void> _openEditDialog(Map<String, dynamic> item) async {
    final record = item['record'] as StudentTransferRecord;
    final student = item['student'] as Map<String, dynamic>? ?? {};

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StudentTransferRecordDialog(
          record: record,
          student: student,
          students: _students,
          initialSchoolYear: record.schoolYear,
          onSaved: (_) => _loadRecords(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Transfer Records'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadRecords,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Record'),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildRecordsTable()),
        ],
      ),
    );
  }
}
