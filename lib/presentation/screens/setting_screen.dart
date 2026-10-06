import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';
import 'package:fitness_aura_athletix/services/auth_error_message.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';
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
  static const String _customReminderEnabledKey = 'reminder_custom_enabled';
  static const String _customReminderHourKey = 'reminder_custom_hour';
  static const String _aiSuggestionsEnabledKey = 'ai_suggestions_enabled';

  bool _notifications = true;
  bool _customReminderEnabled = false;
  int _customReminderHour = 18;
  ThemeMode _themeMode = ThemeMode.system;
  bool _aiSuggestionsEnabled = true;
  bool _loading = true;
  bool _themeSaving = false;
  bool _accountBusy = false;
  bool _isGuest = false;
  bool _isAuthenticated = false;
  String? _accountEmail;
  String _signInProvider = 'Guest';
  String? _loadError;
  late Future<List<FileSystemEntity>> _savedImagesFuture;

  @override
  void initState() {
    super.initState();
    _savedImagesFuture = _listSavedImages();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = StorageService();
      final notifications = await storage.loadBoolSetting(
        'notifications_enabled',
      );
      final customEnabled = await storage.loadBoolSetting(
        _customReminderEnabledKey,
      );
      final customHourRaw = await storage.loadStringSetting(
        _customReminderHourKey,
      );
      final customHour = int.tryParse(customHourRaw ?? '') ?? 18;
      final aiEnabled = await storage.loadBoolSetting(_aiSuggestionsEnabledKey);
      final themeMode = ThemeSettingsService().themeMode;
      final auth = AuthService();
      final isAuthenticated = auth.currentUser != null;
      final isGuest = !isAuthenticated && await auth.isGuestMode();

      if (!mounted) return;
      setState(() {
        _notifications = notifications ?? true;
        _customReminderEnabled = customEnabled ?? false;
        _customReminderHour = customHour.clamp(0, 23);
        _aiSuggestionsEnabled = aiEnabled ?? true;
        _themeMode = themeMode;
        _isAuthenticated = isAuthenticated;
        _isGuest = isGuest;
        _accountEmail = auth.currentEmail;
        _signInProvider = auth.signInProviderLabel;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load settings: $error';
      });
    }
  }

  Future<void> _saveBoolSetting(
    String key,
    bool value,
    VoidCallback update,
  ) async {
    try {
      await StorageService().saveBoolSetting(key, value);
      if (!mounted) return;
      setState(update);
    } catch (error) {
      _showSettingsError('Could not save setting: $error');
    }
  }

  Future<void> _saveNotificationSetting(bool value) {
    return _saveBoolSetting(
      'notifications_enabled',
      value,
      () => _notifications = value,
    );
  }

  Future<void> _saveCustomReminderEnabled(bool value) {
    return _saveBoolSetting(
      _customReminderEnabledKey,
      value,
      () => _customReminderEnabled = value,
    );
  }

  Future<void> _saveAiSuggestionsEnabled(bool value) {
    return _saveBoolSetting(
      _aiSuggestionsEnabledKey,
      value,
      () => _aiSuggestionsEnabled = value,
    );
  }

  Future<void> _pickCustomReminderTime() async {
    final initial = TimeOfDay(hour: _customReminderHour, minute: 0);
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Pick reminder time',
    );
    if (selected == null) return;

    try {
      await StorageService().saveStringSetting(
        _customReminderHourKey,
        selected.hour.toString(),
      );

      if (!mounted) return;
      setState(() {
        _customReminderHour = selected.hour;
      });
    } catch (error) {
      _showSettingsError('Could not save reminder time: $error');
    }
  }

  String _hourLabel(int hour24) {
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$h:00 $suffix';
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    if (_themeSaving || mode == _themeMode) return;

    setState(() => _themeSaving = true);
    try {
      await ThemeSettingsService().setThemeMode(mode);
      if (!mounted) return;
      setState(() {
        _themeMode = mode;
        _themeSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _themeSaving = false);
      _showSettingsError('Could not change appearance: $error');
    }
  }

  void _showSettingsError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _leaveToAuthEntry() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authEntry, (_) => false);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(_isGuest ? 'Leave guest session?' : 'Sign out?'),
        content: Text(
          _isGuest
              ? 'Your guest session will end. Local workout data will remain on this device.'
              : 'You can sign in again at any time. Your local workout data will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _accountBusy = true);
    try {
      await AuthService().signOut();
      if (!mounted) return;
      _leaveToAuthEntry();
    } catch (error) {
      if (!mounted) return;
      if (!AuthService().isLoggedIn && !await AuthService().isGuestMode()) {
        _leaveToAuthEntry();
        return;
      }
      _showSettingsError(AuthErrorMessage.from(error, operation: 'sign out'));
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _accountEmail;
    if (_isGuest || email == null || email.isEmpty) {
      _showSettingsError(
        'Sign in with an email account to reset its password.',
      );
      return;
    }
    if (!AuthService().requiresPasswordForSensitiveAction) {
      _showSettingsError(
        'This account uses $_signInProvider sign-in. Manage its password with that provider.',
      );
      return;
    }

    setState(() => _accountBusy = true);
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'If an account is registered for $email, a password reset link has been sent.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is FirebaseAuthException && error.code == 'user-not-found'
          ? 'If an account is registered for this email, a password reset link has been sent.'
          : AuthErrorMessage.from(
              error,
              operation: 'send a password reset link',
            );
      _showSettingsError(message);
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final auth = AuthService();
    final isGuest = await auth.isGuestMode();
    final requiresPassword =
        !isGuest && auth.requiresPasswordForSensitiveAction;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(isGuest ? 'Delete guest data?' : 'Delete account?'),
        content: Text(
          'This permanently removes ${isGuest ? 'your guest data' : 'your sign-in account'}, '
          'local workout history, goals, and custom exercise images from this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    String? password;
    if (requiresPassword) {
      password = await _requestCurrentPassword();
      if (password == null || !mounted) return;
    }

    setState(() => _accountBusy = true);
    try {
      await auth.deleteAccount(password: password);
      if (!mounted) return;
      _leaveToAuthEntry();
    } on AccountDeletionException catch (error) {
      if (!mounted) return;
      if (error.accountDeleted) {
        _leaveToAuthEntry();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your account was deleted, but some local data could not be removed. Please contact support.',
            ),
          ),
        );
      } else {
        _showSettingsError(
          'Could not remove local account data: ${error.cause}',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSettingsError(
        AuthErrorMessage.from(error, operation: 'delete your account'),
      );
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<String?> _requestCurrentPassword() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.lock_outline_rounded),
          title: const Text('Confirm your password'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Current password'),
            onSubmitted: (value) {
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(dialogContext, controller.text);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
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
      if (!mounted) return;
      setState(() => _savedImagesFuture = _listSavedImages());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image removed')));
    } catch (e) {
      if (!mounted) return;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_rounded, size: 40),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadError = null;
                        });
                        _loadSettings();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildSettingsHeader(context),
                const SizedBox(height: 18),
                _SettingsSection(
                  title: 'Your profile',
                  icon: Icons.person_outline_rounded,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: const Text('Edit profile'),
                      subtitle: const Text(
                        'Update your display name and profile details',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.fitness_center_rounded),
                      title: const Text('Fitness profile'),
                      subtitle: const Text('Edit your onboarding information'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const OnboardingScreen(isEditMode: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const _FitnessProgressBanner(),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Account & security',
                  icon: Icons.manage_accounts_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(_isGuest ? 'Guest session' : _signInProvider),
                      subtitle: Text(
                        _accountEmail ?? 'Your workout data is stored locally.',
                      ),
                    ),
                    if (_isAuthenticated)
                      ListTile(
                        enabled:
                            !_accountBusy &&
                            AuthService().requiresPasswordForSensitiveAction,
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Reset password'),
                        subtitle: Text(
                          AuthService().requiresPasswordForSensitiveAction
                              ? 'Email a secure password reset link'
                              : 'Password is managed by your sign-in provider',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap:
                            _accountBusy ||
                                !AuthService()
                                    .requiresPasswordForSensitiveAction
                            ? null
                            : _sendPasswordReset,
                      ),
                    ListTile(
                      enabled: !_accountBusy,
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      subtitle: const Text(
                        'End this session; keep local workout data',
                      ),
                      trailing: _accountBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _accountBusy ? null : _signOut,
                    ),
                    ListTile(
                      enabled: !_accountBusy,
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        _isGuest ? 'Delete guest data' : 'Delete account',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently remove account and local workout data',
                      ),
                      onTap: _accountBusy ? null : _deleteAccount,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'Choose how Fitness Aura looks on this device.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {_themeMode},
                        onSelectionChanged: _themeSaving
                            ? null
                            : (selection) {
                                if (selection.isNotEmpty) {
                                  _saveTheme(selection.first);
                                }
                              },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Icon(
                            _themeMode == ThemeMode.system
                                ? Icons.sync_rounded
                                : _themeMode == ThemeMode.light
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _themeDescription,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (_themeSaving)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Training & reminders',
                  icon: Icons.notifications_active_outlined,
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive workout reminders'),
                      value: _notifications,
                      onChanged: _saveNotificationSetting,
                    ),
                    SwitchListTile(
                      title: const Text('Custom reminder time'),
                      subtitle: const Text(
                        'Use your chosen hour instead of auto-detect',
                      ),
                      value: _customReminderEnabled,
                      onChanged: _notifications
                          ? _saveCustomReminderEnabled
                          : null,
                    ),
                    ListTile(
                      enabled: _notifications && _customReminderEnabled,
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Reminder time'),
                      subtitle: Text(_hourLabel(_customReminderHour)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _notifications && _customReminderEnabled
                          ? _pickCustomReminderTime
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('AI suggestions'),
                      subtitle: const Text(
                        'Show AI-driven insights on Home and analysis screens',
                      ),
                      value: _aiSuggestionsEnabled,
                      onChanged: _saveAiSuggestionsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Privacy & storage',
                  icon: Icons.shield_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Privacy & Security'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_rounded),
                      title: const Text('Export workouts'),
                      subtitle: const Text('Share your workout history as CSV'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _exportAllEntriesCsv,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Exercise images',
                  icon: Icons.photo_library_outlined,
                  trailing: TextButton.icon(
                    onPressed: () =>
                        setState(() => _savedImagesFuture = _listSavedImages()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh'),
                  ),
                  children: [
                    FutureBuilder<List<FileSystemEntity>>(
                      future: _savedImagesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load saved images: ${snapshot.error}',
                            ),
                          );
                        }

                        final files = snapshot.data ?? [];
                        if (files.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No custom exercise images saved.'),
                          );
                        }

                        return Column(
                          children: files.map((file) {
                            final name = file.path
                                .split(Platform.pathSeparator)
                                .last;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(file.path),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(name),
                              trailing: IconButton(
                                tooltip: 'Remove image',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _removeFile(file.path),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'About',
                  icon: Icons.info_outline_rounded,
                  children: const [
                    ListTile(
                      title: Text('Fitness Aura Athletix'),
                      subtitle: Text('Your AI-powered fitness companion'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.22),
            scheme.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tune_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make it yours',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalize your training experience.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _themeDescription {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'Follows your device appearance settings.';
      case ThemeMode.light:
        return 'Keeps the app bright, whatever your device setting.';
      case ThemeMode.dark:
        return 'Keeps the app dark, whatever your device setting.';
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surface.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.86,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            children[index],
          ],
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
    final improvedSignal =
        entries.length >= 20 || weeklyWorkouts >= 4 || streak >= 7;
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
