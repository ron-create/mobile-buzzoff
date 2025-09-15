import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/notification_permission.dart';
import '../../utils/location_permission.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

class ThemeModeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final isNotifGranted = await NotificationPermission.isGranted();
    final isLocationGranted = await LocationPermission.isGranted();
    setState(() {
      _notificationsEnabled = isNotifGranted;
      _locationEnabled = isLocationGranted;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationPermission.requestPermission();
      setState(() {
        _notificationsEnabled = granted;
      });
      
      if (!granted && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enable Notifications', style: TextStyle(fontSize: Responsive.font(context, 18))),
            content: Text(
              'Would you like to enable notifications for BuzzOff?',
              style: TextStyle(fontSize: Responsive.font(context, 16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Not Now', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                  _checkPermissions();
                },
                child: Text('Enable', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Disable Notifications', style: TextStyle(fontSize: Responsive.font(context, 18))),
            content: Text(
              'To disable notifications, you need to go to your device settings.',
              style: TextStyle(fontSize: Responsive.font(context, 16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: Text('Open Settings', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      final granted = await LocationPermission.requestPermission();
      setState(() {
        _locationEnabled = granted;
      });
      
      if (!granted && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enable Location', style: TextStyle(fontSize: Responsive.font(context, 18))),
            content: Text(
              'Location access is needed to show nearby dengue cases and breeding sites.',
              style: TextStyle(fontSize: Responsive.font(context, 16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Not Now', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                  _checkPermissions();
                },
                child: Text('Enable', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Disable Location', style: TextStyle(fontSize: Responsive.font(context, 18))),
            content: Text(
              'To disable location access, you need to go to your device settings.',
              style: TextStyle(fontSize: Responsive.font(context, 16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: Text('Open Settings', style: TextStyle(fontSize: Responsive.font(context, 16))),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: Responsive.padding(context, 20),
            right: Responsive.padding(context, 20),
            top: Responsive.vertical(context, 16),
            bottom: MediaQuery.of(context).padding.bottom + Responsive.vertical(context, 20),
          ),
          children: [
            // Back Button and Title
            Padding(
              padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            _buildAppearanceSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildPermissionsSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildPrivacySection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Appearance'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Consumer<ThemeModeNotifier>(
            builder: (context, themeNotifier, _) {
              return Column(
                children: [
                  _buildThemeOption(
                    context,
                    title: 'Light Mode',
                    subtitle: 'Use light theme for the app',
                    icon: Icons.light_mode,
                    isSelected: themeNotifier.themeMode == ThemeMode.light,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
                  _buildThemeOption(
                    context,
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme for the app',
                    icon: Icons.dark_mode,
                    isSelected: themeNotifier.themeMode == ThemeMode.dark,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Permissions'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPermissionTile(
                context,
                icon: Icons.notifications,
                title: 'Push Notifications',
                subtitle: _notificationsEnabled 
                  ? 'Notifications are enabled' 
                  : 'Tap to enable notifications',
                isEnabled: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildPermissionTile(
                context,
                icon: Icons.location_on,
                title: 'Location Access',
                subtitle: _locationEnabled 
                  ? 'Location access is enabled' 
                  : 'Tap to enable location access',
                isEnabled: _locationEnabled,
                onChanged: _toggleLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Privacy'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () => context.push('/privacy-policy'),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildSettingsTile(
                context,
                icon: Icons.article,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                onTap: () {}, // Implement navigation
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Support'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & FAQ',
                subtitle: 'Get help and find answers',
                onTap: () => context.push('/help'),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: 'v1.0.0',
                onTap: null,
                showArrow: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Responsive.padding(context, 16)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.padding(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF5271FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF5271FF),
                size: Responsive.icon(context, 20),
              ),
            ),
            SizedBox(width: Responsive.padding(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 4)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 4)),
                decoration: BoxDecoration(
                  color: const Color(0xFF5271FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF5271FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5271FF),
              size: Responsive.icon(context, 20),
            ),
          ),
          SizedBox(width: Responsive.padding(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEnabled ? Colors.green : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF5271FF),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Responsive.padding(context, 16)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.padding(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF5271FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF5271FF),
                size: Responsive.icon(context, 20),
              ),
            ),
            SizedBox(width: Responsive.padding(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 4)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow && onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF999999),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }
} 