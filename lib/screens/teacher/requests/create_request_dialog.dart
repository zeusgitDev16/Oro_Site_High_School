import 'package:flutter/material.dart';
import 'package:oro_site_high_school/models/teacher_request.dart';
import 'package:oro_site_high_school/services/teacher_request_service.dart';

/// Dialog for teachers to create requests to admin
/// UI-only component following OSHS architecture
class CreateRequestDialog extends StatefulWidget {
  final String? preSelectedType;
  final Map<String, dynamic>? preFilledData;

  const CreateRequestDialog({
    super.key,
    this.preSelectedType,
    this.preFilledData,
  });

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  final TeacherRequestService _requestService = TeacherRequestService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'other';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _requestTypes = [
    {
      'value': 'password_reset',
      'label': 'Password Reset',
      'icon': Icons.lock_reset,
      'color': Colors.red,
      'description': 'Request password reset for a student',
    },
    {
      'value': 'resource',
      'label': 'Resource Request',
      'icon': Icons.inventory_2,
      'color': Colors.blue,
      'description': 'Request materials or equipment',
    },
    {
      'value': 'technical',
      'label': 'Technical Issue',
      'icon': Icons.build,
      'color': Colors.orange,
      'description': 'Report technical problems',
    },
    {
      'value': 'course_modification',
      'label': 'Course Modification',
      'icon': Icons.edit_note,
      'color': Colors.purple,
      'description': 'Request changes to course or students',
    },
    {
      'value': 'section_change',
      'label': 'Section Change',
      'icon': Icons.swap_horiz,
      'color': Colors.teal,
      'description': 'Request student section transfer',
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.help_outline,
      'color': Colors.grey,
      'description': 'General requests or inquiries',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedType != null) {
      _selectedType = widget.preSelectedType!;
    }
    if (widget.preFilledData != null) {
      _titleController.text = widget.preFilledData!['title'] ?? '';
      _descriptionController.text = widget.preFilledData!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = TeacherRequest(
        id: 'req-${DateTime.now().millisecondsSinceEpoch}',
        teacherId: 'teacher-1', // Mock: Maria Santos
        teacherName: 'Maria Santos',
        requestType: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: 'pending',
        createdAt: DateTime.now(),
        metadata: widget.preFilledData,
      );

      await _requestService.createRequest(request);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.send, color: Colors.blue.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Request to Admin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your request will be reviewed by the admin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request Type
                      const Text(
                        'Request Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _requestTypes.map((type) {
                          final isSelected = _selectedType == type['value'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type['value'];
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: (MediaQuery.of(context).size.width - 120) / 3,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? type['color'].withOpacity(0.1)
                                    : Colors.grey.shade50,
                                border: Border.all(
                                  color: isSelected ? type['color'] : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    type['icon'],
                                    color: isSelected ? type['color'] : Colors.grey.shade600,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    type['label'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? type['color'] : Colors.grey.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Priority
                      const Text(
                        'Priority Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'low',
                            label: Text('Low'),
                            icon: Icon(Icons.arrow_downward, size: 16),
                          ),
                          ButtonSegment(
                            value: 'medium',
                            label: Text('Medium'),
                            icon: Icon(Icons.remove, size: 16),
                          ),
                          ButtonSegment(
                            value: 'high',
                            label: Text('High'),
                            icon: Icon(Icons.arrow_upward, size: 16),
                          ),
                          ButtonSegment(
                            value: 'urgent',
                            label: Text('Urgent'),
                            icon: Icon(Icons.priority_high, size: 16),
                          ),
                        ],
                        selected: {_selectedPriority},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedPriority = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Request Title *',
                          hintText: 'Brief summary of your request',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Provide detailed information about your request...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your request will be sent to the admin and you will be notified when it is reviewed.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(_isLoading ? 'Submitting...' : 'Submit Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
