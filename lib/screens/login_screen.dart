import 'package:flutter/material.dart';
import 'package:oro_site_high_school/services/auth_service.dart';
import 'package:oro_site_high_school/backend/config/environment.dart';
import 'admin/admin_dashboard_screen.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'student/dashboard/student_dashboard_screen.dart';
import 'parent/dashboard/parent_dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            _buildFeaturesSection(),
            _buildFooter(),
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Oro Site High School',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // TODO: Implement Campus Helpdesk navigation
          },
          child: const Text('Campus Helpdesk'),
        ),
        TextButton(
          onPressed: () {
            // TODO: Implement FAQ navigation
          },
          child: const Text('FAQ'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _showLoginDialog(context),
          child: const Text('Log In'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoginDialog();
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade600, Colors.orange.shade800],
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the local logo asset
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/OroSiteLogo3.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aim High Oro High!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Electronic Learning Management System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: const Wrap(
        spacing: 40,
        runSpacing: 40,
        alignment: WrapAlignment.center,
        children: [
          FeatureCard(
            title: 'Comprehensive Course Management',
            description:
                'Teachers can create and manage courses, upload learning materials, assign tasks, and track student progress all in one centralized platform.',
          ),
          FeatureCard(
            title: 'Real-time Grade Tracking',
            description:
                'Students and parents can view grades, assignments, and academic performance in real-time with detailed analytics and progress reports.',
          ),
          FeatureCard(
            title: 'Automated Attendance System',
            description:
                'Integrated attendance tracking with scanner support for efficient student check-ins, automated reports, and real-time notifications to parents.',
          ),
          FeatureCard(
            title: 'Secure Communication Hub',
            description:
                'Built-in messaging system for teachers, students, and parents with announcements, notifications, and direct communication channels.',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF003366), // Dark blue color
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Contact section
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                // School logo
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/OroSiteLogo3.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact us',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ORO SITE HIGH SCHOOL',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Electronic Learning Management System',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement contact/learn more functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Learn more'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatItem(count: '19,167', label: 'Courses'),
          StatItem(count: '2,109', label: 'Teachers'),
        ],
      ),
    );
  }
}

// Login Dialog with Authentication
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _authService = AuthService();
  bool _showEmailLogin = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.signIn(
      context: context,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Close the dialog on successful login
      Navigator.of(context).pop();
      // AuthGate will handle navigation to dashboard
    }
  }

  Future<void> _handleQuickLogin(String userType) async {
    setState(() => _isLoading = true);

    final success = await _authService.quickLogin(
      context: context,
      userType: userType,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      // AuthGate will handle navigation based on role
    }
  }

  Future<void> _handleAdminLogin() async {
    // Admin login uses Azure AD with admin verification
    setState(() => _isLoading = true);

    final success = await _authService.signInWithAzure(
      context,
      requireAdmin: true, // This ensures only admins can login
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      // AuthGate will handle navigation to admin dashboard
    }
  }

  Future<void> _handleAzureLogin() async {
    // Regular Azure login for any user type
    setState(() => _isLoading = true);

    final success = await _authService.signInWithAzure(
      context,
      requireAdmin: false, // Any user type can login
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      // AuthGate will handle navigation based on role
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_showEmailLogin ? 'Sign In' : 'Log In'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: _showEmailLogin ? _buildEmailLoginForm() : _buildLoginOptions(),
    );
  }

  Widget _buildLoginOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Azure AD / Office 365 Login
        if (Environment.enableAzureAuth) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.business_center),
            label: const Text('Log in with Office 365'),
            onPressed: _isLoading ? null : _handleAzureLogin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Parent Google Login (reusing the email entry point visually)
        OutlinedButton.icon(
          icon: const Icon(Icons.family_restroom),
          label: const Text('Parent login (Google)'),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final success = await _authService.signInWithGoogleForParent(
                    context,
                  );
                  setState(() => _isLoading = false);
                  if (success && mounted) {
                    // Dialog will typically close after OAuth redirect completes
                    // AuthGate will handle routing based on the parent role
                    Navigator.of(context).pop();
                  }
                },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),

        // Admin Login - Uses Azure AD with admin verification
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleAdminLogin,
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Admin log in (Office 365)'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: const Color(
              0xFF1976D2,
            ), // Blue color matching other buttons
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => _showEmailLogin = false);
          },
          child: const Text('Back to login options'),
        ),
      ],
    );
  }

  void _showUserTypeSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select User Type'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserTypeButton(
                context,
                'Teacher',
                Icons.school,
                Colors.blue,
                () => _handleQuickLogin('teacher'),
              ),
              const SizedBox(height: 12),
              _buildUserTypeButton(
                context,
                'Student',
                Icons.person,
                Colors.green,
                () => _handleQuickLogin('student'),
              ),
              const SizedBox(height: 12),
              _buildUserTypeButton(
                context,
                'Parent',
                Icons.family_restroom,
                Colors.orange,
                () => _handleQuickLogin('parent'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTypeButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for feature icon
          Container(
            height: 100,
            width: 250,
            color: Colors.grey[200],
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String count;
  final String label;

  const StatItem({super.key, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 18, color: Colors.grey)),
      ],
    );
  }
}
