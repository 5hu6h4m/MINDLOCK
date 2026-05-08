// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableSlotAdapter extends TypeAdapter<TimetableSlot> {
  @override
  final int typeId = 5;

  @override
  TimetableSlot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableSlot(
      subject: fields[0] as String,
      dayOfWeek: fields[1] as int,
      startHour: fields[2] as int,
      startMinute: fields[3] as int,
      endHour: fields[4] as int,
      endMinute: fields[5] as int,
      isAutoSilent: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableSlot obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.subject)
      ..writeByte(1)
      ..write(obj.dayOfWeek)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.startMinute)
      ..writeByte(4)
      ..write(obj.endHour)
      ..writeByte(5)
      ..write(obj.endMinute)
      ..writeByte(6)
      ..write(obj.isAutoSilent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
