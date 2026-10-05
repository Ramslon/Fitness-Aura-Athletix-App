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
}
