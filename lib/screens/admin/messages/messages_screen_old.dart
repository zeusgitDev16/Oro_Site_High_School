import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/admin/messages/messages_state.dart';

/// NEO LMS-style Messages screen (3-pane layout)
/// UI-only: state and models are defined in messages_state.dart
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessagesState state;

  @override
  void initState() {
    super.initState();
    state = MessagesState()..initMockData();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'New broadcast',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => _openBroadcastDialog(context),
          ),
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => _openTemplatePicker(
              context,
              onPick: (tpl) {
                state.insertTemplateIntoComposer(tpl.body);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ChangeNotifierProvider<MessagesState>(
        notifier: state,
        child: Row(
          children: const [
            SizedBox(width: 240, child: FoldersPane()),
            VerticalDivider(width: 1),
            SizedBox(width: 340, child: ThreadListPane()),
            VerticalDivider(width: 1),
            Expanded(child: ThreadDetailPane()),
          ],
        ),
      ),
    );
  }

  void _openBroadcastDialog(BuildContext context) async {
    final result = await showDialog<BroadcastResult>(
      context: context,
      builder: (_) => BroadcastDialog(initialText: state.composerText),
    );
    if (result != null) {
      // Placeholder: create announcement/broadcast thread (no backend yet)
      state.createBroadcast(
        subject: result.subject,
        body: result.body,
        disableReplies: result.disableReplies,
        requireAck: result.requireAck,
        targets: result.targets,
        scheduleAt: result.scheduleAt,
      );
    }
  }

  void _openTemplatePicker(
    BuildContext context, {
    required void Function(Template tpl) onPick,
  }) async {
    final result = await showDialog<Template>(
      context: context,
      builder: (_) => TemplatePickerDialog(templates: state.templates),
    );
    if (result != null) onPick(result);
  }
}

// ---------------------------------------------------------------------------
// UI Panes (consume MessagesState)
// ---------------------------------------------------------------------------

