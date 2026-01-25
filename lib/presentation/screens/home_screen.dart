import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import 'package:fitness_aura_athletix/routes/app_route.dart';
import 'package:fitness_aura_athletix/core/models/exercise.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  int _thisWeek = 0;
  bool _loading = true;
  double _consistencyPercent = 0;
  String _mostImprovedMuscle = 'N/A';
  String _weakestMuscle = 'N/A';
  int _strengthTrends = 0; // Number of exercises with improvements

  final Map<String, _BodyPartCardStats> _bodyPartStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final streak = await StorageService().currentStreak();
    final week = await StorageService().workoutsThisWeek();
    final muscleFreq = await StorageService().getMuscleGroupFrequency();
    final overload = await StorageService().getProgressiveOverloadMetrics();
    await StorageService().loadEntries();

    // Per-body-part card stats for workout categories.
    final bodyParts = <String>[
      'Arms',
      'Chest',
      'Legs',
      'Back',
      'Shoulders',
      'Core',
      'Glutes',
      'Abs',
    ];

    final now = DateTime.now();
    final startThisWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final startPrevWeek = startThisWeek.subtract(const Duration(days: 7));
    final endPrevWeek = startThisWeek.subtract(const Duration(days: 1));

    final nextStats = <String, _BodyPartCardStats>{};
    final volumesThisWeek = <String, double>{};

    for (final part in bodyParts) {
      final records = await StorageService().getExerciseRecordsByBodyPart(part);
      DateTime? lastTrained;
      if (records.isNotEmpty) lastTrained = records.first.dateRecorded;

      double volumeThisWeek = 0;
      double volumePrevWeek = 0;

      for (final r in records) {
        final d = DateTime(
          r.dateRecorded.year,
          r.dateRecorded.month,
          r.dateRecorded.day,
        );
        final load = r.weight * r.sets * r.repsPerSet;

        final inThisWeek =
            d.isAfter(startThisWeek) || _isSameDay(d, startThisWeek);
        final inPrevWeek =
            (d.isAfter(startPrevWeek) || _isSameDay(d, startPrevWeek)) &&
            (d.isBefore(endPrevWeek) || _isSameDay(d, endPrevWeek));

        if (inThisWeek) volumeThisWeek += load;
        if (inPrevWeek) volumePrevWeek += load;
      }

      volumesThisWeek[part] = volumeThisWeek;
      nextStats[part] = _BodyPartCardStats(
        bodyPart: part,
        lastTrained: lastTrained,
        volumeThisWeek: volumeThisWeek,
        volumePrevWeek: volumePrevWeek,
        recentRecords: records.take(8).toList(),
      );
    }

    final maxVolume = volumesThisWeek.values.isEmpty
        ? 0
        : volumesThisWeek.values.reduce((a, b) => a > b ? a : b);
    final normalized = <String, _BodyPartCardStats>{};
    for (final entry in nextStats.entries) {
      normalized[entry.key] = entry.value.withNormalizedProgress(
        maxVolume <= 0 ? 0 : (entry.value.volumeThisWeek / maxVolume),
      );
    }

    // Calculate consistency: workouts this week / ideal workouts (assume 5 ideal per week)
    double consistency = week > 0 ? (week / 5.0 * 100).clamp(0, 100) : 0;

    // Find most improved muscle (most volume increase)
    String mostImproved = 'N/A';
    if (overload.isNotEmpty) {
      final sorted = overload.where((m) => m.hasVolumeIncrease).toList();
      if (sorted.isNotEmpty) {
        sorted.sort(
          (a, b) =>
              b.volumeIncreasePercentage.compareTo(a.volumeIncreasePercentage),
        );
        mostImproved = sorted[0].bodyPart;
      }
    }

    // Find weakest muscle (least trained this week)
    String weakest = 'N/A';
    if (muscleFreq.isNotEmpty) {
      final sorted = muscleFreq.toList();
      sorted.sort(
        (a, b) => a.workoutCountLastWeek.compareTo(b.workoutCountLastWeek),
      );
      weakest = sorted[0].muscleGroup;
    }

    setState(() {
      _streak = streak;
      _thisWeek = week;
      _consistencyPercent = consistency;
      _mostImprovedMuscle = mostImproved;
      _weakestMuscle = weakest;
      _strengthTrends = overload
          .where((m) => m.hasWeightIncrease || m.hasRepIncrease)
          .length;
      _bodyPartStats
        ..clear()
        ..addAll(normalized);
      _loading = false;
    });
  }

  void _navigateAndRefresh(String route, BuildContext context) {
    Navigator.pushNamed(context, route).then((_) => _loadStats());
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openBodyPartHistorySheet(
    BuildContext context,
    _FeatureCard feature,
    _BodyPartCardStats? stats,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final bodyPart = feature.bodyPart ?? feature.title;
    final records = stats?.recentRecords ?? const <ExerciseRecord>[];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.60),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: feature.color.withValues(alpha: 0.16),
                          border: Border.all(
                            color: feature.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          _iconForBodyPart(bodyPart),
                          color: feature.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$bodyPart history',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last trained: ${_lastTrainedLabel(stats?.lastTrained)}',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (records.isEmpty)
                    Text(
                      'No history yet. Log exercises to see trends here.',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        itemBuilder: (context, index) {
                          final r = records[index];
                          final d = DateTime(
                            r.dateRecorded.year,
                            r.dateRecorded.month,
                            r.dateRecorded.day,
                          );
                          final dateLabel =
                              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          final load = r.weight * r.sets * r.repsPerSet;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              r.exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '$dateLabel • ${r.sets}x${r.repsPerSet} @ ${r.weight.toStringAsFixed(1)}kg',
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.70),
                              ),
                            ),
                            trailing: Text(
                              load.toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _navigateAndRefresh(feature.route, context);
                      },
                      child: const Text('Start Workout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_FeatureCard> features = [
      // Workout categories
      _FeatureCard(
        title: 'Arm Workouts',
        description:
            'Targeted arm routines — biceps, triceps and forearms with sets & reps.',
        icon: Icons.fitness_center,
        color: Colors.indigo.shade400,
        route: AppRoutes.armWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Arms',
      ),
      _FeatureCard(
        title: 'Chest Workouts',
        description:
            'Bench press, push-ups and chest isolation moves for strength & hypertrophy.',
        icon: Icons.favorite,
        color: Colors.red.shade400,
        route: AppRoutes.chestWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Chest',
      ),
      _FeatureCard(
        title: 'Leg Workouts',
        description:
            'Squats, lunges and plyometrics for lower-body power and endurance.',
        icon: Icons.directions_run,
        color: Colors.teal.shade400,
        route: AppRoutes.legWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Legs',
      ),
      _FeatureCard(
        title: 'Back Workouts',
        description:
            'Pulls, rows and posterior chain work to build a strong back.',
        icon: Icons.back_hand,
        color: Colors.blueGrey.shade700,
        route: AppRoutes.backWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Back',
      ),
      _FeatureCard(
        title: 'Shoulder Workouts',
        description:
            'Presses, raises and mobility drills for stronger shoulders and posture.',
        icon: Icons.self_improvement,
        color: Colors.orange.shade400,
        route: AppRoutes.shoulderWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Shoulders',
      ),
      _FeatureCard(
        title: 'Core Workouts',
        description:
            'Planks, crunches and rotational exercises for core strength and stability.',
        icon: Icons.hub,
        color: Colors.deepOrange.shade400,
        route: AppRoutes.coreWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Core',
      ),
      _FeatureCard(
        title: 'Glutes Workouts',
        description:
            'Hip thrusts, squats and kickbacks for a stronger posterior chain.',
        icon: Icons.accessibility_new,
        color: Colors.pink.shade400,
        route: AppRoutes.glutesWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Glutes',
      ),
      _FeatureCard(
        title: 'Abs Workouts',
        description:
            'Crunches, leg raises and core isolation moves for defined abs.',
        icon: Icons.exposure_plus_1,
        color: Colors.amber.shade500,
        route: AppRoutes.absWorkouts,
        kind: _FeatureKind.bodyPart,
        bodyPart: 'Abs',
      ),

      // Analysis & premium
      _FeatureCard(
        title: 'Daily Workout Analysis',
        description:
            'AI-driven analysis comparing performance to recommendations with improvement tips.',
        icon: Icons.analytics,
        color: Colors.green.shade400,
        route: AppRoutes.dailyWorkoutAnalysis,
      ),
      _FeatureCard(
        title: 'Goal-Based Tracking',
        description:
            'Set a goal (e.g., bench 100kg) and get tailored suggestions.',
        icon: Icons.flag,
        color: Colors.lightGreen.shade400,
        route: AppRoutes.goalTracking,
      ),
      _FeatureCard(
        title: 'PRs & Achievements',
        description:
            'Personal records, consistency badges, and overload streaks.',
        icon: Icons.emoji_events,
        color: Colors.orange.shade400,
        route: AppRoutes.achievements,
      ),
      _FeatureCard(
        title: 'Volume & Load',
        description:
            'Automatic volume calculations and comparisons (Today/Week/Month).',
        icon: Icons.scale,
        color: Colors.cyan.shade400,
        route: AppRoutes.volumeLoad,
      ),
      _FeatureCard(
        title: 'Premium Features',
        description:
            'Unlock advanced coaching, personalized plans and wearable integrations.',
        icon: Icons.workspace_premium,
        color: const Color.fromARGB(255, 137, 151, 235),
        route: AppRoutes.premiumFeatures,
      ),

      // Community & progress
      _FeatureCard(
        title: 'History & Insights',
        description:
            'Calendar view, movement history, and exports to visualize your progress.',
        icon: Icons.show_chart,
        color: Colors.purple.shade400,
        route: AppRoutes.progressDashboard,
      ),
      _FeatureCard(
        title: 'Community Feed',
        description:
            'Share updates, join challenges and get motivated with the community.',
        icon: Icons.groups,
        color: Colors.blueGrey.shade400,
        route: AppRoutes.socialCommunity,
      ),

      // Support & settings
      _FeatureCard(
        title: 'Help & FAQ',
        description:
            'Get answers, how-tos and troubleshooting for the app features.',
        icon: Icons.help_outline,
        color: Colors.grey.shade600,
        route: AppRoutes.helpFaq,
      ),
      _FeatureCard(
        title: 'Privacy & Security',
        description: 'Biometrics, AI data consent, export & deletion.',
        icon: Icons.lock_outline,
        color: Colors.grey.shade600,
        route: AppRoutes.privacySettings,
      ),
    ];

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fitness Aura Athletix',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _WelcomeHeader(),
          const SizedBox(height: 12),
          // Quick summary cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Streak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : '$_streak days',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Consistency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading
                              ? '...'
                              : '${_consistencyPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Strength Trends',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : '$_strengthTrends improving',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Week',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : '$_thisWeek workouts',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Most Improved',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : _mostImprovedMuscle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Focus Area',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : _weakestMuscle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Slightly taller cards to avoid vertical overflow on small devices
              childAspectRatio: 0.82,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              final bodyPart = feature.bodyPart;
              final stats = bodyPart == null ? null : _bodyPartStats[bodyPart];
              return _FeatureCardWidget(
                feature: feature,
                bodyPartStats: stats,
                onTap: () => _navigateAndRefresh(feature.route, context),
                onLongPress: bodyPart == null
                    ? null
                    : () => _openBodyPartHistorySheet(context, feature, stats),
              );
            },
          ),
        ],
      ),
      drawer: const _AppDrawer(),
    );
  }
}

