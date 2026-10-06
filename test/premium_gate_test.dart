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
