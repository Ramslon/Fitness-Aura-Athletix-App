import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Your privacy policy content goes here. Explain what data you collect, why, and how you protect it. Be transparent and clear, especially regarding AI data usage, guest mode limitations, and data deletion.',
        ),
      ),
    );
  }
}
