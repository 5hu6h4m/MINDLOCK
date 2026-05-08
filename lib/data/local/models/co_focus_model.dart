import 'package:hive_flutter/hive_flutter.dart';

part 'co_focus_model.g.dart';

@HiveType(typeId: 6)
class CoFocusSession extends HiveObject {
  @HiveField(0) String roomId;
  @HiveField(1) String hostId;
  @HiveField(2) List<String> participants;
  @HiveField(3) bool isLive;
  @HiveField(4) DateTime startTime;
  @HiveField(5) int durationMinutes;
  @HiveField(6) String status; // 'waiting', 'active', 'failed', 'completed'

  CoFocusSession({
    required this.roomId,
    required this.hostId,
    required this.participants,
    this.isLive = false,
    required this.startTime,
    required this.durationMinutes,
    this.status = 'waiting',
  });
}
