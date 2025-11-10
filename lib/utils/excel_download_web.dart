// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation: triggers a browser download using an anchor element.
Future<String?> saveExcelBytesImpl(List<int> bytes, String fileName) async {
  final data = Uint8List.fromList(bytes);
  final blob = html.Blob(
    [data],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return null;
}

