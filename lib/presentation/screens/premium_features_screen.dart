import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/currency_service.dart';

class PremiumFeaturesScreen extends StatelessWidget {
	const PremiumFeaturesScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final options = [50, 100, 150, 200, 250]; // KES amounts
		return Scaffold(
			appBar: AppBar(title: const Text('Premium Features'), backgroundColor: Colors.green),
			body: ListView(padding: const EdgeInsets.all(16), children: [
				const Text('Upgrade to Premium', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
				const SizedBox(height: 8),
				const Text('Unlock advanced workouts, progress tracking and AI plans.'),
				const SizedBox(height: 16),
				...options.map((kes) => Card(
					child: ListTile(
						title: Text('Premium — ${kes} KES'),
						subtitle: FutureBuilder<double>(
							future: Future.value(CurrencyService().convert(kes.toDouble(), 'KES', 'USD')),
							builder: (context, snap) {
								final usd = snap.data;
								return Text(usd != null ? '≈ \\$${usd} USD' : 'Converting...');
							},
						),
						trailing: ElevatedButton(
							child: const Text('Upgrade'),
							onPressed: () => Navigator.of(context).pushNamed('/billing', arguments: {'amountKes': kes}),
						),
					),
				)).toList(),
			]),
		);
	}
}
