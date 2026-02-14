import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

enum ExerciseTrend { up, down, flat }

class ExerciseCardStats {
  final DateTime? lastTrained;
  final ExerciseTrend trend;
  final double volumeThisWeek;
  final double volumePrevWeek;
  final List<ExerciseRecord> recent;

  const ExerciseCardStats({
    required this.lastTrained,
    required this.trend,
    required this.volumeThisWeek,
    required this.volumePrevWeek,
    required this.recent,
  });
}

class ExerciseInsights {
  ExerciseInsights._();

  static Future<List<ExerciseRecord>>? _recordsFuture;

  static Future<List<ExerciseRecord>> _loadAllRecords() {
    _recordsFuture ??= StorageService().loadExerciseRecords();
    return _recordsFuture!;
  }

  static void invalidateCache() {
    _recordsFuture = null;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static ExerciseTrend _trendFromVolumes(double current, double previous) {
    if (previous <= 0 && current > 0) return ExerciseTrend.up;
    if (previous <= 0 && current <= 0) return ExerciseTrend.flat;
    final ratio = current / previous;
    if (ratio >= 1.05) return ExerciseTrend.up;
    if (ratio <= 0.95) return ExerciseTrend.down;
    return ExerciseTrend.flat;
  }

  static String lastTrainedLabel(DateTime? lastTrained) {
    if (lastTrained == null) return 'Not yet';
    final days = DateTime.now()
        .difference(
          DateTime(lastTrained.year, lastTrained.month, lastTrained.day),
        )
        .inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  static Future<ExerciseCardStats> statsFor({
    required String exerciseName,
    required String bodyPart,
  }) async {
    final records = await _loadAllRecords();
    final filtered =
        records
            .where(
              (r) => r.bodyPart == bodyPart && r.exerciseName == exerciseName,
            )
            .toList()
          ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

    DateTime? lastTrained;
    if (filtered.isNotEmpty) lastTrained = filtered.first.dateRecorded;

    final now = DateTime.now();
    final startThisWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final startPrevWeek = startThisWeek.subtract(const Duration(days: 7));
    final endPrevWeek = startThisWeek.subtract(const Duration(days: 1));

    double volumeThisWeek = 0;
    double volumePrevWeek = 0;

    for (final r in filtered) {
      final d = DateTime(
        r.dateRecorded.year,
        r.dateRecorded.month,
        r.dateRecorded.day,
      );
      final load = r.volumeLoadKg;

      final inThisWeek =
          d.isAfter(startThisWeek) || _isSameDay(d, startThisWeek);
      final inPrevWeek =
          (d.isAfter(startPrevWeek) || _isSameDay(d, startPrevWeek)) &&
          (d.isBefore(endPrevWeek) || _isSameDay(d, endPrevWeek));

      if (inThisWeek) volumeThisWeek += load;
      if (inPrevWeek) volumePrevWeek += load;
    }

    return ExerciseCardStats(
      lastTrained: lastTrained,
      trend: _trendFromVolumes(volumeThisWeek, volumePrevWeek),
      volumeThisWeek: volumeThisWeek,
      volumePrevWeek: volumePrevWeek,
      recent: filtered.take(12).toList(),
    );
  }

  static Future<void> showHistorySheet(
    BuildContext context, {
    required String exerciseName,
    required String bodyPart,
    required Color accent,
  }) async {
    final stats = await ExerciseInsights.statsFor(
      exerciseName: exerciseName,
      bodyPart: bodyPart,
    );

    if (!context.mounted) return;

    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.60),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: accent.withValues(alpha: 0.16),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(Icons.history, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$bodyPart • Last trained: ${ExerciseInsights.lastTrainedLabel(stats.lastTrained)}',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stats.recent.isEmpty)
                    Text(
                      'No history yet. Tap Pick to log your first set.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: stats.recent.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        itemBuilder: (context, index) {
                          final r = stats.recent[index];
                          final d = DateTime(
                            r.dateRecorded.year,
                            r.dateRecorded.month,
                            r.dateRecorded.day,
                          );
                          final dateLabel =
                              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          final load = r.progressScore;

                          final extras = <String>[];
                          if (r.isBodyweight) {
                            final tut = r.timeUnderTensionSeconds ?? 0;
                            if (tut > 0) extras.add('TUT ${tut}s');
                            final tempo = r.tempo?.trim() ?? '';
                            if (tempo.isNotEmpty) extras.add('Tempo $tempo');
                            final v = r.difficultyVariation?.trim() ?? '';
                            if (v.isNotEmpty) extras.add(v);
                          }
                          if (r.hasTags) {
                            extras.add('Tags ${r.tags!.join(', ')}');
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              dateLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${r.sets}x${r.repsPerSet} @ ${r.weightLabel} • ${r.difficulty}${extras.isEmpty ? '' : ' • ${extras.join(' • ')}'}',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                            trailing: Text(
                              r.isBodyweight ? r.progressScoreLabel : load.toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          );
                        },
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
