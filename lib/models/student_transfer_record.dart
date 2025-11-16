// Student transfer/admission record for SF9.
// Backed by the `student_transfer_records` table and used
// for eligibility, admission, and transfer history fields
// on the official SF9 report card.

class StudentTransferRecord {
  final String id;
  final String studentId;
  final String schoolYear;

  // Admission / eligibility information
  final String? eligibilityForAdmissionGrade; // e.g., "Grade 8"
  final int? admittedGrade;
  final String? admittedSection;
  final DateTime? admissionDate;

  // Transfer-out / cancellation information
  final String? fromSchool;
  final String? toSchool;
  final String? canceledIn;
  final DateTime? cancellationDate;

  // Administrative metadata
  final String? createdBy;
  final String? approvedBy;
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  StudentTransferRecord({
    required this.id,
    required this.studentId,
    required this.schoolYear,
    this.eligibilityForAdmissionGrade,
    this.admittedGrade,
    this.admittedSection,
    this.admissionDate,
    this.fromSchool,
    this.toSchool,
    this.canceledIn,
    this.cancellationDate,
    this.createdBy,
    this.approvedBy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the learner has admission information recorded.
  bool get hasAdmissionInfo =>
      eligibilityForAdmissionGrade != null ||
      admittedGrade != null ||
      admittedSection != null ||
      admissionDate != null;

  /// True if there is a cancellation / transfer-out record.
  bool get hasCancellationInfo =>
      canceledIn != null || cancellationDate != null || toSchool != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'school_year': schoolYear,
      'eligibility_for_admission_grade': eligibilityForAdmissionGrade,
      'admitted_grade': admittedGrade,
      'admitted_section': admittedSection,
      'admission_date': admissionDate?.toIso8601String(),
      'from_school': fromSchool,
      'to_school': toSchool,
      'canceled_in': canceledIn,
      'cancellation_date': cancellationDate?.toIso8601String(),
      'created_by': createdBy,
      'approved_by': approvedBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudentTransferRecord.fromJson(Map<String, dynamic> json) {
    return StudentTransferRecord(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id'] as String,
      schoolYear: json['school_year'] as String,
      eligibilityForAdmissionGrade:
          json['eligibility_for_admission_grade'] as String?,
      admittedGrade: json['admitted_grade'] as int?,
      admittedSection: json['admitted_section'] as String?,
      admissionDate: json['admission_date'] != null
          ? DateTime.parse(json['admission_date'] as String)
          : null,
      fromSchool: json['from_school'] as String?,
      toSchool: json['to_school'] as String?,
      canceledIn: json['canceled_in'] as String?,
      cancellationDate: json['cancellation_date'] != null
          ? DateTime.parse(json['cancellation_date'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
