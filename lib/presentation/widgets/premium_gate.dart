import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';

class PremiumGate extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  final String title;
  final String previewText;
  final List<String> benefits;
  final VoidCallback? onAccessChanged;

  const PremiumGate({
    super.key,
    required this.isPremium,
    required this.child,
    required this.title,
    required this.previewText,
    this.benefits = const [],
    this.onAccessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureOfferCard(
      title: title,
      description: previewText,
      icon: Icons.lock_outline_rounded,
      benefits: benefits.isEmpty
          ? const [
              'Get deeper context from your saved training activity.',
              'Use this feature whenever your Premium access is active.',
            ]
          : benefits,
      unlockedContent: child,
      onAccessChanged: onAccessChanged,
      initiallyPremiumActive: isPremium,
    );
  }
}
