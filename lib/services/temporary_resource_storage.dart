import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/temporary_resource.dart';

/// Service for managing temporary resources in CREATE mode
/// Stores resources in SharedPreferences until classroom is created
class TemporaryResourceStorage {
  static const String _storageKey = 'temp_classroom_resources';

  /// Save temporary resources to SharedPreferences
  /// Organized by subject ID for easy retrieval
  Future<void> saveResources(
    Map<String, List<TemporaryResource>> resourcesBySubject,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('💾 [RESOURCE SAVE] Starting save to SharedPreferences...');
      print(
        '💾 [RESOURCE SAVE] Total subjects with resources: ${resourcesBySubject.length}',
      );

      // Convert to JSON structure
      final Map<String, dynamic> toSave = {};
      int totalResources = 0;

      for (final entry in resourcesBySubject.entries) {
        final subjectId = entry.key;
        final resources = entry.value;

        if (resources.isNotEmpty) {
          toSave[subjectId] = resources.map((r) => r.toJson()).toList();
          totalResources += resources.length;

          print(
            '   📝 [RESOURCE SAVE] Subject: $subjectId | Resources: ${resources.length}',
          );
        }
      }

      await prefs.setString(_storageKey, json.encode(toSave));
      print(
        '💾 [RESOURCE SAVE] ✅ Successfully saved $totalResources resources',
      );
    } catch (e) {
      print('❌ [RESOURCE SAVE] Error saving temporary resources: $e');
      print('❌ [RESOURCE SAVE] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Load temporary resources from SharedPreferences
  /// Returns a map of subject ID to list of resources
  Future<Map<String, List<TemporaryResource>>> loadResources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? resourcesJson = prefs.getString(_storageKey);

      if (resourcesJson == null) {
        print('📦 [RESOURCE LOAD] No saved resources found');
        return {};
      }

      print('📦 [RESOURCE LOAD] Found saved data in SharedPreferences');
      final Map<String, dynamic> decoded = json.decode(resourcesJson);
      print(
        '📦 [RESOURCE LOAD] Decoded ${decoded.length} subject keys from JSON',
      );

      final Map<String, List<TemporaryResource>> result = {};
      int totalResources = 0;

      for (final entry in decoded.entries) {
        final subjectId = entry.key;
        final resourcesJson = entry.value as List<dynamic>;

        final resources = resourcesJson
            .map(
              (json) =>
                  TemporaryResource.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        result[subjectId] = resources;
        totalResources += resources.length;

        print(
          '   📥 [RESOURCE LOAD] Subject: $subjectId | Resources: ${resources.length}',
        );
      }

      print(
        '📦 [RESOURCE LOAD] ✅ Successfully loaded $totalResources resources',
      );
      return result;
    } catch (e) {
      print('❌ [RESOURCE LOAD] Error loading temporary resources: $e');
      print('❌ [RESOURCE LOAD] Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  /// Add a single resource to storage
  Future<void> addResource(String subjectId, TemporaryResource resource) async {
    try {
      // Load existing resources
      final resourcesBySubject = await loadResources();

      // Add new resource
      if (!resourcesBySubject.containsKey(subjectId)) {
        resourcesBySubject[subjectId] = [];
      }
      resourcesBySubject[subjectId]!.add(resource);

      // Save back
      await saveResources(resourcesBySubject);

      print(
        '✅ [RESOURCE ADD] Added resource "${resource.resourceName}" to subject $subjectId',
      );
    } catch (e) {
      print('❌ [RESOURCE ADD] Error adding resource: $e');
      rethrow;
    }
  }

  /// Remove a resource from storage
  Future<void> removeResource(String subjectId, String tempResourceId) async {
    try {
      // Load existing resources
      final resourcesBySubject = await loadResources();

      // Remove resource
      if (resourcesBySubject.containsKey(subjectId)) {
        resourcesBySubject[subjectId]!.removeWhere(
          (r) => r.tempId == tempResourceId,
        );

        // Remove subject key if no resources left
        if (resourcesBySubject[subjectId]!.isEmpty) {
          resourcesBySubject.remove(subjectId);
        }
      }

      // Save back
      await saveResources(resourcesBySubject);

      print(
        '✅ [RESOURCE REMOVE] Removed resource $tempResourceId from subject $subjectId',
      );
    } catch (e) {
      print('❌ [RESOURCE REMOVE] Error removing resource: $e');
      rethrow;
    }
  }

  /// Get resources for a specific subject and quarter
  Future<List<TemporaryResource>> getResourcesByQuarter(
    String subjectId,
    int quarter,
  ) async {
    try {
      final resourcesBySubject = await loadResources();
      final subjectResources = resourcesBySubject[subjectId] ?? [];

      return subjectResources.where((r) => r.quarter == quarter).toList();
    } catch (e) {
      print('❌ [RESOURCE GET] Error getting resources: $e');
      return [];
    }
  }

  /// Get all resources for a specific subject
  Future<List<TemporaryResource>> getResourcesBySubject(
    String subjectId,
  ) async {
    try {
      final resourcesBySubject = await loadResources();
      return resourcesBySubject[subjectId] ?? [];
    } catch (e) {
      print('❌ [RESOURCE GET] Error getting resources: $e');
      return [];
    }
  }

  /// Get resource counts by quarter for a subject
  Future<Map<int, int>> getResourceCountsByQuarter(String subjectId) async {
    try {
      final resources = await getResourcesBySubject(subjectId);
      final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};

      for (final resource in resources) {
        counts[resource.quarter] = (counts[resource.quarter] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('❌ [RESOURCE COUNT] Error getting resource counts: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0};
    }
  }

  /// Clear all temporary resources
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('🗑️ [RESOURCE CLEAR] All temporary resources cleared');
    } catch (e) {
      print('❌ [RESOURCE CLEAR] Error clearing resources: $e');
      rethrow;
    }
  }

  /// Get all temporary resources (for uploading when classroom is created)
  Future<Map<String, List<TemporaryResource>>> getAllResources() async {
    return await loadResources();
  }
}
