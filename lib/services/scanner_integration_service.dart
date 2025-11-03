/// Scanner Integration Service
/// Handles integration with the external attendance scanner subsystem
/// This service acts as a bridge between our ELMS and the scanner subsystem

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../models/attendance_session.dart';
import '../models/student.dart';
import 'attendance_service.dart';

/// Scanner data model from the subsystem
class ScannerData {
  final String studentLrn;
  final DateTime scanTime;
  final String scanType; // 'in' or 'out'
  final String? deviceId;
  final String? location;
  final Map<String, dynamic>? metadata;

  ScannerData({
    required this.studentLrn,
    required this.scanTime,
    required this.scanType,
    this.deviceId,
    this.location,
    this.metadata,
  });

  factory ScannerData.fromJson(Map<String, dynamic> json) {
    return ScannerData(
      studentLrn: json['student_lrn'] ?? json['lrn'],
      scanTime: DateTime.parse(json['scan_time'] ?? json['timestamp']),
      scanType: json['scan_type'] ?? 'in',
      deviceId: json['device_id'],
      location: json['location'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_lrn': studentLrn,
      'scan_time': scanTime.toIso8601String(),
      'scan_type': scanType,
      'device_id': deviceId,
      'location': location,
      'metadata': metadata,
    };
  }
}

/// Scanner session configuration
class ScannerSessionConfig {
  final int sessionId;
  final String teacherId;
  final int courseId;
  final int? sectionId;
  final DateTime startTime;
  final DateTime endTime;
  final int scanTimeLimitMinutes;
  final bool allowStudentScanning;
  final List<String>? authorizedScanners; // Student IDs allowed to scan

  ScannerSessionConfig({
    required this.sessionId,
    required this.teacherId,
    required this.courseId,
    this.sectionId,
    required this.startTime,
    required this.endTime,
    required this.scanTimeLimitMinutes,
    this.allowStudentScanning = false,
    this.authorizedScanners,
  });
}

class ScannerIntegrationService extends ChangeNotifier {
  static final ScannerIntegrationService _instance = ScannerIntegrationService._internal();
  factory ScannerIntegrationService() => _instance;
  ScannerIntegrationService._internal();

  final _supabase = Supabase.instance.client;
  final _attendanceService = AttendanceService();
  
  // Real-time subscription for scanner data
  StreamSubscription? _scannerSubscription;
  
  // Active scanner sessions
  final Map<int, ScannerSessionConfig> _activeSessions = {};
  
  // Scan queue for offline support
  final List<ScannerData> _scanQueue = [];
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Scanner statistics
  int _totalScansToday = 0;
  int _successfulScans = 0;
  int _failedScans = 0;
  
  int get totalScansToday => _totalScansToday;
  int get successfulScans => _successfulScans;
  int get failedScans => _failedScans;

  /// Initialize scanner integration
  Future<void> initialize() async {
    try {
      // Set up real-time subscription to scanner data table
      await _setupRealtimeSubscription();
      
      // Load active sessions
      await _loadActiveSessions();
      
      // Process any queued scans
      await _processQueuedScans();
      
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      print('Scanner integration initialization error: $e');
      _isConnected = false;
    }
  }

