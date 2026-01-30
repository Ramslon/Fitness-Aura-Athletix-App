import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/core/models/volume_load.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_bar_chart.dart';
import 'package:fitness_aura_athletix/presentation/widgets/simple_line_chart.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_gate.dart';
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
  List<VolumeLoadData> _data = [];
  BodyLoadSummary? _summary;

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
    final data = await StorageService().getVolumeLoadData();
    final summary = await StorageService().getBodyLoadSummary();
    final records = await StorageService().loadExerciseRecords();
    final premium = await PremiumAccessService().isPremiumActive();
    setState(() {
      _data = data;
      _summary = summary;
      _records = records;
      _isPremium = premium;
      _loading = false;
    });
  }

  void _goToPremium() {
    Navigator.of(context).pushNamed('/premium-features');
  }

  bool _isViewLocked(_VolumeView v) {
    if (_isPremium) return false;
    // Keep beginners on Weekly. Premium unlocks the deeper views.
    return v != _VolumeView.weekly;
  }

  void _selectView(_VolumeView v) {
    if (_isViewLocked(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock advanced analytics 🔒')),
      );
      _goToPremium();
      return;
    }
    setState(() {
      _view = v;
      _selectedVolumePoint = null;
      _selectedMuscleBar = null;
    });
  }

  Widget _metricTile(String title, String value, {Color? color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, color: color ?? Colors.black)),
          ],
        ),
      ),
    );
  }

  Color _deltaColor(double pct) {
    if (pct > 0) return Colors.green;
    if (pct < 0) return Colors.red;
    return Colors.grey;
  }

  String _pctText(double pct) {
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}%';
  }

  double _totalVolumeForDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    return _records
        .where((r) => !r.dateRecorded.isBefore(cutoff))
      .fold<double>(0, (s, r) => s + r.volumeLoadKg);
  }

  double _totalVolumeForWindow({required int startDaysAgo, required int lengthDays}) {
    final end = DateTime.now().subtract(Duration(days: startDaysAgo));
    final start = end.subtract(Duration(days: lengthDays - 1));
    return _records
        .where((r) => !r.dateRecorded.isBefore(start) && !r.dateRecorded.isAfter(end))
      .fold<double>(0, (s, r) => s + r.volumeLoadKg);
  }

  int _trainingDaysInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    final set = <DateTime>{};
    for (final r in _records) {
      if (r.dateRecorded.isBefore(cutoff)) continue;
      set.add(DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day));
    }
    return set.length;
  }

  Map<String, double> _muscleVolumeInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days - 1));
    final m = <String, double>{};
    for (final r in _records) {
      if (r.dateRecorded.isBefore(cutoff)) continue;
      final vol = r.volumeLoadKg;
      m.update(r.bodyPart, (v) => v + vol, ifAbsent: () => vol);
    }
    return m;
  }

  String _mostTrainedBodyPart(int days) {
    final map = _muscleVolumeInLastDays(days);
    if (map.isEmpty) return '—';
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<LineChartPoint> _weeklyVolumeSeries() {
    final now = DateTime.now();
    final fmt = DateFormat('EEE');
    final points = <LineChartPoint>[];

    for (int i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      double vol = 0;
      for (final r in _records) {
        final rd = DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day);
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
      final end = DateTime(now.year, now.month, now.day).subtract(Duration(days: endDaysAgo));
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: startDaysAgo));

      double vol = 0;
      for (final r in _records) {
        final d = DateTime(r.dateRecorded.year, r.dateRecorded.month, r.dateRecorded.day);
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
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return entries.take(8).map((e) {
      final pct = total <= 0 ? 0 : (e.value / total) * 100;
      return BarChartBar(
        label: e.key,
        value: e.value,
        tooltip: '${e.key}: ${e.value.toStringAsFixed(0)} kg (${pct.toStringAsFixed(0)}%)',
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
    final filtered = _records.where((r) => !r.dateRecorded.isBefore(cutoff)).toList();

    final by = <String, List<ExerciseRecord>>{};
    for (final r in filtered) {
      if (_bodyPartFilter != 'All' && r.bodyPart != _bodyPartFilter) continue;
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty && !r.exerciseName.toLowerCase().contains(q)) continue;
      by.putIfAbsent(r.exerciseName, () => []).add(r);
    }

    final out = <_ExerciseStats>[];
    for (final e in by.entries) {
      final rs = e.value..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
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

  (_OverloadSignal, String) _overloadSignalForExercise(List<ExerciseRecord> sortedAsc) {
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
      if (last.repsPerSet > prev.repsPerSet) return (_OverloadSignal.overload, 'Volume increased by reps.');
      if (last.sets > prev.sets) return (_OverloadSignal.overload, 'Volume increased by sets.');
      return (_OverloadSignal.overload, 'Volume increased.');
    }

    if (changePct <= -5) {
      return (_OverloadSignal.plateau, 'Volume dropped — consider recovery or technique.');
    }

    return (_OverloadSignal.maintain, 'Maintain — steady output.');
  }

  List<String> _aiInsightsForWeek({required bool premium}) {
    // Max 2, actionable, trend-based.
    if (_records.isEmpty) return const [];

    final thisWeek = _totalVolumeForWindow(startDaysAgo: 0, lengthDays: 7);
    final lastWeek = _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final pct = lastWeek > 0 ? ((thisWeek - lastWeek) / lastWeek) * 100 : 0.0;

    final insights = <String>[];

    if (pct >= 20) {
      insights.add('Total load ↑ ${pct.toStringAsFixed(0)}% vs last week — consider a lighter session or an extra rest day.');
    } else if (pct.abs() <= 4 && thisWeek > 0) {
      insights.add('Total volume has been steady for 2 weeks — add 1 set to your main lift this week.');
    }

    // Muscle balance + spike check.
    final thisBy = _muscleVolumeInLastDays(7);
    final lastBy = _muscleVolumeInLastDays(14);
    final lastOnlyBy = <String, double>{};
    for (final e in lastBy.entries) {
      lastOnlyBy[e.key] = e.value - (thisBy[e.key] ?? 0);
    }

    String? spike;
    for (final m in thisBy.keys) {
      final t = thisBy[m] ?? 0;
      final l = lastOnlyBy[m] ?? 0;
      if (l <= 0) continue;
      final p = ((t - l) / l) * 100;
      if (p >= 20) {
        spike = '$m load ↑ ${p.toStringAsFixed(0)}% — monitor recovery and keep form strict.';
        break;
      }
    }
    if (spike != null && insights.length < 2) insights.add(spike);

    // Premium: add an extra layer of deload-style guidance (still actionable).
    if (premium && insights.length < 2) {
      final plateaued = _exerciseStats(days: 30).where((e) => e.signal == _OverloadSignal.plateau).toList();
      if (plateaued.isNotEmpty) {
        insights.add('${plateaued.first.exerciseName} is plateauing — reduce volume ~20% for 1 week, then rebuild.');
      }
    }

    if (insights.length >= 2) return insights.take(2).toList();

    final under = _undertrainedMuscles(thisBy);
    if (under.isNotEmpty && insights.length < 2) {
      insights.add('${under.first} is undertrained this week — add 1 accessory movement (2–3 sets).');
    }

    return insights.take(2).toList();
  }

  List<String> _undertrainedMuscles(Map<String, double> weekByMuscle) {
    final entries = weekByMuscle.entries.toList();
    if (entries.isEmpty) return const [];
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const [];

    entries.sort((a, b) => a.value.compareTo(b.value));
    final out = <String>[];
    for (final e in entries) {
      final pct = (e.value / total) * 100;
      if (pct < 8) out.add(e.key);
    }
    return out;
  }

  Widget _topWeeklySummary() {
    final scheme = Theme.of(context).colorScheme;
    final week = _summary?.totalWeekVolume ?? _totalVolumeForDays(7);
    final lastWeek = _summary?.totalLastWeekVolume ?? _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
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
                  onUpgrade: _goToPremium,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(deltaIcon, color: deltaColor, size: 26),
                        Text(
                          _pctText(pct),
                          style: TextStyle(fontWeight: FontWeight.w700, color: deltaColor),
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
                Expanded(child: _summaryLine(title: 'Training Days', value: '$sessions / 5')),
                const SizedBox(width: 12),
                Expanded(child: _summaryLine(title: 'Focus', value: focus)),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _topMonthlySummary() {
    final scheme = Theme.of(context).colorScheme;
    final month = _summary?.totalMonthVolume ?? _totalVolumeForDays(30);
    final lastMonth = _summary?.totalLastMonthVolume ?? _totalVolumeForWindow(startDaysAgo: 30, lengthDays: 30);
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
                  onUpgrade: _goToPremium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _summaryLine(
              title: 'Total Volume',
              value: '${month.toStringAsFixed(0)} kg',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(deltaIcon, color: deltaColor, size: 26),
                  Text(
                    _pctText(pct),
                    style: TextStyle(fontWeight: FontWeight.w700, color: deltaColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _summaryLine(title: 'Training Days', value: sessions.toString())),
                const SizedBox(width: 12),
                Expanded(child: _summaryLine(title: 'Focus', value: focus)),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryLine({required String title, required String value, Widget? trailing}) {
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
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _compareBars({required String leftLabel, required double leftValue, required String rightLabel, required double rightValue}) {
    final scheme = Theme.of(context).colorScheme;
    final maxV = [leftValue, rightValue].reduce((a, b) => a > b ? a : b);
    final l = maxV <= 0 ? 0.0 : (leftValue / maxV);
    final r = maxV <= 0 ? 0.0 : (rightValue / maxV);

    Widget bar(String label, double frac, double value, Color color) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.70))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Text('${value.toStringAsFixed(0)} kg', style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final week = _summary?.totalWeekVolume ?? _totalVolumeForDays(7);
    final lastWeek = _summary?.totalLastWeekVolume ?? _totalVolumeForWindow(startDaysAgo: 7, lengthDays: 7);
    final pct = lastWeek > 0 ? ((week - lastWeek) / lastWeek) * 100 : 0.0;
    if (pct < 20) return const SizedBox.shrink();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.health_and_safety_outlined, color: Colors.orange),
        title: const Text('Load safety'),
        subtitle: Text('Load spike ${pct.toStringAsFixed(0)}% — consider a lighter session or a deload soon.'),
      ),
    );
  }

  Widget _aiInsightCard() {
    final insights = _aiInsightsForWeek(premium: _isPremium);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_outlined),
                SizedBox(width: 8),
                Text('AI Insights', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            for (final i in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $i'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _muscleBreakdownList(int days) {
    final scheme = Theme.of(context).colorScheme;
    final map = _muscleVolumeInLastDays(days);
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (entries.isEmpty || total <= 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Log workouts to see muscle load breakdown.'),
        ),
      );
    }

    final avg = total / entries.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Muscle group load', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final e in entries.take(10)) ...[
              Row(
                children: [
                  Expanded(child: Text(e.key)),
                  Text('${((e.value / total) * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (e.value / total).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  valueColor: AlwaysStoppedAnimation(_muscleColor(e.key)),
                ),
              ),
              if (e.value < avg * 0.55) ...[
                const SizedBox(height: 6),
                Text(
                  'Undertrained (subtle) — add 1–2 sets.',
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.60), fontSize: 12),
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
    final stats = _exerciseStats(days: _rangeDays);
    if (stats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No matching exercises yet. Try clearing filters or logging workouts.'),
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
          _OverloadSignal.overload => Colors.green,
          _OverloadSignal.maintain => Colors.amber,
          _OverloadSignal.plateau => Colors.red,
        };

        final trend = s.lastLoadKg > s.avgLoadKg
            ? Icons.trending_up
            : (s.lastLoadKg < s.avgLoadKg ? Icons.trending_down : Icons.trending_flat);

        return Card(
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(s.exerciseName, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.bodyPart}'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text('Last: ${s.lastLoadKg.toStringAsFixed(1)} kg')),
                      Expanded(child: Text('Best: ${s.bestLoadKg.toStringAsFixed(1)} kg')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text('Avg: ${s.avgLoadKg.toStringAsFixed(1)} kg')),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trend, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            switch (trend) {
                              Icons.trending_up => '↑ Improving',
                              Icons.trending_down => '↓ Dropping',
                              _ => '→ Stable',
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.signalReason,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.exerciseName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text('Signal: ${s.signal.name}'),
                        const SizedBox(height: 6),
                        Text('Details: ${s.signalReason}'),
                        const SizedBox(height: 10),
                        Text('Avg load: ${s.avgLoadKg.toStringAsFixed(1)} kg'),
                        Text('Best load: ${s.bestLoadKg.toStringAsFixed(1)} kg'),
                        Text('Last load: ${s.lastLoadKg.toStringAsFixed(1)} kg'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      }).toList(),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bodyPartFilter,
                    items: _bodyParts()
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _bodyPartFilter = v ?? 'All'),
                    decoration: const InputDecoration(labelText: 'Body part'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _rangeDays,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                      DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                      DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                    ],
                    onChanged: (v) => setState(() => _rangeDays = v ?? 30),
                    decoration: const InputDecoration(labelText: 'Range'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // View toggles
                  SegmentedButton<_VolumeView>(
                    segments: const [
                      ButtonSegment(value: _VolumeView.weekly, label: Text('Weekly'), icon: Icon(Icons.calendar_view_week_outlined)),
                      ButtonSegment(value: _VolumeView.monthly, label: Text('Monthly'), icon: Icon(Icons.calendar_month_outlined)),
                      ButtonSegment(value: _VolumeView.byExercise, label: Text('By Exercise'), icon: Icon(Icons.fitness_center_outlined)),
                      ButtonSegment(value: _VolumeView.byMuscleGroup, label: Text('By Muscle'), icon: Icon(Icons.groups_outlined)),
                    ],
                    selected: {_view},
                    onSelectionChanged: (v) {
                      _selectView(v.first);
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_view == _VolumeView.weekly) ...[
                    _topWeeklySummary(),
                    const SizedBox(height: 10),
                    _safetyCardIfNeeded(),
                    const SizedBox(height: 10),
                    PremiumGate(
                      isPremium: _isPremium,
                      title: 'AI Insights',
                      previewText: 'Unlock insights 🔒 (plateaus, deloads, trends).',
                      onUpgrade: _goToPremium,
                      child: _aiInsightCard(),
                    ),
                    const SizedBox(height: 14),
                    Text('Total volume (line)', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.85))),
                    const SizedBox(height: 8),
                    SimpleLineChart(
                      points: weeklyPoints,
                      selectedIndex: _selectedVolumePoint,
                      onSelected: (i) => setState(() => _selectedVolumePoint = i),
                    ),
                    const SizedBox(height: 14),
                    Text('Muscle groups (bar)', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.85))),
                    const SizedBox(height: 8),
                    PremiumGate(
                      isPremium: _isPremium,
                      title: 'Muscle breakdown',
                      previewText: 'Unlock muscle group load + balance view 🔒',
                      onUpgrade: _goToPremium,
                      child: Column(
                        children: [
                          SimpleBarChart(
                            bars: weekMuscleBars,
                            selectedIndex: _selectedMuscleBar,
                            onSelected: (i) => setState(() => _selectedMuscleBar = i),
                          ),
                          const SizedBox(height: 14),
                          _muscleBreakdownList(7),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PremiumGate(
                      isPremium: _isPremium,
                      title: 'Exercise-level tracking',
                      previewText: 'Unlock last/best/avg + overload signals 🔒',
                      onUpgrade: _goToPremium,
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
                    // Monthly is premium (selection is gated), keep a safety fallback.
                    PremiumGate(
                      isPremium: _isPremium,
                      title: 'Monthly analytics',
                      previewText: 'Unlock long-term trends (months) 🔒',
                      onUpgrade: _goToPremium,
                      child: Column(
                        children: [
                          _topMonthlySummary(),
                          const SizedBox(height: 14),
                          Text('Total volume (line)', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.85))),
                          const SizedBox(height: 8),
                          SimpleLineChart(
                            points: monthlyPoints,
                            selectedIndex: _selectedVolumePoint,
                            onSelected: (i) => setState(() => _selectedVolumePoint = i),
                          ),
                          const SizedBox(height: 14),
                          Text('Muscle groups (bar)', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.85))),
                          const SizedBox(height: 8),
                          SimpleBarChart(
                            bars: monthMuscleBars,
                            selectedIndex: _selectedMuscleBar,
                            onSelected: (i) => setState(() => _selectedMuscleBar = i),
                          ),
                          const SizedBox(height: 14),
                          _muscleBreakdownList(30),
                        ],
                      ),
                    ),
                  ],

                  if (_view == _VolumeView.byExercise) ...[
                    const Text('Exercise-level load tracking', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _filtersRow(),
                    const SizedBox(height: 10),
                    _exerciseTracking(),
                  ],

                  if (_view == _VolumeView.byMuscleGroup) ...[
                    const Text('Muscle group load breakdown', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _topWeeklySummary(),
                    const SizedBox(height: 14),
                    SimpleBarChart(
                      bars: weekMuscleBars,
                      selectedIndex: _selectedMuscleBar,
                      onSelected: (i) => setState(() => _selectedMuscleBar = i),
                    ),
                    const SizedBox(height: 14),
                    _muscleBreakdownList(7),
                  ],
                ],
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
            const Text('Compare', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            if (!isPremium) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline, size: 16, color: scheme.onSurface.withValues(alpha: 0.55)),
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
