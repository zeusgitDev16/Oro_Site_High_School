import 'package:flutter/material.dart';

/// Interactive logic for Student Courses
/// Handles state management for courses, modules, and lessons
/// Separated from UI as per architecture guidelines
class StudentCoursesLogic extends ChangeNotifier {
  // Loading states
  bool _isLoadingCourses = false;
  bool _isLoadingModules = false;
  bool _isLoadingLesson = false;

  bool get isLoadingCourses => _isLoadingCourses;
  bool get isLoadingModules => _isLoadingModules;
  bool get isLoadingLesson => _isLoadingLesson;

  // Search and filter
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, In Progress, Completed

  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  // Current selections
  int? _selectedCourseId;
  int? _selectedModuleId;
  int? _selectedLessonId;

  int? get selectedCourseId => _selectedCourseId;
  int? get selectedModuleId => _selectedModuleId;
  int? get selectedLessonId => _selectedLessonId;

  // Mock enrolled courses data
  List<Map<String, dynamic>> _enrolledCourses = [
    {
      'id': 1,
      'name': 'Mathematics 7',
      'code': 'MATH-7',
      'teacher': 'Maria Santos',
      'section': 'Grade 7 - Diamond',
      'schedule': 'MWF 7:00-8:00 AM',
      'room': 'Room 201',
      'color': Colors.blue,
      'progress': 65, // percentage
      'totalModules': 8,
      'completedModules': 5,
      'totalLessons': 32,
      'completedLessons': 21,
      'description': 'Introduction to basic algebra, geometry, and number theory for Grade 7 students.',
    },
    {
      'id': 2,
      'name': 'Science 7',
      'code': 'SCI-7',
      'teacher': 'Juan Cruz',
      'section': 'Grade 7 - Diamond',
      'schedule': 'TTH 8:00-9:30 AM',
      'room': 'Lab 202',
      'color': Colors.green,
      'progress': 45,
      'totalModules': 6,
      'completedModules': 3,
      'totalLessons': 24,
      'completedLessons': 11,
      'description': 'Exploring life science, earth science, and physical science concepts.',
    },
    {
      'id': 3,
      'name': 'English 7',
      'code': 'ENG-7',
      'teacher': 'Ana Reyes',
      'section': 'Grade 7 - Diamond',
      'schedule': 'MWF 9:00-10:00 AM',
      'room': 'Room 203',
      'color': Colors.orange,
      'progress': 70,
      'totalModules': 10,
      'completedModules': 7,
      'totalLessons': 40,
      'completedLessons': 28,
      'description': 'Developing reading, writing, and communication skills in English.',
    },
    {
      'id': 4,
      'name': 'Filipino 7',
      'code': 'FIL-7',
      'teacher': 'Pedro Santos',
      'section': 'Grade 7 - Diamond',
      'schedule': 'TTH 10:00-11:00 AM',
      'room': 'Room 204',
      'color': Colors.red,
      'progress': 55,
      'totalModules': 8,
      'completedModules': 4,
      'totalLessons': 32,
      'completedLessons': 18,
      'description': 'Pag-aaral ng wika, panitikan, at kultura ng Pilipinas.',
    },
  ];

  List<Map<String, dynamic>> get enrolledCourses => _enrolledCourses;

