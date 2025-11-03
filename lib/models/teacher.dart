/// Teacher Model
/// Represents teacher-specific information linked to profiles table
class Teacher {
  final String id; // UUID from profiles table
  final String employeeId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? department;
  final List<String> subjects;
  final bool isGradeCoordinator;
  final String? coordinatorGradeLevel;
  final bool isSHSTeacher;
  final String? shsTrack;
  final List<String>? shsStrands;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from profiles (if joined)
  final String? email;
  final String? fullName;
  final String? phone;

  Teacher({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.department,
    this.subjects = const [],
    this.isGradeCoordinator = false,
    this.coordinatorGradeLevel,
    this.isSHSTeacher = false,
    this.shsTrack,
    this.shsStrands,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.fullName,
    this.phone,
  });

  /// Create Teacher from database map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    // Handle subjects as JSONB array
    List<String> subjectsList = [];
    if (map['subjects'] != null) {
      if (map['subjects'] is List) {
        subjectsList = (map['subjects'] as List).map((e) => e.toString()).toList();
      } else if (map['subjects'] is String) {
        // If it's a JSON string, parse it
        try {
          final decoded = map['subjects'];
          if (decoded is List) {
            subjectsList = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          subjectsList = [];
        }
      }
    }

    // Handle SHS strands as JSONB array
    List<String>? strandsList;
    if (map['shs_strands'] != null) {
      if (map['shs_strands'] is List) {
        strandsList = (map['shs_strands'] as List).map((e) => e.toString()).toList();
      }
    }

    return Teacher(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      middleName: map['middle_name'] as String?,
      department: map['department'] as String?,
      subjects: subjectsList,
      isGradeCoordinator: map['is_grade_coordinator'] as bool? ?? false,
      coordinatorGradeLevel: map['coordinator_grade_level'] as String?,
      isSHSTeacher: map['is_shs_teacher'] as bool? ?? false,
      shsTrack: map['shs_track'] as String?,
      shsStrands: strandsList,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
    );
  }

  /// Convert Teacher to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'department': department,
      'subjects': subjects,
      'is_grade_coordinator': isGradeCoordinator,
      'coordinator_grade_level': coordinatorGradeLevel,
      'is_shs_teacher': isSHSTeacher,
      'shs_track': shsTrack,
      'shs_strands': shsStrands,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to map for INSERT (without id and timestamps)
  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'department': department,
      'subjects': subjects,
      'is_grade_coordinator': isGradeCoordinator,
      'coordinator_grade_level': coordinatorGradeLevel,
      'is_shs_teacher': isSHSTeacher,
      'shs_track': shsTrack,
      'shs_strands': shsStrands,
      'is_active': isActive,
    };
  }

  /// Get teacher's full name
  String get displayName {
    if (fullName != null) return fullName!;
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    return parts;
  }

  /// Get teacher's formal name (Last, First M.)
  String get formalName {
    final middle = middleName != null && middleName!.isNotEmpty
        ? ' ${middleName![0]}.'
        : '';
    return '$lastName, $firstName$middle';
  }

  /// Get subjects as comma-separated string
  String get subjectsDisplay {
    if (subjects.isEmpty) return 'No subjects assigned';
    return subjects.join(', ');
  }

  /// Get role description
  String get roleDescription {
    final roles = <String>[];
    if (isGradeCoordinator) {
      roles.add('Grade $coordinatorGradeLevel Coordinator');
    }
    if (isSHSTeacher) {
      roles.add('SHS Teacher');
      if (shsTrack != null) {
        roles.add('($shsTrack)');
      }
    }
    if (roles.isEmpty) {
      return 'Teacher';
    }
    return roles.join(' • ');
  }

  /// Check if teacher teaches a specific subject
  bool teachesSubject(String subject) {
    return subjects.any((s) => s.toLowerCase() == subject.toLowerCase());
  }

  /// Check if teacher is coordinator for a specific grade
  bool isCoordinatorFor(int gradeLevel) {
    return isGradeCoordinator &&
        coordinatorGradeLevel == gradeLevel.toString();
  }

  /// Copy with updated fields
  Teacher copyWith({
    String? id,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? middleName,
    String? department,
    List<String>? subjects,
    bool? isGradeCoordinator,
    String? coordinatorGradeLevel,
    bool? isSHSTeacher,
    String? shsTrack,
    List<String>? shsStrands,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? fullName,
    String? phone,
  }) {
    return Teacher(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      department: department ?? this.department,
      subjects: subjects ?? this.subjects,
      isGradeCoordinator: isGradeCoordinator ?? this.isGradeCoordinator,
      coordinatorGradeLevel: coordinatorGradeLevel ?? this.coordinatorGradeLevel,
      isSHSTeacher: isSHSTeacher ?? this.isSHSTeacher,
      shsTrack: shsTrack ?? this.shsTrack,
      shsStrands: shsStrands ?? this.shsStrands,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() {
    return 'Teacher(id: $id, name: $displayName, employeeId: $employeeId, subjects: ${subjects.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// SHS Tracks
class SHSTracks {
  static const String academic = 'Academic';
  static const String tvl = 'Technical-Vocational-Livelihood';
  static const String sports = 'Sports';
  static const String artsAndDesign = 'Arts and Design';

  static const List<String> all = [
    academic,
    tvl,
    sports,
    artsAndDesign,
  ];
}

/// SHS Academic Strands
class SHSStrands {
  static const String stem = 'STEM';
  static const String abm = 'ABM';
  static const String humss = 'HUMSS';
  static const String gas = 'GAS';

  static const List<String> academic = [
    stem,
    abm,
    humss,
    gas,
  ];

  static const List<String> tvl = [
    'Home Economics',
    'Agri-Fishery Arts',
    'Industrial Arts',
    'ICT',
  ];

  /// Get strands by track
  static List<String> getStrandsByTrack(String track) {
    switch (track) {
      case SHSTracks.academic:
        return academic;
      case SHSTracks.tvl:
        return tvl;
      default:
        return [];
    }
  }
}
