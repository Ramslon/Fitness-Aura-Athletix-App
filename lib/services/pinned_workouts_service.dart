import 'dart:convert';
import 'storage_service.dart';

class PinnedWorkoutsService {
  static const String _pinnedWorkoutsKey = 'pinned_workouts_v1';
  static const int maxPinnedWorkouts = 3;

  static Future<List<String>> getPinnedWorkouts() async {
    try {
      final jsonStr = await StorageService().loadStringSetting(_pinnedWorkoutsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> pinWorkout(String workoutType) async {
    final current = await getPinnedWorkouts();
    if (current.contains(workoutType)) return;
    if (current.length >= maxPinnedWorkouts) {
      current.removeAt(0); // FIFO
    }
    current.add(workoutType);
    await StorageService().saveStringSetting(_pinnedWorkoutsKey, jsonEncode(current));
  }

  static Future<void> unpinWorkout(String workoutType) async {
    final current = await getPinnedWorkouts();
    current.remove(workoutType);
    await StorageService().saveStringSetting(_pinnedWorkoutsKey, jsonEncode(current));
  }

  static Future<bool> isPinned(String workoutType) async {
    final pinned = await getPinnedWorkouts();
    return pinned.contains(workoutType);
  }
}
