import 'package:flutter/material.dart';

class ProfileSecurityTab extends StatefulWidget {
  const ProfileSecurityTab({super.key});

  @override
  State<ProfileSecurityTab> createState() => _ProfileSecurityTabState();
}

class _ProfileSecurityTabState extends State<ProfileSecurityTab> {
  bool _twoFactorEnabled = false;
  bool _loginAlertsEnabled = true;
  
  // Mock data for active sessions
  final List<Map<String, dynamic>> _activeSessions = [
    {
      'device': 'Windows PC - Chrome',
      'location': 'Cagayan de Oro, Philippines',
      'ip': '192.168.1.100',
      'lastActive': '2 minutes ago',
      'isCurrent': true,
    },
    {
      'device': 'Android - Mobile App',
      'location': 'Cagayan de Oro, Philippines',
      'ip': '192.168.1.101',
      'lastActive': '1 hour ago',
      'isCurrent': false,
    },
  ];

  // Mock data for login history
  final List<Map<String, dynamic>> _loginHistory = [
    {
      'date': '2024-02-15 10:30 AM',
      'device': 'Windows PC - Chrome',
      'location': 'Cagayan de Oro, Philippines',
      'ip': '192.168.1.100',
      'status': 'Success',
    },
    {
      'date': '2024-02-15 08:15 AM',
      'device': 'Android - Mobile App',
      'location': 'Cagayan de Oro, Philippines',
      'ip': '192.168.1.101',
      'status': 'Success',
    },
    {
      'date': '2024-02-14 04:45 PM',
      'device': 'Windows PC - Chrome',
      'location': 'Cagayan de Oro, Philippines',
      'ip': '192.168.1.100',
      'status': 'Success',
    },
    {
      'date': '2024-02-14 09:20 AM',
      'device': 'Unknown Device',
      'location': 'Manila, Philippines',
      'ip': '203.177.xxx.xxx',
      'status': 'Failed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildPasswordSection(),
          const SizedBox(height: 24),
          _buildTwoFactorAuthSection(),
          const SizedBox(height: 24),
          _buildSecurityAlertsSection(),
          const SizedBox(height: 24),
          _buildActiveSessionsSection(),
          const SizedBox(height: 24),
          _buildLoginHistorySection(),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Change Password'),
              subtitle: const Text('Last changed 30 days ago'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Password History'),
              subtitle: const Text('View previous password changes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Show password history
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorAuthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable 2FA'),
              subtitle: Text(
                _twoFactorEnabled
                    ? 'Your account is protected with 2FA'
                    : 'Add an extra layer of security',
                style: TextStyle(
                  color: _twoFactorEnabled ? Colors.green : Colors.orange,
                ),
              ),
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() {
                  _twoFactorEnabled = value;
                });
                if (value) {
                  _showEnable2FADialog();
                }
              },
              secondary: Icon(
                _twoFactorEnabled ? Icons.check_circle : Icons.warning,
                color: _twoFactorEnabled ? Colors.green : Colors.orange,
              ),
            ),
            if (_twoFactorEnabled) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Authenticator App'),
                subtitle: const Text('Google Authenticator configured'),
                trailing: TextButton(
                  onPressed: () {
                    // TODO: Reconfigure 2FA
                  },
                  child: const Text('Reconfigure'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Codes'),
                subtitle: const Text('5 codes remaining'),
                trailing: TextButton(
                  onPressed: () {
                    // TODO: View backup codes
                  },
                  child: const Text('View'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Security Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Login Alerts'),
              subtitle: const Text('Get notified of new login attempts'),
              value: _loginAlertsEnabled,
              onChanged: (value) {
                setState(() {
                  _loginAlertsEnabled = value;
                });
              },
              secondary: const Icon(Icons.login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Active Sessions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._activeSessions.map((session) => _buildSessionCard(session)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logoutAllSessions,
              icon: const Icon(Icons.logout),
              label: const Text('Logout All Other Sessions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: session['isCurrent'] ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          _getDeviceIcon(session['device'] as String),
          color: session['isCurrent'] ? Colors.blue : Colors.grey,
        ),
        title: Row(
          children: [
            Text(session['device'] as String),
            if (session['isCurrent']) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${session['location']} • ${session['ip']}'),
            Text('Last active: ${session['lastActive']}'),
          ],
        ),
        trailing: session['isCurrent']
            ? null
            : IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => _logoutSession(session),
                tooltip: 'Logout this session',
              ),
      ),
    );
  }

  Widget _buildLoginHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Login History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._loginHistory.map((login) => _buildLoginHistoryItem(login)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginHistoryItem(Map<String, dynamic> login) {
    final isSuccess = login['status'] == 'Success';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSuccess ? Colors.white : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        title: Text(login['date'] as String),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${login['device']}'),
            Text('${login['location']} • ${login['ip']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            login['status'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String device) {
    if (device.contains('Windows') || device.contains('PC')) {
      return Icons.computer;
    } else if (device.contains('Android') || device.contains('Mobile')) {
      return Icons.phone_android;
    } else if (device.contains('iOS') || device.contains('iPhone')) {
      return Icons.phone_iphone;
    } else {
      return Icons.devices;
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call AuthService().changePassword()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showEnable2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan this QR code with your authenticator app:'),
            SizedBox(height: 16),
            Icon(Icons.qr_code_2, size: 150),
            SizedBox(height: 16),
            Text('Or enter this code manually:'),
            SizedBox(height: 8),
            SelectableText(
              'ABCD EFGH IJKL MNOP',
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _twoFactorEnabled = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call AuthService().enable2FA()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _logoutSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Session'),
        content: Text('Are you sure you want to logout from ${session['device']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call AuthService().logoutSession()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session logged out successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logoutAllSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout All Sessions'),
        content: const Text(
          'This will logout all other devices except your current session. You will need to login again on those devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Call AuthService().logoutAllSessions()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All other sessions logged out'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout All'),
          ),
        ],
      ),
    );
  }
}
