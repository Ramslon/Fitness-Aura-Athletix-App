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

  static final List<_PremiumFeature> _premiumFeatures = [
    const _PremiumFeature(
      title: 'AI Coaching',
      subtitle: 'Plateaus, deloads, weak-points.',
      details:
          'Get intelligent training recommendations based on your history, recovery trend, and recent performance.',
      icon: Icons.auto_awesome_outlined,
    ),
    const _PremiumFeature(
      title: 'Advanced Analytics',
      subtitle: 'Long-term trends & insights.',
      details:
          'Unlock deeper charts and trend breakdowns over weeks and months so you can spot stalls and growth patterns quickly.',
      icon: Icons.insights_outlined,
    ),
    const _PremiumFeature(
      title: 'Smart Programs',
      subtitle: 'Adaptive splits & updates.',
      details:
          'Receive adaptive program updates that adjust your split and weekly workload as your progress changes.',
      icon: Icons.route_outlined,
    ),
    const _PremiumFeature(
      title: 'Form Analysis',
      subtitle: 'Coming soon (Phase 2+).',
      details:
          'Upcoming premium capability for deeper movement-quality feedback and corrective guidance.',
      icon: Icons.videocam_outlined,
    ),
    const _PremiumFeature(
      title: 'Unlimited History',
      subtitle: 'Export CSV/PDF.',
      details:
          'Keep full long-term training history with richer export options for coaching reviews and personal archives.',
      icon: Icons.history_outlined,
    ),
    const _PremiumFeature(
      title: 'Cloud Backup',
      subtitle: 'Sync across devices.',
      details:
          'Back up your data and sync workout progress reliably across supported devices.',
      icon: Icons.cloud_outlined,
    ),
    const _PremiumFeature(
      title: 'Advanced PRs & Goals',
      subtitle: '1RM, ratios, projections.',
      details:
          'Track advanced personal records and projected milestones with richer performance indicators.',
      icon: Icons.emoji_events_outlined,
    ),
    const _PremiumFeature(
      title: 'Smart Reminders',
      subtitle: 'Recovery-aware nudges.',
      details:
          'Receive personalized reminders tuned to your training rhythm and recovery profile.',
      icon: Icons.notifications_active_outlined,
    ),
    const _PremiumFeature(
      title: 'Premium Perks',
      subtitle: 'Themes, templates, filters.',
      details:
          'Access extra customization options and premium-only workflow shortcuts.',
      icon: Icons.tune_outlined,
    ),
  ];

  _Plan _plan = _Plan.monthly;
  bool _startingTrial = false;
  bool _premiumActive = false;
  DateTime? _trialUntil;

  @override
  void initState() {
    super.initState();
    _loadAccessState();
  }

  Future<void> _loadAccessState() async {
    final active = await PremiumAccessService().isPremiumActive();
    final trialUntil = await PremiumAccessService().trialUntil();
    if (!mounted) return;
    setState(() {
      _premiumActive = active;
      _trialUntil = trialUntil;
    });
  }

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
    await _loadAccessState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('7-day free trial started.')),
    );
  }

  String _trialUntilLabel(DateTime date) {
    final d = date;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  void _openFeatureDetails(_PremiumFeature feature) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(feature.icon, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Icon(
                      _premiumActive ? Icons.lock_open : Icons.lock,
                      size: 18,
                      color: _premiumActive
                          ? Colors.green
                          : scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  feature.details,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: 12),
                if (_premiumActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.green.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      _trialUntil != null && DateTime.now().isBefore(_trialUntil!)
                          ? 'Unlocked via free trial until ${_trialUntilLabel(_trialUntil!)}'
                          : 'Unlocked with Premium access',
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: scheme.errorContainer.withValues(alpha: 0.45),
                    ),
                    child: const Text(
                      'Locked. Start the 7-day free trial or subscribe to unlock this feature.',
                    ),
                  ),
                const SizedBox(height: 14),
                if (!_premiumActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (_plan == _Plan.freeTrial) {
                          _startTrial();
                        } else {
                          _startPremium();
                        }
                      },
                      icon: Icon(
                        _plan == _Plan.freeTrial
                            ? Icons.timer_outlined
                            : Icons.workspace_premium,
                      ),
                      label: Text(
                        _plan == _Plan.freeTrial
                            ? 'Start 7-day free trial'
                            : 'Unlock with Premium',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

          Card(
            child: ListTile(
              leading: Icon(
                _premiumActive ? Icons.lock_open : Icons.lock_outline,
                color: _premiumActive ? Colors.green : scheme.primary,
              ),
              title: Text(
                _premiumActive ? 'Premium is active' : 'Premium is locked',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _premiumActive &&
                        _trialUntil != null &&
                        DateTime.now().isBefore(_trialUntil!)
                    ? 'Free trial active until ${_trialUntilLabel(_trialUntil!)}'
                    : _premiumActive
                        ? 'Paid premium is active on this account'
                        : 'Choose free trial or premium plan below to unlock features',
              ),
            ),
          ),
          const SizedBox(height: 14),

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
            children: _premiumFeatures
                .map(
                  (feature) => _PremiumFeatureCard(
                    title: feature.title,
                    subtitle: feature.subtitle,
                    icon: feature.icon,
                    unlocked: _premiumActive,
                    onTap: () => _openFeatureDetails(feature),
                  ),
                )
                .toList(growable: false),
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
                            label: Text(
                              _premiumActive
                                  ? 'Trial/Premium already active'
                                  : 'Start 7-day free trial',
                            ),
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
  final bool unlocked;
  final VoidCallback onTap;

  const _PremiumFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Fixed width makes Wrap look like a grid across screen sizes.
    final w = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return SizedBox(
      width: w.clamp(160, 340),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
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
                        Icon(
                          unlocked ? Icons.lock_open : Icons.lock,
                          size: 18,
                          color: unlocked
                              ? Colors.green
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFeature {
  final String title;
  final String subtitle;
  final String details;
  final IconData icon;

  const _PremiumFeature({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.icon,
  });
}
