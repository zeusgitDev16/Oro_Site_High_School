import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherAnnouncementTab extends StatefulWidget {
  final dynamic selectedClassroom;
  final dynamic selectedCourse;
  final String? teacherId;

  const TeacherAnnouncementTab({
    Key? key,
    required this.selectedClassroom,
    required this.selectedCourse,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<TeacherAnnouncementTab> createState() => _TeacherAnnouncementTabState();
}

class _TeacherAnnouncementTabState extends State<TeacherAnnouncementTab>
    with AutomaticKeepAliveClientMixin {
  final List<Map<String, dynamic>> _announcements = [];
  final Map<String, List<Map<String, dynamic>>> _announcementReplies = {};
  String? _selectedAnnouncementId;
  final TextEditingController _replyCtrl = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _isLoadingAnnouncements = false;
  StreamSubscription? _repliesStream;
  final Map<String, String> _replyAuthorNames = {};
  final Map<String, String> _lastSelectedAnnouncement = {};

  @override
  void initState() {
    super.initState();
    _loadAnnouncementsForSelectedCourse();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _replyFocus.dispose();
    _repliesStream?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildAnnouncementsTab();
  }
}
