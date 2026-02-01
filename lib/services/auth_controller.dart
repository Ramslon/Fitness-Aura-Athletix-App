import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool get isLoggedIn => _authService.isLoggedIn;
  
  bool _isGuest = false;
  bool get isGuest => _isGuest;

  String? get currentUserEmail => _authService.currentUser?.email;
  String? get currentDisplayName => _authService.currentDisplayName;

  AuthController() {
    _checkGuestMode();
  }

  Future<void> _checkGuestMode() async {
    _isGuest = await _authService.isGuestMode();
    notifyListeners();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _authService.signUpWithEmail(email, password);
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password, {bool rememberMe = false}) async {
    try {
      await _authService.signInWithEmail(email, password, rememberMe: rememberMe);
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      await _authService.signInWithApple();
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    try {
      await _authService.continueAsGuest();
      _isGuest = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> canUseBiometric() async {
    return await _authService.canUseBiometric();
  }

  Future<bool> authenticateWithBiometric() async {
    return await _authService.authenticateWithBiometric();
  }

  Future<void> enableBiometric(bool enable) async {
    await _authService.enableBiometric(enable);
  }
}
