import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// IO (mobile/desktop) implementation
Future<String?> saveExcelBytesImpl(List<int> bytes, String fileName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  } catch (_) {
    // Fallback to a temp-based directory if Documents is unavailable
    try {
      final sep = Platform.pathSeparator;
      final fallback = Directory('${Directory.systemTemp.path}${sep}attendance_exports');
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      final path = '${fallback.path}${sep}$fileName';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      rethrow;
    }
  }
}

