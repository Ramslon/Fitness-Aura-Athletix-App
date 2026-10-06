import 'package:fitness_aura_athletix/services/theme_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeSettingsService', () {
    late ThemeSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ThemeSettingsService();
      await service.load();
    });

    test('defaults to system appearance', () {
      expect(service.themeMode, ThemeMode.system);
    });

    test('persists a selected appearance', () async {
      await service.setThemeMode(ThemeMode.light);

      expect(service.themeMode, ThemeMode.light);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('app_setting_theme_mode'), 'light');
    });

    test('loads a saved dark appearance', () async {
      SharedPreferences.setMockInitialValues({
        'app_setting_theme_mode': 'dark',
      });

      await service.load();

      expect(service.themeMode, ThemeMode.dark);
    });
  });
}
