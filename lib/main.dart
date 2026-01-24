import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessAuraApp());
}

class FitnessAuraApp extends StatelessWidget {
  const FitnessAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Aura Athletix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
