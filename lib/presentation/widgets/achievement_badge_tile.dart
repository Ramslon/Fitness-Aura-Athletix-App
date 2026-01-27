import 'package:flutter/material.dart';

import 'package:fitness_aura_athletix/core/models/achievement.dart';

class AchievementBadgeTile extends StatelessWidget {
  final AchievementProgress progress;

  const AchievementBadgeTile({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEarned = progress.isEarned;

    final iconColor = isEarned ? scheme.primary : scheme.onSurface.withValues(alpha: 0.70);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: Border.all(
                  color: isEarned
                      ? scheme.primary.withValues(alpha: 0.55)
                      : scheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(progress.definition.icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progress.definition.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          progress.definition.category.title,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.definition.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isEarned)
                    Text(
                      progress.progressText,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress.fraction,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          progress.progressText,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
