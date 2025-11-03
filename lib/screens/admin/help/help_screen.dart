/// Admin Help Screen
/// Provides comprehensive help documentation and support resources

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  
  final List<HelpCategory> _helpCategories = [
    HelpCategory(
      id: 'getting_started',
      title: 'Getting Started',
      icon: Icons.rocket_launch,
      color: Colors.blue,
      articles: [
        HelpArticle(
          title: 'System Overview',
          description: 'Learn about the ELMS features and capabilities',
          content: '''
# System Overview

The Oro Site High School Electronic Learning Management System (ELMS) is a comprehensive platform designed to manage all academic operations.

## Key Features:
- User Management (Students, Teachers, Parents, Admins)
- Course Management
- Grade Management
- Attendance Tracking with QR Scanner
- Real-time Notifications
- Parent Portal
- Reports and Analytics

## User Roles:
1. **Administrator** - Full system control
2. **Teacher** - Manage classes and students
3. **Student** - Access learning resources
4. **Parent** - Monitor child's progress
5. **Hybrid Users** - Admin + Teacher capabilities
          ''',
        ),
        HelpArticle(
          title: 'First Time Login',
          description: 'How to access the system for the first time',
          content: '''
# First Time Login

## For School Users (Admin, Teachers, Students):
1. Navigate to https://elms.orosite.edu.ph
2. Click "Sign in with Microsoft"
3. Enter your @orosite.onmicrosoft.com email
4. Enter your temporary password
5. Change your password when prompted

## For Parents:
1. Navigate to https://elms.orosite.edu.ph
2. Click "Sign in with Google"
3. Use your Gmail account
4. Accept the invitation to link to your child
          ''',
        ),
        HelpArticle(
          title: 'Dashboard Navigation',
          description: 'Understanding the admin dashboard layout',
          content: '''
# Dashboard Navigation

## Main Sections:
- **Home** - Overview and statistics
- **Users** - Manage all system users
- **Courses** - Course management
- **Reports** - Analytics and reports
- **Settings** - System configuration

## Quick Actions:
Located on the home screen for fast access to common tasks:
- Add New User
- Create Course
- Role Upgrade
- Generate Reports
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'user_management',
      title: 'User Management',
      icon: Icons.people,
      color: Colors.green,
      articles: [
        HelpArticle(
          title: 'Adding New Users',
          description: 'Step-by-step guide to create user accounts',
          content: '''
# Adding New Users

## Steps:
1. Click "Add New User" from Quick Actions or navigate to Users > Add User
2. Fill in basic information:
   - First Name, Middle Name, Last Name
   - Email (auto-generated from name)
3. Select user role
4. Add role-specific information:
   - **Students**: LRN, Grade Level, Section, Parent Email
   - **Teachers**: Employee ID, Department, Subjects
   - **Admin**: Administrative privileges
5. Configure account settings
6. Click "Create User"

## Important Notes:
- Students require parent email (Gmail)
- Teachers can be assigned as Grade Coordinators
- Admins can have hybrid roles (Admin + Teacher)
          ''',
        ),
        HelpArticle(
          title: 'Role Upgrade',
          description: 'How to assign hybrid roles to users',
          content: '''
# Role Upgrade

## What is a Hybrid User?
A hybrid user has both administrative and teaching capabilities. They can switch between Admin and Teacher views.

## How to Upgrade:
1. Click "Role Upgrade" from Quick Actions
2. Search for the user by name or email
3. Select the user from search results
4. Choose hybrid permissions
5. Confirm the upgrade

## Use Cases:
- Principal who also teaches
- Department heads with admin duties
- ICT coordinators who conduct training
          ''',
        ),
        HelpArticle(
          title: 'Managing Parent Accounts',
          description: 'Linking parents to students',
          content: '''
# Managing Parent Accounts

## Automatic Creation:
When adding a student, you can automatically create a parent account by:
1. Entering parent's Gmail address
2. Selecting relationship (Mother/Father/Guardian)
3. Checking "Create Parent Account"

## Manual Linking:
1. Go to Users > Parents
2. Find the parent account
3. Click "Link Student"
4. Search for student by LRN
5. Confirm the link

## Parent Permissions:
- View child's grades
- Monitor attendance
- Receive announcements
- Message teachers
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'academic',
      title: 'Academic Management',
      icon: Icons.school,
      color: Colors.purple,
      articles: [
        HelpArticle(
          title: 'Course Management',
          description: 'Creating and managing courses',
          content: '''
# Course Management

## Creating a Course:
1. Navigate to Courses > Add Course
2. Enter course details:
   - Course Code (e.g., MATH7)
   - Course Name
   - Grade Level
   - Units/Credits
3. Assign teachers
4. Set schedule
5. Save course

## DepEd Compliance:
All courses follow the K-12 curriculum:
- Core subjects (Math, Science, English, Filipino)
- Makabayan subjects (AP, ESP)
- Special subjects (TLE, MAPEH)
          ''',
        ),
        HelpArticle(
          title: 'Grade Management',
          description: 'Recording and managing student grades',
          content: '''
# Grade Management

## Grade Components (DepEd):
- Written Works (WW)
- Performance Tasks (PT)
- Quarterly Assessment (QA)

## Grade Calculation:
Final Grade = (WW × 0.3) + (PT × 0.5) + (QA × 0.2)

## Grade Entry:
1. Navigate to Grades
2. Select course and section
3. Choose quarter
4. Enter component scores
5. System auto-calculates final grade
6. Submit for verification

## Grade Levels:
- 90-100: Outstanding
- 85-89: Very Satisfactory
- 80-84: Satisfactory
- 75-79: Fairly Satisfactory
- Below 75: Did Not Meet Expectations
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'attendance',
      title: 'Attendance System',
      icon: Icons.qr_code_scanner,
      color: Colors.orange,
      articles: [
        HelpArticle(
          title: 'QR Scanner Integration',
          description: 'Using the attendance scanner system',
          content: '''
# QR Scanner Integration

## How It Works:
1. Teacher creates attendance session
2. Sets time limit (e.g., 15 minutes)
3. Students scan QR code with ID
4. System marks present/late/absent
5. Real-time dashboard updates

## Scanner Features:
- Automatic late detection
- Duplicate scan prevention
- Offline queue support
- Real-time synchronization
          ''',
        ),
        HelpArticle(
          title: 'Manual Attendance',
          description: 'Recording attendance manually',
          content: '''
# Manual Attendance

## When to Use:
- Scanner system is offline
- Make-up classes
- Field trips
- Special events

## Steps:
1. Go to Attendance > Manual Entry
2. Select date and class
3. Mark each student:
   - Present
   - Late
   - Absent
   - Excused
4. Add remarks if needed
5. Save attendance
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'reports',
      title: 'Reports & Analytics',
      icon: Icons.analytics,
      color: Colors.teal,
      articles: [
        HelpArticle(
          title: 'Generating Reports',
          description: 'Creating various system reports',
          content: '''
# Generating Reports

## Available Reports:
- Enrollment Statistics
- Grade Distribution
- Attendance Summary
- Teacher Performance
- Student Progress
- Parent Engagement

## Export Formats:
- PDF (for printing)
- Excel (for analysis)
- CSV (for data processing)

## DepEd Forms:
- Form 137 (Permanent Record)
- Form 138 (Report Card)
- Form 1 (School Register)
- Form 2 (Daily Attendance)
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'troubleshooting',
      title: 'Troubleshooting',
      icon: Icons.build,
      color: Colors.red,
      articles: [
        HelpArticle(
          title: 'Common Issues',
          description: 'Solutions to frequently encountered problems',
          content: '''
# Common Issues

## Cannot Login:
- Verify email format (@orosite.onmicrosoft.com)
- Check CAPS LOCK
- Clear browser cache
- Try incognito mode
- Contact IT if password expired

## Scanner Not Working:
- Check internet connection
- Verify session is active
- Ensure QR code is clear
- Check scanner device status

## Grades Not Showing:
- Verify enrollment status
- Check quarter selection
- Ensure grades are published
- Refresh the page

## Slow Performance:
- Clear browser cache
- Check internet speed
- Close unnecessary tabs
- Try different browser
          ''',
        ),
        HelpArticle(
          title: 'Error Messages',
          description: 'Understanding system error messages',
          content: '''
# Error Messages

## "Access Denied":
You don't have permission for this action. Contact admin.

## "Session Expired":
Your login session has ended. Please login again.

## "Network Error":
Check internet connection and try again.

## "Invalid Data":
Check input format and required fields.

## "Duplicate Entry":
Record already exists. Check for existing data.
          ''',
        ),
      ],
    ),
  ];

  List<HelpArticle> get _filteredArticles {
    List<HelpArticle> articles = [];
    
    for (var category in _helpCategories) {
      if (_selectedCategory == 'all' || _selectedCategory == category.id) {
        articles.addAll(category.articles);
      }
    }
    
    if (_searchQuery.isNotEmpty) {
      articles = articles.where((article) {
        return article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               article.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               article.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return articles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search help articles...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Categories
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildCategoryTile(
                        'all',
                        'All Articles',
                        Icons.article,
                        Colors.grey,
                      ),
                      ..._helpCategories.map((category) {
                        return _buildCategoryTile(
                          category.id,
                          category.title,
                          category.icon,
                          category.color,
                        );
                      }),
                    ],
                  ),
                ),
                // Support Links
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need More Help?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSupportLink(
                        Icons.email,
                        'Email Support',
                        'support@orosite.edu.ph',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.phone,
                        'Call IT Dept',
                        '(088) 123-4567',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.chat,
                        'Live Chat',
                        'Available 8AM-5PM',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _filteredArticles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredArticles.length,
                    itemBuilder: (context, index) {
                      return _buildArticleCard(_filteredArticles[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    String id,
    String title,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCategory == id;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.grey.shade100,
      onTap: () {
        setState(() {
          _selectedCategory = id;
        });
      },
    );
  }

  Widget _buildSupportLink(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        if (title == 'Email Support') {
          launchUrl(Uri.parse('mailto:support@orosite.edu.ph'));
        } else if (title == 'Call IT Dept') {
          launchUrl(Uri.parse('tel:0881234567'));
        } else {
          // Show live chat dialog
          _showLiveChatDialog();
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(HelpArticle article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showArticleDialog(article);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showArticleDialog(HelpArticle article) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                article.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    article.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Print article
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveChatDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Chat Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Available Monday-Friday',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                '8:00 AM - 5:00 PM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Status: Online',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Open chat window
                },
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Start Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<HelpArticle> articles;

  HelpCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.articles,
  });
}

class HelpArticle {
  final String title;
  final String description;
  final String content;

  HelpArticle({
    required this.title,
    required this.description,
    required this.content,
  });
}