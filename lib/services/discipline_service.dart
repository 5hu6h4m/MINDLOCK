import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/local/models/reminder_model.dart';

final disciplineServiceProvider = Provider<DisciplineService>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return DisciplineService(repo);
});

class DisciplineService {
  final ReminderRepository _repo;

  DisciplineService(this._repo);

  double calculateDailyScore(DateTime date) {
    final tasks = _repo.getHistoryForDate(date);
    if (tasks.isEmpty) return 1.0; // Perfect score for a clean day

    double actualPoints = 0;
    double potentialPoints = 0;

    for (final task in tasks) {
      // 1. Calculate Potential Points (Base 10 + Priority Bonus)
      double taskPotential = 10;
      switch (task.priorityIndex) {
        case 1: taskPotential += 5; break;  // Medium
        case 2: taskPotential += 10; break; // High
        case 3: taskPotential += 20; break; // Emergency
      }
      // Punctuality potential
      taskPotential += 10;
      
      potentialPoints += taskPotential;

      // 2. Calculate Actual Points
      if (task.isCompleted) {
        actualPoints += 10; // Base completion

        // Priority bonus
        switch (task.priorityIndex) {
          case 1: actualPoints += 5; break;
          case 2: actualPoints += 10; break;
          case 3: actualPoints += 20; break;
        }

        // Punctuality bonus (completed within 15 mins of scheduled time)
        if (task.completedAt != null) {
          final diff = task.completedAt!.difference(task.dateTime).inMinutes.abs();
          if (diff <= 15) {
            actualPoints += 10;
          } else if (diff <= 60) {
            actualPoints += 5; // Partial bonus for being within an hour
          }
        }
      }

      // Penalties
      if (task.isIgnored) {
        actualPoints -= 20;
      }

      actualPoints -= (task.snoozeCount * 2); // Small penalty for snoozing
    }

    if (potentialPoints == 0) return 1.0;
    
    final score = actualPoints / potentialPoints;
    return score.clamp(0.0, 1.0);
  }

  String getDisciplineLabel(double score) {
    if (score >= 0.9) return 'Legendary 🔥';
    if (score >= 0.8) return 'Disciplined ⚔️';
    if (score >= 0.6) return 'On Track 📈';
    if (score >= 0.4) return 'Room to Grow 🌱';
    return 'Weak Focus ⚠️';
  }
}
