import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

