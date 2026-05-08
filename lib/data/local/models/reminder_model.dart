import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindlock/core/constants/enums.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 0)
class ReminderModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String description;
  @HiveField(3) DateTime dateTime;
  @HiveField(4) int priorityIndex; // ReminderPriority index
  @HiveField(5) int repeatIntervalMinutes;
  @HiveField(6) int repeatCount;
  @HiveField(7) int remainingRepeats;
  @HiveField(8) bool isFullScreenMode;
  @HiveField(9) bool isStrictMode;
  @HiveField(10) int strictTypeIndex; // StrictModeType index
  @HiveField(11) bool isCompleted;
  @HiveField(12) bool isPersistent;
  @HiveField(13) int vibrationIntensity; // 0-3
  @HiveField(14) DateTime createdAt;
  @HiveField(15) DateTime? completedAt;
  @HiveField(16) bool isIgnored;
  @HiveField(17) int snoozeCount;
  @HiveField(18) int autoRescheduleMinutes;
  @HiveField(19) String tone;

  ReminderModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.priorityIndex = 1,
    this.repeatIntervalMinutes = 5,
    this.repeatCount = 1,
    this.remainingRepeats = 1,
    this.isFullScreenMode = false,
    this.isStrictMode = false,
    this.strictTypeIndex = 0,
    this.isCompleted = false,
    this.isPersistent = false,
    this.vibrationIntensity = 1,
    required this.createdAt,
    this.completedAt,
    this.isIgnored = false,
    this.snoozeCount = 0,
    this.autoRescheduleMinutes = 120, // 2 hours default
    this.tone = 'default',
  });

  ReminderPriority get priority => ReminderPriority.values[priorityIndex];
  StrictModeType get strictType => StrictModeType.values[strictTypeIndex];

  ReminderModel copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    int? priorityIndex,
    int? repeatIntervalMinutes,
    int? repeatCount,
    int? remainingRepeats,
    bool? isFullScreenMode,
    bool? isStrictMode,
    int? strictTypeIndex,
    bool? isCompleted,
    bool? isPersistent,
    int? vibrationIntensity,
    DateTime? completedAt,
    bool? isIgnored,
    int? snoozeCount,
    int? autoRescheduleMinutes,
    String? tone,
  }) {
    return ReminderModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      repeatCount: repeatCount ?? this.repeatCount,
      remainingRepeats: remainingRepeats ?? this.remainingRepeats,
      isFullScreenMode: isFullScreenMode ?? this.isFullScreenMode,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      strictTypeIndex: strictTypeIndex ?? this.strictTypeIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isPersistent: isPersistent ?? this.isPersistent,
      vibrationIntensity: vibrationIntensity ?? this.vibrationIntensity,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      isIgnored: isIgnored ?? this.isIgnored,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      autoRescheduleMinutes: autoRescheduleMinutes ?? this.autoRescheduleMinutes,
    );
  }
}
