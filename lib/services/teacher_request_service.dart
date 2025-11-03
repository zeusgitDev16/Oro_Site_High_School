import 'package:oro_site_high_school/models/teacher_request.dart';
import 'package:oro_site_high_school/services/notification_trigger_service.dart';

/// Service for managing teacher requests to admin
/// Backend integration point: Supabase 'teacher_requests' table
class TeacherRequestService {
  // Singleton pattern
  static final TeacherRequestService _instance = TeacherRequestService._internal();
  factory TeacherRequestService() => _instance;
  TeacherRequestService._internal();

  final NotificationTriggerService _notificationTrigger = NotificationTriggerService();

  // Mock data for UI testing (will be replaced with Supabase calls)
  final List<TeacherRequest> _mockRequests = [
    TeacherRequest(
      id: 'req-1',
      teacherId: 'teacher-1',
      teacherName: 'Maria Santos',
      requestType: 'password_reset',
      title: 'Password Reset for Juan Dela Cruz',
      description: 'Student forgot password and cannot access the system.',
      priority: 'high',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      metadata: {
        'studentName': 'Juan Dela Cruz',
        'studentLRN': '123456789012',
        'section': 'Grade 7 - Diamond',
      },
    ),
    TeacherRequest(
      id: 'req-2',
      teacherId: 'teacher-1',
      teacherName: 'Maria Santos',
      requestType: 'resource',
      title: 'Need Science Lab Equipment',
      description: 'Requesting microscopes and slides for Science 7 practical exam.',
      priority: 'medium',
      status: 'in_progress',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      adminResponse: 'Checking availability with procurement.',
      resolvedBy: 'Steven Johnson',
    ),
    TeacherRequest(
      id: 'req-3',
      teacherId: 'teacher-2',
      teacherName: 'Juan Reyes',
      requestType: 'technical',
      title: 'Projector Not Working in Room 201',
      description: 'The projector in Room 201 is not turning on. Need urgent repair.',
      priority: 'urgent',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
      adminResponse: 'Projector has been repaired and tested.',
      resolvedBy: 'Steven Johnson',
    ),
  ];

  /// Get all requests
  Future<List<TeacherRequest>> getAllRequests() async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('teacher_requests').select();
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockRequests);
  }

  /// Get requests by teacher
  Future<List<TeacherRequest>> getRequestsByTeacher(String teacherId) async {
    // TODO: Replace with Supabase query
    // final response = await supabase.from('teacher_requests')
    //   .select()
    //   .eq('teacher_id', teacherId);
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRequests.where((r) => r.teacherId == teacherId).toList();
  }

  /// Get requests by status
  Future<List<TeacherRequest>> getRequestsByStatus(String status) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRequests.where((r) => r.status == status).toList();
  }

  /// Get pending requests
  Future<List<TeacherRequest>> getPendingRequests() async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRequests.where((r) => r.status == 'pending').toList();
  }

  /// Get urgent requests
  Future<List<TeacherRequest>> getUrgentRequests() async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRequests.where((r) => r.priority == 'urgent' && !r.isResolved).toList();
  }

  /// Get requests by type
  Future<List<TeacherRequest>> getRequestsByType(String type) async {
    // TODO: Replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRequests.where((r) => r.requestType == type).toList();
  }

  /// Create a new request
  Future<TeacherRequest> createRequest(TeacherRequest request) async {
    // TODO: Replace with Supabase insert
    // final response = await supabase.from('teacher_requests')
    //   .insert(request.toJson())
    //   .select()
    //   .single();
    await Future.delayed(const Duration(milliseconds: 500));
    _mockRequests.insert(0, request); // Add to beginning
    
    // Trigger notification to admin
    await _notificationTrigger.triggerNewRequest(
      adminId: 'admin-1', // Mock admin ID
      teacherName: request.teacherName,
      requestType: request.requestType,
      requestTitle: request.title,
      priority: request.priority,
    );
    
    return request;
  }

  /// Update request status
  Future<TeacherRequest> updateRequestStatus(
    String requestId,
    String status, {
    String? adminResponse,
    String? resolvedBy,
  }) async {
    // TODO: Replace with Supabase update
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final request = _mockRequests[index];
      _mockRequests[index] = request.copyWith(
        status: status,
        adminResponse: adminResponse,
        resolvedBy: resolvedBy,
        resolvedAt: (status == 'completed' || status == 'rejected') ? DateTime.now() : null,
      );
      
      // Trigger notification to teacher
      if (adminResponse != null) {
        await _notificationTrigger.triggerRequestResponse(
          teacherId: request.teacherId,
          requestTitle: request.title,
          status: status,
          adminResponse: adminResponse,
          adminName: resolvedBy ?? 'Admin',
        );
      }
      
      return _mockRequests[index];
    }
    throw Exception('Request not found');
  }

  /// Delete a request
  Future<void> deleteRequest(String requestId) async {
    // TODO: Replace with Supabase delete
    await Future.delayed(const Duration(milliseconds: 500));
    _mockRequests.removeWhere((r) => r.id == requestId);
  }

  /// Get request count by status
  Future<Map<String, int>> getRequestCountByStatus() async {
    // TODO: Replace with Supabase aggregation query
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'pending': _mockRequests.where((r) => r.status == 'pending').length,
      'in_progress': _mockRequests.where((r) => r.status == 'in_progress').length,
      'completed': _mockRequests.where((r) => r.status == 'completed').length,
      'rejected': _mockRequests.where((r) => r.status == 'rejected').length,
    };
  }

  /// Get request statistics
  Future<Map<String, dynamic>> getRequestStatistics() async {
    // TODO: Replace with Supabase aggregation query
    await Future.delayed(const Duration(milliseconds: 300));
    final total = _mockRequests.length;
    final pending = _mockRequests.where((r) => r.status == 'pending').length;
    final urgent = _mockRequests.where((r) => r.priority == 'urgent' && !r.isResolved).length;
    final avgResolutionTime = _calculateAverageResolutionTime();

    return {
      'total': total,
      'pending': pending,
      'urgent': urgent,
      'avgResolutionTime': avgResolutionTime,
    };
  }

  /// Calculate average resolution time in hours
  double _calculateAverageResolutionTime() {
    final resolved = _mockRequests.where((r) => r.isResolved && r.resolvedAt != null).toList();
    if (resolved.isEmpty) return 0;

    final totalHours = resolved.fold<double>(
      0,
      (sum, r) => sum + r.resolvedAt!.difference(r.createdAt).inHours,
    );

    return totalHours / resolved.length;
  }

  /// Search requests
  Future<List<TeacherRequest>> searchRequests(String query) async {
    // TODO: Replace with Supabase full-text search
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _mockRequests.where((r) {
      return r.title.toLowerCase().contains(lowerQuery) ||
          r.description.toLowerCase().contains(lowerQuery) ||
          r.teacherName.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
