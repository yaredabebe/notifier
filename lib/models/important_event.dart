import 'event_type.dart';

// Remove these lines:
// import 'package:hive/hive.dart';
// part 'important_event.g.dart';
// @HiveType(typeId: 0)
// @HiveField(0), @HiveField(1), etc.

class ImportantEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final EventType eventType;
  final bool isRecurring;
  final int snoozeDuration;
  final String soundAsset;
  final bool vibrateEnabled;
  final DateTime createdAt;
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
      'eventType': eventType.index, // Store as index instead of string
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
      eventType: EventType.values[json['eventType']], // Get from index
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