
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_permission.dart';

class RolePermissionService {
  final _supabase = Supabase.instance.client;

  Future<List<RolePermission>> getPermissionsForRole(int roleId) async {
    final response = await _supabase.from('role_permissions').select().eq('role_id', roleId);
    return (response as List).map((item) => RolePermission.fromMap(item)).toList();
  }
}
