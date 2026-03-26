import 'package:flutter/material.dart';
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

  final List<String> _languages = ['English', 'Tamil', 'Sinhala'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await AuthService.getCurrentUserProfile();
    if (!mounted) return;

    setState(() {
      if (profile != null) {
        _notificationsEnabled = profile['notificationsEnabled'] ?? true;
        _darkModeEnabled = profile['darkModeEnabled'] ?? false;
        _language = profile['language'] ?? 'English';
        _updateAppLanguage(_language);
      }
      _isLoading = false;
    });
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

          // Admin-specific settings could go here
          const Divider(),
          ListTile(
            title: const Text('System Maintenance'),
            subtitle: const Text('Perform system maintenance tasks'),
            trailing: const Icon(Icons.build),
            onTap: () {
              // TODO: Implement system maintenance
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System maintenance not implemented yet'),
                ),
              );
            },
          ),

          ListTile(
            title: const Text('Backup Data'),
            subtitle: const Text('Create a backup of all platform data'),
            trailing: const Icon(Icons.backup),
            onTap: () {
              // TODO: Implement data backup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data backup not implemented yet'),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

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
