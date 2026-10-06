import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:fitness_aura_athletix/services/ai_integration_service.dart';
import 'package:fitness_aura_athletix/services/local_cache_service.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class AccountDeletionException implements Exception {
  final bool accountDeleted;
  final Object cause;

  const AccountDeletionException({
    required this.accountDeleted,
    required this.cause,
  });
}

/// Enhanced AuthService with Firebase integration
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  Future<void>? _googleSignInInit;
  final AiIntegrationService _aiIntegration = AiIntegrationService();
  final LocalCacheService _localCache = LocalCacheService();

  // Keys for SharedPreferences
  static const String _keyRememberMe = 'remember_me';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyIsGuest = 'is_guest';

  User? get currentUser => _auth.currentUser;
  String? get currentDisplayName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email;
  String? get currentEmail => _auth.currentUser?.email;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get requiresPasswordForSensitiveAction =>
      _auth.currentUser?.providerData.any(
        (provider) => provider.providerId == 'password',
      ) ??
      false;
  String get signInProviderLabel {
    final providers = _auth.currentUser?.providerData
        .map((provider) => provider.providerId)
        .toSet();
    if (providers == null || providers.isEmpty) return 'Guest';
    if (providers.contains('password')) return 'Email and password';
    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('apple.com')) return 'Apple';
    return 'Connected provider';
  }

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  // Set guest mode
  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, isGuest);
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await setGuestMode(false);
      final user = userCredential.user;
      if (user != null) {
        await _aiIntegration.onFirstLogin(user);
      }
      await _localCache.clearTransientCaches();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await setGuestMode(false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, rememberMe);

      final user = userCredential.user;
      if (user != null) {
        await _aiIntegration.onFirstLogin(user);
      }
      await _localCache.clearTransientCaches();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    _googleSignInInit ??= _googleSignIn.initialize();
    return _googleSignInInit!;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await setGuestMode(false);
      final user = userCredential.user;
      if (user != null) {
        await _aiIntegration.onFirstLogin(user);
      }
      await _localCache.clearTransientCaches();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await setGuestMode(false);
      final user = userCredential.user;
      if (user != null) {
        await _aiIntegration.onFirstLogin(user);
      }
      await _localCache.clearTransientCaches();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Continue as guest
  Future<void> continueAsGuest() async {
    await setGuestMode(true);
    await _aiIntegration.onGuestModeEnabled();
    await _localCache.clearTransientCaches();
  }

  /// Re-authenticate before sensitive account actions.
  Future<void> reauthenticateForSensitiveAction({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('There is no signed-in account to re-authenticate.');
    }

    if (user.providerData.any(
      (provider) => provider.providerId == 'password',
    )) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw FirebaseAuthException(code: 'requires-recent-login');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    if (user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    )) {
      await _ensureGoogleSignInInitialized();
      final account = await _googleSignIn.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      return;
    }

    if (user.providerData.any(
      (provider) => provider.providerId == 'apple.com',
    )) {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      await user.reauthenticateWithCredential(
        OAuthProvider(
          'apple.com',
        ).credential(idToken: token, accessToken: credential.authorizationCode),
      );
      return;
    }

    throw FirebaseAuthException(code: 'provider-not-supported');
  }

  /// Deletes the signed-in account and its locally stored workout data.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    final guest = user == null && await isGuestMode();
    if (user == null && !guest) {
      throw StateError('There is no account to delete.');
    }

    if (user != null) {
      await reauthenticateForSensitiveAction(password: password);
      await user.delete();
      await _clearGoogleSession();
    }

    Object? cleanupError;
    try {
      await StorageService().deleteLocalAccountData(
        userId: user?.uid,
        guest: guest,
      );
    } catch (error) {
      cleanupError = error;
    }
    try {
      await _aiIntegration.onUserDeleted();
    } catch (error) {
      cleanupError ??= error;
    }
    try {
      await setGuestMode(false);
    } catch (error) {
      cleanupError ??= error;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.setBool(_keyBiometricEnabled, false);
    } catch (error) {
      cleanupError ??= error;
    }
    try {
      await _localCache.clearTransientCaches();
    } catch (error) {
      cleanupError ??= error;
    }

    if (cleanupError != null) {
      throw AccountDeletionException(
        accountDeleted: user != null,
        cause: cleanupError,
      );
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    Object? cleanupError;
    try {
      await setGuestMode(false);
    } catch (error) {
      cleanupError = error;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.setBool(_keyBiometricEnabled, false);
    } catch (error) {
      cleanupError ??= error;
    }
    await _clearGoogleSession();
    try {
      await _localCache.clearTransientCaches();
    } catch (error) {
      cleanupError ??= error;
    }
    if (cleanupError != null) throw cleanupError;
  }

  Future<void> _clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
    } on Exception catch (error) {
      debugPrint(
        'Google local session cleanup failed after Firebase sign-out: $error',
      );
    }
  }

  // Check if biometric is available
  Future<bool> canUseBiometric() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        biometricOnly: true,
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // Enable biometric login
  Future<void> enableBiometric(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enable);
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }
}
