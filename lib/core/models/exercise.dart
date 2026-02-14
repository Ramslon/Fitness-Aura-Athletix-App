import 'dart:math' as math;

/// Represents a single exercise record with detailed tracking information
class ExerciseRecord {
  final String id;
  final String exerciseName;
  final String bodyPart; // Legs, Back, Shoulders, Arms, Chest, Core, Glutes, Abs
  /// Single-weight logging (kg). For bodyweight/no-weight exercises, this is
  /// typically 0.
  ///
  /// When [setWeightsKg] is provided, this field is kept for back-compat and
  /// summaries.
  final double weight; // in kg
  /// Optional per-set weights (kg), used for progressive/pyramid sets.
  ///
  /// If present, [sets] should usually match this list length.
  final List<double>? setWeightsKg;
  /// Optional per-set reps, used when reps vary between sets.
  ///
  /// If present, [sets] should usually match this list length.
  final List<int>? setReps;
  final int sets;
  final int repsPerSet;
  /// Optional time under tension in seconds.
  ///
  /// For non-weight/bodyweight exercises, this can be used as a primary
  /// progress signal. Interpreted as total seconds for the whole exercise
  /// (across all sets) when logged.
  final int? timeUnderTensionSeconds;
  /// Optional tempo notation (e.g., 3-1-1).
  final String? tempo;
  /// Optional difficulty variation note (e.g., incline/decline, added pause).
  final String? difficultyVariation;
  final int restTime; // in seconds
  final String difficulty; // Easy, Moderate, Hard
  final String? notes;
  final DateTime dateRecorded;

  ExerciseRecord({
    required this.id,
    required this.exerciseName,
    required this.bodyPart,
    required this.weight,
    this.setWeightsKg,
    this.setReps,
    required this.sets,
    required this.repsPerSet,
    this.timeUnderTensionSeconds,
    this.tempo,
    this.difficultyVariation,
    required this.restTime,
    required this.difficulty,
    this.notes,
    required this.dateRecorded,
  });

  bool get hasSetWeights => (setWeightsKg != null && setWeightsKg!.isNotEmpty);
  bool get hasSetReps => (setReps != null && setReps!.isNotEmpty);

  bool get isBodyweight => effectiveWeightKg <= 0.0;

  int get totalReps {
    if (!hasSetReps) return sets * repsPerSet;
    var total = 0;
    for (var i = 0; i < sets; i++) {
      total += setReps![i];
    }
    return total;
  }

  /// A unified progress score used for analytics/summaries.
  ///
  /// - Weighted exercises: kg*reps across sets.
  /// - Bodyweight exercises: prefers time under tension (seconds) if provided,
  ///   otherwise uses total reps.
  double get progressScore {
    if (!isBodyweight) return volumeLoadKg;
    final tut = timeUnderTensionSeconds ?? 0;
    if (tut > 0) return tut.toDouble();
    return totalReps.toDouble();
  }

  String get progressScoreLabel {
    if (!isBodyweight) return volumeLoadKg.toStringAsFixed(0);
    final tut = timeUnderTensionSeconds ?? 0;
    if (tut > 0) return '${tut}s';
    return '${totalReps} reps';
  }

  double get effectiveWeightKg {
    if (!hasSetWeights) return weight;
    var maxW = 0.0;
    for (final w in setWeightsKg!) {
      if (w > maxW) maxW = w;
    }
    return maxW;
  }

  double get volumeLoadKg {
    if (!hasSetWeights && !hasSetReps) return weight * sets * repsPerSet;
    
    var total = 0.0;
    for (var i = 0; i < sets; i++) {
      final w = hasSetWeights ? setWeightsKg![i] : weight;
      final r = hasSetReps ? setReps![i] : repsPerSet;
      total += w * r;
    }
    return total;
  }

  String get weightLabel {
    if (hasSetWeights) {
      final minW = setWeightsKg!.reduce(math.min);
      final maxW = setWeightsKg!.reduce(math.max);
      if ((maxW - minW).abs() < 0.01) {
        return '${maxW.toStringAsFixed(1)}kg';
      }
      return '${minW.toStringAsFixed(1)}–${maxW.toStringAsFixed(1)}kg';
    }
    if (weight <= 0.0) return 'Bodyweight';
    return '${weight.toStringAsFixed(1)}kg';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'exerciseName': exerciseName,
    'bodyPart': bodyPart,
    'weight': weight,
    if (hasSetWeights) 'setWeightsKg': setWeightsKg,
    if (hasSetReps) 'setReps': setReps,
    'sets': sets,
    'repsPerSet': repsPerSet,
    if (timeUnderTensionSeconds != null)
      'timeUnderTensionSeconds': timeUnderTensionSeconds,
    if (tempo != null && tempo!.trim().isNotEmpty) 'tempo': tempo,
    if (difficultyVariation != null && difficultyVariation!.trim().isNotEmpty)
      'difficultyVariation': difficultyVariation,
    'restTime': restTime,
    'difficulty': difficulty,
    'notes': notes,
    'dateRecorded': dateRecorded.toIso8601String(),
  };

  factory ExerciseRecord.fromMap(Map<String, dynamic> m) => ExerciseRecord(
    id: m['id'] as String,
    exerciseName: m['exerciseName'] as String,
    bodyPart: m['bodyPart'] as String,
    weight: (m['weight'] as num).toDouble(),
    setWeightsKg: (m['setWeightsKg'] is List)
        ? (m['setWeightsKg'] as List)
            .map((e) => (e as num).toDouble())
            .toList(growable: false)
        : null,
    setReps: (m['setReps'] is List)
        ? (m['setReps'] as List)
            .map((e) => (e as num).toInt())
            .toList(growable: false)
        : null,
    sets: (m['sets'] as num).toInt(),
    repsPerSet: (m['repsPerSet'] as num).toInt(),
    timeUnderTensionSeconds: (m['timeUnderTensionSeconds'] as num?)?.toInt(),
    tempo: m['tempo'] as String?,
    difficultyVariation: m['difficultyVariation'] as String?,
    restTime: (m['restTime'] as num).toInt(),
    difficulty: m['difficulty'] as String,
    notes: m['notes'] as String?,
    dateRecorded: DateTime.parse(m['dateRecorded'] as String),
  );
}
