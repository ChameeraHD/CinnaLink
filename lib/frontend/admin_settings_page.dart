import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cinnalink/l10n/app_localizations.dart';
import '../backend/auth.dart';
import '../main.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  bool _isLoading = true;
  bool _isSigningOut = false;
  bool _isSuperAdmin = false;

  final List<String> _languages = ['English', 'Tamil', 'Sinhala'];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await AuthService.getCurrentUserProfile();
    final isSuperAdmin = await _checkIfSuperAdmin();
    if (!mounted) return;

    setState(() {
      if (profile != null) {
        _notificationsEnabled = profile['notificationsEnabled'] ?? true;
        _darkModeEnabled = profile['darkModeEnabled'] ?? false;
        _language = profile['language'] ?? 'English';
        _updateAppLanguage(_language);
      }
      _isSuperAdmin = isSuperAdmin;
      _isLoading = false;
    });
  }

  Future<bool> _checkIfSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final isSuperAdmin = doc.data()?['isSuperAdmin'] ?? false;
      return isSuperAdmin == true;
    } catch (e) {
      return false;
    }
  }

  void _updateAppLanguage(String languageName) {
    Locale newLocale;
    switch (languageName) {
      case 'Tamil':
        newLocale = const Locale('ta');
        break;
      case 'Sinhala':
        newLocale = const Locale('si');
        break;
      default:
        newLocale = const Locale('en');
    }
    MyApp.of(context)?.setLocale(newLocale);
  }

  Future<void> _updateProfile() async {
    await AuthService.updateCurrentUserProfile({
      'notificationsEnabled': _notificationsEnabled,
      'darkModeEnabled': _darkModeEnabled,
      'language': _language,
    });
    MyApp.of(context)?.toggleDarkMode(_darkModeEnabled);
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showOldPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: !showOldPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showOldPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showOldPassword = !showOldPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: !showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showNewPassword = !showNewPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => showConfirmPassword = !showConfirmPassword,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                try {
                  // Re-authenticate with current password
                  final user = _auth.currentUser;
                  final email = user?.email;
                  if (email == null) throw Exception('No user email found');

                  await user!.reauthenticateWithCredential(
                    EmailAuthProvider.credential(
                      email: email,
                      password: oldPasswordController.text,
                    ),
                  );

                  // Update password
                  await user.updatePassword(newPasswordController.text);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.code == 'wrong-password'
                            ? 'Current password is incorrect'
                            : 'Error: ${e.message}',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAdmin() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  hintText: 'admin@example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This admin cannot add other admins',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                try {
                  // Create new admin user account
                  final userCredential = await _auth
                      .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );

                  // Create user document in Firestore
                  await _firestore
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set({
                        'email': emailController.text.trim(),
                        'role': 'admin',
                        'isSuperAdmin':
                            false, // Regular admin, cannot add other admins
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Admin ${emailController.text.trim()} added successfully',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Error creating admin';
                  if (e.code == 'email-already-in-use') {
                    errorMessage = 'Email is already in use';
                  } else if (e.code == 'weak-password') {
                    errorMessage = 'Password is too weak';
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage)));
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Add Admin'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await AuthService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Admin Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),

          // Display admin level
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Icon(
                  _isSuperAdmin ? Icons.admin_panel_settings : Icons.security,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Text(
                  _isSuperAdmin ? 'Super Admin' : 'Admin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dark Mode Toggle
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() => _darkModeEnabled = value);
              _updateProfile();
            },
          ),

          // Language Selection
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(l10n),
          ),

          // Notifications Toggle
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _updateProfile();
            },
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your admin password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _changePassword,
          ),

          const SizedBox(height: 12),

          // Add Admin (only for super admins)
          if (_isSuperAdmin)
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add New Admin'),
                  subtitle: const Text('Create a new admin account'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _addAdmin,
                ),
                const SizedBox(height: 12),
              ],
            ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(_isSigningOut ? 'Signing Out...' : l10n.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _language = value);
                  _updateAppLanguage(value);
                  _updateProfile();
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
