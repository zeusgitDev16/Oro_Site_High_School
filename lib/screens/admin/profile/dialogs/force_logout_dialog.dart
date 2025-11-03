import 'package:flutter/material.dart';

class ForceLogoutDialog extends StatefulWidget {
  const ForceLogoutDialog({super.key});

  @override
  State<ForceLogoutDialog> createState() => _ForceLogoutDialogState();
}

class _ForceLogoutDialogState extends State<ForceLogoutDialog> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                size: 48,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Force Logout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            const Text(
              'This will immediately log you out from all devices and sessions. You will need to log in again to access the system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Active Sessions Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.devices, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Active Sessions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSessionItem('Windows PC - Chrome', 'Current session'),
                  _buildSessionItem('Android - Mobile App', '1 hour ago'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. All active sessions will be terminated.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoggingOut ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoggingOut ? null : _forceLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Force Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(String device, String lastActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            device.contains('Windows') ? Icons.computer : Icons.phone_android,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  lastActive,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forceLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // TODO: Call AuthService().forceLogoutAllSessions()
      
      Navigator.pop(context, true); // Return true to indicate logout was successful
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All sessions have been logged out'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
