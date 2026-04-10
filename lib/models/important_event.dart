import 'package:hive/hive.dart';
import 'event_type.dart';

part 'important_event.g.dart';

@HiveType(typeId: 0)
class ImportantEvent {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final DateTime dateTime;
  
  @HiveField(4)
  final EventType eventType;
  
  @HiveField(5)
  final bool isRecurring;
  
  @HiveField(6)
  final int snoozeDuration;
  
  @HiveField(7)
  final String soundAsset;
  
  @HiveField(8)
  final bool vibrateEnabled;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final bool isEnabled;
  
  ImportantEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.eventType,
    this.isRecurring = false,
    this.snoozeDuration = 5,
    this.soundAsset = 'assets/sounds/alarm_sound.mp3',
    this.vibrateEnabled = true,
    DateTime? createdAt,
    this.isEnabled = true,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Copy with method
  ImportantEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    EventType? eventType,
    bool? isRecurring,
    int? snoozeDuration,
    String? soundAsset,
    bool? vibrateEnabled,
    DateTime? createdAt,
    bool? isEnabled,
  }) {
    return ImportantEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      eventType: eventType ?? this.eventType,
      isRecurring: isRecurring ?? this.isRecurring,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      soundAsset: soundAsset ?? this.soundAsset,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      createdAt: createdAt ?? this.createdAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'eventType': eventType.toString(),
      'isRecurring': isRecurring,
      'snoozeDuration': snoozeDuration,
      'soundAsset': soundAsset,
      'vibrateEnabled': vibrateEnabled,
      'createdAt': createdAt.toIso8601String(),
      'isEnabled': isEnabled,
    };
  }
  
  factory ImportantEvent.fromJson(Map<String, dynamic> json) {
    return ImportantEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      eventType: EventType.values.firstWhere(
        (e) => e.toString() == json['eventType'],
      ),
      isRecurring: json['isRecurring'],
      snoozeDuration: json['snoozeDuration'],
      soundAsset: json['soundAsset'],
      vibrateEnabled: json['vibrateEnabled'],
      createdAt: DateTime.parse(json['createdAt']),
      isEnabled: json['isEnabled'],
    );
  }
  
  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }
  
  Duration get timeRemaining => dateTime.difference(DateTime.now());
  
  @override
  String toString() => 'ImportantEvent: $title on $dateTime';
}