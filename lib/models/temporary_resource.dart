import 'resource_type.dart';

/// Temporary resource model for CREATE mode
/// Stores resource metadata and file path before classroom is created
class TemporaryResource {
  final String tempId; // Temporary UUID
  final String subjectId; // Temporary subject ID
  final String resourceName;
  final ResourceType resourceType;
  final int quarter; // 1, 2, 3, or 4
  final String filePath; // Local file path
  final String fileName;
  final int fileSize;
  final String fileType;
  final String? description;
  final DateTime createdAt;

  const TemporaryResource({
    required this.tempId,
    required this.subjectId,
    required this.resourceName,
    required this.resourceType,
    required this.quarter,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.description,
    required this.createdAt,
  });

  /// Convert to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'temp_id': tempId,
      'subject_id': subjectId,
      'resource_name': resourceName,
      'resource_type': resourceType.value,
      'quarter': quarter,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (SharedPreferences)
  factory TemporaryResource.fromJson(Map<String, dynamic> json) {
    return TemporaryResource(
      tempId: json['temp_id'] as String,
      subjectId: json['subject_id'] as String,
      resourceName: json['resource_name'] as String,
      resourceType: ResourceType.fromString(json['resource_type'] as String),
      quarter: json['quarter'] as int,
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int,
      fileType: json['file_type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Create a copy with updated fields
  TemporaryResource copyWith({
    String? tempId,
    String? subjectId,
    String? resourceName,
    ResourceType? resourceType,
    int? quarter,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? description,
    DateTime? createdAt,
  }) {
    return TemporaryResource(
      tempId: tempId ?? this.tempId,
      subjectId: subjectId ?? this.subjectId,
      resourceName: resourceName ?? this.resourceName,
      resourceType: resourceType ?? this.resourceType,
      quarter: quarter ?? this.quarter,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format file size for display
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'TemporaryResource(id: $tempId, name: $resourceName, type: ${resourceType.displayName}, quarter: $quarter)';
  }
}

