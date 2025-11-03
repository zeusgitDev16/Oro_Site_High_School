/// Model for section-adviser assignments
/// Represents the relationship between sections and their advisers
class SectionAssignment {
  final String id;
  final String sectionId;
  final String sectionName;
  final String adviserId;
  final String adviserName;
  final int gradeLevel;
  final int studentCount;
  final DateTime assignedDate;
  final String schoolYear;
  final String status; // 'active', 'completed', 'archived'
  final String? assignedBy; // Admin who made the assignment
  final String? room;
  final String? schedule;
  final String? notes;

  SectionAssignment({
    required this.id,
    required this.sectionId,
    required this.sectionName,
    required this.adviserId,
    required this.adviserName,
    required this.gradeLevel,
    required this.studentCount,
    required this.assignedDate,
    required this.schoolYear,
    required this.status,
    this.assignedBy,
    this.room,
    this.schedule,
    this.notes,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'section_name': sectionName,
      'adviser_id': adviserId,
      'adviser_name': adviserName,
      'grade_level': gradeLevel,
      'student_count': studentCount,
      'assigned_date': assignedDate.toIso8601String(),
      'school_year': schoolYear,
      'status': status,
      'assigned_by': assignedBy,
      'room': room,
      'schedule': schedule,
      'notes': notes,
    };
  }

  // Create from JSON
  factory SectionAssignment.fromJson(Map<String, dynamic> json) {
    return SectionAssignment(
      id: json['id'],
      sectionId: json['section_id'],
      sectionName: json['section_name'],
      adviserId: json['adviser_id'],
      adviserName: json['adviser_name'],
      gradeLevel: json['grade_level'],
      studentCount: json['student_count'],
      assignedDate: DateTime.parse(json['assigned_date']),
      schoolYear: json['school_year'],
      status: json['status'],
      assignedBy: json['assigned_by'],
      room: json['room'],
      schedule: json['schedule'],
      notes: json['notes'],
    );
  }

  // Copy with method for updates
  SectionAssignment copyWith({
    String? id,
    String? sectionId,
    String? sectionName,
    String? adviserId,
    String? adviserName,
    int? gradeLevel,
    int? studentCount,
    DateTime? assignedDate,
    String? schoolYear,
    String? status,
    String? assignedBy,
    String? room,
    String? schedule,
    String? notes,
  }) {
    return SectionAssignment(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      adviserId: adviserId ?? this.adviserId,
      adviserName: adviserName ?? this.adviserName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      studentCount: studentCount ?? this.studentCount,
      assignedDate: assignedDate ?? this.assignedDate,
      schoolYear: schoolYear ?? this.schoolYear,
      status: status ?? this.status,
      assignedBy: assignedBy ?? this.assignedBy,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      notes: notes ?? this.notes,
    );
  }
}
