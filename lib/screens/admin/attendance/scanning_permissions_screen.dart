import 'package:flutter/material.dart';

class ScanningPermissionsScreen extends StatefulWidget {
  const ScanningPermissionsScreen({super.key});

  @override
  State<ScanningPermissionsScreen> createState() => _ScanningPermissionsScreenState();
}

class _ScanningPermissionsScreenState extends State<ScanningPermissionsScreen> {
  final List<Map<String, dynamic>> _students = [
    {'name': 'Juan Dela Cruz', 'lrn': '123456789012', 'canScan': true},
    {'name': 'Maria Santos', 'lrn': '123456789013', 'canScan': false},
    {'name': 'Pedro Garcia', 'lrn': '123456789014', 'canScan': true},
    {'name': 'Ana Reyes', 'lrn': '123456789015', 'canScan': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Permissions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By default, only teachers can scan. Grant permission to trusted students to help with attendance.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: student['canScan']
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        student['canScan'] ? Icons.qr_code_scanner : Icons.person,
                        color: student['canScan'] ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(
                      student['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('LRN: ${student['lrn']}'),
                    trailing: Switch(
                      value: student['canScan'],
                      onChanged: (value) {
                        setState(() {
                          student['canScan'] = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Scanning permission granted to ${student['name']}'
                                  : 'Scanning permission revoked from ${student['name']}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
