import 'package:fitness_aura_athletix/services/premium_access_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'debug reset disables Premium and makes the one-time trial available',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_setting_premium': true,
        'app_setting_premium_trial_until_iso': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      });
      final access = PremiumAccessService();

      await access.resetForTesting();

      expect(await access.isPremiumActive(), isFalse);
      expect(await access.hasUsedTrial(), isFalse);
    },
  );

  test('guest sessions cannot use stored Premium access', () async {
    SharedPreferences.setMockInitialValues({
      'is_guest': true,
      'app_setting_premium': true,
    });

    final status = await PremiumAccessService().checkAccess();

    expect(status.block, PremiumAccessBlock.signInRequired);
    expect(status.canUsePremium, isFalse);
    expect(await PremiumAccessService().isPremiumActive(), isFalse);
  });

  test(
    'free trial cannot start unless user is authenticated and online',
    () async {
      SharedPreferences.setMockInitialValues({});
      final access = PremiumAccessService();
      access.setStatusLoaderForTesting(
        () async => const PremiumAccessStatus(
          authenticated: true,
          online: false,
          premiumActive: false,
          block: PremiumAccessBlock.offline,
        ),
      );

      await expectLater(access.startFreeTrial(), throwsA(isA<StateError>()));
      expect(await access.hasUsedTrial(), isFalse);

      access.setStatusLoaderForTesting(
        () async => const PremiumAccessStatus(
          authenticated: false,
          online: false,
          premiumActive: false,
          block: PremiumAccessBlock.signInRequired,
        ),
      );
      await expectLater(access.startFreeTrial(), throwsA(isA<StateError>()));
      expect(await access.hasUsedTrial(), isFalse);
      access.setStatusLoaderForTesting(null);
    },
  );
}
