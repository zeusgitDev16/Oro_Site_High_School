class Profile {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fullName;
  final int? roleId;
  final String? roleName; // Joined from roles table
  final String? avatarUrl;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? azureObjectId; // For Azure AD sync
  final DateTime? lastLogin;

  Profile({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.fullName,
    this.roleId,
    this.roleName,
    this.avatarUrl,
    this.email,
    this.phone,
    this.isActive = true,
    this.azureObjectId,
    this.lastLogin,
  });

  /// Create from database map
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      fullName: map['full_name'] as String?,
      roleId: map['role_id'] as int?,
      roleName: map['roles'] != null
          ? (map['roles'] as Map)['name'] as String?
          : null,
      avatarUrl: map['avatar_url'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      azureObjectId: map['azure_object_id'] as String?,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'full_name': fullName,
      'role_id': roleId,
      'avatar_url': avatarUrl,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'azure_object_id': azureObjectId,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  /// Get initials for avatar
  String get initials {
    if (fullName == null || fullName!.isEmpty) {
      return email?.substring(0, 2).toUpperCase() ?? '??';
    }

    final parts = fullName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName!.substring(0, 2).toUpperCase();
  }

  /// Get display name
  String get displayName => fullName ?? email ?? 'Unknown User';

  /// Check if user is active
  bool get canLogin => isActive;

  /// Get role display name
  String get roleDisplayName {
    if (roleName != null) return _formatRoleName(roleName!);

    switch (roleId) {
      case 1:
        return 'Administrator';
      case 2:
        return 'Teacher';
      case 3:
        return 'Student';
      case 4:
        return 'Parent';
      case 5:
        return 'Grade Coordinator';
      default:
        return 'User';
    }
  }

  /// Format role name for display
  String _formatRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return 'Administrator';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'parent':
      case 'guardian':
        return 'Parent';
      case 'coordinator':
      case 'grade_coordinator':
        return 'Grade Coordinator';
      default:
        return role;
    }
  }

  /// Check if synced from Azure AD
  bool get isSyncedFromAzure => azureObjectId != null;

  /// Get last login display text
  String get lastLoginDisplay {
    if (lastLogin == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastLogin!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${lastLogin!.day}/${lastLogin!.month}/${lastLogin!.year}';
  }

  /// Copy with updated fields
  Profile copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    int? roleId,
    String? roleName,
    String? avatarUrl,
    String? email,
    String? phone,
    bool? isActive,
    String? azureObjectId,
    DateTime? lastLogin,
  }) {
    return Profile(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      azureObjectId: azureObjectId ?? this.azureObjectId,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $fullName, email: $email, role: $roleDisplayName, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// User role enum for type safety
enum UserRole {
  admin(1, 'Administrator'),
  teacher(2, 'Teacher'),
  student(3, 'Student'),
  parent(4, 'Parent'),
  coordinator(5, 'Grade Coordinator');

  final int id;
  final String displayName;

  const UserRole(this.id, this.displayName);

  static UserRole? fromId(int? id) {
    if (id == null) return null;
    return UserRole.values.firstWhere(
      (role) => role.id == id,
      orElse: () => UserRole.student,
    );
  }

  static UserRole? fromName(String? name) {
    if (name == null) return null;
    final lowerName = name.toLowerCase();

    for (final role in UserRole.values) {
      if (role.name.toLowerCase() == lowerName ||
          role.displayName.toLowerCase() == lowerName) {
        return role;
      }
    }

    return null;
  }
}
