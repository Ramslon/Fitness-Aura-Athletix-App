import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_insights.dart';

class ExerciseGridCard extends StatelessWidget {
  final String id;
  final String title;
  final String setsReps;
  final String bodyPart;
  final String? assetPath;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onPick;

  const ExerciseGridCard({
    super.key,
    required this.id,
    required this.title,
    required this.setsReps,
    required this.bodyPart,
    required this.assetPath,
    required this.accent,
    required this.onTap,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final cardBg = theme.cardTheme.color ?? theme.cardColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: () => ExerciseInsights.showHistorySheet(
          context,
          exerciseName: title,
          bodyPart: bodyPart,
          accent: accent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.40)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LocalImagePlaceholder(
                        id: id,
                        assetPath: assetPath,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                size: 14,
                                color: accent.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pick',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setsReps,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<ExerciseCardStats>(
                      future: ExerciseInsights.statsFor(
                        exerciseName: title,
                        bodyPart: bodyPart,
                      ),
                      builder: (context, snap) {
                        final last = snap.data?.lastTrained;
                        final trend = snap.data?.trend ?? ExerciseTrend.flat;

                        final trendIcon = switch (trend) {
                          ExerciseTrend.up => Icons.trending_up,
                          ExerciseTrend.down => Icons.trending_down,
                          ExerciseTrend.flat => Icons.trending_flat,
                        };

                        final trendColor = switch (trend) {
                          ExerciseTrend.up => const Color(0xFF2EE59D),
                          ExerciseTrend.down => const Color(0xFFFF5C5C),
                          ExerciseTrend.flat => scheme.onSurface,
                        };

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Last: ${ExerciseInsights.lastTrainedLabel(last)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.80,
                                  ),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(trendIcon, size: 18, color: trendColor),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPick,
                        child: const Text('Pick'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Long press for history',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontSize: 10.5,
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
      ),
    );
  }
}
