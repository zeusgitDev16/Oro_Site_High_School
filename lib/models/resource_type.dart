/// Enum representing the type of subject resource
/// 
/// - [module]: Learning materials uploaded by admins, accessible by all
/// - [assignmentResource]: Guidelines for teachers uploaded by admins, accessible by admins and teachers only
/// - [assignment]: Assignments uploaded by teachers, accessible by admins, teachers, and students
enum ResourceType {
  /// Learning materials for students (uploaded by admins)
  module('module', 'Module', 'Modules'),
  
  /// Assignment guidelines for teachers (uploaded by admins, teachers only)
  assignmentResource('assignment_resource', 'Assignment Resource', 'Assignment Resources'),
  
  /// Assignments for students (uploaded by teachers)
  assignment('assignment', 'Assignment', 'Assignments');

  const ResourceType(this.value, this.displayName, this.pluralName);

  /// Database value
  final String value;
  
  /// Display name for UI (singular)
  final String displayName;
  
  /// Display name for UI (plural)
  final String pluralName;

  /// Convert from database string value to enum
  static ResourceType fromString(String value) {
    switch (value) {
      case 'module':
        return ResourceType.module;
      case 'assignment_resource':
        return ResourceType.assignmentResource;
      case 'assignment':
        return ResourceType.assignment;
      default:
        throw ArgumentError('Invalid resource type: $value');
    }
  }

  /// Get storage folder name for this resource type
  String get folderName {
    switch (this) {
      case ResourceType.module:
        return 'modules';
      case ResourceType.assignmentResource:
        return 'assignment_resources';
      case ResourceType.assignment:
        return 'assignments';
    }
  }

  /// Check if this resource type can be uploaded by admins
  bool get canBeUploadedByAdmin {
    return this == ResourceType.module || this == ResourceType.assignmentResource;
  }

  /// Check if this resource type can be uploaded by teachers
  bool get canBeUploadedByTeacher {
    return this == ResourceType.assignment;
  }

  /// Check if this resource type is visible to students
  bool get visibleToStudents {
    return this == ResourceType.module || this == ResourceType.assignment;
  }

  /// Check if this resource type is visible to teachers
  bool get visibleToTeachers {
    return true; // Teachers can see all resource types
  }
}

