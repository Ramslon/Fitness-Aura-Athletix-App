import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles AI lifecycle events tied to authentication.
class AiIntegrationService {
  AiIntegrationService._();
  static final AiIntegrationService _instance = AiIntegrationService._();
  factory AiIntegrationService() => _instance;

  static const String _keyAiLearningStarted = 'ai_learning_started';
  static const String _keyAiLearningUserId = 'ai_learning_user_id';
  static const String _keyAiLearningPaused = 'ai_learning_paused';
  static const String _keyAiLearningStartedAt = 'ai_learning_started_at';

  /// Start AI learning after first login (non-guest only).
  Future<void> onFirstLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool(_keyAiLearningStarted) ?? false;
    final storedUserId = prefs.getString(_keyAiLearningUserId);

    if (!started || storedUserId != user.uid) {
      await prefs.setBool(_keyAiLearningStarted, true);
      await prefs.setString(_keyAiLearningUserId, user.uid);
      await prefs.setInt(
        _keyAiLearningStartedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    await prefs.setBool(_keyAiLearningPaused, false);
  }

  /// Pause AI learning when guest mode is enabled.
  Future<void> onGuestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAiLearningPaused, true);
  }

  /// Reset AI learning state when a user deletes their account.
  Future<void> onUserDeleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAiLearningStarted);
    await prefs.remove(_keyAiLearningUserId);
    await prefs.remove(_keyAiLearningPaused);
    await prefs.remove(_keyAiLearningStartedAt);
  }

  /// Whether AI learning is currently enabled.
  Future<bool> isLearningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final started = prefs.getBool(_keyAiLearningStarted) ?? false;
    final paused = prefs.getBool(_keyAiLearningPaused) ?? false;
    return started && !paused;
  }
}
