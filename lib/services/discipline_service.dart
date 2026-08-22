import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/local/models/reminder_model.dart';

final disciplineServiceProvider = Provider<DisciplineService>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return DisciplineService(repo);
});

/// Calculates and evaluates the user's discipline score based on
/// task completion rate, punctuality, and penalty factors.
class DisciplineService {
  final ReminderRepository _repo;

  // ─── Scoring Constants ─────────────────────────────────────────────────────
  static const double _baseCompletionPoints = 10.0;
  static const double _punctualityBonusStrict = 10.0;  // within 15 mins
  static const double _punctualityBonusLoose = 5.0;    // within 60 mins
  static const double _ignorepenalty = 20.0;
  static const double _snoozePenaltyPerSnooze = 2.0;
  static const int _strictPunctualityMinutes = 15;
  static const int _loosePunctualityMinutes = 60;

  // ─── Priority Bonus Map ────────────────────────────────────────────────────
  static const Map<int, double> _priorityBonus = {
    0: 0,   // Low
    1: 5,   // Medium
    2: 10,  // High
    3: 20,  // Emergency
  };

  DisciplineService(this._repo);

  /// Returns a score between 0.0 and 1.0 for the given [date].
  double calculateDailyScore(DateTime date) {
    final tasks = _repo.getHistoryForDate(date);

    // Perfect score if no tasks were scheduled — clean day
    if (tasks.isEmpty) return 1.0;

    double actualPoints = 0;
    double potentialPoints = 0;

    for (final task in tasks) {
      final bonus = _priorityBonus[task.priorityIndex] ?? 0;

      // Potential = base + priority bonus + max punctuality bonus
      final taskPotential = _baseCompletionPoints + bonus + _punctualityBonusStrict;
      potentialPoints += taskPotential;

      if (task.isCompleted) {
        actualPoints += _baseCompletionPoints + bonus;
        actualPoints += _getPunctualityBonus(task);
      }

      // Penalties
      if (task.isIgnored) actualPoints -= _ignorepenalty;
      actualPoints -= task.snoozeCount * _snoozePenaltyPerSnooze;
    }

    if (potentialPoints == 0) return 1.0;
    return (actualPoints / potentialPoints).clamp(0.0, 1.0);
  }

  /// Returns a punctuality bonus based on how quickly the task was completed.
  double _getPunctualityBonus(ReminderModel task) {
    if (task.completedAt == null) return 0;
    final diff = task.completedAt!.difference(task.dateTime).inMinutes.abs();
    if (diff <= _strictPunctualityMinutes) return _punctualityBonusStrict;
    if (diff <= _loosePunctualityMinutes) return _punctualityBonusLoose;
    return 0;
  }

  /// Returns a human-readable label for a given discipline [score].
  String getDisciplineLabel(double score) {
    if (score >= 0.9) return 'Legendary 🔥';
    if (score >= 0.8) return 'Disciplined ⚔️';
    if (score >= 0.6) return 'On Track 📈';
    if (score >= 0.4) return 'Room to Grow 🌱';
    return 'Weak Focus ⚠️';
  }

  /// Returns a motivational message based on the discipline [score].
  String getMotivationalMessage(double score) {
    if (score >= 0.9) return "You're operating at peak level. Keep the streak alive!";
    if (score >= 0.8) return "Strong discipline! One more push and you're legendary.";
    if (score >= 0.6) return "Good progress. Stay consistent and the score will climb.";
    if (score >= 0.4) return "You're building the habit. Don't break the chain!";
    return "Every master was once a disaster. Start fresh — right now.";
  }

  /// Returns a color hex string representing the score zone.
  String getScoreColor(double score) {
    if (score >= 0.9) return '#FF6B35'; // Fiery orange — Legendary
    if (score >= 0.8) return '#8A78F0'; // Purple — Disciplined
    if (score >= 0.6) return '#4FC295'; // Green — On Track
    if (score >= 0.4) return '#FFC53D'; // Amber — Room to Grow
    return '#FF5263';                   // Red — Weak Focus
  }
}
