import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/hive_boxes.dart';
import '../data/local/models/mission_model.dart';
import '../data/local/models/user_stats_model.dart';
import '../core/theme/app_theme.dart';
import '../data/local/models/suggestion_model.dart';
import '../data/repositories/reminder_repository.dart';

final aiSuggestionServiceProvider = Provider<AISuggestionService>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  return AISuggestionService(reminderRepo);
});

class AISuggestionService {
  final ReminderRepository _reminderRepo;
  final _random = Random();

  AISuggestionService(this._reminderRepo);

  final List<String> _baseAdvice = [
    "Focus is a muscle. The more you use it, the stronger it gets.",
    "Don't wait for motivation. Discipline is showing up anyway.",
    "Break your big tasks into 15-minute missions.",
    "Your phone is a tool, not a master. Lock it in.",
  ];

  String getSmartAdvice() {
    final stats = HiveBoxes.userStats.get('main');
    final missions = HiveBoxes.missions.values.toList();
    
    if (stats == null) return _baseAdvice[0];

    // Failure check
    if (stats.missionsFailed > stats.missionsCompleted && stats.missionsFailed > 0) {
      return "Failing is part of the process. Try a 'Light' intensity mission next time to rebuild your streak.";
    }

    // Streak check
    if (stats.currentStreak > 3) {
      return "You're on a ${stats.currentStreak} day streak! You're becoming a Discipline Master.";
    }

    // Time-based
    final hour = DateTime.now().hour;
    if (hour < 9) return "Early bird! Start with a 15-min focus session to set the tone for today.";
    if (hour > 22) return "Late night? Don't forget to set your Sleep Timer to protect your rest.";

    // Mission density
    final recentMissions = missions.where((m) => m.startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).length;
    if (recentMissions > 5) return "You've crushed $recentMissions sessions today. Take a 10-min break to recharge.";

    return _baseAdvice[DateTime.now().second % _baseAdvice.length];
  }

  SuggestionModel getContextualSuggestion() {
    final hour = DateTime.now().hour;
    final completionRate = _reminderRepo.completionRate;
    final pendingCount = _reminderRepo.getToday().length;

    // 1. Time-based Logic
    if (hour >= 5 && hour < 9) {
      return SuggestionModel(
        title: 'Morning Clarity',
        body: 'Start your day by planning your most important tasks. A clear mind leads to a productive day.',
        icon: Icons.wb_sunny_rounded,
        color: AppTheme.accentAmber,
        action: SuggestionAction.createReminder,
        actionLabel: 'Plan Day',
      );
    }

    if (hour >= 21 || hour < 4) {
      return SuggestionModel(
        title: 'Digital Detox',
        body: 'It\'s late. High blue light exposure affects sleep. Consider setting a sleep timer now.',
        icon: Icons.bedtime_rounded,
        color: AppTheme.accentBlue,
        action: SuggestionAction.openSleepTimer,
        actionLabel: 'Set Timer',
      );
    }

    // 2. Activity-based Logic
    if (pendingCount > 5) {
      return SuggestionModel(
        title: 'Overwhelmed?',
        body: 'You have $pendingCount tasks today. Try breaking them into 15-minute micro-tasks.',
        icon: Icons.account_tree_rounded,
        color: AppTheme.primaryPurple,
        action: SuggestionAction.createReminder,
        actionLabel: 'Quick Task',
      );
    }

    if (completionRate < 0.3 && _reminderRepo.totalCompleted > 5) {
      return SuggestionModel(
        title: 'Consistency Check',
        body: 'Your completion rate is lower than usual today. Want to start a Focus Mission to catch up?',
        icon: Icons.rocket_launch_rounded,
        color: AppTheme.accentCyan,
        action: SuggestionAction.startMission,
        actionLabel: 'Start Mission',
      );
    }

    // 3. Random Inspirational/Habit Suggestions
    final varietySuggestions = [
      SuggestionModel(
        title: 'Stay Hydrated',
        body: 'Physical discipline fuels mental discipline. Don\'t forget to drink water!',
        icon: Icons.water_drop_rounded,
        color: AppTheme.accentBlue,
        action: SuggestionAction.createReminder,
        actionLabel: 'Add Hydration',
      ),
      SuggestionModel(
        title: 'Progress View',
        body: 'You\'ve completed ${_reminderRepo.totalCompleted} tasks so far. Check your growth in Analytics.',
        icon: Icons.auto_graph_rounded,
        color: AppTheme.accentGreen,
        action: SuggestionAction.viewAnalytics,
        actionLabel: 'View Stats',
      ),
      SuggestionModel(
        title: 'The 2-Minute Rule',
        body: 'If a task takes less than 2 minutes, do it now instead of scheduling it.',
        icon: Icons.timer_rounded,
        color: AppTheme.accentAmber,
      ),
    ];

    return varietySuggestions[_random.nextInt(varietySuggestions.length)];
  }
}
