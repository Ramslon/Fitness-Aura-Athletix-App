import 'package:flutter/material.dart';

enum AchievementCategory {
  consistency,
  strength,
  balance,
  discipline,
}

extension AchievementCategoryX on AchievementCategory {
  String get title {
    switch (this) {
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.strength:
        return 'Strength';
      case AchievementCategory.balance:
        return 'Balance';
      case AchievementCategory.discipline:
        return 'Discipline';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.consistency:
        return Icons.local_fire_department_outlined;
      case AchievementCategory.strength:
        return Icons.fitness_center_outlined;
      case AchievementCategory.balance:
        return Icons.balance_outlined;
      case AchievementCategory.discipline:
        return Icons.check_circle_outline;
    }
  }
}

class AchievementDefinition {
  final String id;
  final AchievementCategory category;
  final String title;
  final String description;
  final String progressLabel;
  final double target;
  final IconData icon;

  const AchievementDefinition({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.target,
    required this.icon,
  });
}

class AchievementProgress {
  final AchievementDefinition definition;
  final double current;
  final DateTime? earnedAt;

  const AchievementProgress({
    required this.definition,
    required this.current,
    required this.earnedAt,
  });

  bool get isEarned => earnedAt != null;

  double get fraction {
    if (definition.target <= 0) return isEarned ? 1 : 0;
    return (current / definition.target).clamp(0, 1);
  }

  String get earnedDateText {
    final d = earnedAt;
    if (d == null) return '';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get progressText {
    if (isEarned) return 'Earned • $earnedDateText';

    final target = definition.target;
    final currentText = _formatForTarget(current, target);
    final targetText = _formatForTarget(target, target);
    return '$currentText / $targetText ${definition.progressLabel}'.trim();
  }

  static String _formatForTarget(double v, double target) {
    // If the target is an integer, treat progress as integer-like.
    if (target % 1 == 0) return v.round().toString();

    // Ratios and decimal targets: show up to 2 decimals, trim trailing zeros.
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.0+$'), '').replaceFirst(RegExp(r'(\.[0-9]*?)0+$'), r'$1');
  }
}
