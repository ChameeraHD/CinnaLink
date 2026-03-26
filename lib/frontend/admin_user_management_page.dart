import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      userData['name']?.substring(0, 1).toUpperCase() ?? '?',
                    ),
                  ),
                  title: Text(userData['name'] ?? 'Unknown'),
                  subtitle: Text(
                    '${userData['email'] ?? ''}\nRole: ${userData['role'] ?? 'Unknown'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleUserAction(value, userId, userData),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
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
          value: selectedRole,
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
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    // For now, just show a message. In a real app, you'd implement user creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User creation not implemented yet')),
    );
  }
}
