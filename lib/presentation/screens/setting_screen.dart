import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/ai_gym_workout_plan.dart';
import 'package:fitness_aura_athletix/presentation/screens/privacy_settings_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiController = TextEditingController();
  final _endpointController = TextEditingController();
  bool _notifications = true;
  String _theme = 'system';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // API key and endpoint stored securely when available. Fall back to
    // non-secure settings if secure values are not present (for older installs).
    final apiSecure = await StorageService().loadSecureString('llm_api_key');
    final endpointSecure = await StorageService().loadSecureString('llm_endpoint');
    final apiFallback = await StorageService().loadStringSetting('llm_api_key');
    final endpointFallback = await StorageService().loadStringSetting('llm_endpoint');
    final api = apiSecure ?? apiFallback;
    final endpoint = endpointSecure ?? endpointFallback;
    final notifications = await StorageService().loadBoolSetting('notifications_enabled');
    final theme = await StorageService().loadStringSetting('theme_mode');
    setState(() {
      _apiController.text = api ?? '';
      _endpointController.text = endpoint ?? '';
      _notifications = notifications ?? true;
      _theme = theme ?? 'system';
      _loading = false;
    });
  }

  Future<void> _saveLlMSettings() async {
    // Save API key and endpoint into secure storage.
    await StorageService().saveSecureString('llm_api_key', _apiController.text.trim());
    await StorageService().saveSecureString('llm_endpoint', _endpointController.text.trim());
    AiGymWorkoutPlan().configure(apiKey: _apiController.text.trim(), endpoint: _endpointController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI settings saved')));
  }

  Future<void> _saveNotificationSetting(bool v) async {
    await StorageService().saveBoolSetting('notifications_enabled', v);
    setState(() => _notifications = v);
  }

  Future<void> _saveTheme(String mode) async {
    await StorageService().saveStringSetting('theme_mode', mode);
    setState(() => _theme = mode);
  }

  Future<List<FileSystemEntity>> _listSavedImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) {
      final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
      return name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg');
    }).toList();
    return files;
  }

  Future<void> _removeFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image removed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  Future<void> _exportAllEntriesCsv() async {
    try {
      final entries = await StorageService().loadEntries();
      final rows = <String>['id,date,workoutType,durationMinutes,notes'];
      for (final e in entries) {
        final notes = (e.notes ?? '').replaceAll('\n', ' ').replaceAll(',', ' ');
        rows.add('${e.id},${e.date.toIso8601String()},${e.workoutType},${e.durationMinutes},$notes');
      }
      final csv = rows.join('\n');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/workouts_export_${DateTime.now().toIso8601String()}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Workout entries export');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  void dispose() {
    _apiController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.green),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('AI Integration', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _apiController, decoration: const InputDecoration(labelText: 'API Key (optional)')),
                const SizedBox(height: 8),
                TextField(controller: _endpointController, decoration: const InputDecoration(labelText: 'Endpoint (optional)')),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _saveLlMSettings, child: const Text('Save AI Settings')),
                const Divider(height: 30),

                ListTile(leading: const Icon(Icons.person), title: const Text('Profile'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                ListTile(leading: const Icon(Icons.lock), title: const Text('Privacy & Security'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()))),

                const Text('General', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile(title: const Text('Notifications'), value: _notifications, onChanged: _saveNotificationSetting),
                const SizedBox(height: 8),
                Row(children: [const Text('Theme:'), const SizedBox(width: 12), DropdownButton<String>(value: _theme, items: const [DropdownMenuItem(value: 'system', child: Text('System')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))], onChanged: (v) { if (v != null) _saveTheme(v); })]),
                const Divider(height: 30),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Manage Exercise Images', style: TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () => setState(() {}), child: const Text('Refresh'))]),
                const SizedBox(height: 8),
                FutureBuilder<List<FileSystemEntity>>(future: _listSavedImages(), builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final files = snap.data!;
                  if (files.isEmpty) return const Text('No custom images saved.');
                  return Column(children: files.map((f) {
                    final name = f.path.split(Platform.pathSeparator).last;
                    return ListTile(
                      leading: Image.file(File(f.path), width: 56, height: 56, fit: BoxFit.cover),
                      title: Text(name),
                      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeFile(f.path)),
                    );
                  }).toList());
                }),
                const Divider(height: 30),

                ListTile(leading: const Icon(Icons.download), title: const Text('Export all workouts (CSV)'), onTap: _exportAllEntriesCsv),
                ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), subtitle: const Text('Fitness Aura Athletix — AI powered fitness companion')),
              ],
            ),
    );
  }
}
