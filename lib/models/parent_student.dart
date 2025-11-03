/// Parent-Student Relationship Model
/// Manages the relationship between parents and their children
/// Supports multiple children per parent and multiple guardians per student

enum GuardianRelationship {
  mother,
  father,
  guardian,
  stepMother,
  stepFather,
  grandparent,
  aunt,
  uncle,
  sibling,
  other,
}

extension GuardianRelationshipExtension on GuardianRelationship {
  String get displayName {
    switch (this) {
      case GuardianRelationship.mother:
        return 'Mother';
      case GuardianRelationship.father:
        return 'Father';
      case GuardianRelationship.guardian:
        return 'Guardian';
      case GuardianRelationship.stepMother:
        return 'Step-Mother';
      case GuardianRelationship.stepFather:
        return 'Step-Father';
      case GuardianRelationship.grandparent:
        return 'Grandparent';
      case GuardianRelationship.aunt:
        return 'Aunt';
      case GuardianRelationship.uncle:
        return 'Uncle';
      case GuardianRelationship.sibling:
        return 'Sibling';
      case GuardianRelationship.other:
        return 'Other';
    }
  }

  String get code {
    switch (this) {
      case GuardianRelationship.mother:
        return 'mother';
      case GuardianRelationship.father:
        return 'father';
      case GuardianRelationship.guardian:
        return 'guardian';
      case GuardianRelationship.stepMother:
        return 'step_mother';
      case GuardianRelationship.stepFather:
        return 'step_father';
      case GuardianRelationship.grandparent:
        return 'grandparent';
      case GuardianRelationship.aunt:
        return 'aunt';
      case GuardianRelationship.uncle:
        return 'uncle';
      case GuardianRelationship.sibling:
        return 'sibling';
      case GuardianRelationship.other:
        return 'other';
    }
  }

  static GuardianRelationship fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'mother':
        return GuardianRelationship.mother;
      case 'father':
        return GuardianRelationship.father;
      case 'guardian':
        return GuardianRelationship.guardian;
      case 'step_mother':
        return GuardianRelationship.stepMother;
      case 'step_father':
        return GuardianRelationship.stepFather;
      case 'grandparent':
        return GuardianRelationship.grandparent;
      case 'aunt':
        return GuardianRelationship.aunt;
      case 'uncle':
        return GuardianRelationship.uncle;
      case 'sibling':
        return GuardianRelationship.sibling;
      default:
        return GuardianRelationship.other;
    }
  }
}

/// Parent-Student Relationship Model
class ParentStudent {
  final String id;
  final String parentId; // User ID of the parent
  final String studentId; // User ID of the student
  final String studentLrn; // Student's LRN for easy reference
  
  // Relationship details
  final GuardianRelationship relationship;
  final bool isPrimaryGuardian; // Primary contact for the student
  final bool canViewGrades; // Permission to view grades
  final bool canViewAttendance; // Permission to view attendance
  final bool canReceiveSms; // Should receive SMS notifications
  final bool canContactTeachers; // Can send messages to teachers
  
  // Student information (denormalized for quick access)
  final String studentFirstName;
  final String studentLastName;
  final String studentMiddleName;
  final int studentGradeLevel;
  final String? studentSection;
  final String? studentPhotoUrl;
  
  // Parent information (denormalized for quick access)
  final String parentFirstName;
  final String parentLastName;
  final String? parentEmail;
  final String? parentPhone;
  
