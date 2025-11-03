import 'package:flutter/material.dart';

class CreateAttendanceSessionScreen extends StatefulWidget {
  const CreateAttendanceSessionScreen({super.key});

  @override
  State<CreateAttendanceSessionScreen> createState() => _CreateAttendanceSessionScreenState();
}

class _CreateAttendanceSessionScreenState extends State<CreateAttendanceSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDay;
  TimeOfDay? _scheduleStart;
  TimeOfDay? _scheduleEnd;
  int _scanTimeLimit = 15;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance Session'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Session Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Day of Week Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                value: _selectedDay,
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(value: day, child: Text(day));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a day';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Schedule Start Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Schedule Start Time'),
                subtitle: Text(
                  _scheduleStart != null
                      ? _scheduleStart!.format(context)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _scheduleStart ?? const TimeOfDay(hour: 7, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _scheduleStart = time;
                    });
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              
              // Schedule End Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Schedule End Time'),
                subtitle: Text(
                  _scheduleEnd != null
                      ? _scheduleEnd!.format(context)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _scheduleEnd ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _scheduleEnd = time;
                    });
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              
              // Scan Time Limit
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Scan Time Limit (minutes)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  helperText: 'Students must scan within this time after schedule start',
                ),
                initialValue: _scanTimeLimit.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _scanTimeLimit = int.tryParse(value) ?? 15;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter scan time limit';
                  }
                  final minutes = int.tryParse(value);
                  if (minutes == null || minutes <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Students who scan after the time limit will be marked as LATE. '
                          'Students who don\'t scan will be marked as ABSENT.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _createSession,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Create Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createSession() {
    if (_formKey.currentState!.validate()) {
      if (_scheduleStart == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select schedule start time')),
        );
        return;
      }
      if (_scheduleEnd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select schedule end time')),
        );
        return;
      }

      // TODO: Implement actual session creation with AttendanceService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance session created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
