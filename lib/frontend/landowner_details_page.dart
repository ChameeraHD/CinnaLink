import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// 1. Import the generated localizations
import 'package:cinnalink/l10n/app_localizations.dart';

import '../backend/auth.dart';

class LandownerDetailsPage extends StatefulWidget {
  const LandownerDetailsPage({super.key});

  @override
  State<LandownerDetailsPage> createState() => _LandownerDetailsPageState();
}

class _LandownerDetailsPageState extends State<LandownerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = true;

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
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _farmNameController.text = profile['farmName'] ?? '';
        _locationController.text = profile['location'] ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    await AuthService.updateCurrentUserProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'farmName': _farmNameController.text.trim(),
      'location': _locationController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    // Use localized success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.updateSuccess)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Initialize the localization shortcut
    final l10n = AppLocalizations.of(context)!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellTopColors = isDark
        ? const [Color(0xFF1A130F), Color(0xFF352417)]
        : const [Color(0xFF8D5A2B), Color(0xFFC58A45)];
    final inputFill = isDark ? const Color(0xFF241B15) : Colors.grey.shade50;

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
                        l10n.myDetails, // UPDATED
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.manageProfileDesc, // UPDATED (Add this to ARB)
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.personalInformation, // UPDATED
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.fullName, // UPDATED
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: inputFill,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.errorEnterName; // UPDATED
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.email, // UPDATED
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: inputFill,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: l10n.phoneNumber, // UPDATED
                                    prefixIcon: const Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: inputFill,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.errorEnterPhone; // UPDATED
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  l10n.landInformation, // UPDATED
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _farmNameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.farmName, // UPDATED
                                    prefixIcon: const Icon(Icons.agriculture),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: inputFill,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.errorEnterFarmName; // UPDATED
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _locationController,
                                  decoration: InputDecoration(
                                    labelText: l10n.location, // UPDATED
                                    prefixIcon: const Icon(Icons.location_on),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: inputFill,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.errorEnterLocation; // UPDATED
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saveDetails,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Text(
                                      l10n.saveDetails, // UPDATED
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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