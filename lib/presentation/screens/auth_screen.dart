import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/screens/auth_entry_screen.dart';

/// Legacy AuthScreen - now redirects to new AuthEntryScreen
/// Kept for backward compatibility with existing routes
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new entry screen
    return const AuthEntryScreen();
  }
}
