import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AuthErrorMessage {
  const AuthErrorMessage._();

  static bool isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  static String from(
    Object error, {
    String operation = 'complete this request',
  }) {
    if (error is ApiRequestException) {
      return _httpStatusMessage(error.statusCode);
    }
    if (error is ApiConfigurationException) {
      return 'The online service is not configured with a valid endpoint.';
    }
    if (error is TimeoutException) {
      return 'The request timed out. Check your internet connection and try again.';
    }
    if (error is http.ClientException) {
      return 'Could not reach the service. Check your internet connection and try again.';
    }

    final code = switch (error) {
      FirebaseAuthException() => error.code,
      FirebaseException() => error.code,
      PlatformException() => error.code,
      FormatException() => 'invalid-response',
      _ => '',
    };

    switch (code) {
      case 'network-request-failed':
      case 'network_error':
      case 'handshake_error':
      case 'HandshakeException':
      case 'SocketException':
      case 'CERTIFICATE_VERIFY_FAILED':
      case 'unavailable':
      case 'deadline-exceeded':
      case 'connection-failed':
        return 'You appear to be offline or the secure connection failed. '
            'Check your internet connection and try again.';
      case 'invalid-response':
        return 'The service returned an unexpected response. Please try again later.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';
      case 'too-many-requests':
        return 'Too many attempts were made. Wait a little and try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 8 characters.';
      case 'requires-recent-login':
        return 'For your security, sign in again before trying this action.';
      case 'account-exists-with-different-credential':
        return 'This email is linked to another sign-in method. Use that method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support for help.';
      case 'permission-denied':
      case 'unauthenticated':
        return 'You are not authorized to perform this request. Sign in and try again.';
      case 'resource-exhausted':
        return 'The service is receiving too many requests. Wait a little and try again.';
      case 'internal':
      case 'unknown':
        return 'The service is temporarily unavailable. Please try again later.';
      case 'user-cancelled':
      case 'canceled':
        return 'Sign-in was cancelled.';
      case 'provider-not-supported':
        return 'This account provider is not supported for this action.';
    }

    final runtimeType = error.runtimeType.toString();
    if (runtimeType == 'SocketException' ||
        runtimeType == 'HandshakeException') {
      return 'You appear to be offline or the secure connection failed. '
          'Check your internet connection and try again.';
    }

    return 'Could not $operation. Please try again.';
  }

  static String _httpStatusMessage(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'The service rejected this request. Check your API credentials and permissions.';
    }
    if (statusCode == 408 || statusCode == 504) {
      return 'The service took too long to respond. Please try again.';
    }
    if (statusCode == 429) {
      return 'The service is receiving too many requests. Wait a little and try again.';
    }
    if (statusCode >= 500) {
      return 'The service is temporarily unavailable. Please try again later.';
    }
    return 'The service could not process this request (HTTP $statusCode).';
  }
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.statusCode);

  final int statusCode;
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException();
}
