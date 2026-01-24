import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/core/models/progressive_overload.dart';
import 'package:fitness_aura_athletix/core/models/muscle_balance.dart';

/// Simple StorageService to persist daily workout entries.
/// Each entry is stored as a JSON object with:
///  - id: unique string
///  - date: ISO8601 date
///  - workoutType: string (e.g., 'arm', 'chest')
///  - durationMinutes: int
///  - notes: optional string
class StorageService {
	static const _kEntriesKey = 'workout_entries_v1';

	StorageService._();
	static final StorageService _instance = StorageService._();
	factory StorageService() => _instance;

	Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

	final FlutterSecureStorage _secure = const FlutterSecureStorage();

	Future<List<Map<String, dynamic>>> _readEntriesRaw() async {
		final prefs = await _prefs;
		final s = prefs.getString(_kEntriesKey);
		if (s == null || s.isEmpty) return [];
		final List<dynamic> list = jsonDecode(s);
		return list.cast<Map<String, dynamic>>();
	}

	Future<void> _writeEntriesRaw(List<Map<String, dynamic>> entries) async {
		final prefs = await _prefs;
		await prefs.setString(_kEntriesKey, jsonEncode(entries));
	}

	Future<List<WorkoutEntry>> loadEntries() async {
		final raw = await _readEntriesRaw();
		return raw.map((m) => WorkoutEntry.fromMap(m)).toList();
	}

	Future<void> saveEntry(WorkoutEntry entry) async {
		final entries = await loadEntries();
		entries.removeWhere((e) => e.id == entry.id);
		entries.add(entry);
		await _writeEntriesRaw(entries.map((e) => e.toMap()).toList());
	}

	Future<void> deleteEntry(String id) async {
		final entries = await loadEntries();
		entries.removeWhere((e) => e.id == id);
		await _writeEntriesRaw(entries.map((e) => e.toMap()).toList());
	}

	/// Returns number of workouts in the last 7 days (including today)
	Future<int> workoutsThisWeek() async {
		final entries = await loadEntries();
		final now = DateTime.now();
		final weekAgo = now.subtract(const Duration(days: 6));
		final count = entries.where((e) => e.date.isAfter(weekAgo) || _isSameDay(e.date, weekAgo)).length;
		return count;
	}

	/// Returns current streak (consecutive days with at least one entry)
	Future<int> currentStreak() async {
		final entries = await loadEntries();
		if (entries.isEmpty) return 0;
		final dates = entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().toList()
			..sort((a, b) => b.compareTo(a));

		int streak = 0;
		DateTime cursor = DateTime.now();
		while (true) {
			final day = DateTime(cursor.year, cursor.month, cursor.day);
			final found = dates.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
			if (found) {
				streak++;
				cursor = cursor.subtract(const Duration(days: 1));
			} else {
				break;
			}
		}
		return streak;
	}

	bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

