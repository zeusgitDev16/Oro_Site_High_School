
class Permission {
  final int id;
  final DateTime createdAt;
  final String name;

  Permission({
    required this.id,
    required this.createdAt,
    required this.name,
  });

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      name: map['name'],
    );
  }
}
