import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_aura_athletix/services/auth_error_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AuthErrorMessage', () {
    test('validates common email addresses', () {
      expect(AuthErrorMessage.isValidEmail(' athlete@example.com '), isTrue);
      expect(AuthErrorMessage.isValidEmail('invalid-email'), isFalse);
      expect(AuthErrorMessage.isValidEmail('a @example.com'), isFalse);
    });

    test('does not expose credential enumeration errors', () {
      final message = AuthErrorMessage.from(
        FirebaseAuthException(code: 'user-not-found'),
      );

      expect(message, 'The email or password is incorrect.');
    });

    test('explains offline and secure-handshake failures', () {
      final message = AuthErrorMessage.from(
        PlatformException(code: 'handshake_error'),
      );

      expect(message, contains('offline'));
      expect(message, contains('secure connection'));
    });

    test('maps API connectivity and timeout failures clearly', () {
      expect(
        AuthErrorMessage.from(http.ClientException('connection refused')),
        contains('internet connection'),
      );
      expect(
        AuthErrorMessage.from(TimeoutException('request timed out')),
        contains('timed out'),
      );
    });

    test('maps common API response status failures', () {
      expect(
        AuthErrorMessage.from(const ApiRequestException(429)),
        contains('too many requests'),
      );
      expect(
        AuthErrorMessage.from(const ApiRequestException(503)),
        contains('temporarily unavailable'),
      );
      expect(
        AuthErrorMessage.from(const ApiRequestException(401)),
        contains('API credentials'),
      );
    });

    test('explains API endpoint configuration errors', () {
      expect(
        AuthErrorMessage.from(const ApiConfigurationException()),
        contains('valid endpoint'),
      );
    });

    test('uses an action-specific safe fallback', () {
      final message = AuthErrorMessage.from(
        StateError('private implementation details'),
        operation: 'delete your account',
      );

      expect(message, contains('delete your account'));
      expect(message, isNot(contains('private implementation details')));
    });
  });
}
