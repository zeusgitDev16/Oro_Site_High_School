import 'package:flutter/material.dart';

/// Teacher messaging domain models and interactive logic (no backend hookups).
/// This file contains ChangeNotifier-based state and plain models to
/// separate UI from behavior.

class TeacherMessagesState extends ChangeNotifier {
  // Folders/filters
  final List<Folder> folders = const [
    Folder('All', Icons.inbox_outlined),
    Folder('Unread', Icons.markunread_outlined),
    Folder('Starred', Icons.star_border),
    Folder('Archived', Icons.archive_outlined),
    Folder('Sent', Icons.send_outlined),
    Folder('Drafts', Icons.drafts_outlined),
  ];
  final List<Label> labels = [];

  // Templates (teacher-managed canned messages)
  final List<Template> templates = [];

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
      Label(id: 'l1', name: 'Students', color: Colors.green),
      Label(id: 'l2', name: 'Parents', color: Colors.purple),
      Label(id: 'l3', name: 'Teachers', color: Colors.blue),
      Label(id: 'l4', name: 'Urgent', color: Colors.red),
    ]);

    // Templates
    templates.addAll([
      Template(
        id: 't1',
        name: 'Assignment Reminder',
        body: 'This is a reminder that your assignment is due soon. Please submit it on time.',
      ),
      Template(
        id: 't2',
        name: 'Grade Update',
        body: 'Your grades have been updated. Please check the portal for details.',
      ),
      Template(
        id: 't3',
        name: 'Meeting Request',
        body: 'I would like to schedule a meeting to discuss your progress. Please let me know your availability.',
      ),
      Template(
        id: 't4',
        name: 'Absence Follow-up',
        body: 'I noticed you were absent from class. Please let me know if you need any help catching up.',
      ),
    ]);

    // Mock users
    final teacher = User(id: 'u1', name: 'Maria Santos', initials: 'MS');
    final student1 = User(id: 'u2', name: 'Juan Dela Cruz', initials: 'JD');
    final student2 = User(id: 'u3', name: 'Pedro Garcia', initials: 'PG');
    final parent1 = User(id: 'u4', name: 'Mrs. Maria Santos', initials: 'MS');
    final teacher2 = User(id: 'u5', name: 'Prof. Ana Reyes', initials: 'AR');
    final parent2 = User(id: 'u6', name: 'Mr. Jose Rizal', initials: 'JR');

    // Threads
    final now = DateTime.now();
    allThreads.addAll([
      Thread(
        id: 'th1',
        subject: 'Question about homework',
        participants: [teacher, student1],
        labels: {'l1'},
        pinned: false,
        messages: [
          Msg(
            id: 'm1',
            author: student1,
            body: 'Good afternoon Ma\'am! I have a question about the homework you gave us. Can you clarify problem #5?',
            createdAt: now.subtract(const Duration(minutes: 15)),
          ),
        ],
        unreadCount: 1,
      ),
      Thread(
        id: 'th2',
        subject: 'Meeting request - Child\'s progress',
        participants: [teacher, parent1],
        labels: {'l2', 'l4'},
        pinned: false,
        messages: [
          Msg(
            id: 'm2',
            author: parent1,
            body: 'Good day Teacher! Can we schedule a meeting to discuss my child\'s progress? I\'m concerned about their recent grades.',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        unreadCount: 1,
      ),
      Thread(
        id: 'th3',
        subject: 'Assignment feedback',
        participants: [teacher, student2],
        labels: {'l1'},
        pinned: false,
        starred: false,
        messages: [
          Msg(
            id: 'm3',
            author: teacher,
            body: 'Hi Pedro! I reviewed your assignment. Great work overall, but please review the section on quadratic equations.',
            createdAt: now.subtract(const Duration(hours: 5)),
          ),
          Msg(
            id: 'm4',
            author: student2,
            body: 'Thank you for the feedback Ma\'am! I will review that section.',
            createdAt: now.subtract(const Duration(hours: 4, minutes: 30)),
          ),
        ],
        unreadCount: 0,
      ),
      Thread(
        id: 'th4',
        subject: 'Upcoming event coordination',
        participants: [teacher, teacher2],
        labels: {'l3'},
        pinned: false,
        messages: [
          Msg(
            id: 'm5',
            author: teacher2,
            body: 'Hi Maria! Let\'s coordinate for the upcoming Science Fair. Can we meet this Friday?',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        unreadCount: 0,
      ),
      Thread(
        id: 'th5',
        subject: 'Thank you for the update',
        participants: [teacher, parent2],
        labels: {'l2'},
        pinned: false,
        archived: false,
        messages: [
          Msg(
            id: 'm6',
            author: teacher,
            body: 'Good day! Just wanted to update you that your child is doing well in class. Keep up the good work!',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          Msg(
            id: 'm7',
            author: parent2,
            body: 'Thank you so much for the update Teacher! We really appreciate it.',
            createdAt: now.subtract(const Duration(days: 1, hours: 20)),
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
        list = list.where((t) => t.sentByTeacher);
        break;
      case 'Drafts':
        list = list.where((t) => t.isDraft);
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

  void toggleLock(Thread t) {
    t.locked = !t.locked;
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
      author: User(id: 'u1', name: 'Maria Santos', initials: 'MS'),
      body: text.trim(),
      createdAt: DateTime.now(),
    );
    thread.messages.add(msg);
    composerText = '';
    notifyListeners();
  }

  void insertTemplateIntoComposer(String body) {
    if (composerText.isEmpty) {
      composerText = body;
    } else {
      composerText = '$composerText\n\n$body';
    }
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
        User(id: 'u1', name: 'Maria Santos', initials: 'MS'),
        ...recipients,
      ],
      messages: [
        Msg(
          id: UniqueKey().toString(),
          author: User(id: 'u1', name: 'Maria Santos', initials: 'MS'),
          body: body,
          createdAt: DateTime.now(),
        ),
      ],
      sentByTeacher: true,
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
  bool locked;
  bool sentByTeacher;
  bool isDraft;
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
    this.locked = false,
    this.sentByTeacher = false,
    this.isDraft = false,
    this.unreadCount = 0,
  });

  DateTime get lastMessageAt => messages.isNotEmpty
      ? messages.last.createdAt
      : DateTime.fromMillisecondsSinceEpoch(0);
}

class Template {
  final String id;
  final String name;
  final String body;
  const Template({required this.id, required this.name, required this.body});
}
