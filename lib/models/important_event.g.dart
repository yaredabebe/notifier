// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'important_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImportantEventAdapter extends TypeAdapter<ImportantEvent> {
  @override
  final int typeId = 0;

  @override
  ImportantEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImportantEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dateTime: fields[3] as DateTime,
      eventType: fields[4] as EventType,
      isRecurring: fields[5] as bool,
      snoozeDuration: fields[6] as int,
      soundAsset: fields[7] as String,
      vibrateEnabled: fields[8] as bool,
      createdAt: fields[9] as DateTime?,
      isEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ImportantEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.eventType)
      ..writeByte(5)
      ..write(obj.isRecurring)
      ..writeByte(6)
      ..write(obj.snoozeDuration)
      ..writeByte(7)
      ..write(obj.soundAsset)
      ..writeByte(8)
      ..write(obj.vibrateEnabled)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportantEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
