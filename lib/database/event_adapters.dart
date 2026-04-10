import 'package:hive/hive.dart';
import '../models/important_event.dart';
import '../models/event_type.dart';

class ImportantEventAdapter extends TypeAdapter<ImportantEvent> {
  @override
  final int typeId = 0;

  @override
  ImportantEvent read(BinaryReader reader) {
    return ImportantEvent(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      eventType: EventType.values[reader.readInt()],
      isRecurring: reader.readBool(),
      snoozeDuration: reader.readInt(),
      soundAsset: reader.readString(),
      vibrateEnabled: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isEnabled: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ImportantEvent obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description ?? '');
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    writer.writeInt(obj.eventType.index);
    writer.writeBool(obj.isRecurring);
    writer.writeInt(obj.snoozeDuration);
    writer.writeString(obj.soundAsset);
    writer.writeBool(obj.vibrateEnabled);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.isEnabled);
  }
}

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 1;

  @override
  EventType read(BinaryReader reader) {
    return EventType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    writer.writeInt(obj.index);
  }
}