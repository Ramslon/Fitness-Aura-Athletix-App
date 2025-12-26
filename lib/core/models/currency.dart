class Currency {
  final String code;
  final String symbol;
  const Currency(this.code, this.symbol);

  static const Currency kes = Currency('KES', 'KSh');
  static const Currency usd = Currency('USD', '\u0024');
  static const Currency eur = Currency('EUR', '\u20AC');
}
