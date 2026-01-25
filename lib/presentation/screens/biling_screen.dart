import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/currency_service.dart';
import 'package:fitness_aura_athletix/services/payment_service.dart';
import 'package:fitness_aura_athletix/services/payment_provider.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _currency = 'KES';
  double _amountKes = 50;
  bool _processing = false;
  String _selectedProvider = 'Test';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('amountKes')) {
      _amountKes = (args['amountKes'] as num).toDouble();
    }
  }

  double get _displayAmount {
    if (_currency == 'KES') return _amountKes;
    return CurrencyService().convert(_amountKes, 'KES', _currency);
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    if (_selectedProvider == 'Test') {
      PaymentService().registerProvider(TestPaymentProvider());
    }
    final success = await PaymentService().processPayment(
      amount: _displayAmount,
      currency: _currency,
      description: 'Premium upgrade',
    );
    setState(() => _processing = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful — premium unlocked')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Purchase',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Plan price: ${_amountKes.toInt()} KES'),
            const SizedBox(height: 8),
            Row(
              children: [
                DropdownButton<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'KES', child: Text('KES')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pay: ${NumberFormat.simpleCurrency(name: _currency).format(_displayAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Payment provider',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedProvider,
              items: const [
                DropdownMenuItem(
                  value: 'Test',
                  child: Text('Test (no real provider)'),
                ),
                DropdownMenuItem(
                  value: 'Stripe',
                  child: Text('Stripe (configure later)'),
                ),
                DropdownMenuItem(
                  value: 'MPesa',
                  child: Text('MPesa (configure later)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedProvider = v);
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            _processing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _pay, child: const Text('Pay now')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await StorageService().saveBoolSetting('premium', false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase cancelled')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