  // Mock modules data for selected course
  Map<int, List<Map<String, dynamic>>> _courseModules = {
    1: [ // Mathematics 7
      {
        'id': 1,
        'courseId': 1,
        'title': 'Module 1: Integers',
        'order': 1,
        'totalLessons': 4,
        'completedLessons': 4,
        'isCompleted': true,
      },
      {
        'id': 2,
        'courseId': 1,
        'title': 'Module 2: Fractions and Decimals',
        'order': 2,
        'totalLessons': 5,
        'completedLessons': 5,
        'isCompleted': true,
      },
      {
        'id': 3,
        'courseId': 1,
        'title': 'Module 3: Ratios and Proportions',
        'order': 3,
        'totalLessons': 4,
        'completedLessons': 4,
        'isCompleted': true,
      },
      {
        'id': 4,
        'courseId': 1,
        'title': 'Module 4: Basic Algebra',
        'order': 4,
        'totalLessons': 6,
        'completedLessons': 4,
        'isCompleted': false,
      },
      {
        'id': 5,
        'courseId': 1,
        'title': 'Module 5: Geometry Basics',
        'order': 5,
        'totalLessons': 5,
        'completedLessons': 2,
        'isCompleted': false,
      },
    ],
    2: [ // Science 7
      {
        'id': 6,
        'courseId': 2,
        'title': 'Module 1: Scientific Method',
        'order': 1,
        'totalLessons': 3,
        'completedLessons': 3,
        'isCompleted': true,
      },
      {
        'id': 7,
        'courseId': 2,
        'title': 'Module 2: Matter and Energy',
        'order': 2,
        'totalLessons': 5,
        'completedLessons': 5,
        'isCompleted': true,
      },
      {
        'id': 8,
        'courseId': 2,
        'title': 'Module 3: Living Things',
        'order': 3,
        'totalLessons': 6,
        'completedLessons': 3,
        'isCompleted': false,
      },
    ],
  };

