import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fitness_aura_athletix/presentation/screens/legal_doc_screen.dart';
import 'package:fitness_aura_athletix/presentation/widgets/local_image_placeholder.dart';

enum _HelpLevel { beginner, advanced }

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  static const _supportIssueUrl =
      'https://github.com/Ramslon/Fitness-Aura-Athletix-App/issues/new';
  static const _supportEmail = 'ramsonlonayo@gmail.com';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';
  String _selectedFaqCategory = 'All';
  _HelpLevel _level = _HelpLevel.beginner;

  final List<_AssistantMessage> _assistantMessages = <_AssistantMessage>[
    const _AssistantMessage(
      role: _AssistantRole.assistant,
      text:
          'Hi! Ask me anything about workouts, tracking, offline mode, privacy, or troubleshooting.\n\nTry: “How do I track progress?” or “My images won\'t load”.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = <String>{'All', ..._faqItems.map((e) => e.category)}
        .toList(growable: false);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & FAQ'),
          actions: [
            IconButton(
              tooltip: 'AI help assistant',
              icon: const Icon(Icons.smart_toy_outlined),
              onPressed: _openAssistant,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SearchBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hintText:
                        'Search help (e.g., “offline”, “billing”, “progress”)',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocus.unfocus();
                          },
                        ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
                  tabs: const [
                    Tab(text: 'FAQs'),
                    Tab(text: 'Guides'),
                    Tab(text: 'Troubleshooting'),
                    Tab(text: 'Contact'),
                    Tab(text: 'Safety & Legal'),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAssistant,
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('AI help'),
        ),
        body: TabBarView(
          children: [
            _buildFaqTab(context, categories),
            _buildGuidesTab(context),
            _buildTroubleshootingTab(context),
            _buildContactTab(context),
            _buildSafetyLegalTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTab(BuildContext context, List<String> categories) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filterFaqs();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              ChoiceChip(
                label: Text(c),
                selected: _selectedFaqCategory == c,
                onSelected: (_) => setState(() => _selectedFaqCategory = c),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_HelpLevel>(
            segments: const [
              ButtonSegment<_HelpLevel>(
                value: _HelpLevel.beginner,
                label: Text('Beginner'),
                icon: Icon(Icons.school_outlined),
              ),
              ButtonSegment<_HelpLevel>(
                value: _HelpLevel.advanced,
                label: Text('Advanced'),
                icon: Icon(Icons.auto_graph_outlined),
              ),
            ],
            selected: {_level},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) setState(() => _level = s.first);
            },
          ),
        ),
        const SizedBox(height: 12),
        if (_query.isNotEmpty)
          Text(
            'Showing results for “$_query”',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          _EmptyState(
            title: 'No matches found',
            subtitle:
                'Try a different keyword, switch categories, or ask the AI assistant.',
            actionLabel: 'Ask AI assistant',
            onAction: _openAssistant,
          )
        else
          ...filtered.map((item) => _FaqTile(item: item, level: _level)),
      ],
    );
  }

  Widget _buildGuidesTab(BuildContext context) {
    final guides = _visualGuides;
    final scheme = Theme.of(context).colorScheme;

    final filtered = _query.isEmpty
        ? guides
        : guides
            .where((g) => g.matches(_query))
            .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Visual guides',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap a guide to expand. You can also customize guide images from your device.',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyState(
            title: 'No guides match your search',
            subtitle: 'Try “progress”, “workout”, “photo”, or “offline”.',
            actionLabel: 'Clear search',
            onAction: () => _searchController.clear(),
          )
        else
          ...filtered.map(_GuideTile.new),
      ],
    );
  }

  Widget _buildTroubleshootingTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _query.isEmpty
        ? _troubleshooting
        : _troubleshooting
            .where((t) => t.matches(_query))
            .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Troubleshooting',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Common issues and quick fixes. If you\'re still stuck, use Contact Support.',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyState(
            title: 'No troubleshooting matches',
            subtitle: 'Try “billing”, “slow”, “sync”, or “image”.',
            actionLabel: 'Ask AI assistant',
            onAction: _openAssistant,
          )
        else
          ...items.map(_TroubleTile.new),
      ],
    );
  }

  Widget _buildContactTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Contact support',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'If something is broken or confusing, you can report it with details so we can fix it faster.',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email support',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Email: $_supportEmail',
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _launchEmail(
                        to: _supportEmail,
                        subject: 'Fitness Aura Athletix — Support Request',
                        body: [
                          'What happened:',
                          '',
                          'Steps to reproduce:',
                          '',
                          'Expected result:',
                          '',
                          'Actual result:',
                          '',
                          'Device + OS:',
                          'App version: 1.0.0+1',
                          '',
                          'If possible, include screenshots and any relevant settings.',
                        ].join('\n'),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Compose email'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportEmail),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied.')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy email'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Report an issue',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Best option: open a GitHub issue with steps to reproduce, screenshots, and what you expected vs what happened.',
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _launchUrl(_supportIssueUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open issue page'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportIssueUrl),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied.')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.send_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Share feedback',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'This opens the system share sheet so you can send details to yourself or a support channel.',
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Fitness Aura Athletix — Feedback\n\nWhat happened:\n\nSteps to reproduce:\n\nExpected result:\n\nActual result:\n\nDevice + OS:\nApp version: 1.0.0+1\n',
                        subject: 'Fitness Aura Athletix — Feedback',
                      ),
                    );
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share feedback template'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyLegalTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final docs = const <_LegalDocLink>[
      _LegalDocLink(
        title: 'Privacy Policy',
        assetPath: 'assets/legal/privacy_policy.md',
        icon: Icons.privacy_tip_outlined,
      ),
      _LegalDocLink(
        title: 'Terms of Service',
        assetPath: 'assets/legal/terms.md',
        icon: Icons.description_outlined,
      ),
      _LegalDocLink(
        title: 'Encryption Info',
        assetPath: 'assets/legal/encryption_info.md',
        icon: Icons.enhanced_encryption_outlined,
      ),
    ];

    final filtered = _query.isEmpty
        ? docs
        : docs
            .where((d) => d.title.toLowerCase().contains(_query.toLowerCase()))
            .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Safety & legal information',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'This app provides fitness guidance but does not replace professional medical advice. Train within your limits and stop if you feel pain, dizziness, or unusual discomfort.',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final d in filtered)
                ListTile(
                  leading: Icon(d.icon),
                  title: Text(d.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LegalDocScreen(
                          title: d.title,
                          assetPath: d.assetPath,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_FaqItem> _filterFaqs() {
    final q = _query.toLowerCase();
    return _faqItems.where((item) {
      if (_selectedFaqCategory != 'All' && item.category != _selectedFaqCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.matches(q);
    }).toList(growable: false);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  Future<void> _launchEmail({
    required String to,
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
        if (body != null && body.trim().isNotEmpty) 'body': body,
      },
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  void _openAssistant() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return _AiAssistantSheet(
          level: _level,
          queryHint: _query,
          messages: _assistantMessages,
          onSend: (text) {
            final trimmed = text.trim();
            if (trimmed.isEmpty) return;

            setState(() {
              _assistantMessages.add(
                _AssistantMessage(role: _AssistantRole.user, text: trimmed),
              );
              _assistantMessages.add(
                _AssistantMessage(
                  role: _AssistantRole.assistant,
                  text: _generateAssistantResponse(trimmed, level: _level),
                ),
              );
            });
          },
        );
      },
    );
  }

  String _generateAssistantResponse(String prompt, {required _HelpLevel level}) {
    final q = prompt.toLowerCase();

    final faqMatches = _faqItems
        .map((f) => (f, f.score(q)))
        .where((p) => p.$2 > 0)
        .toList(growable: false)
      ..sort((a, b) => b.$2.compareTo(a.$2));

    final troubleMatches = _troubleshooting
        .map((t) => (t, t.score(q)))
        .where((p) => p.$2 > 0)
        .toList(growable: false)
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (q.contains('privacy') || q.contains('terms') || q.contains('legal')) {
      return 'For safety & legal information, open the “Safety & Legal” tab to read the Privacy Policy, Terms of Service, and Encryption Info.';
    }

    if (q.contains('support') || q.contains('contact') || q.contains('bug')) {
      return 'To contact support, open the “Contact” tab. The fastest route is filing a GitHub issue with steps to reproduce.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Here\'s what I found:');

    if (faqMatches.isNotEmpty) {
      final top = faqMatches.take(2).map((p) => p.$1).toList(growable: false);
      for (final f in top) {
        buffer.writeln();
        buffer.writeln('• ${f.question}');
        buffer.writeln(level == _HelpLevel.beginner ? f.beginner : f.advanced);
      }
    }

    if (troubleMatches.isNotEmpty) {
      final top = troubleMatches.take(1).map((p) => p.$1).toList(growable: false);
      for (final t in top) {
        buffer.writeln();
        buffer.writeln('• Troubleshooting: ${t.title}');
        buffer.writeln(t.quickAnswer);
      }
    }

    if (faqMatches.isEmpty && troubleMatches.isEmpty) {
      return 'I couldn\'t find an exact match. Try asking about one of these:\n\n• Tracking progress\n• Offline mode\n• Exporting / sharing\n• Billing / premium\n• Privacy\n\nOr use the search bar and tell me the screen name you\'re on.';
    }

    buffer.writeln();
    buffer.writeln(
      'If this doesn\'t resolve it, open the “Troubleshooting” tab or “Contact” tab for next steps.',
    );
    return buffer.toString();
  }
}

class _FaqTile extends StatelessWidget {
  final _FaqItem item;
  final _HelpLevel level;

  const _FaqTile({required this.item, required this.level});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          item.category,
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            level == _HelpLevel.beginner ? item.beginner : item.advanced,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in item.tags)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(t),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  final _VisualGuide guide;
  const _GuideTile(this.guide);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          guide.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          guide.subtitle,
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LocalImagePlaceholder(
                id: guide.imageId,
                assetPath: guide.fallbackAssetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final step in guide.steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(step.icon, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.text,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.85),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TroubleTile extends StatelessWidget {
  final _TroubleshootItem item;
  const _TroubleTile(this.item);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          item.symptoms,
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            item.quickAnswer,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.85), height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final s in item.steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.85),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Icon(Icons.search_off_outlined, size: 42, color: scheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75), height: 1.3),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _LegalDocLink {
  final String title;
  final String assetPath;
  final IconData icon;
  const _LegalDocLink({
    required this.title,
    required this.assetPath,
    required this.icon,
  });
}

// -------------------- AI assistant --------------------

enum _AssistantRole { user, assistant }

class _AssistantMessage {
  final _AssistantRole role;
  final String text;
  const _AssistantMessage({required this.role, required this.text});
}

class _AiAssistantSheet extends StatefulWidget {
  final _HelpLevel level;
  final String queryHint;
  final List<_AssistantMessage> messages;
  final void Function(String) onSend;

  const _AiAssistantSheet({
    required this.level,
    required this.queryHint,
    required this.messages,
    required this.onSend,
  });

  @override
  State<_AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<_AiAssistantSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.queryHint.isNotEmpty) {
      _controller.text = widget.queryHint;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI help assistant',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  label: Text(widget.level == _HelpLevel.beginner
                      ? 'Beginner'
                      : 'Advanced'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.messages.length,
                  itemBuilder: (_, i) {
                    final m = widget.messages[i];
                    final isUser = m.role == _AssistantRole.user;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scheme.outlineVariant
                                  .withValues(alpha: isUser ? 0.3 : 0.6),
                            ),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: isUser
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask a question…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    setState(() {});
  }
}

