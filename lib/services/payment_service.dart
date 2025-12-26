import 'dart:async';

import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/payment_provider.dart';

/// PaymentService orchestrates payment providers. By default it uses a
/// simple simulated provider; you can configure a real provider later
/// (e.g., Stripe or MPesa) by implementing `PaymentProvider`.
class PaymentService {
	PaymentService._();
	static final PaymentService _instance = PaymentService._();
	factory PaymentService() => _instance;

	PaymentProvider? _provider;

	/// Register an in-memory provider instance (useful for wiring tests).
	void registerProvider(PaymentProvider provider) {
		_provider = provider;
	}

	/// Configure provider by name and optional credentials. This stores
	/// the chosen provider name and credentials (non-secure) so the app can
	/// recreate a provider instance at runtime. For sensitive data use
	/// secure storage (not implemented here).
	Future<void> configureProvider(String providerName, Map<String, String> credentials) async {
		await StorageService().saveStringSetting('payment_provider', providerName);
		// store credentials non-securely as a convenience for later wiring
		for (final e in credentials.entries) {
			await StorageService().saveStringSetting('payment_cred_${e.key}', e.value);
		}
		// If the provider is 'test' register a TestPaymentProvider
		if (providerName == 'test') {
			_provider = TestPaymentProvider();
			await _provider!.configure(credentials);
		}
		// For 'stripe' or 'mpesa' the implementation should create real provider
		// instances here when those packages are added.
	}

	Future<PaymentProvider> _resolveProvider() async {
		if (_provider != null) return _provider!;
		final name = await StorageService().loadStringSetting('payment_provider') ?? 'test';
		if (name == 'test') {
			_provider = TestPaymentProvider();
			await _provider!.configure({});
			return _provider!;
		}
		// If an unsupported provider is configured, fallback to test provider
		_provider = TestPaymentProvider();
		await _provider!.configure({});
		return _provider!;
	}

	/// Process a payment via the configured provider.
	Future<bool> processPayment({required double amount, required String currency, String? description}) async {
		final provider = await _resolveProvider();
		final success = await provider.processPayment(amount: amount, currency: currency, description: description);
		if (success) {
			await StorageService().saveBoolSetting('premium', true);
		}
		return success;
	}
}

