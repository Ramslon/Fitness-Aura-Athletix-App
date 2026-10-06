import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/auth_error_message.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _isGuest = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final name = await StorageService().loadStringSetting('display_name');
      final isGuest = await AuthService().isGuestMode();
      if (!mounted) return;
      setState(() {
        _nameController.text = name ?? (AuthService().currentDisplayName ?? '');
        _isGuest = isGuest;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = AuthErrorMessage.from(
          error,
          operation: 'load your profile',
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _nameController.text.trim();
    setState(() => _saving = true);
    try {
      if (!_isGuest) {
        await AuthService().updateDisplayName(displayName);
      }
      await StorageService().saveStringSetting('display_name', displayName);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthErrorMessage.from(error, operation: 'save your profile'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportProfile() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/profile_${DateTime.now().toIso8601String()}.txt',
      );
      await file.writeAsString(
        'display_name: ${_nameController.text.trim()}\n'
        'email: ${AuthService().currentEmail ?? ''}\n',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile export is ready to share.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export profile: $error')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadError = null;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: scheme.primaryContainer,
                                  child: Text(
                                    _initials(_nameController.text),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Your profile',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keep your account details up to date.',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 50,
                                  decoration: const InputDecoration(
                                    labelText: 'Display name',
                                    hintText: 'How should we address you?',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    final name = (value ?? '').trim();
                                    if (name.length < 2) {
                                      return 'Enter at least 2 characters.';
                                    }
                                    if (name.length > 50) {
                                      return 'Use 50 characters or fewer.';
                                    }
                                    if (RegExp(r'[\x00-\x1F]').hasMatch(name)) {
                                      return 'Remove control characters.';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _save(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue:
                                      AuthService().currentEmail ??
                                      (_isGuest ? 'Guest account' : ''),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                    helperText:
                                        'Email address is managed by your sign-in provider.',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: Text(
                                      _saving ? 'Saving…' : 'Save changes',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _exportProfile,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Export profile details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return 'FA';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
