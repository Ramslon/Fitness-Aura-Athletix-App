import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/presentation/widgets/exercise_insights.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

Color exerciseCardAccent(String id) {
  var hash = 0x811c9dc5;
  for (final codeUnit in id.toLowerCase().codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
  }

  hash = _mixExerciseColorSeed(hash);
  final hue = hash / 0xffffffff * 360;
  final saturationSeed = _mixExerciseColorSeed(hash ^ 0x9e3779b9);
  final valueSeed = _mixExerciseColorSeed(hash ^ 0x85ebca6b);

  return HSVColor.fromAHSV(
    1,
    hue,
    0.68 + saturationSeed / 0xffffffff * 0.18,
    0.78 + valueSeed / 0xffffffff * 0.16,
  ).toColor();
}

int _mixExerciseColorSeed(int value) {
  value = ((value ^ (value >> 16)) * 0x7feb352d) & 0xffffffff;
  value = ((value ^ (value >> 15)) * 0x846ca68b) & 0xffffffff;
  return (value ^ (value >> 16)) & 0xffffffff;
}

class ExerciseGridCard extends StatelessWidget {
  final String id;
  final String title;
  final String setsReps;
  final String bodyPart;
  final String? assetPath;
  final bool showExerciseArtwork;
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
    this.showExerciseArtwork = false,
    required this.accent,
    required this.onTap,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ?? theme.cardColor;
    final cardAccent = exerciseCardAccent(id);

    final setsRepsDisplay = setsReps.replaceAll(' x ', ' × ');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Protect against RenderFlex overflow on smaller devices.
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final isTight =
            constraints.maxHeight > 0 &&
            (constraints.maxHeight < 280 || textScale > 1.05);

        final contentPadding = isTight
            ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
            : const EdgeInsets.fromLTRB(12, 10, 12, 12);

        final titleMaxLines = isTight ? 1 : 2;
        final double titleFontSize = isTight ? 13.0 : 13.5;

        final buttonStyle = ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(isTight ? 34 : 38),
          padding: EdgeInsets.symmetric(
            horizontal: isTight ? 8 : 12,
            vertical: isTight ? 8 : 10,
          ),
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
              accent: cardAccent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardAccent.withValues(alpha: 0.40)),
                boxShadow: [
                  BoxShadow(
                    color: cardAccent.withValues(alpha: 0.16),
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
                            assetPath: showExerciseArtwork ? null : assetPath,
                            fallbackLabel: showExerciseArtwork
                                ? exerciseArtworkLabel(
                                    bodyPart: bodyPart,
                                    exerciseName: title,
                                  )
                                : null,
                            fallbackColor: showExerciseArtwork ? accent : null,
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
                  Flexible(
                    child: Padding(
                      padding: contentPadding,
                      child: SingleChildScrollView(
                        // Prevent nested-scroll issues while still ensuring
                        // this content never causes a RenderFlex overflow.
                        physics: const NeverScrollableScrollPhysics(),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cardAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                setsRepsDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontSize: isTight ? 11.5 : 12,
                                  fontWeight: FontWeight.w700,
                                ),
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
                              child: ElevatedButton.icon(
                                style: buttonStyle,
                                onPressed: onPick,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Log exercise'),
                              ),
                            ),
                            if (!isTight) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Long press for history',
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
