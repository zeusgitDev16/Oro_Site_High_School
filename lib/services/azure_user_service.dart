import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing users in Azure AD using Microsoft Graph API
class AzureUserService {
  final String _tenantId = dotenv.env['AZURE_TENANT_ID'] ?? '';
  final String _clientId = dotenv.env['AZURE_CLIENT_ID'] ?? '';
  final String _clientSecret = dotenv.env['AZURE_CLIENT_SECRET'] ?? '';

  String? _accessToken;
  DateTime? _tokenExpiry;

  // ============================================
  // AUTHENTICATION
  // ============================================

  /// Get access token for Microsoft Graph API
  Future<String> _getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    try {
      final tokenUrl =
          'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token';

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'scope': 'https://graph.microsoft.com/.default',
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

        print('✅ Azure AD access token obtained');
        return _accessToken!;
      } else {
        throw Exception(
            'Failed to get access token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting Azure AD access token: $e');
      rethrow;
    }
  }

  // ============================================
  // USER CREATION
  // ============================================

  /// Create user in Azure AD
  Future<Map<String, dynamic>> createAzureUser({
    required String email,
    required String displayName,
    required String password,
    String? givenName,
    String? surname,
    String? jobTitle,
    String? department,
    String? mobilePhone,
    bool forceChangePasswordNextSignIn = true,
  }) async {
    try {
      final token = await _getAccessToken();

      // Extract username from email (before @)
      final mailNickname = email.split('@')[0];

      // Prepare user data
      final userData = {
        'accountEnabled': true,
        'displayName': displayName,
        'mailNickname': mailNickname,
        'userPrincipalName': email,
        'passwordProfile': {
          'forceChangePasswordNextSignIn': forceChangePasswordNextSignIn,
          'password': password,
        },
      };

      // Add optional fields
      if (givenName != null) userData['givenName'] = givenName;
      if (surname != null) userData['surname'] = surname;
      if (jobTitle != null) userData['jobTitle'] = jobTitle;
      if (department != null) userData['department'] = department;
      if (mobilePhone != null) userData['mobilePhone'] = mobilePhone;

      final response = await http.post(
        Uri.parse('https://graph.microsoft.com/v1.0/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        final createdUser = json.decode(response.body);
        print('✅ Azure AD user created: ${createdUser['id']}');
        return createdUser;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            'Failed to create Azure user: ${response.statusCode} - ${error['error']['message']}');
      }
    } catch (e) {
      print('Error creating Azure AD user: $e');
      rethrow;
    }
  }

  // ============================================
  // USER MANAGEMENT
  // ============================================

  /// Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final token = await _getAccessToken();

      final response = await http.get(
        Uri.parse(
            'https://graph.microsoft.com/v1.0/users/$email?\$select=id,displayName,mail,userPrincipalName,jobTitle,department'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null; // User not found
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting Azure AD user: $e');
      return null;
    }
  }

  /// Update user in Azure AD
  Future<void> updateAzureUser({
    required String userId,
    String? displayName,
    String? givenName,
    String? surname,
    String? jobTitle,
    String? department,
    String? mobilePhone,
  }) async {
    try {
      final token = await _getAccessToken();

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (givenName != null) updates['givenName'] = givenName;
      if (surname != null) updates['surname'] = surname;
      if (jobTitle != null) updates['jobTitle'] = jobTitle;
      if (department != null) updates['department'] = department;
      if (mobilePhone != null) updates['mobilePhone'] = mobilePhone;

      final response = await http.patch(
        Uri.parse('https://graph.microsoft.com/v1.0/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 204) {
        print('✅ Azure AD user updated: $userId');
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating Azure AD user: $e');
      rethrow;
    }
  }

  /// Delete user from Azure AD
  Future<void> deleteAzureUser(String userId) async {
    try {
      final token = await _getAccessToken();

      final response = await http.delete(
        Uri.parse('https://graph.microsoft.com/v1.0/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        print('✅ Azure AD user deleted: $userId');
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting Azure AD user: $e');
      rethrow;
    }
  }

  /// Reset user password
  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
    bool forceChangePasswordNextSignIn = true,
  }) async {
    try {
      final token = await _getAccessToken();

      final response = await http.patch(
        Uri.parse('https://graph.microsoft.com/v1.0/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'passwordProfile': {
            'forceChangePasswordNextSignIn': forceChangePasswordNextSignIn,
            'password': newPassword,
          }
        }),
      );

      if (response.statusCode == 204) {
        print('✅ Azure AD user password reset: $userId');
      } else {
        throw Exception(
            'Failed to reset password: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error resetting Azure AD user password: $e');
      rethrow;
    }
  }

  /// Disable user account
  Future<void> disableUser(String userId) async {
    try {
      final token = await _getAccessToken();

      final response = await http.patch(
        Uri.parse('https://graph.microsoft.com/v1.0/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'accountEnabled': false}),
      );

      if (response.statusCode == 204) {
        print('✅ Azure AD user disabled: $userId');
      } else {
        throw Exception('Failed to disable user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error disabling Azure AD user: $e');
      rethrow;
    }
  }

  /// Enable user account
  Future<void> enableUser(String userId) async {
    try {
      final token = await _getAccessToken();

      final response = await http.patch(
        Uri.parse('https://graph.microsoft.com/v1.0/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'accountEnabled': true}),
      );

      if (response.statusCode == 204) {
        print('✅ Azure AD user enabled: $userId');
      } else {
        throw Exception('Failed to enable user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error enabling Azure AD user: $e');
      rethrow;
    }
  }

  // ============================================
  // BATCH OPERATIONS
  // ============================================

  /// Get all users (with pagination)
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 100,
    String? filter,
  }) async {
    try {
      final token = await _getAccessToken();

      var url =
          'https://graph.microsoft.com/v1.0/users?\$top=$limit&\$select=id,displayName,mail,userPrincipalName,jobTitle,department,accountEnabled';

      if (filter != null) {
        url += '&\$filter=$filter';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['value']);
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting Azure AD users: $e');
      return [];
    }
  }

  // ============================================
  // VALIDATION
  // ============================================

  /// Check if email is available in Azure AD
  Future<bool> isEmailAvailable(String email) async {
    final user = await getUserByEmail(email);
    return user == null;
  }

  /// Validate Azure AD configuration
  bool isConfigured() {
    return _tenantId.isNotEmpty &&
        _clientId.isNotEmpty &&
        _clientSecret.isNotEmpty;
  }
}
