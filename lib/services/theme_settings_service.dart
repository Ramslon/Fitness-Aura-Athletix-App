import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class ThemeSettingsService extends ChangeNotifier {
	ThemeSettingsService._();
	static final ThemeSettingsService _instance = ThemeSettingsService._();
	factory ThemeSettingsService() => _instance;

	ThemeMode _themeMode = ThemeMode.system;
	ThemeMode get themeMode => _themeMode;

	Future<void> load() async {
		final saved = await StorageService().loadStringSetting('theme_mode');
		_themeMode = _parseThemeMode(saved);
		notifyListeners();
	}

	Future<void> setThemeMode(ThemeMode mode) async {
		_themeMode = mode;
		await StorageService().saveStringSetting('theme_mode', _serialize(mode));
		notifyListeners();
	}

	ThemeMode _parseThemeMode(String? value) {
		switch (value) {
			case 'light':
				return ThemeMode.light;
			case 'dark':
				return ThemeMode.dark;
			default:
				return ThemeMode.system;
		}
	}

	String _serialize(ThemeMode mode) {
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
}
