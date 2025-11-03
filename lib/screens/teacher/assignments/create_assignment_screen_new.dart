import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/models/classroom.dart';
import 'package:oro_site_high_school/services/assignment_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:math' as math;

/// Layer 1: UI Layer - Create Assignment Screen
/// Full-screen assignment creation with type-specific templates
class CreateAssignmentScreen extends StatefulWidget {
  final Classroom classroom;
  final Map<String, dynamic>? existingAssignment; // For editing

  const CreateAssignmentScreen({
    super.key,
    required this.classroom,
    this.existingAssignment,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '0');

  String _selectedType = 'quiz';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isSaving = false;
  bool _allowLateSubmissions = true;
  // Grading tags (UI only for now; persisted in content.meta until DB columns are added)
  String _component = 'written_works'; // 'written_works' | 'performance_task'
  int _quarterNo = 1; // 1..4

  // Supabase client and pending uploaded files for file-upload type
  final _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _pendingFiles = [];

  // Quiz questions
  final List<Map<String, dynamic>> _quizQuestions = [];

  // Multiple choice questions
  final List<Map<String, dynamic>> _multipleChoiceQuestions = [];

  // Identification questions
  final List<Map<String, dynamic>> _identificationQuestions = [];

  // Matching type pairs
  final List<Map<String, dynamic>> _matchingPairs = [];

  // Essay questions
  final List<Map<String, dynamic>> _essayQuestions = [];

  @override
  void initState() {
    super.initState();

    // If editing, hydrate state from existing assignment
    if (widget.existingAssignment != null) {
      final a = widget.existingAssignment!;
      _titleController.text = a['title'] ?? '';
      _descriptionController.text = a['description'] ?? '';
      _selectedType = a['assignment_type'] ?? 'quiz';
      _pointsController.text = (a['total_points'] ?? 0).toString();
      _allowLateSubmissions = a['allow_late_submissions'] ?? true;

      // Parse due_date
      if (a['due_date'] != null) {
        final dt = DateTime.tryParse(a['due_date']);
        if (dt != null) {
          _dueDate = DateTime(dt.year, dt.month, dt.day);
          _dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
      }

      // Hydrate grading tags if present (temporary: from content.meta)
      try {
        final meta = (a['content']?['meta']) as Map<String, dynamic>?;
        if (meta != null) {
          _component = (meta['component'] as String?) ?? _component;
          _quarterNo = int.tryParse((meta['quarter_no']?.toString() ?? '1')) ?? _quarterNo;
        }
        if (a['component'] != null) _component = a['component'];
        if (a['quarter_no'] != null) _quarterNo = int.tryParse(a['quarter_no'].toString()) ?? _quarterNo;
      } catch (_) {}

      // Load content based on type
      final content = (a['content'] ?? {}) as Map<String, dynamic>;
      switch (_selectedType) {
        case 'quiz':
          final qs = (content['questions'] as List?) ?? [];
          _quizQuestions.addAll(qs.map((e) => Map<String, dynamic>.from(e as Map)));
          break;
        case 'multiple_choice':
          final qs = (content['questions'] as List?) ?? [];
          _multipleChoiceQuestions.addAll(qs.map((e) => Map<String, dynamic>.from(e as Map)));
          break;
        case 'identification':
          final qs = (content['questions'] as List?) ?? [];
          _identificationQuestions.addAll(qs.map((e) => Map<String, dynamic>.from(e as Map)));
          break;
        case 'matching_type':
          final ps = (content['pairs'] as List?) ?? [];
          _matchingPairs.addAll(ps.map((e) => Map<String, dynamic>.from(e as Map)));
          break;
        case 'essay':
          final qs = (content['questions'] as List?) ?? [];
          _essayQuestions.addAll(qs.map((e) => Map<String, dynamic>.from(e as Map)));
          break;
        case 'file_upload':
          // file_upload uses free-form; nothing to hydrate beyond instructions
          break;
      }
    }

    _updateTotalPoints();
  }

  final List<Map<String, dynamic>> _assignmentTypes = [
    {'id': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz},
    {
      'id': 'multiple_choice',
      'label': 'Multiple Choice',
      'icon': Icons.checklist,
    },
    {
      'id': 'identification',
      'label': 'Identification',
      'icon': Icons.text_fields,
    },
    {
      'id': 'matching_type',
      'label': 'Matching Type',
      'icon': Icons.compare_arrows,
    },
    {'id': 'file_upload', 'label': 'File Upload', 'icon': Icons.upload_file},
    {'id': 'essay', 'label': 'Essay', 'icon': Icons.article},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: Row(
              children: [
                // Left Sidebar - Assignment Types
                _buildTypeSidebar(),

                // Main Content Area
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_add,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingAssignment == null ? 'Create New Assignment' : 'Edit Assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.classroom.title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAssignment,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save Assignment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'ASSIGNMENT TYPE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _assignmentTypes.length,
              itemBuilder: (context, index) {
                final type = _assignmentTypes[index];
                final isSelected = _selectedType == type['id'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type['id'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type['icon'],
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type['label'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildBasicInfoSection(),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // Type-specific content
            _buildTypeSpecificContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Assignment Title
        _buildSectionLabel('Assignment Title', Icons.title, isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration('Enter assignment title'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an assignment title';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Assignment Description
        _buildSectionLabel('Description', Icons.description),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: _inputDecoration('Enter assignment description'),
          maxLines: 3,
        ),

        const SizedBox(height: 20),

        // Points, Due Date, Due Time Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Points', Icons.star, isRequired: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pointsController,
                    decoration: _inputDecoration('100'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final points = int.tryParse(value);
                      if (points == null || points <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Due Date', Icons.calendar_today),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDueDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dueDate != null
                                  ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 14,
                                color: _dueDate != null
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Due Time', Icons.access_time),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDueTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dueTime != null
                                  ? _dueTime!.format(context)
                                  : 'Select time',
                              style: TextStyle(
                                fontSize: 14,
                                color: _dueTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Grading Tags (Component and Quarter)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Grading Tags',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Component', style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              selected: _component == 'written_works',
                              label: const Text('Written Works'),
                              onSelected: (_) => setState(() => _component = 'written_works'),
                            ),
                            ChoiceChip(
                              selected: _component == 'performance_task',
                              label: const Text('Performance Task'),
                              onSelected: (_) => setState(() => _component = 'performance_task'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quarter', style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _quarterNo,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Q1')),
                            DropdownMenuItem(value: 2, child: Text('Q2')),
                            DropdownMenuItem(value: 3, child: Text('Q3')),
                            DropdownMenuItem(value: 4, child: Text('Q4')),
                          ],
                          onChanged: (v) => setState(() => _quarterNo = v ?? 1),
                          decoration: _inputDecoration('Select quarter'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Late Submission Settings
        _buildLateSubmissionSettings(),
      ],
    );
  }

  Widget _buildLateSubmissionSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                'Late Submission Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Allow Late Submissions Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _allowLateSubmissions ? Colors.green.shade300 : Colors.red.shade300,
                width: 2,
              ),
            ),
            child: SwitchListTile(
              value: _allowLateSubmissions,
              onChanged: (value) {
                setState(() {
                  _allowLateSubmissions = value;
                });
              },
              title: Text(
                _allowLateSubmissions ? 'Allow Late Submissions' : 'Do Not Allow Late Submissions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _allowLateSubmissions ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              subtitle: Text(
                _allowLateSubmissions
                    ? 'Students can submit after the deadline (marked as late)'
                    : 'Assignment will be hidden after deadline - no submissions allowed',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              activeColor: Colors.green,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _allowLateSubmissions ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _allowLateSubmissions ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _allowLateSubmissions ? Icons.check_circle_outline : Icons.block,
                  color: _allowLateSubmissions ? Colors.green.shade700 : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _allowLateSubmissions ? 'Late Submissions Enabled' : 'Late Submissions Disabled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _allowLateSubmissions ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _allowLateSubmissions
                            ? '• Assignment remains visible to students after deadline\n'
                              '• Students can still submit their work\n'
                              '• Late submissions will be clearly marked\n'
                              '• You can apply late penalties when grading'
                            : '• Assignment automatically hidden after deadline\n'
                              '• Students cannot view or submit after due date\n'
                              '• Helps enforce strict deadlines\n'
                              '• Students who miss deadline get 0 points',
                        style: TextStyle(
                          fontSize: 13,
                          color: _allowLateSubmissions ? Colors.green.shade800 : Colors.red.shade800,
                          height: 1.5,
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
    );
  }

  Widget _buildTypeSpecificContent() {
    switch (_selectedType) {
      case 'quiz':
        return _buildQuizTemplate();
      case 'multiple_choice':
        return _buildMultipleChoiceTemplate();
      case 'identification':
        return _buildIdentificationTemplate();
      case 'matching_type':
        return _buildMatchingTypeTemplate();
      case 'file_upload':
        return _buildFileUploadTemplate();
      case 'essay':
        return _buildEssayTemplate();
      default:
        return const SizedBox.shrink();
    }
  }

  // Template builders will be in the next file part...
  Widget _buildQuizTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quiz Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addQuizQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_quizQuestions.isEmpty)
          _buildEmptyState(
            'No questions added yet',
            'Click "Add Question" to create your first quiz question',
          )
        else
          ..._quizQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuizQuestionCard(index, question);
          }).toList(),
      ],
    );
  }

  Widget _buildQuizQuestionCard(int index, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeQuizQuestion(index),
                  tooltip: 'Delete question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['question'],
              decoration: _inputDecoration('Enter question'),
              maxLines: 2,
              onChanged: (value) {
                question['question'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['answer'],
              decoration: _inputDecoration('Enter correct answer'),
              onChanged: (value) {
                question['answer'] = value;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['points']?.toString() ?? '1',
              decoration: _inputDecoration('Points for this question').copyWith(
                suffixText: 'points',
                suffixStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                question['points'] = int.tryParse(value) ?? 1;
                _updateTotalPoints();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Multiple Choice Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addMultipleChoiceQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_multipleChoiceQuestions.isEmpty)
          _buildEmptyState(
            'No questions added yet',
            'Click "Add Question" to create your first multiple choice question',
          )
        else
          ..._multipleChoiceQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildMultipleChoiceQuestionCard(index, question);
          }).toList(),
      ],
    );
  }

  Widget _buildMultipleChoiceQuestionCard(
    int index,
    Map<String, dynamic> question,
  ) {
    final choices = List<String>.from(
      ((question['choices'] as List?) ?? const []).map((e) => e == null ? '' : e.toString()),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeMultipleChoiceQuestion(index),
                  tooltip: 'Delete question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['question'],
              decoration: _inputDecoration('Enter question'),
              maxLines: 2,
              onChanged: (value) {
                question['question'] = value;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Choices:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...List.generate(choices.length, (choiceIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: choiceIndex,
                      groupValue: question['correctIndex'],
                      onChanged: (value) {
                        setState(() {
                          question['correctIndex'] = value;
                        });
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: choices[choiceIndex],
                        decoration: _inputDecoration(
                          'Choice ${String.fromCharCode(65 + choiceIndex)}',
                        ),
                        onChanged: (value) {
                          choices[choiceIndex] = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['points']?.toString() ?? '1',
              decoration: _inputDecoration('Points for this question').copyWith(
                suffixText: 'points',
                suffixStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                question['points'] = int.tryParse(value) ?? 1;
                _updateTotalPoints();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificationTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Identification Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addIdentificationQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_identificationQuestions.isEmpty)
          _buildEmptyState(
            'No questions added yet',
            'Click "Add Question" to create your first identification question',
          )
        else
          ..._identificationQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildIdentificationQuestionCard(index, question);
          }).toList(),
      ],
    );
  }

  Widget _buildIdentificationQuestionCard(
    int index,
    Map<String, dynamic> question,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeIdentificationQuestion(index),
                  tooltip: 'Delete question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['question'],
              decoration: _inputDecoration('Enter question or statement'),
              maxLines: 2,
              onChanged: (value) {
                question['question'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['answer'],
              decoration: _inputDecoration('Enter correct answer'),
              onChanged: (value) {
                question['answer'] = value;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['points']?.toString() ?? '1',
              decoration: _inputDecoration('Points for this question'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                question['points'] = int.tryParse(value) ?? 1;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingTypeTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Matching Type Pairs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addMatchingPair,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Pair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_matchingPairs.isEmpty)
          _buildEmptyState(
            'No pairs added yet',
            'Click "Add Pair" to create your first matching pair',
          )
        else
          ..._matchingPairs.asMap().entries.map((entry) {
            final index = entry.key;
            final pair = entry.value;
            return _buildMatchingPairCard(index, pair);
          }).toList(),
      ],
    );
  }

  Widget _buildMatchingPairCard(int index, Map<String, dynamic> pair) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pair ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeMatchingPair(index),
                  tooltip: 'Delete pair',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Column A',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: pair['columnA'],
                        decoration: _inputDecoration('Enter item'),
                        onChanged: (value) {
                          pair['columnA'] = value;
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Column B',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: pair['columnB'],
                        decoration: _inputDecoration('Enter matching item'),
                        onChanged: (value) {
                          pair['columnB'] = value;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: pair['points']?.toString() ?? '1',
              decoration: _inputDecoration('Points for this pair'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                pair['points'] = int.tryParse(value) ?? 1;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Upload Assignment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'File Upload Instructions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Students will be able to upload files as their submission for this assignment. You can specify:',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Maximum file size allowed'),
              _buildBulletPoint(
                'Accepted file types (PDF, DOCX, images, etc.)',
              ),
              _buildBulletPoint('Number of files students can upload'),
              _buildBulletPoint('Additional instructions for students'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _pickAndUploadFiles,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Upload files for students'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _pendingFiles.isEmpty
                  ? 'No files uploaded yet'
                  : '${_pendingFiles.length} file(s) uploaded',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingFiles.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: _pendingFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final f = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(f['file_name'] ?? 'file'),
                  subtitle: Text('${_formatBytes(f['file_size'] as int)} • ${f['file_type'] ?? 'file'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: _isSaving ? null : () => _removePendingFile(idx),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
        TextFormField(
          decoration: _inputDecoration(
            'Enter detailed instructions for students',
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _inputDecoration('Max file size (MB)'),
                keyboardType: TextInputType.number,
                initialValue: '10',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: _inputDecoration('Max number of files'),
                keyboardType: TextInputType.number,
                initialValue: '3',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEssayTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Essay Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addEssayQuestion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_essayQuestions.isEmpty)
          _buildEmptyState(
            'No questions added yet',
            'Click "Add Question" to create your first essay question',
          )
        else
          ..._essayQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildEssayQuestionCard(index, question);
          }).toList(),
      ],
    );
  }

  Widget _buildEssayQuestionCard(int index, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeEssayQuestion(index),
                  tooltip: 'Delete question',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['question'],
              decoration: _inputDecoration('Enter essay question or prompt'),
              maxLines: 3,
              onChanged: (value) {
                question['question'] = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['guidelines'],
              decoration: _inputDecoration(
                'Enter guidelines or rubric (optional)',
              ),
              maxLines: 3,
              onChanged: (value) {
                question['guidelines'] = value;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: question['minWords']?.toString() ?? '',
                    decoration: _inputDecoration('Minimum words (optional)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      question['minWords'] = int.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: question['points']?.toString() ?? '10',
                    decoration: _inputDecoration('Points for this question'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      question['points'] = int.tryParse(value) ?? 10;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to upload files'), backgroundColor: Colors.red),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
      if (result == null) return; // user canceled

      for (final file in result.files) {
        final Uint8List? bytes = file.bytes;
        final int size = file.size;
        final String name = file.name;
        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not read data for $name'), backgroundColor: Colors.red),
          );
          continue;
        }

        final sanitizedName = _sanitizeStorageSegment(name);
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
        final storagePath = '${_sanitizeStorageSegment(userId)}/$uniqueName';

        // Upload to Supabase storage (assignment_files bucket)
        await _supabase.storage
            .from('assignment_files')
            .uploadBinary(storagePath, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

        setState(() {
          _pendingFiles.add({
            'file_name': name,
            'file_path': storagePath,
            'file_size': size,
            'file_type': _guessMimeFromName(name),
            'uploaded_by': userId,
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('File(s) uploaded')]),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Upload failed: $e'))]),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removePendingFile(int index) async {
    try {
      final path = _pendingFiles[index]['file_path'] as String;
      await _supabase.storage.from('assignment_files').remove([path]);
      setState(() {
        _pendingFiles.removeAt(index);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text('Remove failed: $e'))]),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _guessMimeFromName(String name) {
    final lc = name.toLowerCase();
    if (lc.endsWith('.pdf')) return 'application/pdf';
    if (lc.endsWith('.doc') || lc.endsWith('.docx')) return 'application/msword';
    if (lc.endsWith('.xls') || lc.endsWith('.xlsx')) return 'application/vnd.ms-excel';
    if (lc.endsWith('.png')) return 'image/png';
    if (lc.endsWith('.jpg') || lc.endsWith('.jpeg')) return 'image/jpeg';
    if (lc.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  String _sanitizeStorageSegment(String s) {
    return s
        .replaceAll(RegExp(r'[^a-zA-Z0-9._\-/]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(k)).floor();
    final idx = i.clamp(0, sizes.length - 1).toInt();
    final dm = decimals < 0 ? 0 : decimals;
    final value = bytes / math.pow(k, idx);
    return '${value.toStringAsFixed(dm)} ${sizes[idx]}';
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon, {
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Automatic points computation
  void _updateTotalPoints() {
    int total = 0;

    switch (_selectedType) {
      case 'quiz':
        for (var question in _quizQuestions) {
          total += (question['points'] as int?) ?? 0;
        }
        break;
      case 'multiple_choice':
        for (var question in _multipleChoiceQuestions) {
          total += (question['points'] as int?) ?? 0;
        }
        break;
      case 'identification':
        for (var question in _identificationQuestions) {
          total += (question['points'] as int?) ?? 0;
        }
        break;
      case 'matching_type':
        for (var pair in _matchingPairs) {
          total += (pair['points'] as int?) ?? 0;
        }
        break;
      case 'essay':
        for (var question in _essayQuestions) {
          total += (question['points'] as int?) ?? 0;
        }
        break;
      case 'file_upload':
        // For file upload, use manual points entry
        return;
    }

    _pointsController.text = total.toString();
  }

  // Add question methods
  void _addQuizQuestion() {
    setState(() {
      _quizQuestions.add({'question': '', 'answer': '', 'points': 1});
      _updateTotalPoints();
    });
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      _quizQuestions.removeAt(index);
      _updateTotalPoints();
    });
  }

  void _addMultipleChoiceQuestion() {
    setState(() {
      _multipleChoiceQuestions.add({
        'question': '',
        'choices': ['', '', '', ''],
        'correctIndex': 0,
        'points': 1,
      });
      _updateTotalPoints();
    });
  }

  void _removeMultipleChoiceQuestion(int index) {
    setState(() {
      _multipleChoiceQuestions.removeAt(index);
      _updateTotalPoints();
    });
  }

  void _addIdentificationQuestion() {
    setState(() {
      _identificationQuestions.add({'question': '', 'answer': '', 'points': 1});
      _updateTotalPoints();
    });
  }

  void _removeIdentificationQuestion(int index) {
    setState(() {
      _identificationQuestions.removeAt(index);
      _updateTotalPoints();
    });
  }

  void _addMatchingPair() {
    setState(() {
      _matchingPairs.add({'columnA': '', 'columnB': '', 'points': 1});
      _updateTotalPoints();
    });
  }

  void _removeMatchingPair(int index) {
    setState(() {
      _matchingPairs.removeAt(index);
      _updateTotalPoints();
    });
  }

  void _addEssayQuestion() {
    setState(() {
      _essayQuestions.add({
        'question': '',
        'guidelines': '',
        'minWords': null,
        'points': 10,
      });
      _updateTotalPoints();
    });
  }

  void _removeEssayQuestion(int index) {
    setState(() {
      _essayQuestions.removeAt(index);
      _updateTotalPoints();
    });
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Additional validations (description is optional; all others required)
    String? error;
    if (_dueDate == null) {
      error = 'Please select a Due Date (required).';
    } else if (!{'written_works','performance_task'}.contains(_component)) {
      error = 'Please select a Component (Written Works or Performance Task).';
    } else if (!([1, 2, 3, 4].contains(_quarterNo))) {
      error = 'Please select a Quarter (Q1–Q4).';
    } else {
      switch (_selectedType) {
        case 'quiz':
          if (_quizQuestions.isEmpty) error = 'Add at least 1 quiz question.';
          break;
        case 'multiple_choice':
          if (_multipleChoiceQuestions.isEmpty) error = 'Add at least 1 multiple choice question.';
          break;
        case 'identification':
          if (_identificationQuestions.isEmpty) error = 'Add at least 1 identification question.';
          break;
        case 'matching_type':
          if (_matchingPairs.isEmpty) error = 'Add at least 1 matching pair.';
          break;
        case 'essay':
          if (_essayQuestions.isEmpty) error = 'Add at least 1 essay question.';
          break;
        case 'file_upload':
          // Allowed with just points & instructions
          break;
        default:
          error = 'Unsupported assignment type.';
      }
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare assignment content based on type
      Map<String, dynamic> content = {};
      
      switch (_selectedType) {
        case 'quiz':
          content = {'questions': _quizQuestions};
          break;
        case 'multiple_choice':
          content = {'questions': _multipleChoiceQuestions};
          break;
        case 'identification':
          content = {'questions': _identificationQuestions};
          break;
        case 'matching_type':
          content = {'pairs': _matchingPairs};
          break;
        case 'essay':
          content = {'questions': _essayQuestions};
          break;
        case 'file_upload':
          content = {
            'instructions': 'File upload assignment',
            'max_file_size': 10,
            'max_files': 3,
          };
          break;
      }

      // Persist grading tags inside content meta temporarily (until DB columns wired)
      content['meta'] = {
        'component': _component,
        'quarter_no': _quarterNo,
      };

      // Combine due date and time
      DateTime? dueDateTime;
      if (_dueDate != null && _dueTime != null) {
        dueDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      } else if (_dueDate != null) {
        dueDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          23,
          59,
        );
      }

      // Ensure points are up to date before saving
      _updateTotalPoints();
      
      // Get the final points value
      final totalPoints = int.tryParse(_pointsController.text) ?? 0;
      
      // Save or update via service
      final assignmentService = AssignmentService();

      if (widget.existingAssignment != null) {
        // Update existing assignment
        final assignmentId = widget.existingAssignment!['id'].toString();
        await assignmentService.updateAssignment(
          assignmentId: assignmentId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          assignmentType: _selectedType,
          totalPoints: totalPoints,
          dueDate: dueDateTime,
          allowLateSubmissions: _allowLateSubmissions,
          content: content,
          component: _component,
          quarterNo: _quarterNo,
        );

        // Insert any newly uploaded files
        if (_pendingFiles.isNotEmpty) {
          await assignmentService.addAssignmentFiles(
            assignmentId: assignmentId,
            files: _pendingFiles,
          );
          setState(() {
            _pendingFiles.clear();
          });
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assignment "${_titleController.text}" updated successfully!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Create new assignment
        final created = await assignmentService.createAssignment(
          classroomId: widget.classroom.id,
          teacherId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          assignmentType: _selectedType,
          totalPoints: totalPoints,
          dueDate: dueDateTime,
          allowLateSubmissions: _allowLateSubmissions,
          content: content,
          component: _component,
          quarterNo: _quarterNo,
        );

        final createdId = created['id'].toString();
        if (_pendingFiles.isNotEmpty) {
          await assignmentService.addAssignmentFiles(
            assignmentId: createdId,
            files: _pendingFiles,
          );
          setState(() {
            _pendingFiles.clear();
          });
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Assignment "${_titleController.text}" created successfully!',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error saving assignment: $e');
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error creating assignment: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
