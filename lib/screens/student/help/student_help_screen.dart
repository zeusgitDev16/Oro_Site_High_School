/// Student Help Screen
/// Provides comprehensive help documentation and support resources for students

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentHelpScreen extends StatefulWidget {
  const StudentHelpScreen({super.key});

  @override
  State<StudentHelpScreen> createState() => _StudentHelpScreenState();
}

class _StudentHelpScreenState extends State<StudentHelpScreen> {
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
          title: 'Welcome to ELMS',
          description: 'Learn how to navigate the student portal',
          content: '''
# Welcome to ELMS

The Electronic Learning Management System (ELMS) is your gateway to academic success at Oro Site High School.

## What You Can Do:
- View your class schedule
- Check grades and performance
- Submit assignments online
- Track attendance records
- Access learning materials
- Communicate with teachers
- View announcements

## First Time Login:
1. Go to https://elms.orosite.edu.ph
2. Click "Sign in with Microsoft"
3. Use your student email: firstname.lastname@student.orosite.onmicrosoft.com
4. Enter your temporary password
5. Change your password when prompted

## Navigation Tips:
- Use the sidebar menu to access different sections
- Check notifications regularly for updates
- Your dashboard shows important information at a glance
          ''',
        ),
        HelpArticle(
          title: 'Dashboard Overview',
          description: 'Understanding your student dashboard',
          content: '''
# Dashboard Overview

Your dashboard is the central hub for all your academic information.

## Dashboard Sections:

### Quick Stats
- Current GWA (General Weighted Average)
- Attendance rate
- Pending assignments
- Upcoming activities

### Today's Schedule
Shows your classes for the current day with:
- Subject name
- Time slot
- Room number
- Teacher name

### Recent Grades
Latest grades posted by your teachers

### Announcements
Important updates from school and teachers

### Calendar
View upcoming events, exams, and deadlines

## Customization:
- You can rearrange dashboard widgets
- Hide/show sections based on preference
- Set notification preferences
          ''',
        ),
        HelpArticle(
          title: 'Mobile Access',
          description: 'Access ELMS on your phone or tablet',
          content: '''
# Mobile Access

ELMS is fully responsive and works on all devices.

## Accessing on Mobile:
1. Open your mobile browser
2. Go to https://elms.orosite.edu.ph
3. Sign in with your Microsoft account
4. The interface will adapt to your screen

## Mobile Features:
- All desktop features available
- Touch-optimized interface
- Offline mode for downloaded materials
- Push notifications (if enabled)

## Tips for Mobile:
- Save the site to your home screen
- Enable notifications for updates
- Download materials when on WiFi
- Use landscape mode for better viewing
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'courses',
      title: 'Courses & Lessons',
      icon: Icons.school,
      color: Colors.green,
      articles: [
        HelpArticle(
          title: 'Viewing Your Courses',
          description: 'How to access and navigate your enrolled courses',
          content: '''
# Viewing Your Courses

## Accessing Courses:
1. Click "Courses" in the main menu
2. View all your enrolled subjects
3. Click on any course to see details

## Course Information:
- Course code and name
- Teacher information
- Schedule (days and time)
- Room assignment
- Course description
- Learning objectives

## Course Materials:
Each course contains:
- Modules and lessons
- Learning resources
- Assignments
- Quizzes and exams
- Discussion forums

## Progress Tracking:
- See completed modules
- Track your progress percentage
- View upcoming lessons
- Check module deadlines
          ''',
        ),
        HelpArticle(
          title: 'Accessing Learning Materials',
          description: 'Download and view course materials',
          content: '''
# Accessing Learning Materials

## Types of Materials:
- PDF documents
- Video lessons
- Presentations
- Interactive content
- External links

## Downloading Materials:
1. Navigate to the course
2. Click on the module
3. Find the resource
4. Click download icon
5. File saves to your device

## Viewing Materials:
- PDFs open in browser
- Videos play inline
- Presentations viewable online
- Downloads available offline

## Organization Tips:
- Create folders by subject
- Name files clearly
- Keep backups of important materials
- Delete old files regularly
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'assignments',
      title: 'Assignments & Submissions',
      icon: Icons.assignment,
      color: Colors.orange,
      articles: [
        HelpArticle(
          title: 'Viewing Assignments',
          description: 'How to check and manage your assignments',
          content: '''
# Viewing Assignments

## Finding Assignments:
1. Click "Assignments" in the menu
2. View all assignments across subjects
3. Filter by:
   - Subject
   - Status (pending, submitted, graded)
   - Due date

## Assignment Details:
Each assignment shows:
- Title and description
- Subject and teacher
- Due date and time
- Points/weight
- Submission status
- Instructions
- Attached files

## Assignment Types:
- Individual assignments
- Group projects
- Online quizzes
- Performance tasks
- Portfolio submissions

## Notifications:
- New assignment alerts
- Due date reminders
- Grade posted notifications
          ''',
        ),
        HelpArticle(
          title: 'Submitting Assignments',
          description: 'How to submit your work online',
          content: '''
# Submitting Assignments

## Submission Process:
1. Open the assignment
2. Read instructions carefully
3. Click "Submit Assignment"
4. Choose submission type:
   - File upload
   - Text entry
   - URL/link
5. Add your work
6. Click "Submit"

## File Upload:
- Supported formats: PDF, DOC, DOCX, PPT, PPTX, images
- Maximum file size: 10MB
- Multiple files allowed (if specified)

## Before Submitting:
- Review requirements
- Check file format
- Verify file opens correctly
- Save a backup copy

## After Submission:
- Confirmation message appears
- Email receipt sent
- Can view submission
- May edit until deadline (if allowed)

## Late Submissions:
- Marked as late
- May have penalty
- Teacher discretion on acceptance
          ''',
        ),
        HelpArticle(
          title: 'Checking Feedback',
          description: 'View grades and teacher comments',
          content: '''
# Checking Feedback

## Viewing Grades:
1. Go to submitted assignment
2. Check status: "Graded"
3. View score and feedback
4. Read teacher comments

## Feedback Types:
- Numerical score
- Letter grade
- Rubric evaluation
- Written comments
- Annotated files

## Understanding Rubrics:
- Criteria breakdown
- Points per criterion
- Performance levels
- Total score calculation

## Responding to Feedback:
- Read carefully
- Note improvements needed
- Ask questions if unclear
- Apply to future work

## Grade Disputes:
- Contact teacher first
- Provide justification
- Follow school policy
- Respect deadlines
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'grades',
      title: 'Grades & Performance',
      icon: Icons.grade,
      color: Colors.purple,
      articles: [
        HelpArticle(
          title: 'Understanding Your Grades',
          description: 'How grades are calculated and displayed',
          content: '''
# Understanding Your Grades

## DepEd Grading System:

### Components:
- Written Works (WW) - 30%
- Performance Tasks (PT) - 50%
- Quarterly Assessment (QA) - 20%

### Grade Levels:
- 90-100: Outstanding
- 85-89: Very Satisfactory
- 80-84: Satisfactory
- 75-79: Fairly Satisfactory
- Below 75: Did Not Meet Expectations

## Viewing Grades:
1. Click "Grades" in menu
2. Select quarter
3. View by subject
4. See component breakdown

## Grade Calculation:
Final Grade = (WW × 0.3) + (PT × 0.5) + (QA × 0.2)

## Quarterly vs Final:
- 4 quarters per year
- Each quarter: 20%
- Final grade: Average of quarters
          ''',
        ),
        HelpArticle(
          title: 'Grade Reports',
          description: 'Generate and download grade reports',
          content: '''
# Grade Reports

## Available Reports:
- Quarterly report card
- Progress report
- Transcript of records
- Class ranking

## Generating Reports:
1. Go to Grades section
2. Click "Generate Report"
3. Select report type
4. Choose quarter/period
5. Click "Download PDF"

## Report Contents:
- Personal information
- Subjects and grades
- Attendance record
- Teacher remarks
- Parent signature line

## Sharing Reports:
- Download as PDF
- Print for parents
- Email to guardian
- Save for records
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'attendance',
      title: 'Attendance',
      icon: Icons.calendar_today,
      color: Colors.teal,
      articles: [
        HelpArticle(
          title: 'Checking Attendance',
          description: 'View your attendance records',
          content: '''
# Checking Attendance

## Viewing Attendance:
1. Click "Attendance" in menu
2. View monthly calendar
3. Check daily status:
   - Present (green)
   - Late (yellow)
   - Absent (red)
   - Excused (blue)

## Attendance Details:
- Time in/out
- Subject attendance
- Total days present
- Attendance percentage
- Perfect attendance streaks

## QR Code Scanning:
- Scan upon arrival
- Scan for each class
- Automatic time recording
- Real-time updates

## Attendance Requirements:
- Minimum 80% attendance
- Affects academic standing
- Required for clearance
          ''',
        ),
        HelpArticle(
          title: 'Excused Absences',
          description: 'How to submit excuse letters',
          content: '''
# Excused Absences

## Valid Reasons:
- Illness with medical certificate
- Family emergency
- School activities
- Religious observances

## Submission Process:
1. Prepare excuse letter
2. Get parent signature
3. Attach supporting documents
4. Submit within 3 days
5. Wait for approval

## Required Documents:
- Parent/guardian letter
- Medical certificate (if sick)
- Barangay certificate (if needed)
- Other supporting documents

## Approval Process:
- Teacher reviews
- Adviser approves
- Reflected in system
- Parents notified
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'communication',
      title: 'Messages & Notifications',
      icon: Icons.message,
      color: Colors.indigo,
      articles: [
        HelpArticle(
          title: 'Messaging Teachers',
          description: 'How to communicate with your teachers',
          content: '''
# Messaging Teachers

## Sending Messages:
1. Click "Messages" in menu
2. Click "Compose"
3. Select teacher
4. Type your message
5. Click "Send"

## Message Guidelines:
- Be respectful and polite
- Use proper grammar
- State purpose clearly
- Include relevant details
- Check before sending

## When to Message:
- Questions about lessons
- Assignment clarifications
- Request for consultation
- Report technical issues
- Inform about absences

## Response Time:
- Teachers reply within 24-48 hours
- Urgent matters: visit faculty room
- Respect office hours
- Avoid messaging late at night
          ''',
        ),
        HelpArticle(
          title: 'Notifications',
          description: 'Managing your notification preferences',
          content: '''
# Notifications

## Types of Notifications:
- New assignments
- Grade updates
- Announcements
- Messages
- Schedule changes
- Deadline reminders

## Setting Preferences:
1. Go to Settings
2. Click Notifications
3. Toggle categories on/off
4. Set quiet hours
5. Save changes

## Notification Channels:
- In-app notifications
- Email alerts
- SMS (if enabled)
- Push notifications (mobile)

## Managing Notifications:
- Mark as read
- Clear old notifications
- Filter by type
- Mute specific courses
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
- Check email spelling
- Verify CAPS LOCK is off
- Clear browser cache
- Try incognito mode
- Reset password if needed

## Assignment Not Uploading:
- Check file size (max 10MB)
- Verify file format
- Check internet connection
- Try different browser
- Contact teacher if persists

## Grades Not Showing:
- Refresh the page
- Check correct quarter
- Wait for teacher to post
- Clear browser cache

## QR Scanner Issues:
- Allow camera permission
- Clean camera lens
- Ensure good lighting
- Update browser
- Use backup manual entry

## Slow Performance:
- Close other tabs
- Clear browser cache
- Check internet speed
- Try different device
- Report to IT support
          ''',
        ),
        HelpArticle(
          title: 'Password Reset',
          description: 'How to reset your forgotten password',
          content: '''
# Password Reset

## Self-Service Reset:
1. Click "Forgot Password" at login
2. Enter your email
3. Check email for reset link
4. Click link within 24 hours
5. Create new password
6. Login with new password

## Password Requirements:
- Minimum 8 characters
- Include uppercase letter
- Include lowercase letter
- Include number
- Include special character

## If Email Not Received:
- Check spam folder
- Verify email address
- Wait 5 minutes
- Try again
- Contact IT support

## Security Tips:
- Never share password
- Change regularly
- Use unique password
- Enable 2FA if available
- Log out when done
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
                        Icons.person,
                        'Ask Your Teacher',
                        'Message via ELMS',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.support_agent,
                        'IT Support',
                        'Room 101 / Local 123',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.email,
                        'Email Support',
                        'support@orosite.edu.ph',
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
        } else if (title == 'Ask Your Teacher') {
          Navigator.pushNamed(context, '/messages');
        } else {
          // Show IT support info
          _showSupportDialog();
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

  void _showSupportDialog() {
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
                Icons.support_agent,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'IT Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location: Room 101 (Computer Lab)',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Local: 123',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Hours: 7:00 AM - 5:00 PM',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text(
                'For urgent technical issues, visit the IT office directly.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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