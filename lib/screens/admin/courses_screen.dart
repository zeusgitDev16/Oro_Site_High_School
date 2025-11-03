import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/course.dart';
import 'package:oro_site_high_school/models/course_file.dart';
import 'package:oro_site_high_school/services/course_service.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/services/file_upload_service.dart';
import 'package:oro_site_high_school/services/profile_service.dart';
import 'package:oro_site_high_school/models/profile.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simplified Course Management Screen
/// Based on the new UI design with sidebar, tabs, and resource management
/// Layer 1: UI Layer - Presentation only
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  final TeacherService _teacherService = TeacherService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ProfileService _profileService = ProfileService();
  
  List<Course> _courses = [];
  String? _selectedCourseId;
  bool _isLoading = true;
  
  // Teacher data
  Map<String, List<String>> _courseTeachers = {}; // courseId -> List of teacherIds
  Map<String, String> _teacherNames = {}; // teacherId -> teacher name
  bool _isLoadingTeachers = false;
  // Avatar cache for teachers (profile avatar_url)
  final Map<String, String?> _teacherAvatars = {};
  // Selected assigned teacher per course (for display in pill)
  final Map<String, String?> _selectedCourseTeacherId = {};
  
  // File data
  Map<String, List<CourseFile>> _courseFiles = {}; // courseId -> List of files
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  /// Load courses from database
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _courseService.fetchCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
        // Auto-select first course if available
        if (_courses.isNotEmpty && _selectedCourseId == null) {
          _selectedCourseId = _courses.first.id;
        }
      });
      
      // Load teachers for all courses
      await _loadAllTeachers();
      
      // Load files for all courses
      await _loadAllFiles();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load all teachers and course-teacher assignments
  Future<void> _loadAllTeachers() async {
    try {
      // Load all active teachers
      final teachers = await _teacherService.getActiveTeachers();
      
      // Build teacher name map
      final nameMap = <String, String>{};
      for (var teacher in teachers) {
        nameMap[teacher.id] = teacher.displayName;
      }
      
      // Load teachers for each course
      final courseTeacherMap = <String, List<String>>{};
      for (var course in _courses) {
        final teacherIds = await _courseService.getCourseTeachers(course.id);
        courseTeacherMap[course.id] = teacherIds;
      }
      
      setState(() {
        _teacherNames = nameMap;
        _courseTeachers = courseTeacherMap;
      });

      // Prefetch avatars for all assigned teachers across courses
      final ids = <String>{};
      for (final list in courseTeacherMap.values) {
        ids.addAll(list);
      }
      if (ids.isNotEmpty) {
        await _prefetchTeacherAvatars(ids);
      }
    } catch (e) {
      print('⚠️ Error loading teachers: $e');
    }
  }

  Future<void> _prefetchTeacherAvatars(Set<String> teacherIds) async {
    for (final id in teacherIds) {
      if (_teacherAvatars.containsKey(id)) continue;
      try {
        final profile = await _profileService.getProfile(id);
        if (profile != null) {
          setState(() {
            // Use profile full name if teacher name is missing
            _teacherNames[id] = _teacherNames[id] ?? profile.fullName ?? 'Unknown Teacher';
            _teacherAvatars[id] = profile.avatarUrl;
          });
        }
      } catch (e) {
        // Ignore failures; fallback to initials avatar
      }
    }
  }

  /// Load all files for courses
  Future<void> _loadAllFiles() async {
    try {
      final fileMap = <String, List<CourseFile>>{};
      
      for (var course in _courses) {
        final files = await _fileUploadService.getCourseFiles(
          courseId: course.id,
        );
        fileMap[course.id] = files;
      }
      
      setState(() {
        _courseFiles = fileMap;
      });
    } catch (e) {
      print('⚠️ Error loading files: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar - Course List
          _buildLeftSidebar(),
          
          // Main Content Area
          Expanded(
            child: _selectedCourseId != null
                ? _buildCourseContent()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'COURSE MANAGEMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Create Course Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCreateCourseDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('create course'),
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Course List
          Expanded(
            child: _courses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No courses yet.\nClick "create course" to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final isSelected = _selectedCourseId == course.id;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => _confirmDeleteCourse(course),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCourseId = course.id;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent() {
    final course = _courses.firstWhere((c) => c.id == _selectedCourseId);
    
    return Column(
      children: [
        // Course Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Teachers Dropdown
              _buildTeachersDropdown(course.id),
            ],
          ),
        ),
        
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'module resource'),
              Tab(text: 'assignment resource'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResourceTab('module'),
              _buildResourceTab('assignment'),
            ],
          ),
        ),
        
        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddTeachersDialog,
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('add teachers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showUploadFilesDialog,
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text('upload files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceTab(String type) {
    if (_selectedCourseId == null) {
      return const Center(child: Text('No course selected'));
    }

    final allFiles = _courseFiles[_selectedCourseId] ?? [];
    final files = allFiles.where((f) => f.fileType == type).toList();

    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No files uploaded yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click "upload files" to add $type resources',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                file.fileIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${file.fileSizeFormatted} • ${file.uploadedAt.toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  onPressed: () => _downloadFile(file),
                  tooltip: 'Download',
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _viewFile(file),
                  tooltip: 'View',
                  color: Colors.green,
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.red.shade400),
                  onPressed: () => _confirmDeleteFile(file),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No course selected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a course or select one from the sidebar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCourseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isCreating = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Course'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    hintText: 'e.g., Mathematics 7',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isCreating,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of the course',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isCreating,
                ),
                if (isCreating) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a course title'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      try {
                        await _courseService.createCourse(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                        );

                        Navigator.pop(context);
                        
                        // Reload courses
                        await _loadCourses();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Course created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isCreating = false;
                        });
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating course: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCourse(course.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await _courseService.deleteCourse(courseId);
      
      // Reload courses
      await _loadCourses();
      
      // Clear selection if deleted course was selected
      if (_selectedCourseId == courseId) {
        setState(() {
          _selectedCourseId = _courses.isNotEmpty ? _courses.first.id : null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeachersDropdown(String courseId) {
    final assignedTeacherIds = _courseTeachers[courseId] ?? [];

    Widget emptyPill(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        );

    if (assignedTeacherIds.isEmpty) {
      return emptyPill('No teachers assigned');
    }

    // Prefetch avatars for assigned teachers (deferred and guarded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _prefetchTeacherAvatars(assignedTeacherIds.toSet());
      } catch (_) {}
    });

    // Determine selected teacher for this course
    final selectedId = _selectedCourseTeacherId[courseId] ?? assignedTeacherIds.first;
    final selectedName = _teacherNames[selectedId] ?? 'Unknown Teacher';
    final avatarUrl = _teacherAvatars[selectedId];
    String initials = '';
    if (selectedName.isNotEmpty) {
      final parts = selectedName.split(' ');
      if (parts.isNotEmpty) initials += parts.first.isNotEmpty ? parts.first[0] : '';
      if (parts.length > 1) initials += parts.last.isNotEmpty ? parts.last[0] : '';
    }

    return InkWell(
      onTap: () => _showAssignedTeachersPicker(courseId),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Colors.blueGrey.shade100,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(initials.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              selectedName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '${assignedTeacherIds.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignedTeachersPicker(String courseId) async {
    final assignedTeacherIds = List<String>.from(_courseTeachers[courseId] ?? []);
    String localQuery = '';
    final controller = TextEditingController();
    final scrollCtrl = ScrollController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          List<String> filtered = assignedTeacherIds.where((id) {
            final name = _teacherNames[id] ?? '';
            if (localQuery.isEmpty) return true;
            return name.toLowerCase().contains(localQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 360,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: controller,
                      onChanged: (v) => setLocalState(() => localQuery = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search assigned teachers',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        suffixIcon: localQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  controller.clear();
                                  setLocalState(() => localQuery = '');
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No results', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : Scrollbar(
                      controller: scrollCtrl,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: scrollCtrl,
                        shrinkWrap: true,
                        primary: false,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final id = filtered[i];
                          final name = _teacherNames[id] ?? 'Unknown Teacher';
                          final avatarUrl = _teacherAvatars[id];
                          String initials = '';
                          if (name.isNotEmpty) {
                            final parts = name.split(' ');
                            if (parts.isNotEmpty) initials += parts.first.isNotEmpty ? parts.first[0] : '';
                            if (parts.length > 1) initials += parts.last.isNotEmpty ? parts.last[0] : '';
                          }
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.blueGrey.shade100,
                              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Text(initials.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))
                                  : null,
                            ),
                            title: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red.shade400),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await _removeTeacher(courseId, id);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCourseTeacherId[courseId] = id;
                              });
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTeachersDialog() {
    if (_selectedCourseId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _AddTeacherDialog(
        courseId: _selectedCourseId!,
        courseService: _courseService,
        teacherService: _teacherService,
        assignedTeacherIds: _courseTeachers[_selectedCourseId!] ?? [],
        onTeacherAdded: () {
          _loadAllTeachers();
        },
      ),
    );
  }

  Future<void> _removeTeacher(String courseId, String teacherId) async {
    try {
      await _courseService.removeTeacherFromCourse(
        courseId: courseId,
        teacherId: teacherId,
      );
      
      await _loadAllTeachers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUploadFilesDialog() async {
    if (_selectedCourseId == null) return;
    
    final currentTab = _tabController.index == 0 ? 'module' : 'assignment';
    
    try {
      // Pick files
      final files = await _fileUploadService.pickFiles(allowMultiple: true);
      
      if (files == null || files.isEmpty) {
        return;
      }

      // Show upload progress dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _UploadProgressDialog(
          files: files,
          courseId: _selectedCourseId!,
          fileType: currentTab,
          fileUploadService: _fileUploadService,
          onComplete: () {
            _loadAllFiles();
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(CourseFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${file.fileName}...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch ${file.fileUrl}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewFile(CourseFile file) async {
    try {
      final uri = Uri.parse(file.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not open ${file.fileUrl}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteFile(CourseFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFile(file);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(CourseFile file) async {
    try {
      await _fileUploadService.deleteFile(
        fileId: file.id,
        fileUrl: file.fileUrl,
        fileType: file.fileType,
      );
      
      await _loadAllFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Upload Progress Dialog
class _UploadProgressDialog extends StatefulWidget {
  final List files;
  final String courseId;
  final String fileType;
  final FileUploadService fileUploadService;
  final VoidCallback onComplete;

  const _UploadProgressDialog({
    required this.files,
    required this.courseId,
    required this.fileType,
    required this.fileUploadService,
    required this.onComplete,
  });

  @override
  State<_UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<_UploadProgressDialog> {
  int _uploadedCount = 0;
  int _totalCount = 0;
  String _currentFileName = '';
  bool _isComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _totalCount = widget.files.length;
    _uploadFiles();
  }

  Future<void> _uploadFiles() async {
    try {
      for (var file in widget.files) {
        setState(() {
          _currentFileName = file.name;
        });

        await widget.fileUploadService.uploadFile(
          file: file,
          courseId: widget.courseId,
          fileType: widget.fileType,
          uploadedBy: 'admin-1', // TODO: Get actual user ID
        );

        setState(() {
          _uploadedCount++;
        });
      }

      setState(() {
        _isComplete = true;
      });

      widget.onComplete();

      // Auto-close after 1 second
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isComplete ? 'Upload Complete!' : 'Uploading Files...'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isComplete && _error == null) ...[
              LinearProgressIndicator(
                value: _uploadedCount / _totalCount,
              ),
              const SizedBox(height: 16),
              Text(
                'Uploading $_uploadedCount of $_totalCount files',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _currentFileName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_isComplete) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Successfully uploaded $_uploadedCount file(s)!',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (_error != null) ...[
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_error != null || _isComplete)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}

/// Add Teacher Dialog
class _AddTeacherDialog extends StatefulWidget {
  final String courseId;
  final CourseService courseService;
  final TeacherService teacherService;
  final List<String> assignedTeacherIds;
  final VoidCallback onTeacherAdded;

  const _AddTeacherDialog({
    required this.courseId,
    required this.courseService,
    required this.teacherService,
    required this.assignedTeacherIds,
    required this.onTeacherAdded,
  });

  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  List<dynamic> _availableTeachers = [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _selectedTeacherId;

  // New UI state
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _selectedNormal = {};
  final Set<String> _selectedGLC = {};
  final Set<String> _glcRoleIds = {}; // profiles with role grade_coordinator
  final ScrollController _normalScrollCtrl = ScrollController();
  final ScrollController _glcScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _query = _searchCtrl.text.trim();
      _performSearch();
    });
    _loadTeachers();
    _loadGlcRoleIds();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _normalScrollCtrl.dispose();
    _glcScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await widget.teacherService.getActiveTeachers();
      
      // Filter out already assigned teachers
      final available = teachers.where((teacher) {
        return !widget.assignedTeacherIds.contains(teacher.id);
      }).toList();
      
      setState(() {
        _availableTeachers = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch() async {
    try {
      if (_query.isEmpty) {
        // reload full list
        await _loadTeachers();
        return;
      }
      // Server-side search
      final results = await widget.teacherService.searchTeachers(_query);
      // Filter out already assigned
      final filtered = results.where((t) => !widget.assignedTeacherIds.contains(t.id)).toList();
      setState(() {
        _availableTeachers = filtered;
      });
    } catch (e) {
      // keep previous list on error
    }
  }

  Future<void> _loadGlcRoleIds() async {
    try {
      // Fetch all profiles with role grade_coordinator; keep to a reasonable limit
      final profiles = await ProfileService().getAllUsers(
        roleFilter: 'grade_coordinator',
        limit: 1000,
        page: 1,
      );
      setState(() {
        _glcRoleIds
          ..clear()
          ..addAll(profiles.map((p) => p.id));
      });
    } catch (e) {
      // Non-fatal; fallback to teacher flag only
    }
  }

  @override
  Widget build(BuildContext context) {
    // Partition into normal and GLC, then apply search filter (UI-only)
    bool matches(dynamic t) {
      final name = (t.displayName ?? t.fullName ?? '').toString();
      final email = (t.email ?? '').toString();
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return name.toLowerCase().contains(q) || email.toLowerCase().contains(q);
    }

    final base = _availableTeachers;
    bool isGlc(dynamic t) {
      final id = (t.id).toString();
      final flag = (t.isGradeCoordinator == true);
      final byRole = _glcRoleIds.contains(id);
      return flag || byRole;
    }
    final normal = base.where((t) => !isGlc(t)).where(matches).toList();
    final glc = base.where((t) => isGlc(t)).where(matches).toList();

    Widget listTile(dynamic t, int index, bool isGLC) {
      final id = (t.id).toString();
      final name = (t.displayName ?? t.fullName ?? '').toString();
      final email = (t.email ?? '').toString();
      final selected = isGLC ? _selectedGLC.contains(id) : _selectedNormal.contains(id);

      void toggle() {
        setState(() {
          if (isGLC) {
            if (selected) {
              _selectedGLC.remove(id);
            } else {
              _selectedGLC.add(id);
            }
          } else {
            if (selected) {
              _selectedNormal.remove(id);
            } else {
              _selectedNormal.add(id);
            }
          }
        });
      }

      return InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 24, child: Text('${index + 1}.')),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '$name:  $email',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: selected,
                onChanged: (v) => toggle(),
              ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Add Teachers:'),
      content: SizedBox(
        width: 1000,
        child: _isLoading
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  // Two-pane layout
                  SizedBox(
                    height: 420,
                    child: Row(
                      children: [
                        // Left: Normal teachers
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('teachers:', style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                                  Row(children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          final allIds = normal.map((t) => (t as dynamic).id.toString()).toList();
                                          if (_selectedNormal.length == allIds.length) {
                                            _selectedNormal.clear();
                                          } else {
                                            _selectedNormal
                                              ..clear()
                                              ..addAll(allIds);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.done_all, size: 14, color: Colors.green.shade700),
                                            const SizedBox(width: 6),
                                            const Text('select all', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                            if (_selectedNormal.length > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${_selectedNormal.length}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: normal.isEmpty
                                    ? Center(child: Text('No results', style: TextStyle(color: Colors.grey.shade600)))
                                    : Scrollbar(
                                        controller: _normalScrollCtrl,
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          controller: _normalScrollCtrl,
                                          itemCount: normal.length,
                                          itemBuilder: (ctx, i) => listTile(normal[i], i, false),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            height: double.infinity,
                            child: VerticalDivider(color: Colors.grey.shade300),
                          ),
                        ),
                        // Right: GLC teachers
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('GLC teachers:', style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                                  Row(children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          final allIds = glc.map((t) => (t as dynamic).id.toString()).toList();
                                          if (_selectedGLC.length == allIds.length) {
                                            _selectedGLC.clear();
                                          } else {
                                            _selectedGLC
                                              ..clear()
                                              ..addAll(allIds);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.done_all, size: 14, color: Colors.green.shade700),
                                            const SizedBox(width: 6),
                                            const Text('select all', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                            if (_selectedGLC.length > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade100,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${_selectedGLC.length}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: glc.isEmpty
                                    ? Center(child: Text('No results', style: TextStyle(color: Colors.grey.shade600)))
                                    : Scrollbar(
                                        controller: _glcScrollCtrl,
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          controller: _glcScrollCtrl,
                                          itemCount: glc.length,
                                          itemBuilder: (ctx, i) => listTile(glc[i], i, true),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedNormal.isEmpty && _selectedGLC.isEmpty) || _isAdding
              ? null
              : () async {
                  setState(() { _isAdding = true; });
                  try {
                    final ids = <String>{}..addAll(_selectedNormal)..addAll(_selectedGLC);
                    for (final id in ids) {
                      await widget.courseService.addTeacherToCourse(
                        courseId: widget.courseId,
                        teacherId: id,
                      );
                    }
                    if (mounted) {
                      widget.onTeacherAdded();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teacher(s) added successfully'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    setState(() { _isAdding = false; });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding teachers: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
          child: _isAdding
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add selected'),
        ),
      ],
    );
  }

  Future<void> _addTeacher() async {
    if (_selectedTeacherId == null) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await widget.courseService.addTeacherToCourse(
        courseId: widget.courseId,
        teacherId: _selectedTeacherId!,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTeacherAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAdding = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
