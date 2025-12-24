import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class ArmWorkouts extends StatelessWidget {
	const ArmWorkouts({Key? key}) : super(key: key);

	static final List<_Exercise> _exercises = [
		// Biceps
		_Exercise(
			id: 'dumbbell_bicep_curls',
			title: 'Dumbbell Bicep Curls',
			description: 'Classic dumbbell curls for biceps peak and control.',
			image: 'assets/images/arm_dumbbell_bicep_curls.png',
			setsReps: '3 sets x 8-12 reps',
		),
		_Exercise(
			id: 'hammer_curls',
			title: 'Hammer Curls',
			description: 'Hammer curls emphasize brachialis and forearms.',
			image: 'assets/images/arm_hammer_curls.png',
			setsReps: '3 sets x 8-12 reps',
		),
		_Exercise(
			id: 'concentration_curls',
			title: 'Concentration Curls',
			description: 'Strict unilateral curl for peak contraction.',
			image: 'assets/images/arm_concentration_curls.png',
			setsReps: '3 sets x 8-10 reps',
		),
		_Exercise(
			id: 'barbell_curls',
			title: 'Barbell Curls',
			description: 'Barbell curls for heavy loading and mass.',
			image: 'assets/images/arm_barbell_curls.png',
			setsReps: '4 sets x 6-10 reps',
		),
		_Exercise(
			id: 'preacher_curls',
			title: 'Preacher Curls',
			description: 'Preacher bench isolates the biceps and prevents cheating.',
			image: 'assets/images/arm_preacher_curls.png',
			setsReps: '3 sets x 8-12 reps',
		),

		// Triceps
		_Exercise(
			id: 'overhead_tricep_extension',
			title: 'Overhead Tricep Extension',
			description: 'Overhead extension targets the long head of the triceps.',
			image: 'assets/images/arm_overhead_tricep_extension.png',
			setsReps: '3 sets x 8-12 reps',
		),
		_Exercise(
			id: 'tricep_kickbacks',
			title: 'Tricep Kickbacks',
			description: 'Kickbacks for isolating the lateral head of triceps.',
			image: 'assets/images/arm_tricep_kickbacks.png',
			setsReps: '3 sets x 10-12 reps',
		),
		_Exercise(
			id: 'tricep_dips',
			title: 'Tricep Dips',
			description: 'Bodyweight dips (or weighted) for triceps and chest.',
			image: 'assets/images/arm_tricep_dips.png',
			setsReps: '3 sets x 8-15 reps',
		),
		_Exercise(
			id: 'cross_grip',
			title: 'Cross Grip Tricep Press',
			description: 'Cross-grip pressing emphasizes triceps differently.',
			image: 'assets/images/arm_cross_grip.png',
			setsReps: '3 sets x 6-10 reps',
		),
		_Exercise(
			id: 'skull_crusher',
			title: 'Skull Crushers',
			description: 'Lying triceps extensions (skull crushers) for mass.',
			image: 'assets/images/arm_skull_crusher.png',
			setsReps: '3 sets x 8-12 reps',
		),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Arm Workouts')),
			body: Padding(
				padding: const EdgeInsets.all(12.0),
				child: GridView.builder(
					gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
						crossAxisCount: 2,
						mainAxisSpacing: 12,
						crossAxisSpacing: 12,
						childAspectRatio: 0.82,
					),
					itemCount: _exercises.length,
					itemBuilder: (context, index) {
						final ex = _exercises[index];
						return GestureDetector(
							onTap: () => Navigator.push(
								context,
								MaterialPageRoute(builder: (_) => ArmExerciseDetail(exercise: ex)),
							),
							child: Card(
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
								elevation: 3,
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										Expanded(
											child: ClipRRect(
												borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
												child: Image.asset(
													ex.image,
													fit: BoxFit.cover,
													errorBuilder: (c, e, s) => _imageFallback(ex.title),
												),
											),
										),
										Padding(
											padding: const EdgeInsets.all(8.0),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
													const SizedBox(height: 6),
													Text(ex.setsReps, style: const TextStyle(color: Colors.black54, fontSize: 12)),
												],
											),
										),
									],
								),
							),
						);
					},
				),
			),
		);
	}
}

class _Exercise {
	final String id;
	final String title;
	final String description;
	final String image;
	final String setsReps;

	const _Exercise({required this.id, required this.title, required this.description, required this.image, required this.setsReps});
}

class ArmExerciseDetail extends StatelessWidget {
	final _Exercise exercise;

	const ArmExerciseDetail({Key? key, required this.exercise}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text(exercise.title)),
			body: SingleChildScrollView(
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						SizedBox(
							height: 240,
							child: Image.asset(
								exercise.image,
								fit: BoxFit.cover,
								errorBuilder: (c, e, s) => _imageFallback(exercise.title, large: true),
							),
						),
						Padding(
							padding: const EdgeInsets.all(16.0),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(exercise.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
									const SizedBox(height: 8),
									Text(exercise.setsReps, style: const TextStyle(color: Colors.black54)),
									const SizedBox(height: 12),
									Text(exercise.description, style: const TextStyle(fontSize: 16)),
									const SizedBox(height: 20),
									ElevatedButton.icon(
										onPressed: () async {
											final result = await showDialog<Map<String, dynamic>>(
												context: context,
												builder: (ctx) {
													int duration = 20;
													String notes = exercise.title;
													return StatefulBuilder(builder: (c, setState) {
														return AlertDialog(
															title: Text('Mark "${exercise.title}" done'),
															content: Column(
																mainAxisSize: MainAxisSize.min,
																children: [
																	TextFormField(
																		initialValue: duration.toString(),
																		keyboardType: TextInputType.number,
																		decoration: const InputDecoration(labelText: 'Duration (minutes)'),
																		onChanged: (v) => setState(() => duration = int.tryParse(v) ?? 20),
																	),
																	TextFormField(
																		initialValue: notes,
																		decoration: const InputDecoration(labelText: 'Notes (optional)'),
																		onChanged: (v) => setState(() => notes = v),
																	),
																],
															),
															actions: [
																TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
																ElevatedButton(onPressed: () => Navigator.pop(ctx, {'duration': duration, 'notes': notes}), child: const Text('Save')),
															],
														);
													});
												},
											);

											if (result == null) return;
											final entry = WorkoutEntry(
												id: '${exercise.id}_${DateTime.now().millisecondsSinceEpoch}',
												date: DateTime.now(),
												workoutType: 'arms',
												durationMinutes: (result['duration'] as int),
												notes: (result['notes'] as String?),
											);
											await StorageService().saveEntry(entry);
											ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${exercise.title} marked as done')));
											Navigator.pop(context);
										},
										icon: const Icon(Icons.check),
										label: const Text('Mark as Done'),
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

Widget _imageFallback(String title, {bool large = false}) {
	final initials = _initialsFromTitle(title);
	return Container(
		color: Colors.grey.shade200,
		alignment: Alignment.center,
		child: Container(
			width: large ? 120 : 56,
			height: large ? 120 : 56,
			decoration: BoxDecoration(
				color: Colors.blueGrey.shade100,
				borderRadius: BorderRadius.circular(8),
			),
			alignment: Alignment.center,
			child: Text(initials, style: TextStyle(fontSize: large ? 28 : 16, color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold)),
		),
	);
}

String _initialsFromTitle(String title) {
	final parts = title.split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
	if (parts.isEmpty) return '';
	if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
	return (parts[0][0] + parts[1][0]).toUpperCase();
}

