import 'package:flutter/material.dart';
import '../../lib/services/auth_service.dart';
import '../../routes/app_route.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_Featurecard> features = [
      _FeatureCard(
        title: 'Premium Wellness',
        description:
            'AI wellness report,fitness coaching, and wearable insights.',
        icon: Icons.workspace_premium,
        color: const Color.fromARGB(255, 137, 151, 235),
        route: AppRoutes.premiumFeatures,
      ),
      _FeatureCard(
        title: 'Arm Workouts',
        description: 'Check your arm workouts,train and save your for tracking progress to keep it fit.',
        icon: Icons.volunteer_activism,
        color: Colors.brown.shade400,
        route: AppRoutes.armWorkouts,
      ),
      _FeatureCard(
        title: 'Chest Workouts',
        description: 'Check your chest workouts,train and save your progress for tracking to keep it fit.',
        icon: Icons.volunteer_activism,
        color: Colors.brown.shade400,
        route: AppRoutes.chestWorkouts,
      ),
      _FeatureCard(
        title: 'Shoulder Workouts',
        description: 'Check your leg workouts,train and save your progress for tracking to keep it fit.',
        icon: Icons.volunteer_activism,
        color: Colors.brown.shade400,
        route: AppRoutes.shoulderWorkouts,
      ),
      _FeatureCard(
        title: 'Leg Workouts',
        description: 'Check your leg workouts,train and save your progress for tracking to keep it fit.',
        icon: Icons.volunteer_activism,
        color: Colors.brown.shade400,
        route: AppRoutes.legWorkouts,
      ),
      _FeatureCard(
        title: 'Back Workouts',
        description: 'Check your back workouts,train and save your progress for tracking to keep it fit.',
        icon: Icons.volunteer_activism,
        color: Colors.brown.shade400,
        route: AppRoutes.backWorkouts,
      ),
      // Core features
      _FeatureCard(
        title: 'Daily Workout Analysis',
        description:
            'See daily performances vs. recommendation and get AI insights to improve your daily workouts.',
        icon: Icons.bar_chart,
        color: Colors.green.shade400,
        route: AppRoutes.dailyWorkoutAnalysis,
      ),
      _FeatureCard(
        title: '',
        description: '.',
        icon: Icons.restaurant_menu,
        color: Colors.orange.shade400,
        route: AppRoutes.,
      ),
      _FeatureCard(
        title: 'Fitness Coach',
        description:
            'Chat with your personal fitness trainee assistant for guidance.',
        icon: Icons.chat_bubble_outline,
        color: Colors.blue.shade400,
        route: AppRoutes.,
      ),
      _FeatureCard(
        title: 'Community',
        description: 'Snap and Share progess of your body fitness and flex ,tips, join challenges, and stay motivated.',
        icon: Icons.groups_2_outlined,
        color: Colors.blueGrey.shade400,
        route: AppRoutes.socialCommunity,
      ),
      _FeatureCard(
        title: 'Progress Tracker',
        description: 'Visualize your workouts and fitness journey over time.',
        icon: Icons.show_chart,
        color: Colors.purple.shade400,
        route: AppRoutes.progressDashboard,
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
        title: const Text('Fitness Aura Athletix'
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
                  onTap: () => Navigator.pushNamed(context, feature.route),
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
  @override
  Widget build(BuildContext context) {
    // Pull a friendly name; falls back to generic greeting.
    final name = AuthService().currentDisplayName;
    final text = name != null && name.isNotEmpty
        ? 'Welcome back, $name 👋'
        : 'Welcome Back 👋';
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white, fontSize: 20),
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
              'Commontable AI Menu',
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
                applicationName: 'Commontable AI',
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                    'An AI-powered nutrition recommendation system built with Flutter.',
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













            
          
        
      
    
  

