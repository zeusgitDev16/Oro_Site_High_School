import 'package:flutter/material.dart';

/// Student messaging domain models and interactive logic (no backend hookups).
/// This file contains ChangeNotifier-based state and plain models to
/// separate UI from behavior.
/// Aligned with teacher/admin messaging system

class StudentMessagesState extends ChangeNotifier {
  // Folders/filters
  final List<Folder> folders = const [
    Folder('All', Icons.inbox_outlined),
    Folder('Unread', Icons.markunread_outlined),
    Folder('Starred', Icons.star_border),
    Folder('Archived', Icons.archive_outlined),
    Folder('Sent', Icons.send_outlined),
  ];
  final List<Label> labels = [];

  // Data
  final List<Thread> allThreads = [];
  Thread? selectedThread;
  String search = '';
  String selectedFolder = 'All';
  Set<String> activeLabelIds = {};

  // Compose state
  String composerText = '';

  void initMockData() {
    // Labels
    labels.addAll([
      Label(id: 'l1', name: 'Teachers', color: Colors.blue),
      Label(id: 'l2', name: 'Important', color: Colors.red),
      Label(id: 'l3', name: 'Assignments', color: Colors.green),
    ]);

    // Mock users
    final student = User(id: 's1', name: 'Juan Dela Cruz', initials: 'JD');
    final teacher1 = User(id: 't1', name: 'Maria Santos', initials: 'MS');
    final teacher2 = User(id: 't2', name: 'Juan Cruz', initials: 'JC');
    final teacher3 = User(id: 't3', name: 'Ana Reyes', initials: 'AR');
    final teacher4 = User(id: 't4', name: 'Pedro Santos', initials: 'PS');

    // Threads
    final now = DateTime.now();
    allThreads.addAll([
      Thread(
        id: 'th1',
        subject: 'Assignment Feedback - Math Quiz 3',
        participants: [student, teacher1],
        labels: {'l1', 'l3'},
        pinned: false,
        messages: [
          Msg(
            id: 'm1',
            author: teacher1,
            body: 'Hi Juan! I reviewed your Math Quiz 3. Excellent work on problems 1-8! However, please review problem 9 about quadratic equations. You made a small error in the factoring step. Overall score: 45/50 (90%). Keep up the good work!',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        unreadCount: 1,
      ),
      Thread(
        id: 'th2',
        subject: 'Reminder: Science Project Due Date',
        participants: [student, teacher2],
        labels: {'l1', 'l2'},
        pinned: false,
        messages: [
          Msg(
            id: 'm2',
            author: teacher2,
            body: 'Good day! This is a reminder that your Solar System Model project is due this Friday, January 19. Please make sure to submit your work on time. If you have any questions, feel free to ask. Good luck!',
            createdAt: now.subtract(const Duration(hours: 5)),
          ),
        ],
        unreadCount: 1,
      ),
      Thread(
        id: 'th3',
        subject: 'Great work on your essay!',
        participants: [student, teacher3],
        labels: {'l1'},
        pinned: false,
        starred: true,
        messages: [
          Msg(
            id: 'm3',
            author: teacher3,
            body: 'Hi Juan! I just finished reading your essay "My Hero" and I\'m very impressed! Your writing has improved significantly. The structure is clear, your arguments are well-supported, and your conclusion is powerful. Score: 48/50 (96%). Excellent work!',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          Msg(
            id: 'm4',
            author: student,
            body: 'Thank you so much Ma\'am! I really worked hard on that essay. I appreciate your feedback!',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
        unreadCount: 0,
      ),
      Thread(
        id: 'th4',
        subject: 'Attendance Follow-up',
        participants: [student, teacher1],
        labels: {'l1'},
        pinned: false,
        messages: [
          Msg(
            id: 'm5',
            author: teacher1,
            body: 'Hi Juan! I noticed you were absent from class last Tuesday. I hope everything is okay. We covered Module 4: Basic Algebra. Please review the lesson materials and let me know if you need any help catching up.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          Msg(
            id: 'm6',
            author: student,
            body: 'Good afternoon Ma\'am! I was sick that day but I\'m feeling better now. I will review the materials. Thank you for checking on me!',
            createdAt: now.subtract(const Duration(days: 1, hours: 20)),
          ),
          Msg(
            id: 'm7',
            author: teacher1,
            body: 'Glad to hear you\'re feeling better! If you have any questions about the lesson, don\'t hesitate to ask. Take care!',
            createdAt: now.subtract(const Duration(days: 1, hours: 18)),
          ),
        ],
        unreadCount: 0,
      ),
      Thread(
        id: 'th5',
        subject: 'Class Schedule Change',
        participants: [student, teacher4],
        labels: {'l1'},
        pinned: false,
        archived: true,
        messages: [
          Msg(
            id: 'm8',
            author: teacher4,
            body: 'Magandang araw! Please be informed that our Filipino class on Friday will be moved to Room 305 instead of our usual room. Salamat!',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ],
        unreadCount: 0,
      ),
    ]);

    // Default selection
    selectedThread = allThreads.first;
    notifyListeners();
  }

  List<Thread> get filteredThreads {
    Iterable<Thread> list = allThreads;
    // Folder filtering
    switch (selectedFolder) {
      case 'Unread':
        list = list.where((t) => t.unreadCount > 0);
        break;
      case 'Starred':
        list = list.where((t) => t.starred);
        break;
      case 'Archived':
        list = list.where((t) => t.archived);
        break;
      case 'Sent':
        list = list.where((t) => t.sentByStudent);
        break;
      default:
        break;
    }
    if (activeLabelIds.isNotEmpty) {
      list = list.where((t) => t.labels.any(activeLabelIds.contains));
    }
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((t) =>
          t.subject.toLowerCase().contains(q) ||
          t.messages.any((m) => m.body.toLowerCase().contains(q)) ||
          t.participants.any((p) => p.name.toLowerCase().contains(q)));
    }
    final result = list.toList();
    result.sort((a, b) => (b.lastMessageAt).compareTo(a.lastMessageAt));
    return result;
  }

  void selectFolder(String name) {
    selectedFolder = name;
    notifyListeners();
  }

  void toggleLabel(String id) {
    if (activeLabelIds.contains(id)) {
      activeLabelIds.remove(id);
    } else {
      activeLabelIds.add(id);
    }
    notifyListeners();
  }

  void updateSearch(String value) {
    search = value;
    notifyListeners();
  }

  void selectThread(Thread t) {
    selectedThread = t;
    t.unreadCount = 0;
    notifyListeners();
  }

  void toggleStar(Thread t) {
    t.starred = !t.starred;
    notifyListeners();
  }

  void toggleArchive(Thread t) {
    t.archived = !t.archived;
    notifyListeners();
  }

  void deleteThread(Thread t) {
    allThreads.removeWhere((x) => x.id == t.id);
    if (selectedThread?.id == t.id) {
      selectedThread = allThreads.isNotEmpty ? allThreads.first : null;
    }
    notifyListeners();
  }

  void sendMessage(String text) {
    final thread = selectedThread;
    if (thread == null) return;
    final msg = Msg(
      id: UniqueKey().toString(),
      author: User(id: 's1', name: 'Juan Dela Cruz', initials: 'JD'),
      body: text.trim(),
      createdAt: DateTime.now(),
    );
    thread.messages.add(msg);
    composerText = '';
    notifyListeners();
  }

  void createNewThread({
    required String subject,
    required String body,
    required List<User> recipients,
    Set<String> labels = const {},
  }) {
    final thread = Thread(
      id: UniqueKey().toString(),
      subject: subject.isEmpty ? 'Untitled conversation' : subject,
      participants: [
        User(id: 's1', name: 'Juan Dela Cruz', initials: 'JD'),
        ...recipients,
      ],
      messages: [
        Msg(
          id: UniqueKey().toString(),
          author: User(id: 's1', name: 'Juan Dela Cruz', initials: 'JD'),
          body: body,
          createdAt: DateTime.now(),
        ),
      ],
      sentByStudent: true,
      labels: labels,
    );
    allThreads.insert(0, thread);
    selectedThread = thread;
    notifyListeners();
  }

  int getUnreadCount() {
    return allThreads.where((t) => t.unreadCount > 0).length;
  }
}

class Folder {
  final String name;
  final IconData icon;
  const Folder(this.name, this.icon);
}

class Label {
  final String id;
  final String name;
  final Color color;
  const Label({required this.id, required this.name, required this.color});
}

class User {
  final String id;
  final String name;
  final String initials;
  const User({required this.id, required this.name, required this.initials});
}

class Msg {
  final String id;
  final User author;
  final String body;
  final DateTime createdAt;
  Msg({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
  });
}

class Thread {
  final String id;
  String subject;
  final List<User> participants;
  final List<Msg> messages;
  Set<String> labels;
  bool pinned;
  bool starred;
  bool archived;
  bool sentByStudent;
  int unreadCount;

  Thread({
    required this.id,
    required this.subject,
    required this.participants,
    required this.messages,
    this.labels = const {},
    this.pinned = false,
    this.starred = false,
    this.archived = false,
    this.sentByStudent = false,
    this.unreadCount = 0,
  });

  DateTime get lastMessageAt => messages.isNotEmpty
      ? messages.last.createdAt
      : DateTime.fromMillisecondsSinceEpoch(0);
}
