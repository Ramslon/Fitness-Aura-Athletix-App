import 'dart:async';

import 'package:fitness_aura_athletix/services/storage_service.dart';

/// Lightweight AI analysis shim for workout entries.
///
/// This is intentionally local and rule-based so it is safe offline and
/// easy to replace with a real AI call later (e.g., to an LLM or cloud
/// inference service).
class AiGymWorkoutPlan {
  AiGymWorkoutPlan._();
  static final AiGymWorkoutPlan _instance = AiGymWorkoutPlan._();
  factory AiGymWorkoutPlan() => _instance;

  /// Analyze a list of `WorkoutEntry` and produce a human-readable analysis.
  /// The implementation uses simple heuristics but is extracted so it can
  /// be swapped for a real AI-backed implementation later.
  Future<String> analyze(List<WorkoutEntry> entries) async {
    await Future.delayed(const Duration(milliseconds: 200)); // simulate work
    if (entries.isEmpty) return '';

    final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
    final types = <String, int>{};
    for (final e in entries) types[e.workoutType] = (types[e.workoutType] ?? 0) + 1;

    final buf = StringBuffer();
    buf.writeln('AI Summary:');
    buf.writeln('- Entries: ${entries.length}');
    import 'dart:async';
    import 'dart:convert';
    import 'dart:io' show HttpHeaders;

    import 'package:http/http.dart' as http;
    import 'package:fitness_aura_athletix/services/storage_service.dart';

    /// AI analysis service. By default uses a lightweight local heuristic,
    /// but if an API key and endpoint are configured it will call a hosted LLM.
    class AiGymWorkoutPlan {
      AiGymWorkoutPlan._();
      static final AiGymWorkoutPlan _instance = AiGymWorkoutPlan._();
      factory AiGymWorkoutPlan() => _instance;

      String? _apiKey;
      String? _endpoint; // full URL to POST the chat/completion request
      String _model = 'gpt-4o-mini';

      /// Configure to use a hosted LLM. Call this from app initialization
      /// or set environment variables before launching the app.
      void configure({String? apiKey, String? endpoint, String? model}) {
        _apiKey = apiKey;
        _endpoint = endpoint;
        if (model != null) _model = model;
      }

      /// Analyze a list of `WorkoutEntry` and produce a human-readable analysis.
      /// If an LLM is configured it will attempt to call that; otherwise falls
      /// back to the local heuristic implementation.
      Future<String> analyze(List<WorkoutEntry> entries) async {
        // If LLM is available, attempt remote analysis.
        if (_apiKey != null && _apiKey!.isNotEmpty && _endpoint != null && _endpoint!.isNotEmpty) {
          try {
            final prompt = _buildPrompt(entries);
            final resp = await _callHostedModel(prompt);
            if (resp != null && resp.isNotEmpty) return resp;
          } catch (_) {
            // ignore and fallback to local analysis
          }
        }

        return _localAnalyze(entries);
      }

      String _buildPrompt(List<WorkoutEntry> entries) {
        final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
        final types = <String, int>{};
        for (final e in entries) types[e.workoutType] = (types[e.workoutType] ?? 0) + 1;

        final sb = StringBuffer();
        sb.writeln('You are a fitness coach. Provide a concise analysis and clear recommendations.');
        sb.writeln('Workout entries:');
        for (final e in entries) {
          sb.writeln('- ${e.workoutType}: ${e.durationMinutes} minutes; notes: ${e.notes ?? 'none'}');
        }
        sb.writeln('Totals: $totalMinutes minutes across ${entries.length} entries.');
        sb.writeln('Return a short human-friendly analysis and 3 bullet recommendations.');
        return sb.toString();
      }

      Future<String?> _callHostedModel(String prompt) async {
        final uri = Uri.parse(_endpoint!);
        final headers = {HttpHeaders.contentTypeHeader: 'application/json', HttpHeaders.authorizationHeader: 'Bearer $_apiKey'};

        final body = jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'You are a helpful fitness coach.'},
            {'role': 'user', 'content': prompt}
          ]
        });

        final r = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 10));
        if (r.statusCode >= 200 && r.statusCode < 300) {
          final Map<String, dynamic> j = jsonDecode(r.body);
          // Try common OpenAI Chat response shape first
          if (j.containsKey('choices')) {
            final choices = j['choices'] as List<dynamic>;
            if (choices.isNotEmpty) {
              final msg = choices[0]['message']?['content'] ?? choices[0]['text'];
              return msg?.toString();
            }
          }

          // Fallback: try 'result' or flat text
          if (j.containsKey('result')) return j['result'].toString();
          return r.body;
        }
        return null;
      }

      String _localAnalyze(List<WorkoutEntry> entries) {
        if (entries.isEmpty) return '';

        final totalMinutes = entries.fold<int>(0, (s, e) => s + e.durationMinutes);
        final types = <String, int>{};
        for (final e in entries) types[e.workoutType] = (types[e.workoutType] ?? 0) + 1;

        final buf = StringBuffer();
        buf.writeln('AI Summary:');
        buf.writeln('- Entries: ${entries.length}');
        buf.writeln('- Total time: $totalMinutes minutes');
        buf.writeln('- Focus: ${types.keys.join(', ')}');

        if (totalMinutes < 20) {
          buf.writeln('- Recommendation: Increase duration or add compound exercises.');
        } else if (totalMinutes < 45) {
          buf.writeln('- Recommendation: Good session — track progression and nutrition.');
        } else {
          buf.writeln('- Recommendation: High volume — ensure recovery (sleep & nutrition).');
        }

        if (types.length == 1) buf.writeln('- Note: Consider adding a complementary muscle group.');

        buf.writeln('Quick tip: Log RPE (perceived exertion) to fine-tune intensity next session.');

        return buf.toString();
      }
    }
