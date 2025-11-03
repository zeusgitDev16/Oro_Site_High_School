/// DepEd Official Forms Models
/// 
/// This file contains models for official DepEd forms:
/// - Form 137 (Permanent Record / SF10)
/// - Form 138 (Report Card / SF9)
/// - SF1 (School Register)
/// - SF2 (Daily Attendance Report)
/// - SF3 (Learner's Attendance Record)
/// - SF4 (Class Record)
/// - SF5 (Report on Promotion and Level of Proficiency)
/// - SF6 (Learner's Progress Report)
/// - SF7 (School Form 7 - Learner's Basic Data)
/// - SF8 (Learner's Contact Information)

/// Form 137 - Permanent Record (SF10)
/// Official record of student's academic history
class Form137 {
  final String id;
  final String studentId;
  final String studentLrn;
  
  // Student Information
  final String lastName;
  final String firstName;
  final String middleName;
  final String? suffix;
  final DateTime birthDate;
  final String birthPlace;
  final String gender;
  
  // Parent/Guardian Information
  final String? motherName;
  final String? fatherName;
  final String? guardianName;
  final String? guardianRelationship;
  
  // School Information
  final String schoolName;
  final String schoolId;
  final String schoolAddress;
  final String district;
  final String division;
  final String region;
  
  // Academic Records (by school year)
  final List<Form137AcademicRecord> academicRecords;
  
  // Scholastic Record
  final List<Form137ScholasticRecord> scholasticRecords;
  