	/// Persist a short analysis note for the given date (uses ISO yyyy-MM-dd keying).
	Future<void> saveAnalysisNoteForDate(DateTime date, String note) async {
		final prefs = await _prefs;
		final key = _analysisKey;
		final raw = prefs.getString(key);
		final Map<String, dynamic> map = raw == null || raw.isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(raw));
		map[_dateKey(date)] = note;
		await prefs.setString(key, jsonEncode(map));
	}

	/// Load the saved analysis note for a given date, or null if none.
	Future<String?> loadAnalysisNoteForDate(DateTime date) async {
		final prefs = await _prefs;
		final key = _analysisKey;
		final raw = prefs.getString(key);
		if (raw == null || raw.isEmpty) return null;
		final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(raw));
		return map[_dateKey(date)] as String?;
	}

	String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

	static const _analysisKey = 'daily_analysis_notes_v1';

	// Generic settings helpers
	static const _kSettingsPrefix = 'app_setting_';

	Future<void> saveStringSetting(String key, String value) async {
		final prefs = await _prefs;
		await prefs.setString('$_kSettingsPrefix$key', value);
	}

	Future<String?> loadStringSetting(String key) async {
		final prefs = await _prefs;
		return prefs.getString('$_kSettingsPrefix$key');
	}

	Future<void> saveBoolSetting(String key, bool value) async {
		final prefs = await _prefs;
		await prefs.setBool('$_kSettingsPrefix$key', value);
	}

	Future<bool?> loadBoolSetting(String key) async {
		final prefs = await _prefs;
		return prefs.getBool('$_kSettingsPrefix$key');
	}

	// Secure storage helpers (for API keys and secrets). Keys are namespaced with
	// 'secure_' prefix when written to the secure storage provider.

	Future<void> saveSecureString(String key, String value) async {
		await _secure.write(key: 'secure_$key', value: value);
	}

	Future<String?> loadSecureString(String key) async {
		return await _secure.read(key: 'secure_$key');
	}

	Future<void> deleteSecureString(String key) async {
		await _secure.delete(key: 'secure_$key');
	}

	Future<bool> hasSecureString(String key) async {
		final v = await loadSecureString(key);
		return v != null && v.isNotEmpty;
	}

	// Exercise tracking methods
	static const _kExerciseRecordsKey = 'exercise_records_v1';

	Future<List<Map<String, dynamic>>> _readExerciseRecordsRaw() async {
		final prefs = await _prefs;
		final s = prefs.getString(_kExerciseRecordsKey);
		if (s == null || s.isEmpty) return [];
		final List<dynamic> list = jsonDecode(s);
		return list.cast<Map<String, dynamic>>();
	}

	Future<void> _writeExerciseRecordsRaw(List<Map<String, dynamic>> records) async {
		final prefs = await _prefs;
		await prefs.setString(_kExerciseRecordsKey, jsonEncode(records));
	}

	Future<List<ExerciseRecord>> loadExerciseRecords() async {
		final raw = await _readExerciseRecordsRaw();
		return raw.map((m) => ExerciseRecord.fromMap(m)).toList();
	}

	Future<void> saveExerciseRecord(ExerciseRecord record) async {
		final records = await loadExerciseRecords();
		records.removeWhere((e) => e.id == record.id);
		records.add(record);
		await _writeExerciseRecordsRaw(records.map((e) => e.toMap()).toList());
	}

	Future<void> deleteExerciseRecord(String id) async {
		final records = await loadExerciseRecords();
		records.removeWhere((e) => e.id == id);
		await _writeExerciseRecordsRaw(records.map((e) => e.toMap()).toList());
	}

	Future<List<ExerciseRecord>> getExerciseRecordsByBodyPart(String bodyPart) async {
		final records = await loadExerciseRecords();
		return records.where((r) => r.bodyPart == bodyPart).toList()..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
	}

	Future<List<ExerciseRecord>> getExerciseRecordsByDate(DateTime date) async {
		final records = await loadExerciseRecords();
		return records.where((r) {
			final same = r.dateRecorded.year == date.year && r.dateRecorded.month == date.month && r.dateRecorded.day == date.day;
			return same;
		}).toList()..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
	}

	// Progressive Overload Tracking
	Future<List<ProgressiveOverloadMetrics>> getProgressiveOverloadMetrics() async {
		final records = await loadExerciseRecords();
		if (records.isEmpty) return [];

		final metrics = <ProgressiveOverloadMetrics>[];
		final groupedByExercise = <String, List<ExerciseRecord>>{};

		// Group records by exercise name
		for (final record in records) {
			groupedByExercise.putIfAbsent(record.exerciseName, () => []);
			groupedByExercise[record.exerciseName]!.add(record);
		}

		// For each exercise, find the latest and previous records to calculate improvements
		for (final exerciseName in groupedByExercise.keys) {
			final exerciseRecords = groupedByExercise[exerciseName]!
				..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));

			if (exerciseRecords.length >= 2) {
				final latest = exerciseRecords[0];
				final previous = exerciseRecords[1];

				final latestVolume = (latest.weight * latest.sets * latest.repsPerSet).toInt();
				final previousVolume = (previous.weight * previous.sets * previous.repsPerSet).toInt();

				metrics.add(ProgressiveOverloadMetrics(
					exerciseName: exerciseName,
					bodyPart: latest.bodyPart,
					previousWeight: previous.weight,
					currentWeight: latest.weight,
					previousReps: previous.repsPerSet,
					currentReps: latest.repsPerSet,
					previousSets: previous.sets,
					currentSets: latest.sets,
					previousVolume: previousVolume,
					currentVolume: latestVolume,
					lastPerformedDate: latest.dateRecorded,
					previousPerformedDate: previous.dateRecorded,
				));
			}
		}

		return metrics;
	}

	Future<List<MuscleGroupFrequency>> getMuscleGroupFrequency() async {
		final records = await loadExerciseRecords();
		if (records.isEmpty) return [];

		final now = DateTime.now();
		final weekAgo = now.subtract(const Duration(days: 7));
		final monthAgo = now.subtract(const Duration(days: 30));

		final groupedByMuscle = <String, List<ExerciseRecord>>{};

		// Group records by body part
		for (final record in records) {
			groupedByMuscle.putIfAbsent(record.bodyPart, () => []);
			groupedByMuscle[record.bodyPart]!.add(record);
		}

		final frequency = <MuscleGroupFrequency>[];

		for (final muscle in groupedByMuscle.keys) {
			final muscleRecords = groupedByMuscle[muscle]!;
			final weekCount = muscleRecords.where((r) => r.dateRecorded.isAfter(weekAgo)).length;
			final monthCount = muscleRecords.where((r) => r.dateRecorded.isAfter(monthAgo)).length;
			final lastWorkout = muscleRecords.reduce((a, b) => a.dateRecorded.isAfter(b.dateRecorded) ? a : b);

			frequency.add(MuscleGroupFrequency(
				muscleGroup: muscle,
				workoutCountLastWeek: weekCount,
				workoutCountLastMonth: monthCount,
				averageFrequencyPerWeek: monthCount > 0 ? (monthCount / 4.3) : 0,
				lastWorkoutDate: lastWorkout.dateRecorded,
			));
		}

		return frequency..sort((a, b) => b.workoutCountLastWeek.compareTo(a.workoutCountLastWeek));
	}

	// Muscle Balance Analysis
	Future<List<MuscleBalanceAnalysis>> getMuscleBalanceAnalysis() async {
		final records = await loadExerciseRecords();
		if (records.isEmpty) return [];

		final now = DateTime.now();
		final weekAgo = now.subtract(const Duration(days: 7));

		final muscleData = <String, List<ExerciseRecord>>{};

		// Group records by muscle and filter to this week
		for (final record in records) {
			if (record.dateRecorded.isAfter(weekAgo)) {
				muscleData.putIfAbsent(record.bodyPart, () => []);
				muscleData[record.bodyPart]!.add(record);
			}
		}

		// Recommended frequencies based on training science
		const recommendedFrequencies = {
			'Chest': 2,
			'Back': 2,
			'Legs': 2,
			'Shoulders': 2,
			'Arms': 2,
			'Core': 3,
			'Glutes': 2,
			'Abs': 3,
		};

		final analysis = <MuscleBalanceAnalysis>[];
		final totalVolume = muscleData.entries.fold<double>(0, (sum, entry) {
			final volume = entry.value.fold<double>(0, (s, r) => s + (r.weight * r.sets * r.repsPerSet));
			return sum + volume;
		});

		for (final muscle in muscleData.keys) {
			final records = muscleData[muscle]!;
			final frequency = records.length;
			final volume = records.fold<double>(0, (s, r) => s + (r.weight * r.sets * r.repsPerSet));
			final recommendedFreq = recommendedFrequencies[muscle] ?? 2;
			final avgVolume = frequency > 0 ? volume / frequency : 0;

			String? warning;
			bool isUnderTrained = false;
			bool hasImbalance = false;

			// Check if under-trained
			if (frequency < recommendedFreq) {
				isUnderTrained = true;
				warning = '⚠️ $muscle trained $frequency× this week. Recommended: $recommendedFreq–${recommendedFreq + 1}×';
			}

			analysis.add(MuscleBalanceAnalysis(
				muscleGroup: muscle,
				weeklyFrequency: frequency,
				volumeThisWeek: volume,
				averageVolumePerSession: avgVolume,
				warning: warning,
				isUnderTrained: isUnderTrained,
				hasImbalance: false, // Will be calculated in balance check
			));
		}

		return analysis..sort((a, b) => b.weeklyFrequency.compareTo(a.weeklyFrequency));
	}

	Future<List<MuscleTrainingRecommendation>> getMuscleTrainingRecommendations() async {
		final analysis = await getMuscleBalanceAnalysis();
		const recommendedFrequencies = {
			'Chest': 2,
			'Back': 2,
			'Legs': 2,
			'Shoulders': 2,
			'Arms': 2,
			'Core': 3,
			'Glutes': 2,
			'Abs': 3,
		};

		final recommendations = <MuscleTrainingRecommendation>[];
		final totalVolume = analysis.fold<double>(0, (sum, a) => sum + a.volumeThisWeek);
		final avgVolumePerMuscle = totalVolume / (analysis.length > 0 ? analysis.length : 1);

		for (final muscle in analysis) {
			final recommendedFreq = recommendedFrequencies[muscle.muscleGroup] ?? 2;
			final volumeDiff = muscle.volumeThisWeek - (avgVolumePerMuscle);
			final volumeBalance = avgVolumePerMuscle > 0 ? muscle.volumeThisWeek / avgVolumePerMuscle : 1.0;

			String recommendation;
			if (muscle.weeklyFrequency < recommendedFreq) {
				recommendation = 'Add ${recommendedFreq - muscle.weeklyFrequency} more session(s) for ${muscle.muscleGroup}';
			} else if (muscle.weeklyFrequency > recommendedFreq + 1) {
				recommendation = '${muscle.muscleGroup} is being trained frequently; consider deload week';
			} else {
				recommendation = '${muscle.muscleGroup} training frequency is optimal';
			}

			recommendations.add(MuscleTrainingRecommendation(
				muscleGroup: muscle.muscleGroup,
				currentFrequency: muscle.weeklyFrequency,
				recommendedFrequency: recommendedFreq,
				volumeDifference: volumeDiff,
				recommendation: recommendation,
				volumeBalance: volumeBalance,
			));
		}

		return recommendations..sort((a, b) => a.currentFrequency.compareTo(b.currentFrequency));
	}

	Future<List<MuscleImbalanceWarning>> getMuscleImbalanceWarnings() async {
		final analysis = await getMuscleBalanceAnalysis();
		if (analysis.length < 2) return [];

		final warnings = <MuscleImbalanceWarning>[];

		// Define muscle pairs to check for balance
		const balancePairs = [
			('Chest', 'Back'),
			('Shoulders', 'Back'),
			('Legs', 'Back'),
			('Core', 'Glutes'),
		];

		for (final pair in balancePairs) {
			final primary = analysis.firstWhere(
				(m) => m.muscleGroup == pair.$1,
				orElse: () => MuscleBalanceAnalysis(
					muscleGroup: pair.$1,
					weeklyFrequency: 0,
					volumeThisWeek: 0,
					averageVolumePerSession: 0,
					isUnderTrained: false,
					hasImbalance: false,
				),
			);

			final secondary = analysis.firstWhere(
				(m) => m.muscleGroup == pair.$2,
				orElse: () => MuscleBalanceAnalysis(
					muscleGroup: pair.$2,
					weeklyFrequency: 0,
					volumeThisWeek: 0,
					averageVolumePerSession: 0,
					isUnderTrained: false,
					hasImbalance: false,
				),
			);

			final ratio = secondary.volumeThisWeek > 0 ? primary.volumeThisWeek / secondary.volumeThisWeek : 0;

			if (secondary.volumeThisWeek > 0 && ratio > 1.3) {
				final isCritical = ratio > 1.5;
				warnings.add(MuscleImbalanceWarning(
					primaryMuscle: pair.$1,
					secondaryMuscle: pair.$2,
					volumeRatio: ratio,
					warning: '⚠️ ${pair.$1} volume is ${(ratio * 100 - 100).toStringAsFixed(0)}% higher than ${pair.$2} → imbalance risk',
					suggestion: 'Increase ${pair.$2} training volume or decrease ${pair.$1}',
					isCritical: isCritical,
				));
			}
		}

		return warnings;
	}
}

class WorkoutEntry {
	final String id;
	final DateTime date;
	final String workoutType;
	final int durationMinutes;
	final String? notes;

	WorkoutEntry({required this.id, required this.date, required this.workoutType, required this.durationMinutes, this.notes});

	Map<String, dynamic> toMap() => {
				'id': id,
				'date': date.toIso8601String(),
				'workoutType': workoutType,
				'durationMinutes': durationMinutes,
				'notes': notes,
			};

	factory WorkoutEntry.fromMap(Map<String, dynamic> m) => WorkoutEntry(
				id: m['id'] as String,
				date: DateTime.parse(m['date'] as String),
				workoutType: m['workoutType'] as String,
				durationMinutes: (m['durationMinutes'] as num).toInt(),
				notes: m['notes'] as String?,
			);
}

