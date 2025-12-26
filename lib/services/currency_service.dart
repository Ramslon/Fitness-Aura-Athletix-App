import 'dart:math';

/// Very small currency service with static rates for offline conversion.
class CurrencyService {
  CurrencyService._();
  static final CurrencyService _instance = CurrencyService._();
  factory CurrencyService() => _instance;

  // Static sample rates (approximate): 1 USD = 150 KES, 1 EUR = 160 KES
  final double _kesPerUsd = 150.0;
  final double _kesPerEur = 160.0;

  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    // normalize to KES then to target
    double inKes;
    switch (from) {
      case 'USD':
        inKes = amount * _kesPerUsd;
        break;
      case 'EUR':
        inKes = amount * _kesPerEur;
        break;
      case 'KES':
      default:
        inKes = amount;
    }

    double out;
    switch (to) {
      case 'USD':
        out = inKes / _kesPerUsd;
        break;
      case 'EUR':
        out = inKes / _kesPerEur;
        break;
      case 'KES':
      default:
        out = inKes;
    }

    // round to 2 decimals for display
    return (out * 100).roundToDouble() / 100;
  }
}
