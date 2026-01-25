import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_insights.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Protect against RenderFlex overflow on smaller devices.
        final isTight = constraints.maxHeight > 0 && constraints.maxHeight < 240;

        final contentPadding =
            isTight
                ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
                : const EdgeInsets.fromLTRB(12, 10, 12, 12);

        final titleMaxLines = isTight ? 1 : 2;
        final double titleFontSize = isTight ? 13.0 : 13.5;

        final buttonStyle = ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(isTight ? 34 : 38),
          padding: EdgeInsets.symmetric(vertical: isTight ? 8 : 10),
          textStyle: TextStyle(
            fontSize: isTight ? 12.5 : 13,
            fontWeight: FontWeight.w800,
          ),
        );

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
                                  Colors.black.withValues(alpha: 0.06),
                                  Colors.black.withValues(alpha: 0.28),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: titleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.95),
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: isTight ? 4 : 6),
                        Text(
                          setsReps,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            fontSize: isTight ? 11.5 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTight ? 6 : 8),
                        FutureBuilder<ExerciseCardStats>(
                          future: ExerciseInsights.statsFor(
                            exerciseName: title,
                            bodyPart: bodyPart,
                          ),
                          builder: (context, snap) {
                            final last = snap.data?.lastTrained;
                            final trend =
                                snap.data?.trend ?? ExerciseTrend.flat;

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
                                      fontSize: isTight ? 11 : 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(
                                  trendIcon,
                                  size: isTight ? 16 : 18,
                                  color: trendColor,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: isTight ? 8 : 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: buttonStyle,
                            onPressed: onPick,
                            child: const Text('Pick'),
                          ),
                        ),
                        if (!isTight) ...[
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
