import 'package:flutter/material.dart';
import '../../../services/profile_service.dart';
import '../../../models/profile.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();

  String _searchQuery = '';
  List<Profile> _allUsers = [];
  Map<String, int> _userCounts = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUsers();
    _loadUserCounts();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadUsers();
    }
  }

  /// Load users from backend
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current tab filter
      String? roleFilter;
      switch (_tabController.index) {
        case 1:
          roleFilter = 'student';
          break;
        case 2:
          roleFilter = 'teacher';
          break;
        case 3:
          roleFilter = 'admin';
          break;
        case 4:
          roleFilter = 'parent';
          break;
      }

      final users = await _profileService.getAllUsers(
        page: _currentPage,
        limit: _pageSize,
        roleFilter: roleFilter,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: true,
      );

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  /// Load user counts for tabs
  Future<void> _loadUserCounts() async {
    try {
      final counts = await _profileService.getUserCountByRole();
      setState(() {
        _userCounts = counts;
      });
    } catch (e) {
      print('Failed to load user counts: $e');
    }
  }

  /// Search users
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _profileService.searchUsers(query);
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  /// Deactivate user
  Future<void> _deactivateUser(Profile user) async {
    try {
      await _profileService.deactivateUser(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} has been deactivated'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _loadUsers();
      _loadUserCounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Reset user password
  Future<void> _resetPassword(Profile user) async {
    try {
      final newPassword = await _profileService.resetUserPassword(
        user.id,
        null,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password for ${user.displayName} has been reset.'),
                const SizedBox(height: 16),
                const Text(
                  'New Password:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    newPassword,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please share this password with the user securely.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _userCounts.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage All Users'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All ($totalCount)'),
            Tab(text: 'Students (${_userCounts['student'] ?? 0})'),
            Tab(text: 'Teachers (${_userCounts['teacher'] ?? 0})'),
            Tab(text: 'Admins (${_userCounts['admin'] ?? 0})'),
            Tab(text: 'Parents (${_userCounts['parent'] ?? 0})'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_allUsers),
                      _buildUserList(_allUsers),
                      _buildUserList(_allUsers),
                      _buildUserList(_allUsers),
                      _buildUserList(_allUsers),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search users by name or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadUsers();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (value == _searchQuery) {
              _searchUsers(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildUserList(List<Profile> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.roleDisplayName),
                child: Text(
                  user.initials,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          user.roleDisplayName,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: _getRoleColor(
                          user.roleDisplayName,
                        ).withOpacity(0.2),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        user.isActive ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: user.isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last login: ${user.lastLoginDisplay}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Password'),
                      ],
                    ),
                  ),
                  if (user.isActive)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Deactivate',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Activate',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  _handleUserAction(value.toString(), user);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Colors.blue;
      case 'teacher':
        return Colors.green;
      case 'administrator':
      case 'admin':
        return Colors.purple;
      case 'parent':
        return Colors.orange;
      case 'grade coordinator':
      case 'coordinator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _handleUserAction(String action, Profile user) {
    switch (action) {
      case 'reset':
        _showResetPasswordDialog(user);
        break;
      case 'deactivate':
        _showDeactivateDialog(user);
        break;
      case 'activate':
        _activateUser(user);
        break;
      case 'view':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View profile for ${user.displayName}')),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Edit ${user.displayName}')));
        break;
    }
  }

  void _showResetPasswordDialog(Profile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Reset password for "${user.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(user);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(Profile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate "${user.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deactivateUser(user);
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _activateUser(Profile user) async {
    try {
      await _profileService.activateUser(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.displayName} has been activated'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadUsers();
      _loadUserCounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
