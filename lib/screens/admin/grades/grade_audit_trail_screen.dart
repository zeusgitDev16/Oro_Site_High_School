import 'package:flutter/material.dart';

class GradeAuditTrailScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const GradeAuditTrailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<GradeAuditTrailScreen> createState() => _GradeAuditTrailScreenState();
}

class _GradeAuditTrailScreenState extends State<GradeAuditTrailScreen> {
  bool _isLoading = true;
  String? _selectedSubject;

  // Mock audit trail data
  final List<Map<String, dynamic>> _auditTrail = [
    {
      'id': 1,
      'date': '2024-02-15 10:30 AM',
      'subject': 'Mathematics',
      'action': 'Grade Override',
      'oldValue': 85,
      'newValue': 88,
      'reason': 'Corrected calculation error in final exam',
      'performedBy': 'Principal Maria Santos',
      'userRole': 'Principal',
    },
    {
      'id': 2,
      'date': '2024-02-10 02:15 PM',
      'subject': 'Mathematics',
      'action': 'Grade Entry',
      'oldValue': null,
      'newValue': 85,
      'reason': 'Initial grade entry for Q1',
      'performedBy': 'Mr. Juan Dela Cruz',
      'userRole': 'Teacher',
    },
    {
      'id': 3,
      'date': '2024-01-20 09:00 AM',
      'subject': 'Science',
      'action': 'Grade Entry',
      'oldValue': null,
      'newValue': 90,
      'reason': 'Initial grade entry for Q1',
      'performedBy': 'Ms. Maria Santos',
      'userRole': 'Teacher',
    },
    {
      'id': 4,
      'date': '2024-01-18 03:45 PM',
      'subject': 'English',
      'action': 'Grade Update',
      'oldValue': 83,
      'newValue': 85,
      'reason': 'Added bonus points for extra credit assignment',
      'performedBy': 'Mrs. Ana Reyes',
      'userRole': 'Teacher',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Call GradeService().getAuditTrail(widget.studentId)

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredAuditTrail {
    if (_selectedSubject == null) {
      return _auditTrail;
    }
    return _auditTrail.where((entry) => entry['subject'] == _selectedSubject).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grade Audit Trail'),
            Text(
              widget.studentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAuditTrail,
            tooltip: 'Export Audit Trail',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterSection(),
                Expanded(child: _buildAuditTrailList()),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Filter by Subject',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Subjects')),
                DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                DropdownMenuItem(value: 'Science', child: Text('Science')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_filteredAuditTrail.length} entries',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailList() {
    final entries = _filteredAuditTrail;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No audit trail entries',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildAuditTrailCard(entry);
      },
    );
  }

  Widget _buildAuditTrailCard(Map<String, dynamic> entry) {
    final isOverride = entry['action'] == 'Grade Override';
    final isEntry = entry['action'] == 'Grade Entry';
    final isUpdate = entry['action'] == 'Grade Update';

    Color actionColor;
    IconData actionIcon;

    if (isOverride) {
      actionColor = Colors.orange;
      actionIcon = Icons.admin_panel_settings;
    } else if (isEntry) {
      actionColor = Colors.blue;
      actionIcon = Icons.add_circle;
    } else {
      actionColor = Colors.green;
      actionIcon = Icons.edit;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(actionIcon, color: actionColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry['action'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            entry['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry['subject'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Grade change display
            Row(
              children: [
                if (entry['oldValue'] != null) ...[
                  _buildGradeBox('Old Grade', entry['oldValue'], Colors.grey),
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_forward, color: Colors.grey.shade600),
                  const SizedBox(width: 16),
                ],
                _buildGradeBox('New Grade', entry['newValue'], actionColor),
              ],
            ),
            const SizedBox(height: 12),
            // Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry['reason'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Performed by
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Performed by: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  entry['performedBy'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${entry['userRole']})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeBox(String label, int grade, Color color) {
    // Determine text color based on the action color
    Color textColor;
    if (color == Colors.orange) {
      textColor = Colors.orange.shade900;
    } else if (color == Colors.blue) {
      textColor = Colors.blue.shade900;
    } else if (color == Colors.green) {
      textColor = Colors.green.shade900;
    } else {
      textColor = Colors.grey.shade900;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            grade.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  void _exportAuditTrail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting audit trail...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Export audit trail to PDF/Excel
  }
}
