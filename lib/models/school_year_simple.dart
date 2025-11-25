/// Simple School Year Model for School Year Selector
/// Represents a school year label in the system (e.g., 2023-2024)
/// This is different from the complex SchoolYear model used for academic calendar
class SchoolYearSimple {
  final String id;
  final String yearLabel; // Format: YYYY-YYYY (e.g., 2023-2024)
  final int startYear; // Starting year (e.g., 2023)
  final int endYear; // Ending year (e.g., 2024)
  final bool isActive; // Whether this school year is active
  final bool isCurrent; // Whether this is the current school year
  final String? createdBy; // User ID who created this school year
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolYearSimple({
    required this.id,
    required this.yearLabel,
    required this.startYear,
    required this.endYear,
    required this.isActive,
    required this.isCurrent,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create SchoolYearSimple from JSON
  factory SchoolYearSimple.fromJson(Map<String, dynamic> json) {
    return SchoolYearSimple(
      id: json['id'] as String,
      yearLabel: json['year_label'] as String,
      startYear: json['start_year'] as int,
      endYear: json['end_year'] as int,
      isActive: json['is_active'] as bool? ?? true,
      isCurrent: json['is_current'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert SchoolYearSimple to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'year_label': yearLabel,
      'start_year': startYear,
      'end_year': endYear,
      'is_active': isActive,
      'is_current': isCurrent,
      'created_by': createdBy,
    };
  }

  /// Create a copy with updated fields
  SchoolYearSimple copyWith({
    String? id,
    String? yearLabel,
    int? startYear,
    int? endYear,
    bool? isActive,
    bool? isCurrent,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolYearSimple(
      id: id ?? this.id,
      yearLabel: yearLabel ?? this.yearLabel,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      isActive: isActive ?? this.isActive,
      isCurrent: isCurrent ?? this.isCurrent,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SchoolYearSimple(id: $id, yearLabel: $yearLabel, isCurrent: $isCurrent, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SchoolYearSimple &&
        other.id == id &&
        other.yearLabel == yearLabel &&
        other.startYear == startYear &&
        other.endYear == endYear &&
        other.isActive == isActive &&
        other.isCurrent == isCurrent &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      yearLabel,
      startYear,
      endYear,
      isActive,
      isCurrent,
      createdBy,
    );
  }
}

