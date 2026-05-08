import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/models/user_stats_model.dart';
import 'discipline_service.dart';

final userStatsProvider = StateNotifierProvider<UserStatsNotifier, UserStatsModel>((ref) {
  final disciplineService = ref.watch(disciplineServiceProvider);
  return UserStatsNotifier(disciplineService);
});

class UserStatsNotifier extends StateNotifier<UserStatsModel> {
  final DisciplineService _disciplineService;

  UserStatsNotifier(this._disciplineService) : super(UserStatsModel()) {
    _init();
  }

  void _init() {
    final box = HiveBoxes.userStats;
    if (box.isEmpty) {
      final initialStats = UserStatsModel(lastUpdateDate: DateTime.now());
      box.put('current', initialStats);
      state = initialStats;
    } else {
      state = box.get('current')!;
    }
    _checkAndUpdateStreak();
  }

  void _checkAndUpdateStreak() {
    final now = DateTime.now();
    final lastUpdate = state.lastUpdateDate ?? now;

    // Is it a new day?
    if (now.year == lastUpdate.year &&
        now.month == lastUpdate.month &&
        now.day == lastUpdate.day) {
      return; // Already updated today
    }

    final diffDays = now.difference(lastUpdate).inDays;

    if (diffDays == 1) {
      // Yesterday was the last update. Check yesterday's score.
      final yesterday = now.subtract(const Duration(days: 1));
      final score = _disciplineService.calculateDailyScore(yesterday);
      
      if (score >= 0.6) {
        // Successful day!
        final newStreak = state.currentStreak + 1;
        state = state.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > state.longestStreak ? newStreak : state.longestStreak,
          lastUpdateDate: now,
        );
      } else {
        // Failed day
        state = state.copyWith(currentStreak: 0, lastUpdateDate: now);
      }
    } else if (diffDays > 1) {
      // Streak broken (gap in days)
      state = state.copyWith(currentStreak: 0, lastUpdateDate: now);
    }

    _save();
  }

  void addFocusPoints(int points) {
    state = state.copyWith(totalFocusPoints: state.totalFocusPoints + points);
    _save();
  }

  void _save() {
    HiveBoxes.userStats.put('current', state);
  }
}
