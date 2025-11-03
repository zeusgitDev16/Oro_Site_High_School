import 'package:flutter/foundation.dart';

/// Parent Messages Logic - Handles messaging state and operations
/// Mock implementation with sample data
class ParentMessagesLogic extends ChangeNotifier {
  bool _isLoading = false;
  String _selectedFolder = 'Inbox';
  String _searchQuery = '';
  Map<String, dynamic>? _selectedThread;
  List<Map<String, dynamic>> _threads = [];

  bool get isLoading => _isLoading;
  String get selectedFolder => _selectedFolder;
  Map<String, dynamic>? get selectedThread => _selectedThread;
  
  List<Map<String, dynamic>> get filteredThreads {
    var filtered = _threads.where((thread) {
      // Filter by folder
      bool matchesFolder = true;
      if (_selectedFolder == 'Inbox') {
        matchesFolder = thread['folder'] == 'Inbox';
      } else if (_selectedFolder == 'Sent') {
        matchesFolder = thread['folder'] == 'Sent';
      } else if (_selectedFolder == 'Starred') {
        matchesFolder = thread['starred'] == true;
      } else if (_selectedFolder == 'Archived') {
        matchesFolder = thread['archived'] == true;
      }

      // Filter by search
      bool matchesSearch = _searchQuery.isEmpty ||
          thread['subject'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          thread['from'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFolder && matchesSearch;
    }).toList();

    return filtered;
  }

  void loadMessages() {
    _isLoading = true;
    notifyListeners();

    // Mock data
    _threads = [
      {
        'id': 'thread-1',
        'from': 'Maria Santos (Teacher)',
        'subject': 'Regarding Juan\'s Math Performance',
        'preview': 'I wanted to discuss Juan\'s recent improvement in Mathematics...',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'unread': true,
        'starred': false,
        'archived': false,
        'folder': 'Inbox',
        'messages': [
          {
            'author': 'Maria Santos',
            'body': 'Good afternoon! I wanted to discuss Juan\'s recent improvement in Mathematics. He has been doing excellent work.',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
            'isMe': false,
          },
        ],
      },
      {
        'id': 'thread-2',
        'from': 'School Admin',
        'subject': 'Parent-Teacher Conference Schedule',
        'preview': 'The upcoming parent-teacher conference is scheduled for...',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'unread': true,
        'starred': true,
        'archived': false,
        'folder': 'Inbox',
        'messages': [
          {
            'author': 'School Admin',
            'body': 'The upcoming parent-teacher conference is scheduled for next Friday at 2:00 PM. Please confirm your attendance.',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)),
            'isMe': false,
          },
        ],
      },
      {
        'id': 'thread-3',
        'from': 'Pedro Garcia (Adviser)',
        'subject': 'Juan\'s Attendance Record',
        'preview': 'I noticed Juan was absent yesterday. Is everything okay?',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'unread': false,
        'starred': false,
        'archived': false,
        'folder': 'Inbox',
        'messages': [
          {
            'author': 'Pedro Garcia',
            'body': 'I noticed Juan was absent yesterday. Is everything okay?',
            'timestamp': DateTime.now().subtract(const Duration(days: 2)),
            'isMe': false,
          },
          {
            'author': 'You',
            'body': 'Yes, he had a doctor\'s appointment. I\'ve sent the excuse letter.',
            'timestamp': DateTime.now().subtract(const Duration(days: 2, hours: 2)),
            'isMe': true,
          },
        ],
      },
      {
        'id': 'thread-4',
        'from': 'School Nurse',
        'subject': 'Health Clearance Reminder',
        'preview': 'Please submit Juan\'s health clearance form by Friday.',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'unread': false,
        'starred': false,
        'archived': false,
        'folder': 'Inbox',
        'messages': [
          {
            'author': 'School Nurse',
            'body': 'Please submit Juan\'s health clearance form by Friday.',
            'timestamp': DateTime.now().subtract(const Duration(days: 3)),
            'isMe': false,
          },
        ],
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  void selectFolder(String folder) {
    _selectedFolder = folder;
    _selectedThread = null;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectThread(Map<String, dynamic> thread) {
    _selectedThread = thread;
    // Mark as read
    thread['unread'] = false;
    notifyListeners();
  }

  void toggleStar(Map<String, dynamic> thread) {
    thread['starred'] = !(thread['starred'] as bool);
    notifyListeners();
  }

  void toggleArchive(Map<String, dynamic> thread) {
    thread['archived'] = !(thread['archived'] as bool);
    if (thread['archived']) {
      thread['folder'] = 'Archived';
    } else {
      thread['folder'] = 'Inbox';
    }
    _selectedThread = null;
    notifyListeners();
  }

  void deleteThread(Map<String, dynamic> thread) {
    _threads.remove(thread);
    _selectedThread = null;
    notifyListeners();
  }

  void sendMessage(String message) {
    if (_selectedThread != null) {
      final messages = _selectedThread!['messages'] as List;
      messages.add({
        'author': 'You',
        'body': message,
        'timestamp': DateTime.now(),
        'isMe': true,
      });
      notifyListeners();
    }
  }

  void composeMessage(String recipient, String subject, String message) {
    final newThread = {
      'id': 'thread-${_threads.length + 1}',
      'from': recipient,
      'subject': subject,
      'preview': message.substring(0, message.length > 50 ? 50 : message.length),
      'timestamp': DateTime.now(),
      'unread': false,
      'starred': false,
      'archived': false,
      'folder': 'Sent',
      'messages': [
        {
          'author': 'You',
          'body': message,
          'timestamp': DateTime.now(),
          'isMe': true,
        },
      ],
    };
    _threads.insert(0, newThread);
    notifyListeners();
  }

  int getUnreadCount() {
    return _threads.where((t) => t['unread'] == true && t['folder'] == 'Inbox').length;
  }
}
