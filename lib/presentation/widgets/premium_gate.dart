import 'package:flutter/material.dart';

class PremiumGate extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  final String title;
  final String previewText;
  final VoidCallback onUpgrade;

  const PremiumGate({
    super.key,
    required this.isPremium,
    required this.child,
    required this.title,
    required this.previewText,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;

    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onUpgrade,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
