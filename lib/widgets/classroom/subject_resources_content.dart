import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/classroom_subject.dart';
import '../../models/subject_resource.dart';
import '../../models/resource_type.dart';
import '../../models/temporary_resource.dart';
import '../../services/subject_resource_service.dart';
import '../../services/temporary_resource_storage.dart';
import 'quarter_selector_widget.dart';
import 'resource_section_widget.dart';
import 'file_upload_dialog.dart';

/// Main content area for subject resources
/// Shows quarter selector and resource sections (modules, assignment resources, assignments)
class SubjectResourcesContent extends StatefulWidget {
  final ClassroomSubject subject;
  final String classroomId;
  final bool isCreateMode;
  final bool isAdmin;
  final String? currentUserId;
  final String? userRole; // 'admin', 'teacher', 'student'

  const SubjectResourcesContent({
    super.key,
    required this.subject,
    required this.classroomId,
    required this.isCreateMode,
    required this.isAdmin,
    this.currentUserId,
    this.userRole,
  });

  @override
  State<SubjectResourcesContent> createState() =>
      _SubjectResourcesContentState();
}

class _SubjectResourcesContentState extends State<SubjectResourcesContent> {
  final SubjectResourceService _resourceService = SubjectResourceService();
  final TemporaryResourceStorage _tempStorage = TemporaryResourceStorage();
  int _selectedQuarter = 1;
  Map<ResourceType, List<SubjectResource>> _resourcesByType = {};
  List<TemporaryResource> _temporaryResources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔍 [RESOURCES] SubjectResourcesContent initialized');
    print('   isAdmin: ${widget.isAdmin}');
    print('   userRole: ${widget.userRole}');
    print('   isCreateMode: ${widget.isCreateMode}');
    print('   currentUserId: ${widget.currentUserId}');
    print('   subject: ${widget.subject.subjectName}');
    print('   _hasAdminPermissions(): ${_hasAdminPermissions()}');
    print('   _hasTeacherPermissions(): ${_hasTeacherPermissions()}');
    print('   _isStudent(): ${_isStudent()}');

