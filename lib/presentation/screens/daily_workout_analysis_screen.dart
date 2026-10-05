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
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
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
    if (!mounted) return;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_index);
        }
      });
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

  void _movePage(int delta) {
    final next = (_index + delta).clamp(0, _sessionKeys.length - 1);
    if (next == _index || !_pageController.hasClients) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Workout Analysis')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessionKeys.isEmpty
                  ? _emptyState(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _filterBodyPart == null
                                        ? 'Your sessions'
                                        : '$_filterBodyPart sessions',
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Swipe to move through your training history',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Compare sessions',
                              onPressed: _sessionKeys.length < 2
                                  ? null
                                  : () => _showCompare(context),
                              icon: const Icon(Icons.compare_arrows_rounded),
                            ),
                            IconButton(
                              tooltip: 'Refresh sessions',
                              onPressed: _loadSessions,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cardHeight = constraints.maxHeight.clamp(
                                0.0,
                                480.0,
                              );
                              return Center(
                                child: SizedBox(
                                  height: cardHeight,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (i) {
                                      setState(() => _index = i);
                                    },
                                    itemCount: _sessionKeys.length,
                                    itemBuilder: (context, i) {
                                      final a = _analysisAt(i);
                                      if (a == null) {
                                        return Center(
                                          child: Text(
                                            'Unable to load analysis for this session.',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10,
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 470,
                                            ),
                                            child: DailyWorkoutAnalysisCard(
                                              analysis: a,
                                              compact: true,
                                              onTap: () =>
                                                  DailyWorkoutAnalysisDetailsSheet
                                                      .show(
                                                        context,
                                                        analysis: a,
                                                      ),
                                              onLongPress: () =>
                                                  _showCompare(context),
                                              onViewDetails: () =>
                                                  DailyWorkoutAnalysisDetailsSheet
                                                      .show(
                                                        context,
                                                        analysis: a,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Previous session',
                              onPressed: _index < _sessionKeys.length - 1
                                  ? () => _movePage(1)
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${_index + 1} / ${_sessionKeys.length}',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next session',
                              onPressed: _index > 0
                                  ? () => _movePage(-1)
                                  : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Done'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 44,
              color: scheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Your training insights start here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log a workout to see progress, recovery, and personalized guidance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
