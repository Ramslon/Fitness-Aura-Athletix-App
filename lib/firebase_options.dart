import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// This would be your actual Firebase options file
// You must generate this file from your Firebase project settings
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Replace with your actual Firebase project configuration
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
    );
  }
}
