import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_aura_athletix/firebase_options.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';
import 'package:fitness_aura_athletix/services/theme_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeSettingsService().load();
  runApp(const FitnessAuraApp());
}

class FitnessAuraApp extends StatelessWidget {
  const FitnessAuraApp({super.key});

  ThemeData _buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.70),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.brightness == Brightness.dark
              ? Colors.black
              : scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.onSurface.withValues(alpha: 0.06),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.dark,
    );

    return AnimatedBuilder(
      animation: ThemeSettingsService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Fitness Aura Athletix',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(lightScheme),
          darkTheme: _buildTheme(darkScheme),
          themeMode: ThemeSettingsService().themeMode,
          initialRoute: AppRoutes.onboarding,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            return _GymAppFrame(child: child);
          },
        );
      },
    );
  }
}

class _GymAppFrame extends StatelessWidget {
  final Widget child;

  const _GymAppFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0F14), Color(0xFF111827), Color(0xFF0A0A0A)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
