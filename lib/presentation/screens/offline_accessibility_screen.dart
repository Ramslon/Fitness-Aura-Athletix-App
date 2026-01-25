import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/offline_cache_service.dart';
import 'package:fitness_aura_athletix/services/offline_sync_service.dart';

class OfflineAccessibilityScreen extends StatefulWidget {
  const OfflineAccessibilityScreen({super.key});

  @override
  State<OfflineAccessibilityScreen> createState() =>
      _OfflineAccessibilityScreenState();
}

class _OfflineAccessibilityScreenState
    extends State<OfflineAccessibilityScreen> {
  bool _downloadedForOffline = false;
  bool _largeText = false;
  bool _highContrast = false;
  bool _voicePrompts = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dl =
        await StorageService().loadBoolSetting('offline_downloaded') ?? false;
    final lt =
        await StorageService().loadBoolSetting('access_large_text') ?? false;
    final hc =
        await StorageService().loadBoolSetting('access_high_contrast') ?? false;
    final vp =
        await StorageService().loadBoolSetting('access_voice_prompts') ?? false;
    setState(() {
      _downloadedForOffline = dl;
      _largeText = lt;
      _highContrast = hc;
      _voicePrompts = vp;
      _loading = false;
    });
  }

  Future<void> _toggleDownloaded(bool v) async {
    setState(() => _loading = true);
    try {
      if (v) {
        await OfflineCacheService().downloadCoreContent();
      } else {
        await OfflineCacheService().clearCache();
      }
      final dl = await OfflineCacheService().isDownloaded();
      setState(() => _downloadedForOffline = dl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dl ? 'Content saved for offline use' : 'Offline content cleared',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _loading = true);
    try {
      final ok = await OfflineSyncService().syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Sync completed' : 'Sync failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sync error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLargeText(bool v) async {
    await StorageService().saveBoolSetting('access_large_text', v);
    setState(() => _largeText = v);
  }

  Future<void> _toggleHighContrast(bool v) async {
    await StorageService().saveBoolSetting('access_high_contrast', v);
    setState(() => _highContrast = v);
  }

  Future<void> _toggleVoicePrompts(bool v) async {
    await StorageService().saveBoolSetting('access_voice_prompts', v);
    setState(() => _voicePrompts = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline & Accessibility')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Offline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Store core workouts for offline use'),
                  subtitle: const Text(
                    'Keeps exercise data and images available without network',
                  ),
                  value: _downloadedForOffline,
                  onChanged: _toggleDownloaded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_for_offline),
                      label: const Text('Force download now'),
                      onPressed: () async {
                        await _toggleDownloaded(true);
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _syncNow,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync now'),
                    ),
                  ],
                ),
                const Divider(height: 30),

                const Text(
                  'Accessibility',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Large text'),
                  value: _largeText,
                  onChanged: _toggleLargeText,
                ),
                SwitchListTile(
                  title: const Text('High contrast'),
                  value: _highContrast,
                  onChanged: _toggleHighContrast,
                ),
                SwitchListTile(
                  title: const Text('Voice prompts'),
                  value: _voicePrompts,
                  onChanged: _toggleVoicePrompts,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Large text increases font sizes in supported screens. High contrast alters some colors for readability. Voice prompts will read short hints in supported flows.',
                ),
              ],
            ),
    );
  }
}
