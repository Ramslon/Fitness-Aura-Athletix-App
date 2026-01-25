import 'package:flutter/material.dart';

import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';

class DailyWorkoutAnalysisDetailsSheet extends StatelessWidget {
  final DailyWorkoutAnalysis analysis;

  const DailyWorkoutAnalysisDetailsSheet({
    super.key,
    required this.analysis,
  });

  static Future<void> show(
    BuildContext context, {
    required DailyWorkoutAnalysis analysis,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: DailyWorkoutAnalysisDetailsSheet(analysis: analysis),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final trendColor = DailyWorkoutAnalysisEngine.trendColor(
      analysis.overloadTrend,
      scheme,
    );

    Widget section(String title, Widget child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.cardTheme.color ?? theme.cardColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.95),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
    }

    final muscles = const [
      'Legs',
      'Back',
      'Chest',
      'Arms',
      'Shoulders',
      'Core',
      'Glutes',
      'Abs',
    ];

    final trained = {analysis.bodyPart};

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.98),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          expand: false,
          builder: (ctx, controller) {
            return ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header summary
                section(
                  '1️⃣ Workout Summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analysis.workoutName} · ${analysis.bodyPart}',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _pill(context, '⏱ ${analysis.durationMinutes} min'),
                          _pill(
                            context,
                            '✅ ${analysis.exercisesCompleted} exercises',
                          ),
                          _pill(
                            context,
                            '🏋️ ${analysis.totalVolume.toStringAsFixed(0)} kg vol',
                          ),
                          if (analysis.caloriesBurned != null)
                            _pill(
                              context,
                              '🔥 ${analysis.caloriesBurned} kcal',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                section(
                  '2️⃣ Progressive Overload Indicator',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: trendColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DailyWorkoutAnalysisEngine.trendLabel(
                                analysis.overloadTrend,
                              ),
                              style: TextStyle(
                                color: trendColor.withValues(alpha: 0.95),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (analysis.volumeChangePercent != null)
                        Text(
                          'Volume: ${analysis.volumeChangePercent! >= 0 ? '+' : ''}${analysis.volumeChangePercent!.toStringAsFixed(0)}% vs last session',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (analysis.overloadDetails.isEmpty)
                        Text(
                          'No clear overload signals yet — keep logging consistently and aim for small progress next session.',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        ...analysis.overloadDetails.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Text('• '),
                                Expanded(
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                section(
                  '3️⃣ Muscle Group Impact Analysis',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muscle heat map',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in muscles)
                            _heatChip(
                              context,
                              label: m,
                              active: trained.contains(m),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Volume per muscle group',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...analysis.volumeByMuscleGroup.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${e.value.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (analysis.undertrainedWarnings.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Undertrained warning',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...analysis.undertrainedWarnings.map(
                          (w) => Text(
                            '• $w',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                section(
                  '4️⃣ Fatigue & Recovery Signal',
                  Text(
                    DailyWorkoutAnalysisEngine.fatigueLabel(analysis.fatigue),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),

                section(
                  '5️⃣ Personal Records & Milestones',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (analysis.prsAndMilestones.isEmpty)
                        Text(
                          'No new PRs detected today — keep stacking consistent sessions.',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        ...analysis.prsAndMilestones.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '🏅 $p',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (analysis.consistencyStreakDays != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '🔥 Consistency streak: ${analysis.consistencyStreakDays} days',
                            style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                section(
                  '🤖 AI Suggestions',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (analysis.aiSuggestions.isEmpty)
                        Text(
                          'Log a few sessions to unlock suggestions.',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        ...analysis.aiSuggestions.take(3).map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡 '),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _pill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.85),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _heatChip(
    BuildContext context, {
    required String label,
    required bool active,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active
        ? scheme.primary.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.06);
    final border = active
        ? scheme.primary.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: active ? 0.92 : 0.72),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
