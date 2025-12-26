import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'setting_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _hasApiKey = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await StorageService().hasSecureString('llm_api_key');
    setState(() {
      _hasApiKey = has;
      _loading = false;
    });
  }

  Future<void> _removeApiKey() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove stored API key?'),
        content: const Text('This will delete the stored AI API key from secure storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    await StorageService().deleteSecureString('llm_api_key');
    await StorageService().deleteSecureString('llm_endpoint');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key removed')));
    await _check();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security'), backgroundColor: Colors.green),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(children: [
                const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your AI API key (if provided) is stored using the platform secure storage (Keychain / Keystore). We do not transmit this key to any third party from the app itself.'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('AI API key stored'),
                  subtitle: Text(_hasApiKey ? 'Yes (stored securely)' : 'No API key stored'),
                  trailing: _hasApiKey
                      ? TextButton(onPressed: _removeApiKey, child: const Text('Remove'))
                      : TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())), child: const Text('Add')),
                ),
                const Divider(height: 30),
                const Text('Data sharing', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('When using AI analysis, workout metadata (dates, durations, types) and any notes you provide may be sent to the configured AI endpoint. Do not provide personal information in notes if you do not want it shared.'),
                const SizedBox(height: 16),
                const Text('Stored data'),
                const SizedBox(height: 8),
                const Text('Workout entries and analysis notes are stored locally on the device. You can export your workouts via the Settings screen.'),
              ]),
            ),
    );
  }
}
