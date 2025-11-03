/// SMS Notification System
/// Manages SMS notifications to parents/guardians
/// Integrates with SMS gateway providers (e.g., Semaphore, Twilio)

/// SMS Status
enum SMSStatus {
  pending,    // Queued for sending
  sending,    // Currently being sent
  sent,       // Successfully sent
  delivered,  // Delivered to recipient
  failed,     // Failed to send
  cancelled,  // Cancelled before sending
}

extension SMSStatusExtension on SMSStatus {
  String get displayName {
    switch (this) {
      case SMSStatus.pending:
        return 'Pending';
      case SMSStatus.sending:
        return 'Sending';
      case SMSStatus.sent:
        return 'Sent';
      case SMSStatus.delivered:
        return 'Delivered';
      case SMSStatus.failed:
        return 'Failed';
      case SMSStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// SMS Type
enum SMSType {
  attendance,      // Attendance alerts
  grade,          // Grade notifications
  announcement,   // School announcements
  reminder,       // General reminders
  emergency,      // Emergency alerts
  event,          // Event notifications
  remedial,       // Remedial class notifications
  meeting,        // Parent-teacher meeting
  custom,         // Custom message
}

extension SMSTypeExtension on SMSType {
  String get displayName {
    switch (this) {
      case SMSType.attendance:
        return 'Attendance Alert';
      case SMSType.grade:
        return 'Grade Notification';
      case SMSType.announcement:
        return 'Announcement';
      case SMSType.reminder:
        return 'Reminder';
      case SMSType.emergency:
        return 'Emergency Alert';
      case SMSType.event:
        return 'Event Notification';
      case SMSType.remedial:
        return 'Remedial Class';
      case SMSType.meeting:
        return 'Parent-Teacher Meeting';
      case SMSType.custom:
        return 'Custom Message';
    }
  }

  /// Get priority level (1-5, 5 being highest)
  int get priority {
    switch (this) {
      case SMSType.emergency:
        return 5;
      case SMSType.attendance:
        return 4;
      case SMSType.grade:
        return 3;
      case SMSType.meeting:
        return 3;
      case SMSType.remedial:
        return 3;
      case SMSType.announcement:
        return 2;
      case SMSType.event:
        return 2;
      case SMSType.reminder:
        return 2;
      case SMSType.custom:
        return 1;
    }
  }
}

/// SMS Notification Model
class SMSNotification {
  final String id;
  final String recipientPhone;
  final String recipientName;
  final String? studentId;
  final String? studentLrn;
  final String? studentName;
  
  // Message Details
  final SMSType type;
  final String message;
  final int messageLength;
  final int segmentCount; // SMS segments (160 chars per segment)
  
  // Status
  final SMSStatus status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  
  // Metadata
  final String? referenceId; // Reference to related record (grade, attendance, etc.)
  final String sentBy;
  final String sentByName;
  final double? cost; // SMS cost
  
  final DateTime createdAt;
  final DateTime updatedAt;

  SMSNotification({
    required this.id,
    required this.recipientPhone,
    required this.recipientName,
    this.studentId,
    this.studentLrn,
    this.studentName,
    required this.type,
    required this.message,
    required this.messageLength,
    required this.segmentCount,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.failureReason,
    this.referenceId,
    required this.sentBy,
    required this.sentByName,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate SMS segments (160 chars per segment)
  static int calculateSegments(String message) {
    return (message.length / 160).ceil();
  }

  /// Validate phone number (Philippine format)
  static bool isValidPhoneNumber(String phone) {
    // Remove spaces and special characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check Philippine mobile formats
    // +639XXXXXXXXX or 09XXXXXXXXX or 9XXXXXXXXX
    return RegExp(r'^(\+639|09|9)\d{9}$').hasMatch(cleaned);
  }

  /// Format phone number to standard format (+639XXXXXXXXX)
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.startsWith('09')) {
      return '+63${cleaned.substring(1)}';
    } else if (cleaned.startsWith('9') && cleaned.length == 10) {
      return '+63$cleaned';
    } else if (cleaned.startsWith('639')) {
      return '+$cleaned';
    }
    
    return phone; // Return original if format not recognized
  }

  /// Check if SMS is overdue (scheduled but not sent)
  bool get isOverdue {
    if (scheduledAt == null || status != SMSStatus.pending) return false;
    return DateTime.now().isAfter(scheduledAt!);
  }

  /// Get delivery time (time from sent to delivered)
  Duration? get deliveryTime {
    if (sentAt == null || deliveredAt == null) return null;
    return deliveredAt!.difference(sentAt!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'student_id': studentId,
      'student_lrn': studentLrn,
      'student_name': studentName,
      'type': type.toString().split('.').last,
      'message': message,
      'message_length': messageLength,
      'segment_count': segmentCount,
      'status': status.toString().split('.').last,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'failure_reason': failureReason,
      'reference_id': referenceId,
      'sent_by': sentBy,
      'sent_by_name': sentByName,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SMSNotification.fromJson(Map<String, dynamic> json) {
    return SMSNotification(
      id: json['id'],
      recipientPhone: json['recipient_phone'],
      recipientName: json['recipient_name'],
      studentId: json['student_id'],
      studentLrn: json['student_lrn'],
      studentName: json['student_name'],
      type: SMSType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      message: json['message'],
      messageLength: json['message_length'],
      segmentCount: json['segment_count'],
      status: SMSStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      failureReason: json['failure_reason'],
      referenceId: json['reference_id'],
      sentBy: json['sent_by'],
      sentByName: json['sent_by_name'],
      cost: json['cost']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// SMS Template
class SMSTemplate {
  final String id;
  final String name;
  final SMSType type;
  final String template; // Template with placeholders: {student_name}, {grade}, etc.
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SMSTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.template,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Replace placeholders in template
  String generateMessage(Map<String, String> variables) {
    String message = template;
    variables.forEach((key, value) {
      message = message.replaceAll('{$key}', value);
    });
    return message;
  }

  /// Get template variables
  List<String> get variables {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(template);
    return matches.map((m) => m.group(1)!).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'template': template,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SMSTemplate.fromJson(Map<String, dynamic> json) {
    return SMSTemplate(
      id: json['id'],
      name: json['name'],
      type: SMSType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      template: json['template'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Predefined SMS Templates
class SMSTemplates {
  // Attendance Templates
  static const String attendanceAbsent = 
      'Good day! Your child {student_name} was absent on {date}. Please contact the school if this is excused. - {school_name}';
  
  static const String attendanceLate = 
      'Good day! Your child {student_name} was late today ({time}). Please remind them about punctuality. - {school_name}';
  
  static const String attendanceConsecutiveAbsent = 
      'URGENT: Your child {student_name} has been absent for {days} consecutive days. Please contact the school immediately. - {school_name}';

  // Grade Templates
  static const String gradeQuarterlyReport = 
      'Good day! {student_name}\'s Quarter {quarter} grades are now available. Overall average: {average}. Please check the portal. - {school_name}';
  
  static const String gradeFailingAlert = 
      'ATTENTION: {student_name} is currently failing in {subject} with a grade of {grade}. Please schedule a meeting with the teacher. - {school_name}';
  
  static const String gradeHonorRoll = 
      'Congratulations! {student_name} made the honor roll with an average of {average}! Keep up the excellent work! - {school_name}';

  // Remedial Templates
  static const String remedialNotification = 
      'Your child {student_name} needs remedial classes for {subject}. Schedule: {schedule}. Please ensure attendance. - {school_name}';

  // Meeting Templates
  static const String meetingInvitation = 
      'You are invited to a parent-teacher conference on {date} at {time}. Topic: {topic}. Please confirm attendance. - {school_name}';

  // Event Templates
  static const String eventReminder = 
      'Reminder: {event_name} on {date}. {details}. - {school_name}';

  // Emergency Templates
  static const String emergencyAlert = 
      'EMERGENCY: {message}. Please contact the school immediately at {contact}. - {school_name}';
}

/// SMS Statistics
class SMSStatistics {
  final String period; // e.g., "January 2024"
  final int totalSent;
  final int totalDelivered;
  final int totalFailed;
  final double deliveryRate;
  final double totalCost;
  final Map<SMSType, int> byType;

  SMSStatistics({
    required this.period,
    required this.totalSent,
    required this.totalDelivered,
    required this.totalFailed,
    required this.deliveryRate,
    required this.totalCost,
    required this.byType,
  });

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'total_sent': totalSent,
      'total_delivered': totalDelivered,
      'total_failed': totalFailed,
      'delivery_rate': deliveryRate,
      'total_cost': totalCost,
      'by_type': byType.map((k, v) => MapEntry(k.toString().split('.').last, v)),
    };
  }
}
