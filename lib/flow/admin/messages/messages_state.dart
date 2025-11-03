import 'package:flutter/material.dart';

/// Messaging domain models and interactive logic (no backend hookups).
/// This file contains ChangeNotifier-based state and plain models to
/// separate UI from behavior.

class MessagesState extends ChangeNotifier {
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

  // Templates (admin-managed canned messages)
  final List<Template> templates = [];

  // Data
  final List<Thread> allThreads = [];
  Thread? selectedThread;
  String search = '';
  String selectedFolder = 'All';
  Set<String> activeLabelIds = {};

  // Compose state
  String composerText = '';
  bool composerRequireAck = false;
  bool composerAnnouncement = false;

  void initMockData() {
    // Labels
    labels.addAll([
      Label(id: 'l1', name: 'Admissions', color: Colors.teal),
      Label(id: 'l2', name: 'IT Helpdesk', color: Colors.indigo),
      Label(id: 'l3', name: 'Parents', color: Colors.orange),
    ]);

    // Templates
    templates.addAll([
      Template(id: 't1', name: 'Welcome', body: 'Welcome to OSHS! Please review the onboarding guide.'),
      Template(id: 't2', name: 'Maintenance Notice', body: 'Scheduled maintenance on Friday at 9PM. Expect downtime of 30 minutes.'),
      Template(id: 't3', name: 'Policy Update', body: 'Please read the updated Acceptable Use Policy.'),
    ]);

    // Mock users
    final admin = User(id: 'u1', name: 'Admin', initials: 'AD');
    final teacher = User(id: 'u2', name: 'Ms. Cruz', initials: 'MC');
    final student = User(id: 'u3', name: 'Juan Dela Cruz', initials: 'JD');

    // Threads
    final now = DateTime.now();
    allThreads.addAll([
      Thread(
        id: 'th1',
        subject: 'Welcome to the new term',
        participants: [admin, teacher, student],
        labels: {'l1'},
        pinned: true,
        isAnnouncement: true,
        messages: [
          Msg(
            id: 'm1',
            author: admin,
            body: 'Welcome everyone! Please find the schedule attached.',
            createdAt: now.subtract(const Duration(hours: 26)),
          ),
          Msg(
            id: 'm2',
            author: teacher,
            body: 'Thanks! Looking forward to it.',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
      Thread(
        id: 'th2',
        subject: 'IT: Password reset issue',
        participants: [admin, teacher],
        labels: {'l2'},
        messages: [
          Msg(
            id: 'm3',
            author: teacher,
            body: 'I cannot reset a student\'s password, error 403.',
            createdAt: now.subtract(const Duration(hours: 5)),
          ),
          Msg(
            id: 'm4',
            author: admin,
            body: 'We\'re checking logs, please share the username via secure form.',
            createdAt: now.subtract(const Duration(hours: 4, minutes: 20)),
          ),
        ],
      ),
      Thread(
        id: 'th3',
        subject: 'Parents\' orientation',
        participants: [admin],
        labels: {'l3'},
        messages: [
          Msg(
            id: 'm5',
            author: admin,
            body: 'Orientation this Saturday 10AM at the auditorium. Please acknowledge.',
            createdAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
        requireAck: true,
      ),
    ]);

    // Default selection
    selectedThread = allThreads.first;
    notifyListeners();
  }

  List<Thread> get filteredThreads {
    Iterable<Thread> list = allThreads;
    // Folder filtering (simple mock rules)
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
        list = list.where((t) => t.sentByAdmin);
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
      list = list.where((t) => t.subject.toLowerCase().contains(q) ||
          t.messages.any((m) => m.body.toLowerCase().contains(q)));
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
      author: User(id: 'u1', name: 'Admin', initials: 'AD'),
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

  void createBroadcast({
    required String subject,
    required String body,
    required bool disableReplies,
    required bool requireAck,
    required BroadcastTargets targets,
    DateTime? scheduleAt,
  }) {
    final thread = Thread(
      id: UniqueKey().toString(),
      subject: subject.isEmpty ? 'Untitled broadcast' : subject,
      participants: [User(id: 'u1', name: 'Admin', initials: 'AD')],
      isAnnouncement: disableReplies,
      requireAck: requireAck,
      messages: [
        Msg(
          id: UniqueKey().toString(),
          author: User(id: 'u1', name: 'Admin', initials: 'AD'),
          body: body,
          createdAt: scheduleAt ?? DateTime.now(),
        ),
      ],
      sentByAdmin: true,
      labels: {'l1'},
    );
    allThreads.insert(0, thread);
    selectedThread = thread;
    notifyListeners();
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
  Msg({required this.id, required this.author, required this.body, required this.createdAt});
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
  bool isAnnouncement;
  bool requireAck;
  bool sentByAdmin;
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
    this.isAnnouncement = false,
    this.requireAck = false,
    this.sentByAdmin = false,
    this.isDraft = false,
    this.unreadCount = 0,
  });

  DateTime get lastMessageAt => messages.isNotEmpty ? messages.last.createdAt : DateTime.fromMillisecondsSinceEpoch(0);
}

class Template {
  final String id;
  final String name;
  final String body;
  const Template({required this.id, required this.name, required this.body});
}

class BroadcastTargets {
  final Set<String> roles = {};
  // Future: org units, groups, courses, sections
}

class BroadcastResult {
  final String subject;
  final String body;
  final bool disableReplies;
  final bool requireAck;
  final BroadcastTargets targets;
  final DateTime? scheduleAt;
  BroadcastResult({
    required this.subject,
    required this.body,
    required this.disableReplies,
    required this.requireAck,
    required this.targets,
    required this.scheduleAt,
  });
}
