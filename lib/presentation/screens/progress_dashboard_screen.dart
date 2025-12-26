import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  bool _loading = true;
  List<WorkoutEntry> _entries = [];
  int _totalWorkouts = 0;
  int _totalMinutes = 0;
  int _streak = 0;
  int _thisWeek = 0;
  Map<String, int> _last7DaysCounts = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    final entries = await StorageService().loadEntries();
    final streak = await StorageService().currentStreak();
    final week = await StorageService().workoutsThisWeek();

    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return {'date': d, 'key': key};
    });

    final counts = <String, int>{};
    for (final item in last7) counts[item['key'] as String] = 0;

    for (final e in entries) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }

    setState(() {
      _entries = entries;
      _totalWorkouts = entries.length;
      _totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
      _streak = streak;
      _thisWeek = week;
      _last7DaysCounts = counts.map((k, v) => MapEntry(k, v));
      _loading = false;
    });
  }

  Widget _metricCard(String title, String value, {Color? color}) {
    return Card(
      color: color ?? Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                      Expanded(child: _metricCard('Current Streak', '$_streak days', color: Colors.orange.shade50)),
                      const SizedBox(width: 12),
                      Expanded(child: _metricCard('This Week', '$_thisWeek workouts', color: Colors.blue.shade50)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Last 7 Days', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _exportCsv,
                                icon: const Icon(Icons.share),
                                label: const Text('Export CSV'),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: _buildChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _entries.isEmpty
                        ? const Center(child: Text('No workout history yet.'))
                        : ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, i) {
                              final e = _entries.reversed.toList()[i];
                              return ListTile(
                                leading: const Icon(Icons.fitness_center),
                                title: Text('${e.workoutType} — ${e.durationMinutes} min'),
                                subtitle: Text('${e.date.toLocal().toString().split(' ').first}'),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: _loadMetrics,
                          child: const Text('Refresh'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildLast7Bars() {
    final entries = _last7DaysCounts.entries.toList();
    final maxCount = entries.map((e) => e.value).fold<int>(0, (p, c) => c > p ? c : p);
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7]}';
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
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(height: 8),
            Text(labels[i], style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    });
  }

  Widget _buildChart() {
    final data = <_DayCount>[];
    final now = DateTime.now();
    final ordered = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final count = _last7DaysCounts[key] ?? 0;
      final label = '${['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7]}';
      return _DayCount(label, count);
    });

    data.addAll(ordered);

    final series = [
      charts.Series<_DayCount, String>(
        id: 'workouts',
        domainFn: (d, _) => d.day,
        measureFn: (d, _) => d.count,
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        data: data,
      ),
    ];

    return charts.BarChart(
      series,
      animate: true,
      domainAxis: const charts.OrdinalAxisSpec(renderSpec: charts.SmallTickRendererSpec(labelRotation: 0)),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final rows = <String>['date,count'];
      // Ensure deterministic ordering
      final orderedKeys = _last7DaysCounts.keys.toList()..sort();
      for (final k in orderedKeys) {
        rows.add('$k,${_last7DaysCounts[k]}');
      }
      final csv = rows.join('\n');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/progress_${DateTime.now().toIso8601String()}.csv');
      await file.writeAsString(csv);

      // Use share_plus to share the CSV file
      await Share.shareXFiles([XFile(file.path)], text: 'Progress data (last 7 days)');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

}

class _DayCount {
  final String day;
  final int count;
  _DayCount(this.day, this.count);
}

