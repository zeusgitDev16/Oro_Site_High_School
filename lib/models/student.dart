/// DepEd-Compliant Student Model
/// Includes Learner Reference Number (LRN) as required by DepEd
/// 
/// LRN Format: 12-digit number (e.g., 123456789012)
/// LRN is the primary identifier for students in the Philippine education system

class Student {
  final String id;
  final String lrn; // Learner Reference Number (12 digits, required)
  final String firstName;
  final String middleName;
  final String lastName;
  final String? suffix; // Jr., Sr., III, etc.
  final DateTime birthDate;
  final String gender; // 'M' or 'F'
  final String? birthPlace;
  
  // Contact Information
  final String? email;
  final String? contactNumber;
  final String? address;
  final String? barangay;
  final String? municipality;
  final String? province;
  final String? zipCode;
  
  // Academic Information
  final int gradeLevel; // 7-12
  final String? sectionId;
  final String? sectionName;
  final String? track; // For Senior High: STEM, ABM, HUMSS, TVL
  final String? strand; // Specific strand within track
  final String schoolYear; // e.g., "2023-2024"
  
  // DepEd-Specific Fields
  final String? motherTongue; // For MTB-MLE (Mother Tongue-Based Multilingual Education)
  final String? indigenousPeople; // IP affiliation if applicable
  final bool is4PsBeneficiary; // Pantawid Pamilyang Pilipino Program
  final String? learnerType; // 'Regular', 'Transferee', 'Balik-Aral', etc.
  
  // Parent/Guardian Information
  final String? motherName;
  final String? motherOccupation;
  final String? motherContact;
  final String? fatherName;
  final String? fatherOccupation;
  final String? fatherContact;
  final String? guardianName;
  final String? guardianRelationship;
  final String? guardianContact;
  
  // System Fields
  final String? userId; // Link to auth user
  final String status; // 'active', 'inactive', 'transferred', 'graduated'
  final DateTime enrollmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.lrn,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.suffix,
    required this.birthDate,
    required this.gender,
    this.birthPlace,
    this.email,
    this.contactNumber,
    this.address,
    this.barangay,
    this.municipality,
    this.province,
    this.zipCode,
    required this.gradeLevel,
    this.sectionId,
    this.sectionName,
    this.track,
    this.strand,
    required this.schoolYear,
    this.motherTongue,
    this.indigenousPeople,
    this.is4PsBeneficiary = false,
    this.learnerType,
    this.motherName,
    this.motherOccupation,
    this.motherContact,
    this.fatherName,
    this.fatherOccupation,
    this.fatherContact,
    this.guardianName,
    this.guardianRelationship,
    this.guardianContact,
    this.userId,
    this.status = 'active',
    required this.enrollmentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full name
  String get fullName {
    final parts = [firstName, middleName, lastName, suffix]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    return parts;
  }

  /// Get last name, first name format
  String get lastNameFirst {
    return '$lastName, $firstName ${middleName.isNotEmpty ? middleName[0] : ""}.';
  }

  /// Validate LRN format (12 digits)
  static bool isValidLRN(String lrn) {
    return RegExp(r'^\d{12}$').hasMatch(lrn);
  }

  /// Check if student is in Junior High School (Grades 7-10)
  bool get isJuniorHigh => gradeLevel >= 7 && gradeLevel <= 10;

  /// Check if student is in Senior High School (Grades 11-12)
  bool get isSeniorHigh => gradeLevel >= 11 && gradeLevel <= 12;

  /// Get grade level name
  String get gradeLevelName {
    if (gradeLevel >= 11) {
      return 'Grade $gradeLevel - Senior High';
    }
    return 'Grade $gradeLevel';
  }

