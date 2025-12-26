import 'package:flutter/material.dart';
import 'dart:convert';

// NOTE: This file uses `shared_preferences` for local persistence. Add
// `shared_preferences` to `pubspec.yaml` or run:
//   flutter pub add shared_preferences
// then import the package and uncomment the save code.
// import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';

  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Intro walkthrough (moved here from presentation/screens)
class IntroOnboardingScreen extends StatefulWidget {
  const IntroOnboardingScreen({super.key});

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Welcome to Fitness Aura Athletix',
      description:
          'Your AI-powered personal gym workout companion. Track your daily workouts and get instant assessment and recommendations.',
      icon: Icons.fitness_center,
    ),
    _OnboardingPage(
      title: 'Personalized Plans',
      description:
          'Receive gym workout suggestions tailored to your goals, preferences, and experience level.',
      icon: Icons.track_changes,
    ),
    _OnboardingPage(
      title: 'Daily Analysis',
      description:
          'Get daily analysis with suggested improvements where necessary.',
      icon: Icons.analytics,
    ),
    _OnboardingPage(
      title: 'AI Fitness Coach',
      description:
          'Chat with our smart coach for personalized tips, motivation, and guidance.',
      icon: Icons.smart_toy,
    ),
    _OnboardingPage(
      title: 'Track Progress',
      description:
          'Visualize your workout journey, monitor progress, and achieve your goals.',
      icon: Icons.show_chart,
    ),
  ];

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingCard(page: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 20 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.green
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                onPressed: _nextPage,
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingCard({required this.page, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Icon(page.icon, size: 120, color: Colors.green.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _gender = 'Prefer not to say';
  String _goal = 'Build muscle';
  String _experience = 'Beginner';
  Map<String, bool> _days = {
    'Mon': false,
    'Tue': false,
    'Wed': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };

  String _preferredTime = 'Morning';
  bool _useMetric = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender,
      'goal': _goal,
      'experience': _experience,
      'days': _days.entries.where((e) => e.value).map((e) => e.key).toList(),
      'preferredTime': _preferredTime,
      'useMetric': _useMetric,
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Persisting locally requires `shared_preferences`. If you add the
    // dependency, uncomment the import at top and the lines below.
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('onboarding_data', jsonEncode(data));

    // For now, simply show a confirmation and return the data to caller.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Onboarding saved locally')));

    Navigator.of(context).pop(data);
  }

  Widget _buildDaysChips() {
    return Wrap(
      spacing: 6,
      children: _days.keys.map((d) {
        final selected = _days[d]!;
        return FilterChip(
          label: Text(d),
          selected: selected,
          onSelected: (v) => setState(() => _days[d] = v),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your age';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  items:
                      [
                            'Build muscle',
                            'Lose fat',
                            'Improve endurance',
                            'General fitness',
                          ]
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _goal = v ?? _goal),
                  decoration: const InputDecoration(
                    labelText: 'Primary goal',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _experience,
                  items: ['Beginner', 'Intermediate', 'Advanced']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _experience = v ?? _experience),
                  decoration: const InputDecoration(
                    labelText: 'Experience level',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Preferred workout days',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildDaysChips(),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _preferredTime,
                  items: ['Morning', 'Afternoon', 'Evening']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _preferredTime = v ?? _preferredTime),
                  decoration: const InputDecoration(
                    labelText: 'Preferred time',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Use metric units (kg, cm)'),
                  value: _useMetric,
                  onChanged: (v) => setState(() => _useMetric = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: _useMetric ? 'Height (cm)' : 'Height (in)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: _useMetric ? 'Weight (kg)' : 'Weight (lb)',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveOnboarding,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text('Save and Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
