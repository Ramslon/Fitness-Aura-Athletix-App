import 'package:fitness_aura_athletix/presentation/widgets/daily_workout_analysis_card.dart';
import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analysis = DailyWorkoutAnalysis(
    date: DateTime(2025, 4, 12),
    workoutName: 'Core strength',
    bodyPart: 'Core',
    durationMinutes: 42,
    exercisesCompleted: 6,
    totalVolume: 1250,
    caloriesBurned: 180,
    overloadTrend: OverloadTrend.improved,
    volumeChangePercent: 8,
    overloadDetails: ['Volume increased from the previous session.'],
    volumeByMuscleGroup: {'Core': 1250},
    undertrainedWarnings: [],
    fatigue: FatigueSignal.fresh,
    prsAndMilestones: [],
    consistencyStreakDays: 3,
    aiSuggestions: ['Add a controlled anti-rotation movement next session.'],
  );

  testWidgets('compact analysis card fits a constrained mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: DailyWorkoutAnalysisCard(
                analysis: analysis,
                compact: true,
                onViewDetails: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Core strength'), findsOneWidget);
    expect(find.text('DURATION'), findsOneWidget);
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('VOLUME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