  // Certification
  final String? certifiedBy;
  final String? certifiedByPosition;
  final DateTime? certificationDate;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Form137({
    required this.id,
    required this.studentId,
    required this.studentLrn,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    this.suffix,
    required this.birthDate,
    required this.birthPlace,
    required this.gender,
    this.motherName,
    this.fatherName,
    this.guardianName,
    this.guardianRelationship,
    required this.schoolName,
    required this.schoolId,
    required this.schoolAddress,
    required this.district,
    required this.division,
    required this.region,
    required this.academicRecords,
    required this.scholasticRecords,
    this.certifiedBy,
    this.certifiedByPosition,
    this.certificationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'suffix': suffix,
      'birth_date': birthDate.toIso8601String(),
      'birth_place': birthPlace,
      'gender': gender,
      'mother_name': motherName,
      'father_name': fatherName,
      'guardian_name': guardianName,
      'guardian_relationship': guardianRelationship,
      'school_name': schoolName,
      'school_id': schoolId,
      'school_address': schoolAddress,
      'district': district,
      'division': division,
      'region': region,
      'academic_records': academicRecords.map((r) => r.toJson()).toList(),
      'scholastic_records': scholasticRecords.map((r) => r.toJson()).toList(),
      'certified_by': certifiedBy,
      'certified_by_position': certifiedByPosition,
      'certification_date': certificationDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Form137.fromJson(Map<String, dynamic> json) {
    return Form137(
      id: json['id'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      suffix: json['suffix'],
      birthDate: DateTime.parse(json['birth_date']),
      birthPlace: json['birth_place'],
      gender: json['gender'],
      motherName: json['mother_name'],
      fatherName: json['father_name'],
      guardianName: json['guardian_name'],
      guardianRelationship: json['guardian_relationship'],
      schoolName: json['school_name'],
      schoolId: json['school_id'],
      schoolAddress: json['school_address'],
      district: json['district'],
      division: json['division'],
      region: json['region'],
      academicRecords: (json['academic_records'] as List)
          .map((r) => Form137AcademicRecord.fromJson(r))
          .toList(),
      scholasticRecords: (json['scholastic_records'] as List)
          .map((r) => Form137ScholasticRecord.fromJson(r))
          .toList(),
      certifiedBy: json['certified_by'],
      certifiedByPosition: json['certified_by_position'],
      certificationDate: json['certification_date'] != null
          ? DateTime.parse(json['certification_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Academic Record entry for Form 137
class Form137AcademicRecord {
  final String schoolYear;
  final int gradeLevel;
  final String section;
  final String schoolName;
  final String schoolId;
  final String? remarks; // PROMOTED, RETAINED, etc.

  Form137AcademicRecord({
    required this.schoolYear,
    required this.gradeLevel,
    required this.section,
    required this.schoolName,
    required this.schoolId,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'school_year': schoolYear,
      'grade_level': gradeLevel,
      'section': section,
      'school_name': schoolName,
      'school_id': schoolId,
      'remarks': remarks,
    };
  }

  factory Form137AcademicRecord.fromJson(Map<String, dynamic> json) {
    return Form137AcademicRecord(
      schoolYear: json['school_year'],
      gradeLevel: json['grade_level'],
      section: json['section'],
      schoolName: json['school_name'],
      schoolId: json['school_id'],
      remarks: json['remarks'],
    );
  }
}

/// Scholastic Record entry for Form 137
class Form137ScholasticRecord {
  final String schoolYear;
  final int gradeLevel;
  final String subject;
  final double? quarter1;
  final double? quarter2;
  final double? quarter3;
  final double? quarter4;
  final double finalGrade;
  final String remarks; // PASSED, FAILED, INC, etc.

  Form137ScholasticRecord({
    required this.schoolYear,
    required this.gradeLevel,
    required this.subject,
    this.quarter1,
    this.quarter2,
    this.quarter3,
    this.quarter4,
    required this.finalGrade,
    required this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'school_year': schoolYear,
      'grade_level': gradeLevel,
      'subject': subject,
      'quarter_1': quarter1,
      'quarter_2': quarter2,
      'quarter_3': quarter3,
      'quarter_4': quarter4,
      'final_grade': finalGrade,
      'remarks': remarks,
    };
  }

  factory Form137ScholasticRecord.fromJson(Map<String, dynamic> json) {
    return Form137ScholasticRecord(
      schoolYear: json['school_year'],
      gradeLevel: json['grade_level'],
      subject: json['subject'],
      quarter1: json['quarter_1']?.toDouble(),
      quarter2: json['quarter_2']?.toDouble(),
      quarter3: json['quarter_3']?.toDouble(),
      quarter4: json['quarter_4']?.toDouble(),
      finalGrade: (json['final_grade'] as num).toDouble(),
      remarks: json['remarks'],
    );
  }
}

/// Form 138 - Report Card (SF9)
/// Quarterly report card for students
class Form138 {
  final String id;
  final String studentId;
  final String studentLrn;
  final String studentName;
  final String schoolYear;
  final int gradeLevel;
  final String section;
  final String adviser;
  
  // Quarter grades by subject
  final List<Form138SubjectGrade> subjectGrades;
  
  // Core values (1-4 scale)
  final Map<String, int>? coreValues; // Respect, Excellence, Teamwork, etc.
  
  // Behavior indicators
  final Map<String, String>? behaviorIndicators;
  
  // Attendance
  final int? daysOfSchool;
  final int? daysPresent;
  final int? daysAbsent;
  final int? timesLate;
  
  // Remarks
  final String? teacherRemarks;
  final String? parentRemarks;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Form138({
    required this.id,
    required this.studentId,
    required this.studentLrn,
    required this.studentName,
    required this.schoolYear,
    required this.gradeLevel,
    required this.section,
    required this.adviser,
    required this.subjectGrades,
    this.coreValues,
    this.behaviorIndicators,
    this.daysOfSchool,
    this.daysPresent,
    this.daysAbsent,
    this.timesLate,
    this.teacherRemarks,
    this.parentRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'student_name': studentName,
      'school_year': schoolYear,
      'grade_level': gradeLevel,
      'section': section,
      'adviser': adviser,
      'subject_grades': subjectGrades.map((g) => g.toJson()).toList(),
      'core_values': coreValues,
      'behavior_indicators': behaviorIndicators,
      'days_of_school': daysOfSchool,
      'days_present': daysPresent,
      'days_absent': daysAbsent,
      'times_late': timesLate,
      'teacher_remarks': teacherRemarks,
      'parent_remarks': parentRemarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Form138.fromJson(Map<String, dynamic> json) {
    return Form138(
      id: json['id'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      studentName: json['student_name'],
      schoolYear: json['school_year'],
      gradeLevel: json['grade_level'],
      section: json['section'],
      adviser: json['adviser'],
      subjectGrades: (json['subject_grades'] as List)
          .map((g) => Form138SubjectGrade.fromJson(g))
          .toList(),
      coreValues: json['core_values'] != null
          ? Map<String, int>.from(json['core_values'])
          : null,
      behaviorIndicators: json['behavior_indicators'] != null
          ? Map<String, String>.from(json['behavior_indicators'])
          : null,
      daysOfSchool: json['days_of_school'],
      daysPresent: json['days_present'],
      daysAbsent: json['days_absent'],
      timesLate: json['times_late'],
      teacherRemarks: json['teacher_remarks'],
      parentRemarks: json['parent_remarks'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Subject grade entry for Form 138
class Form138SubjectGrade {
  final String subject;
  final double? quarter1;
  final double? quarter2;
  final double? quarter3;
  final double? quarter4;
  final double? finalGrade;
  final String? remarks;

  Form138SubjectGrade({
    required this.subject,
    this.quarter1,
    this.quarter2,
    this.quarter3,
    this.quarter4,
    this.finalGrade,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'quarter_1': quarter1,
      'quarter_2': quarter2,
      'quarter_3': quarter3,
      'quarter_4': quarter4,
      'final_grade': finalGrade,
      'remarks': remarks,
    };
  }

  factory Form138SubjectGrade.fromJson(Map<String, dynamic> json) {
    return Form138SubjectGrade(
      subject: json['subject'],
      quarter1: json['quarter_1']?.toDouble(),
      quarter2: json['quarter_2']?.toDouble(),
      quarter3: json['quarter_3']?.toDouble(),
      quarter4: json['quarter_4']?.toDouble(),
      finalGrade: json['final_grade']?.toDouble(),
      remarks: json['remarks'],
    );
  }
}

/// SF2 - Daily Attendance Report
class SF2DailyAttendance {
  final String id;
  final DateTime date;
  final String schoolYear;
  final int gradeLevel;
  final String section;
  
  // Attendance summary
  final int totalEnrolled;
  final int maleEnrolled;
  final int femaleEnrolled;
  
  final int presentMale;
  final int presentFemale;
  final int absentMale;
  final int absentFemale;
  final int lateMale;
  final int lateFemale;
  
  // Teacher information
  final String teacherId;
  final String teacherName;
  
  final DateTime createdAt;

  SF2DailyAttendance({
    required this.id,
    required this.date,
    required this.schoolYear,
    required this.gradeLevel,
    required this.section,
    required this.totalEnrolled,
    required this.maleEnrolled,
    required this.femaleEnrolled,
    required this.presentMale,
    required this.presentFemale,
    required this.absentMale,
    required this.absentFemale,
    required this.lateMale,
    required this.lateFemale,
    required this.teacherId,
    required this.teacherName,
    required this.createdAt,
  });

  int get totalPresent => presentMale + presentFemale;
  int get totalAbsent => absentMale + absentFemale;
  int get totalLate => lateMale + lateFemale;
  double get attendanceRate => 
      totalEnrolled > 0 ? (totalPresent / totalEnrolled) * 100 : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'school_year': schoolYear,
      'grade_level': gradeLevel,
      'section': section,
      'total_enrolled': totalEnrolled,
      'male_enrolled': maleEnrolled,
      'female_enrolled': femaleEnrolled,
      'present_male': presentMale,
      'present_female': presentFemale,
      'absent_male': absentMale,
      'absent_female': absentFemale,
      'late_male': lateMale,
      'late_female': lateFemale,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SF2DailyAttendance.fromJson(Map<String, dynamic> json) {
    return SF2DailyAttendance(
      id: json['id'],
      date: DateTime.parse(json['date']),
      schoolYear: json['school_year'],
      gradeLevel: json['grade_level'],
      section: json['section'],
      totalEnrolled: json['total_enrolled'],
      maleEnrolled: json['male_enrolled'],
      femaleEnrolled: json['female_enrolled'],
      presentMale: json['present_male'],
      presentFemale: json['present_female'],
      absentMale: json['absent_male'],
      absentFemale: json['absent_female'],
      lateMale: json['late_male'],
      lateFemale: json['late_female'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// DepEd Form Generation Status
enum FormGenerationStatus {
  pending,
  generating,
  completed,
  failed,
}

/// Form Generation Request
class FormGenerationRequest {
  final String id;
  final String formType; // 'form_137', 'form_138', 'sf2', etc.
  final String studentId;
  final String? schoolYear;
  final int? quarter;
  final FormGenerationStatus status;
  final String? fileUrl;
  final String? errorMessage;
  final String requestedBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  FormGenerationRequest({
    required this.id,
    required this.formType,
    required this.studentId,
    this.schoolYear,
    this.quarter,
    required this.status,
    this.fileUrl,
    this.errorMessage,
    required this.requestedBy,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_type': formType,
      'student_id': studentId,
      'school_year': schoolYear,
      'quarter': quarter,
      'status': status.toString().split('.').last,
      'file_url': fileUrl,
      'error_message': errorMessage,
      'requested_by': requestedBy,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory FormGenerationRequest.fromJson(Map<String, dynamic> json) {
    return FormGenerationRequest(
      id: json['id'],
      formType: json['form_type'],
      studentId: json['student_id'],
      schoolYear: json['school_year'],
      quarter: json['quarter'],
      status: FormGenerationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      fileUrl: json['file_url'],
      errorMessage: json['error_message'],
      requestedBy: json['requested_by'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}