// -------------------- Content models --------------------

class _FaqItem {
  final String category;
  final String question;
  final String beginner;
  final String advanced;
  final List<String> tags;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.beginner,
    required this.advanced,
    this.tags = const [],
  });

  bool matches(String lowerQuery) {
    return question.toLowerCase().contains(lowerQuery) ||
        beginner.toLowerCase().contains(lowerQuery) ||
        advanced.toLowerCase().contains(lowerQuery) ||
        tags.any((t) => t.toLowerCase().contains(lowerQuery));
  }

  int score(String lowerQuery) {
    var s = 0;
    if (question.toLowerCase().contains(lowerQuery)) s += 6;
    if (tags.any((t) => t.toLowerCase().contains(lowerQuery))) s += 4;
    if (beginner.toLowerCase().contains(lowerQuery)) s += 2;
    if (advanced.toLowerCase().contains(lowerQuery)) s += 2;
    return s;
  }
}

class _VisualGuide {
  final String title;
  final String subtitle;
  final String imageId;
  final String? fallbackAssetPath;
  final List<_GuideStep> steps;

  const _VisualGuide({
    required this.title,
    required this.subtitle,
    required this.imageId,
    this.fallbackAssetPath,
    required this.steps,
  });

  bool matches(String q) {
    final lower = q.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        subtitle.toLowerCase().contains(lower) ||
        steps.any((s) => s.text.toLowerCase().contains(lower));
  }
}

