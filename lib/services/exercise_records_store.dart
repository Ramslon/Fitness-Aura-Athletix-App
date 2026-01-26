// Conditional export for exercise records persistence.
//
// - On IO platforms (Android/iOS/Desktop): store as JSONL file in app documents.
// - On non-IO platforms (web): store as SharedPreferences StringList.
//
// This avoids importing dart:io on web builds.

import 'exercise_records_store_stub.dart'
    if (dart.library.io) 'exercise_records_store_io.dart';

export 'exercise_records_store_stub.dart'
    if (dart.library.io) 'exercise_records_store_io.dart';
