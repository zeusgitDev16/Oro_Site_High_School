// Database Models
// Data models for all database tables

// ==================== USER & PROFILE MODELS ====================

/// Profile model
class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final int? roleId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.roleId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      roleId: json['role_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'role_id': roleId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Role model
class Role {
  final int id;
  final String name;
  final DateTime createdAt;

  Role({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== STUDENT MODELS ====================

/// Student model
class Student {
  final String id;
  final String lrn;
  final int gradeLevel;
  final String section;
  final bool isActive;
  final String? guardianName;
  final String? guardianContact;
  final String? address;
  final DateTime? birthDate;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.lrn,
    required this.gradeLevel,
    required this.section,
    this.isActive = true,
    this.guardianName,
    this.guardianContact,
    this.address,
    this.birthDate,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      lrn: json['lrn'],
      gradeLevel: json['grade_level'],
      section: json['section'],
      isActive: json['is_active'] ?? true,
      guardianName: json['guardian_name'],
      guardianContact: json['guardian_contact'],
      address: json['address'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lrn': lrn,
      'grade_level': gradeLevel,
      'section': section,
      'is_active': isActive,
      'guardian_name': guardianName,
      'guardian_contact': guardianContact,
      'address': address,
      'birth_date': birthDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Parent-Student relationship model
class ParentStudent {
  final int id;
  final String parentId;
  final String studentId;
  final String? studentLrn;
  final String? relationship;
  final bool isPrimaryGuardian;
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentMiddleName;
  final int? studentGradeLevel;
  final String? studentSection;
  final String? studentPhotoUrl;
  final String? parentFirstName;
  final String? parentLastName;
  final String? parentEmail;
  final String? parentPhone;
  final bool isActive;
  final bool canViewGrades;
  final bool canViewAttendance;
  final bool canReceiveSms;
  final bool canContactTeachers;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentStudent({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.studentLrn,
    this.relationship,
    this.isPrimaryGuardian = false,
    this.studentFirstName,
    this.studentLastName,
    this.studentMiddleName,
    this.studentGradeLevel,
    this.studentSection,
    this.studentPhotoUrl,
    this.parentFirstName,
    this.parentLastName,
    this.parentEmail,
    this.parentPhone,
    this.isActive = true,
    this.canViewGrades = true,
    this.canViewAttendance = true,
    this.canReceiveSms = true,
    this.canContactTeachers = true,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentStudent.fromJson(Map<String, dynamic> json) {
    return ParentStudent(
      id: json['id'],
      parentId: json['parent_id'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      relationship: json['relationship'],
      isPrimaryGuardian: json['is_primary_guardian'] ?? false,
      studentFirstName: json['student_first_name'],
      studentLastName: json['student_last_name'],
      studentMiddleName: json['student_middle_name'],
      studentGradeLevel: json['student_grade_level'],
      studentSection: json['student_section'],
      studentPhotoUrl: json['student_photo_url'],
      parentFirstName: json['parent_first_name'],
      parentLastName: json['parent_last_name'],
      parentEmail: json['parent_email'],
      parentPhone: json['parent_phone'],
      isActive: json['is_active'] ?? true,
      canViewGrades: json['can_view_grades'] ?? true,
      canViewAttendance: json['can_view_attendance'] ?? true,
      canReceiveSms: json['can_receive_sms'] ?? true,
      canContactTeachers: json['can_contact_teachers'] ?? true,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
      verifiedBy: json['verified_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'relationship': relationship,
      'is_primary_guardian': isPrimaryGuardian,
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
      'can_view_grades': canViewGrades,
      'can_view_attendance': canViewAttendance,
      'can_receive_sms': canReceiveSms,
      'can_contact_teachers': canContactTeachers,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ==================== COURSE MODELS ====================

/// Course model
class Course {
  final int id;
  final String name;
  final String? description;
  final String? teacherId;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.name,
    this.description,
    this.teacherId,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      teacherId: json['teacher_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Course Assignment model
class CourseAssignment {
  final int id;
  final String teacherId;
  final int courseId;
  final String status;
  final DateTime assignedAt;
  final DateTime createdAt;

  CourseAssignment({
    required this.id,
    required this.teacherId,
    required this.courseId,
    this.status = 'active',
    required this.assignedAt,
    required this.createdAt,
  });

  factory CourseAssignment.fromJson(Map<String, dynamic> json) {
    return CourseAssignment(
      id: json['id'],
      teacherId: json['teacher_id'],
      courseId: json['course_id'],
      status: json['status'] ?? 'active',
      assignedAt: DateTime.parse(json['assigned_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'course_id': courseId,
      'status': status,
      'assigned_at': assignedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Enrollment model
class Enrollment {
  final int id;
  final String studentId;
  final int courseId;
  final DateTime createdAt;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.createdAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== GRADE MODELS ====================

/// Grade model
class Grade {
  final int id;
  final int submissionId;
  final String graderId;
  final double score;
  final String? comments;
  final DateTime createdAt;

  Grade({
    required this.id,
    required this.submissionId,
    required this.graderId,
    required this.score,
    this.comments,
    required this.createdAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'],
      submissionId: json['submission_id'],
      graderId: json['grader_id'],
      score: (json['score'] as num).toDouble(),
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submission_id': submissionId,
      'grader_id': graderId,
      'score': score,
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== ATTENDANCE MODELS ====================

/// Attendance model
class Attendance {
  final int id;
  final String studentId;
  final int courseId;
  final DateTime date;
  final String status;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'date': date.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Attendance Session model
class AttendanceSession {
  final int id;
  final String teacherId;
  final int courseId;
  final DateTime sessionDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final String? qrCode;
  final int lateThresholdMinutes;
  final int totalStudents;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final DateTime createdAt;

  AttendanceSession({
    required this.id,
    required this.teacherId,
    required this.courseId,
    required this.sessionDate,
    required this.startTime,
    this.endTime,
    this.status = 'active',
    this.qrCode,
    this.lateThresholdMinutes = 15,
    this.totalStudents = 0,
    this.presentCount = 0,
    this.lateCount = 0,
    this.absentCount = 0,
    required this.createdAt,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'],
      teacherId: json['teacher_id'],
      courseId: json['course_id'],
      sessionDate: DateTime.parse(json['session_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      status: json['status'] ?? 'active',
      qrCode: json['qr_code'],
      lateThresholdMinutes: json['late_threshold_minutes'] ?? 15,
      totalStudents: json['total_students'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      lateCount: json['late_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'course_id': courseId,
      'session_date': sessionDate.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'qr_code': qrCode,
      'late_threshold_minutes': lateThresholdMinutes,
      'total_students': totalStudents,
      'present_count': presentCount,
      'late_count': lateCount,
      'absent_count': absentCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ==================== NOTIFICATION MODELS ====================

/// Notification model
class Notification {
  final int id;
  final String recipientId;
  final String content;
  final bool isRead;
  final String? link;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.recipientId,
    required this.content,
    this.isRead = false,
    this.link,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      recipientId: json['recipient_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      link: json['link'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'content': content,
      'is_read': isRead,
      'link': link,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Message model
class Message {
  final int id;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Announcement model
class Announcement {
  final int id;
  final int? courseId;
  final String title;
  final String content;
  final DateTime createdAt;

  Announcement({
    required this.id,
    this.courseId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}