class _GuideStep {
  final IconData icon;
  final String text;
  const _GuideStep(this.icon, this.text);
}

class _TroubleshootItem {
  final String title;
  final String symptoms;
  final String quickAnswer;
  final List<String> steps;
  final List<String> keywords;

  const _TroubleshootItem({
    required this.title,
    required this.symptoms,
    required this.quickAnswer,
    required this.steps,
    this.keywords = const [],
  });

  bool matches(String q) {
    final lower = q.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        symptoms.toLowerCase().contains(lower) ||
        quickAnswer.toLowerCase().contains(lower) ||
        steps.any((s) => s.toLowerCase().contains(lower)) ||
        keywords.any((k) => k.toLowerCase().contains(lower));
  }

  int score(String q) {
    final lower = q.toLowerCase();
    var s = 0;
    if (title.toLowerCase().contains(lower)) s += 6;
    if (keywords.any((k) => k.toLowerCase().contains(lower))) s += 4;
    if (quickAnswer.toLowerCase().contains(lower)) s += 2;
    if (steps.any((st) => st.toLowerCase().contains(lower))) s += 1;
    return s;
  }
}

// -------------------- Content --------------------

const List<_FaqItem> _faqItems = [
  _FaqItem(
    category: 'Getting Started',
    question: 'How do I start my first workout?',
    beginner:
        'Open Home → pick a workout category (Arms/Chest/Back/Legs/etc.) → select an exercise → follow the sets/reps guidance and log what you completed.',
    advanced:
        'Use a consistent split (e.g., push/pull/legs) and log each set with weight + reps. Review your weekly volume to ensure progressive overload without overreaching.',
    tags: ['workout', 'home', 'beginner'],
  ),
  _FaqItem(
    category: 'Workouts',
    question: 'How do I customize exercise images?',
    beginner:
        'Some exercise tiles let you tap “Customize” to choose your own photo from your device. This helps you remember form cues or equipment setup.',
    advanced:
        'Use consistent angles (side/front) and label images mentally with cues (brace, hip hinge, bar path). Keep images minimal so they load quickly offline.',
    tags: ['image', 'photo', 'customize', 'file picker'],
  ),
  _FaqItem(
    category: 'Tracking & Insights',
    question: 'How do I track progress over time?',
    beginner:
        'Use the Progress Dashboard / History & Insights screen to review your workouts. Aim to improve a little each week (more reps, more weight, or better form).',
    advanced:
        'Track weekly sets per muscle group and your top sets (heaviest × reps). Use rolling averages to smooth day-to-day noise and confirm long-term trends.',
    tags: ['progress', 'history', 'insights', 'dashboard'],
  ),
  _FaqItem(
    category: 'Premium & Billing',
    question: 'What if premium features are not unlocking?',
    beginner:
        'First, confirm you’re signed in on the same device/account you used to purchase. Then restart the app and try again.',
    advanced:
        'Check your network connection, ensure the billing screen shows your active status, and verify the app isn’t blocked by restrictive connectivity (VPN/firewall).',
    tags: ['billing', 'premium', 'purchase'],
  ),
  _FaqItem(
    category: 'Offline & Accessibility',
    question: 'Can I use the app offline?',
    beginner:
        'Yes for many screens—your data is stored on your device. Some features may require internet (like sharing or fetching remote content).',
    advanced:
        'Offline-first means local persistence; sync/online actions occur when connectivity returns. If something depends on network (billing, share targets), it may fail offline.',
    tags: ['offline', 'accessibility', 'storage'],
  ),
  _FaqItem(
    category: 'Privacy & Security',
    question: 'How is my data protected?',
    beginner:
        'Your data is saved on your device. Keep your phone locked and avoid sharing sensitive screenshots if you don’t want others to see your progress.',
    advanced:
        'Use platform security features (PIN/biometrics). For details, open Safety & Legal → Encryption Info. If you share exports, treat them like personal health data.',
    tags: ['privacy', 'security', 'encryption'],
  ),
];