  /// Set up real-time subscription to scanner data
  Future<void> _setupRealtimeSubscription() async {
    // Subscribe to the scanner_data table (from subsystem)
    _scannerSubscription = _supabase
        .from('scanner_data')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          // Process new scan data
          for (final scan in data) {
            _processScanData(ScannerData.fromJson(scan));
          }
        });
  }

  /// Load active attendance sessions
  Future<void> _loadActiveSessions() async {
    try {
      final sessions = await _attendanceService.getActiveSessions();
      
      for (final session in sessions) {
        _activeSessions[session.id] = ScannerSessionConfig(
          sessionId: session.id,
          teacherId: session.teacherId,
          courseId: session.courseId,
          sectionId: session.sectionId,
          startTime: session.scheduleStart,
          endTime: session.scheduleEnd,
          scanTimeLimitMinutes: session.scanTimeLimitMinutes,
        );
      }
    } catch (e) {
      print('Error loading active sessions: $e');
    }
  }

  /// Process scan data from the subsystem
  Future<void> _processScanData(ScannerData scanData) async {
    try {
      _totalScansToday++;
      
      // Validate scan data
      if (!_validateScanData(scanData)) {
        _failedScans++;
        notifyListeners();
        return;
      }
      
      // Find active session for this scan
      final session = _findActiveSessionForScan(scanData);
      if (session == null) {
        // Queue scan if no active session
        _queueScan(scanData);
        _failedScans++;
        notifyListeners();
        return;
      }
      
      // Get student information from LRN
      final student = await _getStudentByLrn(scanData.studentLrn);
      if (student == null) {
        print('Student not found for LRN: ${scanData.studentLrn}');
        _failedScans++;
        notifyListeners();
        return;
      }
      
      // Record attendance
      await _recordAttendanceFromScan(
        scanData: scanData,
        student: student,
        session: session,
      );
      
      _successfulScans++;
      notifyListeners();
    } catch (e) {
      print('Error processing scan data: $e');
      _queueScan(scanData);
      _failedScans++;
      notifyListeners();
    }
  }

  /// Validate scan data
  bool _validateScanData(ScannerData scanData) {
    // Validate LRN format (12 digits)
    if (scanData.studentLrn.length != 12) {
      print('Invalid LRN length: ${scanData.studentLrn}');
      return false;
    }
    
    // Validate scan time (not future)
    if (scanData.scanTime.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      print('Invalid scan time (future): ${scanData.scanTime}');
      return false;
    }
    
    return true;
  }

  /// Find active session for a scan
  ScannerSessionConfig? _findActiveSessionForScan(ScannerData scanData) {
    final now = scanData.scanTime;
    
    for (final session in _activeSessions.values) {
      // Check if scan is within session time window
      if (now.isAfter(session.startTime.subtract(Duration(minutes: 15))) &&
          now.isBefore(session.endTime.add(Duration(minutes: 15)))) {
        return session;
      }
    }
    
    return null;
  }

  /// Get student by LRN
  Future<Student?> _getStudentByLrn(String lrn) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('lrn', lrn)
          .maybeSingle();
      
      if (response == null) return null;
      return Student.fromJson(response);
    } catch (e) {
      print('Error fetching student by LRN: $e');
      return null;
    }
  }

  /// Record attendance from scan
  Future<void> _recordAttendanceFromScan({
    required ScannerData scanData,
    required Student student,
    required ScannerSessionConfig session,
  }) async {
    try {
      // Determine if student is late
      final scanDeadline = session.startTime.add(
        Duration(minutes: session.scanTimeLimitMinutes),
      );
      final isLate = scanData.scanTime.isAfter(scanDeadline);
      
      // Record attendance
      if (scanData.scanType == 'in') {
        await _attendanceService.recordAttendance(
          studentId: student.id,
          studentLrn: student.lrn,
          courseId: session.courseId,
          sessionId: session.sessionId,
          date: scanData.scanTime,
          timeIn: scanData.scanTime,
          remarks: isLate 
              ? 'Late - Scanned at ${scanData.location ?? "entrance"}' 
              : 'On time - Scanned at ${scanData.location ?? "entrance"}',
        );
      } else if (scanData.scanType == 'out') {
        // Update time out for existing attendance record
        await _updateTimeOut(
          studentId: student.id,
          sessionId: session.sessionId,
          timeOut: scanData.scanTime,
        );
      }
      
      // Log scan activity
      await _logScanActivity(scanData, student, session, isLate);
    } catch (e) {
      print('Error recording attendance from scan: $e');
      throw e;
    }
  }

  /// Update time out for attendance record
  Future<void> _updateTimeOut({
    required String studentId,
    required int sessionId,
    required DateTime timeOut,
  }) async {
    try {
      await _supabase
          .from('attendance')
          .update({'time_out': timeOut.toIso8601String()})
          .eq('student_id', studentId)
          .eq('session_id', sessionId);
    } catch (e) {
      print('Error updating time out: $e');
    }
  }

  /// Log scan activity for audit
  Future<void> _logScanActivity(
    ScannerData scanData,
    Student student,
    ScannerSessionConfig session,
    bool isLate,
  ) async {
    try {
      await _supabase.from('scan_activity_log').insert({
        'student_id': student.id,
        'student_lrn': student.lrn,
        'session_id': session.sessionId,
        'scan_time': scanData.scanTime.toIso8601String(),
        'scan_type': scanData.scanType,
        'device_id': scanData.deviceId,
        'location': scanData.location,
        'is_late': isLate,
        'metadata': scanData.metadata,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging scan activity: $e');
    }
  }

  /// Queue scan for later processing
  void _queueScan(ScannerData scanData) {
    _scanQueue.add(scanData);
    // Persist queue to local storage if needed
    _persistQueue();
  }

  /// Process queued scans
  Future<void> _processQueuedScans() async {
    if (_scanQueue.isEmpty) return;
    
    final queue = List<ScannerData>.from(_scanQueue);
    _scanQueue.clear();
    
    for (final scan in queue) {
      await _processScanData(scan);
    }
  }

  /// Persist scan queue to local storage
  void _persistQueue() {
    // TODO: Implement local storage persistence
    // This would save the queue to SharedPreferences or similar
  }

  /// Create a scanner session for a teacher
  Future<ScannerSessionConfig> createScannerSession({
    required String teacherId,
    required int courseId,
    int? sectionId,
    required DateTime startTime,
    required DateTime endTime,
    required int scanTimeLimitMinutes,
    bool allowStudentScanning = false,
    List<String>? authorizedScanners,
  }) async {
    try {
      // Create attendance session
      final session = await _attendanceService.createAttendanceSession(
        teacherId: teacherId,
        teacherName: '', // Will be fetched from teacher profile
        courseId: courseId,
        courseName: '', // Will be fetched from course
        sectionId: sectionId,
        sectionName: '', // Will be fetched from section
        dayOfWeek: _getDayOfWeek(startTime),
        scheduleStart: startTime,
        scheduleEnd: endTime,
        scanTimeLimitMinutes: scanTimeLimitMinutes,
      );
      
      // Create scanner configuration
      final config = ScannerSessionConfig(
        sessionId: session.id,
        teacherId: teacherId,
        courseId: courseId,
        sectionId: sectionId,
        startTime: startTime,
        endTime: endTime,
        scanTimeLimitMinutes: scanTimeLimitMinutes,
        allowStudentScanning: allowStudentScanning,
        authorizedScanners: authorizedScanners,
      );
      
      // Add to active sessions
      _activeSessions[session.id] = config;
      
      // Notify scanner subsystem about new session
      await _notifyScannerSubsystem(config);
      
      notifyListeners();
      return config;
    } catch (e) {
      print('Error creating scanner session: $e');
      throw e;
    }
  }

  /// Notify scanner subsystem about session
  Future<void> _notifyScannerSubsystem(ScannerSessionConfig config) async {
    try {
      // This would send session details to the scanner subsystem
      // The subsystem needs to know which session is active for scanning
      await _supabase.from('scanner_sessions').insert({
        'session_id': config.sessionId,
        'course_id': config.courseId,
        'section_id': config.sectionId,
        'start_time': config.startTime.toIso8601String(),
        'end_time': config.endTime.toIso8601String(),
        'scan_deadline': config.startTime.add(
          Duration(minutes: config.scanTimeLimitMinutes),
        ).toIso8601String(),
        'allow_student_scanning': config.allowStudentScanning,
        'authorized_scanners': config.authorizedScanners,
        'status': 'active',
      });
    } catch (e) {
      print('Error notifying scanner subsystem: $e');
    }
  }

  /// End a scanner session
  Future<void> endScannerSession(int sessionId) async {
    try {
      // Update session status
      await _attendanceService.updateSessionStatus(sessionId, 'completed');
      
      // Remove from active sessions
      _activeSessions.remove(sessionId);
      
      // Notify scanner subsystem
      await _supabase
          .from('scanner_sessions')
          .update({'status': 'completed'})
          .eq('session_id', sessionId);
      
      notifyListeners();
    } catch (e) {
      print('Error ending scanner session: $e');
    }
  }

  /// Get scanner statistics for today
  Future<Map<String, dynamic>> getTodayStatistics() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    try {
      final response = await _supabase
          .from('scan_activity_log')
          .select()
          .gte('scan_time', startOfDay.toIso8601String())
          .lte('scan_time', today.toIso8601String());
      
      final scans = response as List;
      
      return {
        'total_scans': scans.length,
        'successful_scans': _successfulScans,
        'failed_scans': _failedScans,
        'unique_students': scans.map((s) => s['student_id']).toSet().length,
        'late_scans': scans.where((s) => s['is_late'] == true).length,
        'on_time_scans': scans.where((s) => s['is_late'] == false).length,
      };
    } catch (e) {
      print('Error getting scanner statistics: $e');
      return {
        'total_scans': _totalScansToday,
        'successful_scans': _successfulScans,
        'failed_scans': _failedScans,
        'unique_students': 0,
        'late_scans': 0,
        'on_time_scans': 0,
      };
    }
  }

  /// Get day of week string
  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Clean up resources
  @override
  void dispose() {
    _scannerSubscription?.cancel();
    super.dispose();
  }

  /// Reconnect to scanner subsystem
  Future<void> reconnect() async {
    _scannerSubscription?.cancel();
    await initialize();
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    try {
      // Ping the scanner subsystem
      final response = await _supabase
          .from('scanner_sessions')
          .select('id')
          .limit(1);
      
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
}