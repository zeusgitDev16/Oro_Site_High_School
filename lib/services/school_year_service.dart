import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school_year_simple.dart';

/// Service for managing school years in the database
class SchoolYearService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all school years (sorted by start_year descending)
  Future<List<SchoolYearSimple>> getAllSchoolYears() async {
    try {
      final response = await _supabase
          .from('school_years')
          .select()
          .eq('is_active', true)
          .order('start_year', ascending: false);

      return (response as List)
          .map((json) => SchoolYearSimple.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching school years: $e');
      rethrow;
    }
  }

  /// Get current school year
  Future<SchoolYearSimple?> getCurrentSchoolYear() async {
    try {
      final response = await _supabase
          .from('school_years')
          .select()
          .eq('is_current', true)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return SchoolYearSimple.fromJson(response);
    } catch (e) {
      print('❌ Error fetching current school year: $e');
      rethrow;
    }
  }

  /// Create a new school year (admin only)
  Future<SchoolYearSimple> createSchoolYear({
    required String yearLabel,
    required int startYear,
    required int endYear,
    bool isActive = true,
    bool isCurrent = false,
  }) async {
    try {
      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;

      print('📝 Creating school year...');
      print('   Year Label: $yearLabel');
      print('   Start Year: $startYear');
      print('   End Year: $endYear');
      print('   User ID: $userId');

      final data = {
        'year_label': yearLabel,
        'start_year': startYear,
        'end_year': endYear,
        'is_active': isActive,
        'is_current': isCurrent,
        'created_by': userId,
      };

      print('   Data to insert: $data');

      final response = await _supabase
          .from('school_years')
          .insert(data)
          .select()
          .single();

      print('✅ School year created successfully: $yearLabel');
      print('   Response: $response');
      return SchoolYearSimple.fromJson(response);
    } catch (e) {
      print('❌ Error creating school year: $e');
      print('   Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('   Postgrest code: ${e.code}');
        print('   Postgrest message: ${e.message}');
        print('   Postgrest details: ${e.details}');
        print('   Postgrest hint: ${e.hint}');
      }
      rethrow;
    }
  }

  /// Update a school year (admin only)
  Future<SchoolYearSimple> updateSchoolYear({
    required String id,
    String? yearLabel,
    int? startYear,
    int? endYear,
    bool? isActive,
    bool? isCurrent,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (yearLabel != null) data['year_label'] = yearLabel;
      if (startYear != null) data['start_year'] = startYear;
      if (endYear != null) data['end_year'] = endYear;
      if (isActive != null) data['is_active'] = isActive;
      if (isCurrent != null) data['is_current'] = isCurrent;

      final response = await _supabase
          .from('school_years')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      print('✅ School year updated: $id');
      return SchoolYearSimple.fromJson(response);
    } catch (e) {
      print('❌ Error updating school year: $e');
      rethrow;
    }
  }

  /// Delete a school year (admin only)
  Future<void> deleteSchoolYear(String id) async {
    try {
      await _supabase.from('school_years').delete().eq('id', id);
      print('✅ School year deleted: $id');
    } catch (e) {
      print('❌ Error deleting school year: $e');
      rethrow;
    }
  }

  /// Check if a school year already exists
  Future<bool> schoolYearExists(String yearLabel) async {
    try {
      final response = await _supabase
          .from('school_years')
          .select('id')
          .eq('year_label', yearLabel)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking school year existence: $e');
      return false;
    }
  }

  /// Parse year label to extract start and end years
  /// Example: "2023-2024" returns {startYear: 2023, endYear: 2024}
  Map<String, int>? parseYearLabel(String yearLabel) {
    final regex = RegExp(r'^(\d{4})-(\d{4})$');
    final match = regex.firstMatch(yearLabel);

    if (match == null) return null;

    final startYear = int.parse(match.group(1)!);
    final endYear = int.parse(match.group(2)!);

    // Validate that end year is start year + 1
    if (endYear != startYear + 1) return null;

    return {'startYear': startYear, 'endYear': endYear};
  }
}
