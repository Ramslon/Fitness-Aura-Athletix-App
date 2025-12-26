import 'dart:async';

import 'package:fitness_aura_athletix/services/storage_service.dart';

/// Lightweight AI analysis shim for workout entries.
///
/// This is intentionally local and rule-based so it is safe offline and
/// easy to replace with a real AI call later (e.g., to an LLM or cloud
/// inference service).
class AiGymWorkoutPlan {
  AiGymWorkoutPlan._();
  static final AiGymWorkoutPlan _instance = AiGymWorkoutPlan._();
  factory AiGymWorkoutPlan() => _instance;

  /// Analyze a list of `WorkoutEntry` and produce a human-readable analysis.
  /// The implementation uses simple heuristics but is extracted so it can
  /// be swapped for a real AI-backed implementation later.
  Future<String> analyze(List<WorkoutEntry> entries) async {
    await Future.delayed(const Duration(milliseconds: 200)); // simulate work
    if (entries.isEmpty) return '';

    final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
    final types = <String, int>{};
    for (final e in entries) types[e.workoutType] = (types[e.workoutType] ?? 0) + 1;

    final buf = StringBuffer();
    buf.writeln('AI Summary:');
    buf.writeln('- Entries: ${entries.length}');
    buf.writeln('- Total time: $totalMinutes minutes');
    buf.writeln('- Focus: ${types.keys.join(', ')}');

    if (totalMinutes < 20) {
      buf.writeln('- Recommendation: Increase duration or add compound exercises.');
    } else if (totalMinutes < 45) {
      buf.writeln('- Recommendation: Good session — track progression and nutrition.');
    } else {
      buf.writeln('- Recommendation: High volume — ensure recovery (sleep & nutrition).');
    }

    if (types.length == 1) buf.writeln('- Note: Consider adding a complementary muscle group.');

    buf.writeln('Quick tip: Log RPE (perceived exertion) to fine-tune intensity next session.');

    return buf.toString();
  }
}