class FoldersPane extends StatelessWidget {
  const FoldersPane({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<MessagesState>(context);
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: state.updateSearch,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Folders',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...state.folders.map((f) {
                  final selected = state.selectedFolder == f.name;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      f.icon,
                      size: 20,
                      color: selected ? Colors.teal : Colors.grey.shade700,
                    ),
                    title: Text(
                      f.name,
                      style: TextStyle(
                        color: selected ? Colors.teal : Colors.black87,
                      ),
                    ),
                    selected: selected,
                    onTap: () => state.selectFolder(f.name),
                  );
                }),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Labels',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...state.labels.map((l) {
                  final active = state.activeLabelIds.contains(l.id);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 6, backgroundColor: l.color),
                    title: Text(l.name),
                    trailing: active
                        ? const Icon(Icons.check, size: 18, color: Colors.teal)
                        : null,
                    onTap: () => state.toggleLabel(l.id),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThreadListPane extends StatelessWidget {
  const ThreadListPane({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<MessagesState>(context);
    final threads = state.filteredThreads;

    return Column(
      children: [
        const _FilterBar(),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = threads[index];
              final selected = state.selectedThread?.id == t.id;
              return Material(
                color: selected
                    ? Colors.teal.withOpacity(0.08)
                    : Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  title: Row(
                    children: [
                      if (t.pinned) const Icon(Icons.push_pin, size: 14),
                      if (t.pinned) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          t.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (t.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${t.unreadCount}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    t.messages.isNotEmpty
                        ? t.messages.last.body
                        : 'No messages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => state.selectThread(t),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: t.starred ? 'Unstar' : 'Star',
                        icon: Icon(
                          t.starred ? Icons.star : Icons.star_border,
                          size: 18,
                          color: Colors.amber,
                        ),
                        onPressed: () => state.toggleStar(t),
                      ),
                      IconButton(
                        tooltip: t.archived ? 'Unarchive' : 'Archive',
                        icon: Icon(
                          t.archived ? Icons.unarchive : Icons.archive_outlined,
                          size: 18,
                        ),
                        onPressed: () => state.toggleArchive(t),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ThreadDetailPane extends StatelessWidget {
  const ThreadDetailPane({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<MessagesState>(context);
    final t = state.selectedThread;
    if (t == null) {
      return const Center(child: Text('No thread selected'));
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (t.isAnnouncement)
                          const _Chip(text: 'Announcement', color: Colors.teal),
                        if (t.requireAck) const SizedBox(width: 6),
                        if (t.requireAck)
                          const _Chip(text: 'Acknowledge', color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Participants: ${t.participants.map((e) => e.name).join(', ')}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.locked ? 'Unlock thread' : 'Lock thread',
                icon: Icon(
                  t.locked ? Icons.lock : Icons.lock_open,
                  color: Colors.grey.shade700,
                ),
                onPressed: () => state.toggleLock(t),
              ),
              IconButton(
                tooltip: 'Delete thread',
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                onPressed: () => state.deleteThread(t),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: t.messages.length,
            itemBuilder: (context, i) {
              final m = t.messages[i];
              final isAdmin = m.author.initials == 'AD';
              return Align(
                alignment: isAdmin
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    color: isAdmin ? Colors.teal.shade50 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m.author.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatTime(m.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(m.body),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        const Composer(),
      ],
    );
  }
}

class Composer extends StatelessWidget {
  const Composer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<MessagesState>(context);
    final controller = TextEditingController(text: state.composerText);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Insert template',
                icon: const Icon(Icons.article_outlined),
                onPressed: () async {
                  final tpl = await showDialog<Template>(
                    context: context,
                    builder: (_) =>
                        TemplatePickerDialog(templates: state.templates),
                  );
                  if (tpl != null) state.insertTemplateIntoComposer(tpl.body);
                },
              ),
              IconButton(
                tooltip: 'Attach file',
                icon: const Icon(Icons.attach_file),
                onPressed: () {},
              ),
              IconButton(
                tooltip: 'Emoji',
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () {},
              ),
              const Spacer(),
              Row(
                children: [
                  const Text('Announcement'),
                  Switch(
                    value: state.composerAnnouncement,
                    onChanged: (v) {
                      state.composerAnnouncement = v;
                      state.notifyListeners();
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Text('Require ack'),
                  Switch(
                    value: state.composerRequireAck,
                    onChanged: (v) {
                      state.composerRequireAck = v;
                      state.notifyListeners();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (v) => state.composerText = v,
                  decoration: InputDecoration(
                    hintText: 'Write a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => state.sendMessage(controller.text),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();
  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<MessagesState>(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 20),
          const SizedBox(width: 6),
          Text(
            'Folder: ${state.selectedFolder}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '${state.filteredThreads.length} threads',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.darken(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Broadcast dialog & Template picker (UI only)
// ---------------------------------------------------------------------------

class BroadcastDialog extends StatefulWidget {
  final String initialText;
  const BroadcastDialog({super.key, required this.initialText});
  @override
  State<BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<BroadcastDialog> {
  final _subjectCtrl = TextEditingController();
  late TextEditingController _bodyCtrl;
  bool _disableReplies = true;
  bool _requireAck = false;
  DateTime? _scheduleAt;
  final _targets = BroadcastTargets();

  @override
  void initState() {
    super.initState();
    _bodyCtrl = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Broadcast message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _roleChip('Administrators'),
                    _roleChip('Teachers'),
                    _roleChip('Students'),
                    _roleChip('Parents'),
                    _roleChip('Managers'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyCtrl,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Message body',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _disableReplies,
                      onChanged: (v) =>
                          setState(() => _disableReplies = v ?? false),
                    ),
                    const Text('Disable replies (announcement)'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _requireAck,
                      onChanged: (v) =>
                          setState(() => _requireAck = v ?? false),
                    ),
                    const Text('Require acknowledge'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _scheduleAt == null
                          ? 'Send now'
                          : 'Scheduled: ${_scheduleAt!.toLocal()}',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        // Simple schedule picker: +1 hour
                        setState(
                          () => _scheduleAt = now.add(const Duration(hours: 1)),
                        );
                      },
                      child: const Text('Schedule +1h'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _scheduleAt = null),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          BroadcastResult(
                            subject: _subjectCtrl.text,
                            body: _bodyCtrl.text,
                            disableReplies: _disableReplies,
                            requireAck: _requireAck,
                            targets: _targets,
                            scheduleAt: _scheduleAt,
                          ),
                        );
                      },
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Send broadcast'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    final selected = _targets.roles.contains(role);
    return FilterChip(
      label: Text(role),
      selected: selected,
      onSelected: (v) => setState(() {
        if (v) {
          _targets.roles.add(role);
        } else {
          _targets.roles.remove(role);
        }
      }),
    );
  }
}

class TemplatePickerDialog extends StatelessWidget {
  final List<Template> templates;
  const TemplatePickerDialog({super.key, required this.templates});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Templates',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = templates[i];
                    return ListTile(
                      title: Text(
                        t.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        t.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal ChangeNotifier provider without external packages
// ---------------------------------------------------------------------------

typedef _Listener = void Function();

class ChangeNotifierProvider<T extends ChangeNotifier> extends InheritedWidget {
  final T notifier;
  const ChangeNotifierProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ChangeNotifierProvider<T>>();
    assert(provider != null, 'No ChangeNotifierProvider<$T> found in context');
    return provider!.notifier;
  }

  @override
  bool updateShouldNotify(ChangeNotifierProvider<T> oldWidget) =>
      notifier != oldWidget.notifier;
}

extension _ColorExt on Color {
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  if (now.difference(dt).inDays >= 1) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
