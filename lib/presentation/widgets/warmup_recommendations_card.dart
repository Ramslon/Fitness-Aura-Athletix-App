import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/warmup_recommendation_service.dart';

class WarmupRecommendationsCard extends StatelessWidget {
  final String bodyPart;

  const WarmupRecommendationsCard({
    Key? key,
    required this.bodyPart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WarmupSuggestion>>(
      future: WarmupRecommendationService.recommendForBodyPart(bodyPart),
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const <WarmupSuggestion>[];
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Warmups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '$bodyPart-focused warmup suggestions from your history + daily analysis.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                if (loading)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  Column(
                    children: List<Widget>.generate(
                      suggestions.length,
                      (i) {
                        final item = suggestions[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == suggestions.length - 1 ? 0 : 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.local_fire_department, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.title} • ${item.detail}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
