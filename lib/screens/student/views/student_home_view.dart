import 'package:flutter/material.dart';
import 'package:oro_site_high_school/flow/student/student_dashboard_logic.dart';
import 'package:oro_site_high_school/models/student.dart';

import 'package:oro_site_high_school/screens/student/dashboard/widgets/dashboard_stats_card.dart';
import 'package:oro_site_high_school/screens/student/dashboard/widgets/upcoming_assignments_card.dart';
import 'package:oro_site_high_school/screens/student/dashboard/widgets/recent_announcements_card.dart';
import 'package:oro_site_high_school/screens/student/dashboard/widgets/today_schedule_card.dart';

/// Student Home View - Main dashboard content
/// UI only - interactive logic in StudentDashboardLogic
class StudentHomeView extends StatefulWidget {
  final StudentDashboardLogic logic;

  const StudentHomeView({super.key, required this.logic});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  final _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _lrnController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianContactController =
      TextEditingController();
  final TextEditingController _trackController = TextEditingController();
  final TextEditingController _strandController = TextEditingController();

  String? _selectedGender;
  String? _selectedSchoolLevel;
  DateTime? _birthDate;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();

    // Prime controllers from any existing logic data
    _initialiseProfileFieldsFromLogic();

    // Load dashboard data after the first frame is built
    // Note: Student profile is already loaded in StudentDashboardScreen.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.logic.loadDashboardData();
      if (!mounted) return;
      _initialiseProfileFieldsFromLogic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await widget.logic.refreshDashboard();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildMainContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initialiseProfileFieldsFromLogic() {
    final data = widget.logic.studentData;

    _lrnController.text = (data['lrn'] ?? '').toString();
    _addressController.text = (data['address'] ?? '') as String? ?? '';
    _guardianNameController.text =
        (data['guardianName'] ?? '') as String? ?? '';
    _guardianContactController.text =
        (data['guardianContact'] ?? '') as String? ?? '';
    _trackController.text = (data['track'] ?? '') as String? ?? '';
    _strandController.text = (data['strand'] ?? '') as String? ?? '';

    final gender = data['gender'] as String?;
    if (gender != null && gender.isNotEmpty) {
      _selectedGender = gender;
    }

    final level = data['schoolLevel'] as String?;
    if (level != null && level.isNotEmpty) {
      _selectedSchoolLevel = level;
    } else {
      final gradeLevel = data['gradeLevel'];
      if (gradeLevel is int) {
        if (gradeLevel >= 7 && gradeLevel <= 10) {
          _selectedSchoolLevel = 'JHS';
        } else if (gradeLevel >= 11 && gradeLevel <= 12) {
          _selectedSchoolLevel = 'SHS';
        }
      }
    }

    final birthDateValue = data['birthDate'];
    if (birthDateValue is String && birthDateValue.isNotEmpty) {
      _birthDate = DateTime.tryParse(birthDateValue);
    } else if (birthDateValue is DateTime) {
      _birthDate = birthDateValue;
    }

    if (_birthDate != null) {
      _birthDateController.text =
          '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
              .toString();
    }
  }

