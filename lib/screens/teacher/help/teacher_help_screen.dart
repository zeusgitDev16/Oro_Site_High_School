/// Teacher Help Screen
/// Provides comprehensive help documentation and support resources for teachers

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherHelpScreen extends StatefulWidget {
  const TeacherHelpScreen({super.key});

  @override
  State<TeacherHelpScreen> createState() => _TeacherHelpScreenState();
}

class _TeacherHelpScreenState extends State<TeacherHelpScreen> {
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
          title: 'Teacher Portal Overview',
          description: 'Learn about the teacher dashboard and features',
          content: '''
# Teacher Portal Overview

Welcome to the ELMS Teacher Portal - your comprehensive teaching management system.

## Key Features:
- Class management
- Grade encoding
- Attendance tracking
- Assignment creation
- Student monitoring
- Parent communication
- Resource sharing
- Performance analytics

## First Time Login:
1. Navigate to https://elms.orosite.edu.ph
2. Click "Sign in with Microsoft"
3. Use your email: firstname.lastname@orosite.onmicrosoft.com
4. Enter your temporary password
5. Change password when prompted

## Dashboard Sections:
- Today's Schedule
- Recent Activities
- Pending Tasks
- Class Performance
- Announcements
- Calendar

## Role Capabilities:
- Regular Teacher: Manage assigned classes
- Grade Coordinator: Additional grade level permissions
- Hybrid (Admin+Teacher): Switch between roles
          ''',
        ),
        HelpArticle(
          title: 'Navigation Guide',
          description: 'How to navigate the teacher interface',
          content: '''
# Navigation Guide

## Main Menu:
- **Dashboard**: Overview and quick stats
- **Classes**: Your assigned subjects
- **Students**: Student roster and profiles
- **Grades**: Grade management system
- **Attendance**: Track student attendance
- **Assignments**: Create and manage tasks
- **Messages**: Communication center
- **Reports**: Analytics and reports

## Quick Actions:
Located on dashboard for fast access:
- Create Assignment
- Record Attendance
- Enter Grades
- Send Announcement

## Search Function:
- Search students by name or LRN
- Find assignments
- Locate resources
- Filter by class/section

## Switching Views:
For hybrid users (Admin+Teacher):
1. Click profile menu
2. Select "Switch Role"
3. Choose desired view
          ''',
        ),
        HelpArticle(
          title: 'Grade Coordinator Features',
          description: 'Additional features for grade coordinators',
          content: '''
# Grade Coordinator Features

## What is a Grade Coordinator?
A teacher with additional administrative privileges for a specific grade level.

## Additional Permissions:
- View all sections in grade level
- Generate grade-wide reports
- Coordinate with other teachers
- Monitor overall performance
- Manage grade-level activities

## Accessing Coordinator Mode:
1. Click toggle switch in header
2. Select "Coordinator Mode"
3. View expanded dashboard
4. Access additional features

## Coordinator Tools:
- Bulk grade entry
- Cross-section analytics
- Performance comparison
- Attendance overview
- Parent communication hub

## Responsibilities:
- Ensure grade consistency
- Monitor teacher compliance
- Generate quarterly reports
- Coordinate activities
- Support fellow teachers
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'class_management',
      title: 'Class Management',
      icon: Icons.class_,
      color: Colors.green,
      articles: [
        HelpArticle(
          title: 'Managing Your Classes',
          description: 'How to manage your assigned classes',
          content: '''
# Managing Your Classes

## Viewing Classes:
1. Click "Classes" in menu
2. View all assigned subjects
3. Click class for details

## Class Information:
- Subject code and name
- Section assignment
- Schedule (days/time)
- Room number
- Student count
- Class resources

## Class Actions:
- View student roster
- Post announcements
- Upload resources
- Create assignments
- Record attendance
- Enter grades

## Class Settings:
- Set grading weights
- Configure attendance rules
- Manage class calendar
- Set notification preferences

## Adding Co-Teachers:
1. Go to class settings
2. Click "Add Co-Teacher"
3. Search teacher name
4. Assign permissions
5. Send invitation
          ''',
        ),
        HelpArticle(
          title: 'Student Roster',
          description: 'Managing your class student list',
          content: '''
# Student Roster

## Viewing Students:
1. Open class
2. Click "Students" tab
3. View enrolled students
4. Click for student profile

## Student Information:
- Full name and LRN
- Contact information
- Parent details
- Academic performance
- Attendance record
- Submission history

## Student Actions:
- View individual progress
- Send message
- Contact parent
- Add remarks
- Generate report

## Managing Enrollment:
- View pending enrollments
- Approve/reject students
- Transfer students
- Mark as dropped

## Grouping Students:
- Create groups for projects
- Assign group leaders
- Set group tasks
- Monitor group progress
          ''',
        ),
        HelpArticle(
          title: 'Class Resources',
          description: 'Uploading and managing learning materials',
          content: '''
# Class Resources

## Uploading Materials:
1. Go to class page
2. Click "Resources" tab
3. Click "Upload"
4. Select files
5. Add description
6. Set visibility
7. Click "Save"

## Supported Formats:
- Documents: PDF, DOC, DOCX
- Presentations: PPT, PPTX
- Spreadsheets: XLS, XLSX
- Images: JPG, PNG, GIF
- Videos: MP4, AVI (via link)
- Audio: MP3, WAV

## Organizing Resources:
- Create folders by topic
- Add module numbers
- Use clear naming
- Include descriptions
- Set access permissions

## Resource Settings:
- Available from/until dates
- Download permissions
- View-only option
- Student visibility

## Best Practices:
- Keep file sizes small
- Use PDF for documents
- Compress images
- Host videos externally
- Update regularly
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'grading',
      title: 'Grading System',
      icon: Icons.grade,
      color: Colors.purple,
      articles: [
        HelpArticle(
          title: 'DepEd Grading System',
          description: 'Understanding the K-12 grading components',
          content: '''
# DepEd Grading System

## Grade Components:
According to DepEd Order No. 8, s. 2015:

### Written Works (30%)
- Quizzes
- Unit tests
- Essays
- Reports

### Performance Tasks (50%)
- Activities
- Projects
- Presentations
- Demonstrations

### Quarterly Assessment (20%)
- Quarterly exams
- Summative tests

## Grade Calculation:
Initial Grade = (WW × 0.3) + (PT × 0.5) + (QA × 0.2)

## Transmutation Table:
- 100: 100
- 98.40-99.99: 99
- 96.80-98.39: 98
- (See full table in DepEd guidelines)

## Descriptors:
- 90-100: Outstanding
- 85-89: Very Satisfactory
- 80-84: Satisfactory
- 75-79: Fairly Satisfactory
- Below 75: Did Not Meet Expectations
          ''',
        ),
        HelpArticle(
          title: 'Entering Grades',
          description: 'How to input and manage student grades',
          content: '''
# Entering Grades

## Grade Entry Process:
1. Go to "Grades" section
2. Select class and quarter
3. Choose component (WW/PT/QA)
4. Enter scores
5. System auto-calculates
6. Review and save
7. Submit for approval

## Entry Methods:
- Individual entry
- Bulk upload (Excel)
- Copy from previous
- Import from quiz

## Bulk Upload:
1. Download template
2. Fill in scores
3. Save as CSV/Excel
4. Upload file
5. Map columns
6. Verify data
7. Confirm import

## Grade Validation:
- Check score ranges
- Verify calculations
- Review outliers
- Confirm totals

## Editing Grades:
- Click on grade cell
- Enter new value
- Add remarks
- Save changes
- System logs edit

## Grade Submission:
- Complete all components
- Review accuracy
- Submit to registrar
- Lock after deadline
          ''',
        ),
        HelpArticle(
          title: 'Grade Reports',
          description: 'Generating grade sheets and reports',
          content: '''
# Grade Reports

## Available Reports:
- Class grade sheet
- Individual report cards
- Quarterly summary
- Final grades
- DepEd Form 138
- Honor roll list

## Generating Reports:
1. Go to Reports section
2. Select report type
3. Choose class/quarter
4. Set parameters
5. Preview report
6. Export/Print

## Export Formats:
- PDF (for printing)
- Excel (for analysis)
- CSV (for systems)
- DepEd forms

## Report Contents:
- Student information
- Grade components
- Quarterly grades
- Final grades
- Attendance
- Remarks

## Submission to DepEd:
- Generate Form 138
- Verify completeness
- Get approval
- Submit online
- Keep copies
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'attendance',
      title: 'Attendance Management',
      icon: Icons.calendar_today,
      color: Colors.orange,
      articles: [
        HelpArticle(
          title: 'Recording Attendance',
          description: 'How to track student attendance',
          content: '''
# Recording Attendance

## Methods:
1. **QR Scanner**
   - Create session
   - Students scan QR
   - Auto-record time
   - Real-time updates

2. **Manual Entry**
   - Open attendance sheet
   - Mark each student
   - Add time if needed
   - Save records

3. **Bulk Update**
   - Select multiple students
   - Apply same status
   - Add remarks
   - Save changes

## Attendance Status:
- Present (P)
- Late (L)
- Absent (A)
- Excused (E)

## Creating QR Session:
1. Click "Start Session"
2. Set time limit
3. Display QR code
4. Monitor scanning
5. Close session

## Late Marking:
- Set grace period
- Auto-mark late
- Configure rules
- Apply consistently
          ''',
        ),
        HelpArticle(
          title: 'Attendance Reports',
          description: 'Generate attendance summaries',
          content: '''
# Attendance Reports

## Report Types:
- Daily attendance
- Weekly summary
- Monthly report
- Quarterly overview
- Perfect attendance
- Chronic absences

## Generating Reports:
1. Go to Attendance
2. Click Reports
3. Select type
4. Choose period
5. Filter if needed
6. Generate

## Report Details:
- Total days
- Days present
- Days absent
- Late count
- Attendance rate
- Patterns

## DepEd Form 2:
- Daily attendance report
- Required submission
- Generate monthly
- Submit to principal

## Parent Notification:
- Auto-notify absences
- Send summaries
- Request meetings
- Document concerns
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'assignments',
      title: 'Assignments & Activities',
      icon: Icons.assignment,
      color: Colors.teal,
      articles: [
        HelpArticle(
          title: 'Creating Assignments',
          description: 'How to create and manage assignments',
          content: '''
# Creating Assignments

## Assignment Creation:
1. Go to Assignments
2. Click "Create New"
3. Fill in details:
   - Title
   - Description
   - Instructions
   - Points
   - Due date
4. Attach resources
5. Set submission type
6. Publish

## Assignment Types:
- Individual work
- Group project
- Online quiz
- Performance task
- Portfolio
- Research paper

## Submission Options:
- File upload
- Text entry
- URL submission
- Offline submission

## Settings:
- Due date and time
- Late submission policy
- Attempts allowed
- Plagiarism check
- Peer review

## Rubrics:
- Create rubric
- Set criteria
- Define levels
- Assign points
- Attach to assignment
          ''',
        ),
        HelpArticle(
          title: 'Reviewing Submissions',
          description: 'How to review and grade submissions',
          content: '''
# Reviewing Submissions

## Viewing Submissions:
1. Open assignment
2. Click "Submissions"
3. View submitted list
4. Click to review

## Review Process:
1. Open submission
2. View/download files
3. Check requirements
4. Apply rubric
5. Add feedback
6. Enter grade
7. Return to student

## Feedback Types:
- Score/grade
- Written comments
- Audio feedback
- Annotated files
- Rubric scores

## Bulk Actions:
- Download all
- Grade multiple
- Send reminders
- Extend deadline
- Return all

## Late Submissions:
- Mark as late
- Apply penalty
- Add comments
- Document reason

## Plagiarism Check:
- Run checker
- Review results
- Take action
- Document findings
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'communication',
      title: 'Communication',
      icon: Icons.message,
      color: Colors.indigo,
      articles: [
        HelpArticle(
          title: 'Messaging System',
          description: 'Communicate with students and parents',
          content: '''
# Messaging System

## Sending Messages:
1. Click Messages
2. Compose new
3. Select recipients
4. Type message
5. Attach if needed
6. Send

## Recipient Types:
- Individual student
- Entire class
- Parent/guardian
- Co-teachers
- Grade level

## Message Types:
- General announcement
- Assignment reminder
- Grade notification
- Attendance alert
- Meeting request

## Best Practices:
- Clear subject line
- Professional tone
- Timely responses
- Document important
- Follow up

## Auto-Messages:
- Grade posted
- Assignment created
- Attendance issue
- Due date reminder
          ''',
        ),
        HelpArticle(
          title: 'Parent Communication',
          description: 'Engaging with parents effectively',
          content: '''
# Parent Communication

## Communication Channels:
- ELMS messaging
- Email notifications
- SMS alerts
- Conference scheduling

## Regular Updates:
- Weekly progress
- Grade notifications
- Attendance alerts
- Behavior reports
- Achievement recognition

## Parent Conferences:
1. Schedule meeting
2. Send invitation
3. Prepare materials
4. Conduct meeting
5. Document outcomes
6. Follow up

## Information Sharing:
- Academic progress
- Attendance records
- Behavioral observations
- Areas of concern
- Improvement plans

## Best Practices:
- Regular communication
- Positive feedback
- Constructive criticism
- Clear expectations
- Collaborative approach
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
- Verify email format
- Check CAPS LOCK
- Clear browser cache
- Try different browser
- Contact IT support

## Grades Not Saving:
- Check internet connection
- Verify all fields complete
- Look for validation errors
- Try smaller batches
- Save frequently

## Scanner Not Working:
- Check session active
- Verify QR visible
- Ensure good lighting
- Try manual entry
- Restart session

## Reports Not Generating:
- Check date range
- Verify data exists
- Try different format
- Clear cache
- Reduce scope

## Messages Not Sending:
- Check recipients valid
- Verify connection
- Check attachment size
- Try plain text
- Send in batches

## Slow Performance:
- Close unused tabs
- Clear browser cache
- Check internet speed
- Try off-peak hours
- Report to IT
          ''',
        ),
        HelpArticle(
          title: 'Technical Support',
          description: 'How to get help when you need it',
          content: '''
# Technical Support

## Support Channels:
1. **IT Help Desk**
   - Room 201
   - Local 456
   - 7:00 AM - 6:00 PM

2. **Email Support**
   - itsupport@orosite.edu.ph
   - Response within 24 hours

3. **Phone Support**
   - (088) 123-4567
   - Monday-Friday
   - 8:00 AM - 5:00 PM

## Before Contacting:
- Note error messages
- Document steps taken
- Try basic troubleshooting
- Check help articles
- Prepare screenshots

## Information to Provide:
- Your name and ID
- Problem description
- When it occurred
- Error messages
- Browser/device used
- Steps to reproduce

## Emergency Issues:
- System down
- Data loss
- Security breach
- Grade deadline
- Contact IT immediately
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
                        Icons.support_agent,
                        'IT Support',
                        'Room 201 / Local 456',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.email,
                        'Email Support',
                        'itsupport@orosite.edu.ph',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.phone,
                        'Call Support',
                        '(088) 123-4567',
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
          launchUrl(Uri.parse('mailto:itsupport@orosite.edu.ph'));
        } else if (title == 'Call Support') {
          launchUrl(Uri.parse('tel:0881234567'));
        } else {
          // Show IT support dialog
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
                'Location: Room 201 (Faculty Office)',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Local: 456',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Hours: 7:00 AM - 6:00 PM',
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