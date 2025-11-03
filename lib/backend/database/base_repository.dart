// Base Repository
// Abstract base class for all database repositories
// Implements common CRUD operations and patterns

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/environment.dart';

/// Base repository exception
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;
  
  RepositoryException(this.message, [this.originalError]);
  
  @override
  String toString() => 'RepositoryException: $message';
}

/// Query filter
class QueryFilter {
  final String column;
  final dynamic value;
  final String operator;
  
  QueryFilter({
    required this.column,
    required this.value,
    this.operator = 'eq',
  });
}

/// Sort order
class SortOrder {
  final String column;
  final bool ascending;
  
  SortOrder({
    required this.column,
    this.ascending = true,
  });
}

/// Pagination parameters
class PaginationParams {
  final int page;
  final int limit;
  
  PaginationParams({
    this.page = 1,
    this.limit = 20,
  });
  
  int get offset => (page - 1) * limit;
}

/// Base repository class
abstract class BaseRepository<T> {
  /// Table name in database
  String get tableName;
  
  /// Supabase client
  final SupabaseClient client = SupabaseConfig.client;
  
  /// Whether to use mock data fallback
  bool get useMockData => Environment.useMockData;
  
  // ==================== ABSTRACT METHODS ====================
  
  /// Convert database row to model
  T fromJson(Map<String, dynamic> json);
  
  /// Convert model to database row
  Map<String, dynamic> toJson(T model);
  
  /// Get mock data for testing
  List<Map<String, dynamic>> getMockData() {
    return [];
  }
  
  // ==================== CRUD OPERATIONS ====================
  
  /// Get all records
  Future<List<T>> getAll({
    List<QueryFilter>? filters,
    SortOrder? sortOrder,
    PaginationParams? pagination,
    String? select,
  }) async {
    try {
      if (useMockData) {
        return getMockData().map((json) => fromJson(json)).toList();
      }
      
      dynamic query = client.from(tableName).select(select ?? '*');
      
      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = _applyFilter(query, filter);
        }
      }
      
      // Apply sorting
      if (sortOrder != null) {
        query = query.order(sortOrder.column, ascending: sortOrder.ascending);
      }
      
      // Apply pagination
      if (pagination != null) {
        query = query.range(
          pagination.offset,
          pagination.offset + pagination.limit - 1,
        );
      }
      