class _WelcomeTitle extends StatelessWidget {
  const _WelcomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    // Pull a friendly name; falls back to generic greeting.
    final name = (AuthService().currentDisplayName ?? '').trim();
    final text = name.isNotEmpty ? 'Welcome back, $name 👋' : 'Welcome Back 👋';
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Expanded(child: _WelcomeTitle()),
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            child: Icon(Icons.person, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

// 🟢 FEATURE CARD
class _FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final _FeatureKind kind;
  final String? bodyPart;

  _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    this.kind = _FeatureKind.utility,
    this.bodyPart,
  });
}

enum _FeatureKind { bodyPart, utility }

class _BodyPartCardStats {
  final String bodyPart;
  final DateTime? lastTrained;
  final double volumeThisWeek;
  final double volumePrevWeek;
  final double normalizedProgress; // 0..1 compared to max among body parts
  final List<ExerciseRecord> recentRecords;

  const _BodyPartCardStats({
    required this.bodyPart,
    required this.lastTrained,
    required this.volumeThisWeek,
    required this.volumePrevWeek,
    required this.recentRecords,
    this.normalizedProgress = 0,
  });

  _BodyPartCardStats withNormalizedProgress(double p) => _BodyPartCardStats(
    bodyPart: bodyPart,
    lastTrained: lastTrained,
    volumeThisWeek: volumeThisWeek,
    volumePrevWeek: volumePrevWeek,
    recentRecords: recentRecords,
    normalizedProgress: p.clamp(0, 1),
  );
}

