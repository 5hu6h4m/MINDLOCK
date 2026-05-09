// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reflection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyReflectionModelAdapter extends TypeAdapter<DailyReflectionModel> {
  @override
  final int typeId = 7;

  @override
  DailyReflectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyReflectionModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      summary: fields[2] as String,
      appUsage: (fields[3] as Map).cast<String, int>(),
      aiVerdict: fields[4] as String,
      moodIndex: fields[5] as int,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyReflectionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.appUsage)
      ..writeByte(4)
      ..write(obj.aiVerdict)
      ..writeByte(5)
      ..write(obj.moodIndex)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyReflectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
