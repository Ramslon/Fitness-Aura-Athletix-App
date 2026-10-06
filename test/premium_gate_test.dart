import 'package:fitness_aura_athletix/presentation/widgets/premium_gate.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_feature_offer_card.dart';
import 'package:fitness_aura_athletix/services/premium_access_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    PremiumAccessService().setStatusLoaderForTesting(null);
  });

  testWidgets('locked feature shows its contextual Premium offer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PremiumAccessService().setStatusLoaderForTesting(
      () async => const PremiumAccessStatus(
        authenticated: true,
        online: true,
        premiumActive: false,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            isPremium: false,
            title: 'Advanced goal planning',
            previewText: 'Unlock goal forecasts and training focus.',
            child: Text('Advanced goal content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Advanced goal planning'), findsOneWidget);
    expect(
      find.text('Unlock goal forecasts and training focus.'),
      findsOneWidget,
    );
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('WHAT YOU’LL UNLOCK'), findsOneWidget);
    expect(find.text('KES 50 monthly  ·  KES 100 annual'), findsOneWidget);
    expect(find.text('Advanced goal content'), findsNothing);
    expect(find.text('Start Premium'), findsOneWidget);

    await tester.tap(find.text('Start Premium'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a plan'), findsOneWidget);
    expect(find.text('7-day free trial'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual · best value'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('online locked feature opens plans instead of a verify warning', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var accessChecks = 0;
    PremiumAccessService().setStatusLoaderForTesting(() async {
      accessChecks++;
      return const PremiumAccessStatus(
        authenticated: true,
        online: true,
        premiumActive: false,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            isPremium: false,
            title: 'Premium comparison',
            previewText: 'Compare recent training blocks.',
            child: Text('Comparison insights'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(accessChecks, 1);

    await tester.tap(find.text('Premium comparison'));
    await tester.pumpAndSettle();

    expect(accessChecks, 1);
    expect(find.text('Choose a plan'), findsOneWidget);
    expect(
      find.text(
        'We could not verify Premium access right now. Please try again.',
      ),
      findsNothing,
    );
  });

  testWidgets('Premium offer scrolls instead of overflowing when constrained', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    PremiumAccessService().setStatusLoaderForTesting(
      () async => const PremiumAccessStatus(
        authenticated: true,
        online: true,
        premiumActive: false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 328,
              height: 494,
              child: PremiumGate(
                isPremium: false,
                title: 'Advanced community insights',
                previewText:
                    'A longer description that uses several lines in a narrow card.',
                benefits: List.generate(
                  7,
                  (index) =>
                      'Benefit ${index + 1}: a detailed explanation that wraps to multiple lines in this constrained layout.',
                ),
                child: const Text('Community insight content'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final offerScroll = find.descendant(
      of: find.byType(PremiumFeatureOfferCard),
      matching: find.byType(SingleChildScrollView),
    );
    expect(offerScroll, findsOneWidget);
    await tester.ensureVisible(find.text('Start Premium'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('active Premium gate expands feature content when tapped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_setting_premium': true});
    PremiumAccessService().setStatusLoaderForTesting(
      () async => const PremiumAccessStatus(
        authenticated: true,
        online: true,
        premiumActive: true,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            isPremium: true,
            title: 'Advanced goal planning',
            previewText: 'Unlock goal forecasts and training focus.',
            child: Text('Advanced goal content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Advanced goal content'), findsNothing);
    expect(find.byType(PremiumFeatureOfferCard), findsOneWidget);

    await tester.tap(find.text('Advanced goal planning'));
    await tester.pumpAndSettle();

    expect(find.text('Advanced goal content'), findsOneWidget);
  });

  testWidgets('verified Premium reveal does not request access a second time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var accessChecks = 0;
    PremiumAccessService().setStatusLoaderForTesting(() async {
      accessChecks++;
      return const PremiumAccessStatus(
        authenticated: true,
        online: true,
        premiumActive: true,
      );
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            isPremium: true,
            title: 'Advanced history insights',
            previewText: 'Explore training trends from saved history.',
            child: Text('History insight content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(accessChecks, 1);
    await tester.tap(find.text('Advanced history insights'));
    await tester.pumpAndSettle();

    expect(accessChecks, 1);
    expect(find.text('History insight content'), findsOneWidget);
    expect(
      find.text(
        'We could not verify Premium access right now. Please try again.',
      ),
      findsNothing,
    );
  });

  testWidgets('guest cannot open Premium plans or features', (tester) async {
    SharedPreferences.setMockInitialValues({'is_guest': true});
    PremiumAccessService().setStatusLoaderForTesting(
      () async => const PremiumAccessStatus(
        authenticated: false,
        online: false,
        premiumActive: false,
        block: PremiumAccessBlock.signInRequired,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumGate(
            isPremium: true,
            title: 'Advanced goal planning',
            previewText: 'Unlock goal forecasts and training focus.',
            child: Text('Advanced goal content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Advanced goal content'), findsNothing);
    expect(find.text('Start Premium'), findsNothing);
    expect(find.text('Sign in to unlock'), findsOneWidget);

    await tester.tap(find.text('Sign in to unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a plan'), findsNothing);
    expect(
      find.text('Sign in to an account to use Premium features.'),
      findsNWidgets(2),
    );
  });

  testWidgets(
    'offline account stays locked and gets a friendly retry message',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_setting_premium': true});
      PremiumAccessService().setStatusLoaderForTesting(
        () async => const PremiumAccessStatus(
          authenticated: true,
          online: false,
          premiumActive: false,
          block: PremiumAccessBlock.offline,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumGate(
              isPremium: true,
              title: 'Advanced goal planning',
              previewText: 'Unlock goal forecasts and training focus.',
              child: Text('Advanced goal content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced goal content'), findsNothing);
      expect(find.text('ACCESS ACTIVE'), findsNothing);
      expect(find.text('Check connection'), findsOneWidget);

      await tester.tap(find.text('Check connection'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a plan'), findsNothing);
      expect(
        find.textContaining('Connect to the internet to verify Premium access'),
        findsNWidgets(2),
      );
      expect(find.textContaining('http'), findsNothing);
    },
  );
}
