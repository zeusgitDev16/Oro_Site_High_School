
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch_upload.dart';

class BatchUploadService {
  final _supabase = Supabase.instance.client;

  Future<List<BatchUpload>> getBatchUploadsForUploader(String uploaderId) async {
    final response = await _supabase.from('batch_uploads').select().eq('uploader_id', uploaderId);
    return (response as List).map((item) => BatchUpload.fromMap(item)).toList();
  }

  Future<BatchUpload> createBatchUpload(BatchUpload batchUpload) async {
    final response = await _supabase.from('batch_uploads').insert({
      'uploader_id': batchUpload.uploaderId,
      'upload_type': batchUpload.uploadType,
      'status': batchUpload.status,
      'file_path': batchUpload.filePath,
      'results': batchUpload.results,
    }).select().single();
    return BatchUpload.fromMap(response);
  }
}
