import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/parent/parent_children_logic.dart';

/// Child Detail Screen - View detailed information about a child
/// UI only - interactive logic in ParentChildrenLogic
class ChildDetailScreen extends StatefulWidget {
  final String childId;
  
  const ChildDetailScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final ParentChildrenLogic _logic = ParentChildrenLogic();

  @override
  void initState() {
    super.initState();
    _logic.selectChild(widget.childId);
    _logic.refreshChildData(widget.childId);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          final child = _logic.getChildById(widget.childId);

          if (child == null) {
            return const Center(
              child: Text('Child not found'),
            );
          }

          if (_logic.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(child),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStatsRow(child),
                      const SizedBox(height: 24),
                      _buildAcademicInfoCard(child),
                      const SizedBox(height: 16),
                      _buildContactInfoCard(child),
                      const SizedBox(height: 16),
                      _buildPerformanceOverviewCard(child),
                      const SizedBox(height: 16),
                      _buildQuickActionsCard(child),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> child) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          child['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(128, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade700,
                Colors.orange,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    _logic.getChildInitials(child['id']),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(Map<String, dynamic> child) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Overall Grade',
            '${child['overallGrade']}%',
            Icons.grade,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Attendance',
            '${child['attendanceRate']}%',
            Icons.fact_check,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfoCard(Map<String, dynamic> child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Academic Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('LRN', child['lrn']),
            const SizedBox(height: 12),
            _buildInfoRow('Grade Level', 'Grade ${child['gradeLevel']}'),
            const SizedBox(height: 12),
            _buildInfoRow('Section', child['section']),
            const SizedBox(height: 12),
            _buildInfoRow('Adviser', child['adviser']),
            const SizedBox(height: 12),
            _buildInfoRow('Relationship', child['relationship'].toString().toUpperCase()),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Primary Contact',
              child['isPrimary'] ? 'Yes' : 'No',
              valueColor: child['isPrimary'] ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(Map<String, dynamic> child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Email', child['email']),
            const SizedBox(height: 12),
            _buildInfoRow('Contact Number', child['contactNumber']),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverviewCard(Map<String, dynamic> child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Performance Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildPerformanceBar('Mathematics', 91.0, Colors.blue),
            const SizedBox(height: 16),
            _buildPerformanceBar('Science', 89.5, Colors.green),
            const SizedBox(height: 16),
            _buildPerformanceBar('English', 89.8, Colors.orange),
            const SizedBox(height: 16),
            _buildPerformanceBar('Filipino', 92.6, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(String subject, double grade, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${grade.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: grade / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(Map<String, dynamic> child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildActionButton(
              'View Grades',
              Icons.grade,
              Colors.blue,
              () => _showComingSoon('Grades'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Attendance',
              Icons.fact_check,
              Colors.green,
              () => _showComingSoon('Attendance'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'View Progress Report',
              Icons.trending_up,
              Colors.purple,
              () => _showComingSoon('Progress Report'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Contact Adviser',
              Icons.mail,
              Colors.orange,
              () => _showComingSoon('Contact Adviser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming in next phases'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
