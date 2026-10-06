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
  void didUpdateWidget(covariant LegalDocScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _content = rootBundle.loadString(widget.assetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: scheme.onSurface,
      ),
      h2: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: scheme.onSurface,
      ),
      h3: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: scheme.onSurface,
      ),
      p: textTheme.bodyLarge?.copyWith(
        height: 1.65,
        color: scheme.onSurfaceVariant,
      ),
      listBullet: textTheme.bodyLarge?.copyWith(
        height: 1.65,
        color: scheme.primary,
      ),
      blockSpacing: 18,
      listIndent: 28,
    );

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
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 40, color: scheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load this document.',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again. If the problem continues, contact support.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _content = rootBundle.loadString(widget.assetPath);
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(
                        alpha: scheme.brightness == Brightness.dark
                            ? 0.42
                            : 0.72,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_documentIcon, color: scheme.primary, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A clear guide for your peace of mind',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _documentDescription,
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                      child: MarkdownBody(
                        data: snapshot.data ?? '',
                        selectable: true,
                        styleSheet: markdownStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData get _documentIcon {
    if (widget.title.toLowerCase().contains('privacy')) {
      return Icons.privacy_tip_outlined;
    }
    if (widget.title.toLowerCase().contains('term')) {
      return Icons.description_outlined;
    }
    return Icons.enhanced_encryption_outlined;
  }

  String get _documentDescription {
    if (widget.title.toLowerCase().contains('privacy')) {
      return 'See what information the app may process, where it is stored, '
          'and how optional AI features work.';
    }
    if (widget.title.toLowerCase().contains('term')) {
      return 'Review the fitness disclaimer, your responsibilities, and the '
          'terms for using the app.';
    }
    return 'Understand how information is protected on your device and what '
        'to keep in mind when data is sent or shared.';
  }
}
