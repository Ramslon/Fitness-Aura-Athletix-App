import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/core/models/volume_load.dart';

class VolumeLoadScreen extends StatefulWidget {
  const VolumeLoadScreen({Key? key}) : super(key: key);

  @override
  State<VolumeLoadScreen> createState() => _VolumeLoadScreenState();
}

class _VolumeLoadScreenState extends State<VolumeLoadScreen> {
  bool _loading = true;
  List<VolumeLoadData> _data = [];
  BodyLoadSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await StorageService().getVolumeLoadData();
    final summary = await StorageService().getBodyLoadSummary();
    setState(() {
      _data = data;
      _summary = summary;
      _loading = false;
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

  @override
  Widget build(BuildContext context) {
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
                  if (_summary != null) ...[
                    Row(
                      children: [
                        Expanded(child: _metricTile('Today Vol', '${_summary!.totalTodayVolume.toStringAsFixed(0)} kg', color: Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _metricTile('Yesterday Vol', '${_summary!.totalYesterdayVolume.toStringAsFixed(0)} kg')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _metricTile('This Week', '${_summary!.totalWeekVolume.toStringAsFixed(0)} kg', color: Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _metricTile('Last Week', '${_summary!.totalLastWeekVolume.toStringAsFixed(0)} kg')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _metricTile('This Month', '${_summary!.totalMonthVolume.toStringAsFixed(0)} kg', color: Colors.deepPurple)),
                        const SizedBox(width: 12),
                        Expanded(child: _metricTile('Last Month', '${_summary!.totalLastMonthVolume.toStringAsFixed(0)} kg')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Volume by Muscle', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._summary!.volumeByMuscle.entries.map((e) => ListTile(
                          title: Text(e.key),
                          trailing: Text('${e.value.toStringAsFixed(0)} kg'),
                        )),
                    const SizedBox(height: 18),
                    const Divider(),
                  ],
                  const SizedBox(height: 8),
                  const Text('Exercises', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._data.map((d) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Today: ${d.todayVolume.toStringAsFixed(0)} kg  vs Last: ${d.lastSessionVolume.toStringAsFixed(0)} kg'),
                            const SizedBox(height: 6),
                            Text('Week: ${d.weekVolume.toStringAsFixed(0)} kg  vs LastWeek: ${d.lastWeekVolume.toStringAsFixed(0)} kg'),
                            const SizedBox(height: 6),
                            Text('Month: ${d.monthVolume.toStringAsFixed(0)} kg  vs LastMonth: ${d.lastMonthVolume.toStringAsFixed(0)} kg'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
