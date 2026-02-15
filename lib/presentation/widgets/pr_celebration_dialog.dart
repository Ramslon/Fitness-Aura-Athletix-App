import 'package:flutter/material.dart';

Future<void> showPrCelebrationDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'PR Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const _PrCelebrationDialog(),
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
  );
}

class _PrCelebrationDialog extends StatefulWidget {
  const _PrCelebrationDialog();

  @override
  State<_PrCelebrationDialog> createState() => _PrCelebrationDialogState();
}

class _PrCelebrationDialogState extends State<_PrCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final glow = 0.45 + (_controller.value * 0.35);
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: glow),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: glow),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events, size: 46),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'New PR 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Huge lift. Keep that momentum going.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Awesome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
