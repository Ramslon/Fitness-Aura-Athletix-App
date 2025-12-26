import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
	const ProfileScreen({super.key});

	@override
	State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
	final _nameController = TextEditingController();
	bool _loading = true;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		final name = await StorageService().loadStringSetting('display_name');
		setState(() {
			_nameController.text = name ?? (AuthService().currentDisplayName ?? '');
			_loading = false;
		});
	}

	Future<void> _save() async {
		await StorageService().saveStringSetting('display_name', _nameController.text.trim());
		ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
	}

	Future<void> _exportProfile() async {
		// simple export that writes a small text file with profile info
		final dir = await getTemporaryDirectory();
		final file = File('${dir.path}/profile_${DateTime.now().toIso8601String()}.txt');
		final contents = 'display_name: ${_nameController.text}\n';
		await file.writeAsString(contents);
		ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile exported to temp folder')));
	}

	@override
	void dispose() {
		_nameController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.green),
			body: _loading
					? const Center(child: CircularProgressIndicator())
					: Padding(
							padding: const EdgeInsets.all(16.0),
							child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
								Center(
									child: CircleAvatar(radius: 44, child: Text(_initials(_nameController.text), style: const TextStyle(fontSize: 24))),
								),
								const SizedBox(height: 16),
								const Text('Display name', style: TextStyle(fontWeight: FontWeight.bold)),
								TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Your display name')),
								const SizedBox(height: 12),
								Row(children: [ElevatedButton(onPressed: _save, child: const Text('Save')), const SizedBox(width: 12), OutlinedButton(onPressed: _exportProfile, child: const Text('Export'))]),
								const SizedBox(height: 20),
								const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
								const SizedBox(height: 8),
								ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), subtitle: const Text('Sign out from the app (placeholder)'), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign out not implemented')))),
							]),
						),
		);
	}

	String _initials(String name) {
		if (name.trim().isEmpty) return 'FA';
		final parts = name.trim().split(RegExp(r'\s+'));
		if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
		return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
	}