    if (widget.isCreateMode) {
      _loadTemporaryResources();
    } else {
      _loadResources();
    }
  }

  /// Check if user has admin-like permissions
  /// Includes: admin, ict_coordinator, hybrid
  bool _hasAdminPermissions() {
    final role = widget.userRole?.toLowerCase();
    final hasPermission =
        role == 'admin' ||
        role == 'ict_coordinator' ||
        role == 'hybrid' ||
        widget.isAdmin;
    print('🔐 [PERMISSION CHECK] _hasAdminPermissions()');
    print('   userRole: ${widget.userRole}');
    print('   role (lowercase): $role');
    print('   widget.isAdmin: ${widget.isAdmin}');
    print('   result: $hasPermission');
    return hasPermission;
  }

  /// Check if user has teacher-like permissions
  /// Includes: teacher, grade_level_coordinator, hybrid
  bool _hasTeacherPermissions() {
    final role = widget.userRole?.toLowerCase();
    final hasPermission =
        role == 'teacher' ||
        role == 'grade_level_coordinator' ||
        role == 'hybrid';
    print('🔐 [PERMISSION CHECK] _hasTeacherPermissions()');
    print('   userRole: ${widget.userRole}');
    print('   role (lowercase): $role');
    print('   result: $hasPermission');
    return hasPermission;
  }

  /// Check if user is a student
  bool _isStudent() {
    final isStudent = widget.userRole?.toLowerCase() == 'student';
    print('🔐 [PERMISSION CHECK] _isStudent()');
    print('   userRole: ${widget.userRole}');
    print('   result: $isStudent');
    return isStudent;
  }

  @override
  void didUpdateWidget(SubjectResourcesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject.id != widget.subject.id ||
        oldWidget.classroomId != widget.classroomId) {
      if (widget.isCreateMode) {
        _loadTemporaryResources();
      } else {
        _loadResources();
      }
    }
  }

  /// Load temporary resources from SharedPreferences (CREATE mode)
  Future<void> _loadTemporaryResources() async {
    setState(() => _isLoading = true);

    try {
      print(
        '📦 [TEMP LOAD] Loading temporary resources for subject: ${widget.subject.id}',
      );

      final resources = await _tempStorage.getResourcesByQuarter(
        widget.subject.id,
        _selectedQuarter,
      );

      setState(() {
        _temporaryResources = resources;
        _isLoading = false;
      });

      print('📦 [TEMP LOAD] ✅ Loaded ${resources.length} temporary resources');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('❌ [TEMP LOAD] Error loading temporary resources: $e');
      }
    }
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);

    try {
      final resources = await _resourceService.getResourcesByQuarter(
        widget.subject.id,
        _selectedQuarter,
      );

      // Group by type
      final byType = <ResourceType, List<SubjectResource>>{};
      for (final resource in resources) {
        byType.putIfAbsent(resource.resourceType, () => []).add(resource);
      }

      setState(() {
        _resourcesByType = byType;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading resources: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpload(ResourceType resourceType) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FileUploadDialog(
        resourceType: resourceType,
        quarter: _selectedQuarter,
        subjectName: widget.subject.subjectName,
      ),
    );

    if (result != null && mounted) {
      print('');
      print('📥 [UPLOAD HANDLER] Received file data from dialog');
      print('   Resource name: ${result['name']}');
      print('   Original filename: ${result['originalFileName']}');
      print('   Original file size: ${result['originalFileSize']} bytes');
      print('   File path: ${(result['file'] as File).path}');

      await _uploadFile(
        resourceType,
        result['name'] as String,
        result['description'] as String?,
        result['file'] as File,
        result['originalFileName'] as String?, // Pass the original filename
        result['originalFileSize'] as int?, // Pass the original file size
      );
    }
  }

  /// Extract filename from path in a platform-independent way
  String _getFileName(String filePath) {
    print('🔍 [FILENAME EXTRACTION] _getFileName called');
    print('   Input filePath: "$filePath"');

    // Split by both forward slash and backslash to handle all platforms
    final parts = filePath.split(RegExp(r'[/\\]'));
    print('   Split into ${parts.length} parts');
    print('   Parts: $parts');

    final fileName = parts.last;
    print('   Extracted fileName: "$fileName"');

    return fileName;
  }

  /// Extract file extension from path
  String _getFileExtension(String filePath) {
    print('🔍 [EXTENSION EXTRACTION] _getFileExtension called');
    print('   Input filePath: "$filePath"');

    final fileName = _getFileName(filePath);
    final parts = fileName.split('.');
    print('   Split fileName by ".": ${parts.length} parts');

    final extension = parts.length > 1 ? parts.last.toLowerCase() : '';
    print('   Extracted extension: "$extension"');

    return extension;
  }

  Future<void> _uploadFile(
    ResourceType resourceType,
    String name,
    String? description,
    File file,
    String? originalFileName, // Add parameter for original filename from picker
    int? originalFileSize, // Add parameter for original file size from picker
  ) async {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📤 [UPLOAD START] Starting file upload process');
    print('═══════════════════════════════════════════════════════════');
    print('   Resource Type: ${resourceType.displayName}');
    print('   Resource Name: "$name"');
    print('   Description: "$description"');
    print('   File Path: "${file.path}"');
    print('   Original Filename (from picker): "$originalFileName"');
    print('   Original File Size (from picker): "$originalFileSize" bytes');
    print('   Is Create Mode: ${widget.isCreateMode}');
    print('───────────────────────────────────────────────────────────');

    // Show loading
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('');
      print('🔍 [VALIDATION] Starting file validation...');

      // CRITICAL: Use original filename from picker for validation
      // The file.path might be a temporary path with UUID, but originalFileName
      // contains the actual filename with correct extension
      String fileNameForValidation;

      if (originalFileName != null && originalFileName.isNotEmpty) {
        // Use the original filename from the file picker (RELIABLE)
        fileNameForValidation = originalFileName;
        print(
          '   ✅ Using original filename from picker: "$fileNameForValidation"',
        );
      } else {
        // Fallback: Extract from path (for backward compatibility)
        fileNameForValidation = _getFileName(file.path);
        print(
          '   ⚠️ Fallback: Extracted filename from path: "$fileNameForValidation"',
        );
      }

      print('   Calling isValidFileType with: "$fileNameForValidation"');

      final isValidType = _resourceService.isValidFileType(
        fileNameForValidation,
      );
      print('   Validation result: ${isValidType ? "✅ VALID" : "❌ INVALID"}');

      if (!isValidType) {
        print('');
        print('❌ [VALIDATION FAILED] File type is invalid!');
        print('   Filename used for validation: "$fileNameForValidation"');
        print('   Throwing exception: "Invalid file type"');
        print('═══════════════════════════════════════════════════════════');
        throw Exception('Invalid file type');
      }

      print('   ✅ File type validation passed');
      print('');

      print('🔍 [SIZE VALIDATION] Checking file size...');

      // CRITICAL: Use original file size from picker if available
      // Trying to read file.length() may fail with temporary paths
      int fileSize;
      if (originalFileSize != null) {
        fileSize = originalFileSize;
        print('   ✅ Using file size from picker: $fileSize bytes');
      } else {
        // Fallback: Try to read from file (for backward compatibility)
        print('   ⚠️ Fallback: Reading file size from file.length()...');
        try {
          fileSize = await file.length();
          print('   File size from file.length(): $fileSize bytes');
        } catch (e) {
          print('   ❌ Error reading file size: $e');
          print('   Throwing exception: "Unable to read file size"');
          print('═══════════════════════════════════════════════════════════');
          throw Exception('Unable to read file size');
        }
      }

      print(
        '   File size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
      );

      final isValidSize = _resourceService.isValidFileSize(fileSize);
      print(
        '   Size validation result: ${isValidSize ? "✅ VALID" : "❌ INVALID"}',
      );

      if (!isValidSize) {
        print('');
        print('❌ [SIZE VALIDATION FAILED] File size exceeds limit!');
        print('   Throwing exception: "File size exceeds 100MB limit"');
        print('═══════════════════════════════════════════════════════════');
        throw Exception('File size exceeds 100MB limit');
      }

      print('   ✅ File size validation passed');
      print('');

      if (widget.isCreateMode) {
        print('📝 [CREATE MODE] Saving to temporary storage...');

        // CREATE MODE: Save to temporary storage
        // Use original filename for storage metadata
        final fileNameToStore = originalFileName ?? _getFileName(file.path);
        final fileExtension = originalFileName != null
            ? originalFileName.split('.').last.toLowerCase()
            : _getFileExtension(file.path);

        print('   Filename to store: "$fileNameToStore"');
        print('   File extension: "$fileExtension"');

        final tempResource = TemporaryResource(
          tempId: 'temp_resource_${DateTime.now().millisecondsSinceEpoch}',
          subjectId: widget.subject.id,
          resourceName: name,
          resourceType: resourceType,
          quarter: _selectedQuarter,
          filePath: file.path,
          fileName: fileNameToStore, // Use original filename
          fileSize: fileSize,
          fileType: fileExtension,
          description: description,
          createdAt: DateTime.now(),
        );

        print('   Temporary resource created');
        print('   - fileName: ${tempResource.fileName}');
        print('   - fileType: ${tempResource.fileType}');
        await _tempStorage.addResource(widget.subject.id, tempResource);
        print('   ✅ Saved to temporary storage');
        print('═══════════════════════════════════════════════════════════');

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${resourceType.displayName} added (will save when classroom is created)',
              ),
              backgroundColor: Colors.blue,
            ),
          );
          _loadTemporaryResources(); // Reload temporary resources
        }
      } else {
        print('☁️ [EDIT MODE] Uploading to storage and database...');

        // EDIT MODE: Upload file to storage and save to database
        // Use original filename for storage and metadata
        final fileNameToStore = originalFileName ?? _getFileName(file.path);
        final fileExtension = originalFileName != null
            ? originalFileName.split('.').last.toLowerCase()
            : _getFileExtension(file.path);

        print('   Filename to store: "$fileNameToStore"');
        print('   File extension: "$fileExtension"');
        print('   Uploading file to Supabase storage...');

        final fileUrl = await _resourceService.uploadFile(
          file: file,
          classroomId: widget.classroomId,
          subjectId: widget.subject.id,
          quarter: _selectedQuarter,
          resourceType: resourceType,
          fileName: fileNameToStore, // Pass original filename to service
        );
        print('   ✅ File uploaded to storage');
        print('   File URL: $fileUrl');

        // Create resource record - use original filename and validated file size
        print('   Creating resource record in database...');
        final resource = SubjectResource(
          id: '',
          subjectId: widget.subject.id,
          resourceName: name,
          resourceType: resourceType,
          quarter: _selectedQuarter,
          fileUrl: fileUrl,
          fileName: fileNameToStore, // Use original filename
          fileSize: fileSize, // Use the validated file size from above
          fileType: fileExtension, // Use extracted extension
          version: 1,
          isLatestVersion: true,
          previousVersionId: null,
          displayOrder: 0,
          description: description,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: widget.currentUserId,
          uploadedBy: widget.currentUserId,
        );

        print('   Resource metadata:');
        print('   - fileName: ${resource.fileName}');
        print('   - fileSize: ${resource.fileSize} bytes');
        print('   - fileType: ${resource.fileType}');

        await _resourceService.createResource(resource);
        print('   ✅ Resource record created in database');
        print('═══════════════════════════════════════════════════════════');

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${resourceType.displayName} uploaded successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadResources(); // Reload resources
        }
      }
    } catch (e, stackTrace) {
      print('');
      print('❌❌❌ [UPLOAD ERROR] An error occurred during upload! ❌❌❌');
      print('═══════════════════════════════════════════════════════════');
      print('Error: $e');
      print('───────────────────────────────────────────────────────────');
      print('Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════════════');

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleDownload(SubjectResource resource) async {
    // TODO: Implement download logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${resource.resourceName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _handleDeleteTemporary(TemporaryResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource', style: TextStyle(fontSize: 14)),
        content: Text(
          'Are you sure you want to delete "${resource.resourceName}"?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _tempStorage.removeResource(widget.subject.id, resource.tempId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resource removed'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTemporaryResources();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing resource: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(SubjectResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource', style: TextStyle(fontSize: 14)),
        content: Text(
          'Are you sure you want to delete "${resource.resourceName}"?',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _resourceService.deleteResource(resource.id);
        await _resourceService.deleteFile(resource.fileUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resource deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadResources();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting resource: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Convert temporary resources to SubjectResource for display
  List<SubjectResource> _convertTemporaryToSubjectResources(ResourceType type) {
    return _temporaryResources
        .where((r) => r.resourceType == type)
        .map(
          (temp) => SubjectResource(
            id: temp.tempId,
            subjectId: temp.subjectId,
            resourceName: temp.resourceName,
            resourceType: temp.resourceType,
            quarter: temp.quarter,
            fileUrl: temp.filePath, // Use file path as URL for temporary
            fileName: temp.fileName,
            fileSize: temp.fileSize,
            fileType: temp.fileType,
            version: 1,
            isLatestVersion: true,
            previousVersionId: null,
            displayOrder: 0,
            description: temp.description,
            isActive: true,
            createdAt: temp.createdAt,
            updatedAt: temp.createdAt,
            createdBy: null,
            uploadedBy: null,
          ),
        )
        .toList();
  }

  /// Handle delete for temporary resources (wrapper)
  Future<void> _handleDeleteWrapper(SubjectResource resource) async {
    if (widget.isCreateMode) {
      // Find the temporary resource
      final tempResource = _temporaryResources.firstWhere(
        (r) => r.tempId == resource.id,
      );
      await _handleDeleteTemporary(tempResource);
    } else {
      await _handleDelete(resource);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade100, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.book, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.subject.subjectName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Quarter selector
        QuarterSelectorWidget(
          selectedQuarter: _selectedQuarter,
          onQuarterChanged: (quarter) {
            setState(() => _selectedQuarter = quarter);
            if (widget.isCreateMode) {
              _loadTemporaryResources();
            } else {
              _loadResources();
            }
          },
        ),

        // Resource sections
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modules section
                      // - Admins/ICT Coordinators/Hybrid: Can upload, delete
                      // - Teachers/Grade Level Coordinators: Can view only
                      // - Students: Can view only
                      ResourceSectionWidget(
                        resourceType: ResourceType.module,
                        resources: widget.isCreateMode
                            ? _convertTemporaryToSubjectResources(
                                ResourceType.module,
                              )
                            : _resourcesByType[ResourceType.module] ?? [],
                        onUpload: () => _handleUpload(ResourceType.module),
                        onDownload: _handleDownload,
                        onDelete: _handleDeleteWrapper,
                        canUpload:
                            _hasAdminPermissions(), // Admin-like roles can upload
                        canDelete:
                            _hasAdminPermissions(), // Admin-like roles can delete
                      ),

                      // Assignment Resources section
                      // - Admins/ICT Coordinators/Hybrid: Can upload, delete, view
                      // - Teachers/Grade Level Coordinators: Can view only
                      // - Students: CANNOT view (hidden)
                      if (!_isStudent())
                        ResourceSectionWidget(
                          resourceType: ResourceType.assignmentResource,
                          resources: widget.isCreateMode
                              ? _convertTemporaryToSubjectResources(
                                  ResourceType.assignmentResource,
                                )
                              : _resourcesByType[ResourceType
                                        .assignmentResource] ??
                                    [],
                          onUpload: () =>
                              _handleUpload(ResourceType.assignmentResource),
                          onDownload: _handleDownload,
                          onDelete: _handleDeleteWrapper,
                          canUpload:
                              _hasAdminPermissions(), // Admin-like roles can upload
                          canDelete:
                              _hasAdminPermissions(), // Admin-like roles can delete
                        ),

                      // Assignments section
                      // - Admins/ICT Coordinators/Hybrid: Full CRUD (manage all)
                      // - Teachers/Grade Level Coordinators: Full CRUD (their main job)
                      // - Students: Can create submissions, view, update drafts, delete drafts
                      //   (Note: Student submission logic will be different - handled separately)
                      ResourceSectionWidget(
                        resourceType: ResourceType.assignment,
                        resources: widget.isCreateMode
                            ? _convertTemporaryToSubjectResources(
                                ResourceType.assignment,
                              )
                            : _resourcesByType[ResourceType.assignment] ?? [],
                        onUpload: () => _handleUpload(ResourceType.assignment),
                        onDownload: _handleDownload,
                        onDelete: _handleDeleteWrapper,
                        canUpload:
                            _hasAdminPermissions() ||
                            _hasTeacherPermissions(), // Admin-like and teacher-like roles can upload
                        canDelete:
                            _hasAdminPermissions() ||
                            _hasTeacherPermissions(), // Admin-like and teacher-like roles can delete
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
