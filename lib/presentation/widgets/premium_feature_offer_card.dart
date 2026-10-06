import 'package:fitness_aura_athletix/services/currency_service.dart';
import 'package:fitness_aura_athletix/services/premium_access_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _PremiumPlan { trial, monthly, annual }

class PremiumFeatureOfferCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> benefits;
  final Widget? unlockedContent;
  final VoidCallback? onAccessChanged;

  const PremiumFeatureOfferCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.benefits,
    this.unlockedContent,
    this.onAccessChanged,
  });

  @override
  State<PremiumFeatureOfferCard> createState() =>
      _PremiumFeatureOfferCardState();
}

class _PremiumFeatureOfferCardState extends State<PremiumFeatureOfferCard> {
  static const _monthlyKes = 50;
  static const _annualKes = 100;

  bool _loading = true;
  bool _premiumActive = false;
  bool _expanded = false;
  bool _trialUsed = false;
  bool _startingTrial = false;
  PremiumAccessStatus _accessStatus = const PremiumAccessStatus(
    authenticated: false,
    online: false,
    premiumActive: false,
    block: PremiumAccessBlock.unavailable,
  );

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final service = PremiumAccessService();
    final status = await service.checkAccess();
    final trialUsed = status.authenticated && status.online
        ? await service.hasUsedTrial()
        : false;
    if (!mounted) return;
    setState(() {
      _accessStatus = status;
      _premiumActive = status.canUsePremium;
      _trialUsed = trialUsed;
      _loading = false;
    });
  }

  Future<PremiumAccessStatus> _refreshAccess() async {
    setState(() => _loading = true);
    try {
      await _loadAccess();
    } on FirebaseException {
      if (mounted) {
        setState(() {
          _accessStatus = const PremiumAccessStatus(
            authenticated: true,
            online: false,
            premiumActive: false,
            block: PremiumAccessBlock.unavailable,
          );
          _premiumActive = false;
          _loading = false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _accessStatus = const PremiumAccessStatus(
            authenticated: true,
            online: false,
            premiumActive: false,
            block: PremiumAccessBlock.unavailable,
          );
          _premiumActive = false;
          _loading = false;
        });
      }
    }
    return _accessStatus;
  }

  void _showAccessMessage(PremiumAccessStatus status) {
    final message = status.message.isNotEmpty
        ? status.message
        : 'Premium access could not be verified. Please try again.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _togglePremiumContent() async {
    final status = await _refreshAccess();
    if (!mounted) return;
    if (!status.canUsePremium) {
      _showAccessMessage(status);
      return;
    }
    setState(() => _expanded = !_expanded);
  }

  Future<void> _choosePlan() async {
    final access = await _refreshAccess();
    if (!mounted) return;
    if (!access.authenticated || !access.online) {
      _showAccessMessage(access);
      return;
    }
    if (access.canUsePremium) {
      setState(() => _expanded = true);
      return;
    }

    final selection = await showModalBottomSheet<_PremiumPlan>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        var selected = _trialUsed ? _PremiumPlan.monthly : _PremiumPlan.trial;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final amount = switch (selected) {
              _PremiumPlan.trial => 0,
              _PremiumPlan.monthly => _monthlyKes,
              _PremiumPlan.annual => _annualKes,
            };
            final price = selected == _PremiumPlan.trial
                ? 'Free'
                : 'KES $amount';

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a plan',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock ${widget.title.toLowerCase()} and all included Premium perks.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    if (!_trialUsed) ...[
                      RadioListTile<_PremiumPlan>(
                        value: _PremiumPlan.trial,
                        groupValue: selected,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('7-day free trial'),
                        subtitle: const Text('One-time trial access'),
                        onChanged: (plan) {
                          if (plan != null) {
                            setSheetState(() => selected = plan);
                          }
                        },
                      ),
                      const Divider(height: 1),
                    ],
                    RadioListTile<_PremiumPlan>(
                      value: _PremiumPlan.monthly,
                      groupValue: selected,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Monthly'),
                      subtitle: Text(
                        'KES $_monthlyKes · approximately '
                        '\$${CurrencyService().convert(_monthlyKes.toDouble(), 'KES', 'USD').toStringAsFixed(2)} USD',
                      ),
                      onChanged: (plan) {
                        if (plan != null) {
                          setSheetState(() => selected = plan);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<_PremiumPlan>(
                      value: _PremiumPlan.annual,
                      groupValue: selected,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Annual · best value'),
                      subtitle: Text(
                        'KES $_annualKes · approximately '
                        '\$${CurrencyService().convert(_annualKes.toDouble(), 'KES', 'USD').toStringAsFixed(2)} USD',
                      ),
                      onChanged: (plan) {
                        if (plan != null) {
                          setSheetState(() => selected = plan);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selected == _PremiumPlan.trial
                          ? 'No payment required to start your trial.'
                          : 'Approximate offline currency conversion. '
                                'Checkout is currently provided by the configured test payment provider.',
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(selected),
                        icon: Icon(
                          selected == _PremiumPlan.trial
                              ? Icons.timer_outlined
                              : Icons.workspace_premium_rounded,
                        ),
                        label: Text(
                          selected == _PremiumPlan.trial
                              ? 'Start 7-day free trial'
                              : 'Continue · $price',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selection == null) return;
    if (selection == _PremiumPlan.trial) {
      await _startTrial();
      return;
    }

    final amountKes = selection == _PremiumPlan.monthly
        ? _monthlyKes
        : _annualKes;
    final purchased = await Navigator.of(
      context,
    ).pushNamed<bool>('/billing', arguments: {'amountKes': amountKes});
    if (!mounted || purchased != true) return;
    await _loadAccess();
    if (_premiumActive) setState(() => _expanded = true);
    widget.onAccessChanged?.call();
  }

  Future<void> _startTrial() async {
    final access = await _refreshAccess();
    if (!mounted) return;
    if (!access.authenticated || !access.online) {
      _showAccessMessage(access);
      return;
    }

    setState(() => _startingTrial = true);
    final bool started;
    try {
      started = await PremiumAccessService().startFreeTrial(days: 7);
    } on StateError {
      if (!mounted) return;
      final latest = await _refreshAccess();
      if (mounted) _showAccessMessage(latest);
      return;
    } finally {
      if (mounted) setState(() => _startingTrial = false);
    }
    if (!mounted) return;
    if (!started) {
      await _loadAccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The free trial has already been used.')),
      );
      return;
    }
    await _loadAccess();
    if (_premiumActive) setState(() => _expanded = true);
    widget.onAccessChanged?.call();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('7-day free trial started.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = !_loading && _premiumActive && _accessStatus.canUsePremium;
    final revealContent = active && _expanded;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.75),
              scheme.surfaceContainerLow,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 15,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'PREMIUM FEATURE',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                _statusPill(
                  context,
                  label: active ? 'ACCESS ACTIVE' : 'LOCKED',
                  icon: active
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  active: active,
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _loading ? null : _togglePremiumContent,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(widget.icon, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (active)
                      Icon(
                        revealContent
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: scheme.primary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            if (widget.benefits.isNotEmpty && (!active || revealContent)) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'YOUR PREMIUM TOOLS' : 'WHAT YOU’LL UNLOCK',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < widget.benefits.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == widget.benefits.length - 1 ? 0 : 9,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 23,
                              height: 23,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                active
                                    ? Icons.check_rounded
                                    : Icons.auto_awesome_rounded,
                                size: 14,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                widget.benefits[index],
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (revealContent && widget.unlockedContent != null) ...[
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: widget.unlockedContent!,
              ),
            ],
            if (!active && !_loading) ...[
              const SizedBox(height: 8),
              if (!_accessStatus.authenticated || !_accessStatus.online)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _accessStatus.block == PremiumAccessBlock.signInRequired
                            ? Icons.person_outline_rounded
                            : Icons.cloud_off_rounded,
                        color: scheme.onErrorContainer,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _accessStatus.message,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _trialUsed
                            ? Icons.payments_outlined
                            : Icons.card_giftcard_rounded,
                        color: scheme.tertiary,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KES $_monthlyKes monthly  ·  KES $_annualKes annual',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 11,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!_trialUsed) ...[
                              const SizedBox(height: 3),
                              Text(
                                'A one-time 7-day free trial is also available.',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startingTrial ? null : _choosePlan,
                  icon: _loading || _startingTrial
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.workspace_premium_rounded),
                  label: Text(
                    _loading
                        ? 'Checking access…'
                        : _startingTrial
                        ? 'Starting trial…'
                        : _accessStatus.block ==
                              PremiumAccessBlock.signInRequired
                        ? 'Sign in to unlock'
                        : !_accessStatus.online
                        ? 'Check connection'
                        : 'Start Premium',
                  ),
                ),
              ),
            ],
            if (active)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    revealContent
                        ? 'Tap to hide Premium insights'
                        : 'Tap to view unlocked insights',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool active,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = active ? scheme.primary : scheme.onSurfaceVariant;
    final background = active
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surface.withValues(alpha: 0.72);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }
}