const List<_VisualGuide> _visualGuides = [
  _VisualGuide(
    title: 'Log a workout session',
    subtitle: 'From selecting a workout to saving your sets.',
    imageId: 'help_guide_log_workout',
    fallbackAssetPath: 'assets/images/chest_flat_bench.png',
    steps: [
      _GuideStep(Icons.home_outlined, 'Go to Home and pick a workout category.'),
      _GuideStep(Icons.fitness_center_outlined, 'Select an exercise and review the cues.'),
      _GuideStep(Icons.edit_outlined, 'Enter your sets/reps/weight as you complete them.'),
      _GuideStep(Icons.save_outlined, 'Save the session so it appears in History/Insights.'),
    ],
  ),
  _VisualGuide(
    title: 'View your progress dashboard',
    subtitle: 'See your trends and training history.',
    imageId: 'help_guide_progress',
    fallbackAssetPath: 'assets/images/back_deadlift.png',
    steps: [
      _GuideStep(Icons.auto_graph_outlined, 'Open Progress Dashboard / History & Insights.'),
      _GuideStep(Icons.calendar_month_outlined, 'Use the calendar to find past sessions.'),
      _GuideStep(Icons.trending_up_outlined, 'Look for steady improvements week to week.'),
    ],
  ),
  _VisualGuide(
    title: 'Customize an exercise photo',
    subtitle: 'Add your own images for quick visual cues.',
    imageId: 'help_guide_custom_photo',
    fallbackAssetPath: 'assets/images/arm_dumbbell_bicep_curls.png',
    steps: [
      _GuideStep(Icons.image_outlined, 'Tap “Customize/Change” on an exercise card image.'),
      _GuideStep(Icons.folder_open_outlined, 'Pick a photo from your device.'),
      _GuideStep(Icons.check_outlined, 'The app will reuse the image next time.'),
    ],
  ),
  _VisualGuide(
    title: 'Export or share results',
    subtitle: 'Share a snapshot of your progress.',
    imageId: 'help_guide_share',
    fallbackAssetPath: 'assets/images/shoulder_arnold_press.png',
    steps: [
      _GuideStep(Icons.picture_as_pdf_outlined, 'Create a report (if available) or take a screenshot.'),
      _GuideStep(Icons.ios_share_outlined, 'Use Share to send it to your target app.'),
      _GuideStep(Icons.lock_outlined, 'Avoid sharing sensitive personal details.'),
    ],
  ),
];

