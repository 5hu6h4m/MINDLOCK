// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatsModelAdapter extends TypeAdapter<UserStatsModel> {
  @override
  final int typeId = 2;

  @override
  UserStatsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStatsModel(
      totalFocusPoints: fields[0] as int,
      currentStreak: fields[1] as int,
      longestStreak: fields[2] as int,
      missionsCompleted: fields[3] as int,
      missionsFailed: fields[4] as int,
      unlockedBadges: (fields[5] as List).cast<String>(),
      lastMissionDate: fields[6] as DateTime?,
      lastUpdateDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserStatsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.totalFocusPoints)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.longestStreak)
      ..writeByte(3)
      ..write(obj.missionsCompleted)
      ..writeByte(4)
      ..write(obj.missionsFailed)
      ..writeByte(5)
      ..write(obj.unlockedBadges)
      ..writeByte(6)
      ..write(obj.lastMissionDate)
      ..writeByte(7)
      ..write(obj.lastUpdateDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
