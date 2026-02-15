import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
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
  Map<String, int> _last7DaysWorkoutCounts = {};

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
    final streak = await storage.currentStreak();
    final week = await storage.workoutsThisWeek();

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

    // Last 7 days workout counts (for summary chart)
    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = _normalizeDay(now.subtract(Duration(days: 6 - i)));
      return d;
    });

    final counts = <String, int>{};
    for (final d in last7) {
      counts[_dayKey(d)] = 0;
    }
    for (final e in entries) {
      final d = _normalizeDay(e.date);
      final k = _dayKey(d);
      if (counts.containsKey(k)) counts[k] = (counts[k] ?? 0) + 1;
    }

    setState(() {
      _entries = entries;
      _exerciseRecords = records;
      _totalWorkouts = entries.length;
      _totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
      _streak = streak;
      _thisWeek = week;
      _events
        ..clear()
        ..addAll(events);
      _last7DaysWorkoutCounts = counts;
      _loading = false;
    });
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
      children: _tagOptions.map((tag) {
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
      }).toList(growable: false),
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
                const Text(
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
      final orderedKeys = _last7DaysWorkoutCounts.keys.toList()..sort();
      for (final k in orderedKeys) {
        last7Rows.add([k, '${_last7DaysWorkoutCounts[k] ?? 0}']);
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

  Widget _metricCard(String title, String value, {Color? color}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLast7Bars() {
    final entries = _last7DaysWorkoutCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = entries
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p);

    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d);
    });

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
            Text(labels[i], style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Total Workouts', '$_totalWorkouts')),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Minutes', '$_totalMinutes min')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Current Streak',
                '$_streak days',
                color: Theme.of(
                  context,
                ).colorScheme.tertiary.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'This Week',
                '$_thisWeek workouts',
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last 7 Days',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildLast7Bars(),
                  ),
                ),
              ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workout History',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_entries.length} total',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _entries.isEmpty
                    ? const Center(child: Text('No workout history yet.'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _entries.length.clamp(0, 25),
                        itemBuilder: (context, i) {
                          final ordered = _entries.toList()
                            ..sort((a, b) => b.date.compareTo(a.date));
                          final e = ordered[i];
                          return ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(
                              '${e.workoutType} — ${e.durationMinutes} min',
                            ),
                            subtitle: Text(
                              DateFormat('yyyy-MM-dd').format(e.date),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
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
                todayDecoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
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
                          color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.secondary,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(selected),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _LegendDot(color: Colors.blue, label: 'Workouts'),
                        const SizedBox(width: 8),
                        _LegendDot(color: Colors.orange, label: 'Exercises'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dayWorkouts.isEmpty && dayExercises.isEmpty)
                  const Text('No activity logged for this day.')
                else ...[
                  if (dayWorkouts.isNotEmpty) ...[
                    const Text(
                      'Workouts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...dayWorkouts.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.fitness_center,
                          color: Colors.blue,
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
                    const Text(
                      'Exercises',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...dayExercises.map((r) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bolt, color: Colors.orange),
                        title: Text(
                          '${r.exerciseName} — ${r.weight.toStringAsFixed(1)} kg',
                        ),
                        subtitle: Text(
                          '${DateFormat('yyyy-MM-dd').format(r.dateRecorded)} • ${r.sets} x ${r.repsPerSet} • ${r.bodyPart} • ${r.difficulty}',
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    final movements = _movementNames();
    final filteredExerciseCount = _exerciseRecords
        .where(_matchesSelectedTags)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Filter by tags',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildTagFilters(),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search movement',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _movementQuery = v),
        ),
        const SizedBox(height: 12),
        if (filteredExerciseCount == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No exercise records match selected tags yet.',
              ),
            ),
          )
        else
          Card(
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
                  leading: const Icon(Icons.sports_gymnastics),
                  title: Text(name),
                  subtitle: Text('$count logged sets'),
                  trailing: const Icon(Icons.chevron_right),
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTab(),
                _buildMovementsTab(),
                _buildSummaryTab(),
              ],
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
  final String movementName;
  final List<ExerciseRecord> records;

  const _MovementHistorySheet({
    required this.movementName,
    required this.records,
  });

  Widget _buildTagFilters() {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy-MM-dd');

    double bestWeight = 0;
    for (final r in records) {
      final w = r.effectiveWeightKg;
      if (w > bestWeight) bestWeight = w;
    }

    final latest = records.isNotEmpty ? records.first : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movementName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('${records.length} logs')),
            Chip(label: Text('Best: ${bestWeight.toStringAsFixed(1)} kg')),
            if (latest != null)
              Chip(
                label: Text(
                  'Latest: ${dateFmt.format(latest.dateRecorded)} • ${latest.weightLabel} • ${latest.sets}x${latest.repsPerSet}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Exercise tag filters',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTagFilters(),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No records for this movement yet.'),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: records.length.clamp(0, 50),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = records[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bolt),
                  title: Text(
                    '${r.weightLabel} • ${r.sets} x ${r.repsPerSet}',
                  ),
                  subtitle: Text(
                    '${dateFmt.format(r.dateRecorded)} • ${r.bodyPart} • ${r.difficulty}',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