  // Mock lessons data for selected module
  Map<int, List<Map<String, dynamic>>> _moduleLessons = {
    4: [ // Module 4: Basic Algebra
      {
        'id': 1,
        'moduleId': 4,
        'title': 'Lesson 1: Introduction to Variables',
        'content': '''
# Introduction to Variables

## What is a Variable?

A variable is a symbol (usually a letter) that represents a number we don't know yet. Think of it as a placeholder or a box that can hold different values.

### Examples:
- x = 5
- y = 10
- a + b = 15

## Why Use Variables?

Variables help us:
1. Solve problems with unknown values
2. Write general formulas
3. Represent relationships between numbers

## Practice Problems:

1. If x = 7, what is x + 3?
2. If y = 12, what is y - 5?
3. If a = 4 and b = 6, what is a + b?

Remember: Variables can represent any number!
        ''',
        'videoUrl': 'https://example.com/video1',
        'isCompleted': true,
        'duration': '15 min',
        'attachments': ['variables_worksheet.pdf', 'practice_problems.pdf'],
      },
      {
        'id': 2,
        'moduleId': 4,
        'title': 'Lesson 2: Algebraic Expressions',
        'content': '''
# Algebraic Expressions

## What is an Algebraic Expression?

An algebraic expression is a mathematical phrase that contains:
- Numbers
- Variables
- Operations (+, -, ×, ÷)

### Examples:
- 3x + 5
- 2y - 7
- 4a + 3b - 2

## Parts of an Expression:

**Terms**: Parts separated by + or - signs
- In 3x + 5, there are 2 terms: 3x and 5

**Coefficients**: Numbers multiplied by variables
- In 3x, the coefficient is 3

**Constants**: Numbers without variables
- In 3x + 5, the constant is 5

## Practice:
Identify the terms, coefficients, and constants in:
1. 5x + 8
2. 2a - 3b + 7
3. 4y - 9
        ''',
        'videoUrl': 'https://example.com/video2',
        'isCompleted': true,
        'duration': '20 min',
        'attachments': ['expressions_guide.pdf'],
      },
      {
        'id': 3,
        'moduleId': 4,
        'title': 'Lesson 3: Simplifying Expressions',
        'content': '''
# Simplifying Expressions

## Combining Like Terms

Like terms have the same variable raised to the same power.

### Examples of Like Terms:
- 3x and 5x (both have x)
- 2y² and 7y² (both have y²)

### Examples of Unlike Terms:
- 3x and 5y (different variables)
- 2x and 3x² (different powers)

## How to Simplify:

1. Identify like terms
2. Add or subtract their coefficients
3. Keep the variable part the same

### Example:
3x + 5x = 8x
7y - 2y = 5y
4a + 3b - 2a = 2a + 3b

## Practice Problems:
Simplify these expressions:
1. 5x + 3x
2. 8y - 3y + 2y
3. 4a + 2b - a + 3b
        ''',
        'videoUrl': null,
        'isCompleted': true,
        'duration': '18 min',
        'attachments': ['simplifying_worksheet.pdf', 'answer_key.pdf'],
      },
      {
        'id': 4,
        'moduleId': 4,
        'title': 'Lesson 4: Evaluating Expressions',
        'content': '''
# Evaluating Expressions

## What Does "Evaluate" Mean?

To evaluate an expression means to find its value when we know what the variables represent.

## Steps to Evaluate:

1. Replace each variable with its given value
2. Follow the order of operations (PEMDAS)
3. Calculate the result

### Example:
Evaluate 3x + 5 when x = 4

Step 1: Replace x with 4
3(4) + 5

Step 2: Multiply first
12 + 5

Step 3: Add
= 17

## More Examples:

1. Evaluate 2y - 7 when y = 10
   2(10) - 7 = 20 - 7 = 13

2. Evaluate 4a + 3b when a = 2 and b = 5
   4(2) + 3(5) = 8 + 15 = 23

## Practice:
Evaluate these expressions:
1. 5x + 3 when x = 6
2. 2a - 4b when a = 8 and b = 3
3. 3y² + 2y when y = 4
        ''',
        'videoUrl': 'https://example.com/video4',
        'isCompleted': false,
        'duration': '22 min',
        'attachments': ['evaluation_practice.pdf'],
      },
      {
        'id': 5,
        'moduleId': 4,
        'title': 'Lesson 5: Writing Expressions from Word Problems',
        'content': '''
# Writing Expressions from Word Problems

## Translating Words to Math

Learning to write algebraic expressions from word problems is an important skill.

## Common Phrases:

**Addition (+)**
- sum of
- more than
- increased by
- total

**Subtraction (-)**
- difference of
- less than
- decreased by
- minus

**Multiplication (×)**
- product of
- times
- multiplied by
- of (with fractions)

**Division (÷)**
- quotient of
- divided by
- ratio of

## Examples:

1. "Five more than a number x"
   → x + 5

2. "Three times a number y"
   → 3y

3. "The difference between a number a and 7"
   → a - 7

4. "Twice a number plus 8"
   → 2x + 8

## Practice:
Write expressions for:
1. Seven less than a number n
2. The product of 4 and a number m
3. A number divided by 3, plus 5
4. Three times a number, decreased by 2
        ''',
        'videoUrl': 'https://example.com/video5',
        'isCompleted': false,
        'duration': '25 min',
        'attachments': ['word_problems_guide.pdf', 'practice_sheet.pdf'],
      },
      {
        'id': 6,
        'moduleId': 4,
        'title': 'Lesson 6: Module 4 Quiz',
        'content': '''
# Module 4 Quiz: Basic Algebra

## Instructions:
Complete all questions to test your understanding of basic algebra concepts.

## Questions:

### Part 1: Multiple Choice (5 points each)

1. What is a variable?
   a) A number that never changes
   b) A symbol that represents an unknown value
   c) Always equal to zero
   d) A type of equation

2. In the expression 5x + 3, what is the coefficient?
   a) x
   b) 3
   c) 5
   d) 5x

3. Simplify: 7y + 3y
   a) 10y
   b) 10y²
   c) 21y
   d) 7y + 3y

### Part 2: Simplify (10 points each)

4. 4a + 2a - 3a = ?
5. 5x + 3y - 2x + y = ?

### Part 3: Evaluate (10 points each)

6. Evaluate 3x + 7 when x = 5
7. Evaluate 2a - 3b when a = 8 and b = 2

### Part 4: Word Problems (15 points each)

8. Write an expression for "eight more than twice a number n"
9. Write an expression for "the difference between a number x and 12"

## Submission:
Complete the quiz and submit your answers through the assignment portal.

**Time Limit**: 45 minutes
**Passing Score**: 70%
        ''',
        'videoUrl': null,
        'isCompleted': false,
        'duration': '45 min',
        'attachments': ['quiz_answer_sheet.pdf'],
      },
    ],
  };

