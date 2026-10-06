import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_bar_chart.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_line_chart.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_gate.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';
import 'package:intl/intl.dart';

import 'package:fitness_aura_athletix/services/premium_access_service.dart';

enum _VolumeView { weekly, monthly, byExercise, byMuscleGroup }

enum _OverloadSignal { overload, maintain, plateau }

class VolumeLoadScreen extends StatefulWidget {
  const VolumeLoadScreen({Key? key}) : super(key: key);

  @override
  State<VolumeLoadScreen> createState() => _VolumeLoadScreenState();
}

class _VolumeLoadScreenState extends State<VolumeLoadScreen> {
  bool _loading = true;
  bool _isPremium = false;

  List<ExerciseRecord> _records = const [];

  _VolumeView _view = _VolumeView.weekly;
  bool _compareMode = false;

  int? _selectedVolumePoint;
  int? _selectedMuscleBar;

  final TextEditingController _searchController = TextEditingController();
  String _bodyPartFilter = 'All';
  int _rangeDays = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await StorageService().loadExerciseRecords();
    final premium = await PremiumAccessService().isPremiumActive();
    if (!mounted) return;
    setState(() {
      _records = records;
      _isPremium = premium;
      _loading = false;
    });
  }

  bool _isViewLocked(_VolumeView v) {
    if (_isPremium) return false;
    return v != _VolumeView.weekly;
  }

  void _selectView(_VolumeView v) {
    setState(() {
      _view = v;
      _selectedVolumePoint = null;
      _selectedMuscleBar = null;
    });
  }

  void _showComparisonOffer() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: PremiumFeatureOfferCard(
            title: 'Volume comparisons',
            description: 'Compare training volume across time periods.',
            icon: Icons.compare_arrows_rounded,
            featureLabel: 'VOLUME TRENDS',
            accentColor: const Color(0xFF7653D6),
            unlockedContent: _comparisonOfferDetails(sheetContext),
            benefits: const [
              'Compare complete, like-for-like 7-day or 30-day windows.',
              'See total load, percentage change, and training-day frequency.',
              'Identify which muscle-group volumes changed most.',
              'Use the trend as context alongside recovery and effort, not as a target to chase.',
            ],
            onAccessChanged: () async {
              await _load();
              if (!mounted || !_isPremium) return;
              setState(() => _compareMode = true);
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _comparisonOfferDetails(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekly = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 7);
    final previous = _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final weekChange = previous > 0
        ? ((weekly - previous) / previous) * 100
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your comparison dashboard',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weekChange == null
                ? 'Your last 7 days contain ${weekly.toStringAsFixed(0)} kg of logged volume. Log a previous week to establish a comparison baseline.'
                : 'Your last 7 days: ${weekly.toStringAsFixed(0)} kg (${_pctText(weekChange)} vs the previous 7 days).',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'The dashboard adds frequency and muscle-group changes, and also works with full monthly windows.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }

  Color _deltaColor(double pct) {
    final scheme = Theme.of(context).colorScheme;
    if (pct > 0) return scheme.tertiary;
    if (pct < 0) return scheme.error;
    return scheme.onSurfaceVariant;
  }

  String _pctText(double pct) {
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}%';
  }

  double _totalVolumeForWindow({
    required int startDaysAgo,
    required int lengthDays,
  }) {
    final end = _dayStart(
      DateTime.now(),
    ).subtract(Duration(days: startDaysAgo));
    final start = end.subtract(Duration(days: lengthDays - 1));
    return _records
        .where(
          (r) =>
              !_dayStart(r.dateRecorded).isBefore(start) &&
              !_dayStart(r.dateRecorded).isAfter(end),
        )
        .fold<double>(0, (s, r) => s + r.volumeLoadKg);
  }

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int _trainingDaysInLastDays(int days) {
    final today = _dayStart(DateTime.now());
    final cutoff = today.subtract(Duration(days: days - 1));
    final set = <DateTime>{};
    for (final r in _records) {
      final day = _dayStart(r.dateRecorded);
      if (day.isBefore(cutoff) || day.isAfter(today)) continue;
      set.add(day);
    }
    return set.length;
  }

  Map<String, double> _muscleVolumeInLastDays(int days) {
    final today = _dayStart(DateTime.now());
    final cutoff = today.subtract(Duration(days: days - 1));
    final m = <String, double>{};
    for (final r in _records) {
      final day = _dayStart(r.dateRecorded);
      if (day.isBefore(cutoff) || day.isAfter(today)) continue;
      final vol = r.volumeLoadKg;
      m.update(r.bodyPart, (v) => v + vol, ifAbsent: () => vol);
    }
    return m;
  }

  Map<String, double> _muscleVolumeForWindow({
    required int startDaysAgo,
    required int lengthDays,
  }) {
    final end = _dayStart(
      DateTime.now(),
    ).subtract(Duration(days: startDaysAgo));
    final start = end.subtract(Duration(days: lengthDays - 1));
    final volumes = <String, double>{};
    for (final record in _records) {
      final day = _dayStart(record.dateRecorded);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      volumes.update(
        record.bodyPart,
        (value) => value + record.volumeLoadKg,
        ifAbsent: () => record.volumeLoadKg,
      );
    }
    return volumes;
  }

  int _trainingDaysForWindow({
    required int startDaysAgo,
    required int lengthDays,
  }) {
    final end = _dayStart(
      DateTime.now(),
    ).subtract(Duration(days: startDaysAgo));
    final start = end.subtract(Duration(days: lengthDays - 1));
    return _records
        .map((record) => _dayStart(record.dateRecorded))
        .where((day) => !day.isBefore(start) && !day.isAfter(end))
        .toSet()
        .length;
  }

  String _mostTrainedBodyPart(int days) {
    final map = _muscleVolumeInLastDays(days);
    if (map.isEmpty) return '—';
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<LineChartPoint> _weeklyVolumeSeries() {
    final now = DateTime.now();
    final fmt = DateFormat('EEE');
    final points = <LineChartPoint>[];

    for (int i = 6; i >= 0; i--) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      double vol = 0;
      for (final r in _records) {
        final rd = DateTime(
          r.dateRecorded.year,
          r.dateRecorded.month,
          r.dateRecorded.day,
        );
        if (rd == d) vol += r.volumeLoadKg;
      }
      points.add(
        LineChartPoint(
          label: fmt.format(d),
          value: vol,
          tooltip: '${fmt.format(d)}: ${vol.toStringAsFixed(0)} kg',
        ),
      );
    }
    return points;
  }

  List<LineChartPoint> _monthlyVolumeSeries() {
    final now = DateTime.now();
    final points = <LineChartPoint>[];

    // Aggregate by week (5 points max) to keep readable.
    for (int w = 0; w < 5; w++) {
      final startDaysAgo = (w * 7) + 6;
      final endDaysAgo = w * 7;
      final end = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: endDaysAgo));
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: startDaysAgo));

      double vol = 0;
      for (final r in _records) {
        final d = DateTime(
          r.dateRecorded.year,
          r.dateRecorded.month,
          r.dateRecorded.day,
        );
        if (!d.isBefore(start) && !d.isAfter(end)) {
          vol += r.volumeLoadKg;
        }
      }

      points.add(
        LineChartPoint(
          label: 'W${5 - w}',
          value: vol,
          tooltip: 'Week: ${vol.toStringAsFixed(0)} kg',
        ),
      );
    }

    return points.reversed.toList();
  }

  List<BarChartBar> _muscleBarsForDays(int days) {
    final map = _muscleVolumeInLastDays(days);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return entries.take(8).map((e) {
      final pct = total <= 0 ? 0 : (e.value / total) * 100;
      return BarChartBar(
        label: e.key,
        value: e.value,
        tooltip:
            '${e.key}: ${e.value.toStringAsFixed(0)} kg (${pct.toStringAsFixed(0)}%)',
        color: _muscleColor(e.key),
      );
    }).toList();
  }

  Color _muscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'legs':
        return Colors.indigo;
      case 'back':
        return Colors.teal;
      case 'chest':
        return Colors.deepOrange;
      case 'shoulders':
        return Colors.purple;
      case 'arms':
        return Colors.blueGrey;
      case 'core':
        return Colors.brown;
      case 'glutes':
        return Colors.green;
      case 'abs':
        return Colors.redAccent;
      default:
        return Colors.blue;
    }
  }

  List<String> _bodyParts() {
    final set = <String>{};
    for (final r in _records) {
      set.add(r.bodyPart);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<_ExerciseStats> _exerciseStats({required int days}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days - 1));
    final filtered = _records
        .where((r) => !r.dateRecorded.isBefore(cutoff))
        .toList();

    final by = <String, List<ExerciseRecord>>{};
    for (final r in filtered) {
      if (_bodyPartFilter != 'All' && r.bodyPart != _bodyPartFilter) continue;
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty && !r.exerciseName.toLowerCase().contains(q)) continue;
      by.putIfAbsent(r.exerciseName, () => []).add(r);
    }

    final out = <_ExerciseStats>[];
    for (final e in by.entries) {
      final rs = e.value
        ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
      final last = rs.last;

      double best = 0;
      double sum = 0;
      int n = 0;
      for (final r in rs) {
        final w = r.effectiveWeightKg;
        best = best < w ? w : best;
        sum += w;
        n++;
      }

      final avg = n == 0 ? 0.0 : sum / n;
      final (signal, reason) = _overloadSignalForExercise(rs);

      out.add(
        _ExerciseStats(
          exerciseName: e.key,
          bodyPart: last.bodyPart,
          lastLoadKg: last.effectiveWeightKg,
          bestLoadKg: best,
          avgLoadKg: avg,
          signal: signal,
          signalReason: reason,
          weekVolumeKg: rs.fold<double>(0, (s, r) => s + r.volumeLoadKg),
        ),
      );
    }

    out.sort((a, b) => b.weekVolumeKg.compareTo(a.weekVolumeKg));
    return out;
  }

  (_OverloadSignal, String) _overloadSignalForExercise(
    List<ExerciseRecord> sortedAsc,
  ) {
    if (sortedAsc.length < 2) {
      return (_OverloadSignal.maintain, 'Log more sessions to detect trends.');
    }

    final last = sortedAsc[sortedAsc.length - 1];
    final prev = sortedAsc[sortedAsc.length - 2];

    final lastVol = last.volumeLoadKg;
    final prevVol = prev.volumeLoadKg;

    final changePct = prevVol > 0 ? ((lastVol - prevVol) / prevVol) * 100 : 0.0;

    if (changePct >= 5) {
      if (last.effectiveWeightKg > prev.effectiveWeightKg) {
        return (_OverloadSignal.overload, 'Volume increased by weight.');
      }
      if (last.repsPerSet > prev.repsPerSet)
        return (_OverloadSignal.overload, 'Volume increased by reps.');
      if (last.sets > prev.sets)
        return (_OverloadSignal.overload, 'Volume increased by sets.');
      return (_OverloadSignal.overload, 'Volume increased.');
    }

    if (changePct <= -5) {
      return (
        _OverloadSignal.plateau,
        'Volume dropped — consider recovery or technique.',
      );
    }

    return (_OverloadSignal.maintain, 'Maintain — steady output.');
  }

  Widget _topWeeklySummary() {
    final scheme = Theme.of(context).colorScheme;
    final week = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 7);
    final lastWeek = _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final pct = lastWeek > 0 ? ((week - lastWeek) / lastWeek) * 100 : 0.0;
    final sessions = _trainingDaysInLastDays(7);
    final focus = _mostTrainedBodyPart(7);

    final deltaColor = _deltaColor(pct);
    final deltaIcon = pct > 0
        ? Icons.arrow_drop_up
        : (pct < 0 ? Icons.arrow_drop_down : Icons.arrow_right);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                _CompareToggle(
                  value: _compareMode,
                  onChanged: (v) => setState(() => _compareMode = v),
                  isPremium: _isPremium,
                  onUpgrade: _showComparisonOffer,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryLine(
                    title: 'Total Volume',
                    value: '${week.toStringAsFixed(0)} kg',
                    trailing: lastWeek == 0
                        ? Text(
                            'Baseline needed',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(deltaIcon, color: deltaColor, size: 26),
                              Text(
                                _pctText(pct),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: deltaColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryLine(
                    title: 'Training Days',
                    value: '$sessions / 5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryLine(title: 'Focus', value: focus),
                ),
              ],
            ),
            if (_compareMode) ...[
              const SizedBox(height: 12),
              _compareBars(
                leftLabel: 'This week',
                leftValue: week,
                rightLabel: 'Last week',
                rightValue: lastWeek,
              ),
              const SizedBox(height: 10),
              _comparisonInsights(
                days: 7,
                currentLabel: 'Last 7 days',
                previousLabel: 'Previous 7 days',
                currentVolume: week,
                previousVolume: lastWeek,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topMonthlySummary() {
    final scheme = Theme.of(context).colorScheme;
    final month = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 30);
    final lastMonth = _totalVolumeForWindow(startDaysAgo: 30, lengthDays: 30);
    final pct = lastMonth > 0 ? ((month - lastMonth) / lastMonth) * 100 : 0.0;
    final sessions = _trainingDaysInLastDays(30);
    final focus = _mostTrainedBodyPart(30);

    final deltaColor = _deltaColor(pct);
    final deltaIcon = pct > 0
        ? Icons.arrow_drop_up
        : (pct < 0 ? Icons.arrow_drop_down : Icons.arrow_right);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'THIS MONTH',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                _CompareToggle(
                  value: _compareMode,
                  onChanged: (v) => setState(() => _compareMode = v),
                  isPremium: _isPremium,
                  onUpgrade: _showComparisonOffer,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _summaryLine(
              title: 'Total Volume',
              value: '${month.toStringAsFixed(0)} kg',
              trailing: lastMonth == 0
                  ? Text(
                      'Baseline needed',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(deltaIcon, color: deltaColor, size: 26),
                        Text(
                          _pctText(pct),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: deltaColor,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryLine(
                    title: 'Training Days',
                    value: sessions.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryLine(title: 'Focus', value: focus),
                ),
              ],
            ),
            if (_compareMode) ...[
              const SizedBox(height: 12),
              _compareBars(
                leftLabel: 'This month',
                leftValue: month,
                rightLabel: 'Last month',
                rightValue: lastMonth,
              ),
              const SizedBox(height: 10),
              _comparisonInsights(
                days: 30,
                currentLabel: 'Last 30 days',
                previousLabel: 'Previous 30 days',
                currentVolume: month,
                previousVolume: lastMonth,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryLine({
    required String title,
    required String value,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _compareBars({
    required String leftLabel,
    required double leftValue,
    required String rightLabel,
    required double rightValue,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final maxV = [leftValue, rightValue].reduce((a, b) => a > b ? a : b);
    final l = maxV <= 0 ? 0.0 : (leftValue / maxV);
    final r = maxV <= 0 ? 0.0 : (rightValue / maxV);

    Widget bar(String label, double frac, double value, Color color) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${value.toStringAsFixed(0)} kg',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        bar(leftLabel, l, leftValue, scheme.primary),
        const SizedBox(width: 12),
        bar(rightLabel, r, rightValue, scheme.secondary),
      ],
    );
  }

  Widget _safetyCardIfNeeded() {
    final scheme = Theme.of(context).colorScheme;
    final week = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 7);
    final lastWeek = _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final pct = lastWeek > 0 ? ((week - lastWeek) / lastWeek) * 100 : 0.0;
    if (pct < 20) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: scheme.errorContainer.withValues(alpha: 0.48),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Icon(Icons.health_and_safety_outlined, color: scheme.error),
        title: Text(
          'Load safety',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Load spike ${pct.toStringAsFixed(0)}% — consider a lighter session or a deload soon.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
        ),
      ),
    );
  }

  Widget _aiInsightCard() {
    final scheme = Theme.of(context).colorScheme;
    final thisWeek = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 7);
    final lastWeek = _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final change = lastWeek > 0
        ? ((thisWeek - lastWeek) / lastWeek) * 100
        : null;
    final trainingDays = _trainingDaysForWindow(startDaysAgo: 0, lengthDays: 7);
    final muscles = _muscleVolumeForWindow(
      startDaysAgo: 0,
      lengthDays: 7,
    ).entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final exerciseStats = _exerciseStats(days: 30).take(3).toList();
    final focus = muscles.isEmpty
        ? 'No muscle-group volume recorded this week.'
        : thisWeek <= 0
        ? 'The current week has no positive load total to compare.'
        : '${muscles.first.key} leads this week at '
              '${(muscles.first.value / thisWeek * 100).toStringAsFixed(0)}% '
              'of logged volume.';
    final loadGuidance = change == null
        ? 'Log training in two consecutive weeks to unlock a like-for-like load trend.'
        : change >= 25
        ? 'Weekly volume is up ${change.toStringAsFixed(0)}%. Review effort and recovery before adding more work.'
        : change <= -25
        ? 'Weekly volume is down ${change.abs().toStringAsFixed(0)}%. Check whether this was planned recovery or missed logging before changing your plan.'
        : 'Weekly volume is ${_pctText(change)} versus the previous week. Keep progression aligned with your planned training and recovery.';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.48),
              scheme.surfaceContainerLow,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly training brief',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Based on your logged training data',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _comparisonMetric(
                  context,
                  'LAST 7 DAYS',
                  '${thisWeek.toStringAsFixed(0)} kg',
                  color: scheme.primary,
                ),
                _comparisonMetric(
                  context,
                  'ACTIVE DAYS',
                  '$trainingDays',
                  color: scheme.onSurface,
                ),
                _comparisonMetric(
                  context,
                  'WEEK-OVER-WEEK',
                  change == null ? 'Baseline needed' : _pctText(change),
                  color: change == null
                      ? scheme.onSurfaceVariant
                      : _deltaColor(change),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _loadBriefSection(
              context,
              icon: Icons.monitor_heart_outlined,
              title: 'Load context',
              message: loadGuidance,
            ),
            const SizedBox(height: 10),
            _loadBriefSection(
              context,
              icon: Icons.pie_chart_outline_rounded,
              title: 'Muscle-group distribution',
              message: focus,
            ),
            if (exerciseStats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent exercise signals',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              for (final stats in exerciseStats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        switch (stats.signal) {
                          _OverloadSignal.overload => Icons.trending_up_rounded,
                          _OverloadSignal.maintain =>
                            Icons.trending_flat_rounded,
                          _OverloadSignal.plateau =>
                            Icons.trending_down_rounded,
                        },
                        size: 17,
                        color: switch (stats.signal) {
                          _OverloadSignal.overload => scheme.tertiary,
                          _OverloadSignal.maintain => scheme.secondary,
                          _OverloadSignal.plateau => scheme.error,
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${stats.exerciseName} · ${stats.signalReason}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Text(
              'Volume is a comparison aid, not a measure of recovery or a prescription. Interpret changes alongside effort, pain, sleep, and your training plan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadBriefSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _muscleBreakdownList(int days) {
    final scheme = Theme.of(context).colorScheme;
    final map = _muscleVolumeInLastDays(days);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (entries.isEmpty || total <= 0) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Log workouts to see muscle load breakdown.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final avg = total / entries.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muscle group load',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in entries.take(10)) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _muscleColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value.toStringAsFixed(0)} kg · ${((e.value / total) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (e.value / total).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(_muscleColor(e.key)),
                ),
              ),
              if (e.value < avg * 0.55) ...[
                const SizedBox(height: 6),
                Text(
                  'Lower share of this period’s load',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _exerciseTracking() {
    final scheme = Theme.of(context).colorScheme;
    final stats = _exerciseStats(days: _rangeDays);
    if (stats.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No matching exercises yet. Try clearing filters or logging workouts.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: stats.map((s) {
        final icon = switch (s.signal) {
          _OverloadSignal.overload => Icons.check_circle_outline,
          _OverloadSignal.maintain => Icons.remove_circle_outline,
          _OverloadSignal.plateau => Icons.error_outline,
        };
        final color = switch (s.signal) {
          _OverloadSignal.overload => scheme.tertiary,
          _OverloadSignal.maintain => scheme.secondary,
          _OverloadSignal.plateau => scheme.error,
        };

        final trend = s.lastLoadKg > s.avgLoadKg
            ? Icons.trending_up
            : (s.lastLoadKg < s.avgLoadKg
                  ? Icons.trending_down
                  : Icons.trending_flat);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (sheetContext) {
                    final sheetScheme = Theme.of(sheetContext).colorScheme;
                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.exerciseName,
                              style: Theme.of(sheetContext).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              s.bodyPart,
                              style: TextStyle(
                                color: sheetScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _detailLine(
                              sheetContext,
                              'Training signal',
                              s.signal.name,
                            ),
                            _detailLine(
                              sheetContext,
                              'Recent trend',
                              switch (trend) {
                                Icons.trending_up => 'Improving',
                                Icons.trending_down => 'Dropping',
                                _ => 'Stable',
                              },
                            ),
                            _detailLine(
                              sheetContext,
                              'Average load',
                              '${s.avgLoadKg.toStringAsFixed(1)} kg',
                            ),
                            _detailLine(
                              sheetContext,
                              'Best load',
                              '${s.bestLoadKg.toStringAsFixed(1)} kg',
                            ),
                            _detailLine(
                              sheetContext,
                              'Last load',
                              '${s.lastLoadKg.toStringAsFixed(1)} kg',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.signalReason,
                              style: TextStyle(
                                color: sheetScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.exerciseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                s.bodyPart,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            s.signal.name.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _loadPill(context, 'Last', s.lastLoadKg),
                        _loadPill(context, 'Best', s.bestLoadKg),
                        _loadPill(context, 'Average', s.avgLoadKg),
                        _loadPill(
                          context,
                          'Range volume',
                          s.weekVolumeKg,
                          suffix: ' kg',
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Icon(trend, size: 17, color: scheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.signalReason,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _loadPill(
    BuildContext context,
    String label,
    double value, {
    String suffix = ' kg',
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$label  ${value.toStringAsFixed(1)}$suffix',
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailLine(BuildContext context, String title, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search exercise',
                hintText: 'Squat, Bench, Chest…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final bodyPartDropdown = DropdownButtonFormField<String>(
                  value: _bodyPartFilter,
                  isExpanded: true,
                  items: _bodyParts()
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _bodyPartFilter = v ?? 'All'),
                  decoration: const InputDecoration(labelText: 'Body part'),
                );
                final rangeDropdown = DropdownButtonFormField<int>(
                  value: _rangeDays,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                    DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                    DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                  ],
                  onChanged: (v) => setState(() => _rangeDays = v ?? 30),
                  decoration: const InputDecoration(labelText: 'Range'),
                );

                if (constraints.maxWidth < 440) {
                  return Column(
                    children: [
                      bodyPartDropdown,
                      const SizedBox(height: 10),
                      rangeDropdown,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: bodyPartDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: rangeDropdown),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const views = [
      (
        view: _VolumeView.weekly,
        label: 'Weekly',
        icon: Icons.calendar_view_week_outlined,
      ),
      (
        view: _VolumeView.monthly,
        label: 'Monthly',
        icon: Icons.calendar_month_outlined,
      ),
      (
        view: _VolumeView.byExercise,
        label: 'Exercise',
        icon: Icons.fitness_center_outlined,
      ),
      (
        view: _VolumeView.byMuscleGroup,
        label: 'Muscle',
        icon: Icons.groups_outlined,
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final item in views) ...[
              ChoiceChip(
                avatar: Icon(
                  item.icon,
                  size: 17,
                  color: _view == item.view
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.label),
                    if (_isViewLocked(item.view)) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.lock_outline_rounded, size: 13),
                    ],
                  ],
                ),
                selected: _view == item.view,
                onSelected: (_) => _selectView(item.view),
                showCheckmark: false,
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: _view == item.view
                      ? scheme.onPrimary
                      : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: _view == item.view
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartSection({
    required String title,
    required String subtitle,
    required Widget chart,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
            ),
            const SizedBox(height: 12),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _sectionIntro(String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _comparisonInsights({
    required int days,
    required String currentLabel,
    required String previousLabel,
    required double currentVolume,
    required double previousVolume,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final currentDays = _trainingDaysForWindow(
      startDaysAgo: 0,
      lengthDays: days,
    );
    final previousDays = _trainingDaysForWindow(
      startDaysAgo: days,
      lengthDays: days,
    );
    final currentMuscles = _muscleVolumeForWindow(
      startDaysAgo: 0,
      lengthDays: days,
    );
    final previousMuscles = _muscleVolumeForWindow(
      startDaysAgo: days,
      lengthDays: days,
    );
    final muscleChanges =
        <({String name, double current, double previous})>[
          for (final name in {...currentMuscles.keys, ...previousMuscles.keys})
            (
              name: name,
              current: currentMuscles[name] ?? 0,
              previous: previousMuscles[name] ?? 0,
            ),
        ]..sort(
          (a, b) => (b.current - b.previous).abs().compareTo(
            (a.current - a.previous).abs(),
          ),
        );
    final totalChange = previousVolume > 0
        ? ((currentVolume - previousVolume) / previousVolume) * 100
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$currentLabel vs $previousLabel',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _comparisonMetric(
                context,
                'LOAD CHANGE',
                totalChange == null ? 'No baseline yet' : _pctText(totalChange),
                color: totalChange == null
                    ? scheme.onSurfaceVariant
                    : _deltaColor(totalChange),
              ),
              _comparisonMetric(
                context,
                'TRAINING DAYS',
                '$currentDays vs $previousDays',
                color: scheme.onSurface,
              ),
              _comparisonMetric(
                context,
                'AVG LOAD / DAY',
                '${(currentDays == 0 ? 0 : currentVolume / currentDays).toStringAsFixed(0)} kg',
                color: scheme.onSurface,
              ),
            ],
          ),
          if (muscleChanges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Largest muscle-group shifts',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            for (final change in muscleChanges.take(2))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        change.name,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      '${change.current.toStringAsFixed(0)} kg vs ${change.previous.toStringAsFixed(0)} kg',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (previousVolume == 0) ...[
            const SizedBox(height: 8),
            Text(
              'A percentage change will appear after you have volume logged in both periods.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _comparisonMetric(
    BuildContext context,
    String label,
    String value, {
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPoints = _weeklyVolumeSeries();
    final monthlyPoints = _monthlyVolumeSeries();
    final weekMuscleBars = _muscleBarsForDays(7);
    final monthMuscleBars = _muscleBarsForDays(30);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume & Load'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      _viewSelector(context),
                      const SizedBox(height: 14),

                      if (_view == _VolumeView.weekly) ...[
                        _topWeeklySummary(),
                        const SizedBox(height: 12),
                        _safetyCardIfNeeded(),
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Weekly training brief',
                          previewText:
                              'Get a data-backed readout of weekly load, training frequency, muscle-group distribution, and recent exercise signals.',
                          featureLabel: 'WEEKLY LOAD COACHING',
                          accentColor: const Color(0xFFC65B47),
                          benefits: const [
                            'Compare this week’s logged volume with the previous week.',
                            'See active training days and the largest muscle-group focus.',
                            'Review recent exercise-level increases, stable trends, or drops.',
                            'Get cautious context for interpreting changes alongside recovery.',
                          ],
                          onAccessChanged: _load,
                          child: _aiInsightCard(),
                        ),
                        const SizedBox(height: 14),
                        _chartSection(
                          title: 'Weekly training volume',
                          subtitle:
                              'Daily training load · tap a point for details',
                          chart: SimpleLineChart(
                            points: weeklyPoints,
                            selectedIndex: _selectedVolumePoint,
                            onSelected: (i) =>
                                setState(() => _selectedVolumePoint = i),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Muscle breakdown',
                          previewText:
                              'Explore where logged training volume is concentrated across muscle groups.',
                          featureLabel: 'MUSCLE DISTRIBUTION',
                          accentColor: const Color(0xFF168A63),
                          benefits: const [
                            'See how weekly training load is distributed by muscle.',
                            'Find muscle groups receiving less or more attention.',
                            'Open detailed totals to guide balanced programming.',
                          ],
                          onAccessChanged: _load,
                          child: Column(
                            children: [
                              _chartSection(
                                title: 'Load by muscle group',
                                subtitle:
                                    'Distribution of your training load this week',
                                chart: SimpleBarChart(
                                  bars: weekMuscleBars,
                                  selectedIndex: _selectedMuscleBar,
                                  onSelected: (i) =>
                                      setState(() => _selectedMuscleBar = i),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _muscleBreakdownList(7),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Exercise-level tracking',
                          previewText:
                              'Inspect recent, average, and best loads movement by movement.',
                          featureLabel: 'MOVEMENT TRENDS',
                          accentColor: const Color(0xFFD97706),
                          benefits: const [
                            'Compare recent, average, and best exercise loads.',
                            'Track overload signals across logged sessions.',
                            'Filter the exercise list by movement or body part.',
                          ],
                          onAccessChanged: _load,
                          child: Column(
                            children: [
                              _filtersRow(),
                              const SizedBox(height: 10),
                              _exerciseTracking(),
                            ],
                          ),
                        ),
                      ],

                      if (_view == _VolumeView.monthly) ...[
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Monthly analytics',
                          previewText:
                              'Review the last 30 days against the previous month with weekly load and muscle-group context.',
                          featureLabel: 'LONG-RANGE TRENDS',
                          accentColor: const Color(0xFF3575D3),
                          benefits: const [
                            'Review volume patterns across recent months.',
                            'Compare weekly totals and muscle-group distribution.',
                            'Use longer-term context to adjust your training.',
                          ],
                          onAccessChanged: _load,
                          child: Column(
                            children: [
                              _topMonthlySummary(),
                              const SizedBox(height: 14),
                              _chartSection(
                                title: 'Monthly training volume',
                                subtitle:
                                    'Weekly totals across the last five weeks',
                                chart: SimpleLineChart(
                                  points: monthlyPoints,
                                  selectedIndex: _selectedVolumePoint,
                                  onSelected: (i) =>
                                      setState(() => _selectedVolumePoint = i),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _chartSection(
                                title: 'Load by muscle group',
                                subtitle:
                                    'Distribution of your training load this month',
                                chart: SimpleBarChart(
                                  bars: monthMuscleBars,
                                  selectedIndex: _selectedMuscleBar,
                                  onSelected: (i) =>
                                      setState(() => _selectedMuscleBar = i),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _muscleBreakdownList(30),
                            ],
                          ),
                        ),
                      ],

                      if (_view == _VolumeView.byExercise) ...[
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Exercise load tracking',
                          previewText:
                              'Search and filter your exercise history to inspect recent, average, best, and changing loads.',
                          featureLabel: 'EXERCISE HISTORY',
                          accentColor: const Color(0xFFD97706),
                          benefits: const [
                            'Review recent, average, and best loads per exercise.',
                            'Spot progress or plateaus in individual movements.',
                            'Filter by body part and search your exercise history.',
                          ],
                          onAccessChanged: _load,
                          child: Column(
                            children: [
                              _sectionIntro(
                                'Exercise load tracking',
                                'Compare recent, average and best training loads',
                              ),
                              _filtersRow(),
                              const SizedBox(height: 12),
                              _exerciseTracking(),
                            ],
                          ),
                        ),
                      ],

                      if (_view == _VolumeView.byMuscleGroup) ...[
                        PremiumGate(
                          isPremium: _isPremium,
                          title: 'Muscle-group analytics',
                          previewText:
                              'Compare each muscle group’s logged load and share of the selected period.',
                          featureLabel: 'MUSCLE LOAD MAP',
                          accentColor: const Color(0xFF168A63),
                          benefits: const [
                            'Compare training load across muscle groups.',
                            'See a breakdown of each group’s share of weekly load.',
                            'Use distribution patterns to plan balanced sessions.',
                          ],
                          onAccessChanged: _load,
                          child: Column(
                            children: [
                              _topWeeklySummary(),
                              const SizedBox(height: 14),
                              _chartSection(
                                title: 'Load by muscle group',
                                subtitle:
                                    'Tap a bar to see its share of your total load',
                                chart: SimpleBarChart(
                                  bars: weekMuscleBars,
                                  selectedIndex: _selectedMuscleBar,
                                  onSelected: (i) =>
                                      setState(() => _selectedMuscleBar = i),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _muscleBreakdownList(7),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CompareToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isPremium;
  final VoidCallback onUpgrade;

  const _CompareToggle({
    required this.value,
    required this.onChanged,
    required this.isPremium,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'Compare',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (!isPremium) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ],
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          onChanged: isPremium
              ? onChanged
              : (_) {
                  onUpgrade();
                },
        ),
      ],
    );
  }
}

class _ExerciseStats {
  final String exerciseName;
  final String bodyPart;
  final double lastLoadKg;
  final double bestLoadKg;
  final double avgLoadKg;
  final double weekVolumeKg;
  final _OverloadSignal signal;
  final String signalReason;

  const _ExerciseStats({
    required this.exerciseName,
    required this.bodyPart,
    required this.lastLoadKg,
    required this.bestLoadKg,
    required this.avgLoadKg,
    required this.weekVolumeKg,
    required this.signal,
    required this.signalReason,
  });
}
