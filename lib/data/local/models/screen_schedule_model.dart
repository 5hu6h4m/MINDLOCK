import 'package:hive_flutter/hive_flutter.dart';

part 'screen_schedule_model.g.dart';

@HiveType(typeId: 1)
class ScreenScheduleModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) int startHour;
  @HiveField(3) int startMinute;
  @HiveField(4) int durationMinutes;    // 0 = use inactivity
  @HiveField(5) int inactivityMinutes;  // 0 = use duration
  @HiveField(6) int actionIndex;        // ScheduleAction index
  @HiveField(7) List<String> targetApps;
  @HiveField(8) bool isActive;
  @HiveField(9) DateTime createdAt;

  ScreenScheduleModel({
    required this.id,
    required this.name,
    this.startHour = 1,
    this.startMinute = 0,
    this.durationMinutes = 20,
    this.inactivityMinutes = 0,
    this.actionIndex = 0,
    List<String>? targetApps,
    this.isActive = true,
    required this.createdAt,
  }) : targetApps = targetApps ?? [];
}