  /// Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lrn': lrn,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'suffix': suffix,
      'birth_date': birthDate.toIso8601String(),
      'gender': gender,
      'birth_place': birthPlace,
      'email': email,
      'contact_number': contactNumber,
      'address': address,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'zip_code': zipCode,
      'grade_level': gradeLevel,
      'section_id': sectionId,
      'section_name': sectionName,
      'track': track,
      'strand': strand,
      'school_year': schoolYear,
      'mother_tongue': motherTongue,
      'indigenous_people': indigenousPeople,
      'is_4ps_beneficiary': is4PsBeneficiary,
      'learner_type': learnerType,
      'mother_name': motherName,
      'mother_occupation': motherOccupation,
      'mother_contact': motherContact,
      'father_name': fatherName,
      'father_occupation': fatherOccupation,
      'father_contact': fatherContact,
      'guardian_name': guardianName,
      'guardian_relationship': guardianRelationship,
      'guardian_contact': guardianContact,
      'user_id': userId,
      'status': status,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      lrn: json['lrn'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      suffix: json['suffix'],
      birthDate: DateTime.parse(json['birth_date']),
      gender: json['gender'],
      birthPlace: json['birth_place'],
      email: json['email'],
      contactNumber: json['contact_number'],
      address: json['address'],
      barangay: json['barangay'],
      municipality: json['municipality'],
      province: json['province'],
      zipCode: json['zip_code'],
      gradeLevel: json['grade_level'],
      sectionId: json['section_id'],
      sectionName: json['section_name'],
      track: json['track'],
      strand: json['strand'],
      schoolYear: json['school_year'],
      motherTongue: json['mother_tongue'],
      indigenousPeople: json['indigenous_people'],
      is4PsBeneficiary: json['is_4ps_beneficiary'] ?? false,
      learnerType: json['learner_type'],
      motherName: json['mother_name'],
      motherOccupation: json['mother_occupation'],
      motherContact: json['mother_contact'],
      fatherName: json['father_name'],
      fatherOccupation: json['father_occupation'],
      fatherContact: json['father_contact'],
      guardianName: json['guardian_name'],
      guardianRelationship: json['guardian_relationship'],
      guardianContact: json['guardian_contact'],
      userId: json['user_id'],
      status: json['status'] ?? 'active',
      enrollmentDate: DateTime.parse(json['enrollment_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Copy with updated fields
  Student copyWith({
    String? id,
    String? lrn,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    DateTime? birthDate,
    String? gender,
    String? birthPlace,
    String? email,
    String? contactNumber,
    String? address,
    String? barangay,
    String? municipality,
    String? province,
    String? zipCode,
    int? gradeLevel,
    String? sectionId,
    String? sectionName,
    String? track,
    String? strand,
    String? schoolYear,
    String? motherTongue,
    String? indigenousPeople,
    bool? is4PsBeneficiary,
    String? learnerType,
    String? motherName,
    String? motherOccupation,
    String? motherContact,
    String? fatherName,
    String? fatherOccupation,
    String? fatherContact,
    String? guardianName,
    String? guardianRelationship,
    String? guardianContact,
    String? userId,
    String? status,
    DateTime? enrollmentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      lrn: lrn ?? this.lrn,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      birthPlace: birthPlace ?? this.birthPlace,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      zipCode: zipCode ?? this.zipCode,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      track: track ?? this.track,
      strand: strand ?? this.strand,
      schoolYear: schoolYear ?? this.schoolYear,
      motherTongue: motherTongue ?? this.motherTongue,
      indigenousPeople: indigenousPeople ?? this.indigenousPeople,
      is4PsBeneficiary: is4PsBeneficiary ?? this.is4PsBeneficiary,
      learnerType: learnerType ?? this.learnerType,
      motherName: motherName ?? this.motherName,
      motherOccupation: motherOccupation ?? this.motherOccupation,
      motherContact: motherContact ?? this.motherContact,
      fatherName: fatherName ?? this.fatherName,
      fatherOccupation: fatherOccupation ?? this.fatherOccupation,
      fatherContact: fatherContact ?? this.fatherContact,
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      guardianContact: guardianContact ?? this.guardianContact,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Student enrollment status
enum StudentStatus {
  active,
  inactive,
  transferred,
  graduated,
  dropped,
}

/// Learner types as per DepEd
enum LearnerType {
  regular,
  transferee,
  balikAral, // Returning student
  continuing,
  pept, // Philippine Educational Placement Test passer
  ale, // Alternative Learning System
}
