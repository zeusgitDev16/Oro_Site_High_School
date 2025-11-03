/// Parent Help Screen
/// Provides comprehensive help documentation and support resources for parents

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentHelpScreen extends StatefulWidget {
  const ParentHelpScreen({super.key});

  @override
  State<ParentHelpScreen> createState() => _ParentHelpScreenState();
}

class _ParentHelpScreenState extends State<ParentHelpScreen> {
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
          title: 'Parent Portal Overview',
          description: 'Learn about the parent portal features',
          content: '''
# Parent Portal Overview

Welcome to the ELMS Parent Portal - your window to your child's academic journey.

## What You Can Do:
- Monitor academic progress
- View grades and report cards
- Track attendance records
- Check assignments and deadlines
- Communicate with teachers
- View school announcements
- Access learning resources
- Download reports

## First Time Login:
1. Receive invitation email from school
2. Click the activation link
3. Go to https://elms.orosite.edu.ph
4. Click "Sign in with Google"
5. Use your Gmail account
6. Complete profile setup

## Important Note:
Parents use Google accounts (Gmail) for authentication, unlike students and teachers who use Microsoft accounts.

## Dashboard Features:
- Child selection (for multiple children)
- Quick stats overview
- Recent activities
- Upcoming events
- Important announcements
          ''',
        ),
        HelpArticle(
          title: 'Account Setup',
          description: 'How to set up and link your parent account',
          content: '''
# Account Setup

## Account Creation:
Your account is created when your child is enrolled:
1. School admin enters your Gmail address
2. You receive an invitation email
3. Click the link to activate
4. Sign in with Google
5. Verify your information
6. Account is linked to your child

## Multiple Children:
If you have multiple children in school:
- All children linked to one account
- Switch between children easily
- View consolidated information
- Receive updates for all children

## Profile Information:
Complete your profile with:
- Contact number
- Alternative email
- Home address
- Emergency contact
- Notification preferences

## Security Settings:
- Enable two-factor authentication
- Set up security questions
- Review login history
- Manage connected devices
          ''',
        ),
        HelpArticle(
          title: 'Navigating the Portal',
          description: 'How to find information quickly',
          content: '''
# Navigating the Portal

## Main Menu:
- **Dashboard**: Overview of child's status
- **Grades**: Academic performance
- **Attendance**: Attendance records
- **Children**: Switch between children
- **Messages**: Communication center
- **Reports**: Generate reports
- **Settings**: Account preferences

## Child Selector:
For parents with multiple children:
1. Click child's name in header
2. Select different child
3. Dashboard updates automatically
4. View individual or combined data

## Search Function:
- Search for specific information
- Find teachers by name
- Locate assignments
- Search announcements

## Mobile Access:
- Fully responsive design
- Works on all devices
- Download mobile app (if available)
- Same features as desktop
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'monitoring',
      title: 'Monitoring Your Child',
      icon: Icons.visibility,
      color: Colors.green,
      articles: [
        HelpArticle(
          title: 'Viewing Grades',
          description: 'How to check your child\'s academic performance',
          content: '''
# Viewing Grades

## Accessing Grades:
1. Click "Grades" in menu
2. Select grading period
3. View subject grades
4. Click for details

## Grade Information:
- Subject name and teacher
- Component scores (WW, PT, QA)
- Quarterly grade
- Final grade
- Class standing

## Understanding Grades:
### DepEd Grading System:
- Written Works (30%)
- Performance Tasks (50%)
- Quarterly Assessment (20%)

### Grade Descriptors:
- 90-100: Outstanding
- 85-89: Very Satisfactory
- 80-84: Satisfactory
- 75-79: Fairly Satisfactory
- Below 75: Did Not Meet Expectations

## Grade Notifications:
- Real-time updates
- Email alerts for new grades
- Quarterly report cards
- Final grades notification
          ''',
        ),
        HelpArticle(
          title: 'Attendance Monitoring',
          description: 'Track your child\'s school attendance',
          content: '''
# Attendance Monitoring

## Viewing Attendance:
1. Click "Attendance" in menu
2. View monthly calendar
3. Check daily status
4. Review attendance rate

## Attendance Status:
- **Present** (Green): On time
- **Late** (Yellow): Arrived late
- **Absent** (Red): Did not attend
- **Excused** (Blue): Valid excuse

## Real-time Updates:
- Instant notification when child scans in
- Daily attendance summary
- Weekly attendance report
- Monthly overview

## Attendance Alerts:
Automatic notifications for:
- Unexcused absences
- Frequent tardiness
- Low attendance rate
- Perfect attendance

## Submitting Excuses:
1. Click on absent date
2. Upload excuse letter
3. Add explanation
4. Submit for approval
5. Track status
          ''',
        ),
        HelpArticle(
          title: 'Assignment Tracking',
          description: 'Monitor assignments and submissions',
          content: '''
# Assignment Tracking

## Viewing Assignments:
1. Go to child's dashboard
2. See pending assignments
3. Check due dates
4. View submission status

## Assignment Details:
- Subject and teacher
- Instructions
- Due date and time
- Points/weight
- Submission status
- Grade (when available)

## Status Types:
- **Pending**: Not yet submitted
- **Submitted**: Turned in
- **Late**: Submitted after deadline
- **Graded**: Score available
- **Missing**: Not submitted

## Helping Your Child:
- Review assignment requirements
- Check deadlines regularly
- Ensure timely submission
- Monitor completion rate
- Communicate with teacher if needed

## Notifications:
- New assignment alerts
- Due date reminders
- Submission confirmations
- Grade posted alerts
          ''',
        ),
        HelpArticle(
          title: 'Progress Reports',
          description: 'Understanding your child\'s overall progress',
          content: '''
# Progress Reports

## Types of Reports:
- Daily activity summary
- Weekly progress report
- Quarterly report card
- Annual transcript
- Behavior reports
- Achievement certificates

## Accessing Reports:
1. Click "Reports" in menu
2. Select report type
3. Choose period
4. View or download

## Report Contents:
- Academic performance
- Attendance summary
- Behavior notes
- Teacher comments
- Recommendations
- Areas for improvement

## Understanding Metrics:
- GWA (General Weighted Average)
- Class ranking
- Attendance percentage
- Assignment completion rate
- Participation score

## Using Reports:
- Track improvement
- Identify challenges
- Celebrate achievements
- Plan interventions
- Prepare for conferences
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'communication',
      title: 'Communication',
      icon: Icons.message,
      color: Colors.purple,
      articles: [
        HelpArticle(
          title: 'Messaging Teachers',
          description: 'How to communicate with your child\'s teachers',
          content: '''
# Messaging Teachers

## Sending Messages:
1. Click "Messages"
2. Click "Compose"
3. Select teacher
4. Write message
5. Send

## Message Guidelines:
- Be respectful and professional
- State purpose clearly
- Keep messages concise
- Allow time for response
- Follow up if needed

## Appropriate Topics:
- Academic concerns
- Behavioral issues
- Request for meeting
- Clarifications
- Child's special needs
- Absence notifications

## Response Time:
- Teachers typically respond within 24-48 hours
- Urgent matters: call the school
- Respect teacher's personal time
- Use emergency contacts for urgent issues

## Meeting Requests:
1. Send message requesting meeting
2. Propose dates/times
3. State meeting purpose
4. Wait for confirmation
5. Attend meeting
          ''',
        ),
        HelpArticle(
          title: 'School Announcements',
          description: 'Stay updated with school news',
          content: '''
# School Announcements

## Types of Announcements:
- School events
- Schedule changes
- Holiday notifications
- PTA meetings
- Important reminders
- Emergency alerts

## Viewing Announcements:
1. Check dashboard regularly
2. Click "Announcements"
3. Filter by category
4. Mark as read

## Notification Settings:
- Email alerts
- SMS notifications (if enabled)
- Push notifications
- In-app alerts

## Categories:
- General announcements
- Grade-specific
- Section-specific
- Urgent notices
- Events
- Reminders

## Staying Informed:
- Check daily
- Read thoroughly
- Note important dates
- RSVP when required
- Share with family
          ''',
        ),
        HelpArticle(
          title: 'Parent-Teacher Conferences',
          description: 'Preparing for and attending conferences',
          content: '''
# Parent-Teacher Conferences

## Scheduling:
1. Receive invitation
2. Choose time slot
3. Confirm attendance
4. Receive reminder

## Preparation:
- Review child's grades
- Check attendance record
- List questions/concerns
- Review teacher comments
- Bring necessary documents

## During Conference:
- Arrive on time
- Listen actively
- Ask questions
- Take notes
- Discuss solutions
- Set goals

## Topics to Discuss:
- Academic performance
- Social development
- Behavioral concerns
- Learning challenges
- Home support strategies
- Future goals

## Follow-up:
- Implement suggestions
- Monitor progress
- Maintain communication
- Schedule follow-up if needed
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'reports',
      title: 'Reports & Documents',
      icon: Icons.description,
      color: Colors.orange,
      articles: [
        HelpArticle(
          title: 'Downloading Report Cards',
          description: 'How to access and download report cards',
          content: '''
# Downloading Report Cards

## Accessing Report Cards:
1. Go to "Reports"
2. Select "Report Cards"
3. Choose quarter
4. Click "Download PDF"

## Report Card Contents:
- Student information
- Subject grades
- Quarterly average
- Attendance summary
- Teacher remarks
- Parent signature line

## Digital Signatures:
- View online
- Download PDF
- Print for records
- Digital acknowledgment
- Submit signed copy (if required)

## Quarterly Schedule:
- Q1: October
- Q2: December
- Q3: March
- Q4: May

## Final Report Card:
- Available end of school year
- Includes all quarters
- Final grades
- Promotion status
          ''',
        ),
        HelpArticle(
          title: 'Generating Certificates',
          description: 'Request and download certificates',
          content: '''
# Generating Certificates

## Available Certificates:
- Certificate of Enrollment
- Certificate of Good Moral
- Honor certificates
- Perfect attendance
- Completion certificates

## Requesting Certificates:
1. Go to "Reports"
2. Click "Certificates"
3. Select type
4. Submit request
5. Wait for approval
6. Download when ready

## Processing Time:
- Standard: 3-5 days
- Urgent: 1-2 days (with fee)
- Honor certificates: After recognition

## Digital Certificates:
- PDF format
- QR code verification
- Official school seal
- Digital signature
- Print-ready format
          ''',
        ),
      ],
    ),
    HelpCategory(
      id: 'account',
      title: 'Account Settings',
      icon: Icons.settings,
      color: Colors.teal,
      articles: [
        HelpArticle(
          title: 'Notification Preferences',
          description: 'Manage how you receive updates',
          content: '''
# Notification Preferences

## Notification Types:
- Grade updates
- Attendance alerts
- Assignment reminders
- Announcements
- Messages
- Emergency alerts

## Delivery Methods:
- Email notifications
- SMS alerts (if available)
- Push notifications
- In-app notifications

## Setting Preferences:
1. Go to Settings
2. Click Notifications
3. Toggle categories
4. Select delivery method
5. Set quiet hours
6. Save changes

## Frequency Options:
- Immediate
- Daily digest
- Weekly summary
- Critical only

## Managing Alerts:
- Customize by child
- Set priority levels
- Mute during vacations
- Emergency override
          ''',
        ),
        HelpArticle(
          title: 'Security Settings',
          description: 'Keep your account secure',
          content: '''
# Security Settings

## Account Security:
- Use strong password
- Enable 2FA
- Review login history
- Update recovery email
- Set security questions

## Google Account:
Since you use Google Sign-in:
- Secure your Gmail
- Enable Google 2FA
- Review connected apps
- Check account activity

## Privacy Settings:
- Control data visibility
- Manage sharing preferences
- Review permissions
- Download your data

## Suspicious Activity:
If you notice unusual activity:
1. Change password immediately
2. Review recent logins
3. Remove unknown devices
4. Contact school IT
5. Report to Google
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
- Use Google Sign-in button
- Check Gmail account
- Verify invitation received
- Clear browser cache
- Try different browser

## Child Not Showing:
- Contact school admin
- Verify linking complete
- Check enrollment status
- Refresh account

## Grades Not Visible:
- Check correct quarter
- Verify teacher posted
- Refresh page
- Clear cache
- Contact teacher

## Missing Notifications:
- Check spam folder
- Verify email address
- Review settings
- Update preferences
- Check filters

## Report Not Downloading:
- Check internet connection
- Try different browser
- Disable popup blocker
- Clear downloads folder
- Try again later
          ''',
        ),
        HelpArticle(
          title: 'Getting Support',
          description: 'How to get help when you need it',
          content: '''
# Getting Support

## Support Channels:

### School Support:
- **Registrar Office**
  - Academic records
  - Enrollment issues
  - Report cards
  - Hours: 8:00 AM - 5:00 PM

- **Guidance Office**
  - Student concerns
  - Behavioral issues
  - Counseling services
  - Hours: 7:30 AM - 4:30 PM

- **IT Support**
  - Technical issues
  - Account problems
  - Password reset
  - Email: support@orosite.edu.ph

### Contact Information:
- Main Office: (088) 123-4567
- Registrar: Local 201
- Guidance: Local 202
- IT Support: Local 203

### Before Contacting:
- Check help articles
- Try basic troubleshooting
- Prepare information
- Note error messages
- Have child's LRN ready

### Emergency Contacts:
- School Clinic: Local 911
- Security: Local 999
- Principal: Local 101
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
                    color: Colors.green.shade50,
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
                        Icons.school,
                        'Contact School',
                        '(088) 123-4567',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.email,
                        'Email Support',
                        'support@orosite.edu.ph',
                      ),
                      const SizedBox(height: 8),
                      _buildSupportLink(
                        Icons.person,
                        'Guidance Office',
                        'Local 202',
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
        } else if (title == 'Contact School') {
          launchUrl(Uri.parse('tel:0881234567'));
        } else {
          // Show guidance office info
          _showSupportDialog();
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.green,
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
                Icons.person,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'Guidance Office',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location: 2nd Floor, Main Building',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Local: 202',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Hours: 7:30 AM - 4:30 PM',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text(
                'For student concerns and counseling services.',
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