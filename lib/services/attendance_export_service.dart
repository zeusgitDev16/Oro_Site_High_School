import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as xls;
import 'package:oro_site_high_school/utils/excel_download.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Service for exporting attendance data to SF2 (School Form 2) Excel format
///
/// This service contains all the SF2 export logic extracted from the old
/// attendance implementation. It can be used by both old and new attendance
/// implementations.
///
/// **Key Features:**
/// - Template-based SF2 export with XML injection
/// - Preserves Excel formatting and structure
/// - Supports month/quarter selection
/// - Handles school metadata (name, ID, division, region)
/// - Populates student roster with LRN
/// - Marks attendance (X for absent, tardy counts)
///
/// **Usage:**
/// ```dart
/// final service = AttendanceExportService();
/// await service.exportSf2({
///   context: context,
///   courseId: 123,
///   quarter: 1,
///   month: DateTime(2025, 11, 1),
///   students: [...],
///   classroomTitle: 'Grade 10 - Section A',
///   gradeLevel: '10',
/// });
/// ```
class AttendanceExportService {
  final _supabase = Supabase.instance.client;

  // SF2 export manual overrides (from dialog)
  String? _sf2OverrideSchoolYear;
  String? _sf2OverrideGradeLevel;
  String? _sf2OverrideSection;

