import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumAccessBlock { none, signInRequired, offline, unavailable }

class PremiumAccessStatus {
  const PremiumAccessStatus({
    required this.authenticated,
    required this.online,
    required this.premiumActive,
    this.block = PremiumAccessBlock.none,
  });

  final bool authenticated;
  final bool online;
  final bool premiumActive;
  final PremiumAccessBlock block;

  bool get canUsePremium => authenticated && online && premiumActive;

  String get message => switch (block) {
    PremiumAccessBlock.signInRequired =>
      'Sign in to an account to use Premium features.',
    PremiumAccessBlock.offline =>
      'Connect to the internet to verify Premium access. Premium features will remain locked until you are back online.',
    PremiumAccessBlock.unavailable =>
      'We could not verify Premium access right now. Please try again.',
    PremiumAccessBlock.none => '',
  };
}

class PremiumAccessService {
  static const _kPremiumFlag = 'premium';
  static const _kTrialUntilKey = 'premium_trial_until_iso';

  PremiumAccessService._();
  static final PremiumAccessService _instance = PremiumAccessService._();
  factory PremiumAccessService() => _instance;

  Future<PremiumAccessStatus> Function()? _statusLoaderForTesting;

  @visibleForTesting
  void setStatusLoaderForTesting(
    Future<PremiumAccessStatus> Function()? loader,
  ) {
    _statusLoaderForTesting = loader;
  }

  Future<PremiumAccessStatus> checkAccess() async {
    final testLoader = _statusLoaderForTesting;
    if (testLoader != null) return testLoader();

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_guest') ?? false) {
      return const PremiumAccessStatus(
        authenticated: false,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.signInRequired,
      );
    }

    final User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } on FirebaseException {
      return const PremiumAccessStatus(
        authenticated: false,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.unavailable,
      );
    }

    if (user == null || user.isAnonymous || user.providerData.isEmpty) {
      return const PremiumAccessStatus(
        authenticated: false,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.signInRequired,
      );
    }

    try {
      await user.getIdToken(true);
    } on FirebaseAuthException catch (error) {
      if (_isConnectivityError(error.code)) {
        return const PremiumAccessStatus(
          authenticated: true,
          online: false,
          premiumActive: false,
          block: PremiumAccessBlock.offline,
        );
      }
      if (_requiresSignIn(error.code)) {
        return const PremiumAccessStatus(
          authenticated: false,
          online: false,
          premiumActive: false,
          block: PremiumAccessBlock.signInRequired,
        );
      }
      return const PremiumAccessStatus(
        authenticated: true,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.unavailable,
      );
    } on FirebaseException {
      return const PremiumAccessStatus(
        authenticated: true,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.unavailable,
      );
    }

    return PremiumAccessStatus(
      authenticated: true,
      online: true,
      premiumActive: await _storedPremiumActive(),
    );
  }

  Future<bool> isPremiumActive() async {
    return (await checkAccess()).canUsePremium;
  }

  Future<bool> _storedPremiumActive() async {
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
    final access = await checkAccess();
    if (!access.authenticated || !access.online) {
      throw StateError(access.message);
    }
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

  bool _isConnectivityError(String code) {
    return const {
      'network-request-failed',
      'unavailable',
      'deadline-exceeded',
      'connection-failed',
    }.contains(code);
  }

  bool _requiresSignIn(String code) {
    return const {
      'user-not-found',
      'user-disabled',
      'invalid-user-token',
      'user-token-expired',
    }.contains(code);
  }
}
