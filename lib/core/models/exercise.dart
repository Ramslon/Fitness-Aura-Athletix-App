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
  final int sets;
  final int repsPerSet;
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
    required this.sets,
    required this.repsPerSet,
    required this.restTime,
    required this.difficulty,
    this.notes,
    required this.dateRecorded,
  });

  bool get hasSetWeights => (setWeightsKg != null && setWeightsKg!.isNotEmpty);

  double get effectiveWeightKg {
    if (!hasSetWeights) return weight;
    var maxW = 0.0;
    for (final w in setWeightsKg!) {
      if (w > maxW) maxW = w;
    }
    return maxW;
  }

  double get volumeLoadKg {
    if (!hasSetWeights) return weight * sets * repsPerSet;
    var total = 0.0;
    for (final w in setWeightsKg!) {
      total += w * repsPerSet;
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
    'sets': sets,
    'repsPerSet': repsPerSet,
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
    sets: (m['sets'] as num).toInt(),
    repsPerSet: (m['repsPerSet'] as num).toInt(),
    restTime: (m['restTime'] as num).toInt(),
    difficulty: m['difficulty'] as String,
    notes: m['notes'] as String?,
    dateRecorded: DateTime.parse(m['dateRecorded'] as String),
  );
}
