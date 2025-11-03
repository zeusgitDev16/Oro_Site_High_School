import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/popup_flow.dart';
import 'package:oro_site_high_school/screens/admin/admin_profile_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/admin_menu_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/admin/views/agenda_view.dart';
import 'package:oro_site_high_school/screens/admin/views/enhanced_home_view.dart';
import 'package:oro_site_high_school/screens/admin/help/help_screen.dart';
import 'package:oro_site_high_school/screens/admin/views/admin_analytics_view.dart';
import 'package:oro_site_high_school/screens/admin/views/teacher_overview_view.dart';
import 'package:oro_site_high_school/screens/admin/widgets/dashboard_calendar.dart';
import 'package:oro_site_high_school/screens/admin/courses_screen.dart';
import 'package:oro_site_high_school/screens/admin/widgets/users_popup.dart';
import 'package:oro_site_high_school/screens/admin/widgets/resources_popup.dart';
import 'package:oro_site_high_school/screens/admin/widgets/reports_popup.dart';
import 'package:oro_site_high_school/screens/admin/messages/messages_screen.dart';
import 'package:oro_site_high_school/screens/admin/notifications/notifications_screen.dart';
import 'package:oro_site_high_school/services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  int _sideNavIndex = 0;
  late TabController _tabController;
  late PopupFlow _popupFlow;
  final NotificationService _notificationService = NotificationService();
  int _notificationUnreadCount = 0;
  int _messageUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _popupFlow = PopupFlow();
    _loadNotificationCount();
    _loadMessageCount();
  }

  Future<void> _loadMessageCount() async {
    // TODO: Load actual message count from service
    setState(() {
      _messageUnreadCount = 2; // Mock count for now
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount('admin-1');
    setState(() {
      _notificationUnreadCount = count;
    });
  }

  @override
  void dispose() {
    // Don't dispose singleton PopupFlow - it persists for app lifetime
    _tabController.dispose();
    super.dispose();
  }

  void _showUsersPopup() {
    _popupFlow.showPopup(context, const UsersPopup(), top: 200, index: 2);
  }

  void _showResourcesPopup() {
    _popupFlow.showPopup(context, const ResourcesPopup(), top: 250, index: 3);
  }

  void _showReportsPopup() {
    _popupFlow.showPopup(context, const ReportsPopup(), top: 300, index: 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildLeftNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 7, child: _buildCenterContent()),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(flex: 3, child: _buildRightSidebar()),
        ],
      ),
    );
  }

  Widget _buildLeftNavigationRail() {
    return Container(
      width: 200,
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/OroSiteLogo3.png', height: 30),
                const SizedBox(width: 8),
                const Text(
                  'OSHS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.school, 'Courses', 1),
                _buildNavItem(Icons.person_search, 'Users', 2),
                _buildNavItem(Icons.library_books, 'Resources', 3),
                _buildNavItem(Icons.insert_chart, 'Reports', 4),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildAdminMenuButton(),
          _buildNavItem(Icons.help_outline, 'Help', 10),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _sideNavIndex == index;

    Widget navItem = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey.shade400,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey.shade400,
          ),
        ),
        onTap: () {
          if (index == 1) {
            // Navigate to simple Courses screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CoursesScreen(),
              ),
            );
            return;
          }
          if (index == 2) {
            _showUsersPopup();
            return;
          }
          if (index == 3) {
            _showResourcesPopup();
            return;
          }
          if (index == 4) {
            _showReportsPopup();
            return;
          }

          // Handle Help button
          if (index == 10) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpScreen(),
              ),
            );
          } else {
            setState(() {
              _sideNavIndex = index;
              // Reset tab to Dashboard when Home is clicked
              if (index == 0) {
                _tabController.animateTo(0);
              }
            });
          }
        },
      ),
    );

    // No hover logic needed - clicks are handled in onTap above
    return navItem;
  }

  Widget _buildAdminMenuButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          Icons.admin_panel_settings,
          size: 20,
          color: Colors.grey.shade400,
        ),
        title: Text(
          'Admin',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
        onTap: () => showAdminMenuDialog(context),
      ),
    );
  }

  Widget _buildCenterContent() {
    // Always show the home content with tabs
    return _buildHomeContentWithTabs();
  }

  Widget _buildHomeContentWithTabs() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Dashboard'),
                    Tab(text: 'Analytics'),
                    Tab(text: 'Calendar'),
                    Tab(text: 'Teachers'),
                  ],
                ),
              ),
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EnhancedHomeView(),
          AdminAnalyticsView(),
          AgendaView(),
          TeacherOverviewView(),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                children: [
                  IconButton(
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
                    icon: const Icon(Icons.notifications_none),
                    tooltip: 'Notifications',
                  ),
                  if (_notificationUnreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$_notificationUnreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminMessagesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline),
                    tooltip: 'Messages',
                  ),
                  if (_getUnreadCount() > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${_getUnreadCount()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              const Text(
                'Steven Johnson',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildProfileAvatarWithDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                const DashboardCalendar(),
                const SizedBox(height: 16),
                _buildInfoCard(Icons.check_circle_outline, 'To-do', [
                  'Fix bouncing emails',
                  'Set profile description',
                ]),
                const SizedBox(height: 16),
                _buildInfoCard(Icons.campaign_outlined, 'Announcements', [
                  'None',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, List<String> items) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getUnreadCount() {
    return _messageUnreadCount;
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
          // Main avatar - click to go to profile
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            ),
            child: const CircleAvatar(
              radius: 16,
              child: Text('SJ', style: TextStyle(fontSize: 12)),
            ),
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
