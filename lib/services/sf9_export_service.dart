import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/classroom.dart';

class SF9ExportService {
  SF9ExportService._();

  static final SF9ExportService instance = SF9ExportService._();

  static const _jhsFrontPath =
      'assets/SF9 (Learners Progress Report Card) Template for JHS.pdf';
  static const _jhsBackPath =
      'assets/SF9 (Learners Progress Report Card) Template for JHS back.pdf';
  static const _shsPath =
      "assets/SF 9 - SHS (Learner's Progress Report Card ).pdf";

  Future<void> exportSF9ReportCard({
    required String studentId,
    required Classroom classroom,
    required int quarter,
  }) async {
    if (studentId.isEmpty) {
      throw Exception('Missing student id for SF9 export');
    }
    if (quarter < 1 || quarter > 4) {
      throw Exception('Quarter must be between 1 and 4');
    }

    final client = Supabase.instance.client;

    try {
      // Load student header info (best-effort; ignore failures)
      Map<String, dynamic>? studentRow;
      Map<String, dynamic>? profileRow;
      try {
        studentRow = await client
            .from('students')
            .select('lrn, grade_level, section')
            .eq('id', studentId)
            .maybeSingle();
      } catch (_) {
        studentRow = null;
      }

      try {
        profileRow = await client
            .from('profiles')
            .select('full_name')
            .eq('id', studentId)
            .maybeSingle();
      } catch (_) {
        profileRow = null;
      }

      final gradeRowsRaw = await client
          .from('student_grades')
          .select(
            'course_id, classroom_id, quarter, transmuted_grade, adjusted_grade, remarks',
          )
          .eq('student_id', studentId)
          .eq('classroom_id', classroom.id)
          .eq('quarter', quarter);

      final gradeRows = List<Map<String, dynamic>>.from(
        gradeRowsRaw as List? ?? const [],
      );

      // Derive subject/course metadata
      final courseIds = <String>{};
      for (final r in gradeRows) {
        final cid = r['course_id']?.toString();
        if (cid != null) courseIds.add(cid);
      }

      final courseTitles = <String, String>{};
      final courseTeacherIds = <String, String>{};
      final teacherNames = <String, String>{};
      String? schoolYearLabel = studentRow?['school_year'] as String?;

      if (courseIds.isNotEmpty) {
        final cc = await client
            .from('courses')
            .select('id, title, teacher_id, school_year')
            .inFilter('id', courseIds.toList());
        final teacherIds = <String>{};
        for (final c in cc as List) {
          final id = c['id'].toString();
          courseTitles[id] = (c['title'] as String? ?? '').trim();
          final tid = c['teacher_id']?.toString();
          if (tid != null) {
            courseTeacherIds[id] = tid;
            teacherIds.add(tid);
          }
          schoolYearLabel ??= (c['school_year'] as String?)?.trim();
        }
        if (teacherIds.isNotEmpty) {
          final tt = await client
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', teacherIds.toList());
          for (final t in tt as List) {
            teacherNames[t['id'].toString()] = (t['full_name'] as String? ?? '')
                .trim();
          }
        }
      }

      // Build subject rows and general average
      final subjects = <_Sf9SubjectRow>[];
      for (final r in gradeRows) {
        final cid = r['course_id']?.toString();
        if (cid == null) continue;
        final title = courseTitles[cid] ?? cid;
        final tid = courseTeacherIds[cid];
        final teacherName = tid != null ? (teacherNames[tid] ?? '') : '';
        final numVal = r['adjusted_grade'] ?? r['transmuted_grade'];
        final grade = numVal is num ? numVal.toDouble() : 0.0;
        final rem = (r['remarks'] as String?)?.trim();
        final remarks = rem != null && rem.isNotEmpty
            ? rem
            : (grade >= 75 ? 'PASSED' : 'FAILED');
        subjects.add(
          _Sf9SubjectRow(
            subject: title,
            teacherName: teacherName,
            grade: grade,
            remarks: remarks,
          ),
        );
      }

      double generalAverage = 0;
      final valid = subjects.where((s) => s.grade > 0).toList();
      if (valid.isNotEmpty) {
        generalAverage =
            valid.map((s) => s.grade).reduce((a, b) => a + b) / valid.length;
      }

      final rawName = _composeStudentName(studentRow);
      final profileName = (profileRow?['full_name'] as String? ?? '').trim();
      final studentName = rawName.isNotEmpty ? rawName : profileName;
      final lrn = (studentRow?['lrn'] as String?)?.trim() ?? '';
      final gradeLevel =
          (studentRow?['grade_level'] as num?)?.toInt() ?? classroom.gradeLevel;
      final sectionName =
          (studentRow?['section'] as String?)?.trim() ?? classroom.title;

      final templatePages = await _loadTemplatePages(classroom.schoolLevel);
      final pdfBytes = await _buildPdf(
        templatePages: templatePages,
        studentName: studentName,
        lrn: lrn,
        gradeLevel: gradeLevel,
        sectionName: sectionName,
        schoolYear: schoolYearLabel ?? '',
        quarter: quarter,
        subjects: subjects,
        generalAverage: generalAverage,
      );

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .split('.')
          .first;
      final safeName = studentName.isEmpty
          ? 'Student'
          : studentName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final fileName = 'SF9_${safeName}_Q${quarter}_$ts.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('SF9 export failed: $e\n$st');
      }
      rethrow;
    }
  }

  String _composeStudentName(Map<String, dynamic>? row) {
    if (row == null) return '';
    final first = (row['first_name'] as String? ?? '').trim();
    final middle = (row['middle_name'] as String? ?? '').trim();
    final last = (row['last_name'] as String? ?? '').trim();
    final parts = [first, middle, last].where((p) => p.isNotEmpty).toList();
    return parts.join(' ');
  }

  Future<List<_Sf9TemplatePage>> _loadTemplatePages(String schoolLevel) async {
    if (schoolLevel == Classroom.schoolLevelShs) {
      final data = await rootBundle.load(_shsPath);
      final bytes = data.buffer.asUint8List();
      return _rasterPdf(bytes);
    }
    final frontData = await rootBundle.load(_jhsFrontPath);
    final backData = await rootBundle.load(_jhsBackPath);
    final frontPages = await _rasterPdf(frontData.buffer.asUint8List());
    final backPages = await _rasterPdf(backData.buffer.asUint8List());
    return [...frontPages, ...backPages];
  }

  Future<List<_Sf9TemplatePage>> _rasterPdf(Uint8List bytes) async {
    final rasters = await Printing.raster(bytes, dpi: 100).toList();
    final pages = <_Sf9TemplatePage>[];
    for (final r in rasters) {
      final png = await r.toPng();
      pages.add(
        _Sf9TemplatePage(
          image: pw.MemoryImage(png),
          width: r.width.toDouble(),
          height: r.height.toDouble(),
        ),
      );
    }
    return pages;
  }

  Future<Uint8List> _buildPdf({
    required List<_Sf9TemplatePage> templatePages,
    required String studentName,
    required String lrn,
    required int gradeLevel,
    required String sectionName,
    required String schoolYear,
    required int quarter,
    required List<_Sf9SubjectRow> subjects,
    required double generalAverage,
  }) async {
    final doc = pw.Document();

    for (var i = 0; i < templatePages.length; i++) {
      final page = templatePages[i];
      final isFront = i == 0;
      final w = page.width;
      final h = page.height;
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(w, h),
          build: (context) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Image(page.image, fit: pw.BoxFit.cover),
                ),
                if (isFront)
                  _buildFrontOverlay(
                    w,
                    h,
                    studentName,
                    lrn,
                    gradeLevel,
                    sectionName,
                    schoolYear,
                    quarter,
                    subjects,
                    generalAverage,
                  ),
              ],
            );
          },
        ),
      );
    }

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _buildFrontOverlay(
    double w,
    double h,
    String studentName,
    String lrn,
    int gradeLevel,
    String sectionName,
    String schoolYear,
    int quarter,
    List<_Sf9SubjectRow> subjects,
    double generalAverage,
  ) {
    // Coordinates are expressed as fractions of page width/height for easier tuning.
    const nameX = 0.25;
    const nameY = 0.18;
    const lrnX = 0.75;
    const lrnY = 0.18;
    const gradeX = 0.25;
    const gradeY = 0.21;
    const sectionX = 0.55;
    const sectionY = 0.21;
    const syX = 0.75;
    const syY = 0.21;

    const subjectTableStartX = 0.08;
    const subjectTableStartY = 0.30;
    const subjectRowHeight = 0.025;

    final textStyle = pw.TextStyle(fontSize: 9);

    return pw.Stack(
      children: [
        pw.Positioned(
          left: w * nameX,
          top: h * nameY,
          child: pw.Text(studentName, style: textStyle),
        ),
        pw.Positioned(
          left: w * lrnX,
          top: h * lrnY,
          child: pw.Text(lrn, style: textStyle),
        ),
        pw.Positioned(
          left: w * gradeX,
          top: h * gradeY,
          child: pw.Text('Grade $gradeLevel', style: textStyle),
        ),
        pw.Positioned(
          left: w * sectionX,
          top: h * sectionY,
          child: pw.Text(sectionName, style: textStyle),
        ),
        pw.Positioned(
          left: w * syX,
          top: h * syY,
          child: pw.Text(schoolYear, style: textStyle),
        ),
        // Quarter label
        pw.Positioned(
          left: w * 0.08,
          top: h * 0.27,
          child: pw.Text('Quarter $quarter', style: textStyle),
        ),
        // Subject rows
        for (var i = 0; i < subjects.length; i++)
          pw.Positioned(
            left: w * subjectTableStartX,
            top: h * (subjectTableStartY + subjectRowHeight * i),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: w * 0.35,
                  child: pw.Text(subjects[i].subject, style: textStyle),
                ),
                pw.SizedBox(width: w * 0.02),
                pw.SizedBox(
                  width: w * 0.1,
                  child: pw.Text(
                    subjects[i].grade <= 0
                        ? ''
                        : subjects[i].grade.toStringAsFixed(0),
                    style: textStyle,
                  ),
                ),
                pw.SizedBox(width: w * 0.02),
                pw.SizedBox(
                  width: w * 0.25,
                  child: pw.Text(subjects[i].teacherName, style: textStyle),
                ),
                pw.SizedBox(width: w * 0.02),
                pw.SizedBox(
                  width: w * 0.18,
                  child: pw.Text(subjects[i].remarks, style: textStyle),
                ),
              ],
            ),
          ),
        // General average
        pw.Positioned(
          left: w * 0.55,
          top: h * 0.80,
          child: pw.Text(
            generalAverage <= 0 ? '' : generalAverage.toStringAsFixed(0),
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

class _Sf9TemplatePage {
  final pw.MemoryImage image;
  final double width;
  final double height;

  _Sf9TemplatePage({
    required this.image,
    required this.width,
    required this.height,
  });
}

class _Sf9SubjectRow {
  final String subject;
  final String teacherName;
  final double grade;
  final String remarks;

  _Sf9SubjectRow({
    required this.subject,
    required this.teacherName,
    required this.grade,
    required this.remarks,
  });
}
