enum GoalType { strengthTarget, growMuscle, fixWeakness }

class Goal {
  final String id;
  final GoalType type;
  final String title;
  final String? exerciseName;
  final double? targetWeightKg;
  final String? focusMuscleGroup;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.type,
    required this.title,
    this.exerciseName,
    this.targetWeightKg,
    this.focusMuscleGroup,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'exerciseName': exerciseName,
    'targetWeightKg': targetWeightKg,
    'focusMuscleGroup': focusMuscleGroup,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
    id: m['id'] as String,
    type: GoalType.values.firstWhere(
      (t) => t.name == (m['type'] as String),
      orElse: () => GoalType.strengthTarget,
    ),
    title: m['title'] as String,
    exerciseName: m['exerciseName'] as String?,
    targetWeightKg: (m['targetWeightKg'] as num?)?.toDouble(),
    focusMuscleGroup: m['focusMuscleGroup'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}
