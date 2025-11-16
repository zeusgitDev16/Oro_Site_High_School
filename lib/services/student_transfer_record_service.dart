import 'package:oro_site_high_school/models/student_transfer_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing student_transfer_records used on SF9.
///
/// This mirrors other SF9 services and is intentionally thin:
/// - The database (with RLS) handles authorization
/// - This class focuses on querying and upserting transfer records
class StudentTransferRecordService {
  StudentTransferRecordService._internal();
  static final StudentTransferRecordService _instance =
      StudentTransferRecordService._internal();
  factory StudentTransferRecordService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all transfer records for a learner.
  ///
  /// If [schoolYear] is provided, results are filtered to that year only.
  Future<List<StudentTransferRecord>> getTransferRecordsForStudent({
    required String studentId,
    String? schoolYear,
  }) async {
    try {
      // ignore: avoid_print
      print(
        '📄 StudentTransferRecordService.getTransferRecordsForStudent '
        'studentId=$studentId schoolYear=${schoolYear ?? "<all>"}',
      );

      var query = _supabase
          .from('student_transfer_records')
          .select()
          .eq('student_id', studentId);

      if (schoolYear != null && schoolYear.isNotEmpty) {
        query = query.eq('school_year', schoolYear);
      }

      final response = await query.order('school_year', ascending: false);
      final rows = response as List<dynamic>;
      return rows
          .map(
            (row) =>
                StudentTransferRecord.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'StudentTransferRecordService.getTransferRecordsForStudent error: '
        '$e\n$st',
      );
      return [];
    }
  }

