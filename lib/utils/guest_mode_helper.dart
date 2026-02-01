import 'package:fitness_aura_athletix/services/auth_service.dart';

/// 4️⃣ Guest Mode Utilities
/// Manages guest mode restrictions and permissions
class GuestModeHelper {
  static final AuthService _authService = AuthService();

  /// Check if user is in guest mode
  static Future<bool> isGuestMode() async {
    return await _authService.isGuestMode();
  }

  /// Check if a feature is allowed in guest mode
  static bool isFeatureAllowed(GuestFeature feature) {
    switch (feature) {
      // Allowed features
      case GuestFeature.workoutLogging:
      case GuestFeature.progressViewing:
      case GuestFeature.basicWorkouts:
      case GuestFeature.exerciseLibrary:
        return true;

      // Restricted features
      case GuestFeature.cloudSync:
      case GuestFeature.communityPosting:
      case GuestFeature.aiPersonalization:
      case GuestFeature.socialSharing:
      case GuestFeature.premiumFeatures:
      case GuestFeature.advancedAnalytics:
      case GuestFeature.customPlans:
        return false;
    }
  }

  /// Get restriction message for a feature
  static String getRestrictionMessage(GuestFeature feature) {
    switch (feature) {
      case GuestFeature.cloudSync:
        return 'Create an account to save progress across devices';
      case GuestFeature.communityPosting:
        return 'Create an account to join the community';
      case GuestFeature.aiPersonalization:
        return 'Create an account for personalized AI recommendations';
      case GuestFeature.socialSharing:
        return 'Create an account to share your achievements';
      case GuestFeature.premiumFeatures:
        return 'Create an account to access premium features';
      case GuestFeature.advancedAnalytics:
        return 'Create an account for detailed analytics';
      case GuestFeature.customPlans:
        return 'Create an account to create custom workout plans';
      default:
        return 'Create an account to unlock this feature';
    }
  }

  /// Check feature and show prompt if restricted
  /// Returns true if feature is allowed, false otherwise
  static Future<bool> checkFeatureAccess(GuestFeature feature) async {
    final isGuest = await isGuestMode();
    
    if (!isGuest) {
      return true; // Authenticated users have full access
    }

    return isFeatureAllowed(feature);
  }

  /// Get all restricted features for guest users
  static List<GuestFeature> getRestrictedFeatures() {
    return GuestFeature.values
        .where((feature) => !isFeatureAllowed(feature))
        .toList();
  }

  /// Get all allowed features for guest users
  static List<GuestFeature> getAllowedFeatures() {
    return GuestFeature.values
        .where((feature) => isFeatureAllowed(feature))
        .toList();
  }

  /// Get feature display name
  static String getFeatureName(GuestFeature feature) {
    switch (feature) {
      case GuestFeature.workoutLogging:
        return 'Workout Logging';
      case GuestFeature.progressViewing:
        return 'Progress Viewing';
      case GuestFeature.basicWorkouts:
        return 'Basic Workouts';
      case GuestFeature.exerciseLibrary:
        return 'Exercise Library';
      case GuestFeature.cloudSync:
        return 'Cloud Sync';
      case GuestFeature.communityPosting:
        return 'Community';
      case GuestFeature.aiPersonalization:
        return 'AI Personalization';
      case GuestFeature.socialSharing:
        return 'Social Sharing';
      case GuestFeature.premiumFeatures:
        return 'Premium Features';
      case GuestFeature.advancedAnalytics:
        return 'Advanced Analytics';
      case GuestFeature.customPlans:
        return 'Custom Plans';
    }
  }
}

/// Features that may be restricted in guest mode
enum GuestFeature {
  // Allowed in guest mode
  workoutLogging,
  progressViewing,
  basicWorkouts,
  exerciseLibrary,

  // Restricted in guest mode
  cloudSync,
  communityPosting,
  aiPersonalization,
  socialSharing,
  premiumFeatures,
  advancedAnalytics,
  customPlans,
}
