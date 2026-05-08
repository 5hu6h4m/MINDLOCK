// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'co_focus_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CoFocusSessionAdapter extends TypeAdapter<CoFocusSession> {
  @override
  final int typeId = 6;

  @override
  CoFocusSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoFocusSession(
      roomId: fields[0] as String,
      hostId: fields[1] as String,
      participants: (fields[2] as List).cast<String>(),
      isLive: fields[3] as bool,
      startTime: fields[4] as DateTime,
      durationMinutes: fields[5] as int,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CoFocusSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.hostId)
      ..writeByte(2)
      ..write(obj.participants)
      ..writeByte(3)
      ..write(obj.isLive)
      ..writeByte(4)
      ..write(obj.startTime)
      ..writeByte(5)
      ..write(obj.durationMinutes)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoFocusSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
