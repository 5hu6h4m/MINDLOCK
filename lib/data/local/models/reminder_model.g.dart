// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderModelAdapter extends TypeAdapter<ReminderModel> {
  @override
  final int typeId = 0;

  @override
  ReminderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateTime: fields[3] as DateTime,
      priorityIndex: fields[4] as int,
      repeatIntervalMinutes: fields[5] as int,
      repeatCount: fields[6] as int,
      remainingRepeats: fields[7] as int,
      isFullScreenMode: fields[8] as bool,
      isStrictMode: fields[9] as bool,
      strictTypeIndex: fields[10] as int,
      isCompleted: fields[11] as bool,
      isPersistent: fields[12] as bool,
      vibrationIntensity: fields[13] as int,
      createdAt: fields[14] as DateTime,
      completedAt: fields[15] as DateTime?,
      isIgnored: fields[16] as bool,
      snoozeCount: fields[17] as int,
      autoRescheduleMinutes: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.priorityIndex)
      ..writeByte(5)
      ..write(obj.repeatIntervalMinutes)
      ..writeByte(6)
      ..write(obj.repeatCount)
      ..writeByte(7)
      ..write(obj.remainingRepeats)
      ..writeByte(8)
      ..write(obj.isFullScreenMode)
      ..writeByte(9)
      ..write(obj.isStrictMode)
      ..writeByte(10)
      ..write(obj.strictTypeIndex)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.isPersistent)
      ..writeByte(13)
      ..write(obj.vibrationIntensity)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.completedAt)
      ..writeByte(16)
      ..write(obj.isIgnored)
      ..writeByte(17)
      ..write(obj.snoozeCount)
      ..writeByte(18)
      ..write(obj.autoRescheduleMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
