import 'package:flutter/material.dart';
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
  WorkoutAnalysisIndex? _indexData;
  List<WorkoutSessionKey> _sessionKeys = [];
  final Map<String, DailyWorkoutAnalysis> _analysisCache = {};
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

    // Reuse the cached index to avoid rebuilding on every open.
    final index = await DailyWorkoutAnalysisEngine.loadIndexCached();
    final keys = DailyWorkoutAnalysisEngine.sessionKeys(
      index,
      bodyPart: bodyPartArg,
    );
    _analysisCache.clear();

    // Filter if requested
    _filterBodyPart = bodyPartArg;

    int initial = 0;
    if (dateArg != null) {
      final d = DailyWorkoutAnalysisEngine.dayStart(dateArg);
      final found = keys.indexWhere((k) => k.day == d);
      if (found >= 0) initial = found;
    }

    setState(() {
      _indexData = index;
      _sessionKeys = keys;
      _index = initial.clamp(0, (_sessionKeys.length - 1).clamp(0, 999999));
      _loading = false;
    });

    if (_sessionKeys.isNotEmpty) {
      _pageController.jumpToPage(_index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DailyWorkoutAnalysis? _analysisAt(int i) {
    final index = _indexData;
    if (index == null) return null;
    if (i < 0 || i >= _sessionKeys.length) return null;
    final key = _sessionKeys[i];
    final cached = _analysisCache[key.cacheKey];
    if (cached != null) return cached;
    final a = DailyWorkoutAnalysisEngine.analyzeFromIndex(
      index,
      day: key.day,
      bodyPart: key.bodyPart,
    );
    if (a != null) {
      _analysisCache[key.cacheKey] = a;
    }
    return a;
  }

  Future<void> _showCompare(BuildContext context) async {
    if (_sessionKeys.length < 2) return;
    final current = _analysisAt(_index);
    final previous = _analysisAt((_index + 1).clamp(0, _sessionKeys.length - 1));
    if (current == null || previous == null) return;

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
            child: _sessionKeys.isEmpty
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
                            itemCount: _sessionKeys.length,
                            itemBuilder: (context, i) {
                              // PageView builds adjacent pages; keep open fast by only
                              // computing the analysis for the visible page.
                              final isActive = i == _index;
                              if (!isActive) {
                                return Center(
                                  child: Text(
                                    'Swipe to view this session',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                );
                              }

                              final a = _analysisAt(i);
                              if (a == null) {
                                return Center(
                                  child: Text(
                                    'Unable to load analysis for this session.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                );
                              }
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
