import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fitness_aura_athletix/presentation/screens/legal_doc_screen.dart';
import 'setting_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _hasApiKey = false;
  String? _aiEndpoint;
  bool _loading = true;

  bool _aiEnabled = true;
  bool _aiSendNotes = true;
  bool _communityProfileVisible = true;
  bool _communityShowStats = false;
  bool _cloudSyncEnabled = false;
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await StorageService().hasSecureString('llm_api_key');
    final endpoint = await StorageService().loadSecureString('llm_endpoint') ??
        await StorageService().loadStringSetting('llm_endpoint');

    final aiEnabled =
        await StorageService().loadBoolSetting('privacy_ai_enabled');
    final aiSendNotes =
        await StorageService().loadBoolSetting('privacy_ai_send_notes');
    final communityVisible = await StorageService()
        .loadBoolSetting('privacy_community_profile_visible');
    final communityStats =
        await StorageService().loadBoolSetting('privacy_community_show_stats');
    final cloudSync =
        await StorageService().loadBoolSetting('privacy_cloud_sync_enabled');
    final appLock =
        await StorageService().loadBoolSetting('privacy_app_lock_enabled');
    setState(() {
      _hasApiKey = has;
      _aiEndpoint = endpoint;
      _aiEnabled = aiEnabled ?? true;
      _aiSendNotes = aiSendNotes ?? true;
      _communityProfileVisible = communityVisible ?? true;
      _communityShowStats = communityStats ?? false;
      _cloudSyncEnabled = cloudSync ?? false;
      _appLockEnabled = appLock ?? false;
      _loading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    await StorageService().saveBoolSetting(key, value);
  }

  Future<void> _removeApiKey() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove stored API key?'),
        content: const Text(
          'This will delete the stored AI API key from secure storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService().deleteSecureString('llm_api_key');
    await StorageService().deleteSecureString('llm_endpoint');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('API key removed')));
    await _check();
  }

  Future<void> _exportWorkoutsCsv() async {
    try {
      final entries = await StorageService().loadEntries();
      final rows = <String>['id,date,workoutType,durationMinutes,notes'];
      for (final e in entries) {
        final notes = (e.notes ?? '')
            .replaceAll('\n', ' ')
            .replaceAll(',', ' ')
            .trim();
        rows.add(
          '${e.id},${e.date.toIso8601String()},${e.workoutType},${e.durationMinutes},$notes',
        );
      }
      final csv = rows.join('\n');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/workouts_export_${DateTime.now().toIso8601String()}.csv',
      );
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Workout entries export (CSV)',
          subject: 'Workout export',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _openAppSettings() async {
    final ok = await launchUrl(
      Uri.parse('app-settings:'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open system settings.')),
      );
    }
  }

  void _openLegalDoc(String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocScreen(title: title, assetPath: assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Clear privacy summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Privacy summary',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            icon: Icons.phone_iphone_outlined,
                            title: 'Local storage by default',
                            subtitle:
                                'Your workouts and settings are saved on this device.',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            icon: Icons.smart_toy_outlined,
                            title: 'AI is optional',
                            subtitle:
                                'You can disable AI and remove stored API keys anytime.',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            icon: Icons.group_outlined,
                            title: 'Community sharing is controlled',
                            subtitle:
                                'Choose what appears in community features.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data ownership & export
                  Text(
                    'Data ownership & export',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You own your data. You can export workout entries as a CSV file at any time.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.download_outlined),
                          title: const Text('Export workouts (CSV)'),
                          subtitle: const Text('Creates a shareable CSV file.'),
                          onTap: _exportWorkoutsCsv,
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: const Text('Manage saved exercise images'),
                          subtitle: const Text('Review or delete custom photos.'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Community privacy controls
                  Text(
                    'Community privacy controls',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control what information is visible in community features.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Show my profile in community'),
                          subtitle: const Text('If off, your activity stays private.'),
                          value: _communityProfileVisible,
                          onChanged: (v) async {
                            await _saveBool(
                              'privacy_community_profile_visible',
                              v,
                            );
                            if (!mounted) return;
                            setState(() => _communityProfileVisible = v);
                          },
                        ),
                        const Divider(height: 0),
                        SwitchListTile(
                          title: const Text('Show workout stats in community'),
                          subtitle: const Text('Share high-level stats only (no notes).'),
                          value: _communityShowStats,
                          onChanged: (v) async {
                            await _saveBool(
                              'privacy_community_show_stats',
                              v,
                            );
                            if (!mounted) return;
                            setState(() => _communityShowStats = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI transparency & opt-out
                  Text(
                    'AI transparency & opt-out',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If AI features are enabled, workout metadata and (optionally) your notes may be sent to your configured AI endpoint. Avoid personal information in notes.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Enable AI features'),
                          subtitle: const Text('Turn off to opt out of AI tools.'),
                          value: _aiEnabled,
                          onChanged: (v) async {
                            await _saveBool('privacy_ai_enabled', v);
                            if (!mounted) return;
                            setState(() => _aiEnabled = v);
                          },
                        ),
                        const Divider(height: 0),
                        SwitchListTile(
                          title: const Text('Allow notes to be sent to AI'),
                          subtitle: const Text('If off, notes stay on-device.'),
                          value: _aiSendNotes,
                          onChanged: _aiEnabled
                              ? (v) async {
                                  await _saveBool('privacy_ai_send_notes', v);
                                  if (!mounted) return;
                                  setState(() => _aiSendNotes = v);
                                }
                              : null,
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.vpn_key_outlined),
                          title: const Text('AI API key'),
                          subtitle: Text(
                            _hasApiKey
                                ? 'Stored securely (Keychain/Keystore)'
                                : 'No API key stored',
                          ),
                          trailing: _hasApiKey
                              ? TextButton(
                                  onPressed: _removeApiKey,
                                  child: const Text('Remove'),
                                )
                              : TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                        ),
                        if (_aiEndpoint != null && _aiEndpoint!.trim().isNotEmpty) ...[
                          const Divider(height: 0),
                          ListTile(
                            leading: const Icon(Icons.link_outlined),
                            title: const Text('AI endpoint'),
                            subtitle: Text(_aiEndpoint!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App lock & device security
                  Text(
                    'App lock & device security',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use a device PIN/biometrics. You can also enable an in-app lock reminder.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('App lock (preference)'),
                          subtitle: const Text(
                            'Stores your preference to lock sensitive areas. Enable device lock for full protection.',
                          ),
                          value: _appLockEnabled,
                          onChanged: (v) async {
                            await _saveBool('privacy_app_lock_enabled', v);
                            if (!mounted) return;
                            setState(() => _appLockEnabled = v);
                          },
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Open device/app settings'),
                          subtitle: const Text('Manage lock screen, permissions, and security.'),
                          onTap: _openAppSettings,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cloud sync control
                  Text(
                    'Cloud sync control',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Currently, workouts are stored locally on your device. This toggle is reserved for future cloud sync support.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Enable cloud sync (future)') ,
                      subtitle: const Text('Off keeps data local-only (recommended).'),
                      value: _cloudSyncEnabled,
                      onChanged: (v) async {
                        await _saveBool('privacy_cloud_sync_enabled', v);
                        if (!mounted) return;
                        setState(() => _cloudSyncEnabled = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Permissions manager
                  Text(
                    'Permissions manager',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permissions are managed by your device OS. Use system settings to review or revoke access (e.g., files/photos).',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.tune_outlined),
                          title: const Text('Open app permissions'),
                          subtitle: const Text('Review storage/photos, notifications, and more.'),
                          onTap: _openAppSettings,
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('What we use'),
                          subtitle: const Text('Files/photos (custom images), network (optional), notifications (optional).'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Legal clarity
                  Text(
                    'Legal clarity',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read our policies for details on data handling, AI, and security.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openLegalDoc(
                            'Privacy Policy',
                            'assets/legal/privacy_policy.md',
                          ),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Terms of Service'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openLegalDoc(
                            'Terms of Service',
                            'assets/legal/terms.md',
                          ),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          leading: const Icon(Icons.enhanced_encryption_outlined),
                          title: const Text('Encryption Info'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openLegalDoc(
                            'Encryption Info',
                            'assets/legal/encryption_info.md',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
