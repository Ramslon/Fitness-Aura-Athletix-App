import 'package:flutter/foundation.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';
import 'package:fitness_aura_athletix/services/premium_access_service.dart';
import 'package:flutter/material.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _premiumActive = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final active = await PremiumAccessService().isPremiumActive();
    if (!mounted) return;
    setState(() {
      _premiumActive = active;
      _loading = false;
    });
  }

  Future<void> _resetPremiumForTesting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Premium test access?'),
        content: const Text(
          'This debug-only action disables Premium and resets the trial on this device, so you can test locked features and all plan options again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset test access'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await PremiumAccessService().resetForTesting();
    await _loadAccess();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Premium test access reset. Features are locked again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Perks')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 38,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _premiumActive
                                  ? 'Your Premium access is active'
                                  : 'More insight for every rep',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Premium options now live alongside the training features they enhance.',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer.withValues(
                                  alpha: 0.84,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Premium perks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'A quick look at what Premium unlocks across the app.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _PerkRow(
                icon: Icons.flag_rounded,
                title: 'Advanced goal planning',
                subtitle: 'See this in Goal-Based Tracking.',
              ),
              _PerkRow(
                icon: Icons.emoji_events_rounded,
                title: 'Advanced PR analysis',
                subtitle: 'See this in PRs & Achievements.',
              ),
              _PerkRow(
                icon: Icons.insights_rounded,
                title: 'Deeper training analytics',
                subtitle:
                    'Explore additional context for your training trends.',
              ),
              _PerkRow(
                icon: Icons.auto_awesome_rounded,
                title: 'AI coaching and guidance',
                subtitle:
                    'Available where supported by your configured AI tools.',
              ),
              _PerkRow(
                icon: Icons.tune_rounded,
                title: 'Premium customization',
                subtitle:
                    'More options and shortcuts as Premium perks roll out.',
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                PremiumFeatureOfferCard(
                  title: 'Choose your Premium plan',
                  description: _premiumActive
                      ? 'Your Premium access is active on this account.'
                      : 'Choose a one-time 7-day trial, monthly access, or annual access.',
                  icon: Icons.workspace_premium_rounded,
                  featureLabel: 'ALL-ACCESS MEMBERSHIP',
                  accentColor: const Color(0xFFD19A28),
                  benefits: const [
                    'Plan options are available from this card and feature-specific offers.',
                    'Your workout logging and basic tracking remain available without Premium.',
                  ],
                  onAccessChanged: _loadAccess,
                ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _resetPremiumForTesting,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset Premium test access'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Debug-only: resets Premium and the trial on this device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Premium checkout currently uses the configured test payment provider. Real payment providers must be configured before accepting live payments.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PerkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