  /// Admin helper: get all transfer records with basic student info.
  ///
  /// Returns a list of maps where each entry has:
  /// - `record`: [StudentTransferRecord]
  /// - `student`: basic student fields (id, lrn, name, grade_level, section)
  Future<List<Map<String, dynamic>>> getAllTransferRecords({
    String? schoolYear,
    String? searchQuery,
    bool? isActive,
    String sortBy = 'admission_date',
    bool ascending = false,
  }) async {
    try {
      // ignore: avoid_print
      print(
        '📄 StudentTransferRecordService.getAllTransferRecords '
        'schoolYear=${schoolYear ?? "<all>"} '
        'search="${searchQuery ?? ""}" '
        'isActive=${isActive?.toString() ?? "<any>"} '
        'sortBy=$sortBy ascending=$ascending',
      );

      var query = _supabase.from('student_transfer_records').select('''
          *,
          students!inner(
            id,
            lrn,
            first_name,
            middle_name,
            last_name,
            grade_level,
            section
          )
        ''');

      if (schoolYear != null && schoolYear.isNotEmpty) {
        query = query.eq('school_year', schoolYear);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query;
      final rows = response as List<dynamic>;

      final items = rows.map((raw) {
        final row = raw as Map<String, dynamic>;
        final student = row['students'] as Map<String, dynamic>?;
        final record = StudentTransferRecord.fromJson(row);

        final firstName = (student?['first_name'] as String?) ?? '';
        final middleName = (student?['middle_name'] as String?) ?? '';
        final lastName = (student?['last_name'] as String?) ?? '';
        final nameParts = <String>[];
        if (firstName.isNotEmpty) nameParts.add(firstName);
        if (middleName.isNotEmpty) nameParts.add(middleName);
        if (lastName.isNotEmpty) nameParts.add(lastName);
        final displayName = nameParts.join(' ');

        return <String, Object?>{
          'record': record,
          'student': {
            'id': student?['id']?.toString(),
            'lrn': student?['lrn']?.toString(),
            'first_name': firstName,
            'middle_name': middleName,
            'last_name': lastName,
            'grade_level': student?['grade_level'],
            'section': student?['section'],
            'display_name': displayName,
          },
        };
      }).toList();

      final trimmedQuery = searchQuery?.trim().toLowerCase();
      List<Map<String, dynamic>> filtered = items.cast<Map<String, dynamic>>();
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
        filtered = items
            .where((item) {
              final student = item['student'] as Map<String, dynamic>? ?? {};
              final name = (student['display_name'] as String? ?? '')
                  .toLowerCase();
              final lrn = (student['lrn'] as String? ?? '').toLowerCase();
              return name.contains(trimmedQuery) || lrn.contains(trimmedQuery);
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      int compareNullable<T extends Comparable<Object?>>(T? a, T? b, bool asc) {
        if (a == null && b == null) return 0;
        if (a == null) return asc ? 1 : -1;
        if (b == null) return asc ? -1 : 1;
        final cmp = a.compareTo(b);
        return asc ? cmp : -cmp;
      }

      filtered.sort((a, b) {
        final ra = a['record'] as StudentTransferRecord;
        final rb = b['record'] as StudentTransferRecord;
        final sa = a['student'] as Map<String, dynamic>? ?? {};
        final sb = b['student'] as Map<String, dynamic>? ?? {};

        switch (sortBy) {
          case 'student_name':
            final nameA = (sa['display_name'] as String? ?? '').toLowerCase();
            final nameB = (sb['display_name'] as String? ?? '').toLowerCase();
            return compareNullable(nameA, nameB, ascending);
          case 'lrn':
            final lrnA = (sa['lrn'] as String? ?? '').toLowerCase();
            final lrnB = (sb['lrn'] as String? ?? '').toLowerCase();
            return compareNullable(lrnA, lrnB, ascending);
          case 'school_year':
            return compareNullable(ra.schoolYear, rb.schoolYear, ascending);
          case 'cancellation_date':
            return compareNullable(
              ra.cancellationDate,
              rb.cancellationDate,
              ascending,
            );
          case 'status':
            final statusA = ra.isActive ? 'active' : 'inactive';
            final statusB = rb.isActive ? 'active' : 'inactive';
            return compareNullable(statusA, statusB, ascending);
          case 'admission_date':
          default:
            return compareNullable(
              ra.admissionDate,
              rb.admissionDate,
              ascending,
            );
        }
      });

      return filtered;
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'StudentTransferRecordService.getAllTransferRecords error: $e\n$st',
      );
      return [];
    }
  }

  /// Get the active transfer record for a learner in a specific school year.
  ///
  /// Returns `null` if there is no active record.
  Future<StudentTransferRecord?> getActiveTransferRecord({
    required String studentId,
    required String schoolYear,
  }) async {
    try {
      // ignore: avoid_print
      print(
        '📄 StudentTransferRecordService.getActiveTransferRecord '
        'studentId=$studentId schoolYear=$schoolYear',
      );

      final response = await _supabase
          .from('student_transfer_records')
          .select()
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return StudentTransferRecord.fromJson(response);
    } catch (e, st) {
      // ignore: avoid_print
      print(
        'StudentTransferRecordService.getActiveTransferRecord error: '
        '$e\n$st',
      );
      return null;
    }
  }

  /// Create or update a transfer record.
  ///
  /// The natural key is (student_id, school_year, is_active).
  /// If a row with that combination already exists, it is updated; otherwise
  /// a new row is inserted.
  Future<StudentTransferRecord> saveTransferRecord({
    required String studentId,
    required String schoolYear,
    String? eligibilityForAdmissionGrade,
    int? admittedGrade,
    String? admittedSection,
    DateTime? admissionDate,
    String? fromSchool,
    String? toSchool,
    String? canceledIn,
    DateTime? cancellationDate,
    String? createdBy,
    String? approvedBy,
    bool isActive = true,
  }) async {
    try {
      // ignore: avoid_print
      print(
        '📄 StudentTransferRecordService.saveTransferRecord '
        'studentId=$studentId schoolYear=$schoolYear isActive=$isActive',
      );

      final now = DateTime.now().toIso8601String();
      final payload = <String, dynamic>{
        'student_id': studentId,
        'school_year': schoolYear,
        'eligibility_for_admission_grade': eligibilityForAdmissionGrade,
        'admitted_grade': admittedGrade,
        'admitted_section': admittedSection,
        'admission_date': admissionDate?.toIso8601String(),
        'from_school': fromSchool,
        'to_school': toSchool,
        'canceled_in': canceledIn,
        'cancellation_date': cancellationDate?.toIso8601String(),
        'approved_by': approvedBy,
        'is_active': isActive,
        'updated_at': now,
      };

      // Remove nulls so we don't overwrite existing values with null
      payload.removeWhere((_, value) => value == null);

      // Try to find an existing row for (student, year, is_active).
      final existing = await _supabase
          .from('student_transfer_records')
          .select('id')
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .eq('is_active', isActive)
          .maybeSingle();

      Map<String, dynamic> row;
      if (existing != null) {
        row = await _supabase
            .from('student_transfer_records')
            .update(payload)
            .eq('id', existing['id'])
            .select()
            .single();
      } else {
        final creatorId =
            createdBy ?? _supabase.auth.currentUser?.id.toString();
        if (creatorId != null && creatorId.isNotEmpty) {
          payload['created_by'] = creatorId;
        }
        payload['created_at'] = now;

        row = await _supabase
            .from('student_transfer_records')
            .insert(payload)
            .select()
            .single();
      }

      return StudentTransferRecord.fromJson(row);
    } catch (e, st) {
      // ignore: avoid_print
      print('StudentTransferRecordService.saveTransferRecord error: $e\n$st');
      rethrow;
    }
  }
}
