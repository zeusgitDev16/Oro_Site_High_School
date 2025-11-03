import 'package:flutter/material.dart';

/// Interactive logic for Student Assignments
/// Handles state management for assignments and submissions
/// Separated from UI as per architecture guidelines
class StudentAssignmentsLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingAssignments = false;
  bool _isLoadingSubmission = false;
  bool _isSubmitting = false;

  bool get isLoadingAssignments => _isLoadingAssignments;
  bool get isLoadingSubmission => _isLoadingSubmission;
  bool get isSubmitting => _isSubmitting;

  // Filter and sort
  String _selectedFilter = 'All'; // All, Due Soon, Submitted, Missing, Graded
  String _selectedSort = 'Due Date'; // Due Date, Course, Status

  String get selectedFilter => _selectedFilter;
  String get selectedSort => _selectedSort;

  // Current submission being edited
  Map<String, dynamic>? _currentSubmission;
  Map<String, dynamic>? get currentSubmission => _currentSubmission;

  // Mock assignments data
  List<Map<String, dynamic>> _assignments = [
    {
      'id': 1,
      'title': 'Math Quiz 3: Integers',
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'dueDate': DateTime.now().add(const Duration(days: 1)),
      'pointsPossible': 50,
      'status': 'not_started', // not_started, draft, submitted, graded, missing
      'description': '''
# Math Quiz 3: Integers

## Instructions
Complete all problems showing your work. You may use a calculator for complex calculations.

## Topics Covered
- Adding and subtracting integers
- Multiplying and dividing integers
- Order of operations with integers
- Word problems involving integers

## Requirements
1. Show all work for full credit
2. Circle or box your final answers
3. Submit as PDF or image files
4. Due by 11:59 PM tomorrow

## Grading Rubric
- Correct answers: 40 points
- Work shown: 8 points
- Neatness: 2 points

Good luck!
      ''',
      'attachments': ['quiz3_problems.pdf', 'formula_sheet.pdf'],
      'allowResubmission': true,
      'allowLateSubmission': false,
      'submissionTypes': ['file', 'text'], // file, text, link
      'maxFileSize': 10, // MB
      'allowedFileTypes': ['.pdf', '.jpg', '.png', '.doc', '.docx'],
    },
    {
      'id': 2,
      'title': 'Science Project: Solar System Model',
      'course': 'Science 7',
      'courseId': 2,
      'teacher': 'Juan Cruz',
      'dueDate': DateTime.now().add(const Duration(days: 4)),
      'pointsPossible': 100,
      'status': 'draft',
      'description': '''
# Solar System Model Project

## Objective
Create a 3D model or digital presentation of our solar system.

## Requirements
1. Include all 8 planets
2. Show relative sizes (can be scaled)
3. Include the Sun
4. Label each celestial body
5. Add at least 3 interesting facts per planet

## Submission Options
- Physical model (submit photos)
- Digital presentation (PowerPoint, Google Slides)
- Video presentation (max 5 minutes)

## Grading Criteria
- Accuracy: 30 points
- Creativity: 25 points
- Completeness: 25 points
- Presentation: 20 points

## Resources
- NASA website
- National Geographic
- Your textbook Chapter 5
      ''',
      'attachments': ['project_rubric.pdf', 'planet_facts.pdf'],
      'allowResubmission': true,
      'allowLateSubmission': true,
      'submissionTypes': ['file', 'link'],
      'maxFileSize': 50,
      'allowedFileTypes': ['.pdf', '.ppt', '.pptx', '.jpg', '.png', '.mp4'],
    },
    {
      'id': 3,
      'title': 'English Essay: My Hero',
      'course': 'English 7',
      'courseId': 3,
      'teacher': 'Ana Reyes',
      'dueDate': DateTime.now().add(const Duration(days: 6)),
      'pointsPossible': 75,
      'status': 'not_started',
      'description': '''
# Essay: My Hero

## Topic
Write a 500-word essay about someone you consider a hero. This can be a family member, historical figure, or anyone who has inspired you.

## Essay Structure
1. **Introduction** (1 paragraph)
   - Hook to grab reader's attention
   - Introduce your hero
   - Thesis statement

2. **Body** (3 paragraphs)
   - Who is this person?
   - What did they do?
   - Why are they your hero?

3. **Conclusion** (1 paragraph)
   - Summarize main points
   - Personal reflection
   - Closing thought

## Requirements
- 500-600 words
- Times New Roman, 12pt font
- Double-spaced
- Include a title
- Proper grammar and spelling

## Submission
Submit as a Word document or PDF.
      ''',
      'attachments': ['essay_guidelines.pdf', 'sample_essay.pdf'],
      'allowResubmission': true,
      'allowLateSubmission': true,
      'submissionTypes': ['file', 'text'],
      'maxFileSize': 5,
      'allowedFileTypes': ['.doc', '.docx', '.pdf'],
    },
    {
      'id': 4,
      'title': 'Filipino: Tula (Poem)',
      'course': 'Filipino 7',
      'courseId': 4,
      'teacher': 'Pedro Santos',
      'dueDate': DateTime.now().subtract(const Duration(days: 2)),
      'pointsPossible': 50,
      'status': 'missing',
      'description': '''
# Gawain: Pagsulat ng Tula

## Panuto
Sumulat ng isang tula tungkol sa inyong pamilya o kaibigan.

## Mga Kinakailangan
- 4 na saknong (stanzas)
- 4 na taludtod (lines) bawat saknong
- May tugma (rhyme)
- Gumamit ng mga tayutay (figures of speech)

## Pamantayan sa Pagmamarka
- Nilalaman: 20 puntos
- Tugma at Sukat: 15 puntos
- Paggamit ng Tayutay: 10 puntos
- Kalinisan: 5 puntos

Isumite bilang PDF o Word document.
      ''',
      'attachments': ['halimbawa_tula.pdf'],
      'allowResubmission': false,
      'allowLateSubmission': true,
      'submissionTypes': ['file', 'text'],
      'maxFileSize': 5,
      'allowedFileTypes': ['.doc', '.docx', '.pdf'],
    },
    {
      'id': 5,
      'title': 'Math Homework: Chapter 4 Review',
      'course': 'Mathematics 7',
      'courseId': 1,
      'teacher': 'Maria Santos',
      'dueDate': DateTime.now().subtract(const Duration(days: 5)),
      'pointsPossible': 30,
      'status': 'graded',
      'description': '''
# Chapter 4 Review: Basic Algebra

Complete all problems from pages 85-87 in your textbook.

## Problems to Complete
- Problems 1-20 (all)
- Show your work
- Check your answers

Submit your completed work as a PDF scan or clear photos.
      ''',
      'attachments': ['chapter4_review.pdf'],
      'allowResubmission': false,
      'allowLateSubmission': false,
      'submissionTypes': ['file'],
      'maxFileSize': 10,
      'allowedFileTypes': ['.pdf', '.jpg', '.png'],
    },
  ];

  List<Map<String, dynamic>> get assignments => _assignments;

  // Mock submissions data
  Map<int, Map<String, dynamic>> _submissions = {
    2: { // Science Project - Draft
      'id': 201,
      'assignmentId': 2,
      'status': 'draft',
      'submittedAt': null,
      'lastSaved': DateTime.now().subtract(const Duration(hours: 3)),
      'textContent': 'I am working on a PowerPoint presentation about the solar system...',
      'files': [
        {
          'name': 'solar_system_draft.pptx',
          'size': 2.5, // MB
          'type': 'application/vnd.ms-powerpoint',
          'uploadedAt': DateTime.now().subtract(const Duration(hours: 3)),
        },
      ],
      'links': [],
    },
    5: { // Math Homework - Graded
      'id': 205,
      'assignmentId': 5,
      'status': 'graded',
      'submittedAt': DateTime.now().subtract(const Duration(days: 6)),
      'lastSaved': DateTime.now().subtract(const Duration(days: 6)),
      'textContent': '',
      'files': [
        {
          'name': 'chapter4_homework.pdf',
          'size': 1.2,
          'type': 'application/pdf',
          'uploadedAt': DateTime.now().subtract(const Duration(days: 6)),
        },
      ],
      'links': [],
      'grade': {
        'score': 27,
        'pointsPossible': 30,
        'percentage': 90,
        'feedback': 'Excellent work! Minor error on problem 15. Keep it up!',
        'gradedAt': DateTime.now().subtract(const Duration(days: 4)),
        'gradedBy': 'Maria Santos',
      },
    },
  };

  // Get filtered and sorted assignments
  List<Map<String, dynamic>> getFilteredAssignments() {
    var filtered = _assignments.where((assignment) {
      switch (_selectedFilter) {
        case 'Due Soon':
          final daysUntilDue = assignment['dueDate'].difference(DateTime.now()).inDays;
          return daysUntilDue >= 0 && daysUntilDue <= 3 && assignment['status'] != 'graded';
        case 'Submitted':
          return assignment['status'] == 'submitted' || assignment['status'] == 'graded';
        case 'Missing':
          return assignment['status'] == 'missing';
        case 'Graded':
          return assignment['status'] == 'graded';
        default:
          return true;
      }
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Course':
          return a['course'].compareTo(b['course']);
        case 'Status':
          return a['status'].compareTo(b['status']);
        default: // Due Date
          return a['dueDate'].compareTo(b['dueDate']);
      }
    });

    return filtered;
  }

  // Get assignment by ID
  Map<String, dynamic>? getAssignmentById(int assignmentId) {
    try {
      return _assignments.firstWhere((a) => a['id'] == assignmentId);
    } catch (e) {
      return null;
    }
  }

  // Get submission for assignment
  Map<String, dynamic>? getSubmission(int assignmentId) {
    return _submissions[assignmentId];
  }

  // Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Set sort
  void setSort(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  // Load assignments
  Future<void> loadAssignments() async {
    _isLoadingAssignments = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final enrollments = await EnrollmentService.getEnrollmentsByStudent(studentId);
    // final courseIds = enrollments.map((e) => e.courseId).toList();
    // final assignments = await AssignmentService.getAssignmentsByCourses(courseIds);
    // Update assignment statuses based on submissions

    _isLoadingAssignments = false;
    notifyListeners();
  }

  // Load submission
  Future<void> loadSubmission(int assignmentId) async {
    _isLoadingSubmission = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // In real implementation:
    // final submission = await SubmissionService.getStudentSubmission(assignmentId, studentId);
    _currentSubmission = _submissions[assignmentId];

    _isLoadingSubmission = false;
    notifyListeners();
  }

  // Create or update submission (draft)
  Future<bool> saveSubmissionDraft({
    required int assignmentId,
    String? textContent,
    List<Map<String, dynamic>>? files,
    List<String>? links,
  }) async {
    try {
      // Get or create submission
      var submission = _submissions[assignmentId];
      if (submission == null) {
        submission = {
          'id': 200 + assignmentId,
          'assignmentId': assignmentId,
          'status': 'draft',
          'submittedAt': null,
          'lastSaved': DateTime.now(),
          'textContent': textContent ?? '',
          'files': files ?? [],
          'links': links ?? [],
        };
        _submissions[assignmentId] = submission;
      } else {
        submission['textContent'] = textContent ?? submission['textContent'];
        submission['files'] = files ?? submission['files'];
        submission['links'] = links ?? submission['links'];
        submission['lastSaved'] = DateTime.now();
      }

      // Update assignment status
      final assignment = _assignments.firstWhere((a) => a['id'] == assignmentId);
      if (assignment['status'] == 'not_started') {
        assignment['status'] = 'draft';
      }

      _currentSubmission = submission;
      notifyListeners();

      // In real implementation:
      // await SubmissionService.saveDraft(submission);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Submit final submission
  Future<bool> submitAssignment(int assignmentId) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update submission
      final submission = _submissions[assignmentId];
      if (submission != null) {
        submission['status'] = 'submitted';
        submission['submittedAt'] = DateTime.now();
      }

      // Update assignment status
      final assignment = _assignments.firstWhere((a) => a['id'] == assignmentId);
      assignment['status'] = 'submitted';

      _isSubmitting = false;
      notifyListeners();

      // In real implementation:
      // await SubmissionService.submitFinal(assignmentId, studentId);
      // await NotificationTriggerService.onSubmissionCreated(assignmentId, studentId);

      return true;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // Add file to submission
  void addFile(int assignmentId, Map<String, dynamic> file) {
    var submission = _submissions[assignmentId];
    if (submission == null) {
      submission = {
        'id': 200 + assignmentId,
        'assignmentId': assignmentId,
        'status': 'draft',
        'submittedAt': null,
        'lastSaved': DateTime.now(),
        'textContent': '',
        'files': [file],
        'links': [],
      };
      _submissions[assignmentId] = submission;
    } else {
      (submission['files'] as List).add(file);
      submission['lastSaved'] = DateTime.now();
    }

    _currentSubmission = submission;
    notifyListeners();
  }

  // Remove file from submission
  void removeFile(int assignmentId, String fileName) {
    final submission = _submissions[assignmentId];
    if (submission != null) {
      (submission['files'] as List).removeWhere((f) => f['name'] == fileName);
      submission['lastSaved'] = DateTime.now();
      _currentSubmission = submission;
      notifyListeners();
    }
  }

  // Add link to submission
  void addLink(int assignmentId, String link) {
    var submission = _submissions[assignmentId];
    if (submission == null) {
      submission = {
        'id': 200 + assignmentId,
        'assignmentId': assignmentId,
        'status': 'draft',
        'submittedAt': null,
        'lastSaved': DateTime.now(),
        'textContent': '',
        'files': [],
        'links': [link],
      };
      _submissions[assignmentId] = submission;
    } else {
      (submission['links'] as List).add(link);
      submission['lastSaved'] = DateTime.now();
    }

    _currentSubmission = submission;
    notifyListeners();
  }

  // Remove link from submission
  void removeLink(int assignmentId, String link) {
    final submission = _submissions[assignmentId];
    if (submission != null) {
      (submission['links'] as List).remove(link);
      submission['lastSaved'] = DateTime.now();
      _currentSubmission = submission;
      notifyListeners();
    }
  }

  // Update text content
  void updateTextContent(int assignmentId, String content) {
    var submission = _submissions[assignmentId];
    if (submission == null) {
      submission = {
        'id': 200 + assignmentId,
        'assignmentId': assignmentId,
        'status': 'draft',
        'submittedAt': null,
        'lastSaved': DateTime.now(),
        'textContent': content,
        'files': [],
        'links': [],
      };
      _submissions[assignmentId] = submission;
    } else {
      submission['textContent'] = content;
      submission['lastSaved'] = DateTime.now();
    }

    _currentSubmission = submission;
    notifyListeners();
  }

  // Get statistics
  Map<String, int> getStatistics() {
    int total = _assignments.length;
    int submitted = _assignments.where((a) => a['status'] == 'submitted' || a['status'] == 'graded').length;
    int missing = _assignments.where((a) => a['status'] == 'missing').length;
    int dueSoon = _assignments.where((a) {
      final daysUntilDue = (a['dueDate'] as DateTime).difference(DateTime.now()).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 3 && a['status'] != 'graded';
    }).length;

    return {
      'total': total,
      'submitted': submitted,
      'missing': missing,
      'dueSoon': dueSoon,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
