import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:fitness_aura_athletix/services/ai_integration_service.dart';

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

  // Keys for SharedPreferences
  static const String _keyRememberMe = 'remember_me';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyIsGuest = 'is_guest';

  User? get currentUser => _auth.currentUser;
  String? get currentDisplayName => _auth.currentUser?.displayName ?? _auth.currentUser?.email;
  bool get isLoggedIn => _auth.currentUser != null;

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
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password, {bool rememberMe = false}) async {
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
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Continue as guest
  Future<void> continueAsGuest() async {
    await setGuestMode(true);
    await _aiIntegration.onGuestModeEnabled();
  }

  /// Delete the current user account and reset AI learning state.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
    await _aiIntegration.onUserDeleted();
    await setGuestMode(false);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await setGuestMode(false);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
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
        stickyAuth: true,
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
