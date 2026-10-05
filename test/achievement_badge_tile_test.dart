import 'package:fitness_aura_athletix/core/models/achievement.dart';
import 'package:fitness_aura_athletix/presentation/widgets/achievement_badge_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const definition = AchievementDefinition(
    id: 'streak_7',
    category: AchievementCategory.consistency,
    title: '7-day streak',
    description: 'Train on 7 consecutive days.',
    progressLabel: 'days',
    target: 7,
    icon: Icons.local_fire_department_outlined,
  );

  testWidgets('unearned badge shows themed progress without overflow', (
    tester,
  ) async {
    final progress = AchievementProgress(
      definition: definition,
      current: 4,
      earnedAt: null,
    );
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: Scaffold(
          body: ListView(children: [AchievementBadgeTile(progress: progress)]),
        ),
      ),
    );

    expect(find.text('7-day streak'), findsOneWidget);
    expect(find.text('4 / 7 days'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('earned badge displays earned state and date', (tester) async {
    final progress = AchievementProgress(
      definition: definition,
      current: 7,
      earnedAt: DateTime(2026, 10, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [AchievementBadgeTile(progress: progress)]),
        ),
      ),
    );

    expect(find.text('Earned • 2026-10-01'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
