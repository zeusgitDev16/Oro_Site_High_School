import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'dart:math';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get single profile by ID
  Future<Profile?> getProfile(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, roles(name)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromMap(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Get all users with advanced filtering
  Future<List<Profile>> getAllUsers({
    int page = 1,
    int limit = 50,
    String? roleFilter,
    String? searchQuery,
    bool? isActive,
    int? gradeLevel,
    String? section,
  }) async {
    try {
      var query = _supabase.from('profiles').select('*, roles(name)');

      // Apply filters BEFORE ordering and range
      if (roleFilter != null) {
        final roleId = await _getRoleIdByName(roleFilter);
        if (roleId != null) {
          query = query.eq('role_id', roleId);
        }
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%',
        );
      }

      // Apply ordering and pagination last
      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final data = response as List;
      print(
        'getAllUsers: fetched \\${data.length} rows (page: \\${page}, limit: \\${limit})',
      );

      return data.map((json) => Profile.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get active student profiles for the Add Member dialog, backed by the
  /// `students` table. This avoids relying on `profiles` RLS when listing
  /// candidates, while still using `profiles.id` as the primary key.
  Future<List<Profile>> getAllStudentsForClassroomAdd({
    int page = 1,
    int limit = 200,
  }) async {
    try {
      final response = await _supabase
          .from('students')
          .select(
            'id, first_name, middle_name, last_name, email, contact_number, is_active, created_at, updated_at',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final data = response as List;

      return data.map((row) {
        final map = row as Map<String, dynamic>;

        final parts = <String>[];
        void addPart(String? value) {
          if (value != null && value.trim().isNotEmpty) {
            parts.add(value.trim());
          }
        }

        addPart(map['first_name'] as String?);
        addPart(map['middle_name'] as String?);
        addPart(map['last_name'] as String?);

        final fullName = parts.join(' ').trim();

        return Profile(
          id: map['id'] as String,
          createdAt: _safeParseDateTime(map['created_at']),
          updatedAt: map['updated_at'] != null
              ? _safeParseDateTime(map['updated_at'])
              : null,
          fullName: fullName.isNotEmpty
              ? fullName
              : (map['email'] as String?) ?? 'Student',
          roleId: UserRole.student.id,
          roleName: 'student',
          avatarUrl: null,
          email: map['email'] as String?,
          phone: map['contact_number'] as String?,
          isActive: map['is_active'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error fetching students for classroom Add Member dialog: $e');
      return <Profile>[];
    }
  }

  /// Get active teacher/coordinator profiles for the Add Member dialog,
  /// backed by the `teachers` table.
  Future<List<Profile>> getAllTeachersForClassroomAdd({
    int page = 1,
    int limit = 200,
  }) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select(
            'id, first_name, middle_name, last_name, is_active, is_grade_coordinator, created_at, updated_at',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final data = response as List;

      return data.map((row) {
        final map = row as Map<String, dynamic>;

        final parts = <String>[];
        void addPart(String? value) {
          if (value != null && value.trim().isNotEmpty) {
            parts.add(value.trim());
          }
        }

        addPart(map['first_name'] as String?);
        addPart(map['middle_name'] as String?);
        addPart(map['last_name'] as String?);

        final fullName = parts.join(' ').trim();

        // Derive a coarse role hint only for filtering/labels in the dialog.
        var roleName = 'teacher';
        var roleId = UserRole.teacher.id;
        final isCoordinator = map['is_grade_coordinator'] as bool? ?? false;
        if (isCoordinator) {
          roleName = 'grade_coordinator';
          roleId = UserRole.coordinator.id;
        }

        return Profile(
          id: map['id'] as String,
          createdAt: _safeParseDateTime(map['created_at']),
          updatedAt: map['updated_at'] != null
              ? _safeParseDateTime(map['updated_at'])
              : null,
          fullName: fullName.isNotEmpty ? fullName : 'Teacher',
          roleId: roleId,
          roleName: roleName,
          avatarUrl: null,
          email: null, // Email stays in profiles; omitted to avoid extra joins.
          phone: null,
          isActive: map['is_active'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error fetching teachers for classroom Add Member dialog: $e');
      return <Profile>[];
    }
  }

  DateTime _safeParseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  /// Search users
  Future<List<Profile>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, roles(name)')
          .or('full_name.ilike.%$query%,email.ilike.%$query%')
          .limit(50);

      return (response as List).map((json) => Profile.fromMap(json)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Get user count by role
  Future<Map<String, int>> getUserCountByRole() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('role_id, roles(name)')
          .eq('is_active', true);

      final counts = <String, int>{};
      for (final user in response) {
        final roleName = user['roles']?['name'] as String? ?? 'unknown';
        counts[roleName] = (counts[roleName] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting user counts: $e');
      return {};
    }
  }

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create user with comprehensive role-specific data
  Future<Profile> createUser({
    required String email,
    required String fullName,
    required int roleId,
    // Student-specific
    String? lrn,
    int? gradeLevel,
    String? section,
    String? phone,
    String? address,
    String? gender,
    DateTime? birthDate,
    // Parent/Guardian info
    String? parentEmail,
    String? guardianName,
    String? parentRelationship,
    // Teacher-specific
    String? employeeId,
    String? department,
    List<String>? subjects,
    bool? isGradeCoordinator,
    String? coordinatorGradeLevel,
    // SHS Teacher-specific
    bool? isSHSTeacher,
    String? shsTrack,
    List<String>? shsStrands,
    // Admin-specific
    bool? isHybrid,
    // Options
    bool validateLRN = false,
  }) async {
    try {
      // Optional LRN validation
      if (validateLRN && lrn != null) {
        final isValid = await _validateLRN(lrn);
        if (!isValid) {
          throw Exception('Invalid or duplicate LRN: $lrn');
        }
      }

      // Generate default password
      final password = _generateDefaultPassword(lrn ?? fullName);

      // Store current session tokens to restore later
      final currentAccessToken = _supabase.auth.currentSession?.accessToken;
      final currentRefreshToken = _supabase.auth.currentSession?.refreshToken;

      String userId;
      try {
        // Create auth user using admin API or sign-up
        final authResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'role_id': roleId},
        );

        if (authResponse.user == null) {
          throw Exception('Failed to create auth user');
        }

        userId = authResponse.user!.id;

        // Sign out the newly created user immediately
        await _supabase.auth.signOut();

        // Restore admin session if it existed
        if (currentAccessToken != null && currentRefreshToken != null) {
          try {
            await _supabase.auth.setSession(currentAccessToken);
          } catch (e) {
            print('Warning: Could not restore admin session: $e');
            // Continue anyway - the user was created successfully
          }
        }
      } catch (e) {
        // Restore admin session on error
        if (currentAccessToken != null && currentRefreshToken != null) {
          try {
            await _supabase.auth.setSession(currentAccessToken);
          } catch (_) {
            print('Warning: Could not restore admin session after error');
          }
        }
        rethrow;
      }

      // Create profile (now the foreign key constraint will be satisfied)
      final profileData = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role_id': roleId,
        'phone': phone,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').insert(profileData);

      // Role-specific record creation
      if (roleId == 3 && lrn != null && gradeLevel != null && section != null) {
        // Student
        await _createStudentRecord(
          userId: userId,
          lrn: lrn,
          fullName: fullName,
          gradeLevel: gradeLevel,
          section: section,
          email: email,
          address: address,
          gender: gender,
          birthDate: birthDate,
        );

        // Create parent/guardian link if provided
        if (parentEmail != null && guardianName != null) {
          await _createParentLink(
            studentId: userId,
            parentEmail: parentEmail,
            guardianName: guardianName,
            relationship: parentRelationship ?? 'parent',
            contactNumber: phone,
          );
        }
      } else if (roleId == 2 || (roleId == 1 && isHybrid == true)) {
        // Teacher or Hybrid Admin
        await _createTeacherRecord(
          userId: userId,
          employeeId:
              employeeId ?? 'EMP-${DateTime.now().millisecondsSinceEpoch}',
          fullName: fullName,
          department: department ?? 'General',
          subjects: subjects ?? [],
          isGradeCoordinator: isGradeCoordinator ?? false,
          coordinatorGradeLevel: coordinatorGradeLevel,
          isSHSTeacher: isSHSTeacher ?? false,
          shsTrack: shsTrack,
          shsStrands: shsStrands,
        );
      } else if (roleId == 5) {
        // ICT Coordinator (also a teacher)
        await _createTeacherRecord(
          userId: userId,
          employeeId:
              employeeId ?? 'COORD-${DateTime.now().millisecondsSinceEpoch}',
          fullName: fullName,
          department: 'ICT',
          subjects: subjects ?? ['Information Technology'],
          isGradeCoordinator: true,
          coordinatorGradeLevel: coordinatorGradeLevel ?? '7',
          isSHSTeacher: false,
        );
      }

      // Log activity
      await _logActivity(
        userId: userId,
        action: 'USER_CREATED',
        details: {
          'email': email,
          'role_id': roleId,
          'is_hybrid': isHybrid,
          'is_shs_teacher': isSHSTeacher,
          'created_by': _supabase.auth.currentUser?.id,
        },
      );

      print('✅ User created: $email (Password: $password)');
      return Profile.fromMap(profileData);
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Create profile (basic)
  Future<Profile> createProfile(Profile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .insert(profile.toMap())
          .select()
          .single();

      return Profile.fromMap(response);
    } catch (e) {
      print('Error creating profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update user profile
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('profiles').update(updates).eq('id', userId);

      // Log activity
      await _logActivity(
        userId: userId,
        action: 'USER_UPDATED',
        details: {
          'updates': updates,
          'updated_by': _supabase.auth.currentUser?.id,
        },
      );
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(String userId) async {
    await updateProfile(userId, {'is_active': false});

    await _logActivity(
      userId: userId,
      action: 'USER_DEACTIVATED',
      details: {
        'reason': 'Admin action',
        'deactivated_by': _supabase.auth.currentUser?.id,
      },
    );
  }

  /// Activate user
  Future<void> activateUser(String userId) async {
    await updateProfile(userId, {'is_active': true});

    await _logActivity(
      userId: userId,
      action: 'USER_ACTIVATED',
      details: {
        'reason': 'Admin action',
        'activated_by': _supabase.auth.currentUser?.id,
      },
    );
  }

  /// Reset user password
  Future<String> resetUserPassword(String userId, String? newPassword) async {
    try {
      final password = newPassword ?? _generateDefaultPassword(userId);

      // Log password reset
      await _supabase.from('password_resets').insert({
        'user_id': userId,
        'reset_by': _supabase.auth.currentUser?.id,
        'reset_type': 'admin_reset',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _logActivity(
        userId: userId,
        action: 'PASSWORD_RESET',
        details: {'reset_by': _supabase.auth.currentUser?.id},
      );

      return password;
    } catch (e) {
      print('Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete user (soft delete - deactivate instead)
  Future<void> deleteUser(String userId) async {
    await deactivateUser(userId);
  }

  // ============================================
  // STUDENT-SPECIFIC OPERATIONS
  // ============================================

  /// Create student record
  Future<void> _createStudentRecord({
    required String userId,
    required String lrn,
    required String fullName,
    required int gradeLevel,
    required String section,
    String? email,
    String? address,
    String? gender,
    DateTime? birthDate,
  }) async {
    try {
      final nameParts = fullName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2 ? nameParts[1] : '';

      await _supabase.from('students').insert({
        'id': userId,
        'lrn': lrn,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'grade_level': gradeLevel,
        'section': section,
        'email': email,
        'school_year': '2025-2026',
        'status': 'active',
        'is_active': true,
        'enrollment_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Auto-enroll in section courses
      await _autoEnrollInSectionCourses(userId, gradeLevel, section);
    } catch (e) {
      print('Error creating student record: $e');
      throw Exception('Failed to create student record: $e');
    }
  }

  /// Auto-enroll student in section courses
  Future<void> _autoEnrollInSectionCourses(
    String studentId,
    int gradeLevel,
    String section,
  ) async {
    try {
      // Get courses for this grade/section
      final courses = await _supabase
          .from('courses')
          .select('id')
          .eq('grade_level', gradeLevel)
          .eq('section', section)
          .eq('school_year', '2025-2026');

      // Enroll student in each course
      for (final course in courses) {
        await _supabase.from('enrollments').insert({
          'student_id': studentId,
          'course_id': course['id'],
          'status': 'active',
          'enrolled_at': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Auto-enrolled student in ${courses.length} courses');
    } catch (e) {
      print('Warning: Could not auto-enroll student: $e');
      // Don't throw - enrollment can be done manually later
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Generate default password
  String _generateDefaultPassword(String identifier) {
    final year = DateTime.now().year;
    final cleanIdentifier = identifier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '$cleanIdentifier@$year';
  }

  /// Validate LRN (12 digits, unique)
  Future<bool> _validateLRN(String lrn) async {
    try {
      // Check format (12 digits)
      if (lrn.length != 12 || !RegExp(r'^\d{12}$').hasMatch(lrn)) {
        return false;
      }

      // Check uniqueness
      final existing = await _supabase
          .from('students')
          .select('id')
          .eq('lrn', lrn)
          .maybeSingle();

      return existing == null;
    } catch (e) {
      print('Error validating LRN: $e');
      return false;
    }
  }

  /// Get role ID by name
  Future<int?> _getRoleIdByName(String roleName) async {
    try {
      final response = await _supabase
          .from('roles')
          .select('id')
          .eq('name', roleName.toLowerCase())
          .maybeSingle();

      return response?['id'] as int?;
    } catch (e) {
      print('Error getting role ID: $e');
      return null;
    }
  }

  /// Generate UUID v4 (RFC 4122 compliant)
  String _generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    // Format as UUID string
    return '${_toHex(bytes.sublist(0, 4))}-'
        '${_toHex(bytes.sublist(4, 6))}-'
        '${_toHex(bytes.sublist(6, 8))}-'
        '${_toHex(bytes.sublist(8, 10))}-'
        '${_toHex(bytes.sublist(10, 16))}';
  }

  /// Convert bytes to hex string
  String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Create parent/guardian link
  Future<void> _createParentLink({
    required String studentId,
    required String parentEmail,
    required String guardianName,
    required String relationship,
    String? contactNumber,
  }) async {
    try {
      await _supabase.from('parent_links').insert({
        'student_id': studentId,
        'parent_email': parentEmail,
        'guardian_name': guardianName,
        'relationship': relationship,
        'contact_number': contactNumber,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating parent link: $e');
      throw Exception('Failed to create parent link: $e');
    }
  }

  /// Create teacher record
  Future<void> _createTeacherRecord({
    required String userId,
    required String employeeId,
    required String fullName,
    required String department,
    required List<String> subjects,
    required bool isGradeCoordinator,
    String? coordinatorGradeLevel,
    required bool isSHSTeacher,
    String? shsTrack,
    List<String>? shsStrands,
  }) async {
    try {
      await _supabase.from('teachers').insert({
        'id': userId,
        'employee_id': employeeId,
        'full_name': fullName,
        'department': department,
        'subjects': subjects,
        'is_grade_coordinator': isGradeCoordinator,
        'coordinator_grade_level': coordinatorGradeLevel,
        'is_shs_teacher': isSHSTeacher,
        'shs_track': shsTrack,
        'shs_strands': shsStrands,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating teacher record: $e');
      throw Exception('Failed to create teacher record: $e');
    }
  }

  /// Log activity
  Future<void> _logActivity({
    required String userId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _supabase.from('activity_log').insert({
        'user_id': userId,
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Warning: Could not log activity: $e');
      // Don't throw - logging failure shouldn't break the operation
    }
  }
}
