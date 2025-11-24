/// Model for subject modules (files)
class SubjectModule {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String filePath;
  final String fileName;
  final String fileType;
  final int? fileSize;
  final int moduleOrder;
  final bool isPublished;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectModule({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    this.fileSize,
    required this.moduleOrder,
    required this.isPublished,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubjectModule.fromJson(Map<String, dynamic> json) {
    return SubjectModule(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int?,
      moduleOrder: json['module_order'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'module_order': moduleOrder,
      'is_published': isPublished,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubjectModule copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    String? filePath,
    String? fileName,
    String? fileType,
    int? fileSize,
    int? moduleOrder,
    bool? isPublished,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModule(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      moduleOrder: moduleOrder ?? this.moduleOrder,
      isPublished: isPublished ?? this.isPublished,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

