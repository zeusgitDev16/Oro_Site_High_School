import 'package:flutter/material.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Academic'),
            Tab(text: 'Users'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GeneralSettingsTab(),
          _AcademicSettingsTab(),
          _UserSettingsTab(),
          _SystemSettingsTab(),
        ],
      ),
    );
  }
}

// General Settings Tab
class _GeneralSettingsTab extends StatefulWidget {
  const _GeneralSettingsTab();

  @override
  State<_GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<_GeneralSettingsTab> {
  final _schoolNameController = TextEditingController(text: 'Oro Site High School');
  final _schoolAddressController = TextEditingController(text: 'Oro Site, Cagayan de Oro City');
  final _schoolPhoneController = TextEditingController(text: '(088) 123-4567');
  final _schoolEmailController = TextEditingController(text: 'info@orosite.edu.ph');
  final _principalNameController = TextEditingController(text: 'Dr. Maria Santos');

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _principalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          'School Information',
          [
            TextFormField(
              controller: _schoolNameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolAddressController,
              decoration: const InputDecoration(
                labelText: 'School Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _schoolPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _schoolEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalNameController,
              decoration: const InputDecoration(
                labelText: 'Principal Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'School Logo',
          [
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Upload logo
                      },
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Upload Logo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Save Changes'),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Academic Settings Tab
class _AcademicSettingsTab extends StatefulWidget {
  const _AcademicSettingsTab();

  @override
  State<_AcademicSettingsTab> createState() => _AcademicSettingsTabState();
}

class _AcademicSettingsTabState extends State<_AcademicSettingsTab> {
  String _currentSchoolYear = '2024-2025';
  String _currentQuarter = 'Q3';
  int _passingGrade = 75;
  bool _allowLateSubmissions = true;
  int _lateSubmissionPenalty = 10;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          'School Year Configuration',
          [
            DropdownButtonFormField<String>(
              value: _currentSchoolYear,
              decoration: const InputDecoration(
                labelText: 'Current School Year',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '2023-2024', child: Text('S.Y. 2023-2024')),
                DropdownMenuItem(value: '2024-2025', child: Text('S.Y. 2024-2025')),
                DropdownMenuItem(value: '2025-2026', child: Text('S.Y. 2025-2026')),
              ],
              onChanged: (value) {
                setState(() {
                  _currentSchoolYear = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentQuarter,
              decoration: const InputDecoration(
                labelText: 'Current Quarter',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Q1', child: Text('Quarter 1')),
                DropdownMenuItem(value: 'Q2', child: Text('Quarter 2')),
                DropdownMenuItem(value: 'Q3', child: Text('Quarter 3')),
                DropdownMenuItem(value: 'Q4', child: Text('Quarter 4')),
              ],
              onChanged: (value) {
                setState(() {
                  _currentQuarter = value!;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Grading System (DepEd Scale)',
          [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Passing Grade', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Slider(
                        value: _passingGrade.toDouble(),
                        min: 70,
                        max: 80,
                        divisions: 10,
                        label: _passingGrade.toString(),
                        onChanged: (value) {
                          setState(() {
                            _passingGrade = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _passingGrade.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DepEd Grading Scale:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildGradeScaleRow('90-100', 'Outstanding'),
                  _buildGradeScaleRow('85-89', 'Very Satisfactory'),
                  _buildGradeScaleRow('80-84', 'Satisfactory'),
                  _buildGradeScaleRow('75-79', 'Fairly Satisfactory'),
                  _buildGradeScaleRow('Below 75', 'Did Not Meet Expectations'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Assignment Settings',
          [
            SwitchListTile(
              title: const Text('Allow Late Submissions'),
              subtitle: const Text('Students can submit assignments after deadline'),
              value: _allowLateSubmissions,
              onChanged: (value) {
                setState(() {
                  _allowLateSubmissions = value;
                });
              },
            ),
            if (_allowLateSubmissions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Late Submission Penalty (%)', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Slider(
                          value: _lateSubmissionPenalty.toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 10,
                          label: '$_lateSubmissionPenalty%',
                          onChanged: (value) {
                            setState(() {
                              _lateSubmissionPenalty = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_lateSubmissionPenalty%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildGradeScaleRow(String range, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(range, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Text(description, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Save Changes'),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Academic settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// User Settings Tab
class _UserSettingsTab extends StatefulWidget {
  const _UserSettingsTab();

  @override
  State<_UserSettingsTab> createState() => _UserSettingsTabState();
}

class _UserSettingsTabState extends State<_UserSettingsTab> {
  bool _enableHybridUsers = true;
  bool _requireEmailVerification = true;
  bool _allowSelfRegistration = false;
  int _passwordMinLength = 8;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          'User Account Settings',
          [
            SwitchListTile(
              title: const Text('Enable Hybrid Users'),
              subtitle: const Text('Allow users to have multiple roles (e.g., Teacher + Parent)'),
              value: _enableHybridUsers,
              onChanged: (value) {
                setState(() {
                  _enableHybridUsers = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Require Email Verification'),
              subtitle: const Text('Users must verify email before accessing system'),
              value: _requireEmailVerification,
              onChanged: (value) {
                setState(() {
                  _requireEmailVerification = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Allow Self-Registration'),
              subtitle: const Text('Users can create accounts without admin approval'),
              value: _allowSelfRegistration,
              onChanged: (value) {
                setState(() {
                  _allowSelfRegistration = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Password Requirements',
          [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Minimum Password Length', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Slider(
                        value: _passwordMinLength.toDouble(),
                        min: 6,
                        max: 16,
                        divisions: 10,
                        label: '$_passwordMinLength characters',
                        onChanged: (value) {
                          setState(() {
                            _passwordMinLength = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_passwordMinLength',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Save Changes'),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// System Settings Tab
class _SystemSettingsTab extends StatefulWidget {
  const _SystemSettingsTab();

  @override
  State<_SystemSettingsTab> createState() => _SystemSettingsTabState();
}

class _SystemSettingsTabState extends State<_SystemSettingsTab> {
  bool _enableNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enableMaintenanceMode = false;
  bool _enableDebugMode = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          'Notification Settings',
          [
            SwitchListTile(
              title: const Text('Enable System Notifications'),
              subtitle: const Text('Show in-app notifications to users'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              subtitle: const Text('Send email notifications for important events'),
              value: _enableEmailNotifications,
              onChanged: (value) {
                setState(() {
                  _enableEmailNotifications = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'System Maintenance',
          [
            SwitchListTile(
              title: const Text('Maintenance Mode'),
              subtitle: Text(
                _enableMaintenanceMode
                    ? 'System is in maintenance mode - users cannot access'
                    : 'System is operational',
                style: TextStyle(
                  color: _enableMaintenanceMode ? Colors.red : Colors.green,
                ),
              ),
              value: _enableMaintenanceMode,
              onChanged: (value) {
                setState(() {
                  _enableMaintenanceMode = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Developer Settings',
          [
            SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Show detailed error messages (for development only)'),
              value: _enableDebugMode,
              onChanged: (value) {
                setState(() {
                  _enableDebugMode = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'System Information',
          [
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build', '2024.02.15'),
            _buildInfoRow('Environment', 'Production'),
            _buildInfoRow('Database', 'Connected'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Save Changes'),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('System settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
