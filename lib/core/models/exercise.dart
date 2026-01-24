/// Represents a single exercise record with detailed tracking information
class ExerciseRecord {
  final String id;
  final String exerciseName;
  final String bodyPart; // Legs, Back, Shoulders, Arms, Chest, Core, Glutes, Abs
  final double weight; // in kg
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
    required this.sets,
    required this.repsPerSet,
    required this.restTime,
    required this.difficulty,
    this.notes,
    required this.dateRecorded,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'exerciseName': exerciseName,
    'bodyPart': bodyPart,
    'weight': weight,
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
    sets: (m['sets'] as num).toInt(),
    repsPerSet: (m['repsPerSet'] as num).toInt(),
    restTime: (m['restTime'] as num).toInt(),
    difficulty: m['difficulty'] as String,
    notes: m['notes'] as String?,
    dateRecorded: DateTime.parse(m['dateRecorded'] as String),
  );
}
