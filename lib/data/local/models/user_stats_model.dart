import 'package:hive_flutter/hive_flutter.dart';

part 'user_stats_model.g.dart';

@HiveType(typeId: 2)
class UserStatsModel extends HiveObject {
  @HiveField(0) int totalFocusPoints;
  @HiveField(1) int currentStreak;
  @HiveField(2) int longestStreak;
  @HiveField(3) int missionsCompleted;
  @HiveField(4) int missionsFailed;
  @HiveField(5) List<String> unlockedBadges;
  @HiveField(6) DateTime? lastMissionDate;

  UserStatsModel({
    this.totalFocusPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.missionsCompleted = 0,
    this.missionsFailed = 0,
    this.unlockedBadges = const [],
    this.lastMissionDate,
  });

  UserStatsModel copyWith({
    int? totalFocusPoints,
    int? currentStreak,
    int? longestStreak,
    int? missionsCompleted,
    int? missionsFailed,
    List<String>? unlockedBadges,
    DateTime? lastMissionDate,
  }) {
    return UserStatsModel(
      totalFocusPoints: totalFocusPoints ?? this.totalFocusPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      missionsFailed: missionsFailed ?? this.missionsFailed,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      lastMissionDate: lastMissionDate ?? this.lastMissionDate,
    );
  }
}
