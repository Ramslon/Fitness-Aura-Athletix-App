import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LegalDocScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalDocScreen({
    required this.title,
    required this.assetPath,
    super.key,
  });

  @override
  State<LegalDocScreen> createState() => _LegalDocScreenState();
}

class _LegalDocScreenState extends State<LegalDocScreen> {
  late Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = rootBundle.loadString(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<String>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not load document.',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Asset: ${widget.assetPath}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            );
          }

          return Markdown(
            data: snapshot.data ?? '',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            selectable: true,
          );
        },
      ),
    );
  }
}
