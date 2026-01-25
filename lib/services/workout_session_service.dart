import 'package:fitness_aura_athletix/services/daily_workout_analysis_engine.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutSessionService {
  WorkoutSessionService._();

  static final WorkoutSessionService instance = WorkoutSessionService._();

  static const _kBodyPart = 'active_session_body_part';
  static const _kStartedAt = 'active_session_started_at_ms';

  bool _loaded = false;
  String? _activeBodyPart;
  DateTime? _startedAt;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _activeBodyPart = prefs.getString(_kBodyPart);
    final startedMs = prefs.getInt(_kStartedAt);
    _startedAt = startedMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(startedMs);
    _loaded = true;
  }

  Future<String?> activeBodyPart() async {
    await _load();
    return _activeBodyPart;
  }

  Future<bool> isActiveFor(String bodyPart) async {
    await _load();
    return _activeBodyPart == bodyPart;
  }

  Future<void> start(String bodyPart) async {
    await _load();
    _activeBodyPart = bodyPart;
    _startedAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBodyPart, bodyPart);
    await prefs.setInt(_kStartedAt, _startedAt!.millisecondsSinceEpoch);
  }

  /// Called whenever an exercise is logged. Ensures a session exists.
  Future<void> markExerciseLogged(String bodyPart) async {
    await _load();
    if (_activeBodyPart == null || _activeBodyPart != bodyPart) {
      await start(bodyPart);
      return;
    }

    // Keep the original start time; do not overwrite.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBodyPart, bodyPart);
  }

  Future<void> clear() async {
    await _load();
    _activeBodyPart = null;
    _startedAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBodyPart);
    await prefs.remove(_kStartedAt);
  }

  /// Ends the current session and computes analysis.
  ///
  /// If [expectedBodyPart] is provided, only ends the session if the active
  /// session matches it.
  Future<DailyWorkoutAnalysis?> endAndAnalyze({String? expectedBodyPart}) async {
    await _load();
    final bodyPart = _activeBodyPart;
    if (bodyPart == null) return null;
    if (expectedBodyPart != null && expectedBodyPart != bodyPart) {
      return null;
    }

    final day = DailyWorkoutAnalysisEngine.dayStart(
      (_startedAt ?? DateTime.now()),
    );

    final records = await StorageService().loadExerciseRecords();
    final analysis = DailyWorkoutAnalysisEngine.analyzeFromRecords(
      records,
      day: day,
      bodyPart: bodyPart,
    );

    await clear();
    return analysis;
  }
}
