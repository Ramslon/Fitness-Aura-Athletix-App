import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_details_sheet.dart';

class DailyWorkoutAnalysisScreen extends StatefulWidget {
  const DailyWorkoutAnalysisScreen({super.key});

  @override
  State<DailyWorkoutAnalysisScreen> createState() =>
      _DailyWorkoutAnalysisScreenState();
}

class _DailyWorkoutAnalysisScreenState
    extends State<DailyWorkoutAnalysisScreen> {
  bool _loading = true;
  List<DailyWorkoutAnalysis> _sessions = [];
  int _index = 0;
  String? _filterBodyPart;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    final args = ModalRoute.of(context)?.settings.arguments;
    String? bodyPartArg;
    DateTime? dateArg;
    if (args is Map) {
      bodyPartArg = args['bodyPart'] as String?;
      final dateStr = args['date'] as String?;
      if (dateStr != null) {
        dateArg = DateTime.tryParse(dateStr);
      }
    }

    final records = await StorageService().loadExerciseRecords();
    final grouped = DailyWorkoutAnalysisEngine.groupSessions(records);

    final sessions = <DailyWorkoutAnalysis>[];
    for (final e in grouped.entries) {
      final parts = e.key.split('|');
      if (parts.length != 2) continue;
      final day = DateTime.tryParse(parts[0]);
      final body = parts[1];
      if (day == null) continue;
      final a = DailyWorkoutAnalysisEngine.analyzeFromRecords(
        records,
        day: day,
        bodyPart: body,
      );
      if (a != null) sessions.add(a);
    }

    sessions.sort((a, b) => b.date.compareTo(a.date));

    // Filter if requested
    _filterBodyPart = bodyPartArg;
    final filtered = bodyPartArg == null
        ? sessions
        : sessions.where((s) => s.bodyPart == bodyPartArg).toList();

    int initial = 0;
    if (dateArg != null) {
      final d = DailyWorkoutAnalysisEngine.dayStart(dateArg);
      final found = filtered.indexWhere(
        (s) =>
            s.bodyPart == (bodyPartArg ?? s.bodyPart) &&
            DailyWorkoutAnalysisEngine.dayStart(s.date) == d,
      );
      if (found >= 0) initial = found;
    }

    setState(() {
      _sessions = filtered;
      _index = initial.clamp(0, (_sessions.length - 1).clamp(0, 999999));
      _loading = false;
    });

    if (_sessions.isNotEmpty) {
      _pageController.jumpToPage(_index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showCompare(BuildContext context) async {
    if (_sessions.length < 2) return;
    final current = _sessions[_index];
    final previous = _sessions[(_index + 1).clamp(0, _sessions.length - 1)];

    final delta = current.totalVolume - previous.totalVolume;
    final deltaPct = previous.totalVolume > 0
        ? (delta / previous.totalVolume) * 100
        : null;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Compare sessions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Now: ${current.workoutName} (${current.bodyPart})'),
              Text('Prev: ${previous.workoutName} (${previous.bodyPart})'),
              const SizedBox(height: 12),
              Text(
                'Volume change: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}'
                '${deltaPct == null ? '' : ' (${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(0)}%)'}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: 10),
              if (current.overloadDetails.isNotEmpty)
                ...current.overloadDetails.take(3).map((d) => Text('• $d'))
              else
                Text(
                  'No specific overload details detected.',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Workout Analysis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No workout data yet. Log an exercise to generate your first analysis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filterBodyPart == null
                                    ? 'Swipe for previous sessions'
                                    : '$_filterBodyPart sessions',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Compare (long-press also works)',
                              onPressed: () => _showCompare(context),
                              icon: const Icon(Icons.compare_arrows),
                            ),
                            IconButton(
                              tooltip: 'Refresh',
                              onPressed: _loadSessions,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _index = i),
                            itemCount: _sessions.length,
                            itemBuilder: (context, i) {
                              final a = _sessions[i];
                              return DailyWorkoutAnalysisCard(
                                analysis: a,
                                onTap: () =>
                                    DailyWorkoutAnalysisDetailsSheet.show(
                                      context,
                                      analysis: a,
                                    ),
                                onLongPress: () => _showCompare(context),
                                onViewDetails: () =>
                                    DailyWorkoutAnalysisDetailsSheet.show(
                                      context,
                                      analysis: a,
                                    ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Done'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }
}
