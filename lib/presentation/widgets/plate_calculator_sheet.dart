import 'package:flutter/material.dart';

Future<void> showPlateCalculatorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _PlateCalculatorSheet(),
  );
}

class _PlateCalculatorSheet extends StatefulWidget {
  const _PlateCalculatorSheet();

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _barController = TextEditingController(text: '20');
  String _result = '';

  static const List<double> _plates = [25, 20, 15, 10, 5, 2.5, 1.25];

  @override
  void dispose() {
    _targetController.dispose();
    _barController.dispose();
    super.dispose();
  }

  void _calculate() {
    final target = double.tryParse(_targetController.text) ?? 0;
    final bar = double.tryParse(_barController.text) ?? 20;
    final side = (target - bar) / 2;

    if (target <= 0 || side < 0) {
      setState(() => _result = 'Enter a valid target weight.');
      return;
    }

    var remaining = side;
    final used = <double, int>{};

    for (final p in _plates) {
      final count = remaining ~/ p;
      if (count > 0) {
        used[p] = count;
        remaining -= count * p;
      }
    }

    if (used.isEmpty) {
      setState(() => _result = 'No plates needed.');
      return;
    }

    final parts = <String>[];
    for (final e in used.entries) {
      parts.add('${e.key}×${e.value * 2}');
    }

    setState(() {
      _result = parts.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plate Calculator', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _barController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Bar weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Plates: $_result'),
            ],
          ],
        ),
      ),
    );
  }
}
