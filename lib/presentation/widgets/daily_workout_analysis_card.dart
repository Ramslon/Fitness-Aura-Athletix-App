import 'package:flutter/material.dart';

import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

class DailyWorkoutAnalysisCard extends StatelessWidget {
  final DailyWorkoutAnalysis analysis;
  final VoidCallback? onViewDetails;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DailyWorkoutAnalysisCard({
    super.key,
    required this.analysis,
    this.onViewDetails,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final trendColor = DailyWorkoutAnalysisEngine.trendColor(
      analysis.overloadTrend,
      scheme,
    );

    final volumePct = analysis.volumeChangePercent;
    final volumeLine = volumePct == null
        ? null
        : 'Volume: ${volumePct >= 0 ? '+' : ''}${volumePct.toStringAsFixed(0)}%';

    final topDetail = analysis.overloadDetails.isNotEmpty
        ? analysis.overloadDetails.first
        : null;

    final ai = analysis.aiSuggestions.isNotEmpty
        ? analysis.aiSuggestions.first
        : 'Log consistently to unlock smarter suggestions.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.cardTheme.color ?? theme.cardColor,
            border: Border.all(color: trendColor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: trendColor.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${analysis.workoutName} ✓',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.95),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: trendColor.withValues(alpha: 0.16),
                      border: Border.all(
                        color: trendColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      analysis.bodyPart,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.90),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.trending_up, size: 18, color: trendColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      DailyWorkoutAnalysisEngine.trendLabel(
                        analysis.overloadTrend,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: trendColor.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),

              if (volumeLine != null || topDetail != null) ...[
                const SizedBox(height: 10),
                if (volumeLine != null)
                  Text(
                    volumeLine,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (topDetail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      topDetail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              Text(
                'Fatigue: ${DailyWorkoutAnalysisEngine.fatigueLabel(analysis.fatigue)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.80),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 '),
                    Expanded(
                      child: Text(
                        ai,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.90),
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '⏱ ${analysis.durationMinutes} min · '
                      '${analysis.exercisesCompleted} exercises · '
                      '${analysis.totalVolume.toStringAsFixed(0)} kg vol',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onViewDetails != null)
                    TextButton(
                      onPressed: onViewDetails,
                      child: const Text('VIEW DETAILS'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
