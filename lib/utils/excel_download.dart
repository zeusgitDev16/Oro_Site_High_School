import 'excel_download_io.dart' if (dart.library.html) 'excel_download_web.dart';

/// Saves Excel bytes to the user's device.
///
/// On mobile/desktop (IO): writes to Application Documents directory and returns the saved path.
/// On Web: triggers a browser download and returns null.
Future<String?> saveExcelBytes(List<int> bytes, String fileName) =>
    saveExcelBytesImpl(bytes, fileName);

