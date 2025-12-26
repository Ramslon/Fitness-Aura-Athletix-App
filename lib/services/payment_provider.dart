import 'dart:async';

/// Abstract payment provider interface. Implementations should integrate
/// with real payment SDKs (Stripe, MPesa, etc.).
abstract class PaymentProvider {
  /// Optional human-readable name (e.g., 'Stripe', 'MPesa').
  String get name;

  /// Configure provider with credentials. Implementations should persist
  /// secrets securely (outside the scope of this shim).
  Future<void> configure(Map<String, String> credentials);

  /// Process a payment. Returns true on success.
  Future<bool> processPayment({required double amount, required String currency, String? description});
}

/// A simple test provider that simulates successful payments.
class TestPaymentProvider implements PaymentProvider {
  @override
  String get name => 'test';

  @override
  Future<void> configure(Map<String, String> credentials) async {
    // No-op for test provider
    return;
  }

  @override
  Future<bool> processPayment({required double amount, required String currency, String? description}) async {
    await Future.delayed(const Duration(seconds: 1));
    return amount > 0;
  }
}

/// Placeholder provider implementations can be added here in future.
