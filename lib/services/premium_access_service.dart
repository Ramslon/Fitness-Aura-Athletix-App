import 'package:flutter/foundation.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class PremiumAccessService {
  static const _kPremiumFlag = 'premium';
  static const _kTrialUntilKey = 'premium_trial_until_iso';

  PremiumAccessService._();
  static final PremiumAccessService _instance = PremiumAccessService._();
  factory PremiumAccessService() => _instance;

  Future<bool> isPremiumActive() async {
    final paid = await StorageService().loadBoolSetting(_kPremiumFlag) ?? false;
    if (paid) return true;

    final raw = await StorageService().loadStringSetting(_kTrialUntilKey);
    if (raw == null || raw.trim().isEmpty) return false;

    final until = DateTime.tryParse(raw);
    if (until == null) return false;

    return DateTime.now().isBefore(until);
  }

  Future<DateTime?> trialUntil() async {
    final raw = await StorageService().loadStringSetting(_kTrialUntilKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> hasUsedTrial() async {
    return (await trialUntil()) != null;
  }

  Future<bool> startFreeTrial({int days = 7}) async {
    if (await hasUsedTrial()) return false;
    final until = DateTime.now().add(Duration(days: days));
    await StorageService().saveStringSetting(
      _kTrialUntilKey,
      until.toIso8601String(),
    );
    return true;
  }

  Future<void> clearTrial() async {
    // Not deleting to keep it simple; set to past.
    await StorageService().saveStringSetting(
      _kTrialUntilKey,
      DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
    );
  }

  Future<void> resetForTesting() async {
    if (!kDebugMode) {
      throw StateError('Premium test access can only be reset in debug mode.');
    }
    final storage = StorageService();
    await storage.saveBoolSetting(_kPremiumFlag, false);
    await storage.removeSetting(_kTrialUntilKey);
  }
}
