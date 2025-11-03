/// Enhanced Add New User Screen
/// Single-page form with role-specific sections
/// Follows 4-layer separation: UI only, backend logic in services

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/profile_service.dart';
import '../../../services/integrated_user_service.dart';

class EnhancedAddUserScreen extends StatefulWidget {
  const EnhancedAddUserScreen({super.key});

  @override
  State<EnhancedAddUserScreen> createState() => _EnhancedAddUserScreenState();
}

class _EnhancedAddUserScreenState extends State<EnhancedAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  // Basic Information Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Student-specific Controllers
  final _lrnController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Teacher-specific Controllers
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();

  final _integratedUserService = IntegratedUserService();

  // State Variables
  String _selectedRole = 'student';
  String _selectedGradeLevel = '7';
  String _selectedSection = 'A';
  String _selectedGender = 'M';
  String _coordinatorGradeLevel = '7';
  bool _isHybridUser = false;
  bool _isGradeCoordinator = false;
  bool _isSHSTeacher = false;
  bool _isLoading = false;
  DateTime? _selectedBirthDate;
  List<String> _selectedSubjects = [];
  String _selectedSHSTrack = 'Academic';
  List<String> _selectedSHSStrands = [];

  // Role Options
  final Map<String, String> _roles = {
    'student': 'Student',
    'teacher': 'Teacher',
    'admin': 'Administrator',
    'coordinator': 'ICT Coordinator',
  };

  // Grade Levels
  final List<String> _gradeLevels = ['7', '8', '9', '10', '11', '12'];

  // Sections
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E', 'F'];

  // Subjects (DepEd K-12)
  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'Filipino',
    'Araling Panlipunan',
    'TLE',
    'MAPEH',
    'Values Education',
  ];

  bool get _isCoordinatorRole => _selectedRole == 'coordinator';
  bool get _needsTeacherFields =>
      _selectedRole == 'teacher' || _isCoordinatorRole || _isHybridUser;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateEmail);
    _lastNameController.addListener(_updateEmail);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _lrnController.dispose();
    _parentEmailController.dispose();
    _guardianNameController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _updateEmail() {
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty) {
      final firstName = _firstNameController.text.toLowerCase().replaceAll(
        ' ',
        '',
      );
      final lastName = _lastNameController.text.toLowerCase().replaceAll(
        ' ',
        '',
      );
      final domain = _selectedRole == 'student'
          ? '@student.orosite.onmicrosoft.com'
          : '@orosite.onmicrosoft.com';

      setState(() {
        _emailController.text = '$firstName.$lastName$domain';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information', Icons.person),
              const SizedBox(height: 16),
              _buildBasicInfoFields(),
              const SizedBox(height: 24),

              // Role Selection
              _buildSectionHeader('Role Selection', Icons.badge),
              const SizedBox(height: 16),
              _buildRoleSelection(),
              const SizedBox(height: 24),

              // Student-specific fields
              if (_selectedRole == 'student') ...[
                _buildSectionHeader('Student Information', Icons.school),
                const SizedBox(height: 16),
                _buildStudentFields(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Parent/Guardian Information',
                  Icons.family_restroom,
                ),
                const SizedBox(height: 16),
                _buildParentFields(),
                const SizedBox(height: 24),
              ],

              // Admin-specific section
              if (_selectedRole == 'admin') ...[
                _buildSectionHeader(
                  'Administrative Settings',
                  Icons.admin_panel_settings,
                ),
                const SizedBox(height: 16),
                _buildAdminSection(),
                const SizedBox(height: 24),
              ],

              // Teacher/Coordinator fields
              if (_needsTeacherFields) ...[
                _buildSectionHeader('Teacher Information', Icons.badge),
                const SizedBox(height: 16),
                _buildTeacherFields(),
                const SizedBox(height: 24),
              ],

              // Create Button
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createUser,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(_isLoading ? 'Creating...' : 'Create User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email *',
            hintText: 'Auto-generated from name',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email),
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _updateEmail,
              tooltip: 'Regenerate email',
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@')) {
              return 'Invalid email format';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'User Role *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge),
      ),
      items: _roles.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Icon(_getRoleIcon(entry.key), size: 20),
              const SizedBox(width: 8),
              Text(entry.value),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
          _isHybridUser = false; // Reset hybrid when changing role
          _updateEmail();
        });
      },
    );
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        TextFormField(
          controller: _lrnController,
          decoration: const InputDecoration(
            labelText: 'LRN (Learner Reference Number) *',
            hintText: '12-digit LRN',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'LRN is required for students';
            }
            if (value.length != 12) {
              return 'LRN must be exactly 12 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGradeLevel,
                decoration: const InputDecoration(
                  labelText: 'Grade Level *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade),
                ),
                items: _gradeLevels.map((grade) {
                  return DropdownMenuItem(
                    value: grade,
                    child: Text('Grade $grade'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGradeLevel = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSection,
                decoration: const InputDecoration(
                  labelText: 'Section *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                items: _sections.map((section) {
                  return DropdownMenuItem(
                    value: section,
                    child: Text('Section $section'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 365 * 13),
                    ),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedBirthDate = date;
                      _birthDateController.text =
                          '${date.month}/${date.day}/${date.year}';
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Birth date is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Home Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildParentFields() {
    return Column(
      children: [
        TextFormField(
          controller: _parentEmailController,
          decoration: const InputDecoration(
            labelText: 'Parent/Guardian Email *',
            hintText: 'parent@gmail.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Parent email is required';
            }
            if (!value.contains('@')) {
              return 'Invalid email format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guardianNameController,
          decoration: const InputDecoration(
            labelText: 'Guardian Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Guardian name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactNumberController,
          decoration: const InputDecoration(
            labelText: 'Contact Number *',
            hintText: '09XX-XXX-XXXX',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Contact number is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Administrative Privileges',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This user will have full system access including:\n'
            '• User management (create, edit, delete users)\n'
            '• System configuration and settings\n'
            '• Access to all data and reports\n'
            '• Role assignment and permission management',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Hybrid User (Admin + Teacher)'),
            subtitle: const Text(
              'User will have both administrative and teaching capabilities',
            ),
            value: _isHybridUser,
            onChanged: (value) {
              setState(() {
                _isHybridUser = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherFields() {
    return Column(
      children: [
        TextFormField(
          controller: _employeeIdController,
          decoration: const InputDecoration(
            labelText: 'Employee ID *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
          validator: (value) {
            if (_needsTeacherFields && (value == null || value.isEmpty)) {
              return 'Employee ID is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _departmentController,
          decoration: const InputDecoration(
            labelText: 'Department *',
            hintText: 'e.g., Mathematics, Science',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (_needsTeacherFields && (value == null || value.isEmpty)) {
              return 'Department is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subjects to Teach',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjects.add(subject);
                        } else {
                          _selectedSubjects.remove(subject);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade700,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedRole == 'teacher') ...[
          CheckboxListTile(
            title: const Text('Senior High School (SHS) Teacher'),
            subtitle: const Text(
              'Teaches Grade 11-12 with specialized tracks and strands',
            ),
            value: _isSHSTeacher,
            onChanged: (value) {
              setState(() {
                _isSHSTeacher = value ?? false;
                if (!_isSHSTeacher) {
                  _selectedSHSStrands.clear();
                }
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
        if (_isSHSTeacher) ...[
          const SizedBox(height: 16),
          _buildSHSSection(),
          const SizedBox(height: 16),
        ],
        if (_selectedRole == 'teacher') ...[
          CheckboxListTile(
            title: const Text('Grade Level Coordinator'),
            subtitle: const Text(
              'Has additional permissions for grade level management',
            ),
            value: _isGradeCoordinator,
            onChanged: (value) {
              setState(() {
                _isGradeCoordinator = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
        if (_isCoordinatorRole || _isGradeCoordinator) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _coordinatorGradeLevel,
            decoration: const InputDecoration(
              labelText: 'Coordinator for Grade Level *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.grade),
            ),
            items: _gradeLevels.map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text('Grade $grade'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _coordinatorGradeLevel = value!;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSHSSection() {
    // SHS Tracks and Strands (DepEd K-12 Program)
    final Map<String, List<String>> shsTracks = {
      'Academic': [
        'STEM (Science, Technology, Engineering, and Mathematics)',
        'ABM (Accountancy, Business, and Management)',
        'HUMSS (Humanities and Social Sciences)',
        'GAS (General Academic Strand)',
      ],
      'Technical-Vocational-Livelihood': [
        'Home Economics',
        'Agri-Fishery Arts',
        'Industrial Arts',
        'Information and Communication Technology',
      ],
      'Sports': ['Sports Track'],
      'Arts and Design': ['Arts and Design Track'],
    };

    final availableStrands = shsTracks[_selectedSHSTrack] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              const Text(
                'Senior High School (SHS) Specialization',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSHSTrack,
            decoration: const InputDecoration(
              labelText: 'SHS Track *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.track_changes),
              filled: true,
              fillColor: Colors.white,
            ),
            items: shsTracks.keys.map((track) {
              return DropdownMenuItem(value: track, child: Text(track));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSHSTrack = value!;
                _selectedSHSStrands.clear(); // Clear strands when track changes
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Strands/Specializations *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableStrands.map((strand) {
                final isSelected = _selectedSHSStrands.contains(strand);
                return FilterChip(
                  label: Text(strand, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSHSStrands.add(strand);
                      } else {
                        _selectedSHSStrands.remove(strand);
                      }
                    });
                  },
                  selectedColor: Colors.purple.shade100,
                  checkmarkColor: Colors.purple.shade700,
                );
              }).toList(),
            ),
          ),
          if (_selectedSHSStrands.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Please select at least one strand',
              style: TextStyle(fontSize: 11, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'student':
        return Icons.school;
      case 'teacher':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'coordinator':
        return Icons.computer;
      default:
        return Icons.person;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare full name
      final fullName =
          '${_firstNameController.text} ${_lastNameController.text}'.trim();

      // Get role ID
      int roleId;
      switch (_selectedRole) {
        case 'student':
          roleId = 3;
          break;
        case 'teacher':
          roleId = 2;
          break;
        case 'admin':
          roleId = 1;
          break;
        case 'parent':
          roleId = 4;
          break;
        case 'grade_coordinator':
          roleId = 5;
          break;
        default:
          roleId = 3;
      }

      // Create user in both Azure AD and Supabase
      final result = await _integratedUserService.createUser(
        email: _emailController.text.trim(),
        fullName: fullName,
        roleId: roleId,
        // Student-specific
        lrn: _selectedRole == 'student' ? _lrnController.text : null,
        gradeLevel: _selectedRole == 'student' && _selectedGradeLevel.isNotEmpty
            ? int.parse(_selectedGradeLevel)
            : null,
        section: _selectedRole == 'student' ? _selectedSection : null,
        address: _selectedRole == 'student' ? _addressController.text : null,
        gender: _selectedRole == 'student' ? _selectedGender : null,
        birthDate: _selectedRole == 'student' ? _selectedBirthDate : null,
        // Parent data
        parentEmail:
            _selectedRole == 'student' && _parentEmailController.text.isNotEmpty
            ? _parentEmailController.text
            : null,
        guardianName:
            _selectedRole == 'student' &&
                _guardianNameController.text.isNotEmpty
            ? _guardianNameController.text
            : null,
        parentRelationship: _selectedRole == 'student' ? 'parent' : null,
        phone: _contactNumberController.text.isNotEmpty
            ? _contactNumberController.text
            : null,
        // Teacher data
        employeeId: _needsTeacherFields ? _employeeIdController.text : null,
        department: _needsTeacherFields ? _departmentController.text : null,
        subjects: _needsTeacherFields ? _selectedSubjects : null,
        isGradeCoordinator: _isGradeCoordinator,
        coordinatorGradeLevel: (_isGradeCoordinator || _isCoordinatorRole)
            ? _coordinatorGradeLevel
            : null,
        // SHS Teacher data
        isSHSTeacher: _isSHSTeacher,
        shsTrack: _isSHSTeacher ? _selectedSHSTrack : null,
        shsStrands: _isSHSTeacher ? _selectedSHSStrands : null,
        // Admin data
        isHybrid: _isHybridUser,
        validateLRN: _selectedRole == 'student',
        createInAzure: true, // Set to false to skip Azure creation
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // Show success dialog with credentials
        _showSuccessDialog(
          email: result['email'],
          password: result['password'],
          azureUserId: result['azure_user_id'],
          supabaseUserId: result['supabase_user_id'],
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error Creating User'),
            ],
          ),
          content: Text(
            'Failed to create user: ${e.toString()}\n\n'
            'Please check:\n'
            '• Azure AD permissions\n'
            '• Client secret in .env file\n'
            '• Supabase connection\n'
            '• Email is not already taken',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessDialog({
    required String email,
    required String password,
    String? azureUserId,
    required String supabaseUserId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('User Created Successfully!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The user has been created in both Azure AD and Supabase.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildInfoRow('Email', email),
              _buildInfoRow('Password', password, isPassword: true),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'User must change password on first login',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                'System IDs:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8),
              if (azureUserId != null)
                _buildInfoRow('Azure ID', azureUserId, isSmall: true),
              _buildInfoRow('Supabase ID', supabaseUserId, isSmall: true),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.copy),
            label: Text('Copy Credentials'),
            onPressed: () {
              // Copy to clipboard
              final credentials = 'Email: $email\nPassword: $password';
              // You can use clipboard package here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Credentials copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close add user screen
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isPassword = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 11 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: isPassword ? 'monospace' : null,
                fontSize: isSmall ? 11 : 14,
                fontWeight: isPassword ? FontWeight.bold : FontWeight.normal,
                color: isPassword ? Colors.blue.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
