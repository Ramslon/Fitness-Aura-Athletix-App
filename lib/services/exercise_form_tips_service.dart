class ExerciseFormTipsService {
  static String tipFor({required String exerciseId, required String title}) {
    final id = exerciseId.toLowerCase();

    if (id.contains('bench_press') || id.contains('dumbbell_press')) {
      return 'Set shoulders down and back, keep wrists stacked, and lower with control to a stable touch point.';
    }
    if (id.contains('squat') || id.contains('lunge')) {
      return 'Brace your core, keep pressure through mid-foot, and let knees track in line with toes.';
    }
    if (id.contains('deadlift') || id.contains('row')) {
      return 'Hinge from the hips, keep spine neutral, and drive the floor away before pulling.';
    }
    if (id.contains('curl')) {
      return 'Keep elbows close, avoid swinging, and pause briefly at peak contraction.';
    }
    if (id.contains('tricep') || id.contains('dip') || id.contains('skull')) {
      return 'Lock upper arms in place and move mostly through the elbow for cleaner triceps tension.';
    }
    if (id.contains('raise') || id.contains('press')) {
      return 'Control the eccentric, avoid shrugging, and stop each rep short of momentum.';
    }
    if (id.contains('plank') || id.contains('crunch') || id.contains('core') ||
        id.contains('abs')) {
      return 'Brace as if preparing for a punch and keep your ribcage stacked over the pelvis.';
    }

    return 'Use full control, steady tempo, and stop if form breaks down.';
  }
}
