import 'package:fitness_aura_athletix/presentation/screens/help_faq_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders help topics and filters FAQs from search', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpFaqScreen()));

    expect(find.text('Help & FAQ'), findsOneWidget);
    expect(find.text('Find your answer'), findsOneWidget);
    expect(find.text('How do I start my first workout?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'no-such-help-topic');
    await tester.pumpAndSettle();

    expect(find.text('No matches found'), findsOneWidget);
    expect(find.text('How do I start my first workout?'), findsNothing);
  });
}
