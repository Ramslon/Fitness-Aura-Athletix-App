import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessAuraApp());

  // Pre-warm heavy analysis work off the critical first frame.
  Future.microtask(DailyWorkoutAnalysisEngine.prewarm);
}

class FitnessAuraApp extends StatelessWidget {
  const FitnessAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E676),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Fitness Aura Athletix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
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
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.06),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black.withValues(alpha: 0.75),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return _GymAppFrame(child: child);
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
