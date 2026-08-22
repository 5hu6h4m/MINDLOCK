import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/models/user_stats_model.dart';
import 'discipline_service.dart';
import '../core/constants/app_constants.dart';

final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, UserStatsModel>((ref) {
  final disciplineService = ref.watch(disciplineServiceProvider);
  return UserStatsNotifier(disciplineService);
});

/// Manages the user's stats: streak, focus points, and discipline score history.
/// Persisted in Hive and updated once per day on app launch.
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

  /// Checks if a day has passed since last update and updates streak accordingly.
  void _checkAndUpdateStreak() {
    final now = DateTime.now();
    final lastUpdate = state.lastUpdateDate ?? now;

    // Already updated today — skip
    if (_isSameDay(now, lastUpdate)) return;

    final diffDays = _daysBetween(lastUpdate, now);

    if (diffDays == 1) {
      // Check if yesterday was a successful discipline day
      final yesterday = now.subtract(const Duration(days: 1));
      final score = _disciplineService.calculateDailyScore(yesterday);

      if (score >= AppConstants.scoreOnTrack) {
        final newStreak = state.currentStreak + 1;
        state = state.copyWith(
          currentStreak: newStreak,
          longestStreak:
              newStreak > state.longestStreak ? newStreak : state.longestStreak,
          lastUpdateDate: now,
        );
      } else {
        // Score too low — streak resets
        state = state.copyWith(currentStreak: 0, lastUpdateDate: now);
      }
    } else if (diffDays > 1) {
      // Gap of more than a day — streak is broken
      state = state.copyWith(currentStreak: 0, lastUpdateDate: now);
    }

    _save();
  }

  /// Adds focus session points to the user's total.
  void addFocusPoints(int points) {
    state = state.copyWith(
      totalFocusPoints: state.totalFocusPoints + points,
    );
    _save();
  }

  /// Increments the total completed missions count.
  void recordMissionComplete() {
    state = state.copyWith(
      totalMissionsCompleted: (state.totalMissionsCompleted ?? 0) + 1,
    );
    _save();
  }

  /// Increments the total failed missions count.
  void recordMissionFailed() {
    state = state.copyWith(
      totalMissionsFailed: (state.totalMissionsFailed ?? 0) + 1,
    );
    _save();
  }

  /// Returns the current discipline score for today.
  double get todayScore =>
      _disciplineService.calculateDailyScore(DateTime.now());

  /// Returns the current streak label.
  String get streakLabel {
    final streak = state.currentStreak;
    if (streak == 0) return 'Start your streak!';
    if (streak == 1) return '1 day streak 🔥';
    return '$streak day streak 🔥';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  void _save() => HiveBoxes.userStats.put('current', state);
}
