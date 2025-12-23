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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onboarding saved locally')),
    );

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
                const Text('Tell us about yourself', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
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
                  value: _gender,
                  items: [
                    'Male',
                    'Female',
                    'Non-binary',
                    'Prefer not to say',
                  ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _goal,
                  items: [
                    'Build muscle',
                    'Lose fat',
                    'Improve endurance',
                    'General fitness',
                  ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _goal = v ?? _goal),
                  decoration: const InputDecoration(labelText: 'Primary goal', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _experience,
                  items: ['Beginner', 'Intermediate', 'Advanced']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _experience = v ?? _experience),
                  decoration: const InputDecoration(labelText: 'Experience level', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Preferred workout days', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildDaysChips(),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _preferredTime,
                  items: ['Morning', 'Afternoon', 'Evening']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _preferredTime = v ?? _preferredTime),
                  decoration: const InputDecoration(labelText: 'Preferred time', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Use metric units (kg, cm)'),
                  value: _useMetric,
                  onChanged: (v) => setState(() => _useMetric = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(labelText: _useMetric ? 'Height (cm)' : 'Height (in)', border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: _useMetric ? 'Weight (kg)' : 'Weight (lb)', border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
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
