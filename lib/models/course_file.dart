/// Course File Model
/// Represents a file uploaded to a course (module or assignment resource)
class CourseFile {
  final String id;
  final String courseId;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'module' or 'assignment' - for UI purposes
  final String fileExtension;
  final int fileSize; // in bytes
  final String uploadedBy; // user ID
  final DateTime uploadedAt;

  CourseFile({
    required this.id,
    required this.courseId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileExtension,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  /// Create from JSON (works with both course_modules and course_assignments tables)
  factory CourseFile.fromJson(Map<String, dynamic> json, String fileType) {
    try {
      // Handle file_size - can be int or String
      int fileSize;
      final fileSizeValue = json['file_size'];
      if (fileSizeValue is int) {
        fileSize = fileSizeValue;
      } else if (fileSizeValue is String) {
        fileSize = int.parse(fileSizeValue);
      } else {
        print('⚠️ Unexpected file_size type: ${fileSizeValue.runtimeType}');
        fileSize = 0;
      }

      return CourseFile(
        id: json['id'].toString(),
        courseId: json['course_id'].toString(),
        fileName: json['file_name'] as String,
        fileUrl: json['file_url'] as String,
        fileType: fileType, // Passed from service layer
        fileExtension: json['file_extension'] as String,
        fileSize: fileSize,
        uploadedBy: json['uploaded_by'] as String,
        uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      );
    } catch (e) {
      print('❌ Error parsing CourseFile from JSON: $e');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  /// Convert to JSON (without file_type since it's determined by table)
  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  /// Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file icon based on extension
  String get fileIcon {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📽️';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'zip':
      case 'rar':
        return '📦';
      case 'txt':
        return '📃';
      default:
        return '📎';
    }
  }
}
