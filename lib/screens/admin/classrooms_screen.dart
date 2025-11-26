import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oro_site_high_school/screens/admin/admin_dashboard_screen.dart';
import 'package:oro_site_high_school/services/teacher_service.dart';
import 'package:oro_site_high_school/services/grade_coordinator_service.dart';
import 'package:oro_site_high_school/services/classroom_service.dart';
import 'package:oro_site_high_school/services/classroom_subject_service.dart';
import 'package:oro_site_high_school/services/school_year_service.dart';
import 'package:oro_site_high_school/services/subject_resource_service.dart';
import 'package:oro_site_high_school/services/temporary_resource_storage.dart';
import 'package:oro_site_high_school/models/teacher.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/models/classroom_subject.dart';
import 'package:oro_site_high_school/models/school_year_simple.dart';
import 'package:oro_site_high_school/models/subject_resource.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_editor_widget.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_settings_sidebar.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_left_sidebar_stateful.dart';
import 'package:oro_site_high_school/widgets/classroom/classroom_main_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _teacherSearchController =
      TextEditingController();
  final TeacherService _teacherService = TeacherService();
  final GradeCoordinatorService _coordinatorService = GradeCoordinatorService();
  final ClassroomService _classroomService = ClassroomService();
  final SchoolYearService _schoolYearService = SchoolYearService();
  final _supabase = Supabase.instance.client;
  String _selectedSchoolLevel = 'Junior High School';
  int? _selectedQuarter;
  int? _selectedSemester;
  int? _selectedGradeLevel; // Already defaults to null (None)
  String?
  _selectedAcademicTrack; // Academic track for SHS (ABM, STEM, HUMSS, GAS)
  int _maxStudents = 35; // Default student limit
  String? _selectedSchoolYear; // Selected school year (persisted)
  final TextEditingController _schoolYearSearchController =
      TextEditingController();
  String _schoolYearSearchQuery = ''; // Search query for filtering years
  List<SchoolYearSimple> _schoolYears = []; // Store school years from database
  bool _isLoadingSchoolYears = false;
  static const String _schoolYearPreferenceKey =
      'selected_school_year'; // Key for SharedPreferences
  List<Teacher> _teachers = [];
  List<Teacher> _gradeCoordinatorTeachers = [];
  Teacher? _selectedAdvisoryTeacher;
  bool _isLoadingTeachers = false;
  bool _isLoadingGradeCoordinators = false;

  // Advisory teacher menu overlay state
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  String _teacherSearchQuery = '';

  // Classroom management
  List<Classroom> _allClassrooms = [];
  Classroom? _selectedClassroom;
  bool _isLoadingClassrooms = false;

  // Mode management: 'create' or 'edit'
  String _currentMode = 'create'; // Default to create mode
  bool _isSavingClassroom = false;

  // Grade level expansion state
  final Map<int, bool> _expandedGrades = {
    7: false,
    8: false,
    9: false,
    10: false,
    11: false,
    12: false,
  };

  // Grade level coordinators
  final Map<int, Teacher?> _gradeCoordinators = {
    7: null,
    8: null,
    9: null,
    10: null,
    11: null,
    12: null,
  };

  // Grade coordinator menu state
  final Map<int, GlobalKey> _gradeButtonKeys = {
    7: GlobalKey(),
    8: GlobalKey(),
    9: GlobalKey(),
    10: GlobalKey(),
    11: GlobalKey(),
    12: GlobalKey(),
  };
  final Map<int, LayerLink> _gradeLayerLinks = {
    7: LayerLink(),
    8: LayerLink(),
    9: LayerLink(),
    10: LayerLink(),
    11: LayerLink(),
    12: LayerLink(),
  };
  OverlayEntry? _gradeCoordinatorOverlay;
  int? _openGradeMenu;
  final TextEditingController _gradeCoordinatorSearchController =
      TextEditingController();
  String _gradeCoordinatorSearchQuery = '';

  // School year menu state
  OverlayEntry? _schoolYearOverlay;
  final GlobalKey _schoolYearButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeData(); // Initialize all data in correct order

    // Listen to title changes and save draft
    _titleController.addListener(() {
      _saveDraftClassroom();
    });
  }

  /// Initialize all data in the correct order
  Future<void> _initializeData() async {
    // Load teachers first (needed for draft restoration)
    await _loadTeachers();

    // Then load other data
    await _initializeCoordinators();
    await _loadAllClassrooms();
    await _loadSchoolYears();

    // Finally, load draft after teachers are loaded
    await _loadDraftClassroom();
  }

  /// Initialize coordinators - load teachers first, then assignments
  Future<void> _initializeCoordinators() async {
    print('🔄 Starting coordinator initialization...');

    // First, load grade coordinator teachers
    await _loadGradeCoordinators();
    print(
      '✅ Grade coordinator teachers loaded: ${_gradeCoordinatorTeachers.length}',
    );

    // Then, load existing assignments (depends on teachers being loaded)
    await _loadExistingCoordinatorAssignments();
    print('✅ Coordinator initialization complete');
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });
    try {
      final teachers = await _teacherService.getActiveTeachers();
      setState(() {
        _teachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      print('Error loading teachers: $e');
      setState(() {
        _isLoadingTeachers = false;
      });
    }
  }

  /// Load all classrooms from database
  Future<void> _loadAllClassrooms() async {
    setState(() {
      _isLoadingClassrooms = true;
    });
    try {
      print('📚 Loading all classrooms...');
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('is_active', true)
          .order('grade_level')
          .order('title');

      final classrooms = (response as List)
          .map((json) => Classroom.fromJson(json))
          .toList();

      setState(() {
        _allClassrooms = classrooms;
        _isLoadingClassrooms = false;
      });
      print('✅ Loaded ${classrooms.length} classrooms');
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _isLoadingClassrooms = false;
      });
    }
  }

  Future<void> _loadGradeCoordinators() async {
    setState(() {
      _isLoadingGradeCoordinators = true;
    });
    try {
      final coordinators = await _teacherService.getGradeCoordinators();
      setState(() {
        _gradeCoordinatorTeachers = coordinators;
        _isLoadingGradeCoordinators = false;
      });
    } catch (e) {
      print('Error loading grade coordinators: $e');
      setState(() {
        _isLoadingGradeCoordinators = false;
      });
    }
  }

  /// Refresh the selected classroom to get updated data
  Future<void> _refreshSelectedClassroom() async {
    if (_selectedClassroom == null) return;

    try {
      print('🔄 Refreshing classroom: ${_selectedClassroom!.id}');
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('id', _selectedClassroom!.id)
          .single();

      final updatedClassroom = Classroom.fromJson(response);

      setState(() {
        _selectedClassroom = updatedClassroom;
        // Update in the list as well
        final index = _allClassrooms.indexWhere(
          (c) => c.id == updatedClassroom.id,
        );
        if (index != -1) {
          _allClassrooms[index] = updatedClassroom;
        }
      });

      print('✅ Classroom refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing classroom: $e');
    }
  }

  /// Load existing coordinator assignments from database
  Future<void> _loadExistingCoordinatorAssignments() async {
    print('📥 Loading existing coordinator assignments from database...');
    try {
      final assignments = await _coordinatorService
          .getAllActiveCoordinatorAssignments();

      print('📊 Retrieved ${assignments.length} assignments from database');

      // Debug: Print all assignments
      for (final entry in assignments.entries) {
        print(
          '   Grade ${entry.key}: ${entry.value.teacherName} (ID: ${entry.value.teacherId})',
        );
      }

      setState(() {
        // Map assignments to teachers
        for (final entry in assignments.entries) {
          final gradeLevel = entry.key;
          final assignment = entry.value;

          print(
            '🔍 Looking for teacher ID ${assignment.teacherId} in loaded list of ${_gradeCoordinatorTeachers.length} teachers',
          );

          // Find the teacher in our loaded list
          final teacher = _gradeCoordinatorTeachers.firstWhere(
            (t) => t.id == assignment.teacherId,
            orElse: () {
              print(
                '⚠️ Teacher ${assignment.teacherId} not found in loaded list, creating placeholder',
              );
              return Teacher(
                id: assignment.teacherId,
                employeeId: '',
                firstName: assignment.teacherName.split(' ').first,
                lastName: assignment.teacherName.split(' ').last,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            },
          );

          print('✅ Assigned Grade $gradeLevel to ${teacher.displayName}');
          _gradeCoordinators[gradeLevel] = teacher;
        }
      });

      print(
        '✅ Successfully loaded ${assignments.length} coordinator assignments',
      );
      print(
        '📋 Current _gradeCoordinators map: ${_gradeCoordinators.keys.toList()}',
      );
    } catch (e) {
      print('❌ Error loading coordinator assignments: $e');
    }
  }

  @override
  void dispose() {
    // Clean up overlays without calling setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    _gradeCoordinatorOverlay?.remove();
    _gradeCoordinatorOverlay = null;
    _schoolYearOverlay?.remove();
    _schoolYearOverlay = null;

    // Dispose controllers
    _titleController.dispose();
    _teacherSearchController.dispose();
    _gradeCoordinatorSearchController.dispose();
    super.dispose();
  }

  /// Toggle the advisory teacher menu
  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  /// Open the advisory teacher menu overlay
  void _openMenu() {
    if (_isMenuOpen) return;

    setState(() {
      _isMenuOpen = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Close the advisory teacher menu overlay
  void _closeMenu() {
    if (!_isMenuOpen) return;

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isMenuOpen = false;
        _teacherSearchQuery = '';
        _teacherSearchController.clear();
      });
    }
  }

  /// Create the overlay entry for the advisory teacher menu
  OverlayEntry _createOverlayEntry() {
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Stack(
          children: [
            // Positioned overlay menu
            Positioned(
              width: 200,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(6),
                  child: _buildMenuContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the menu content with search and teacher list
  Widget _buildMenuContent() {
    // Filter teachers based on search query (real-time)
    final filteredTeachers = _teachers.where((teacher) {
      if (_teacherSearchQuery.isEmpty) return true;
      return teacher.displayName.toLowerCase().contains(
        _teacherSearchQuery.toLowerCase(),
      );
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: TextField(
              controller: _teacherSearchController,
              autofocus: true,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                // Real-time search - rebuild overlay with filtered results
                setState(() {
                  _teacherSearchQuery = value;
                });
                // Rebuild the overlay to show filtered results
                if (_isMenuOpen) {
                  _overlayEntry?.markNeedsBuild();
                }
              },
            ),
          ),
          const Divider(height: 1),
          // Teacher list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 2),
              children: [
                // "None" option
                _buildTeacherMenuItem(null, 'None'),
                // Teacher options
                ...filteredTeachers.map((teacher) {
                  return _buildTeacherMenuItem(teacher, teacher.displayName);
                }),
                // No results message
                if (filteredTeachers.isEmpty && _teacherSearchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No teachers found',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single teacher menu item
  Widget _buildTeacherMenuItem(Teacher? teacher, String displayName) {
    final isSelected = teacher?.id == _selectedAdvisoryTeacher?.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAdvisoryTeacher = teacher;
        });
        _saveDraftClassroom(); // Save draft when advisory teacher changes
        _closeMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 14, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  // Grade coordinator menu methods
  void _openGradeCoordinatorMenu(int grade) {
    _gradeCoordinatorSearchController.clear();
    _gradeCoordinatorSearchQuery = '';

    final RenderBox? renderBox =
        _gradeButtonKeys[grade]?.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _gradeCoordinatorOverlay = OverlayEntry(
      builder: (context) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _closeGradeCoordinatorMenu();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _closeGradeCoordinatorMenu();
          },
          child: Stack(
            children: [
              // Transparent background to detect outside clicks
              Positioned.fill(child: Container(color: Colors.transparent)),
              // The actual menu
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 4,
                width: 300,
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when clicking inside the menu
                  },
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: _buildGradeCoordinatorMenuContent(grade),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_gradeCoordinatorOverlay!);
    setState(() {
      _openGradeMenu = grade;
    });
  }

  void _closeGradeCoordinatorMenu() {
    _gradeCoordinatorOverlay?.remove();
    _gradeCoordinatorOverlay = null;
    if (mounted) {
      setState(() {
        _openGradeMenu = null;
      });
    }
  }

  // School year menu methods
  void _openSchoolYearMenu() {
    _schoolYearSearchController.clear();
    setState(() {
      _schoolYearSearchQuery = '';
    });

    final RenderBox? renderBox =
        _schoolYearButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _schoolYearOverlay = OverlayEntry(
      builder: (context) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _closeSchoolYearMenu();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _closeSchoolYearMenu();
          },
          child: Stack(
            children: [
              // Transparent background to detect outside clicks
              Positioned.fill(child: Container(color: Colors.transparent)),
              // The actual menu
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 4,
                width: size.width,
                child: GestureDetector(
                  onTap: () {
                    // Prevent closing when clicking inside the menu
                  },
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: _buildSchoolYearMenuContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_schoolYearOverlay!);
  }

  void _closeSchoolYearMenu() {
    _schoolYearOverlay?.remove();
    _schoolYearOverlay = null;
  }

  Widget _buildSchoolYearMenuContent() {
    return StatefulBuilder(
      builder: (context, setMenuState) {
        // Filter school years from database based on search query
        final filteredYears = _schoolYears.where((year) {
          final query = _schoolYearSearchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;

          // Match against the year label (e.g., "2023-2024")
          return year.yearLabel.toLowerCase().contains(query);
        }).toList();

        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select School Year',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      onPressed: _closeSchoolYearMenu,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Search field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _schoolYearSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search year...',
                    hintStyle: TextStyle(
                      fontSize: 9,
                      color: Colors.purple.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 14,
                      color: Colors.purple.shade400,
                    ),
                    suffixIcon: _schoolYearSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 14,
                              color: Colors.purple.shade400,
                            ),
                            onPressed: () {
                              _schoolYearSearchController.clear();
                              setMenuState(() {
                                _schoolYearSearchQuery = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade500),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 10),
                  onChanged: (value) {
                    setMenuState(() {
                      _schoolYearSearchQuery = value;
                    });
                  },
                ),
              ),
              const Divider(height: 1),

              // School year list
              if (filteredYears.isEmpty &&
                  _schoolYearSearchQuery.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'School year not found',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_schoolYears.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No school years available',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a school year to get started',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredYears.length,
                    itemBuilder: (context, index) {
                      final year = filteredYears[index];
                      final isSelected = _selectedSchoolYear == year.yearLabel;

                      return InkWell(
                        onTap: () async {
                          // If clicking the already selected year, do nothing
                          if (isSelected) {
                            _closeSchoolYearMenu();
                            return;
                          }

                          // Close the menu first
                          _closeSchoolYearMenu();

                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 20,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Change School Year?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              content: SizedBox(
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You are about to change the school year to:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.purple.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.purple.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            year.yearLabel,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.purple.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'This will affect grade levels and all related data. Make sure this is the correct school year.',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange.shade900,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                // Cancel button
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                // Confirm button
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade500,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Yes, Change School Year',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          // If user confirmed, proceed with the change
                          if (confirmed == true) {
                            setState(() {
                              _selectedSchoolYear = year.yearLabel;
                            });

                            // Save preference
                            await _saveSchoolYearPreference(year.yearLabel);

                            // Reload classrooms for the new year
                            await _loadClassroomsForSelectedYear();

                            // Show confirmation
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '📅 School year changed to ${year.yearLabel}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.green.shade500,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.shade50
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.purple.shade700,
                                ),
                              if (isSelected) const SizedBox(width: 8),
                              Text(
                                year.yearLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.purple.shade900
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeCoordinatorMenuContent(int grade) {
    return StatefulBuilder(
      builder: (context, setMenuState) {
        // Filter grade coordinator teachers based on search query
        final filteredTeachers = _gradeCoordinatorSearchQuery.isEmpty
            ? _gradeCoordinatorTeachers
            : _gradeCoordinatorTeachers.where((teacher) {
                final name = teacher.displayName.toLowerCase();
                final employeeId = teacher.employeeId.toLowerCase();
                return name.contains(_gradeCoordinatorSearchQuery) ||
                    employeeId.contains(_gradeCoordinatorSearchQuery);
              }).toList();

        return Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grade $grade Coordinator',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _closeGradeCoordinatorMenu,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Search field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _gradeCoordinatorSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search teachers...',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    suffixIcon: _gradeCoordinatorSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _gradeCoordinatorSearchController.clear();
                              setMenuState(() {
                                _gradeCoordinatorSearchQuery = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF00C853)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (value) {
                    setMenuState(() {
                      _gradeCoordinatorSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const Divider(height: 1),

              // Remove Coordinator option
              if (_gradeCoordinators[grade] != null) ...[
                InkWell(
                  onTap: () async {
                    // Remove from database
                    final success = await _coordinatorService.removeCoordinator(
                      grade,
                    );

                    if (success) {
                      setState(() {
                        _gradeCoordinators[grade] = null;
                      });
                      _closeGradeCoordinatorMenu();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Grade $grade coordinator removed'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      _closeGradeCoordinatorMenu();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to remove coordinator'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.clear, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Remove Coordinator',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],

              // Grade coordinator list
              Flexible(
                child: _isLoadingGradeCoordinators
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : filteredTeachers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No grade coordinators found',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          return InkWell(
                            onTap: () async {
                              print('💾 Attempting to assign coordinator...');
                              print(
                                '   Teacher: ${teacher.displayName} (ID: ${teacher.id})',
                              );
                              print('   Grade: $grade');

                              // Get current user for assignedBy
                              final currentUser = _supabase.auth.currentUser;
                              print('   Assigned by: ${currentUser?.id}');

                              // Get current school year (you may want to make this dynamic)
                              final now = DateTime.now();
                              final schoolYear = now.month >= 6
                                  ? '${now.year}-${now.year + 1}'
                                  : '${now.year - 1}-${now.year}';
                              print('   School year: $schoolYear');

                              // Save to database
                              print('🔄 Calling assignCoordinator service...');
                              final result = await _coordinatorService
                                  .assignCoordinator(
                                    teacherId: teacher.id,
                                    teacherName: teacher.displayName,
                                    gradeLevel: grade,
                                    schoolYear: schoolYear,
                                    assignedBy: currentUser?.id,
                                  );

                              print('📊 Assignment result: $result');

                              final success = result['success'] as bool;
                              final message = result['message'] as String;
                              final error = result['error'] as String?;

                              if (success) {
                                print(
                                  '✅ Updating UI state with new coordinator',
                                );
                                setState(() {
                                  _gradeCoordinators[grade] = teacher;
                                });
                                print(
                                  '📋 Updated _gradeCoordinators map: ${_gradeCoordinators.keys.toList()}',
                                );
                                _closeGradeCoordinatorMenu();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                print('❌ Failed to assign coordinator: $error');
                                _closeGradeCoordinatorMenu();

                                // Show specific error message for already assigned
                                if (error == 'already_assigned') {
                                  final existingGrade =
                                      result['existingGrade'] as int;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${teacher.displayName} is already assigned to Grade $existingGrade. Please remove them first.',
                                        ),
                                        duration: const Duration(seconds: 3),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _gradeCoordinators[grade]?.id == teacher.id
                                        ? Icons.check_circle
                                        : Icons.person_outline,
                                    size: 16,
                                    color:
                                        _gradeCoordinators[grade]?.id ==
                                            teacher.id
                                        ? const Color(0xFF00C853)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      teacher.displayName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Handle school year change with confirmation dialog
  Future<void> _handleSchoolYearChange(String yearLabel) async {
    // If clicking the already selected year, do nothing
    if (_selectedSchoolYear == yearLabel) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Change School Year?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade900,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to change the school year to:',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade300, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      yearLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will affect grade levels and all related data. Make sure this is the correct school year.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // Confirm button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Yes, Change School Year',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with the change
    if (confirmed == true) {
      setState(() {
        _selectedSchoolYear = yearLabel;
      });

      // Save preference
      await _saveSchoolYearPreference(yearLabel);

      // Reload classrooms for the new year
      await _loadClassroomsForSelectedYear();

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📅 School year changed to $yearLabel',
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: Colors.green.shade500,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar - NEW REUSABLE WIDGET
          ClassroomLeftSidebarStateful(
            title: 'CLASSROOM MANAGEMENT',
            onBackPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
            expandedGrades: _expandedGrades,
            onGradeToggle: (grade) {
              setState(() {
                _expandedGrades[grade] = !(_expandedGrades[grade] ?? false);
              });
            },
            allClassrooms: _allClassrooms,
            selectedClassroom: _selectedClassroom,
            onClassroomSelected: (classroom) {
              // Switch to view mode when classroom is selected
              _switchToViewMode(classroom);
            },
            gradeCoordinators: _gradeCoordinators,
            onSetGradeCoordinator: (grade) {
              _openGradeCoordinatorMenu(grade);
            },
            gradeButtonKeys: _gradeButtonKeys,
            gradeLayerLinks: _gradeLayerLinks,
            schoolYears: _schoolYears,
            selectedSchoolYear: _selectedSchoolYear,
            onSchoolYearChanged: (year) async {
              await _handleSchoolYearChange(year);
            },
            onAddSchoolYear: () {
              _showAddSchoolYearDialog();
            },
            canManageCoordinators: true,
            canManageSchoolYears: true,
          ),

          // Main Content Area
          Expanded(child: _buildMainContent()),

          // Right Sidebar
          _buildRightSidebar(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLASSROOM MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Grade level list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Junior High School Section (Grades 7-10)
                _buildSectionHeader('JUNIOR HIGH SCHOOL', isJHS: true),
                for (int grade = 7; grade <= 10; grade++)
                  _buildGradeItem(grade),

                const SizedBox(height: 8),

                // Senior High School Section (Grades 11-12)
                _buildSectionHeader('SENIOR HIGH SCHOOL', isJHS: false),
                for (int grade = 11; grade <= 12; grade++)
                  _buildGradeItem(grade),

                const SizedBox(height: 16),

                // School Year Selector
                _buildSchoolYearSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool isJHS}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // Light blue
            Color(0xFFBBDEFB), // Slightly darker light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  /// Show dialog to add a custom school year
  void _showAddSchoolYearDialog() {
    final TextEditingController yearController = TextEditingController();

    // Get the current real-world year using DateTime.now()
    final currentYear = DateTime.now().year;
    final nextYear = currentYear + 1;
    final currentSchoolYear = '$currentYear-$nextYear';

    // Get the latest school year to show as a guide
    String? latestYear;
    if (_schoolYears.isNotEmpty) {
      // Sort by start_year descending to get the latest
      final sortedYears = List<SchoolYearSimple>.from(_schoolYears)
        ..sort((a, b) => b.startYear.compareTo(a.startYear));
      latestYear = sortedYears.first.yearLabel;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            Text(
              'Add School Year',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.purple.shade900,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the school year (e.g., 2023-2024)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),

              // Show current year (based on real-world date)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Current year: $currentSchoolYear',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Show latest year added as a guide
              if (latestYear != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.purple.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Latest year added: $latestYear',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                maxLength: 9, // YYYY-YYYY format
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade900,
                ),
                decoration: InputDecoration(
                  hintText: 'YYYY-YYYY',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade300,
                  ),
                  prefixIcon: Icon(
                    Icons.edit_calendar,
                    size: 16,
                    color: Colors.purple.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.purple.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.purple.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Colors.purple.shade500,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                  counterText: '', // Hide character counter
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    // Auto-format: add dash after 4 digits
                    String text = newValue.text.replaceAll('-', '');

                    if (text.length > 4) {
                      text = '${text.substring(0, 4)}-${text.substring(4)}';
                    }

                    if (text.length > 9) {
                      text = text.substring(0, 9);
                    }

                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // Add button
          ElevatedButton(
            onPressed: () async {
              final yearText = yearController.text.trim();

              // Validate format: YYYY-YYYY
              final regex = RegExp(r'^\d{4}-\d{4}$');
              if (!regex.hasMatch(yearText)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invalid format. Please enter YYYY-YYYY (e.g., 2023-2024)',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.red.shade400,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              // Parse year label to get start and end years
              final parsed = _schoolYearService.parseYearLabel(yearText);
              if (parsed == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invalid year gap! Must be exactly 1 year (e.g., 2023-2024, not 2023-2025)',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.red.shade400,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }

              // Check if already exists in database
              final exists = await _schoolYearService.schoolYearExists(
                yearText,
              );
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'School year $yearText already exists',
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange.shade400,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              // Close dialog and perform operation
              Navigator.of(context).pop();

              // Perform the operation without showing snackbars
              // (to avoid widget lifecycle issues)
              try {
                print('🔄 Starting school year creation process...');

                // Add to database
                final newYear = await _schoolYearService.createSchoolYear(
                  yearLabel: yearText,
                  startYear: parsed['startYear']!,
                  endYear: parsed['endYear']!,
                  isActive: true,
                  isCurrent: false,
                );

                print(
                  '✅ School year created in database: ${newYear.yearLabel}',
                );

                // Reload school years to update the dropdown
                await _loadSchoolYears();

                print('✅ School years reloaded, count: ${_schoolYears.length}');
                print('✅ School year $yearText added successfully!');
              } catch (e) {
                print('❌ Failed to add school year: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Add',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Load school years from database and restore saved selection
  Future<void> _loadSchoolYears() async {
    setState(() {
      _isLoadingSchoolYears = true;
    });

    try {
      final years = await _schoolYearService.getAllSchoolYears();

      // Load saved school year preference
      final prefs = await SharedPreferences.getInstance();
      final savedYear = prefs.getString(_schoolYearPreferenceKey);

      setState(() {
        _schoolYears = years;
        _isLoadingSchoolYears = false;

        // Restore saved selection if it exists and is valid
        if (savedYear != null && years.any((y) => y.yearLabel == savedYear)) {
          _selectedSchoolYear = savedYear;
        } else {
          // Default to current school year if no saved preference
          final currentYear = years.firstWhere(
            (y) => y.isCurrent,
            orElse: () => years.first,
          );
          _selectedSchoolYear = currentYear.yearLabel;
          // Save the default selection
          _saveSchoolYearPreference(currentYear.yearLabel);
        }
      });

      print('✅ Loaded ${years.length} school years from database');
      print('📅 Selected school year: $_selectedSchoolYear');

      // Load classrooms for the selected year
      await _loadClassroomsForSelectedYear();
    } catch (e) {
      print('❌ Error loading school years: $e');
      setState(() {
        _isLoadingSchoolYears = false;
      });
    }
  }

  /// Save selected school year to SharedPreferences
  Future<void> _saveSchoolYearPreference(String year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_schoolYearPreferenceKey, year);
      print('💾 Saved school year preference: $year');
    } catch (e) {
      print('❌ Error saving school year preference: $e');
    }
  }

  /// Load classrooms filtered by selected school year
  Future<void> _loadClassroomsForSelectedYear() async {
    if (_selectedSchoolYear == null) return;

    setState(() {
      _isLoadingClassrooms = true;
    });

    try {
      print('📚 Loading classrooms for school year: $_selectedSchoolYear');

      // Query classrooms filtered by school year
      final response = await _supabase
          .from('classrooms')
          .select()
          .eq('is_active', true)
          .eq('school_year', _selectedSchoolYear!)
          .order('grade_level')
          .order('title');

      final classrooms = (response as List)
          .map((json) => Classroom.fromJson(json))
          .toList();

      setState(() {
        _allClassrooms = classrooms;
        _isLoadingClassrooms = false;
      });

      print(
        '✅ Loaded ${_allClassrooms.length} classrooms for $_selectedSchoolYear',
      );
    } catch (e) {
      print('❌ Error loading classrooms: $e');
      setState(() {
        _isLoadingClassrooms = false;
      });
    }
  }

  Widget _buildSchoolYearSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'SCHOOL YEAR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Add School Year Button
          InkWell(
            onTap: _showAddSchoolYearDialog,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, size: 14, color: Colors.purple.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Add school year',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown with search bar inside menu
          InkWell(
            key: _schoolYearButtonKey,
            onTap: _openSchoolYearMenu,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.shade300, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedSchoolYear ?? 'Select school year',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _selectedSchoolYear != null
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _selectedSchoolYear != null
                            ? Colors.purple.shade900
                            : Colors.purple.shade400,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.purple.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeItem(int grade) {
    final isExpanded = _expandedGrades[grade] ?? false;
    // Filter classrooms for this grade level
    final classrooms = _allClassrooms
        .where((c) => c.gradeLevel == grade)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedGrades[grade] = !isExpanded;
            });
          },
          hoverColor: Colors.grey.shade100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Grade $grade',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                // Plus button for grade level coordinator with badge
                CompositedTransformTarget(
                  link: _gradeLayerLinks[grade]!,
                  child: Tooltip(
                    message: 'Set grade coordinator',
                    textStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    waitDuration: const Duration(milliseconds: 500),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          key: _gradeButtonKeys[grade],
                          onTap: () {
                            _openGradeCoordinatorMenu(grade);
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        // Badge indicator when coordinator is set
                        if (_gradeCoordinators[grade] != null)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${classrooms.length}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          if (classrooms.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 12, bottom: 8),
              child: Text(
                'No classrooms yet',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...classrooms.map((classroom) => _buildClassroomItem(classroom)),
        ],
      ],
    );
  }

  Widget _buildClassroomItem(Classroom classroom) {
    final isSelected = _selectedClassroom?.id == classroom.id;

    return InkWell(
      onTap: () {
        _switchToViewMode(classroom);
      },
      hoverColor: Colors.blue.shade50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : null,
          border: isSelected
              ? Border(left: BorderSide(color: Colors.blue.shade700, width: 2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.class_,
              size: 12,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                classroom.title,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Switch to view mode and load the selected classroom
  void _switchToViewMode(Classroom classroom) {
    print('👁️ Switching to VIEW mode for classroom: ${classroom.title}');

    setState(() {
      _currentMode = 'view';
      _selectedClassroom = classroom;
      _selectedAdvisoryTeacher = null; // Reset first
    });

    // Load advisory teacher if assigned
    if (classroom.advisoryTeacherId != null) {
      try {
        final teacher = _teachers.firstWhere(
          (t) => t.id == classroom.advisoryTeacherId,
        );
        setState(() {
          _selectedAdvisoryTeacher = teacher;
        });
        print('✅ Loaded advisory teacher: ${teacher.displayName}');
      } catch (e) {
        print('⚠️ Advisory teacher not found in loaded teachers list');
      }
    }

    print('✅ Switched to VIEW mode');
  }

  /// Switch to edit mode and load the selected classroom
  void _switchToEditMode(Classroom classroom) {
    print('📝 Switching to EDIT mode for classroom: ${classroom.title}');

    setState(() {
      _currentMode = 'edit';
      _selectedClassroom = classroom;
      _titleController.text = classroom.title;
      _selectedSchoolLevel = classroom.schoolLevel == 'JHS'
          ? 'Junior High School'
          : 'Senior High School';
      _selectedGradeLevel = classroom.gradeLevel;
      _maxStudents = classroom.maxStudents; // Load student limit

      // Load quarter, semester, and academic track
      if (classroom.quarter != null) {
        // Convert "Q1" to 1, "Q2" to 2, etc.
        _selectedQuarter = int.tryParse(classroom.quarter!.replaceAll('Q', ''));
      } else {
        _selectedQuarter = null;
      }

      if (classroom.semester != null) {
        // Convert "1st Sem" to 1, "2nd Sem" to 2
        _selectedSemester = classroom.semester!.contains('1st') ? 1 : 2;
      } else {
        _selectedSemester = null;
      }

      _selectedAcademicTrack = classroom.academicTrack;
      _selectedAdvisoryTeacher = null; // Reset first
    });

    // Load advisory teacher if assigned
    if (classroom.advisoryTeacherId != null) {
      try {
        final teacher = _teachers.firstWhere(
          (t) => t.id == classroom.advisoryTeacherId,
          orElse: () => throw Exception('Teacher not found'),
        );
        setState(() {
          _selectedAdvisoryTeacher = teacher;
        });
        print('✅ Loaded advisory teacher: ${teacher.displayName}');
      } catch (e) {
        print('⚠️ Advisory teacher not found in loaded teachers list');
      }
    }
  }

  /// Switch to create mode (reset form)
  void _switchToCreateMode() {
    print('➕ Switching to CREATE mode');

    setState(() {
      _currentMode = 'create';
      _selectedClassroom = null;
      _titleController.clear();
      _selectedSchoolLevel = 'Junior High School';
      _selectedQuarter = null;
      _selectedSemester = null;
      _selectedGradeLevel = null;
      _selectedAcademicTrack = null;
      _maxStudents = 35; // Reset to default
      _selectedAdvisoryTeacher = null;
    });

    // Clear draft when explicitly switching to create mode
    _clearDraftClassroom();
  }

  /// Load draft classroom data from SharedPreferences
  Future<void> _loadDraftClassroom() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only load draft if in create mode
      final draftTitle = prefs.getString('draft_classroom_title');
      final draftAdvisoryTeacherId = prefs.getString(
        'draft_advisory_teacher_id',
      );
      final draftSchoolLevel = prefs.getString('draft_school_level');
      final draftQuarter = prefs.getInt('draft_quarter');
      final draftSemester = prefs.getInt('draft_semester');
      final draftGradeLevel = prefs.getInt('draft_grade_level');
      final draftAcademicTrack = prefs.getString('draft_academic_track');
      final draftMaxStudents = prefs.getInt('draft_max_students');

      // If there's draft data, restore it
      if (draftTitle != null || draftAdvisoryTeacherId != null) {
        print('📋 Loading draft classroom data...');

        setState(() {
          if (draftTitle != null) {
            _titleController.text = draftTitle;
          }
          if (draftSchoolLevel != null) {
            _selectedSchoolLevel = draftSchoolLevel;
          }
          if (draftQuarter != null) {
            _selectedQuarter = draftQuarter;
          }
          if (draftSemester != null) {
            _selectedSemester = draftSemester;
          }
          if (draftGradeLevel != null) {
            _selectedGradeLevel = draftGradeLevel;
          }
          if (draftAcademicTrack != null) {
            _selectedAcademicTrack = draftAcademicTrack;
          }
          if (draftMaxStudents != null) {
            _maxStudents = draftMaxStudents;
          }
        });

        // Load advisory teacher if ID exists
        if (draftAdvisoryTeacherId != null && _teachers.isNotEmpty) {
          try {
            final teacher = _teachers.firstWhere(
              (t) => t.id == draftAdvisoryTeacherId,
            );
            setState(() {
              _selectedAdvisoryTeacher = teacher;
            });
            print('✅ Loaded advisory teacher: ${teacher.displayName}');
          } catch (e) {
            print('⚠️ Advisory teacher not found in loaded teachers list');
          }
        }

        print('✅ Draft classroom data loaded');
      }
    } catch (e) {
      print('❌ Error loading draft classroom: $e');
    }
  }

  /// Save draft classroom data to SharedPreferences
  Future<void> _saveDraftClassroom() async {
    // Only save draft in create mode
    if (_currentMode != 'create') return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save all form fields
      await prefs.setString('draft_classroom_title', _titleController.text);

      if (_selectedAdvisoryTeacher != null) {
        await prefs.setString(
          'draft_advisory_teacher_id',
          _selectedAdvisoryTeacher!.id,
        );
      } else {
        await prefs.remove('draft_advisory_teacher_id');
      }

      await prefs.setString('draft_school_level', _selectedSchoolLevel);

      if (_selectedQuarter != null) {
        await prefs.setInt('draft_quarter', _selectedQuarter!);
      } else {
        await prefs.remove('draft_quarter');
      }

      if (_selectedSemester != null) {
        await prefs.setInt('draft_semester', _selectedSemester!);
      } else {
        await prefs.remove('draft_semester');
      }

      if (_selectedGradeLevel != null) {
        await prefs.setInt('draft_grade_level', _selectedGradeLevel!);
      } else {
        await prefs.remove('draft_grade_level');
      }

      if (_selectedAcademicTrack != null) {
        await prefs.setString('draft_academic_track', _selectedAcademicTrack!);
      } else {
        await prefs.remove('draft_academic_track');
      }

      // Save max students
      await prefs.setInt('draft_max_students', _maxStudents);

      print('💾 Draft classroom saved');
    } catch (e) {
      print('❌ Error saving draft classroom: $e');
    }
  }

  /// Clear draft classroom data from SharedPreferences
  Future<void> _clearDraftClassroom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_classroom_title');
      await prefs.remove('draft_advisory_teacher_id');
      await prefs.remove('draft_school_level');
      await prefs.remove('draft_quarter');
      await prefs.remove('draft_semester');
      await prefs.remove('draft_grade_level');
      await prefs.remove('draft_academic_track');
      await prefs.remove('draft_max_students');
      print('🗑️ Draft classroom cleared');
    } catch (e) {
      print('❌ Error clearing draft classroom: $e');
    }
  }

  /// Upload temporary subjects and resources to Supabase after classroom creation
  Future<void> _uploadTemporarySubjectsAndResources(String classroomId) async {
    try {
      print(
        '📤 [UPLOAD] Starting upload of temporary subjects and resources...',
      );

      // Step 1: Upload temporary subjects and build ID mapping
      final subjectIdMapping = await _uploadTemporarySubjects(classroomId);

      // Step 2: Upload temporary resources using the subject ID mapping
      await _uploadTemporaryResources(classroomId, subjectIdMapping);

      print('📤 [UPLOAD] ✅ Complete: All temporary data uploaded');
    } catch (e) {
      print('❌ [UPLOAD] Error uploading temporary data: $e');
      // Don't throw - we don't want to fail classroom creation
    }
  }

  /// Upload temporary subjects from SharedPreferences to database
  Future<Map<String, String>> _uploadTemporarySubjects(
    String classroomId,
  ) async {
    final subjectIdMapping = <String, String>{};

    try {
      print('📤 [SUBJECT UPLOAD] Starting upload of temporary subjects...');

      final prefs = await SharedPreferences.getInstance();
      final String? subjectsJson = prefs.getString('temp_classroom_subjects');

      if (subjectsJson == null) {
        print('📤 [SUBJECT UPLOAD] No temporary subjects to upload');
        return subjectIdMapping;
      }

      final Map<String, dynamic> decoded = json.decode(subjectsJson);
      final subjectService = ClassroomSubjectService();

      int totalUploaded = 0;
      int totalFailed = 0;

      // First pass: Upload parent subjects (no parentSubjectId)
      for (final entry in decoded.entries) {
        final subjectName = entry.key;
        final List<dynamic> subjectsList = entry.value;

        for (final subjectJson in subjectsList) {
          final tempSubject = ClassroomSubject.fromJson(subjectJson);

          // Skip sub-subjects in first pass
          if (tempSubject.parentSubjectId != null) continue;

          try {
            final newSubject = await subjectService.addSubject(
              classroomId: classroomId,
              subjectName: tempSubject.subjectName,
              teacherId: tempSubject.teacherId,
            );

            // Map temp ID to real ID
            subjectIdMapping[tempSubject.id] = newSubject.id;
            totalUploaded++;

            print('   ✅ Uploaded parent subject: ${tempSubject.subjectName}');
          } catch (e) {
            print('   ❌ Failed to upload ${tempSubject.subjectName}: $e');
            totalFailed++;
          }
        }
      }

      // Second pass: Upload sub-subjects (with parentSubjectId)
      for (final entry in decoded.entries) {
        final List<dynamic> subjectsList = entry.value;

        for (final subjectJson in subjectsList) {
          final tempSubject = ClassroomSubject.fromJson(subjectJson);

          // Only process sub-subjects in second pass
          if (tempSubject.parentSubjectId == null) continue;

          try {
            // Get the real parent ID from mapping
            final realParentId = subjectIdMapping[tempSubject.parentSubjectId];
            if (realParentId == null) {
              print(
                '   ⚠️ No parent mapping for ${tempSubject.subjectName}, skipping',
              );
              totalFailed++;
              continue;
            }

            final newSubject = await subjectService.addSubject(
              classroomId: classroomId,
              subjectName: tempSubject.subjectName,
              teacherId: tempSubject.teacherId,
              parentSubjectId: realParentId,
            );

            // Map temp ID to real ID
            subjectIdMapping[tempSubject.id] = newSubject.id;
            totalUploaded++;

            print('   ✅ Uploaded sub-subject: ${tempSubject.subjectName}');
          } catch (e) {
            print('   ❌ Failed to upload ${tempSubject.subjectName}: $e');
            totalFailed++;
          }
        }
      }

      print(
        '📤 [SUBJECT UPLOAD] ✅ Complete: $totalUploaded uploaded, $totalFailed failed',
      );

      // Clear temporary subjects after successful upload
      if (totalUploaded > 0) {
        await prefs.remove('temp_classroom_subjects');
        print('🗑️ [SUBJECT UPLOAD] Temporary subjects cleared');
      }

      return subjectIdMapping;
    } catch (e) {
      print('❌ [SUBJECT UPLOAD] Error uploading temporary subjects: $e');
      return subjectIdMapping;
    }
  }

  /// Upload temporary resources to Supabase after classroom creation
  Future<void> _uploadTemporaryResources(
    String classroomId,
    Map<String, String> subjectIdMapping,
  ) async {
    try {
      print('📤 [RESOURCE UPLOAD] Starting upload of temporary resources...');

      final tempStorage = TemporaryResourceStorage();
      final resourceService = SubjectResourceService();
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load all temporary resources
      final resourcesBySubject = await tempStorage.getAllResources();

      if (resourcesBySubject.isEmpty) {
        print('📤 [RESOURCE UPLOAD] No temporary resources to upload');
        return;
      }

      int totalUploaded = 0;
      int totalFailed = 0;

      // Upload resources for each subject
      for (final entry in resourcesBySubject.entries) {
        final tempSubjectId = entry.key;
        final resources = entry.value;

        // Get the real subject ID from the mapping
        final realSubjectId = subjectIdMapping[tempSubjectId];
        if (realSubjectId == null) {
          print(
            '⚠️ [RESOURCE UPLOAD] No mapping found for temp subject: $tempSubjectId',
          );
          totalFailed += resources.length;
          continue;
        }

        print(
          '📤 [RESOURCE UPLOAD] Uploading ${resources.length} resources for subject: $realSubjectId',
        );

        // Upload each resource
        for (final tempResource in resources) {
          try {
            // Check if file still exists
            final file = File(tempResource.filePath);
            if (!await file.exists()) {
              print(
                '⚠️ [RESOURCE UPLOAD] File not found: ${tempResource.filePath}',
              );
              totalFailed++;
              continue;
            }

            // Upload file to Supabase Storage
            final fileUrl = await resourceService.uploadFile(
              file: file,
              classroomId: classroomId,
              subjectId: realSubjectId,
              quarter: tempResource.quarter,
              resourceType: tempResource.resourceType,
            );

            // Create resource record in database
            final resource = SubjectResource(
              id: '',
              subjectId: realSubjectId,
              resourceName: tempResource.resourceName,
              resourceType: tempResource.resourceType,
              quarter: tempResource.quarter,
              fileUrl: fileUrl,
              fileName: tempResource.fileName,
              fileSize: tempResource.fileSize,
              fileType: tempResource.fileType,
              version: 1,
              isLatestVersion: true,
              previousVersionId: null,
              displayOrder: 0,
              description: tempResource.description,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              createdBy: currentUser.id,
              uploadedBy: currentUser.id,
            );

            await resourceService.createResource(resource);
            totalUploaded++;

            print(
              '   ✅ Uploaded: ${tempResource.resourceName} (Q${tempResource.quarter})',
            );
          } catch (e) {
            print('   ❌ Failed to upload ${tempResource.resourceName}: $e');
            totalFailed++;
          }
        }
      }

      print(
        '📤 [RESOURCE UPLOAD] ✅ Complete: $totalUploaded uploaded, $totalFailed failed',
      );

      // Clear temporary resources after successful upload
      if (totalUploaded > 0) {
        await tempStorage.clearAll();
        print('🗑️ [RESOURCE UPLOAD] Temporary resources cleared');
      }
    } catch (e) {
      print('❌ [RESOURCE UPLOAD] Error uploading temporary resources: $e');
      // Don't throw - we don't want to fail classroom creation if resource upload fails
    }
  }

  /// Save classroom (create new or update existing)
  Future<void> _saveClassroom() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a classroom title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGradeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a grade level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSavingClassroom = true;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (_currentMode == 'create') {
        // Create new classroom
        print('💾 Creating new classroom...');
        print('   Title: ${_titleController.text}');
        print('   Grade Level: $_selectedGradeLevel');
        print('   School Level: $_selectedSchoolLevel');
        print(
          '   Advisory Teacher: ${_selectedAdvisoryTeacher?.displayName ?? "None"}',
        );

        // Validate school year is selected
        if (_selectedSchoolYear == null) {
          throw Exception('Please select a school year first');
        }

        final newClassroom = await _classroomService.createClassroom(
          teacherId: currentUser.id, // Admin creates the classroom
          title: _titleController.text.trim(),
          gradeLevel: _selectedGradeLevel!,
          maxStudents: _maxStudents, // Use configured student limit
          schoolLevel: _selectedSchoolLevel == 'Junior High School'
              ? 'JHS'
              : 'SHS',
          schoolYear: _selectedSchoolYear!,
          quarter: _selectedQuarter != null ? 'Q$_selectedQuarter' : null,
          semester: _selectedSemester != null
              ? '${_selectedSemester}${_selectedSemester == 1 ? "st" : "nd"} Sem'
              : null,
          academicTrack: _selectedAcademicTrack,
          advisoryTeacherId: _selectedAdvisoryTeacher?.id,
        );

        print('✅ Classroom created successfully: ${newClassroom.id}');

        // Upload temporary subjects and resources to database
        await _uploadTemporarySubjectsAndResources(newClassroom.id);

        // Add to local list and sort by grade level
        setState(() {
          _allClassrooms.add(newClassroom);
          // Sort classrooms by grade level, then by title
          _allClassrooms.sort((a, b) {
            final gradeCompare = a.gradeLevel.compareTo(b.gradeLevel);
            if (gradeCompare != 0) return gradeCompare;
            return a.title.compareTo(b.title);
          });
          _selectedClassroom = newClassroom;
          _currentMode = 'edit'; // Switch to edit mode after creation
          _isSavingClassroom = false;
        });

        // Clear draft after successful creation
        await _clearDraftClassroom();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Classroom "${newClassroom.title}" created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing classroom
        print('💾 Updating classroom...');
        print('   ID: ${_selectedClassroom!.id}');
        print('   Title: ${_titleController.text}');

        await _classroomService.updateClassroom(
          classroomId: _selectedClassroom!.id,
          title: _titleController.text.trim(),
          gradeLevel: _selectedGradeLevel,
          maxStudents: _maxStudents, // Update student limit
          schoolLevel: _selectedSchoolLevel == 'Junior High School'
              ? 'JHS'
              : 'SHS',
          quarter: _selectedQuarter != null ? 'Q$_selectedQuarter' : null,
          semester: _selectedSemester != null
              ? '${_selectedSemester}${_selectedSemester == 1 ? "st" : "nd"} Sem'
              : null,
          academicTrack: _selectedAcademicTrack,
          advisoryTeacherId: _selectedAdvisoryTeacher?.id,
        );

        // Update local list
        final updatedClassroom = _selectedClassroom!.copyWith(
          title: _titleController.text.trim(),
          gradeLevel: _selectedGradeLevel,
          maxStudents: _maxStudents, // Update student limit
          schoolLevel: _selectedSchoolLevel == 'Junior High School'
              ? 'JHS'
              : 'SHS',
          quarter: _selectedQuarter != null ? 'Q$_selectedQuarter' : null,
          semester: _selectedSemester != null
              ? '${_selectedSemester}${_selectedSemester == 1 ? "st" : "nd"} Sem'
              : null,
          academicTrack: _selectedAcademicTrack,
          advisoryTeacherId: _selectedAdvisoryTeacher?.id,
        );

        setState(() {
          final index = _allClassrooms.indexWhere(
            (c) => c.id == _selectedClassroom!.id,
          );
          if (index != -1) {
            _allClassrooms[index] = updatedClassroom;
          }
          // Sort classrooms by grade level, then by title
          // This ensures classroom appears in correct position if grade level changed
          _allClassrooms.sort((a, b) {
            final gradeCompare = a.gradeLevel.compareTo(b.gradeLevel);
            if (gradeCompare != 0) return gradeCompare;
            return a.title.compareTo(b.title);
          });
          _selectedClassroom = updatedClassroom;
          _isSavingClassroom = false;
        });

        print('✅ Classroom updated successfully');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Classroom updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving classroom: $e');
      setState(() {
        _isSavingClassroom = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving classroom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMainContent() {
    return ClassroomMainContent(
      currentMode: _currentMode,
      isSaving: _isSavingClassroom,
      config: ClassroomEditorConfig.admin(),
      titleController: _titleController,
      selectedAdvisoryTeacher: _selectedAdvisoryTeacher,
      selectedClassroom: _selectedClassroom,
      availableTeachers: _teachers,
      isMenuOpen: _isMenuOpen,
      layerLink: _layerLink,
      buttonKey: _buttonKey,
      onToggleMenu: _toggleMenu,
      onCreateNew: _switchToCreateMode,
      onSave: _saveClassroom,
      onEdit: _selectedClassroom != null
          ? () => _switchToEditMode(_selectedClassroom!)
          : null,
      onAdvisoryTeacherChanged: (teacher) {
        setState(() {
          _selectedAdvisoryTeacher = teacher;
        });
        _saveDraftClassroom(); // Save draft when advisory teacher changes
      },
      onStudentsChanged: () async {
        // Refresh the selected classroom to get updated student count
        if (_selectedClassroom != null) {
          await _refreshSelectedClassroom();
        }
      },
      // Pass settings from right sidebar to show indicators
      selectedSchoolLevel: _selectedSchoolLevel,
      selectedGradeLevel: _selectedGradeLevel,
      selectedQuarter: _selectedQuarter != null ? 'Q$_selectedQuarter' : null,
      selectedSemester: _selectedSemester != null
          ? '${_selectedSemester}${_selectedSemester == 1 ? "st" : "nd"} Sem'
          : null,
      selectedAcademicTrack: _selectedAcademicTrack,
    );
  }

  Widget _buildRightSidebar() {
    return ClassroomSettingsSidebar(
      selectedSchoolLevel: _selectedSchoolLevel,
      // Note: selectedQuarter and selectedSemester removed from UI
      // They are still stored in database for backward compatibility
      selectedGradeLevel: _selectedGradeLevel,
      selectedAcademicTrack: _selectedAcademicTrack,
      maxStudents: _maxStudents,
      canEdit: true, // Admin has full edit permissions
      onSchoolLevelChanged: (value) {
        setState(() {
          _selectedSchoolLevel = value;
          if (value == 'Senior High School') {
            _selectedQuarter = null;
          } else {
            _selectedSemester = null;
            _selectedAcademicTrack = null; // Reset academic track for JHS
          }
          _selectedGradeLevel = null;
        });
        _saveDraftClassroom(); // Save draft when school level changes
      },
      onGradeLevelChanged: (value) {
        setState(() {
          _selectedGradeLevel = value;
        });
        _saveDraftClassroom(); // Save draft when grade level changes
      },
      onAcademicTrackChanged: (value) {
        setState(() {
          _selectedAcademicTrack = value;
        });
        _saveDraftClassroom(); // Save draft when academic track changes
      },
      onMaxStudentsChanged: (value) {
        setState(() {
          _maxStudents = value;
        });
        _saveDraftClassroom(); // Save draft when max students changes
      },
    );
  }
}
