// SF9 Core Value Rating
// Represents a single behavior/core value rating entry per student,
// indicator, quarter, and school year.
//
// Backed by the `sf9_core_value_ratings` table in Supabase.

class SF9CoreValueRating {
  final String id;
  final String studentId;
  final String recordedBy;
  final String schoolYear;
  final int quarter; // 1-4

  /// Core value grouping (e.g., 'MAKA_DIYOS', 'MAKATAO', 'MAKAKALIKASAN', 'MAKABANSA').
  final String coreValueCode;

  /// Specific behavior indicator code (e.g., 'MD1', 'MT1', 'MK1', 'MB1').
  final String indicatorCode;

  /// Rating code: AO (Always), SO (Sometimes), RO (Rarely), NO (Not Observed).
  final String rating;

  final DateTime createdAt;
  final DateTime updatedAt;

  SF9CoreValueRating({
    required this.id,
    required this.studentId,
    required this.recordedBy,
    required this.schoolYear,
    required this.quarter,
    required this.coreValueCode,
    required this.indicatorCode,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Human-readable description for the rating code.
  String get ratingDescription => describeRating(rating);

  static String describeRating(String code) {
    switch (code) {
      case 'AO':
        return 'Always Observed';
      case 'SO':
        return 'Sometimes Observed';
      case 'RO':
        return 'Rarely Observed';
      case 'NO':
        return 'Not Observed';
      default:
        return code;
    }
  }

  /// Convert to JSON (Supabase row format).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'recorded_by': recordedBy,
      'school_year': schoolYear,
      'quarter': quarter,
      'core_value_code': coreValueCode,
      'indicator_code': indicatorCode,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Supabase row).
  factory SF9CoreValueRating.fromJson(Map<String, dynamic> json) {
    return SF9CoreValueRating(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id'] as String,
      recordedBy: json['recorded_by'] as String,
      schoolYear: json['school_year'] as String,
      quarter: json['quarter'] as int,
      coreValueCode: json['core_value_code'] as String,
      indicatorCode: json['indicator_code'] as String,
      rating: json['rating'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
