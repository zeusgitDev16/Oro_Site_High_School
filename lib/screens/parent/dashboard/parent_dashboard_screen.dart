import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_dashboard_logic.dart';
import 'package:oro_site_high_school/screens/parent/views/parent_home_view.dart';
import 'package:oro_site_high_school/screens/parent/views/parent_overview_view.dart';
import 'package:oro_site_high_school/screens/parent/views/parent_reports_view.dart';
import 'package:oro_site_high_school/screens/parent/children/parent_children_screen.dart';
import 'package:oro_site_high_school/screens/parent/grades/parent_grades_screen.dart';
import 'package:oro_site_high_school/screens/parent/attendance/parent_attendance_screen.dart';
import 'package:oro_site_high_school/screens/parent/progress/parent_progress_screen.dart';
import 'package:oro_site_high_school/screens/parent/profile/parent_profile_screen.dart';
import 'package:oro_site_high_school/screens/parent/widgets/parent_calendar_widget.dart';
import 'package:oro_site_high_school/screens/parent/dialogs/child_selector_dialog.dart';
import 'package:oro_site_high_school/screens/parent/messaging/parent_messages_screen.dart';
import 'package:oro_site_high_school/screens/parent/messaging/parent_notifications_screen.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/logout_dialog.dart';
import 'package:oro_site_high_school/screens/admin/dialogs/calendar_dialog.dart';
import 'package:oro_site_high_school/screens/parent/help/parent_help_screen.dart';

/// Parent Dashboard Screen - Main entry point for parent users
/// UI only - interactive logic in ParentDashboardLogic
/// Follows the same three-column layout pattern as admin/teacher/student
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with TickerProviderStateMixin {
  late ParentDashboardLogic _logic;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _logic = ParentDashboardLogic();
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _logic.setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logic.dispose();
    super.dispose();
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
            child: ListenableBuilder(
              listenable: _logic,
              builder: (context, _) {
                return ListView(
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.family_restroom, 'My Children', 1),
                    _buildNavItem(Icons.grade, 'Grades', 2),
                    _buildNavItem(Icons.fact_check, 'Attendance', 3),
                    _buildNavItem(Icons.trending_up, 'Progress Reports', 4),
                    _buildNavItem(Icons.calendar_today, 'Calendar', 5),
                  ],
                );
              },
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListenableBuilder(
            listenable: _logic,
            builder: (context, _) {
              return Column(
                children: [
                  _buildNavItem(Icons.person, 'Profile', 6),
                  _buildNavItem(Icons.help_outline, 'Help', 7),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _logic.sideNavIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.3) : Colors.transparent,
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
          _logic.setSideNavIndex(index);
          if (index == 0) {
            _tabController.animateTo(0);
          } else if (index == 1) {
            // My Children
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentChildrenScreen(),
              ),
            );
          } else if (index == 2) {
            // Grades
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentGradesScreen(),
              ),
            );
          } else if (index == 3) {
            // Attendance
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentAttendanceScreen(),
              ),
            );
          } else if (index == 4) {
            // Progress Reports
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentProgressScreen(),
              ),
            );
          } else if (index == 5) {
            // Calendar
            showDialog(
              context: context,
              builder: (_) => const CalendarDialog(userRole: 'parent'),
            );
          } else if (index == 6) {
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentProfileScreen(),
              ),
            );
          } else if (index == 7) {
            // Help
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentHelpScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming in Phase 3+'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  
  Widget _buildCenterContent() {
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
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Reports'),
                    Tab(text: 'Analytics'),
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
        children: [
          ParentHomeView(logic: _logic),
          ParentReportsView(logic: _logic),
          ParentOverviewView(logic: _logic),
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
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentMessagesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.mail_outline),
                tooltip: 'Messages',
              ),
              ListenableBuilder(
                listenable: _logic,
                builder: (context, _) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParentNotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_none),
                        tooltip: 'Notifications',
                      ),
                      if (_logic.notificationUnreadCount > 0)
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
                              '${_logic.notificationUnreadCount}',
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
                  );
                },
              ),
              const SizedBox(width: 16),
              ListenableBuilder(
                listenable: _logic,
                builder: (context, _) {
                  final parentData = _logic.parentData;
                  return Text(
                    '${parentData['firstName']} ${parentData['lastName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildProfileAvatarWithDropdown(),
            ],
          ),
          const SizedBox(height: 24),
          // Child Selector
          ListenableBuilder(
            listenable: _logic,
            builder: (context, _) {
              final children = _logic.getAllChildren();
              if (children.length > 1) {
                return _buildChildSelector();
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildMiniCalendarCard(),
                const SizedBox(height: 16),
                _buildQuickStatsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return ListenableBuilder(
      listenable: _logic,
      builder: (context, _) {
        final selectedChild = _logic.getSelectedChildData();
        final children = _logic.getAllChildren();
        
        if (selectedChild == null) return const SizedBox.shrink();
        
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ChildSelectorDialog(
                  children: children,
                  selectedChildId: _logic.selectedChildId,
                  onChildSelected: (childId) {
                    _logic.selectChild(childId);
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange,
                    child: Text(
                      _getInitials(selectedChild['name']),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedChild['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Grade ${selectedChild['gradeLevel']} - ${selectedChild['section']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.swap_horiz, color: Colors.grey.shade600, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Widget _buildMiniCalendarCard() {
    return const ParentCalendarWidget();
  }

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: _logic,
          builder: (context, _) {
            final stats = _logic.getQuickStats();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildStatRow('Overall Grade', '${stats['overallGrade']}%', Colors.blue),
                const SizedBox(height: 12),
                _buildStatRow('Attendance Rate', '${stats['attendanceRate']}%', Colors.green),
                const SizedBox(height: 12),
                _buildStatRow('Pending Assignments', '${stats['pendingAssignments']}', Colors.orange),
                const SizedBox(height: 12),
                _buildStatRow('Recent Activities', '${stats['recentActivities']}', Colors.purple),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
          GestureDetector(
            onTap: () {
              // Navigate to profile when avatar is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentProfileScreen(),
                ),
              );
            },
            child: ListenableBuilder(
              listenable: _logic,
              builder: (context, _) {
                final parentData = _logic.parentData;
                final initials = '${parentData['firstName'][0]}${parentData['lastName'][0]}';
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                );
              },
            ),
          ),
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
              // Only show Logout option
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
