
class RolePermission {
  final int roleId;
  final int permissionId;

  RolePermission({
    required this.roleId,
    required this.permissionId,
  });

  factory RolePermission.fromMap(Map<String, dynamic> map) {
    return RolePermission(
      roleId: map['role_id'],
      permissionId: map['permission_id'],
    );
  }
}
