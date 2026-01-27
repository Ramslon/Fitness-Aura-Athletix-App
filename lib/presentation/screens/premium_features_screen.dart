import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/currency_service.dart';
import 'package:fitness_aura_athletix/services/premium_access_service.dart';

enum _Plan { freeTrial, monthly, annual }

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  static const int _monthlyKes = 50;
  static const int _annualKes = 100;

  _Plan _plan = _Plan.monthly;
  bool _startingTrial = false;

  int get _selectedKes {
    switch (_plan) {
      case _Plan.monthly:
        return _monthlyKes;
      case _Plan.annual:
        return _annualKes;
      case _Plan.freeTrial:
        return 0;
    }
  }

  Future<void> _startTrial() async {
    setState(() => _startingTrial = true);
    await PremiumAccessService().startFreeTrial(days: 7);
    if (!mounted) return;
    setState(() => _startingTrial = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('7-day free trial started.')),
    );
  }

  void _startPremium() {
    Navigator.of(context).pushNamed(
      '/billing',
      arguments: {'amountKes': _selectedKes},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final usd = CurrencyService().convert(_selectedKes.toDouble(), 'KES', 'USD');
    final eur = CurrencyService().convert(_selectedKes.toDouble(), 'KES', 'EUR');

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: scheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Premium',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Train Smarter. Progress Faster.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 6),
          Text(
            'Cancel anytime. No pressure.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 16),

          // FREE vs PREMIUM separation
          Text(
            'FREE (Must Stay Free)',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: const [
                  _CheckRow(text: 'Workout logging'),
                  _CheckRow(text: 'Body part cards'),
                  _CheckRow(text: 'Basic volume & load'),
                  _CheckRow(text: 'Simple PR tracking'),
                  _CheckRow(text: 'Weekly summaries'),
                  _CheckRow(text: 'Rule-based suggestions'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'PREMIUM FEATURES',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where the value lives.',
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _PremiumFeatureCard(
                title: 'AI Coaching',
                subtitle: 'Plateaus, deloads, weak-points.',
                icon: Icons.auto_awesome_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Advanced Analytics',
                subtitle: 'Long-term trends & insights.',
                icon: Icons.insights_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Smart Programs',
                subtitle: 'Adaptive splits & updates.',
                icon: Icons.route_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Form Analysis',
                subtitle: 'Coming soon (Phase 2+).',
                icon: Icons.videocam_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Unlimited History',
                subtitle: 'Export CSV/PDF.',
                icon: Icons.history_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Cloud Backup',
                subtitle: 'Sync across devices.',
                icon: Icons.cloud_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Advanced PRs & Goals',
                subtitle: '1RM, ratios, projections.',
                icon: Icons.emoji_events_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Smart Reminders',
                subtitle: 'Recovery-aware nudges.',
                icon: Icons.notifications_active_outlined,
              ),
              _PremiumFeatureCard(
                title: 'Premium Perks',
                subtitle: 'Themes, templates, filters.',
                icon: Icons.tune_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            'Pricing',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Choose a plan',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      if (_plan != _Plan.freeTrial)
                        Text(
                          'KES $_selectedKes',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        )
                      else
                        const Text(
                          'Free',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  RadioListTile<_Plan>(
                    value: _Plan.freeTrial,
                    groupValue: _plan,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _plan = v ?? _Plan.freeTrial),
                    title: const Text('Free trial (7 days)', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      'Try premium features for a week.',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
                    ),
                  ),
                  const Divider(height: 1),
                  RadioListTile<_Plan>(
                    value: _Plan.monthly,
                    groupValue: _plan,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _plan = v ?? _Plan.monthly),
                    title: const Text('Monthly', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      'KES $_monthlyKes  (≈ \$${CurrencyService().convert(_monthlyKes.toDouble(), 'KES', 'USD').toStringAsFixed(2)} / ≈ €${CurrencyService().convert(_monthlyKes.toDouble(), 'KES', 'EUR').toStringAsFixed(2)})',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
                    ),
                  ),
                  const Divider(height: 1),
                  RadioListTile<_Plan>(
                    value: _Plan.annual,
                    groupValue: _plan,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _plan = v ?? _Plan.annual),
                    title: const Text('Annual (discounted)', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      'KES $_annualKes  (best value)  •  ≈ \$${CurrencyService().convert(_annualKes.toDouble(), 'KES', 'USD').toStringAsFixed(2)} / ≈ €${CurrencyService().convert(_annualKes.toDouble(), 'KES', 'EUR').toStringAsFixed(2)}',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
                    ),
                  ),

                  const SizedBox(height: 10),
                  if (_plan != _Plan.freeTrial) ...[
                    Text(
                      '≈ \$${usd.toStringAsFixed(2)} USD   •   ≈ €${eur.toStringAsFixed(2)} EUR',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Approx conversions (offline rates).',
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _plan == _Plan.freeTrial
                        ? ElevatedButton.icon(
                            icon: _startingTrial
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.timer_outlined),
                            label: const Text('Start 7-day free trial'),
                            onPressed: _startingTrial ? null : _startTrial,
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.workspace_premium),
                            label: const Text('Start Premium'),
                            onPressed: _startPremium,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime. No pressure.',
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PremiumFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Fixed width makes Wrap look like a grid across screen sizes.
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return SizedBox(
      width: w.clamp(160, 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const Spacer(),
                    Icon(Icons.lock, size: 18, color: scheme.onSurface.withValues(alpha: 0.55)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
