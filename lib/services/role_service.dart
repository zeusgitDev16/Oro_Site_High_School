
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role.dart';

class RoleService {
  final _supabase = Supabase.instance.client;

  Future<List<Role>> getRoles() async {
    final response = await _supabase.from('roles').select();
    return (response as List).map((item) => Role.fromMap(item)).toList();
  }
}
