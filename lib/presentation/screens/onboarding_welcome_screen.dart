import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToValuePromise() {
    Navigator.of(context).pushNamed(AppRoutes.onboardingValue);
  }

  void _jumpToAuth() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_controller.value);
                    final dx = (t - 0.5) * 30;
                    final dy = (0.5 - t) * 18;
                    final scale = 0.95 + (t * 0.10);

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: Icon(
                            Icons.accessibility_new_rounded,
                            size: 320,
                            color: scheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.95),
                          scheme.primaryContainer.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.30),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 42,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Fitness Aura Athletix',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your personal gym tracker. Smarter every workout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToValuePromise,
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _jumpToAuth,
                    child: Text(
                      'Already lifting? Jump in',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
