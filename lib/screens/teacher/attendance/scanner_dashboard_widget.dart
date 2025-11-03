/// Scanner Dashboard Widget
/// Real-time attendance scanner monitoring for teachers
/// Shows live scan data from the external scanner subsystem

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/scanner_integration_service.dart';
import '../../../models/attendance_session.dart';
import 'dart:async';

class ScannerDashboardWidget extends StatefulWidget {
  final AttendanceSession? activeSession;
  final VoidCallback? onCreateSession;
  final VoidCallback? onEndSession;

  const ScannerDashboardWidget({
    super.key,
    this.activeSession,
    this.onCreateSession,
    this.onEndSession,
  });

  @override
  State<ScannerDashboardWidget> createState() => _ScannerDashboardWidgetState();
}

class _ScannerDashboardWidgetState extends State<ScannerDashboardWidget> {
  final ScannerIntegrationService _scannerService = ScannerIntegrationService();
  Timer? _refreshTimer;
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    setState(() => _isLoading = true);
    
    await _scannerService.initialize();
    await _loadStatistics();
    
    // Listen to scanner updates
    _scannerService.addListener(_onScannerUpdate);
    
    setState(() => _isLoading = false);
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadStatistics();
      _scannerService.checkConnection();
    });
  }

  Future<void> _loadStatistics() async {
    final stats = await _scannerService.getTodayStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
  }

  void _onScannerUpdate() {
    if (mounted) {
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildConnectionStatus(),
            const SizedBox(height: 20),
            if (widget.activeSession != null) ...[
              _buildActiveSessionInfo(),
              const SizedBox(height: 20),
              _buildScanStatistics(),
              const SizedBox(height: 20),
              _buildRecentScans(),
            ] else
              _buildNoActiveSession(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Card(
      elevation: 4,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to scanner system...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: Colors.blue.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Scanner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Real-time QR code scanning system',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (widget.activeSession != null)
          ElevatedButton.icon(
            onPressed: widget.onEndSession,
            icon: const Icon(Icons.stop),
            label: const Text('End Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: widget.onCreateSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = _scannerService.isConnected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            isConnected 
                ? 'Scanner System Connected' 
                : 'Scanner System Disconnected',
            style: TextStyle(
              color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (!isConnected)
            TextButton(
              onPressed: () async {
                await _scannerService.reconnect();
              },
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionInfo() {
    final session = widget.activeSession!;
    final now = DateTime.now();
    final scanDeadline = session.scheduleStart.add(
      Duration(minutes: session.scanTimeLimitMinutes),
    );
    final isWithinScanTime = now.isBefore(scanDeadline);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Active Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isWithinScanTime ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isWithinScanTime ? 'SCANNING' : 'LATE SCANNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSessionInfoRow('Course', session.courseName),
          if (session.sectionName != null)
            _buildSessionInfoRow('Section', session.sectionName!),
          _buildSessionInfoRow(
            'Schedule',
            '${_formatTime(session.scheduleStart)} - ${_formatTime(session.scheduleEnd)}',
          ),
          _buildSessionInfoRow(
            'Scan Deadline',
            _formatTime(scanDeadline),
          ),
          if (!isWithinScanTime)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Students scanning now will be marked as LATE',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Scans',
            '${_statistics['total_scans'] ?? 0}',
            Icons.qr_code,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'On Time',
            '${_statistics['on_time_scans'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Late',
            '${_statistics['late_scans'] ?? 0}',
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Failed',
            '${_scannerService.failedScans}',
            Icons.error,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Scan Feed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getScanStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting for scans...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final scans = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  return _buildScanItem(scan);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanItem(Map<String, dynamic> scan) {
    final isLate = scan['is_late'] ?? false;
    final scanTime = DateTime.parse(scan['scan_time']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLate ? Colors.orange.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLate ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan['student_name'] ?? 'Unknown Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'LRN: ${scan['student_lrn']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(scanTime),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isLate ? 'LATE' : 'ON TIME',
                style: TextStyle(
                  fontSize: 10,
                  color: isLate ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveSession() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Scanning Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a session to begin scanning student attendance',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onCreateSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Scanning Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getScanStream() {
    // This would connect to the real-time scan feed
    // For now, returning an empty stream
    return Stream.value([]);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}