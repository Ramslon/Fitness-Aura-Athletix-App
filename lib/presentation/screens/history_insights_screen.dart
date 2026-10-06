import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/workout_history_summary.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';

class HistoryInsightsScreen extends StatefulWidget {
  const HistoryInsightsScreen({super.key});

  @override
  State<HistoryInsightsScreen> createState() => _HistoryInsightsScreenState();
}

class _HistoryInsightsScreenState extends State<HistoryInsightsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;

  List<WorkoutEntry> _entries = [];
  List<ExerciseRecord> _exerciseRecords = [];

  int _totalWorkouts = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  int _thisWeek = 0;

  late final TabController _tabController;

  // Calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<_DayEvent>> _events = {};

  // Movements
  String _movementQuery = '';
  final Set<String> _selectedExerciseTags = <String>{};
  static const List<String> _tagOptions = <String>[
    'Strength',
    'Hypertrophy',
    'Warm-up',
    'Heavy power',
    'Volume detail',
  ];

  // Summary
  Map<DateTime, int> _last7DaysWorkoutCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDay = _normalizeDay(DateTime.now());
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final storage = StorageService();
    final entries = await storage.loadEntries();
    final records = await storage.loadExerciseRecords();
    final summary = WorkoutHistorySummary(
      workoutDates: entries.map((entry) => entry.date),
      exerciseRecordDates: records.map((record) => record.dateRecorded),
    );

    final events = <DateTime, List<_DayEvent>>{};

    for (final e in entries) {
      final day = _normalizeDay(e.date);
      events.putIfAbsent(day, () => []);
      events[day]!.add(_DayEvent.workout(e));
    }

    for (final r in records) {
      final day = _normalizeDay(r.dateRecorded);
      events.putIfAbsent(day, () => []);
      events[day]!.add(_DayEvent.exercise(r));
    }

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _exerciseRecords = records;
      _totalWorkouts = summary.totalWorkoutCount;
      _totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
      _streak = summary.currentStreakDays;
      _thisWeek = summary.workoutsThisWeek;
      _events
        ..clear()
        ..addAll(events);
      _last7DaysWorkoutCounts = summary.last7DayCounts;
      _loading = false;
    });
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  List<_DayEvent> _getEventsForDay(DateTime day) {
    final d = _normalizeDay(day);
    return _events[d] ?? const [];
  }

  List<WorkoutEntry> _workoutsForDay(DateTime day) {
    final d = _normalizeDay(day);
    return _entries.where((e) => _normalizeDay(e.date) == d).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<ExerciseRecord> _exerciseForDay(DateTime day) {
    final d = _normalizeDay(day);
    return _exerciseRecords
        .where((r) => _normalizeDay(r.dateRecorded) == d)
        .where(_matchesSelectedTags)
        .toList()
      ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
  }

  bool _matchesSelectedTags(ExerciseRecord r) {
    if (_selectedExerciseTags.isEmpty) return true;
    final tags = r.tags ?? const <String>[];
    for (final t in tags) {
      if (_selectedExerciseTags.contains(t)) return true;
    }
    return false;
  }

  List<String> _movementNames() {
    final set = <String>{};
    for (final r in _exerciseRecords) {
      if (!_matchesSelectedTags(r)) continue;
      final name = r.exerciseName.trim();
      if (name.isNotEmpty) set.add(name);
    }

    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (_movementQuery.trim().isEmpty) return list;
    final q = _movementQuery.trim().toLowerCase();
    return list.where((n) => n.toLowerCase().contains(q)).toList();
  }

  Widget _buildTagFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tagOptions
          .map((tag) {
            final selected = _selectedExerciseTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedExerciseTags.add(tag);
                  } else {
                    _selectedExerciseTags.remove(tag);
                  }
                });
              },
            );
          })
          .toList(growable: false),
    );
  }

  Future<void> _showExportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Workouts (CSV)'),
                  subtitle: const Text(
                    'Workout entries: date, type, duration, notes',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportWorkoutsCsv();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Exercise Records (CSV)'),
                  subtitle: const Text(
                    'Per-set summary: movement, weight, sets, reps, difficulty',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportExerciseRecordsCsv();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('PDF Report'),
                  subtitle: const Text(
                    'Summary + last 7 days + recent activity',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportPdfReport();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareFile(File file, String text) async {
    await SharePlus.instance.share(
      ShareParams(text: text, files: [XFile(file.path)]),
    );
  }

  Future<void> _exportWorkoutsCsv() async {
    try {
      final rows = <String>['id,date,workoutType,durationMinutes,notes'];

      final ordered = _entries.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final e in ordered) {
        rows.add(
          '${_csv(e.id)},${_csv(e.date.toIso8601String())},${_csv(e.workoutType)},${e.durationMinutes},${_csv(e.notes ?? '')}',
        );
      }

      final csv = rows.join('\n');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/workouts_${DateTime.now().toIso8601String()}.csv',
      );
      await file.writeAsString(csv);

      await _shareFile(file, 'Workout entries (CSV)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportExerciseRecordsCsv() async {
    try {
      final rows = <String>[
        'id,dateRecorded,exerciseName,bodyPart,weightKg,sets,repsPerSet,timeUnderTensionSeconds,tempo,difficultyVariation,tags,restTimeSeconds,difficulty,notes',
      ];

      final ordered = _exerciseRecords.toList()
        ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
      for (final r in ordered) {
        rows.add(
          '${_csv(r.id)},${_csv(r.dateRecorded.toIso8601String())},${_csv(r.exerciseName)},${_csv(r.bodyPart)},${r.weight},${r.sets},${r.repsPerSet},${r.timeUnderTensionSeconds ?? ''},${_csv(r.tempo ?? '')},${_csv(r.difficultyVariation ?? '')},${_csv((r.tags ?? const <String>[]).join('|'))},${r.restTime},${_csv(r.difficulty)},${_csv(r.notes ?? '')}',
        );
      }

      final csv = rows.join('\n');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/exercise_records_${DateTime.now().toIso8601String()}.csv',
      );
      await file.writeAsString(csv);

      await _shareFile(file, 'Exercise records (CSV)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  String _csv(String value) {
    final v = value.replaceAll('"', '""');
    return '"$v"';
  }

  Future<void> _exportPdfReport() async {
    try {
      final dateFmt = DateFormat('yyyy-MM-dd');
      final dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');

      final doc = pw.Document();

      final last7Rows = <List<String>>[];
      final orderedKeys = _last7DaysWorkoutCounts.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      for (final k in orderedKeys) {
        last7Rows.add([
          dateFmt.format(k),
          '${_last7DaysWorkoutCounts[k] ?? 0}',
        ]);
      }

      final recentWorkouts = _entries.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final recentExercises = _exerciseRecords.toList()
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Text(
                'History & Insights Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Generated: ${dateTimeFmt.format(DateTime.now())}'),
              pw.SizedBox(height: 12),

              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: const ['Metric', 'Value'],
                data: [
                  ['Total Workouts', '$_totalWorkouts'],
                  ['Total Minutes', '$_totalMinutes'],
                  ['Current Streak (days)', '$_streak'],
                  ['Workouts This Week', '$_thisWeek'],
                  ['Total Exercise Records', '${_exerciseRecords.length}'],
                ],
              ),
              pw.SizedBox(height: 12),

              pw.Text(
                'Last 7 Days (Workouts)',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: const ['Date', 'Workouts'],
                data: last7Rows,
              ),
              pw.SizedBox(height: 12),

              pw.Text(
                'Recent Workouts',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: const ['Date', 'Type', 'Minutes', 'Notes'],
                data: recentWorkouts.take(10).map((e) {
                  return [
                    dateFmt.format(e.date),
                    e.workoutType,
                    '${e.durationMinutes}',
                    e.notes ?? '',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 12),

              pw.Text(
                'Recent Exercise Records',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: const [
                  'Date',
                  'Movement',
                  'Body Part',
                  'Weight',
                  'Sets x Reps',
                  'Diff',
                ],
                data: recentExercises.take(12).map((r) {
                  return [
                    dateFmt.format(r.dateRecorded),
                    r.exerciseName,
                    r.bodyPart,
                    '${r.weight.toStringAsFixed(1)} kg',
                    '${r.sets} x ${r.repsPerSet}',
                    r.difficulty,
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/history_insights_${DateTime.now().toIso8601String()}.pdf',
      );
      await file.writeAsBytes(bytes);

      await _shareFile(file, 'History & Insights (PDF Report)');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    }
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedDay ?? _normalizeDay(DateTime.now());
    final dayWorkouts = _workoutsForDay(selected);
    final dayExercises = _exerciseForDay(selected);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar<_DayEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _normalizeDay(day) == selected,
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = _normalizeDay(selectedDay);
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: scheme.onSurface),
                weekendTextStyle: TextStyle(color: scheme.onSurfaceVariant),
                outsideTextStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
                todayDecoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: scheme.onPrimaryContainer),
                selectedTextStyle: TextStyle(color: scheme.onPrimary),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  final workouts = events
                      .where((e) => e.kind == _DayEventKind.workout)
                      .length;
                  final exercises = events
                      .where((e) => e.kind == _DayEventKind.exercise)
                      .length;

                  final dots = <Widget>[];
                  if (workouts > 0) {
                    dots.add(
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  if (exercises > 0) {
                    dots.add(
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dots
                          .map(
                            (w) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: w,
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, y').format(selected),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _LegendDot(color: scheme.primary, label: 'Workouts'),
                        _LegendDot(color: scheme.tertiary, label: 'Exercises'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dayWorkouts.isEmpty && dayExercises.isEmpty)
                  const Text('No activity logged for this day.')
                else ...[
                  if (dayWorkouts.isNotEmpty) ...[
                    Text(
                      'Workouts',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...dayWorkouts.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.fitness_center_rounded,
                          color: scheme.primary,
                        ),
                        title: Text(
                          '${e.workoutType} — ${e.durationMinutes} min',
                        ),
                        subtitle: e.notes == null || e.notes!.trim().isEmpty
                            ? null
                            : Text(e.notes!),
                      );
                    }),
                    const Divider(),
                  ],
                  if (dayExercises.isNotEmpty) ...[
                    Text(
                      'Exercises',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...dayExercises.map((r) {
                      return Dismissible(
                        key: Key(r.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteRecord(r),
                        background: Container(
                          color: scheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Icon(
                            Icons.delete_rounded,
                            color: scheme.onError,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.bolt_rounded,
                            color: scheme.tertiary,
                          ),
                          title: Text(
                            '${r.exerciseName} — ${r.weight.toStringAsFixed(1)} kg',
                          ),
                          subtitle: Text(
                            '${DateFormat('yyyy-MM-dd').format(r.dateRecorded)} • ${r.sets} x ${r.repsPerSet} • ${r.bodyPart} • ${r.difficulty}',
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRecord(ExerciseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Record?'),
          content: Text(
            'Permanently delete this record for ${record.exerciseName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await StorageService().deleteExerciseRecord(record.id);
      DailyWorkoutAnalysisEngine.invalidateCache();
      await _loadAll();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record deleted.')));
      }
    }
  }

  List<Widget> _buildLast7Bars() {
    final entries = _last7DaysWorkoutCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = entries
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p);

    return List.generate(entries.length, (i) {
      final count = entries[i].value;
      final height = maxCount == 0 ? 8.0 : (8.0 + (120.0 * (count / maxCount)));
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('$count', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('E').format(entries[i].key),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    });
  }

  Widget _advancedHistoryInsights(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = _normalizeDay(DateTime.now());
    final recentStart = today.subtract(const Duration(days: 27));
    final previousStart = today.subtract(const Duration(days: 55));
    final recentDays = <DateTime>{};
    final previousDays = <DateTime>{};

    void addTrainingDay(DateTime date) {
      final day = _normalizeDay(date);
      if (!day.isBefore(recentStart) && !day.isAfter(today)) {
        recentDays.add(day);
      } else if (!day.isBefore(previousStart) && day.isBefore(recentStart)) {
        previousDays.add(day);
      }
    }

    for (final entry in _entries) {
      addTrainingDay(entry.date);
    }
    for (final record in _exerciseRecords) {
      addTrainingDay(record.dateRecorded);
    }

    final estimatesByExercise = <String, double>{};
    for (final record in _exerciseRecords) {
      final weights = record.setWeightsKg;
      final repsBySet = record.setReps;
      for (var setIndex = 0; setIndex < record.sets; setIndex++) {
        final weight = weights != null && setIndex < weights.length
            ? weights[setIndex]
            : record.weight;
        final reps = repsBySet != null && setIndex < repsBySet.length
            ? repsBySet[setIndex]
            : record.repsPerSet;
        if (weight <= 0 || reps < 1 || reps > 12) continue;
        final estimatedMax = weight * (1 + reps / 30);
        final exercise = record.exerciseName.trim();
        if (exercise.isEmpty) continue;
        final current = estimatesByExercise[exercise] ?? 0;
        if (estimatedMax > current)
          estimatesByExercise[exercise] = estimatedMax;
      }
    }

    final topLifts = estimatesByExercise.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final deltaDays = recentDays.length - previousDays.length;
    final deltaText = deltaDays == 0
        ? 'same as the previous 28 days'
        : '${deltaDays > 0 ? '+' : ''}$deltaDays days vs previous 28 days';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _historyInsightMetric(
                context,
                label: 'TRAINING DAYS',
                value: '${recentDays.length} / 28',
                detail: deltaText,
                icon: Icons.calendar_month_rounded,
              ),
              _historyInsightMetric(
                context,
                label: 'LOGGED SESSIONS',
                value: '${_entries.length}',
                detail: 'Across your saved history',
                icon: Icons.fitness_center_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Estimated strength leaders',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (topLifts.isEmpty)
            Text(
              'Add weighted sets of 1–12 reps to see estimated one-rep max trends. These are estimates, not tested maxes.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
            )
          else ...[
            for (final lift in topLifts.take(3))
              _historyInsightLine(
                context,
                lift.key,
                '${lift.value.toStringAsFixed(1)} kg estimated 1RM',
              ),
            const SizedBox(height: 4),
            Text(
              'Epley estimates from your logged sets; not a tested maximum.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyInsightMetric(
    BuildContext context, {
    required String label,
    required String value,
    required String detail,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 135, maxWidth: 215),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 18),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _historyInsightLine(BuildContext context, String title, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: scheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final scheme = Theme.of(context).colorScheme;
    final orderedEntries = _entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _metricCard(
                    title: 'Total workouts',
                    value: '$_totalWorkouts',
                    icon: Icons.fitness_center_rounded,
                    accent: scheme.primary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _metricCard(
                    title: 'Training time',
                    value: '$_totalMinutes min',
                    icon: Icons.timer_outlined,
                    accent: scheme.secondary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _metricCard(
                    title: 'Current streak',
                    value: '$_streak days',
                    icon: Icons.local_fire_department_rounded,
                    accent: scheme.tertiary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _metricCard(
                    title: 'This week',
                    value: '$_thisWeek sessions',
                    icon: Icons.calendar_view_week_rounded,
                    accent: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training rhythm',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Workout sessions over the last seven calendar days',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 184,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _buildLast7Bars(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Workout history',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${_entries.length} total',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (orderedEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'No workout history yet. Completed workouts will appear here.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    else
                      ...orderedEntries
                          .take(25)
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: scheme.secondary.withValues(
                                        alpha: 0.13,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.fitness_center_rounded,
                                      color: scheme.secondary,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.workoutType,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: scheme.onSurface,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          DateFormat(
                                            'EEE, MMM d, y',
                                          ).format(entry.date),
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${entry.durationMinutes} min',
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PremiumFeatureOfferCard(
              title: 'Advanced history insights',
              description:
                  'Find longer-term consistency patterns and strength estimates from your workout history.',
              icon: Icons.query_stats_rounded,
              featureLabel: 'TRAINING HISTORY',
              accentColor: const Color(0xFF3575D3),
              benefits: const [
                'Compare unique training days across recent 28-day periods.',
                'Surface your strongest estimated lifts from logged sets.',
                'Turn saved training history into clearer progress context.',
              ],
              unlockedContent: _advancedHistoryInsights(context),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loadAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh history'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMovementHistory(String movementName) async {
    final records =
        _exerciseRecords
            .where(
              (r) =>
                  r.exerciseName.trim().toLowerCase() ==
                  movementName.toLowerCase(),
            )
            .where(_matchesSelectedTags)
            .toList()
          ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              top: 8,
            ),
            child: _MovementHistorySheet(
              movementName: movementName,
              records: records,
              onDelete: (record) async {
                Navigator.pop(context);
                await _deleteRecord(record);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    final scheme = Theme.of(context).colorScheme;
    final movements = _movementNames();
    final filteredExerciseCount = _exerciseRecords
        .where(_matchesSelectedTags)
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find a movement',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$filteredExerciseCount exercise logs · filter by training tag or search',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search movements',
                    hintText: 'e.g. squat or bench press',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => _movementQuery = value),
                ),
                const SizedBox(height: 14),
                Text(
                  'Training tags',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTagFilters(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredExerciseCount == 0)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No exercise records match these tags yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else if (movements.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No movements match “${_movementQuery.trim()}”. Try another search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final name = movements[i];
                final count = _exerciseRecords
                    .where(
                      (r) =>
                          r.exerciseName.trim().toLowerCase() ==
                          name.toLowerCase(),
                    )
                    .where(_matchesSelectedTags)
                    .length;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 3,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: scheme.primary,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text('$count session logs'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () => _openMovementHistory(name),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Insights'),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.download),
            onPressed: _showExportSheet,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.list_alt), text: 'Movements'),
            Tab(icon: Icon(Icons.insights), text: 'Summary'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarTab(),
                    _buildMovementsTab(),
                    _buildSummaryTab(),
                  ],
                ),
              ),
            ),
    );
  }
}

enum _DayEventKind { workout, exercise }

class _DayEvent {
  final _DayEventKind kind;
  final WorkoutEntry? workout;
  final ExerciseRecord? record;

  const _DayEvent._(this.kind, {this.workout, this.record});

  factory _DayEvent.workout(WorkoutEntry entry) =>
      _DayEvent._(_DayEventKind.workout, workout: entry);

  factory _DayEvent.exercise(ExerciseRecord record) =>
      _DayEvent._(_DayEventKind.exercise, record: record);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
      ],
    );
  }
}

class _MovementHistorySheet extends StatelessWidget {
  const _MovementHistorySheet({
    required this.movementName,
    required this.records,
    this.onDelete,
  });

  final String movementName;
  final List<ExerciseRecord> records;
  final void Function(ExerciseRecord)? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('yyyy-MM-dd');

    double bestWeight = 0;
    for (final r in records) {
      final w = r.effectiveWeightKg;
      if (w > bestWeight) bestWeight = w;
    }

    final latest = records.isNotEmpty ? records.first : null;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movementName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MovementStatChip(
                icon: Icons.list_alt_rounded,
                label: '${records.length} logs',
              ),
              _MovementStatChip(
                icon: Icons.emoji_events_outlined,
                label: 'Best ${bestWeight.toStringAsFixed(1)} kg',
              ),
              if (latest != null)
                _MovementStatChip(
                  icon: Icons.schedule_rounded,
                  label:
                      'Latest ${dateFmt.format(latest.dateRecorded)} · ${latest.weightLabel}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No records for this movement yet.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: records.length,
                separatorBuilder: (_, __) => Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
                itemBuilder: (context, i) {
                  final r = records[i];
                  return Dismissible(
                    key: Key(r.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => onDelete?.call(r),
                    background: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.delete_rounded,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      title: Text(
                        '${r.weight.toStringAsFixed(1)} kg · ${r.sets} × ${r.repsPerSet}',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${dateFmt.format(r.dateRecorded)} · ${r.difficulty}',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MovementStatChip extends StatelessWidget {
  const _MovementStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
