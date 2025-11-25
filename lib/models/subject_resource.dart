import 'resource_type.dart';

/// Model representing a subject resource (module, assignment resource, or assignment)
/// organized by quarter with versioning support
class SubjectResource {
  final String id;
  final String subjectId;
  final String resourceName;
  final ResourceType resourceType;
  final int quarter; // 1, 2, 3, or 4
  final String fileUrl;
  final String fileName;
  final int fileSize; // in bytes
  final String fileType; // pdf, docx, pptx, xlsx, png, jpeg, mp4
  final int version;
  final bool isLatestVersion;
  final String? previousVersionId;
  final int displayOrder;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? uploadedBy;

  SubjectResource({
    required this.id,
    required this.subjectId,
    required this.resourceName,
    required this.resourceType,
    required this.quarter,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.version = 1,
    this.isLatestVersion = true,
    this.previousVersionId,
    this.displayOrder = 0,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.uploadedBy,
  });

  /// Create from JSON (from database)
  factory SubjectResource.fromJson(Map<String, dynamic> json) {
    return SubjectResource(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      resourceName: json['resource_name'] as String,
      resourceType: ResourceType.fromString(json['resource_type'] as String),
      quarter: json['quarter'] as int,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int,
      fileType: json['file_type'] as String,
      version: json['version'] as int? ?? 1,
      isLatestVersion: json['is_latest_version'] as bool? ?? true,
      previousVersionId: json['previous_version_id'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
    );
  }

  /// Convert to JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'resource_name': resourceName,
      'resource_type': resourceType.value,
      'quarter': quarter,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
      'version': version,
      'is_latest_version': isLatestVersion,
      'previous_version_id': previousVersionId,
      'display_order': displayOrder,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'uploaded_by': uploadedBy,
    };
  }

  /// Create a copy with modified fields
  SubjectResource copyWith({
    String? id,
    String? subjectId,
    String? resourceName,
    ResourceType? resourceType,
    int? quarter,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    int? version,
    bool? isLatestVersion,
    String? previousVersionId,
    bool clearPreviousVersionId = false,
    int? displayOrder,
    String? description,
    bool clearDescription = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearCreatedBy = false,
    String? uploadedBy,
    bool clearUploadedBy = false,
  }) {
    return SubjectResource(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      resourceName: resourceName ?? this.resourceName,
      resourceType: resourceType ?? this.resourceType,
      quarter: quarter ?? this.quarter,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      version: version ?? this.version,
      isLatestVersion: isLatestVersion ?? this.isLatestVersion,
      previousVersionId: clearPreviousVersionId ? null : (previousVersionId ?? this.previousVersionId),
      displayOrder: displayOrder ?? this.displayOrder,
      description: clearDescription ? null : (description ?? this.description),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: clearCreatedBy ? null : (createdBy ?? this.createdBy),
      uploadedBy: clearUploadedBy ? null : (uploadedBy ?? this.uploadedBy),
    );
  }

  /// Get human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'SubjectResource(id: $id, name: $resourceName, type: ${resourceType.displayName}, quarter: $quarter, version: $version)';
  }
}

