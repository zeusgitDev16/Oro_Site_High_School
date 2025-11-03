import 'package:flutter/material.dart';

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  // Form controllers
  final _emailController = TextEditingController(text: 'steven.johnson@orosite.edu.ph');
  final _phoneController = TextEditingController(text: '+63 912 345 6789');
  final _alternateEmailController = TextEditingController(text: '');
  
  // Notification preferences
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _weeklyDigest = true;
  
  // Display preferences
  String _language = 'English';
  String _timezone = 'Asia/Manila';
  String _dateFormat = 'MM/DD/YYYY';
  
  // Privacy settings
  bool _showEmail = false;
  bool _showPhone = false;
  bool _showLastActivity = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _alternateEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildContactInformationSection(),
          const SizedBox(height: 24),
          _buildNotificationPreferencesSection(),
          const SizedBox(height: 24),
          _buildDisplayPreferencesSection(),
          const SizedBox(height: 24),
          _buildPrivacySettingsSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildContactInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Primary Email',
                hintText: 'your.email@orosite.edu.ph',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Used for system notifications and login',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alternateEmailController,
              decoration: const InputDecoration(
                labelText: 'Alternate Email (Optional)',
                hintText: 'alternate@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'Backup email for account recovery',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+63 XXX XXX XXXX',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                helperText: 'Used for SMS notifications',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Notification Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
              secondary: const Icon(Icons.email),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive in-app notifications'),
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
              secondary: const Icon(Icons.notifications_active),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive important alerts via SMS'),
              value: _smsNotifications,
              onChanged: (value) {
                setState(() {
                  _smsNotifications = value;
                });
              },
              secondary: const Icon(Icons.sms),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Weekly Digest'),
              subtitle: const Text('Receive weekly summary emails'),
              value: _weeklyDigest,
              onChanged: (value) {
                setState(() {
                  _weeklyDigest = value;
                });
              },
              secondary: const Icon(Icons.summarize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.display_settings, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Display Preferences',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(
                labelText: 'Language',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Filipino', child: Text('Filipino')),
                DropdownMenuItem(value: 'Cebuano', child: Text('Cebuano')),
              ],
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _timezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Asia/Manila', child: Text('Asia/Manila (PHT)')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Asia/Tokyo (JST)')),
              ],
              onChanged: (value) {
                setState(() {
                  _timezone = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dateFormat,
              decoration: const InputDecoration(
                labelText: 'Date Format',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'MM/DD/YYYY', child: Text('MM/DD/YYYY (US)')),
                DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('DD/MM/YYYY (PH)')),
                DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('YYYY-MM-DD (ISO)')),
              ],
              onChanged: (value) {
                setState(() {
                  _dateFormat = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Privacy Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Email Address'),
              subtitle: const Text('Make email visible to other users'),
              value: _showEmail,
              onChanged: (value) {
                setState(() {
                  _showEmail = value;
                });
              },
              secondary: const Icon(Icons.email),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Show Phone Number'),
              subtitle: const Text('Make phone visible to other users'),
              value: _showPhone,
              onChanged: (value) {
                setState(() {
                  _showPhone = value;
                });
              },
              secondary: const Icon(Icons.phone),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Show Last Activity'),
              subtitle: const Text('Display when you were last active'),
              value: _showLastActivity,
              onChanged: (value) {
                setState(() {
                  _showLastActivity = value;
                });
              },
              secondary: const Icon(Icons.access_time),
            ),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
    );
  }

  void _saveSettings() {
    // TODO: Call ProfileService().updateSettings()
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