  /// Export attendance to SF2 format
  ///
  /// **Parameters:**
  /// - `context`: BuildContext for showing dialogs/snackbars
  /// - `courseId`: Course ID (BIGINT) for attendance lookup
  /// - `quarter`: Quarter number (1-4)
  /// - `month`: Month to export
  /// - `students`: List of student maps with id, full_name, lrn
  /// - `classroomTitle`: Classroom title for section field
  /// - `gradeLevel`: Grade level (e.g., '10')
  /// - `schoolYear`: Optional school year override
  /// - `section`: Optional section override
  Future<void> exportSf2({
    required BuildContext context,
    required int courseId,
    required int quarter,
    required DateTime month,
    required List<Map<String, dynamic>> students,
    String? classroomTitle,
    String? gradeLevel,
    String? schoolYear,
    String? section,
  }) async {
    if (students.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students to export')),
        );
      }
      return;
    }

    // Show parameter dialog
    final params = await _pickSf2ParamsDialog(
      context: context,
      initialMonth: month,
      initialGradeLevel: gradeLevel,
      initialSection: classroomTitle ?? section,
    );

    if (params == null) return; // User cancelled

    final DateTime chosenMonth = params['month'] as DateTime;
    final String sy = (params['schoolYear'] as String?)?.trim() ?? '';
    final String grade = (params['gradeLevel'] as String?)?.trim() ?? '';
    final String sect = (params['section'] as String?)?.trim() ?? '';

    _sf2OverrideSchoolYear = sy;
    _sf2OverrideGradeLevel = grade;
    _sf2OverrideSection = sect;

    await _exportMonthlyAttendanceSf2TemplateBased(
      context: context,
      courseId: courseId,
      quarter: quarter,
      month: chosenMonth,
      students: students,
      classroomTitle: classroomTitle,
      gradeLevel: gradeLevel,
      overrideSchoolYear: sy,
      overrideGradeLevel: grade,
      overrideSection: sect,
    );
  }

  /// Helper: Get month name
  String _monthName(int m) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return (m >= 1 && m <= 12) ? names[m] : '';
  }

  /// Helper: Compute school year from month
  String _computeSchoolYear(DateTime m) {
    final y = m.year;
    return m.month >= 6 ? '$y-${y + 1}' : '${y - 1}-$y';
  }

  /// Helper: Format student name (Last, First Middle)
  String formatStudentName(Map<String, dynamic> student) {
    final lastName = (student['last_name'] ?? student['lastName'] ?? '').toString().trim();
    final firstName = (student['first_name'] ?? student['firstName'] ?? '').toString().trim();
    final middleName = (student['middle_name'] ?? student['middleName'] ?? '').toString().trim();
    
    if (lastName.isEmpty && firstName.isEmpty) {
      return (student['full_name'] ?? student['name'] ?? 'Unknown').toString();
    }
    
    final parts = <String>[];
    if (lastName.isNotEmpty) parts.add(lastName);
    if (firstName.isNotEmpty) parts.add(firstName);
    if (middleName.isNotEmpty) parts.add(middleName);
    
    return parts.join(', ');
  }

  /// Helper: Find cell containing text in Excel sheet
  ({int row, int col})? _findCellContainingText(
    xls.Sheet sheet,
    String substring,
  ) {
    final needle = substring.toLowerCase();
    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      for (int c = 0; c < row.length; c++) {
        final s = row[c]?.value?.toString() ?? '';
        if (s.toLowerCase().contains(needle)) {
          return (row: r, col: c);
        }
      }
    }
    return null;
  }

  /// Helper: Write value to the right of a cell
  bool _writeRightOf(
    xls.Sheet sheet,
    ({int row, int col}) pos,
    xls.CellValue value, {
    int maxOffset = 20,
  }) {
    for (int off = 1; off <= maxOffset; off++) {
      final ci = xls.CellIndex.indexByColumnRow(
        columnIndex: pos.col + off,
        rowIndex: pos.row,
      );
      final existing = sheet.cell(ci).value;
      final existingStr = existing?.toString() ?? '';
      if (existing == null || existingStr.isEmpty) {
        sheet.cell(ci).value = value;
        debugPrint('SF2: wrote header at r=${pos.row}, c=${pos.col + off}');
        return true;
      }
    }
    debugPrint(
      'SF2: could not find empty cell to the right of r=${pos.row}, c=${pos.col} within $maxOffset',
    );
    return false;
  }

  /// Helper: Find day columns in template
  ({int headerRow, Map<int, int> dayToCol})? _findDayColumnsInTemplate(
    xls.Sheet sheet,
  ) {
    int bestRow = -1;
    int bestCount = 0;
    final Map<int, int> dayToCol = {};

    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      int count = 0;
      final Map<int, int> tempMap = {};
      for (int c = 0; c < row.length; c++) {
        final cellValue = row[c]?.value;
        // Check if value is IntCellValue and extract the int
        if (cellValue != null) {
          final intVal = cellValue is xls.IntCellValue ? cellValue.value : null;
          if (intVal != null && intVal >= 1 && intVal <= 31) {
            tempMap[intVal] = c;
            count++;
          }
        }
      }
      if (count > bestCount) {
        bestCount = count;
        bestRow = r;
        dayToCol.clear();
        dayToCol.addAll(tempMap);
      }
    }

    if (bestCount < 3) return null;
    return (headerRow: bestRow, dayToCol: dayToCol);
  }

  /// Helper: Compute data start row
  int _computeDataStartRow(
    xls.Sheet sheet,
    ({int headerRow, Map<int, int> dayToCol}) dayCols,
  ) {
    final headerRow = dayCols.headerRow;
    // Check if next row has DOW labels
    if (headerRow + 1 < sheet.rows.length) {
      final nextRow = sheet.rows[headerRow + 1];
      for (final col in dayCols.dayToCol.values) {
        if (col < nextRow.length) {
          final s = nextRow[col]?.value?.toString().toLowerCase() ?? '';
          if (s.contains('m') ||
              s.contains('t') ||
              s.contains('w') ||
              s.contains('f') ||
              s.contains('sat') ||
              s.contains('sun')) {
            return headerRow + 2; // Skip DOW row
          }
        }
      }
    }
    return headerRow + 1;
  }

  /// Helper: Fill header field
  void _fillHeaderField(
    xls.Sheet sheet,
    String labelSubstring,
    String value, {
    int maxOffset = 20,
  }) {
    final pos = _findCellContainingText(sheet, labelSubstring);
    debugPrint(
      'SF2: header locate "$labelSubstring" => \'${pos?.row}\', \'${pos?.col}\'',
    );
    if (pos != null) {
      final ok = _writeRightOf(
        sheet,
        pos,
        xls.TextCellValue(value),
        maxOffset: maxOffset,
      );
      if (!ok) {
        debugPrint('SF2: writeRightOf failed for "$labelSubstring"');
      }
    } else {
      debugPrint('SF2: header label "$labelSubstring" not found');
    }
  }

  // Placeholder methods - will be implemented in next chunk
  Future<List<int>> _loadSf2TemplateBytes() async {
    throw UnimplementedError('To be implemented');
  }

  Future<void> _exportMonthlyAttendanceSf2TemplateBased({
    required BuildContext context,
    required int courseId,
    required int quarter,
    required DateTime month,
    required List<Map<String, dynamic>> students,
    String? classroomTitle,
    String? gradeLevel,
    String? overrideSchoolYear,
    String? overrideGradeLevel,
    String? overrideSection,
  }) async {
    throw UnimplementedError('To be implemented');
  }

  Future<Map<String, dynamic>?> _pickSf2ParamsDialog({
    required BuildContext context,
    required DateTime initialMonth,
    String? initialGradeLevel,
    String? initialSection,
  }) async {
    throw UnimplementedError('To be implemented');
  }
}