      final response = await query;
      return (response as List).map((json) => fromJson(json)).toList();
      
    } catch (e) {
      throw RepositoryException('Failed to fetch $tableName', e);
    }
  }
  
  /// Get single record by ID
  Future<T?> getById(dynamic id, {String? select}) async {
    try {
      if (useMockData) {
        final mockData = getMockData();
        final item = mockData.firstWhere(
          (json) => json['id'] == id,
          orElse: () => {},
        );
        return item.isNotEmpty ? fromJson(item) : null;
      }
      
      final response = await client
          .from(tableName)
          .select(select ?? '*')
          .eq('id', id)
          .maybeSingle();
      
      return response != null ? fromJson(response) : null;
      
    } catch (e) {
      throw RepositoryException('Failed to fetch $tableName by ID: $id', e);
    }
  }
  
  /// Get single record by filter
  Future<T?> getOne({
    required List<QueryFilter> filters,
    String? select,
  }) async {
    try {
      if (useMockData) {
        final mockData = getMockData();
        // Simple mock filter implementation
        return mockData.isNotEmpty ? fromJson(mockData.first) : null;
      }
      
      var query = client.from(tableName).select(select ?? '*');
      
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
      
      final response = await query.maybeSingle();
      return response != null ? fromJson(response) : null;
      
    } catch (e) {
      throw RepositoryException('Failed to fetch single $tableName', e);
    }
  }
  
  /// Create new record
  Future<T> create(T model, {String? select}) async {
    try {
      if (useMockData) {
        // In mock mode, just return the model
        return model;
      }
      
      final json = toJson(model);
      
      final response = await client
          .from(tableName)
          .insert(json)
          .select(select ?? '*')
          .single();
      
      return fromJson(response);
      
    } catch (e) {
      throw RepositoryException('Failed to create $tableName', e);
    }
  }
  
  /// Create multiple records
  Future<List<T>> createMany(List<T> models, {String? select}) async {
    try {
      if (useMockData) {
        return models;
      }
      
      final jsonList = models.map((model) => toJson(model)).toList();
      
      final response = await client
          .from(tableName)
          .insert(jsonList)
          .select(select ?? '*');
      
      return (response as List).map((json) => fromJson(json)).toList();
      
    } catch (e) {
      throw RepositoryException('Failed to create multiple $tableName', e);
    }
  }
  
  /// Update record
  Future<T> update(dynamic id, Map<String, dynamic> data, {String? select}) async {
    try {
      if (useMockData) {
        // In mock mode, return updated mock data
        final mockData = getMockData().first;
        mockData.addAll(data);
        return fromJson(mockData);
      }
      
      final response = await client
          .from(tableName)
          .update(data)
          .eq('id', id)
          .select(select ?? '*')
          .single();
      
      return fromJson(response);
      
    } catch (e) {
      throw RepositoryException('Failed to update $tableName with ID: $id', e);
    }
  }
  
  /// Update multiple records
  Future<List<T>> updateMany({
    required List<QueryFilter> filters,
    required Map<String, dynamic> data,
    String? select,
  }) async {
    try {
      if (useMockData) {
        return getMockData().map((json) => fromJson(json)).toList();
      }
      
      var query = client.from(tableName).update(data);
      
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
      
      final response = await query.select(select ?? '*');
      
      return (response as List).map((json) => fromJson(json)).toList();
      
    } catch (e) {
      throw RepositoryException('Failed to update multiple $tableName', e);
    }
  }
  
  /// Delete record
  Future<bool> delete(dynamic id) async {
    try {
      if (useMockData) {
        return true;
      }
      
      await client
          .from(tableName)
          .delete()
          .eq('id', id);
      
      return true;
      
    } catch (e) {
      throw RepositoryException('Failed to delete $tableName with ID: $id', e);
    }
  }
  
  /// Delete multiple records
  Future<bool> deleteMany(List<QueryFilter> filters) async {
    try {
      if (useMockData) {
        return true;
      }
      
      var query = client.from(tableName).delete();
      
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
      
      await query;
      return true;
      
    } catch (e) {
      throw RepositoryException('Failed to delete multiple $tableName', e);
    }
  }
  
  /// Count records
  Future<int> count({List<QueryFilter>? filters}) async {
    try {
      if (useMockData) {
        return getMockData().length;
      }
      
      // For counting, we need to use a different approach in newer Supabase versions
      var query = client.from(tableName).select('*');
      
      if (filters != null) {
        for (final filter in filters) {
          query = _applyFilter(query, filter);
        }
      }
      
      final response = await query;
      return (response as List).length;
      
    } catch (e) {
      throw RepositoryException('Failed to count $tableName', e);
    }
  }
  
  /// Check if record exists
  Future<bool> exists(dynamic id) async {
    try {
      final record = await getById(id, select: 'id');
      return record != null;
    } catch (e) {
      return false;
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Apply filter to query
  dynamic _applyFilter(dynamic query, QueryFilter filter) {
    switch (filter.operator) {
      case 'eq':
        return query.eq(filter.column, filter.value);
      case 'neq':
        return query.neq(filter.column, filter.value);
      case 'gt':
        return query.gt(filter.column, filter.value);
      case 'gte':
        return query.gte(filter.column, filter.value);
      case 'lt':
        return query.lt(filter.column, filter.value);
      case 'lte':
        return query.lte(filter.column, filter.value);
      case 'like':
        return query.like(filter.column, filter.value);
      case 'ilike':
        return query.ilike(filter.column, filter.value);
      case 'in':
        return query.inFilter(filter.column, filter.value);
      case 'contains':
        return query.contains(filter.column, filter.value);
      case 'is':
        return query.is_(filter.column, filter.value);
      default:
        return query.eq(filter.column, filter.value);
    }
  }
  
  /// Execute raw SQL query (use with caution)
  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    try {
      if (useMockData) {
        return getMockData();
      }
      
      final response = await client.rpc('execute_sql', params: {'query': sql});
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      throw RepositoryException('Failed to execute raw query', e);
    }
  }
  
  /// Begin transaction (if supported)
  Future<void> transaction(Future<void> Function() callback) async {
    // Supabase doesn't support client-side transactions
    // This is a placeholder for future implementation
    await callback();
  }
  
  /// Log repository action
  void log(String message) {
    if (Environment.debugMode) {
      debugPrint('[$tableName] $message');
    }
  }
}