  Widget _buildWelcomeBanner() {
    final studentData = widget.logic.studentData;
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 18) {
      greeting = 'Good Afternoon';
    } else if (hour >= 18) {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      () {
                        final firstName =
                            studentData['firstName']?.toString().trim() ?? '';
                        final lastName =
                            studentData['lastName']?.toString().trim() ?? '';
                        if (firstName.isEmpty && lastName.isEmpty) {
                          return 'Student'; // Fallback if no name loaded yet
                        }
                        return '$firstName $lastName'.trim();
                      }(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, size: 48, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    final data = widget.logic.studentData;

    String asDisplay(dynamic value) {
      if (value == null) return '-';
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    final gradeLevel = data['gradeLevel'];
    final persistedLevel = data['schoolLevel'] as String?;
    String? resolvedLevel = _selectedSchoolLevel ?? persistedLevel;
    if (resolvedLevel == null) {
      if (gradeLevel is int) {
        if (gradeLevel >= 7 && gradeLevel <= 10) {
          resolvedLevel = 'JHS';
        } else if (gradeLevel >= 11 && gradeLevel <= 12) {
          resolvedLevel = 'SHS';
        }
      }
    }

    final levelLabel = switch (resolvedLevel) {
      'JHS' => 'Junior High School',
      'SHS' => 'Senior High School',
      _ => '-',
    };

    final lrn = asDisplay(data['lrn']);
    final address = asDisplay(data['address']);
    final guardianName = asDisplay(data['guardianName']);
    final guardianContact = asDisplay(data['guardianContact']);

    final genderCode = (_selectedGender ?? data['gender']) as String?;
    final genderDisplay = switch (genderCode) {
      'M' => 'Male',
      'F' => 'Female',
      _ => '-',
    };

    String birthDateDisplay;
    if (_birthDateController.text.isNotEmpty) {
      birthDateDisplay = _birthDateController.text;
    } else {
      final birthDateValue = data['birthDate'];
      DateTime? parsed;
      if (birthDateValue is String && birthDateValue.isNotEmpty) {
        parsed = DateTime.tryParse(birthDateValue);
      } else if (birthDateValue is DateTime) {
        parsed = birthDateValue;
      }
      if (parsed != null) {
        birthDateDisplay =
            '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      } else {
        birthDateDisplay = '-';
      }
    }

    final track = asDisplay(data['track']);
    final strand = asDisplay(data['strand']);
    final isShs = resolvedLevel == 'SHS';

    final theme = Theme.of(context);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SF9 profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This information is used for your official report card.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _showEditProfileDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileSummaryRow('School level', levelLabel),
            _buildProfileSummaryRow('LRN', lrn),
            _buildProfileSummaryRow('Gender / sex', genderDisplay),
            _buildProfileSummaryRow('Birth date', birthDateDisplay),
            const SizedBox(height: 8),
            _buildProfileSummaryRow('Address', address),
            _buildProfileSummaryRow('Guardian name', guardianName),
            _buildProfileSummaryRow('Guardian contact', guardianContact),
            if (isShs) ...[
              const Divider(height: 24),
              _buildProfileSummaryRow('SHS track', track),
              _buildProfileSummaryRow('SHS strand', strand),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    _initialiseProfileFieldsFromLogic();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Edit SF9 profile'),
          content: SingleChildScrollView(
            child: Form(
              key: _profileFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSchoolLevel,
                    decoration: const InputDecoration(
                      labelText: 'School level *',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'JHS',
                        child: Text('Junior High School'),
                      ),
                      DropdownMenuItem(
                        value: 'SHS',
                        child: Text('Senior High School'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSchoolLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'School level is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lrnController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'LRN *',
                      helperText: '12-digit Learner Reference Number',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'LRN is required.';
                      }
                      if (!Student.isValidLRN(trimmed)) {
                        return 'LRN must be exactly 12 digits.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender / sex *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Male')),
                      DropdownMenuItem(value: 'F', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Gender is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Birth date *',
                      hintText: 'YYYY-MM-DD',
                    ),
                    onTap: _pickBirthDate,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Birth date is required.';
                      }
                      if (DateTime.tryParse(text) == null) {
                        return 'Enter a valid date (YYYY-MM-DD).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guardianNameController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _guardianContactController,
                    decoration: const InputDecoration(
                      labelText: 'Guardian contact number',
                      helperText: 'Include area code or +63 as needed',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length < 7) {
                        return 'Enter a valid contact number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedSchoolLevel == 'SHS') ...[
                    TextFormField(
                      controller: _trackController,
                      decoration: const InputDecoration(
                        labelText: 'SHS track',
                        helperText: 'e.g. STEM, ABM, HUMSS, TVL',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _strandController,
                      decoration: const InputDecoration(
                        labelText: 'SHS strand',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSavingProfile
                  ? null
                  : () async {
                      await _onSaveProfile();
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    },
              child: Text(_isSavingProfile ? 'Saving...' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).requestFocus(FocusNode());

    final now = DateTime.now();
    final tentativeInitial =
        _birthDate ?? DateTime(now.year - 13, now.month, now.day);
    final firstDate = DateTime(now.year - 25, 1, 1);
    final initialDate = tentativeInitial.isBefore(firstDate)
        ? firstDate
        : tentativeInitial;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _onSaveProfile() async {
    if (_isSavingProfile) return;

    final formState = _profileFormKey.currentState;
    final messenger = ScaffoldMessenger.of(context);

    if (formState == null) {
      return;
    }

    if (!formState.validate()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form before saving.'),
        ),
      );
      return;
    }

    formState.save();

    final lrn = _lrnController.text.trim();
    final address = _addressController.text.trim();
    final guardianName = _guardianNameController.text.trim();
    final guardianContact = _guardianContactController.text.trim();
    final gender = _selectedGender;
    final birthDateText = _birthDateController.text.trim();

    DateTime? birthDate = _birthDate;
    if (birthDate == null && birthDateText.isNotEmpty) {
      birthDate = DateTime.tryParse(birthDateText);
    }

    setState(() {
      _isSavingProfile = true;
    });

    final track = _trackController.text.trim();
    final strand = _strandController.text.trim();
    final schoolLevel = _selectedSchoolLevel;

    final updates = <String, dynamic>{
      'lrn': lrn,
      'address': address,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'track': track.isEmpty ? null : track,
      'strand': strand.isEmpty ? null : strand,
    };

    if (schoolLevel != null && schoolLevel.isNotEmpty) {
      updates['schoolLevel'] = schoolLevel;
    }
    if (gender != null && gender.isNotEmpty) {
      updates['gender'] = gender;
    }
    if (birthDate != null) {
      updates['birthDate'] = birthDate;
      _birthDate = birthDate;
    }

    final success = await widget.logic.updateStudentProfile(updates);

    if (!mounted) return;

    setState(() {
      _isSavingProfile = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile updated successfully.'
              : 'Failed to update profile. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = widget.logic.getQuickStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Courses',
            '${stats['courses']}',
            Icons.book,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Assignments',
            '${stats['assignments']}',
            Icons.assignment,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Grade',
            '${stats['averageGrade'].toStringAsFixed(1)}%',
            Icons.grade,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Attendance',
            '${stats['attendanceRate'].toStringAsFixed(0)}%',
            Icons.check_circle,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              TodayScheduleCard(logic: widget.logic),
              const SizedBox(height: 16),
              UpcomingAssignmentsCard(logic: widget.logic),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              RecentAnnouncementsCard(logic: widget.logic),
              const SizedBox(height: 16),
              DashboardStatsCard(logic: widget.logic),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _lrnController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    super.dispose();
  }
}
