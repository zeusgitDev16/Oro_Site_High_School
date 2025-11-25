import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oro_site_high_school/backend/config/supabase_config.dart';
import 'package:oro_site_high_school/models/course_file.dart';

/// File Upload Service
/// Handles file uploads to Supabase Storage and database records
/// Layer 2: Service Layer - Business logic for file operations
class FileUploadService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _bucketName = 'course_files';

  /// Pick files from device
  Future<List<PlatformFile>?> pickFiles({bool allowMultiple = true}) async {
    try {
      print('📁 FileUploadService: Opening file picker...');

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        print('✅ FileUploadService: Selected ${result.files.length} file(s)');
        return result.files;
      }

      print('⚠️ FileUploadService: No files selected');
      return null;
    } catch (e) {
      print('❌ FileUploadService: Error picking files: $e');
      rethrow;
    }
  }

  /// Upload file to Supabase Storage
  Future<String> uploadFileToStorage({
    required PlatformFile file,
    required String courseId,
    required String fileType, // 'module' or 'assignment'
  }) async {
    try {
      print('📤 FileUploadService: Uploading ${file.name}...');

      // Create unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'unknown';
      final folderName = fileType == 'module' ? 'modules' : 'assignments';
      final fileName = '${courseId}_${fileType}_${timestamp}.$extension';
      final filePath = '$courseId/$folderName/$fileName';

      // Upload to Supabase Storage
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();

      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      print('✅ FileUploadService: File uploaded successfully');
      print('📎 URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ FileUploadService: Error uploading file: $e');
      if (e is StorageException) {
        print('❌ Storage error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Save file record to database (uses separate tables)
  Future<CourseFile> saveFileRecord({
    required String courseId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required String fileExtension,
    required int fileSize,
    required String uploadedBy,
  }) async {
    try {
      print('💾 FileUploadService: Saving file record to database...');

      final fileData = {
        'course_id': int.parse(courseId), // Convert String to int
        'file_name': fileName,
        'file_url': fileUrl,
        'file_extension': fileExtension,
        'file_size': fileSize,
        'uploaded_by': uploadedBy,
        'uploaded_at': DateTime.now().toIso8601String(),
      };

      // Use appropriate table based on file type
      final tableName = fileType == 'module'
          ? 'course_modules'
          : 'course_assignments';

      final response = await _supabase
          .from(tableName)
          .insert(fileData)
          .select()
          .single();

      print('✅ FileUploadService: File record saved to $tableName');

      return CourseFile.fromJson(response, fileType);
    } catch (e) {
      print('❌ FileUploadService: Error saving file record: $e');
      if (e is PostgrestException) {
        print('❌ Postgrest error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Upload file (combines storage upload and database record)
  Future<CourseFile> uploadFile({
    required PlatformFile file,
    required String courseId,
    required String fileType,
    required String uploadedBy,
  }) async {
    try {
      // Upload to storage
      final fileUrl = await uploadFileToStorage(
        file: file,
        courseId: courseId,
        fileType: fileType,
      );

      // Save record to database
      final courseFile = await saveFileRecord(
        courseId: courseId,
        fileName: file.name,
        fileUrl: fileUrl,
        fileType: fileType,
        fileExtension: file.extension ?? 'unknown',
        fileSize: file.size,
        uploadedBy: uploadedBy,
      );

      return courseFile;
    } catch (e) {
      print('❌ FileUploadService: Error in uploadFile: $e');
      rethrow;
    }
  }

  /// Get files for a course (from both tables)
  Future<List<CourseFile>> getCourseFiles({
    required String courseId,
    String? fileType, // null = all, 'module' or 'assignment'
  }) async {
    try {
      // print('📚 FileUploadService: Fetching files for course $courseId...');

      final List<CourseFile> allFiles = [];
      final courseIdInt = int.parse(courseId); // Convert to int for query

      // Fetch modules if needed
      if (fileType == null || fileType == 'module') {
        final modulesResponse = await _supabase
            .from('course_modules')
            .select()
            .eq('course_id', courseIdInt)
            .order('uploaded_at', ascending: false);

        final modules = (modulesResponse as List)
            .map((json) => CourseFile.fromJson(json, 'module'))
            .toList();

        allFiles.addAll(modules);
        // print('✅ FileUploadService: Found ${modules.length} module(s)');
      }

      // Fetch assignments if needed
      if (fileType == null || fileType == 'assignment') {
        final assignmentsResponse = await _supabase
            .from('course_assignments')
            .select()
            .eq('course_id', courseIdInt)
            .order('uploaded_at', ascending: false);

        final assignments = (assignmentsResponse as List)
            .map((json) => CourseFile.fromJson(json, 'assignment'))
            .toList();

        allFiles.addAll(assignments);
        // print('✅ FileUploadService: Found ${assignments.length} assignment(s)');
      }

      // print('✅ FileUploadService: Total ${allFiles.length} file(s)');

      return allFiles;
    } catch (e) {
      print('❌ FileUploadService: Error fetching files: $e');
      return [];
    }
  }

  /// Delete file (from appropriate table)
  Future<void> deleteFile({
    required String fileId,
    required String fileUrl,
    required String fileType,
  }) async {
    try {
      print('🗑️ FileUploadService: Deleting file $fileId...');

      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_bucketName);

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        // Delete from storage
        await _supabase.storage.from(_bucketName).remove([filePath]);

        print('✅ FileUploadService: File deleted from storage');
      }

      // Delete record from appropriate table
      final tableName = fileType == 'module'
          ? 'course_modules'
          : 'course_assignments';

      await _supabase.from(tableName).delete().eq('id', fileId);

      print('✅ FileUploadService: File record deleted from $tableName');
    } catch (e) {
      print('❌ FileUploadService: Error deleting file: $e');
      rethrow;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
