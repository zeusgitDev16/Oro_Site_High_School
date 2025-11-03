
import 'dart:convert';

class BatchUpload {
  final int id;
  final DateTime createdAt;
  final String uploaderId;
  final String uploadType;
  final String status;
  final String filePath;
  final Map<String, dynamic>? results;

  BatchUpload({
    required this.id,
    required this.createdAt,
    required this.uploaderId,
    required this.uploadType,
    required this.status,
    required this.filePath,
    this.results,
  });

  factory BatchUpload.fromMap(Map<String, dynamic> map) {
    return BatchUpload(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      uploaderId: map['uploader_id'],
      uploadType: map['upload_type'],
      status: map['status'],
      filePath: map['file_path'],
      results: map['results'] != null ? jsonDecode(map['results']) : null,
    );
  }
}