  // Status
  final bool isActive;
  final DateTime? verifiedAt; // When the relationship was verified
  final String? verifiedBy; // Admin who verified the relationship
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentStudent({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.studentLrn,
    required this.relationship,
    required this.isPrimaryGuardian,
    this.canViewGrades = true,
    this.canViewAttendance = true,
    this.canReceiveSms = true,
    this.canContactTeachers = true,
    required this.studentFirstName,
    required this.studentLastName,
    required this.studentMiddleName,
    required this.studentGradeLevel,
    this.studentSection,
    this.studentPhotoUrl,
    required this.parentFirstName,
    required this.parentLastName,
    this.parentEmail,
    this.parentPhone,
    this.isActive = true,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get student's full name
  String get studentFullName {
    final middle = studentMiddleName.isNotEmpty ? ' $studentMiddleName' : '';
    return '$studentFirstName$middle $studentLastName';
  }

  /// Get parent's full name
  String get parentFullName {
    return '$parentFirstName $parentLastName';
  }

  /// Get student display name with grade level
  String get studentDisplayName {
    return '$studentFullName (Grade $studentGradeLevel)';
  }

  /// Check if relationship is verified
  bool get isVerified => verifiedAt != null;

  /// Check if parent can access student data
  bool get hasAccess => isActive && (isVerified || isPrimaryGuardian);

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'relationship': relationship.code,
      'is_primary_guardian': isPrimaryGuardian,
      'can_view_grades': canViewGrades,
      'can_view_attendance': canViewAttendance,
      'can_receive_sms': canReceiveSms,
      'can_contact_teachers': canContactTeachers,
      'student_first_name': studentFirstName,
      'student_last_name': studentLastName,
      'student_middle_name': studentMiddleName,
      'student_grade_level': studentGradeLevel,
      'student_section': studentSection,
      'student_photo_url': studentPhotoUrl,
      'parent_first_name': parentFirstName,
      'parent_last_name': parentLastName,
      'parent_email': parentEmail,
      'parent_phone': parentPhone,
      'is_active': isActive,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ParentStudent.fromJson(Map<String, dynamic> json) {
    return ParentStudent(
      id: json['id'],
      parentId: json['parent_id'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      relationship: GuardianRelationshipExtension.fromCode(json['relationship']),
      isPrimaryGuardian: json['is_primary_guardian'] ?? false,
      canViewGrades: json['can_view_grades'] ?? true,
      canViewAttendance: json['can_view_attendance'] ?? true,
      canReceiveSms: json['can_receive_sms'] ?? true,
      canContactTeachers: json['can_contact_teachers'] ?? true,
      studentFirstName: json['student_first_name'],
      studentLastName: json['student_last_name'],
      studentMiddleName: json['student_middle_name'] ?? '',
      studentGradeLevel: json['student_grade_level'],
      studentSection: json['student_section'],
      studentPhotoUrl: json['student_photo_url'],
      parentFirstName: json['parent_first_name'],
      parentLastName: json['parent_last_name'],
      parentEmail: json['parent_email'],
      parentPhone: json['parent_phone'],
      isActive: json['is_active'] ?? true,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      verifiedBy: json['verified_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Copy with updated fields
  ParentStudent copyWith({
    String? id,
    String? parentId,
    String? studentId,
    String? studentLrn,
    GuardianRelationship? relationship,
    bool? isPrimaryGuardian,
    bool? canViewGrades,
    bool? canViewAttendance,
    bool? canReceiveSms,
    bool? canContactTeachers,
    String? studentFirstName,
    String? studentLastName,
    String? studentMiddleName,
    int? studentGradeLevel,
    String? studentSection,
    String? studentPhotoUrl,
    String? parentFirstName,
    String? parentLastName,
    String? parentEmail,
    String? parentPhone,
    bool? isActive,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentStudent(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      studentLrn: studentLrn ?? this.studentLrn,
      relationship: relationship ?? this.relationship,
      isPrimaryGuardian: isPrimaryGuardian ?? this.isPrimaryGuardian,
      canViewGrades: canViewGrades ?? this.canViewGrades,
      canViewAttendance: canViewAttendance ?? this.canViewAttendance,
      canReceiveSms: canReceiveSms ?? this.canReceiveSms,
      canContactTeachers: canContactTeachers ?? this.canContactTeachers,
      studentFirstName: studentFirstName ?? this.studentFirstName,
      studentLastName: studentLastName ?? this.studentLastName,
      studentMiddleName: studentMiddleName ?? this.studentMiddleName,
      studentGradeLevel: studentGradeLevel ?? this.studentGradeLevel,
      studentSection: studentSection ?? this.studentSection,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
      parentFirstName: parentFirstName ?? this.parentFirstName,
      parentLastName: parentLastName ?? this.parentLastName,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      isActive: isActive ?? this.isActive,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Parent with their children
class ParentWithChildren {
  final String parentId;
  final String parentName;
  final String? parentEmail;
  final String? parentPhone;
  final List<ParentStudent> children;

  ParentWithChildren({
    required this.parentId,
    required this.parentName,
    this.parentEmail,
    this.parentPhone,
    required this.children,
  });

  /// Get primary children (where parent is primary guardian)
  List<ParentStudent> get primaryChildren {
    return children.where((child) => child.isPrimaryGuardian).toList();
  }

  /// Get active children
  List<ParentStudent> get activeChildren {
    return children.where((child) => child.isActive).toList();
  }

  /// Get verified children
  List<ParentStudent> get verifiedChildren {
    return children.where((child) => child.isVerified).toList();
  }

  /// Check if parent has any children
  bool get hasChildren => children.isNotEmpty;

  /// Check if parent has active children
  bool get hasActiveChildren => activeChildren.isNotEmpty;
}