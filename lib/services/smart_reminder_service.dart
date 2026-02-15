import 'package:fitness_aura_athletix/services/pinned_workouts_service.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart' as data;

class SmartReminder {
  final String message;
  final int? habitualHour;

  const SmartReminder({required this.message, this.habitualHour});
}

class SmartReminderService {
  static const String _customReminderEnabledKey = 'reminder_custom_enabled';
  static const String _customReminderHourKey = 'reminder_custom_hour';

  static Future<SmartReminder?> getReminder() async {
    final enabled = await data.StorageService().loadBoolSetting(
      'notifications_enabled',
    );
    if (enabled == false) return null;

    final customEnabled =
        await data.StorageService().loadBoolSetting(_customReminderEnabledKey);
    final customHourRaw =
        await data.StorageService().loadStringSetting(_customReminderHourKey);
    final customHour = int.tryParse(customHourRaw ?? '');

    final entries = await data.StorageService().loadEntries();
    if (entries.isEmpty) return null;

    final hourCount = <int, int>{};
    for (final e in entries) {
      final h = e.date.hour;
      hourCount[h] = (hourCount[h] ?? 0) + 1;
    }

    int? bestHour;
    if (customEnabled == true && customHour != null) {
      bestHour = customHour.clamp(0, 23);
    } else {
      var bestCount = 0;
      for (final e in hourCount.entries) {
        if (e.value > bestCount) {
          bestCount = e.value;
          bestHour = e.key;
        }
      }
    }

    final pinned = await PinnedWorkoutsService.getPinnedWorkouts();
    final topPinned = pinned.isNotEmpty ? pinned.first : 'your next session';

    if (bestHour == null) {
      return SmartReminder(message: 'Ready for $topPinned?');
    }

    final nowHour = DateTime.now().hour;
    final nearHabit = (nowHour - bestHour).abs() <= 1;
    final lead = customEnabled == true
      ? 'Reminder set for ${_hourLabel(bestHour)}.'
      : nearHabit
        ? 'You usually train at ${_hourLabel(bestHour)}.'
        : 'Your usual training time is ${_hourLabel(bestHour)}.';

    return SmartReminder(
      message: '$lead Ready for $topPinned?',
      habitualHour: bestHour,
    );
  }

  static String _hourLabel(int hour24) {
    final suffix = hour24 >= 12 ? 'pm' : 'am';
    final h = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$h$suffix';
  }
}
