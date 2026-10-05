import 'package:flutter/material.dart';

import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

class DailyWorkoutAnalysisCard extends StatelessWidget {
  final DailyWorkoutAnalysis analysis;
  final VoidCallback? onViewDetails;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  const DailyWorkoutAnalysisCard({
    super.key,
    required this.analysis,
    this.onViewDetails,
    this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spacing = compact ? 10.0 : 14.0;
    final trendColor = DailyWorkoutAnalysisEngine.trendColor(
      analysis.overloadTrend,
      scheme,
    );
    final ai = analysis.aiSuggestions.isNotEmpty
        ? analysis.aiSuggestions.first
        : 'Log consistently to unlock smarter suggestions.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: theme.cardTheme.color ?? scheme.surface,
            border: Border.all(color: trendColor.withValues(alpha: 0.42)),
            boxShadow: [
              BoxShadow(
                color: trendColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: trendColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.workoutName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(analysis.date),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: analysis.bodyPart,
                    color: scheme.primary,
                    scheme: scheme,
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _trendIcon(analysis.overloadTrend),
                      color: trendColor,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DailyWorkoutAnalysisEngine.trendLabel(
                          analysis.overloadTrend,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (analysis.volumeChangePercent != null)
                      Text(
                        '${analysis.volumeChangePercent! >= 0 ? '+' : ''}'
                        '${analysis.volumeChangePercent!.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.timer_outlined,
                      label: 'DURATION',
                      value: '${analysis.durationMinutes} min',
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.fitness_center_rounded,
                      label: 'EXERCISES',
                      value: '${analysis.exercisesCompleted}',
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.monitor_weight_outlined,
                      label: 'VOLUME',
                      value: '${analysis.totalVolume.toStringAsFixed(0)} kg',
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Icon(
                    _fatigueIcon(analysis.fatigue),
                    size: 18,
                    color: _fatigueColor(analysis.fatigue, scheme),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recovery',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _fatigueLabel(analysis.fatigue),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: scheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        ai,
                        maxLines: compact ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewDetails != null) ...[
                SizedBox(height: compact ? 4 : 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('View analysis'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _trendIcon(OverloadTrend trend) => switch (trend) {
    OverloadTrend.improved => Icons.trending_up_rounded,
    OverloadTrend.maintained => Icons.trending_flat_rounded,
    OverloadTrend.regressed => Icons.trending_down_rounded,
  };

  static IconData _fatigueIcon(FatigueSignal fatigue) => switch (fatigue) {
    FatigueSignal.fresh => Icons.bolt_rounded,
    FatigueSignal.moderate => Icons.battery_3_bar_rounded,
    FatigueSignal.high => Icons.battery_alert_rounded,
  };

  static Color _fatigueColor(FatigueSignal fatigue, ColorScheme scheme) =>
      switch (fatigue) {
        FatigueSignal.fresh => scheme.tertiary,
        FatigueSignal.moderate => scheme.secondary,
        FatigueSignal.high => scheme.error,
      };

  static String _fatigueLabel(FatigueSignal fatigue) => switch (fatigue) {
    FatigueSignal.fresh => 'Fresh',
    FatigueSignal.moderate => 'Moderate',
    FatigueSignal.high => 'High',
  };
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: scheme.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme scheme;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
