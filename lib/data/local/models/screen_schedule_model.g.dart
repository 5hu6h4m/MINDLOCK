// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScreenScheduleModelAdapter extends TypeAdapter<ScreenScheduleModel> {
  @override
  final int typeId = 1;

  @override
  ScreenScheduleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreenScheduleModel(
      id: fields[0] as String,
      name: fields[1] as String,
      startHour: fields[2] as int,
      startMinute: fields[3] as int,
      durationMinutes: fields[4] as int,
      inactivityMinutes: fields[5] as int,
      actionIndex: fields[6] as int,
      targetApps: (fields[7] as List?)?.cast<String>(),
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenScheduleModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.startMinute)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.inactivityMinutes)
      ..writeByte(6)
      ..write(obj.actionIndex)
      ..writeByte(7)
      ..write(obj.targetApps)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenScheduleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
