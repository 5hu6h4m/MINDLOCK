// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionModelAdapter extends TypeAdapter<MissionModel> {
  @override
  final int typeId = 3;

  @override
  MissionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MissionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      categoryIndex: fields[2] as int,
      durationMinutes: fields[3] as int,
      intensityIndex: fields[4] as int,
      startTime: fields[5] as DateTime,
      endTime: fields[6] as DateTime?,
      isCompleted: fields[7] as bool,
      escapeAttempts: fields[8] as int,
      focusPointsEarned: fields[9] as int,
      blockedApps: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MissionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.categoryIndex)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.intensityIndex)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.escapeAttempts)
      ..writeByte(9)
      ..write(obj.focusPointsEarned)
      ..writeByte(10)
      ..write(obj.blockedApps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
