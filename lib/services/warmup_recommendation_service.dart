import 'package:fitness_aura_athletix/core/models/exercise.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class WarmupSuggestion {
  final String title;
  final String detail;

  const WarmupSuggestion({required this.title, required this.detail});
}

class WarmupRecommendationService {
  static const Map<String, List<WarmupSuggestion>> _baseWarmups = {
    'arms': [
      WarmupSuggestion(title: 'Band Curls + Pressdowns', detail: '2 sets x 15 reps each'),
      WarmupSuggestion(title: 'Wrist + Elbow Mobility', detail: '60–90s controlled circles'),
      WarmupSuggestion(title: 'Light Rope Pushdowns', detail: '1–2 sets x 20 reps'),
      WarmupSuggestion(title: 'Scap Push-Ups', detail: '2 sets x 10 reps'),
    ],
    'back': [
      WarmupSuggestion(title: 'Band Lat Pulldowns', detail: '2 sets x 15 reps'),
      WarmupSuggestion(title: 'Thoracic Extensions', detail: '60–90s on bench/foam roller'),
      WarmupSuggestion(title: 'Dead Hang', detail: '2 rounds x 20–30s'),
      WarmupSuggestion(title: 'Face Pulls', detail: '2 sets x 15 reps'),
    ],
    'chest': [
      WarmupSuggestion(title: 'Band Chest Openers', detail: '2 sets x 15 reps'),
      WarmupSuggestion(title: 'Scap Push-Ups', detail: '2 sets x 10 reps'),
      WarmupSuggestion(title: 'Light Incline DB Press', detail: '1–2 ramp-up sets'),
      WarmupSuggestion(title: 'Band Pull-Aparts', detail: '2 sets x 15 reps'),
    ],
    'core': [
      WarmupSuggestion(title: 'Dead Bug Prep', detail: '2 sets x 8 reps per side'),
      WarmupSuggestion(title: 'Bird Dog Prep', detail: '2 sets x 8 reps per side'),
      WarmupSuggestion(title: 'Breathing Brace Drill', detail: '60s diaphragmatic breaths'),
      WarmupSuggestion(title: 'Pallof Hold', detail: '2 rounds x 20s per side'),
    ],
    'glutes': [
      WarmupSuggestion(title: 'Glute Bridge Activation', detail: '2 sets x 15 reps'),
      WarmupSuggestion(title: 'Banded Lateral Walks', detail: '2 rounds x 12 steps'),
      WarmupSuggestion(title: 'Hip Airplanes', detail: '1–2 sets x 5 reps per side'),
      WarmupSuggestion(title: 'Bodyweight RDL', detail: '2 sets x 10 reps'),
    ],
    'legs': [
      WarmupSuggestion(title: 'Leg Swings', detail: '2 rounds x 10 each direction'),
      WarmupSuggestion(title: 'Bodyweight Squats', detail: '2 sets x 12 reps'),
      WarmupSuggestion(title: 'Walking Lunges', detail: '2 rounds x 10 steps'),
      WarmupSuggestion(title: 'Ankle Mobility Drill', detail: '60s per side'),
    ],
    'shoulders': [
      WarmupSuggestion(title: 'Band External Rotations', detail: '2 sets x 12 reps'),
      WarmupSuggestion(title: 'Face Pulls', detail: '2 sets x 15 reps'),
      WarmupSuggestion(title: 'Scaption Raises', detail: '1–2 sets x 12 reps'),
      WarmupSuggestion(title: 'PVC Pass-Throughs', detail: '2 sets x 10 reps'),
    ],
    'abs': [
      WarmupSuggestion(title: 'Cat-Cow + T-Spine Rotations', detail: '60–90s flow'),
      WarmupSuggestion(title: 'Dead Bug Prep', detail: '2 sets x 8 per side'),
      WarmupSuggestion(title: 'Hip Flexor Stretch', detail: '45s per side'),
      WarmupSuggestion(title: 'Plank Ramp-Up', detail: '2 rounds x 20s'),
    ],
  };

  static Future<List<WarmupSuggestion>> recommendForBodyPart(String bodyPart) async {
    final key = bodyPart.toLowerCase();
    final base = List<WarmupSuggestion>.from(
      _baseWarmups[key] ??
          const [
            WarmupSuggestion(
              title: 'Dynamic Mobility Flow',
              detail: '3–5 minutes total',
            ),
            WarmupSuggestion(
              title: 'Light Ramp-Up Set',
              detail: '2 sets x 12 reps',
            ),
            WarmupSuggestion(
              title: 'Joint Prep',
              detail: '60s controlled circles',
            ),
          ],
    );

    final records = await StorageService().loadExerciseRecords();
    final bpRecords = records.where((r) => r.bodyPart.toLowerCase() == key).toList();

    DailyWorkoutAnalysis? analysis;
    if (bpRecords.isNotEmpty) {
      bpRecords.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      final latestDay = DailyWorkoutAnalysisEngine.dayStart(bpRecords.first.dateRecorded);
      analysis = await DailyWorkoutAnalysisEngine.analyzeForDayAndBodyPart(
        latestDay,
        bodyPart,
      );
    }

    final historyTop = _topExercises(bpRecords);
    final suggestions = <WarmupSuggestion>[];

    final shouldBiasPosterior = historyTop.any(
      (e) => e.contains('deadlift') || e.contains('row') || e.contains('pull'),
    );
    final shouldBiasPressing = historyTop.any(
      (e) => e.contains('press') || e.contains('bench') || e.contains('dip'),
    );

    if (analysis?.fatigue == FatigueSignal.high) {
      suggestions.add(
        const WarmupSuggestion(
          title: 'Extended Dynamic Prep',
          detail: '5–7 minutes, lower intensity today',
        ),
      );
    }

    if (shouldBiasPosterior && key != 'back') {
      suggestions.add(
        const WarmupSuggestion(
          title: 'Hip Hinge Patterning',
          detail: '2 sets x 10 reps with light load',
        ),
      );
    }

    if (shouldBiasPressing && (key == 'chest' || key == 'shoulders' || key == 'arms')) {
      suggestions.add(
        const WarmupSuggestion(
          title: 'Scap + Rotator Cuff Primer',
          detail: '2 sets x 12–15 reps',
        ),
      );
    }

    for (final s in base) {
      if (suggestions.length >= 3) break;
      final duplicate = suggestions.any((x) => x.title == s.title);
      if (!duplicate) suggestions.add(s);
    }

    return suggestions.take(3).toList(growable: false);
  }

  static List<String> _topExercises(List<ExerciseRecord> records) {
    final freq = <String, int>{};
    for (final r in records) {
      final key = r.exerciseName.toLowerCase();
      freq[key] = (freq[key] ?? 0) + 1;
    }
    final items = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return items.take(5).map((e) => e.key).toList(growable: false);
  }
}