class _FeatureCardWidget extends StatelessWidget {
  final _FeatureCard feature;
  final _BodyPartCardStats? bodyPartStats;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FeatureCardWidget({
    required this.feature,
    required this.bodyPartStats,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.cardColor;
    final scheme = theme.colorScheme;

    final baseDecoration = BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: feature.color.withValues(alpha: 0.45)),
      boxShadow: [
        BoxShadow(
          color: feature.color.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );

    Widget content;
    if (feature.kind == _FeatureKind.bodyPart) {
      content = _BodyPartWorkoutCard(
        title: feature.bodyPart ?? feature.title,
        accent: feature.color,
        stats: bodyPartStats,
        onPrimaryAction: onTap,
      );
    } else {
      content = _SimpleFeatureCardContent(feature: feature);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          decoration: baseDecoration,
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }
}

class _SimpleFeatureCardContent extends StatelessWidget {
  final _FeatureCard feature;

  const _SimpleFeatureCardContent({required this.feature});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(feature.icon, color: feature.color, size: 36),
        const SizedBox(height: 8),
        Text(
          feature.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            feature.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.72),
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyPartWorkoutCard extends StatelessWidget {
  final String title;
  final Color accent;
  final _BodyPartCardStats? stats;
  final VoidCallback onPrimaryAction;

  const _BodyPartWorkoutCard({
    required this.title,
    required this.accent,
    required this.stats,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icon = _iconForBodyPart(title);
    final progress = stats?.normalizedProgress ?? 0;
    final pct = (progress * 100).round();

    final lastTrainedText = _lastTrainedLabel(stats?.lastTrained);
    final trend = _trendFromVolumes(
      stats?.volumeThisWeek ?? 0,
      stats?.volumePrevWeek ?? 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section — Identity
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withValues(alpha: 0.16),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _statusLabel(stats?.lastTrained),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Middle Section — Progress Feedback
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last trained',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastTrainedText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            _TrendPill(trend: trend, accent: accent),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 14),

        // Bottom Section — Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPrimaryAction,
            child: const Text('Start Workout'),
          ),
        ),
      ],
    );
  }
}

class _TrendPill extends StatelessWidget {
  final _Trend trend;
  final Color accent;

