
class Role {
  final int id;
  final DateTime createdAt;
  final String name;

  Role({
    required this.id,
    required this.createdAt,
    required this.name,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'],
      createdAt: DateTime.parse(map['created_at']),
      name: map['name'],
    );
  }
}
