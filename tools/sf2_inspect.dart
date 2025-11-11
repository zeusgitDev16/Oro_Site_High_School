// Quick one-off inspector for assets/School Form 2 (SF2).xlsx
// Prints sheet names, rough dimensions, and a preview of top rows to help
// document the official template structure without opening Excel manually.
//
// Usage:
//   dart run tools/sf2_inspect.dart
//
// This script is read-only and safe. It requires the 'excel' package
// declared in pubspec.yaml.

import 'dart:io';
import 'package:excel/excel.dart' as xls;

void main(List<String> args) async {
  final path = 'assets/School Form 2 (SF2).xlsx';
  final f = File(path);
  if (!await f.exists()) {
    stderr.writeln('Template not found at: $path');
    exitCode = 2;
    return;
  }

  late final List<int> bytes;
  try {
    bytes = await f.readAsBytes();
  } catch (e) {
    stderr.writeln('Failed to read template bytes: $e');
    exitCode = 3;
    return;
  }

  xls.Excel book;
  try {
    book = xls.Excel.decodeBytes(bytes);
  } catch (e) {
    stderr.writeln('Failed to decode .xlsx with excel package: $e');
    exitCode = 4;
    return;
  }

  print('--- SF2 Template Inspection ---');
  print('Workbook sheets:');
  for (final name in book.tables.keys) {
    print(' - "$name"');
  }

  if (book.tables.isEmpty) {
    print('No sheets found.');
    return;
  }

  // Inspect the first sheet as the presumed main SF2 sheet
  final firstSheetName = book.tables.keys.first;
  final sheet = book.tables[firstSheetName]!;

  // Dimensions
  final maxRows = sheet.maxRows;
  // excel 4.x may not expose maxCols; compute from rows
  int maxCols = 0;
  for (final row in sheet.rows) {
    if (row.length > maxCols) maxCols = row.length;
  }
  print('\nSheet: $firstSheetName');
  print('Dimensions: rows=$maxRows, cols=$maxCols');

  // Preview the first N rows and M columns (values only)
  const previewRows = 30; // keep small
  const previewCols = 20; // keep small

  String colLabel(int c) {
    // Convert 0-based index to Excel-like column labels (A,B,...,Z,AA,AB,...) for readability
    int n = c;
    String s = '';
    while (true) {
      final rem = n % 26;
      s = String.fromCharCode(65 + rem) + s;
      n = (n ~/ 26) - 1;
      if (n < 0) break;
    }
    return s;
  }

  // Header row with column letters
  final colHeader = List.generate(previewCols, (c) => colLabel(c)).join('\t');
  print('\nTop-left preview ($previewRows rows x $previewCols cols)');
  print('    \t$colHeader');

  for (int r = 0; r < maxRows && r < previewRows; r++) {
    final cells = <String>[];
    for (int c = 0; c < maxCols && c < previewCols; c++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
      );
      String s = cell.value?.toString() ?? '';
      if (s.length > 28) s = s.substring(0, 25) + '...';
      cells.add(s.replaceAll('\n', ' '));
    }
    print('${(r + 1).toString().padLeft(4)}\t${cells.join('\t')}');
  }

  // Note: The excel package has limited support for reading merges/styles/print settings.
  // We avoid mutating or re-encoding; this script is analysis-only.
  print('\n--- End of SF2 Template Inspection ---');
}
