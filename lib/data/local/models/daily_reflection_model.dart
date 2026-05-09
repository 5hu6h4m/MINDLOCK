import 'package:hive/hive.dart';

part 'daily_reflection_model.g.dart';

@HiveType(typeId: 7)
class DailyReflectionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final Map<String, int> appUsage; // Package name -> minutes

  @HiveField(4)
  final String aiVerdict;

  @HiveField(5)
  final int moodIndex; // 0-4

  @HiveField(6)
  final bool isSynced;

  DailyReflectionModel({
    required this.id,
    required this.date,
    required this.summary,
    required this.appUsage,
    this.aiVerdict = '',
    this.moodIndex = 2,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'summary': summary,
      'appUsage': appUsage,
      'aiVerdict': aiVerdict,
      'moodIndex': moodIndex,
    };
  }

  factory DailyReflectionModel.fromMap(Map<String, dynamic> map) {
    return DailyReflectionModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      summary: map['summary'],
      appUsage: Map<String, int>.from(map['appUsage'] ?? {}),
      aiVerdict: map['aiVerdict'] ?? '',
      moodIndex: map['moodIndex'] ?? 2,
      isSynced: true,
    );
  }

  DailyReflectionModel copyWith({
    String? summary,
    Map<String, int>? appUsage,
    String? aiVerdict,
    int? moodIndex,
    bool? isSynced,
  }) {
    return DailyReflectionModel(
      id: id,
      date: date,
      summary: summary ?? this.summary,
      appUsage: appUsage ?? this.appUsage,
      aiVerdict: aiVerdict ?? this.aiVerdict,
      moodIndex: moodIndex ?? this.moodIndex,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
