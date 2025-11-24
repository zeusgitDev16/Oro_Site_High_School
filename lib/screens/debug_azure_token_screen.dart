import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Debug screen to inspect Azure AD token claims
/// This helps diagnose why email is not being extracted from Azure AD
class DebugAzureTokenScreen extends StatefulWidget {
  const DebugAzureTokenScreen({Key? key}) : super(key: key);

  @override
  State<DebugAzureTokenScreen> createState() => _DebugAzureTokenScreenState();
}

class _DebugAzureTokenScreenState extends State<DebugAzureTokenScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _tokenData;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inspectCurrentSession();
  }

  Future<void> _inspectCurrentSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = _supabase.auth.currentSession;
      
      if (session == null) {
        setState(() {
          _error = 'No active session. Please login first.';
          _isLoading = false;
        });
        return;
      }

      final user = session.user;
      
      // Extract all available data
      final data = {
        'user_id': user.id,
        'email': user.email,
        'phone': user.phone,
        'created_at': user.createdAt,
        'app_metadata': user.appMetadata,
        'user_metadata': user.userMetadata,
        'identities': user.identities?.map((identity) => {
          'id': identity.id,
          'provider': identity.provider,
          'identity_data': identity.identityData,
          'created_at': identity.createdAt,
          'updated_at': identity.updatedAt,
        }).toList(),
        'access_token_preview': session.accessToken.substring(0, 50) + '...',
      };

      setState(() {
        _tokenData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error inspecting session: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Azure AD Token'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _inspectCurrentSession,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : _tokenData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection('User ID', _tokenData!['user_id']),
                          _buildSection('Email', _tokenData!['email'] ?? '❌ NULL'),
                          _buildSection('Phone', _tokenData!['phone'] ?? 'NULL'),
                          _buildSection('Created At', _tokenData!['created_at']),
                          _buildJsonSection('App Metadata', _tokenData!['app_metadata']),
                          _buildJsonSection('User Metadata', _tokenData!['user_metadata']),
                          _buildIdentitiesSection(_tokenData!['identities']),
                          _buildSection('Access Token (Preview)', _tokenData!['access_token_preview']),
                          const SizedBox(height: 24),
                          _buildInstructions(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection(String title, dynamic value) {
    final valueStr = value?.toString() ?? 'NULL';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(valueStr),
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              valueStr,
              style: TextStyle(
                fontFamily: 'monospace',
                color: valueStr == '❌ NULL' || valueStr == 'NULL' 
                    ? Colors.red 
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonSection(String title, dynamic value) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(value ?? {});
    return _buildSection(title, jsonStr);
  }

  Widget _buildIdentitiesSection(List<dynamic>? identities) {
    if (identities == null || identities.isEmpty) {
      return _buildSection('Identities', 'NULL');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...identities.map((identity) {
              final jsonStr = const JsonEncoder.withIndent('  ').convert(identity);
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return const Card(
      color: Colors.blue,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Instructions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Check if "Email" shows ❌ NULL\n'
              '2. Look in "Identities" → "identity_data" for email fields\n'
              '3. Copy all data and share with developer\n'
              '4. Check Azure AD Token Configuration if email is missing',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

