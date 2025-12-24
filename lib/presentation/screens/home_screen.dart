import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/auth_service.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';
import '../../../routes/app_route.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  int _thisWeek = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final streak = await StorageService().currentStreak();
    final week = await StorageService().workoutsThisWeek();
    setState(() {
      _streak = streak;
      _thisWeek = week;
      _loading = false;
    });
  }

  void _navigateAndRefresh(String route, BuildContext context) {
    Navigator.pushNamed(context, route).then((_) => _loadStats());
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
      ),
      _FeatureCard(
        title: 'Chest Workouts',
        description:
            'Bench press, push-ups and chest isolation moves for strength & hypertrophy.',
        icon: Icons.favorite,
        color: Colors.red.shade400,
        route: AppRoutes.chestWorkouts,
      ),
      _FeatureCard(
        title: 'Leg Workouts',
        description:
            'Squats, lunges and plyometrics for lower-body power and endurance.',
        icon: Icons.directions_run,
        color: Colors.teal.shade400,
        route: AppRoutes.legWorkouts,
      ),
      _FeatureCard(
        title: 'Back Workouts',
        description:
            'Pulls, rows and posterior chain work to build a strong back.',
        icon: Icons.back_hand,
        color: Colors.blueGrey.shade700,
        route: AppRoutes.backWorkouts,
      ),
      _FeatureCard(
        title: 'Shoulder Workouts',
        description:
            'Presses, raises and mobility drills for stronger shoulders and posture.',
        icon: Icons.self_improvement,
        color: Colors.orange.shade400,
        route: AppRoutes.shoulderWorkouts,
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
        title: 'Premium Features',
        description:
            'Unlock advanced coaching, personalized plans and wearable integrations.',
        icon: Icons.workspace_premium,
        color: const Color.fromARGB(255, 137, 151, 235),
        route: AppRoutes.premiumFeatures,
      ),

      // Community & progress
      _FeatureCard(
        title: 'Progress Dashboard',
        description:
            'Charts and history to visualize your strength and consistency over time.',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fitness Aura Athletix',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade200,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _WelcomeHeader(),
            const SizedBox(height: 12),
            // Quick summary cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Streak',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(_loading ? '...' : '$_streak days', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This week',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(_loading ? '...' : '$_thisWeek workouts', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                //Slightly taller cards to avoid vertical overflow on small devices
                childAspectRatio: 0.82,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return GestureDetector(
                  onTap: () => _navigateAndRefresh(feature.route, context),
                  child: _FeatureCardWidget(feature: feature),
                );
              },
            ),
          ],
        ),
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
      style: const TextStyle(color: Colors.white, fontSize: 20),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: const [
          Expanded(child: _WelcomeTitle()),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
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

  _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _FeatureCardWidget extends StatelessWidget {
  final _FeatureCard feature;

  const _FeatureCardWidget({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: feature.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(feature.icon, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            feature.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
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
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 NAVIGATION DRAWER
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              'Fitness Aura Athletix Menu',
              style: TextStyle(color: Colors.white, fontSize: 20),
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
