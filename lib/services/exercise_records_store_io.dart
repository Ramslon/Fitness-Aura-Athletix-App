import 'dart:convert';
import 'dart:isolate';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_aura_athletix/core/models/exercise.dart';

// Legacy (v1) storage key: one big JSON array string.
const String kExerciseRecordsLegacyKey = 'exercise_records_v1';

// v2 (io): store as JSON Lines file.
const String kExerciseRecordsV2FileName = 'exercise_records_v2.jsonl';

Future<File> _recordsFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}${Platform.pathSeparator}$kExerciseRecordsV2FileName');
}

Future<List<ExerciseRecord>> loadExerciseRecordsV2(SharedPreferences prefs) async {
  final file = await _recordsFile();
  if (await file.exists()) {
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <ExerciseRecord>[];
    return await _decodeJsonLines(raw);
  }

  // Migrate from legacy v1 if present.
  final legacy = prefs.getString(kExerciseRecordsLegacyKey);
  if (legacy == null || legacy.isEmpty) {
    // Ensure file exists.
    await file.writeAsString('');
    return <ExerciseRecord>[];
  }

  final records = await _decodeLegacyList(legacy);
  await writeExerciseRecordsV2(prefs, records);
  await prefs.remove(kExerciseRecordsLegacyKey);
  return records;
}

Future<void> writeExerciseRecordsV2(
  SharedPreferences prefs,
  List<ExerciseRecord> records,
) async {
  // Write file atomically-ish: write to temp then rename.
  final file = await _recordsFile();
  final tmp = File('${file.path}.tmp');

  final b = StringBuffer();
  for (final r in records) {
    b.writeln(jsonEncode(r.toMap()));
  }

  await tmp.writeAsString(b.toString());
  if (await file.exists()) {
    await file.delete();
  }
  await tmp.rename(file.path);
}

Future<List<ExerciseRecord>> _decodeLegacyList(String legacy) async {
  return await Isolate.run(() {
    final dynamic parsed = jsonDecode(legacy);
    if (parsed is! List) return <ExerciseRecord>[];
    return parsed
        .map((e) => ExerciseRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  });
}

Future<List<ExerciseRecord>> _decodeJsonLines(String raw) async {
  // Decode off the UI isolate.
  return await Isolate.run(() {
    final lines = raw.split('\n');
    final out = <ExerciseRecord>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final dynamic parsed = jsonDecode(t);
      if (parsed is! Map) continue;
      out.add(ExerciseRecord.fromMap(Map<String, dynamic>.from(parsed as Map)));
    }
    return out;
  });
}