const List<_TroubleshootItem> _troubleshooting = [
  _TroubleshootItem(
    title: 'My progress/history is missing',
    symptoms: 'You can’t see past sessions or graphs look empty.',
    quickAnswer:
        'This usually happens when sessions weren’t saved or storage permissions were restricted. Start by saving a test session and checking if it appears.',
    steps: [
      'Log a small test workout and confirm you tapped Save/Done.',
      'Restart the app and check History & Insights again.',
      'If you recently reinstalled, local-only data may be gone (device storage is cleared on uninstall).',
      'If the problem persists, report an issue with what screen you used and what you expected to happen.',
    ],
    keywords: ['history', 'insights', 'dashboard', 'save'],
  ),
  _TroubleshootItem(
    title: 'Picking an image doesn’t work',
    symptoms: '“Customize” opens but nothing saves, or the image disappears.',
    quickAnswer:
        'Try selecting a smaller JPG/PNG, then re-open the screen. The app stores images locally; if storage access is restricted, saving can fail.',
    steps: [
      'Pick a standard JPG/PNG and avoid very large images.',
      'Try again and verify the image persists after restarting the app.',
      'If using a file provider, try copying the image to local storage first.',
    ],
    keywords: ['image', 'photo', 'customize', 'file picker'],
  ),
  _TroubleshootItem(
    title: 'Premium features aren’t unlocking',
    symptoms: 'You paid but premium screens still look locked.',
    quickAnswer:
        'Confirm you’re on the same account/device used for purchase, check your network, then reopen the Billing screen.',
    steps: [
      'Open Billing and confirm your status.',
      'Restart the app (fully close and reopen).',
      'Make sure internet access is available for purchase verification.',
      'If it still fails, contact support with a screenshot of the Billing screen.',
    ],
    keywords: ['billing', 'premium', 'purchase'],
  ),
  _TroubleshootItem(
    title: 'The app feels slow or stutters',
    symptoms: 'Scrolling is choppy or screens take long to load.',
    quickAnswer:
        'Try closing background apps and restarting. Large images and low storage can also slow things down.',
    steps: [
      'Restart the app.',
      'Free up some device storage and close other heavy apps.',
      'If you customized many high-resolution images, replace them with smaller ones.',
      'If the issue is consistent, report it with your device model + OS version.',
    ],
    keywords: ['slow', 'lag', 'performance'],
  ),
];
