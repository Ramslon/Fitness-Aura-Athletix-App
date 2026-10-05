import 'dart:io';

import 'package:fitness_aura_athletix/presentation/widgets/exercise_grid_card.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (methodCall) async => Directory.systemTemp.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('exercise cards use distinct, repeatable accent colors', () {
    const exerciseIds = [
      'plank',
      'dead_bug',
      'bird_dog',
      'barbell_squat',
      'glute_bridge',
      'romanian_deadlift',
      'jumping_jacks',
      'sit_ups',
    ];
    final colors = exerciseIds.map(exerciseCardAccent).toSet();

    expect(colors, hasLength(exerciseIds.length));
    for (final id in exerciseIds) {
      expect(exerciseCardAccent(id), exerciseCardAccent(id));
    }
  });

  testWidgets('exercise artwork fits compact workout card image slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 68,
              child: LocalImagePlaceholder(
                id: 'missing-exercise-artwork',
                fallbackLabel: 'core side plank knee crunch',
                fallbackColor: Colors.deepOrange,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('core side plank knee crunch'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.text('core side plank knee crunch'))
          .style
          ?.fontSize,
      16,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.deepOrange,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
