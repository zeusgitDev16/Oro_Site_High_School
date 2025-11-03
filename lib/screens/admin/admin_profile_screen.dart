import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oro_site_high_school/flow/admin/popup_flow.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/admin_menu_dialog.dart';
import 'package:oro_site_high_school/screens/admin/help/help_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/admin/courses_screen.dart';
import 'package:oro_site_high_school/screens/admin/widgets/users_popup.dart';
import 'package:oro_site_high_school/screens/admin/widgets/resources_popup.dart';
import 'package:oro_site_high_school/screens/admin/widgets/reports_popup.dart';
import 'package:oro_site_high_school/screens/admin/messages/messages_screen.dart';
import 'package:oro_site_high_school/screens/admin/notifications/notifications_screen.dart';
import 'package:oro_site_high_school/services/notification_service.dart';
import 'package:oro_site_high_school/screens/admin/profile/profile_settings_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/profile_security_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/profile_activity_log_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/tabs/info_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/tabs/system_access_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/tabs/management_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/tabs/archived_tab.dart';
import 'package:oro_site_high_school/screens/admin/profile/dialogs/edit_profile_dialog.dart';
import 'package:oro_site_high_school/screens/admin/profile/dialogs/login_credentials_dialog.dart';
import 'package:oro_site_high_school/screens/admin/profile/dialogs/force_logout_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PopupFlow _popupFlow;
  final NotificationService _notificationService = NotificationService();
  int _mainNavIndex = 0;
  int _notificationUnreadCount = 0;
  int _messageUnreadCount = 0;
  int _sidebarSelectedIndex = 0; // 0=Profile, 1=Settings, 2=Security, 3=Activity Log

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _popupFlow = PopupFlow();
    _loadNotificationCount();
    _loadMessageCount();
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount('admin-1');
    setState(() {
      _notificationUnreadCount = count;
    });
  }

  Future<void> _loadMessageCount() async {
    // TODO: Load actual message count from service
    setState(() {
      _messageUnreadCount = 2; // Mock count for now
    });
  }

  @override
  void dispose() {
    // Don't dispose singleton PopupFlow - it persists for app lifetime
    _tabController.dispose();
    super.dispose();
  }

  int _getUnreadMessageCount() {
    return _messageUnreadCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildMainIconSidebar(),
          _buildProfileSidebar(),
          Expanded(child: _buildMainContent()),
          _buildRightSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainIconSidebar() {
    return Container(
      width: 64,
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/OroSiteLogo3.png', height: 28),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildIconNavItem(Icons.home, 0),
                _buildIconNavItem(Icons.school, 1),
                _buildIconNavItem(Icons.class_, 2),
                _buildIconNavItem(Icons.person_search, 3),
                _buildIconNavItem(Icons.fact_check, 4),
                _buildIconNavItem(Icons.library_books, 5),
                _buildIconNavItem(Icons.insert_chart, 6),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildIconNavItem(Icons.admin_panel_settings, 7),
          _buildIconNavItem(Icons.help_outline, 8),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIconNavItem(IconData icon, int index) {
    final isSelected = _mainNavIndex == index;
    Widget? popupContent = _getPopupContent(index);

    Widget iconButton = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400, size: 20),
        onPressed: () {
          // Show popup if available, otherwise handle navigation
          if (popupContent != null) {
            _showPopup(index);
          } else {
            // Handle special cases for Admin and Help
            if (index == 7) {
              // Admin button - show admin menu dialog
              showAdminMenuDialog(context);
            } else if (index == 8) {
              // Help button - show help center dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            } else if (index == 0) {
              // Home button - navigate back to dashboard
              Navigator.pop(context);
            } else {
              setState(() {
                _mainNavIndex = index;
              });
            }
          }
        },
      ),
    );

    return iconButton;
  }

  void _showPopup(int index) {
    // Handle Courses navigation separately
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CoursesScreen(),
        ),
      );
      return;
    }

    Widget? content = _getPopupContent(index);
    if (content == null) return;

    double topPosition;
    if (index >= 7) {
      // Admin and Help at bottom
      topPosition = MediaQuery.of(context).size.height - 250;
    } else if (index == 6) {
      // Reports (6) - position much higher to show all options
      topPosition = 150;
    } else if (index >= 3) {
      // Resources (3), Reports (4) - position higher to avoid going off screen
      topPosition = 250 + ((index - 3) * 70.0);
    } else {
      // Home through Users (0-3)
      topPosition = 100 + (index * 52.0);
    }

    _popupFlow.showPopup(
      context,
      content,
      top: topPosition,
      index: index,
      sidebarWidth: 64, // Icon sidebar is 64px wide
    );
  }

  Widget? _getPopupContent(int index) {
    switch (index) {
      case 0:
        // Home - navigate back to dashboard
        return null;
      case 1:
        // Courses - navigate to simple screen
        return null;
      case 2:
        return const UsersPopup();
      case 3:
        return const ResourcesPopup();
      case 4:
        return const ResourcesPopup();
      case 6:
        return const ReportsPopup();
      case 7:
        // Admin Tools - could add a dedicated popup later
        return null;
      case 8:
        // Help & Support - could add a dedicated popup later
        return null;
      default:
        return null;
    }
  }

  Widget _buildProfileSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildSidebarItem(Icons.person_outline, 'Profile', 0),
          _buildSidebarItem(Icons.settings_outlined, 'Settings', 1),
          _buildSidebarItem(Icons.lock_outline, 'Security', 2),
          _buildSidebarItem(Icons.history, 'Activity Log', 3),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int index) {
    final isSelected = _sidebarSelectedIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE0F2F1) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, size: 20, color: isSelected ? const Color(0xFF00897B) : Colors.grey.shade600),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF00897B) : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _sidebarSelectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMainContent() {
    // Show different content based on sidebar selection
    if (_sidebarSelectedIndex == 1) {
      return const ProfileSettingsTab();
    } else if (_sidebarSelectedIndex == 2) {
      return const ProfileSecurityTab();
    } else if (_sidebarSelectedIndex == 3) {
      return const ProfileActivityLogTab();
    }
    
    // Default: Show Profile tab (index 0)
    return Column(
      children: [
        Container(
          height: 60,
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, size: 20, color: Colors.grey),
                      ),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Notification icon (LEFT) - RED badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminNotificationsScreen(
                            adminId: 'admin-1',
                          ),
                        ),
                      ).then((_) {
                        // Reload notification count after returning
                        _loadNotificationCount();
                      });
                    },
                    tooltip: 'Notifications',
                  ),
                  if (_notificationUnreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$_notificationUnreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Inbox icon (RIGHT) - BLUE badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminMessagesScreen(),
                        ),
                      );
                    },
                    tooltip: 'Messages',
                  ),
                  if (_getUnreadMessageCount() > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${_getUnreadMessageCount()}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, color: Colors.black),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CalendarDialog(),
                  );
                },
                tooltip: 'Calendar',
              ),
              const SizedBox(width: 8),
              _buildProfileAvatarWithDropdown(),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 16),
                    _buildSocialLinks(),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Expanded(
                child: _buildTabContent(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1557683316-973673baf926?w=1200'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: 40,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
            child: const CircleAvatar(radius: 60, child: Text('SJ', style: TextStyle(fontSize: 32))),
          ),
        ),
        Positioned(
          top: 140,
          left: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Steven Johnson', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Administrator', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.link, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('https://orositehs.edu.ph/admin/steven', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Text('Oro Site High School', style: TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const EditProfileDialog(),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Info'),
          Tab(text: 'System Access'),
          Tab(text: 'Management'),
          Tab(text: 'Archived'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // About Tab
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'I am a dedicated system administrator at Oro Site High School, where I manage and maintain the school\'s learning management system. I ensure smooth operations, user support, and system security.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        // Info Tab
        const SingleChildScrollView(child: InfoTab()),
        // System Access Tab
        const SingleChildScrollView(child: SystemAccessTab()),
        // Management Tab
        const SingleChildScrollView(child: ManagementTab()),
        // Archived Tab
        const SingleChildScrollView(child: ArchivedTab()),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      width: 300,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          _buildAccountCard(),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.teal),
                SizedBox(width: 8),
                Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Joined', 'Jan 10, 2023'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, 'Last activity', 'less than a minute ago'),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const LoginCredentialsDialog(),
                );
              },
              icon: const Icon(Icons.vpn_key, size: 16),
              label: const Text('Login credentials'),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ForceLogoutDialog(),
                );
                if (result == true && mounted) {
                  // User was logged out, navigate to login screen
                  // TODO: Navigate to login screen
                }
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Force logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildProfileAvatarWithDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main avatar - already on profile page, so just show it
          const CircleAvatar(
            radius: 16,
            child: Text('SJ', style: TextStyle(fontSize: 12)),
          ),
          // Dropdown button beside avatar
          PopupMenuButton<String>(
            icon: Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Colors.grey.shade700,
            ),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'logout') {
                showLogoutDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
