import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isSuperAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSuperAdminStatus();
  }

  Future<void> _checkSuperAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final isSuperAdmin = doc.data()?['isSuperAdmin'] ?? false;
      setState(() {
        _isSuperAdmin = isSuperAdmin == true;
        _tabController = TabController(
          length: _isSuperAdmin ? 3 : 2,
          vsync: this,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: _isSuperAdmin ? 3 : 2,
      child: Scaffold(
        appBar: TabBar(
          controller: _tabController,
          tabs: [
            if (_isSuperAdmin)
              const Tab(icon: Icon(Icons.security), text: 'Admins'),
            const Tab(icon: Icon(Icons.person_outline), text: 'Landowners'),
            const Tab(icon: Icon(Icons.people_outline), text: 'Workers'),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            if (_isSuperAdmin)
              _UserListView(
                role: 'admin',
                firestore: _firestore,
                onUserAction: _handleUserAction,
              ),
            _UserListView(
              role: 'landowner',
              firestore: _firestore,
              onUserAction: _handleUserAction,
              excludeSuperAdmins: !_isSuperAdmin,
            ),
            _UserListView(
              role: 'worker',
              firestore: _firestore,
              onUserAction: _handleUserAction,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _handleUserAction(
    String action,
    String userId,
    Map<String, dynamic> userData,
  ) {
    switch (action) {
      case 'edit':
        _showEditRoleDialog(userId, userData);
        break;
      case 'delete':
        _deleteUser(userId);
        break;
    }
  }

  void _showEditRoleDialog(String userId, Map<String, dynamic> userData) {
    final currentRole = userData['role'] ?? 'worker';
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Role'),
        content: DropdownButtonFormField<String>(
          initialValue: selectedRole,
          items: ['worker', 'landowner', 'admin']
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) => selectedRole = value!,
          decoration: const InputDecoration(labelText: 'Role'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('users').doc(userId).update({
                'role': selectedRole,
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Role updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('users').doc(userId).delete();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User creation not implemented yet')),
    );
  }
}

class _UserListView extends StatelessWidget {
  final String role;
  final FirebaseFirestore firestore;
  final Function(String, String, Map<String, dynamic>) onUserAction;
  final bool excludeSuperAdmins;

  const _UserListView({
    required this.role,
    required this.firestore,
    required this.onUserAction,
    this.excludeSuperAdmins = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.docs;

        // Filter out super admins if needed
        if (excludeSuperAdmins && role == 'admin') {
          users = users
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['isSuperAdmin'] !=
                    true,
              )
              .toList();
        }

        if (users.isEmpty) {
          return Center(child: Text('No ${role}s found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final isSuperAdmin = userData['isSuperAdmin'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Text(
                    userData['name']?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  userData['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['email'] ?? ''),
                    Text('Role: ${userData['role'] ?? 'Unknown'}'),
                    if (isSuperAdmin)
                      const Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => onUserAction(value, userId, userData),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Role'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete User'),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'landowner':
        return Colors.blue;
      case 'worker':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