  // Get filtered courses
  List<Map<String, dynamic>> getFilteredCourses() {
    var filtered = _enrolledCourses.where((course) {
      // Search filter
      final matchesSearch = course['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          course['code']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Progress filter
      bool matchesFilter = true;
      if (_selectedFilter == 'In Progress') {
        matchesFilter = course['progress'] < 100;
      } else if (_selectedFilter == 'Completed') {
        matchesFilter = course['progress'] >= 100;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return filtered;
  }

  // Get modules for a course
  List<Map<String, dynamic>> getModulesForCourse(int courseId) {
    return _courseModules[courseId] ?? [];
  }

  // Get lessons for a module
  List<Map<String, dynamic>> getLessonsForModule(int moduleId) {
    return _moduleLessons[moduleId] ?? [];
  }

  // Get course by ID
  Map<String, dynamic>? getCourseById(int courseId) {
    try {
      return _enrolledCourses.firstWhere((course) => course['id'] == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get lesson by ID
  Map<String, dynamic>? getLessonById(int lessonId) {
    for (var lessons in _moduleLessons.values) {
      try {
        return lessons.firstWhere((lesson) => lesson['id'] == lessonId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Update filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // Select course
  void selectCourse(int courseId) {
    _selectedCourseId = courseId;
    notifyListeners();
  }

  // Select module
  void selectModule(int moduleId) {
    _selectedModuleId = moduleId;
    notifyListeners();
  }

  // Select lesson
  void selectLesson(int lessonId) {
    _selectedLessonId = lessonId;
    notifyListeners();
  }

  // Load courses
  Future<void> loadCourses() async {
    _isLoadingCourses = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation:
    // final enrollments = await EnrollmentService.getEnrollmentsByStudent(studentId);
    // final courseIds = enrollments.map((e) => e.courseId).toList();
    // final courses = await CourseService.getCoursesByIds(courseIds);

    _isLoadingCourses = false;
    notifyListeners();
  }

  // Load modules for course
  Future<void> loadModules(int courseId) async {
    _isLoadingModules = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // In real implementation:
    // final modules = await CourseModuleService.getModulesByCourse(courseId);

    _isLoadingModules = false;
    notifyListeners();
  }

  // Load lesson content
  Future<void> loadLesson(int lessonId) async {
    _isLoadingLesson = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // In real implementation:
    // final lesson = await LessonService.getLessonById(lessonId);

    _isLoadingLesson = false;
    notifyListeners();
  }

  // Mark lesson as completed
  Future<void> markLessonCompleted(int lessonId) async {
    // Find and update lesson
    for (var lessons in _moduleLessons.values) {
      for (var lesson in lessons) {
        if (lesson['id'] == lessonId) {
          lesson['isCompleted'] = true;
          
          // Update module completion
          final moduleId = lesson['moduleId'];
          _updateModuleCompletion(moduleId);
          
          // Update course completion
          _updateCourseCompletion();
          
          notifyListeners();
          break;
        }
      }
    }

    // In real implementation:
    // await ActivityLogService.logLessonView(studentId, lessonId);
    // await LessonProgressService.markAsCompleted(studentId, lessonId);
  }

  void _updateModuleCompletion(int moduleId) {
    for (var modules in _courseModules.values) {
      for (var module in modules) {
        if (module['id'] == moduleId) {
          final lessons = _moduleLessons[moduleId] ?? [];
          final completedCount = lessons.where((l) => l['isCompleted'] == true).length;
          module['completedLessons'] = completedCount;
          module['isCompleted'] = completedCount == module['totalLessons'];
        }
      }
    }
  }

  void _updateCourseCompletion() {
    for (var course in _enrolledCourses) {
      final courseId = course['id'];
      final modules = _courseModules[courseId] ?? [];
      
      int totalLessons = 0;
      int completedLessons = 0;
      int completedModules = 0;
      
      for (var module in modules) {
        totalLessons += module['totalLessons'] as int;
        completedLessons += module['completedLessons'] as int;
        if (module['isCompleted'] == true) {
          completedModules++;
        }
      }
      
      course['totalLessons'] = totalLessons;
      course['completedLessons'] = completedLessons;
      course['completedModules'] = completedModules;
      course['progress'] = totalLessons > 0 
          ? ((completedLessons / totalLessons) * 100).round() 
          : 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
