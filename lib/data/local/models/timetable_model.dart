import 'package:hive_flutter/hive_flutter.dart';

part 'timetable_model.g.dart';

@HiveType(typeId: 5)
class TimetableSlot extends HiveObject {
  @HiveField(0) String subject;
  @HiveField(1) int dayOfWeek; // 1 (Mon) - 7 (Sun)
  @HiveField(2) int startHour;
  @HiveField(3) int startMinute;
  @HiveField(4) int endHour;
  @HiveField(5) int endMinute;
  @HiveField(6) bool isAutoSilent;

  TimetableSlot({
    required this.subject,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isAutoSilent = true,
  });
}