  const _TrendPill({required this.trend, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (trend) {
      _Trend.up => (Icons.trending_up, 'Up', const Color(0xFF2EE59D)),
      _Trend.down => (Icons.trending_down, 'Down', const Color(0xFFFF5C5C)),
      _Trend.flat => (Icons.trending_flat, 'Flat', scheme.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.90)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: color.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Trend { up, down, flat }

_Trend _trendFromVolumes(double current, double previous) {
  if (previous <= 0 && current > 0) return _Trend.up;
  if (previous <= 0 && current <= 0) return _Trend.flat;
  final ratio = current / previous;
  if (ratio >= 1.05) return _Trend.up;
  if (ratio <= 0.95) return _Trend.down;
  return _Trend.flat;
}

IconData _iconForBodyPart(String bodyPart) {
  switch (bodyPart) {
    case 'Arms':
      return Icons.fitness_center;
    case 'Chest':
      return Icons.favorite;
    case 'Legs':
      return Icons.directions_run;
    case 'Back':
      return Icons.back_hand;
    case 'Shoulders':
      return Icons.self_improvement;
    case 'Core':
      return Icons.hub;
    case 'Glutes':
      return Icons.accessibility_new;
    case 'Abs':
      return Icons.grid_3x3;
    default:
      return Icons.fitness_center;
  }
}

String _statusLabel(DateTime? lastTrained) {
  if (lastTrained == null) return 'New';
  final days = DateTime.now()
      .difference(
        DateTime(lastTrained.year, lastTrained.month, lastTrained.day),
      )
      .inDays;
  if (days <= 2) return 'On track';
  if (days <= 6) return 'Due soon';
  return 'Needs focus';
}

String _lastTrainedLabel(DateTime? lastTrained) {
  if (lastTrained == null) return 'Not yet';
  final days = DateTime.now()
      .difference(
        DateTime(lastTrained.year, lastTrained.month, lastTrained.day),
      )
      .inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return '1 day ago';
  return '$days days ago';
}

// 🟢 NAVIGATION DRAWER
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Text(
              'Fitness Aura Athletix Menu',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Fitness Aura Athletix',
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                    'An AI-powered fitness recommendation system built with Flutter.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
