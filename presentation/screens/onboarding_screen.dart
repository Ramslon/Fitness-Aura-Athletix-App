import 'package:flutter/material.dart';
import 'onboarding_intro_screen.dart';

// This file used to define the app's onboarding screen. To avoid duplicate
// class names with the new `lib`-based onboarding form, expose a renamed
// widget here. Other code that imports this top-level file will get a
// stable symbol but the original `OnboardingScreen` identifier no longer
// exists here.

class LegacyOnboardingScreen extends StatelessWidget {
  const LegacyOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Delegate to the cleaned up intro screen in the same folder.
    return const IntroOnboardingScreen();
  }
}
