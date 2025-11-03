import 'package:flutter/material.dart';

/// Interactive logic for Student Messages
/// Handles state management for messaging system
/// Separated from UI as per architecture guidelines
/// Students can receive messages from teachers and send replies
class StudentMessagesLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  // Filters
  String _selectedFolder = 'All'; // All, Unread, Starred, Archived
  String _searchQuery = '';

  String get selectedFolder => _selectedFolder;
  String get searchQuery => _searchQuery;

  // Selected thread
  int? _selectedThreadId;
  int? get selectedThreadId => _selectedThreadId;

  // Mock message threads - Student receives from teachers
  final List<Map<String, dynamic>> _threads = [
    {
      'id': 1,
      'subject': 'Assignment Feedback - Math Quiz 3',
      'sender': {
        'id': 't1',
        'name': 'Maria Santos',
        'role': 'Teacher',
        'initials': 'MS',
      },
      'messages': [
        {
          'id': 'm1',
          'senderId': 't1',
          'senderName': 'Maria Santos',
          'body': 'Hi Juan! I reviewed your Math Quiz 3. Excellent work on problems 1-8! However, please review problem 9 about quadratic equations. You made a small error in the factoring step. Overall score: 45/50 (90%). Keep up the good work!',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isFromMe': false,
        },
      ],
      'unreadCount': 1,
      'starred': false,
      'archived': false,
      'lastMessageAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 2,
      'subject': 'Reminder: Science Project Due Date',
      'sender': {
        'id': 't2',
        'name': 'Juan Cruz',
        'role': 'Teacher',
        'initials': 'JC',
      },
      'messages': [
        {
          'id': 'm2',
          'senderId': 't2',
          'senderName': 'Juan Cruz',
          'body': 'Good day! This is a reminder that your Solar System Model project is due this Friday, January 19. Please make sure to submit your work on time. If you have any questions, feel free to ask. Good luck!',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'isFromMe': false,
        },
      ],
      'unreadCount': 1,
      'starred': false,
      'archived': false,
      'lastMessageAt': DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      'id': 3,
      'subject': 'Great work on your essay!',
      'sender': {
        'id': 't3',
        'name': 'Ana Reyes',
        'role': 'Teacher',
        'initials': 'AR',
      },
      'messages': [
        {
          'id': 'm3',
          'senderId': 't3',
          'senderName': 'Ana Reyes',
          'body': 'Hi Juan! I just finished reading your essay "My Hero" and I\'m very impressed! Your writing has improved significantly. The structure is clear, your arguments are well-supported, and your conclusion is powerful. Score: 48/50 (96%). Excellent work!',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'isFromMe': false,
        },
        {
          'id': 'm4',
          'senderId': 's1',
          'senderName': 'Juan Dela Cruz',
          'body': 'Thank you so much Ma\'am! I really worked hard on that essay. I appreciate your feedback!',
          'timestamp': DateTime.now().subtract(const Duration(hours: 20)),
          'isFromMe': true,
        },
      ],
      'unreadCount': 0,
      'starred': true,
      'archived': false,
      'lastMessageAt': DateTime.now().subtract(const Duration(hours: 20)),
    },
    {
      'id': 4,
      'subject': 'Attendance Follow-up',
      'sender': {
        'id': 't1',
        'name': 'Maria Santos',
        'role': 'Teacher',
        'initials': 'MS',
      },
      'messages': [
        {
          'id': 'm5',
          'senderId': 't1',
          'senderName': 'Maria Santos',
          'body': 'Hi Juan! I noticed you were absent from class last Tuesday. I hope everything is okay. We covered Module 4: Basic Algebra. Please review the lesson materials and let me know if you need any help catching up.',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)),
          'isFromMe': false,
        },
        {
          'id': 'm6',
          'senderId': 's1',
          'senderName': 'Juan Dela Cruz',
          'body': 'Good afternoon Ma\'am! I was sick that day but I\'m feeling better now. I will review the materials. Thank you for checking on me!',
          'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 20)),
          'isFromMe': true,
        },
        {
          'id': 'm7',
          'senderId': 't1',
          'senderName': 'Maria Santos',
          'body': 'Glad to hear you\'re feeling better! If you have any questions about the lesson, don\'t hesitate to ask. Take care!',
          'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 18)),
          'isFromMe': false,
        },
      ],
      'unreadCount': 0,
      'starred': false,
      'archived': false,
      'lastMessageAt': DateTime.now().subtract(const Duration(days: 1, hours: 18)),
    },
    {
      'id': 5,
      'subject': 'Class Schedule Change',
      'sender': {
        'id': 't4',
        'name': 'Pedro Santos',
        'role': 'Teacher',
        'initials': 'PS',
      },
      'messages': [
        {
          'id': 'm8',
          'senderId': 't4',
          'senderName': 'Pedro Santos',
          'body': 'Magandang araw! Please be informed that our Filipino class on Friday will be moved to Room 305 instead of our usual room. Salamat!',
          'timestamp': DateTime.now().subtract(const Duration(days: 3)),
          'isFromMe': false,
        },
      ],
      'unreadCount': 0,
      'starred': false,
      'archived': true,
      'lastMessageAt': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  List<Map<String, dynamic>> get threads => _threads;

  // Get filtered threads
  List<Map<String, dynamic>> getFilteredThreads() {
    var filtered = List<Map<String, dynamic>>.from(_threads);

    // Filter by folder
    switch (_selectedFolder) {
      case 'Unread':
        filtered = filtered.where((t) => (t['unreadCount'] as int) > 0).toList();
        break;
      case 'Starred':
        filtered = filtered.where((t) => t['starred'] == true).toList();
        break;
      case 'Archived':
        filtered = filtered.where((t) => t['archived'] == true).toList();
        break;
      // 'All' - no filter
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final subject = (t['subject'] as String).toLowerCase();
        final senderName = (t['sender']['name'] as String).toLowerCase();
        final messages = t['messages'] as List;
        final hasMessageMatch = messages.any((m) => (m['body'] as String).toLowerCase().contains(query));
        
        return subject.contains(query) || senderName.contains(query) || hasMessageMatch;
      }).toList();
    }

    // Sort by last message time
    filtered.sort((a, b) => (b['lastMessageAt'] as DateTime).compareTo(a['lastMessageAt'] as DateTime));

    return filtered;
  }

  // Get thread by ID
  Map<String, dynamic>? getThreadById(int threadId) {
    try {
      return _threads.firstWhere((t) => t['id'] == threadId);
    } catch (e) {
      return null;
    }
  }

  // Get unread count
  int getUnreadCount() {
    return _threads.where((t) => (t['unreadCount'] as int) > 0).length;
  }

  // Select thread
  void selectThread(int threadId) {
    _selectedThreadId = threadId;
    
    // Mark as read
    final thread = getThreadById(threadId);
    if (thread != null) {
      thread['unreadCount'] = 0;
    }
    
    notifyListeners();
  }

  // Toggle star
  void toggleStar(int threadId) {
    final thread = getThreadById(threadId);
    if (thread != null) {
      thread['starred'] = !(thread['starred'] as bool);
      notifyListeners();
    }
  }

  // Toggle archive
  void toggleArchive(int threadId) {
    final thread = getThreadById(threadId);
    if (thread != null) {
      thread['archived'] = !(thread['archived'] as bool);
      notifyListeners();
    }
  }

  // Send reply
  void sendReply(int threadId, String message) {
    final thread = getThreadById(threadId);
    if (thread != null) {
      final messages = thread['messages'] as List;
      messages.add({
        'id': 'm${DateTime.now().millisecondsSinceEpoch}',
        'senderId': 's1',
        'senderName': 'Juan Dela Cruz',
        'body': message,
        'timestamp': DateTime.now(),
        'isFromMe': true,
      });
      thread['lastMessageAt'] = DateTime.now();
      notifyListeners();
    }
  }

  // Set folder
  void setFolder(String folder) {
    _selectedFolder = folder;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Load messages
  Future<void> loadMessages() async {
    _isLoadingMessages = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final messages = await MessageService.getStudentMessages(studentId);

    _isLoadingMessages = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
