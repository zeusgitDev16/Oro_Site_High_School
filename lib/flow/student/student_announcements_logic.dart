import 'package:flutter/material.dart';

/// Interactive logic for Student Announcements
/// Handles state management for announcements feed
/// Separated from UI as per architecture guidelines
/// Students receive announcements from teachers and admin
class StudentAnnouncementsLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingAnnouncements = false;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;

  // Filter
  String _selectedFilter = 'All'; // All, School, Class, Urgent

  String get selectedFilter => _selectedFilter;

  // Mock announcements - Student receives from teachers and admin
  final List<Map<String, dynamic>> _announcements = [
    {
      'id': 1,
      'title': 'Upcoming Quarterly Exam Schedule',
      'content': 'Dear students, please be informed that the quarterly examinations will be held from January 22-26, 2024. Please review your lessons and prepare well. Good luck!',
      'author': 'Admin Office',
      'authorRole': 'Admin',
      'type': 'School', // School, Class, Urgent
      'priority': 'high', // high, medium, low
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'isRead': false,
      'attachments': ['exam_schedule.pdf'],
    },
    {
      'id': 2,
      'title': 'Math 7 - Quiz 4 Postponed',
      'content': 'Good day class! Quiz 4 on Geometry has been postponed to next Monday, January 22. Please use this extra time to review. See you in class!',
      'author': 'Maria Santos',
      'authorRole': 'Teacher',
      'course': 'Mathematics 7',
      'type': 'Class',
      'priority': 'medium',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'isRead': false,
      'attachments': [],
    },
    {
      'id': 3,
      'title': 'URGENT: Class Suspension Tomorrow',
      'content': 'Due to inclement weather, classes are suspended tomorrow, January 16, 2024. Stay safe everyone! Online modules will be posted on the portal.',
      'author': 'Principal\'s Office',
      'authorRole': 'Admin',
      'type': 'Urgent',
      'priority': 'high',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'isRead': true,
      'attachments': [],
    },
    {
      'id': 4,
      'title': 'Science Fair Registration Now Open',
      'content': 'Calling all young scientists! Registration for the Annual Science Fair is now open. Submit your project proposals by January 25. This is a great opportunity to showcase your creativity and scientific knowledge!',
      'author': 'Science Department',
      'authorRole': 'Admin',
      'type': 'School',
      'priority': 'medium',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'attachments': ['science_fair_guidelines.pdf', 'registration_form.pdf'],
    },
    {
      'id': 5,
      'title': 'English 7 - Essay Submission Extended',
      'content': 'Good news! The deadline for the "My Hero" essay has been extended to Friday, January 19. Make sure to submit your best work. Looking forward to reading your essays!',
      'author': 'Ana Reyes',
      'authorRole': 'Teacher',
      'course': 'English 7',
      'type': 'Class',
      'priority': 'low',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      'isRead': true,
      'attachments': [],
    },
    {
      'id': 6,
      'title': 'Parent-Teacher Conference Schedule',
      'content': 'Dear students and parents, the quarterly parent-teacher conference is scheduled for January 27-28, 2024. Please inform your parents to check the portal for their assigned time slots. Your presence is highly encouraged.',
      'author': 'Guidance Office',
      'authorRole': 'Admin',
      'type': 'School',
      'priority': 'medium',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'attachments': ['conference_schedule.pdf'],
    },
    {
      'id': 7,
      'title': 'Filipino 7 - Tula Submission Reminder',
      'content': 'Magandang araw! Paalala lang na ang deadline ng inyong tula ay bukas na, January 16. Huwag kalimutang isumite ang inyong gawa. Salamat!',
      'author': 'Pedro Santos',
      'authorRole': 'Teacher',
      'course': 'Filipino 7',
      'type': 'Class',
      'priority': 'high',
      'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 10)),
      'isRead': true,
      'attachments': [],
    },
    {
      'id': 8,
      'title': 'School Library New Books Available',
      'content': 'The school library has received new books! Visit the library during break time to check out the latest additions. Happy reading!',
      'author': 'Library Staff',
      'authorRole': 'Admin',
      'type': 'School',
      'priority': 'low',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': true,
      'attachments': ['new_books_list.pdf'],
    },
  ];

  List<Map<String, dynamic>> get announcements => _announcements;

  // Get filtered announcements
  List<Map<String, dynamic>> getFilteredAnnouncements() {
    var filtered = List<Map<String, dynamic>>.from(_announcements);

    // Filter by type
    switch (_selectedFilter) {
      case 'School':
        filtered = filtered.where((a) => a['type'] == 'School').toList();
        break;
      case 'Class':
        filtered = filtered.where((a) => a['type'] == 'Class').toList();
        break;
      case 'Urgent':
        filtered = filtered.where((a) => a['type'] == 'Urgent').toList();
        break;
      // 'All' - no filter
    }

    // Sort by timestamp (most recent first)
    filtered.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return filtered;
  }

  // Get announcement by ID
  Map<String, dynamic>? getAnnouncementById(int announcementId) {
    try {
      return _announcements.firstWhere((a) => a['id'] == announcementId);
    } catch (e) {
      return null;
    }
  }

  // Get unread count
  int getUnreadCount() {
    return _announcements.where((a) => a['isRead'] == false).length;
  }

  // Mark as read
  void markAsRead(int announcementId) {
    final announcement = getAnnouncementById(announcementId);
    if (announcement != null) {
      announcement['isRead'] = true;
      notifyListeners();
    }
  }

  // Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Load announcements
  Future<void> loadAnnouncements() async {
    _isLoadingAnnouncements = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final announcements = await AnnouncementService.getStudentAnnouncements(studentId);

    _isLoadingAnnouncements = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
