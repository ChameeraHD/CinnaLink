import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// 1. ADD THIS IMPORT
import 'package:cinnalink/l10n/app_localizations.dart';
import '../backend/auth.dart';
import '../main.dart'; 

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
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

  Future<void> _saveSettings() async {
    await AuthService.updateCurrentUserProfile({
      'notificationsEnabled': _notificationsEnabled,
      'darkModeEnabled': _darkModeEnabled,
      'language': _language,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!; // Shortcut for dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    setState(() => _isSigningOut = true);
    try {
      await AuthService.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $error')));
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. INITIALIZE THE LOCALIZATION SHORTCUT
    final l10n = AppLocalizations.of(context)!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF1A130F), Color(0xFF352417)]
        : const [Color(0xFF8D5A2B), Color(0xFFC58A45)];
    final tileColor = isDark ? const Color(0xFF241B15) : Colors.grey.shade50;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: shellTopColors,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settings, // CHANGED
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage app preferences and account actions',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.preferences, // CHANGED
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SwitchListTile(
                                  title: Text(l10n.pushNotifications), // CHANGED
                                  subtitle: const Text('Receive job updates'),
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(() => _notificationsEnabled = value);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SwitchListTile(
                                  title: Text(l10n.darkMode), // CHANGED
                                  subtitle: const Text('Use dark theme'),
                                  value: _darkModeEnabled,
                                  onChanged: (value) {
                                    setState(() => _darkModeEnabled = value);
                                    MyApp.of(context)?.toggleDarkMode(value);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _language, 
                                decoration: InputDecoration(
                                  labelText: l10n.language, // CHANGED
                                  prefixIcon: const Icon(Icons.language),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: tileColor,
                                ),
                                items: _languages.map((lang) {
                                  return DropdownMenuItem<String>(
                                    value: lang,
                                    child: Text(lang),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue == null) return;
                                  setState(() => _language = newValue);
                                  _updateAppLanguage(newValue);
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _saveSettings,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.saveSettings, // CHANGED
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _isSigningOut ? null : _logout,
                                  icon: _isSigningOut
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.red),
                                        )
                                      : const Icon(Icons.logout),
                                  label: Text(_isSigningOut
                                      ? 'Signing Out...'
                                      : l10n.logout), // CHANGED
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}