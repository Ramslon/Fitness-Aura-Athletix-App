import 'dart:convert';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_aura_athletix/core/models/exercise.dart';

// Legacy (v1) storage key: one big JSON array string.
const String kExerciseRecordsLegacyKey = 'exercise_records_v1';

// v2 (web/non-IO): store each record as a JSON object string in a StringList.
const String kExerciseRecordsV2ListKey = 'exercise_records_v2_list';

Future<List<ExerciseRecord>> loadExerciseRecordsV2(SharedPreferences prefs) async {
  // Preferred v2 path.
  final list = prefs.getStringList(kExerciseRecordsV2ListKey);
  if (list != null) {
    if (list.isEmpty) return <ExerciseRecord>[];
    final decoded = await Isolate.run(() {
      final out = <ExerciseRecord>[];
      for (final line in list) {
        if (line.trim().isEmpty) continue;
        final dynamic parsed = jsonDecode(line);
        if (parsed is! Map) continue;
        out.add(ExerciseRecord.fromMap(Map<String, dynamic>.from(parsed as Map)));
      }
      return out;
    });
    return decoded;
  }

  // Migrate from legacy v1 if present.
  final legacy = prefs.getString(kExerciseRecordsLegacyKey);
  if (legacy == null || legacy.isEmpty) {
    // Initialize v2 key so future reads are fast and predictable.
    await prefs.setStringList(kExerciseRecordsV2ListKey, <String>[]);
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
  // Store as per-record JSON strings.
  final encoded = records.map((r) => jsonEncode(r.toMap())).toList(growable: false);
  await prefs.setStringList(kExerciseRecordsV2ListKey, encoded);
}

Future<List<ExerciseRecord>> _decodeLegacyList(String legacy) async {
  // Decode off the UI isolate.
  return await Isolate.run(() {
    final dynamic parsed = jsonDecode(legacy);
    if (parsed is! List) return <ExerciseRecord>[];
    return parsed
        .map((e) => ExerciseRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  });
}
