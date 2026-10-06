import 'package:fitness_aura_athletix/presentation/screens/legal_doc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('presents the privacy policy in a readable document view', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocScreen(
          title: 'Privacy Policy',
          assetPath: 'assets/legal/privacy_policy.md',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('A clear guide for your peace of mind'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(
      find.textContaining('Your workout logs and most settings'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
