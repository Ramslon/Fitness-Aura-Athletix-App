import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/screens/premium_features_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/onboarding_screen.dart'
    as lib_onboarding;
import 'package:fitness_aura_athletix/presentation/screens/home_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/auth_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/arm_workouts.dart';
import 'package:fitness_aura_athletix/presentation/screens/back_workouts.dart';
import 'package:fitness_aura_athletix/presentation/screens/chest_workouts.dart';
import 'package:fitness_aura_athletix/presentation/screens/biling_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/community_feed_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/daily_workout_analysis_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/help_faq_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/leg_workouts.dart';
import 'package:fitness_aura_athletix/presentation/screens/notification_settings_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/offline_accessibility_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/privacy_settings_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/profile_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/progress_dashboard_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/setting_screen.dart';
import 'package:fitness_aura_athletix/presentation/screens/shoulder_workouts.dart';

class AppRoutes {
  static const String premiumFeatures = '/premium-features';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String dailyWorkoutAnalysis = '/daily-workout-analysis';
  static const String armWorkouts = '/arm-workouts';
  static const String progressDashboard = '/progressDashboard';
  static const String settings = '/settings';
  static const String chestWorkouts = '/chest-workouts';
  static const String shoulderWorkouts = '/shoulder-workouts';
  static const String legWorkouts = '/leg-workouts';
  static const String backWorkouts = '/back-workouts';
  static const String billing = '/billing';
  static const String privacySettings = '/privacy-settings';
  static const String socialCommunity = '/community-feed';
  static const String profile = '/profile';
  static const String offlineAccessibility = '/offline-accessibility';
  static const String notification = '/notification-settings';
  static const String helpFaq = '/help-faq';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const lib_onboarding.OnboardingScreen(),
        );
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case armWorkouts:
        return MaterialPageRoute(builder: (_) => const ArmWorkouts());
      case dailyWorkoutAnalysis:
        return MaterialPageRoute(
          builder: (_) => const DailyWorkoutAnalysisScreen(),
        );
      case chestWorkouts:
        return MaterialPageRoute(builder: (_) => const ChestWorkouts());
      case progressDashboard:
        return MaterialPageRoute(
          builder: (_) => const ProgressDashboardScreen(),
        );
      case shoulderWorkouts:
        return MaterialPageRoute(builder: (_) => const ShoulderWorkouts());
      case legWorkouts:
        return MaterialPageRoute(builder: (_) => const LegWorkouts());
      case backWorkouts:
        return MaterialPageRoute(builder: (_) => const BackWorkouts());
      case premiumFeatures:
        return MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen());
      case billing:
        return MaterialPageRoute(builder: (_) => const BillingScreen());
      case privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      case socialCommunity:
        return MaterialPageRoute(builder: (_) => const CommunityFeedScreen());
      case offlineAccessibility:
        return MaterialPageRoute(
          builder: (_) => const OfflineAccessibilityScreen(),
        );
      case notification:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );
      case helpFaq:
        return MaterialPageRoute(builder: (_) => const HelpFaqScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
