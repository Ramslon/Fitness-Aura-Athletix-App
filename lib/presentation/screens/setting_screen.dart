import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/theme_settings_service.dart';
import 'package:fitness_aura_athletix/presentation/screens/privacy_settings_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/profile_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/onboarding_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _customReminderEnabledKey =
      'reminder_custom_enabled';
  static const String _customReminderHourKey = 'reminder_custom_hour';
  static const String _aiSuggestionsEnabledKey = 'ai_suggestions_enabled';

  bool _notifications = true;
  bool _customReminderEnabled = false;
  int _customReminderHour = 18;
  String _theme = 'system';
  bool _aiSuggestionsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifications = await StorageService().loadBoolSetting(
      'notifications_enabled',
    );
    final customEnabled =
        await StorageService().loadBoolSetting(_customReminderEnabledKey);
    final customHourRaw =
        await StorageService().loadStringSetting(_customReminderHourKey);
    final customHour = int.tryParse(customHourRaw ?? '') ?? 18;
    final aiEnabled =
        await StorageService().loadBoolSetting(_aiSuggestionsEnabledKey);
    final themeMode = ThemeSettingsService().themeMode;
    setState(() {
      _notifications = notifications ?? true;
      _customReminderEnabled = customEnabled ?? false;
      _customReminderHour = customHour.clamp(0, 23);
      _aiSuggestionsEnabled = aiEnabled ?? true;
      _theme = _themeLabel(themeMode);
      _loading = false;
    });
  }

  Future<void> _saveNotificationSetting(bool v) async {
    await StorageService().saveBoolSetting('notifications_enabled', v);
    setState(() => _notifications = v);
  }

  Future<void> _saveCustomReminderEnabled(bool v) async {
    await StorageService().saveBoolSetting(_customReminderEnabledKey, v);
    setState(() => _customReminderEnabled = v);
  }

  Future<void> _saveAiSuggestionsEnabled(bool v) async {
    await StorageService().saveBoolSetting(_aiSuggestionsEnabledKey, v);
    setState(() => _aiSuggestionsEnabled = v);
  }

  Future<void> _pickCustomReminderTime() async {
    final initial = TimeOfDay(hour: _customReminderHour, minute: 0);
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Pick reminder time',
    );
    if (selected == null) return;

    await StorageService().saveStringSetting(
      _customReminderHourKey,
      selected.hour.toString(),
    );

    if (!mounted) return;
    setState(() {
      _customReminderHour = selected.hour;
    });
  }

  String _hourLabel(int hour24) {
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$h:00 $suffix';
  }

  Future<void> _saveTheme(String mode) async {
    final themeService = ThemeSettingsService();
    final themeMode = _parseThemeMode(mode);
    await themeService.setThemeMode(themeMode);
    setState(() => _theme = mode);
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  Future<List<FileSystemEntity>> _listSavedImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) {
      final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
      return name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg');
    }).toList();
    return files;
  }

  Future<void> _removeFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  Future<void> _exportAllEntriesCsv() async {
    try {
      final entries = await StorageService().loadEntries();
      final rows = <String>['id,date,workoutType,durationMinutes,notes'];
      for (final e in entries) {
        final notes = (e.notes ?? '')
            .replaceAll('\n', ' ')
            .replaceAll(',', ' ');
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
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Workout entries export');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: const Text('Update Fitness Profile'),
                  subtitle: const Text('Edit your onboarding info'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const OnboardingScreen(isEditMode: true),
                    ),
                  ),
                ),
                const _FitnessProgressBanner(),
                SwitchListTile(
                  title: const Text('Enable AI Suggestions'),
                  subtitle: const Text(
                    'Shows AI-driven insights in Home and analysis screens.',
                  ),
                  value: _aiSuggestionsEnabled,
                  onChanged: _saveAiSuggestionsEnabled,
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Privacy & Security'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacySettingsScreen(),
                    ),
                  ),
                ),

                const Text(
                  'General',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Notifications'),
                  value: _notifications,
                  onChanged: _saveNotificationSetting,
                ),
                SwitchListTile(
                  title: const Text('Custom reminder time'),
                  subtitle: const Text('Use your chosen hour instead of auto-detect'),
                  value: _customReminderEnabled,
                  onChanged: _notifications
                      ? _saveCustomReminderEnabled
                      : null,
                ),
                ListTile(
                  enabled: _notifications && _customReminderEnabled,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Reminder time'),
                  subtitle: Text(_hourLabel(_customReminderHour)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _notifications && _customReminderEnabled
                      ? _pickCustomReminderTime
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Theme:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _theme,
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System'),
                        ),
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark')),
                      ],
                      onChanged: (v) {
                        if (v != null) _saveTheme(v);
                      },
                    ),
                  ],
                ),
                const Divider(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Exercise Images',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<FileSystemEntity>>(
                  future: _listSavedImages(),
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final files = snap.data!;
                    if (files.isEmpty)
                      return const Text('No custom images saved.');
                    return Column(
                      children: files.map((f) {
                        final name = f.path.split(Platform.pathSeparator).last;
                        return ListTile(
                          leading: Image.file(
                            File(f.path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                          title: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFile(f.path),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(height: 30),

                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export all workouts (CSV)'),
                  onTap: _exportAllEntriesCsv,
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text(
                    'Fitness Aura Athletix — AI powered fitness companion',
                  ),
                ),
              ],
            ),
    );
  }
}

class _FitnessProgressBanner extends StatefulWidget {
  const _FitnessProgressBanner();

  @override
  State<_FitnessProgressBanner> createState() => _FitnessProgressBannerState();
}

class _FitnessProgressBannerState extends State<_FitnessProgressBanner> {
  static const String _kOnboardingDataKey = 'onboarding_profile_v1';
  static const String _kBannerDismissedKey =
      'fitness_progress_banner_dismissed';

  bool _loading = true;
  bool _show = false;
  String _targetLevel = 'Intermediate';

  @override
  void initState() {
    super.initState();
    _loadBannerState();
  }

  Future<void> _loadBannerState() async {
    final storage = StorageService();
    final entries = await storage.loadEntries();
    final weeklyWorkouts = await storage.workoutsThisWeek();
    final streak = await storage.currentStreak();
    final dismissed =
        await storage.loadBoolSetting(_kBannerDismissedKey) ?? false;

    String currentLevel = 'Beginner';
    final raw = await storage.loadStringSetting(_kOnboardingDataKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        currentLevel = (map['experience'] as String?) ?? currentLevel;
      } catch (_) {}
    }

    final normalized = currentLevel.toLowerCase();
    final improvedSignal = entries.length >= 20 || weeklyWorkouts >= 4 || streak >= 7;
    final shouldSuggest =
        improvedSignal && normalized == 'beginner' && !dismissed;

    if (normalized != 'beginner' && !dismissed) {
      await storage.saveBoolSetting(_kBannerDismissedKey, true);
    }

    if (!mounted) return;
    setState(() {
      _show = shouldSuggest;
      _targetLevel = 'Intermediate';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_show) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve improved a lot 💪',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Want to update your level to $_targetLevel?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingScreen(isEditMode: true),
                      ),
                    )
                    .then((_) => _loadBannerState()),
                child: const Text('Update Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
