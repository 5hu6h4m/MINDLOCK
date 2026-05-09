import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/data_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'legal_screen.dart';
import '../../core/providers/interests_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _overlayGranted = false;
  bool _accessibilityEnabled = false;
  bool _batteryOptExempt = false;
  bool _dndGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final overlay = await PlatformChannel.hasOverlayPermission();
    final accessibility = await PlatformChannel.isAccessibilityEnabled();
    final dnd = await PlatformChannel.isDNDPermissionGranted();
    if (mounted) {
      setState(() {
        _overlayGranted = overlay;
        _accessibilityEnabled = accessibility;
        _dndGranted = dnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── App Info ──────────────────────────────────────────────────────
          _AppInfoCard(),
          const SizedBox(height: 20),

          // ── Cloud Backup ──────────────────────────────────────────────────
          _SettingsSection(
            title: 'Cloud Account',
            icon: Icons.cloud_done_rounded,
            color: AppTheme.accentCyan,
            children: [
              if (!ref.read(authServiceProvider).isAvailable)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Firebase Not Configured',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cloud sync requires google-services.json.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                StreamBuilder<User?>(
                  stream: ref.watch(authServiceProvider).authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) {
                      return _NavSetting(
                        label: 'Login to Cloud',
                        trailing: 'Required',
                        onTap: () => context.go('/auth'),
                      );
                    } else {
                      return Column(
                        children: [
                          ListTile(
                            leading: user.photoURL != null 
                              ? CircleAvatar(backgroundImage: NetworkImage(user.photoURL!), radius: 14)
                              : const Icon(Icons.account_circle_rounded, color: AppTheme.accentCyan),
                            title: Text(user.isAnonymous ? 'Guest User' : user.displayName ?? user.email ?? 'User'),
                            subtitle: const Text('Data is isolated & secure', style: TextStyle(fontSize: 11)),
                            trailing: TextButton(
                              onPressed: () async {
                                await ref.read(authServiceProvider).signOut();
                                if (context.mounted) context.go('/check-auth');
                              },
                              child: const Text('Logout', style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
                            ),
                          ),
                          const Divider(color: AppTheme.borderColor, height: 1, indent: 16, endIndent: 16),
                          _NavSetting(
                            label: 'Manual Cloud Sync',
                            trailing: 'Sync Now',
                            onTap: () async {
                              await ref.read(dataSyncServiceProvider).fullSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Data synced with cloud! ☁️'), backgroundColor: AppTheme.accentCyan),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Permissions ───────────────────────────────────────────────────
          _SettingsSection(
            title: 'Permissions',
            icon: Icons.security_rounded,
            color: AppTheme.primaryPurple,
            children: [
              _PermissionTile(
                icon: Icons.layers_rounded,
                label: 'Display over other apps',
                subtitle: 'Required for full-screen reminders',
                granted: _overlayGranted,
                onRequest: () async {
                  await PlatformChannel.openOverlaySettings();
                  await Future.delayed(const Duration(seconds: 2));
                  await _checkPermissions();
                },
              ),
              _PermissionTile(
                icon: Icons.accessibility_new_rounded,
                label: 'Accessibility Service',
                subtitle: 'Required for app monitoring',
                granted: _accessibilityEnabled,
                onRequest: () async {
                  await PlatformChannel.openAccessibilitySettings();
                  await Future.delayed(const Duration(seconds: 2));
                  await _checkPermissions();
                },
              ),
              _PermissionTile(
                icon: Icons.battery_charging_full_rounded,
                label: 'Battery Optimization',
                subtitle: 'Required for background alarms',
                granted: _batteryOptExempt,
                onRequest: () async {
                  await PlatformChannel.requestBatteryOptimizationExemption();
                  setState(() => _batteryOptExempt = true);
                },
              ),
              _PermissionTile(
                icon: Icons.do_not_disturb_on_rounded,
                label: 'Do Not Disturb Access',
                subtitle: 'Required for Smart DND',
                granted: _dndGranted,
                onRequest: () async {
                  await PlatformChannel.setDNDMode(true);
                  await Future.delayed(const Duration(seconds: 2));
                  await _checkPermissions();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Notifications ─────────────────────────────────────────────────
          _SettingsSection(
            title: 'Notifications',
            icon: Icons.notifications_rounded,
            color: AppTheme.accentCyan,
            children: [
              _ToggleSetting(
                label: 'Sound for reminders',
                value: settings.soundEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('soundEnabled', val),
              ),
              _ToggleSetting(
                label: 'Vibration',
                value: settings.vibrationEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('vibrationEnabled', val),
              ),
              _ToggleSetting(
                label: 'Badge count',
                value: settings.badgeEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('badgeEnabled', val),
              ),
              _ToggleSetting(
                label: 'Awareness Pulse (2h)',
                value: settings.awarenessPulseEnabled,
                onChanged: (val) async {
                  await PlatformChannel.setAwarenessMode(val);
                  ref.read(settingsProvider.notifier).updateSetting('awarenessPulseEnabled', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Appearance ────────────────────────────────────────────────────
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            color: AppTheme.accentAmber,
            children: [
              _DropdownSetting(
                label: 'Theme',
                value: themeMode.name[0].toUpperCase() + themeMode.name.substring(1),
                options: const ['Dark', 'Light', 'System'],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(themeProvider.notifier).setTheme(val);
                  }
                },
              ),
            ],
          ),
          // ── Nightly Schedule ──────────────────────────────────────────────
          _SettingsSection(
            title: 'Nightly Lockdown',
            icon: Icons.nightlight_round,
            color: AppTheme.primaryPurple,
            children: [
              ListTile(
                title: const Text('Schedule Time', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                subtitle: Text(
                  '${settings.reflectionHour.toString().padLeft(2, '0')}:${settings.reflectionMinute.toString().padLeft(2, '0')} PM',
                  style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.access_time_rounded, color: AppTheme.primaryPurple),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: settings.reflectionHour, minute: settings.reflectionMinute),
                  );
                  if (time != null) {
                    ref.read(settingsProvider.notifier).updateReflectionTime(time.hour, time.minute);
                    await PlatformChannel.scheduleDailyReflection(hour: time.hour, minute: time.minute);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lockdown scheduled for ${time.format(context)} daily! 🌙'),
                          backgroundColor: AppTheme.primaryPurple,
                        ),
                      );
                    }
                  }
                },
              ),
              _ToggleSetting(
                label: 'Auto-start reflection',
                value: true, // Always true for now if scheduled
                onChanged: (val) {
                  if (val) {
                    PlatformChannel.scheduleDailyReflection(
                      hour: settings.reflectionHour,
                      minute: settings.reflectionMinute,
                    );
                  } else {
                    // Logic to cancel?
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Focus ─────────────────────────────────────────────────────────
          _SettingsSection(
            title: 'Focus & Discipline',
            icon: Icons.center_focus_strong_rounded,
            color: AppTheme.accentGreen,
            children: [
              _ToggleSetting(
                label: 'Daily discipline score',
                value: settings.disciplineScoreEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('disciplineScoreEnabled', val),
              ),
              _ToggleSetting(
                label: 'AI smart suggestions',
                value: settings.aiSuggestionsEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('aiSuggestionsEnabled', val),
              ),
              _ToggleSetting(
                label: 'Streak tracking',
                value: settings.streakTrackingEnabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSetting('streakTrackingEnabled', val),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── My Goals & Interests ──────────────────────────────────────────
          _SettingsSection(
            title: 'My Goals & Interests',
            icon: Icons.auto_awesome_rounded,
            color: AppTheme.accentCyan,
            children: [
              _InterestsSelector(),
              ListTile(
                title: const Text('Preview Nightly Journal', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryPurple),
                onTap: () => context.push('/reflection/overlay'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── About ─────────────────────────────────────────────────────────
          _SettingsSection(
            title: 'Support & About',
            icon: Icons.info_rounded,
            color: AppTheme.textMuted,
            children: [
              _NavSetting(
                label: 'Check for Updates',
                trailing: 'v1.0.0',
                onTap: () {},
              ),
              _NavSetting(
                label: 'Share App with Friends',
                onTap: () async {
                  try {
                    final apkPath = await PlatformChannel.getAppApkPath();
                    if (apkPath != null) {
                      final tempDir = await getTemporaryDirectory();
                      final shareFile = File('${tempDir.path}/MINDLOCK.apk');
                      await File(apkPath).copy(shareFile.path);
                      await Share.shareXFiles([XFile(shareFile.path)], text: 'Check out MINDLOCK!');
                    }
                  } catch (e) {
                    debugPrint('Share failed: $e');
                  }
                },
              ),
              _NavSetting(
                label: 'Contact Support',
                onTap: () => PlatformChannel.openEmail('shubhamja9863@gmail.com', 'MINDLOCK Feedback'),
              ),
              _NavSetting(
                label: 'Privacy Policy',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Privacy Policy', content: PrivacyPolicy.content))),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                Text('By 5hu6h4m', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('MindLock System v1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple.withOpacity(0.15), AppTheme.accentBlue.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.accentBlue]),
            ),
            child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MINDLOCK', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Digital Discipline System', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text('v1.0.0', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    const Divider(color: AppTheme.borderColor, height: 0, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool granted;
  final VoidCallback onRequest;

  const _PermissionTile({required this.icon, required this.label, required this.subtitle, required this.granted, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: granted ? AppTheme.accentGreen : AppTheme.textMuted, size: 20),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      trailing: granted
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 20)
          : TextButton(onPressed: onRequest, child: const Text('Enable', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold))),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryPurple,
      dense: true,
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.bgDarkCard,
        style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 13),
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _NavSetting extends StatelessWidget {
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _NavSetting({required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
      onTap: onTap,
    );
  }
}

class _InterestsSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(userInterestsProvider);
    final allInterests = InterestApps.mapping.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allInterests.map((interest) {
          final isSelected = selected.contains(interest);
          return FilterChip(
            label: Text(interest, style: const TextStyle(fontSize: 11)),
            selected: isSelected,
            onSelected: (_) => ref.read(userInterestsProvider.notifier).toggleInterest(interest),
            selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
            checkmarkColor: AppTheme.primaryPurple,
            backgroundColor: AppTheme.bgDark,
            labelStyle: TextStyle(color: isSelected ? AppTheme.primaryPurple : AppTheme.textMuted),
          );
        }).toList(),
      ),
    );
  }
}
