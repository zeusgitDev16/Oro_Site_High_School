
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission.dart';

class PermissionService {
  final _supabase = Supabase.instance.client;

  Future<List<Permission>> getPermissions() async {
    final response = await _supabase.from('permissions').select();
    return (response as List).map((item) => Permission.fromMap(item)).toList();
  }
}
