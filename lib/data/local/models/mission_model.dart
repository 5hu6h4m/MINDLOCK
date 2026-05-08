import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindlock/core/constants/enums.dart';

part 'mission_model.g.dart';

@HiveType(typeId: 3)
class MissionModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) int categoryIndex;
  @HiveField(3) int durationMinutes;
  @HiveField(4) int intensityIndex;
  @HiveField(5) DateTime startTime;
  @HiveField(6) DateTime? endTime;
  @HiveField(7) bool isCompleted;
  @HiveField(8) int escapeAttempts;
  @HiveField(9) int focusPointsEarned;
  @HiveField(10) List<String> blockedApps;

  MissionModel({
    required this.id,
    required this.title,
    required this.categoryIndex,
    required this.durationMinutes,
    required this.intensityIndex,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.escapeAttempts = 0,
    this.focusPointsEarned = 0,
    this.blockedApps = const [],
  });

  MissionCategory get category => MissionCategory.values[categoryIndex];
  MissionIntensity get intensity => MissionIntensity.values[intensityIndex];

  MissionModel copyWith({
    String? title,
    int? categoryIndex,
    int? durationMinutes,
    int? intensityIndex,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    int? escapeAttempts,
    int? focusPointsEarned,
    List<String>? blockedApps,
  }) {
    return MissionModel(
      id: id,
      title: title ?? this.title,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensityIndex: intensityIndex ?? this.intensityIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      escapeAttempts: escapeAttempts ?? this.escapeAttempts,
      focusPointsEarned: focusPointsEarned ?? this.focusPointsEarned,
      blockedApps: blockedApps ?? this.blockedApps,
    );
  }
}

extension MissionCategoryExt on MissionCategory {
  String get label {
    switch (this) {
      case MissionCategory.study: return 'Study';
      case MissionCategory.work: return 'Work';
      case MissionCategory.coding: return 'Coding';
      case MissionCategory.reading: return 'Reading';
      case MissionCategory.fitness: return 'Fitness';
      case MissionCategory.meditation: return 'Meditation';
      case MissionCategory.sleep: return 'Sleep Discipline';
      case MissionCategory.custom: return 'Custom';
    }
  }
}

extension MissionIntensityExt on MissionIntensity {
  String get label {
    switch (this) {
      case MissionIntensity.light: return 'Light';
      case MissionIntensity.medium: return 'Medium';
      case MissionIntensity.hardcore: return 'Hardcore';
    }
  }
}
