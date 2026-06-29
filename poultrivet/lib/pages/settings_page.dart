import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_notifier.dart';
import '../models/farmer_model.dart';
import 'bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primary = Color.fromARGB(255, 19, 97, 39);

  FarmerModel? _farmer;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _profileLoading = false);
      return;
    }
    FarmerModel? farmer =
        await AuthService().getFarmerProfile(user.uid);
    if (farmer == null) {
      await Future.delayed(const Duration(seconds: 2));
      farmer = await AuthService().getFarmerProfile(user.uid);
    }
    if (mounted) {
      setState(() {
        _farmer = farmer;
        _profileLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
      // AuthGate will redirect to LoginPage automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.isDark;
    final fontSize = themeNotifier.fontSize;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [

          // ── Profile ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: _profileLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: primary))
                : Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                primary.withValues(alpha: 0.15),
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primary),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _farmer?.fullName ?? 'Farmer',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (_farmer?.district.isNotEmpty == true)
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              _farmer!.district,
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _farmer?.phoneNumber ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
          ),

          // ── Appearance ────────────────────────────────────────────────
          _sectionHeader('APPEARANCE'),
          const SizedBox(height: 12),

          // Dark mode
          

          // Font size
          _settingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBox(Icons.format_size),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Font Size',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          'Preview: ${fontSize.round()}px',
                          style: TextStyle(
                              fontSize: fontSize - 3,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: fontSize,
                  min: 12,
                  max: 24,
                  divisions: 6,
                  activeColor: primary,
                  label: '${fontSize.round()}px',
                  onChanged: (value) =>
                      themeNotifier.setFontSize(value),
                ),
                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Small',
                        style: TextStyle(fontSize: 10)),
                    Text('Medium',
                        style: TextStyle(fontSize: 10)),
                    Text('Large',
                        style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── User preferences ──────────────────────────────────────────
          _sectionHeader('USER PREFERENCES'),
          const SizedBox(height: 12),

          _listItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Alerts, updates & reminders',
          ),
          _listItem(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
          ),
          _listItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage data & permissions',
          ),

          const SizedBox(height: 30),

          // ── Account ───────────────────────────────────────────────────
          _sectionHeader('ACCOUNT'),
          const SizedBox(height: 12),

          // Phone number display
          if (_farmer != null)
            _settingsCard(
              child: Row(
                children: [
                  _iconBox(Icons.phone_outlined),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Phone Number',
                            style: TextStyle(fontSize: 16)),
                        Text(
                          _farmer!.phoneNumber,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Sign out
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _signOut,
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'PoulVet v1.0.0 — Made with care 🐔',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _initials {
    if (_farmer == null || _farmer!.fullName.trim().isEmpty) {
      return '?';
    }
    final parts = _farmer!.fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: primary),
    );
  }

  Widget _listItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
