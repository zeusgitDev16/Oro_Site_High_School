import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_resource.dart';
import '../models/resource_type.dart';

/// Service for managing subject resources (modules, assignment resources, assignments)
class SubjectResourceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'subject_resources';
  static const String _bucketName = 'subject-resources';

  // ============================================
  // CRUD Operations
  // ============================================

  /// Get all resources for a subject
  Future<List<SubjectResource>> getResourcesBySubject(String subjectId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('subject_id', subjectId)
          .eq('is_active', true)
          .eq('is_latest_version', true)
          .order('quarter', ascending: true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => SubjectResource.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching resources for subject $subjectId: $e');
      rethrow;
    }
  }

  /// Get resources by subject and quarter
  Future<List<SubjectResource>> getResourcesByQuarter(
    String subjectId,
    int quarter,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('subject_id', subjectId)
          .eq('quarter', quarter)
          .eq('is_active', true)
          .eq('is_latest_version', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => SubjectResource.fromJson(json))
          .toList();
    } catch (e) {
      print(
        '❌ Error fetching resources for subject $subjectId, quarter $quarter: $e',
      );
      rethrow;
    }
  }

  /// Get resources by subject, quarter, and type
  Future<List<SubjectResource>> getResourcesByType(
    String subjectId,
    int quarter,
    ResourceType type,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('subject_id', subjectId)
          .eq('quarter', quarter)
          .eq('resource_type', type.value)
          .eq('is_active', true)
          .eq('is_latest_version', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => SubjectResource.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching ${type.displayName} resources: $e');
      rethrow;
    }
  }

  /// Get a single resource by ID
  Future<SubjectResource?> getResourceById(String resourceId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', resourceId)
          .maybeSingle();

      if (response == null) return null;
      return SubjectResource.fromJson(response);
    } catch (e) {
      print('❌ Error fetching resource $resourceId: $e');
      rethrow;
    }
  }

  /// Create a new resource
  Future<SubjectResource> createResource(SubjectResource resource) async {
    try {
      print('📝 Creating resource: ${resource.resourceName}');

      final response = await _supabase
          .from(_tableName)
          .insert(resource.toJson())
          .select()
          .single();

      print('✅ Resource created successfully');
      return SubjectResource.fromJson(response);
    } catch (e) {
      print('❌ Error creating resource: $e');
      rethrow;
    }
  }

  /// Update an existing resource
  Future<SubjectResource> updateResource(SubjectResource resource) async {
    try {
      print('📝 Updating resource: ${resource.resourceName}');

      final response = await _supabase
          .from(_tableName)
          .update(resource.toJson())
          .eq('id', resource.id)
          .select()
          .single();

      print('✅ Resource updated successfully');
      return SubjectResource.fromJson(response);
    } catch (e) {
      print('❌ Error updating resource: $e');
      rethrow;
    }
  }

  /// Delete a resource (soft delete by setting is_active to false)
  Future<void> deleteResource(String resourceId) async {
    try {
      print('🗑️ Deleting resource: $resourceId');

      await _supabase
          .from(_tableName)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', resourceId);

      print('✅ Resource deleted successfully');
    } catch (e) {
      print('❌ Error deleting resource: $e');
      rethrow;
    }
  }

  /// Hard delete a resource (permanently remove from database)
  Future<void> hardDeleteResource(String resourceId) async {
    try {
      print('🗑️ Hard deleting resource: $resourceId');

      await _supabase.from(_tableName).delete().eq('id', resourceId);

      print('✅ Resource hard deleted successfully');
    } catch (e) {
      print('❌ Error hard deleting resource: $e');
      rethrow;
    }
  }

  // ============================================
  // File Upload/Download Operations
  // ============================================

  /// Extract filename from path in a platform-independent way
  String _getFileName(String filePath) {
    // Split by both forward slash and backslash to handle all platforms
    final parts = filePath.split(RegExp(r'[/\\]'));
    return parts.last;
  }

  /// Upload a file to storage and return the file URL
  ///
  /// [file] - The file to upload
  /// [classroomId] - The classroom ID
  /// [subjectId] - The subject ID
  /// [quarter] - The quarter (1-4)
  /// [resourceType] - The type of resource
  /// [fileName] - Optional custom file name (uses original if not provided)
  Future<String> uploadFile({
    required File file,
    required String classroomId,
    required String subjectId,
    required int quarter,
    required ResourceType resourceType,
    String? fileName,
  }) async {
    try {
      print('');
      print('📤 [SERVICE] uploadFile called');
      print(
        '   fileName parameter: ${fileName ?? "(null - will extract from path)"}',
      );
      print('   file.path: ${file.path}');

      // CRITICAL: Use the provided fileName if available (from file picker)
      // Otherwise fallback to extracting from path (backward compatibility)
      final originalFileName = fileName ?? _getFileName(file.path);
      print('   Original filename to use: "$originalFileName"');

      // Add timestamp prefix to prevent filename conflicts in storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$originalFileName';
      print('   Unique filename for storage: "$uniqueFileName"');

      // Build storage path: {resource_type}/{classroom_id}/{subject_id}/q{quarter}/{filename}
      final storagePath =
          '${resourceType.folderName}/$classroomId/$subjectId/q$quarter/$uniqueFileName';

      print('   Storage path: $storagePath');
      print('   File size: ${file.lengthSync()} bytes');
      print('   Uploading to Supabase Storage...');

      // Upload file to Supabase Storage
      await _supabase.storage.from(_bucketName).upload(storagePath, file);

      // Get public URL
      final fileUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      print('✅ File uploaded successfully');
      print('   URL: $fileUrl');

      return fileUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Download a file from storage
  Future<List<int>> downloadFile(String fileUrl) async {
    try {
      print('📥 Downloading file from: $fileUrl');

      // Extract storage path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and construct the path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) {
        throw Exception('Invalid file URL: bucket not found');
      }

      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Download file
      final bytes = await _supabase.storage
          .from(_bucketName)
          .download(storagePath);

      print('✅ File downloaded successfully (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      print('❌ Error downloading file: $e');
      rethrow;
    }
  }

  /// Delete a file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      print('🗑️ Deleting file from storage: $fileUrl');

      // Extract storage path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and construct the path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) {
        throw Exception('Invalid file URL: bucket not found');
      }

      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete file
      await _supabase.storage.from(_bucketName).remove([storagePath]);

      print('✅ File deleted from storage successfully');
    } catch (e) {
      print('❌ Error deleting file from storage: $e');
      rethrow;
    }
  }

  /// Get signed URL for private file access (valid for 1 hour)
  Future<String> getSignedUrl(String fileUrl) async {
    try {
      // Extract storage path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and construct the path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) {
        throw Exception('Invalid file URL: bucket not found');
      }

      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Create signed URL (valid for 1 hour)
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, 3600);

      return signedUrl;
    } catch (e) {
      print('❌ Error creating signed URL: $e');
      rethrow;
    }
  }

  // ============================================
  // Versioning Operations
  // ============================================

  /// Get all versions of a resource
  Future<List<SubjectResource>> getResourceVersions(
    String subjectId,
    int quarter,
    String resourceName,
    ResourceType resourceType,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('subject_id', subjectId)
          .eq('quarter', quarter)
          .eq('resource_name', resourceName)
          .eq('resource_type', resourceType.value)
          .order('version', ascending: false);

      return (response as List)
          .map((json) => SubjectResource.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching resource versions: $e');
      rethrow;
    }
  }

  /// Create a new version of an existing resource
  /// This will mark the old version as not latest and create a new version
  Future<SubjectResource> createNewVersion({
    required SubjectResource oldResource,
    required File newFile,
    required String classroomId,
    String? description,
  }) async {
    try {
      print('📝 Creating new version of: ${oldResource.resourceName}');
      print('   Current version: ${oldResource.version}');

      // Upload new file
      final newFileUrl = await uploadFile(
        file: newFile,
        classroomId: classroomId,
        subjectId: oldResource.subjectId,
        quarter: oldResource.quarter,
        resourceType: oldResource.resourceType,
        fileName: newFile.path.split('/').last,
      );

      // Mark old version as not latest
      await _supabase
          .from(_tableName)
          .update({'is_latest_version': false})
          .eq('id', oldResource.id);

      // Create new version (manually build JSON to exclude old ID)
      final newVersionJson = {
        'subject_id': oldResource.subjectId,
        'resource_name': oldResource.resourceName,
        'resource_type': oldResource.resourceType.value,
        'quarter': oldResource.quarter,
        'file_url': newFileUrl,
        'file_name': newFile.path.split('/').last,
        'file_size': newFile.lengthSync(),
        'file_type': oldResource.fileType,
        'version': oldResource.version + 1,
        'is_latest_version': true,
        'previous_version_id': oldResource.id,
        'display_order': oldResource.displayOrder,
        'description': description ?? oldResource.description,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'created_by': oldResource.createdBy,
        'uploaded_by': oldResource.uploadedBy,
      };

      final response = await _supabase
          .from(_tableName)
          .insert(newVersionJson)
          .select()
          .single();

      final createdResource = SubjectResource.fromJson(response);
      print('✅ New version created: v${createdResource.version}');
      return createdResource;
    } catch (e) {
      print('❌ Error creating new version: $e');
      rethrow;
    }
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Get resource count by type for a subject and quarter
  Future<Map<ResourceType, int>> getResourceCounts(
    String subjectId,
    int quarter,
  ) async {
    try {
      final resources = await getResourcesByQuarter(subjectId, quarter);

      final counts = <ResourceType, int>{
        ResourceType.module: 0,
        ResourceType.assignmentResource: 0,
        ResourceType.assignment: 0,
      };

      for (final resource in resources) {
        counts[resource.resourceType] =
            (counts[resource.resourceType] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('❌ Error getting resource counts: $e');
      rethrow;
    }
  }

  /// Validate file type
  bool isValidFileType(String fileName) {
    print('🔍 [FILE VALIDATION] isValidFileType called');
    print('   Input fileName: "$fileName"');

    final validExtensions = [
      'pdf',
      'docx',
      'pptx',
      'xlsx',
      'png',
      'jpeg',
      'jpg',
      'mp4',
    ];

    // Extract extension more carefully
    final parts = fileName.split('.');
    print('   Split by ".": ${parts.length} parts');

    if (parts.length < 2) {
      print('   ❌ No extension found (no dot in filename)');
      return false;
    }

    final extension = parts.last.toLowerCase().trim();
    print('   Extracted extension: "$extension"');
    print('   Valid extensions: $validExtensions');

    final isValid = validExtensions.contains(extension);
    print('   Result: ${isValid ? "✅ VALID" : "❌ INVALID"}');

    return isValid;
  }

  /// Validate file size (max 100 MB)
  bool isValidFileSize(int fileSize) {
    const maxSize = 100 * 1024 * 1024; // 100 MB in bytes
    return fileSize <= maxSize;
  }

  /// Get MIME type from file extension
  String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'png':
        return 'image/png';
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
