// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xml/xml.dart';

import '../models/classroom.dart';
import '../utils/excel_download.dart';

class SF9ExportService {
  SF9ExportService._();

  static final SF9ExportService instance = SF9ExportService._();

  // Legacy JHS PDF template paths (kept for now to avoid breaking any
  // pending migration work, but not used by the XLSX export path).
  static const _jhsFrontPath =
      'assets/SF9 (Learners Progress Report Card) Template for JHS.pdf';
  static const _jhsBackPath =
      'assets/SF9 (Learners Progress Report Card) Template for JHS back.pdf';

  // Preferred SHS SF9 XLSX template path.
  static const _shsPath = 'assets/600002751-SF9-Excel-Template.xlsx';

  // JHS SF9 template currently provided as a DOCX file.
  static const _jhsDocxPath = 'assets/624205181-Report-Card-JHS.docx';

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
      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'SF9: building subject rows for student=$studentId classroom=${classroom.id} '
          'gradeRows=${gradeRows.length}',
        );
      }
      for (final r in gradeRows) {
        final cid = r['course_id']?.toString();
        if (cid == null) continue;
        final title = courseTitles[cid] ?? cid;
        final tid = courseTeacherIds[cid];
        final teacherName = tid != null ? (teacherNames[tid] ?? '') : '';
        final numVal = r['adjusted_grade'] ?? r['transmuted_grade'];
        double grade = numVal is num ? numVal.toDouble() : 0.0;
        if (!grade.isFinite) {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
              'SF9: non-finite grade detected for course=$cid raw=$numVal -> forcing to 0.0',
            );
          }
          grade = 0.0;
        }
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
        final sum = valid.map((s) => s.grade).reduce((a, b) => a + b);
        generalAverage = sum / valid.length;
      }
      if (!generalAverage.isFinite || generalAverage <= 0) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
            'SF9: generalAverage computed as non-finite or <= 0: $generalAverage '
            '(validCount=${valid.length}). Forcing to 0.',
          );
        }
        generalAverage = 0;
      } else if (kDebugMode) {
        // ignore: avoid_print
        print(
          'SF9: generalAverage=$generalAverage from ${valid.length} valid subject(s)',
        );
      }

      final rawName = _composeStudentName(studentRow);
      final profileName = (profileRow?['full_name'] as String? ?? '').trim();
      final studentName = rawName.isNotEmpty ? rawName : profileName;
      final lrn = (studentRow?['lrn'] as String?)?.trim() ?? '';
      final gradeLevel =
          (studentRow?['grade_level'] as num?)?.toInt() ?? classroom.gradeLevel;
      final sectionName =
          (studentRow?['section'] as String?)?.trim() ?? classroom.title;

      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .split('.')
          .first;
      final safeName = studentName.isEmpty
          ? 'Student'
          : studentName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final baseFileName = 'SF9_${safeName}_Q${quarter}_$ts';

      final level = classroom.schoolLevel;
      if (level == Classroom.schoolLevelShs) {
        final xlsxBytes = await _buildShsXlsx(
          studentName: studentName,
          lrn: lrn,
          gradeLevel: gradeLevel,
          sectionName: sectionName,
          schoolYear: schoolYearLabel ?? '',
          quarter: quarter,
          subjects: subjects,
          generalAverage: generalAverage,
        );
        await saveExcelBytes(xlsxBytes, '$baseFileName.xlsx');
      } else if (level == Classroom.schoolLevelJhs) {
        throw UnimplementedError(
          'SF9 XLSX export for JHS (DOCX template) is not yet implemented. '
          'Please provide an XLSX template or convert the DOCX template '
          '($_jhsDocxPath).',
        );
      } else {
        throw Exception('Unsupported school level for SF9 export: $level');
      }
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

  Future<List<int>> _buildShsXlsx({
    required String studentName,
    required String lrn,
    required int gradeLevel,
    required String sectionName,
    required String schoolYear,
    required int quarter,
    required List<_Sf9SubjectRow> subjects,
    required double generalAverage,
  }) async {
    // NOTE: This currently focuses on header-level fields (name, LRN, section,
    // school year, general average). The rest of the SF9 layout is preserved
    // from the template so teachers can continue to type into the exported
    // file.
    final templateBytes = await _loadShsTemplateBytes();
    final arc = ZipDecoder().decodeBytes(templateBytes, verify: false);

    if (kDebugMode) {
      debugPrint(
        'SF9: building SHS XLSX for student="$studentName", '
        'gradeLevel=$gradeLevel, section="$sectionName", '
        'quarter=$quarter, subjects=${subjects.length}, '
        'generalAverage=$generalAverage',
      );
    }

    ArchiveFile? sharedStringsFile;
    for (final f in arc.files) {
      if (_normArchiveName(f.name) == 'xl/sharedStrings.xml') {
        sharedStringsFile = f;
        break;
      }
    }
    if (sharedStringsFile == null) {
      throw Exception('SF9: sharedStrings.xml not found in SHS template.');
    }

    final sharedStringsXml = utf8.decode(
      sharedStringsFile.content as List<int>,
    );
    final sharedDoc = XmlDocument.parse(sharedStringsXml);

    void replaceLabel(String label, String value) {
      if (value.isEmpty) return;
      final targetKey = _normalizeLabel(label);
      for (final si in sharedDoc.findAllElements('si')) {
        final tElements = si.findAllElements('t');
        if (tElements.isEmpty) continue;
        final t = tElements.first;
        final raw = t.value ?? '';
        if (_normalizeLabel(raw) == targetKey) {
          t.children
            ..clear()
            ..add(XmlText('$label $value'));
          break;
        }
      }
    }

    replaceLabel('Name:', studentName);
    replaceLabel('LRN:', lrn);
    replaceLabel('Section:', sectionName);
    replaceLabel('School Year:', schoolYear);
    if (generalAverage > 0 && generalAverage.isFinite) {
      replaceLabel('General Average:', generalAverage.toStringAsFixed(0));
    }

    final modifiedSharedStrings = sharedDoc.toXmlString();
    final modifiedSharedBytes = utf8.encode(modifiedSharedStrings);

    final outArc = Archive();
    for (final f in arc.files) {
      if (_normArchiveName(f.name) == 'xl/sharedStrings.xml') {
        outArc.addFile(
          ArchiveFile(f.name, modifiedSharedBytes.length, modifiedSharedBytes),
        );
      } else {
        outArc.addFile(f);
      }
    }

    final outBytes = ZipEncoder().encode(outArc);
    if (outBytes == null) {
      throw Exception('SF9: failed to encode SHS XLSX archive.');
    }
    return outBytes;
  }

  Future<List<int>> _loadShsTemplateBytes() async {
    const preferred = _shsPath;
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest =
          jsonDecode(manifestJson) as Map<String, dynamic>;
      String? selected;
      if (manifest.containsKey(preferred)) {
        selected = preferred;
      } else {
        final candidates = manifest.keys.where((k) {
          final lower = k.toLowerCase();
          return lower.contains('sf9') && lower.endsWith('.xlsx');
        }).toList();
        if (candidates.isNotEmpty) {
          candidates.sort();
          selected = candidates.first;
        }
      }
      selected ??= preferred;
      final data = await rootBundle.load(selected);
      return data.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SF9: failed to resolve SHS template via manifest: $e');
      }
      final data = await rootBundle.load(preferred);
      return data.buffer.asUint8List();
    }
  }

  String _normalizeLabel(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  String _normArchiveName(String name) => name.replaceAll('\\', '/');

  // ignore: unused_element
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

  // ignore: unused_element
  Future<List<_Sf9TemplatePage>> _rasterPdf(Uint8List bytes) async {
    final rasters = await Printing.raster(bytes, dpi: 100).toList();
    final pages = <_Sf9TemplatePage>[];
    var pageIndex = 0;
    for (final r in rasters) {
      final rawWidth = r.width.toDouble();
      final rawHeight = r.height.toDouble();
      var width = rawWidth;
      var height = rawHeight;

      if (!width.isFinite || width <= 0) {
        width = PdfPageFormat.a4.width;
      }
      if (!height.isFinite || height <= 0) {
        height = PdfPageFormat.a4.height;
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'SF9: rasterized template page $pageIndex: '
          'raw=$rawWidth x $rawHeight, sanitized=$width x $height',
        );
      }

      final png = await r.toPng();
      pages.add(
        _Sf9TemplatePage(
          image: pw.MemoryImage(png),
          width: width,
          height: height,
        ),
      );
      pageIndex++;
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('SF9: total rasterized pages=${pages.length}');
    }
    return pages;
  }

  // ignore: unused_element
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
    required String schoolLevel,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'SF9: _buildPdf start: pages=${templatePages.length}, '
        'subjects=${subjects.length}, generalAverage=$generalAverage, '
        'schoolLevel=$schoolLevel',
      );
    }

    final doc = pw.Document();
    final pageCount = templatePages.length;

    for (var i = 0; i < pageCount; i++) {
      final page = templatePages[i];
      var w = page.width;
      var h = page.height;

      final originalW = w;
      final originalH = h;

      // Guard against invalid page sizes coming from rasterization.
      // The pdf package asserts that width/height must not be NaN.
      if (!w.isFinite || w <= 0) {
        w = PdfPageFormat.a4.width;
      }
      if (!h.isFinite || h <= 0) {
        h = PdfPageFormat.a4.height;
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'SF9: page $i format: raw=$originalW x $originalH, '
          'sanitized=$w x $h',
        );
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(w, h),
          build: (context) {
            return pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 0,
                  child: pw.Image(page.image, width: w, height: h),
                ),
                _buildPageOverlay(
                  pageIndex: i,
                  pageCount: pageCount,
                  schoolLevel: schoolLevel,
                  w: w,
                  h: h,
                  studentName: studentName,
                  lrn: lrn,
                  gradeLevel: gradeLevel,
                  sectionName: sectionName,
                  schoolYear: schoolYear,
                  quarter: quarter,
                  subjects: subjects,
                  generalAverage: generalAverage,
                ),
              ],
            );
          },
        ),
      );
    }

    final bytes = await doc.save();
    if (kDebugMode) {
      // ignore: avoid_print
      print('SF9: _buildPdf completed; output size=${bytes.length} bytes');
    }
    return Uint8List.fromList(bytes);
  }

  // ignore: unused_element
  pw.Widget _buildPageOverlay({
    required int pageIndex,
    required int pageCount,
    required String schoolLevel,
    required double w,
    required double h,
    required String studentName,
    required String lrn,
    required int gradeLevel,
    required String sectionName,
    required String schoolYear,
    required int quarter,
    required List<_Sf9SubjectRow> subjects,
    required double generalAverage,
  }) {
    // Page selection:
    // - Header is always on the first page.
    // - For JHS, subject grades go on the back page (index 1) when available.
    // - For SHS (and others), keep grades on the first page to preserve
    //   existing behavior.
    final isFirstPage = pageIndex == 0;
    final isJhs = schoolLevel == Classroom.schoolLevelJhs;
    final isHeaderPage = isFirstPage;
    final bool isGradesPage = isJhs && pageCount > 1
        ? pageIndex == 1
        : isFirstPage;

    // Coordinates are expressed as fractions of page width/height.
    // Header section (bottom half of the front page).
    const nameX = 0.20;
    const nameY = 0.63;
    const lrnX = 0.78;
    const lrnY = 0.19;
    const gradeX = 0.20;
    const gradeY = 0.73;
    const sectionX = 0.54;
    const sectionY = 0.73;
    const syX = 0.78;
    const syY = 0.24;
    const quarterLabelX = 0.20;
    const quarterLabelY = 0.58;

    // Subject table and general average (learning progress page).
    const subjectTableStartX = 0.09;
    const subjectTableStartY = 0.20;
    const subjectRowHeight = 0.027;
    const generalAverageX = 0.58;
    const generalAverageY = 0.86;

    // Area to blank out the pre-printed subject names on the template.
    const subjectAreaEndX = 0.70; // ~70% width: covers subject, grade, remarks
    const subjectAreaEndY = 0.85; // ~85% height: covers all subject rows

    final textStyle = pw.TextStyle(fontSize: 9);
    final children = <pw.Widget>[];

    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'SF9: _buildPageOverlay pageIndex=$pageIndex of ${pageCount - 1}, '
        'w=$w, h=$h, subjects=${subjects.length}, '
        'generalAverage=$generalAverage',
      );
    }

    if (isHeaderPage) {
      if (studentName.isNotEmpty) {
        children.add(
          pw.Positioned(
            left: w * nameX,
            top: h * nameY,
            child: pw.Text(studentName, style: textStyle),
          ),
        );
      }
      children.add(
        pw.Positioned(
          left: w * quarterLabelX,
          top: h * quarterLabelY,
          child: pw.Text('Quarter $quarter', style: textStyle),
        ),
      );
      if (lrn.isNotEmpty) {
        children.add(
          pw.Positioned(
            left: w * lrnX,
            top: h * lrnY,
            child: pw.Text(lrn, style: textStyle),
          ),
        );
      }
      children.add(
        pw.Positioned(
          left: w * gradeX,
          top: h * gradeY,
          child: pw.Text('Grade $gradeLevel', style: textStyle),
        ),
      );
      children.add(
        pw.Positioned(
          left: w * sectionX,
          top: h * sectionY,
          child: pw.Text(sectionName, style: textStyle),
        ),
      );
      if (schoolYear.isNotEmpty) {
        children.add(
          pw.Positioned(
            left: w * syX,
            top: h * syY,
            child: pw.Text(schoolYear, style: textStyle),
          ),
        );
      }
    }

    if (isGradesPage && subjects.isNotEmpty) {
      // First, blank out the template's pre-printed subject names in the
      // subject table area so that only our dynamic subjects are visible.
      final subjectAreaWidth = w * (subjectAreaEndX - subjectTableStartX);
      final subjectAreaHeight = h * (subjectAreaEndY - subjectTableStartY);

      children.add(
        pw.Positioned(
          left: w * subjectTableStartX,
          top: h * subjectTableStartY,
          child: pw.Container(
            width: subjectAreaWidth,
            height: subjectAreaHeight,
            color: PdfColors.white,
          ),
        ),
      );

      for (var i = 0; i < subjects.length; i++) {
        final rowTop = subjectTableStartY + subjectRowHeight * i;
        final row = subjects[i];
        final subjectLabel = row.teacherName.isEmpty
            ? row.subject
            : '${row.subject} (${row.teacherName})';

        final safeGrade = row.grade.isFinite && row.grade > 0 ? row.grade : 0.0;

        if (kDebugMode) {
          // ignore: avoid_print
          print(
            'SF9: subject row $i: subject="${row.subject}", '
            'teacher="${row.teacherName}", grade=${row.grade}, '
            'safeGrade=$safeGrade, rowTop=$rowTop',
          );
        }

        children.add(
          pw.Positioned(
            left: w * subjectTableStartX,
            top: h * rowTop,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: w * 0.33,
                  child: pw.Text(subjectLabel, style: textStyle),
                ),
                pw.SizedBox(width: w * 0.02),
                pw.SizedBox(
                  width: w * 0.08,
                  child: pw.Text(
                    safeGrade <= 0 ? '' : safeGrade.toStringAsFixed(0),
                    style: textStyle,
                  ),
                ),
                pw.SizedBox(width: w * 0.02),
                pw.SizedBox(
                  width: w * 0.18,
                  child: pw.Text(row.remarks, style: textStyle),
                ),
              ],
            ),
          ),
        );
      }

      if (generalAverage > 0 && generalAverage.isFinite) {
        children.add(
          pw.Positioned(
            left: w * generalAverageX,
            top: h * generalAverageY,
            child: pw.Text(generalAverage.toStringAsFixed(0), style: textStyle),
          ),
        );
      } else if (!generalAverage.isFinite && kDebugMode) {
        // ignore: avoid_print
        print(
          'SF9: generalAverage is non-finite in _buildPageOverlay: '
          '$generalAverage (will not render on PDF).',
        );
      }
    }

    if (children.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Stack(children: children);
  }
}

// ignore: unused_element
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
