import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Frequently asked questions and help content goes here.'),
      ),
    );
  }
}
