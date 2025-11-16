import 'package:oro_site_high_school/models/sf9_core_value_rating.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for sf9_core_value_ratings table (behavior / core values).
class Sf9CoreValueRatingService {
  Sf9CoreValueRatingService._internal();
  static final Sf9CoreValueRatingService _instance =
      Sf9CoreValueRatingService._internal();
  factory Sf9CoreValueRatingService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load ratings for a student in a given school year.
  /// Optionally filter by quarter (1-4).
  Future<List<SF9CoreValueRating>> getRatingsForStudent({
    required String studentId,
    required String schoolYear,
    int? quarter,
  }) async {
    try {
      var query = _supabase
          .from('sf9_core_value_ratings')
          .select()
          .eq('student_id', studentId)
          .eq('school_year', schoolYear);

      if (quarter != null) {
        query = query.eq('quarter', quarter);
      }

      final response = await query
          .order('core_value_code')
          .order('indicator_code');

      final rows = response as List<dynamic>;
      return rows
          .map(
            (row) => SF9CoreValueRating.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('Sf9CoreValueRatingService.getRatingsForStudent error: $e\n$st');
      return [];
    }
  }

  /// Create or update a single core value rating.
  ///
  /// Unique key is (student_id, school_year, quarter, indicator_code).
  /// `recordedBy` defaults to the current Supabase user if not provided.
  Future<SF9CoreValueRating> saveRating({
    required String studentId,
    required String schoolYear,
    required int quarter,
    required String coreValueCode,
    required String indicatorCode,
    required String rating,
    String? recordedBy,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final recorderId =
          recordedBy ?? _supabase.auth.currentUser?.id.toString();

      if (recorderId == null || recorderId.isEmpty) {
        throw StateError(
          'Cannot save core value rating without an authenticated user.',
        );
      }

      final payload = <String, dynamic>{
        'student_id': studentId,
        'recorded_by': recorderId,
        'school_year': schoolYear,
        'quarter': quarter,
        'core_value_code': coreValueCode,
        'indicator_code': indicatorCode,
        'rating': rating,
        'updated_at': now,
      };

      final existing = await _supabase
          .from('sf9_core_value_ratings')
          .select('id')
          .eq('student_id', studentId)
          .eq('school_year', schoolYear)
          .eq('quarter', quarter)
          .eq('indicator_code', indicatorCode)
          .maybeSingle();

      Map<String, dynamic> row;
      if (existing != null) {
        row = await _supabase
            .from('sf9_core_value_ratings')
            .update(payload)
            .eq('id', existing['id'])
            .select()
            .single();
      } else {
        payload['created_at'] = now;
        row = await _supabase
            .from('sf9_core_value_ratings')
            .insert(payload)
            .select()
            .single();
      }

      return SF9CoreValueRating.fromJson(row);
    } catch (e, st) {
      // ignore: avoid_print
      print('Sf9CoreValueRatingService.saveRating error: $e\n$st');
      rethrow;
    }
  }

  /// Aggregate ratings into a nested map for SF9 export:
  /// {
  ///   coreValueCode: { indicatorCode: ratingCode }
  /// }
  Future<Map<String, Map<String, String>>> aggregateRatingsForExport({
    required String studentId,
    required String schoolYear,
    required int quarter,
  }) async {
    final ratings = await getRatingsForStudent(
      studentId: studentId,
      schoolYear: schoolYear,
      quarter: quarter,
    );

    final result = <String, Map<String, String>>{};
    for (final r in ratings) {
      final inner = result.putIfAbsent(
        r.coreValueCode,
        () => <String, String>{},
      );
      inner[r.indicatorCode] = r.rating;
    }
    return result;
  }
}
