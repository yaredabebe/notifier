import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/important_event.dart';
import '../models/event_type.dart';

class HiveService {
  static const String eventsBox = 'important_events';
  late Box<String> _eventsBox; // Store as JSON string
  
  Future<void> init() async {
    await Hive.initFlutter();
    _eventsBox = await Hive.openBox<String>(eventsBox);
  }
  
  // Save event as JSON string
  Future<void> saveEvent(ImportantEvent event) async {
    final jsonString = jsonEncode(event.toJson());
    await _eventsBox.put(event.id, jsonString);
  }
  
  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }
  
  Future<void> updateEvent(ImportantEvent event) async {
    await saveEvent(event);
  }
  
  List<ImportantEvent> getAllEvents() {
    return _eventsBox.values
        .map((jsonString) => ImportantEvent.fromJson(jsonDecode(jsonString)))
        .toList();
  }
  
  List<ImportantEvent> getUpcomingEvents() {
    final now = DateTime.now();
    return getAllEvents()
        .where((event) => event.dateTime.isAfter(now) && event.isEnabled)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
  
  List<ImportantEvent> getPastEvents() {
    final now = DateTime.now();
    return getAllEvents()
        .where((event) => event.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
  
  ImportantEvent? getEvent(String id) {
    final jsonString = _eventsBox.get(id);
    if (jsonString == null) return null;
    return ImportantEvent.fromJson(jsonDecode(jsonString));
  }
  
  Future<void> clearAllEvents() async {
    await _eventsBox.clear();
  }
  
  int getEventCount() {
    return _eventsBox.length;
  }
  
  // Check if event exists
  bool eventExists(String id) {
    return _eventsBox.containsKey(id);
  }
  
  // Get events by type
  List<ImportantEvent> getEventsByType(EventType type) {
    return getAllEvents()
        .where((event) => event.eventType == type)
        .toList();
  }
  
  // Get today's events
  List<ImportantEvent> getTodaysEvents() {
    final now = DateTime.now();
    return getAllEvents()
        .where((event) => 
            event.dateTime.year == now.year &&
            event.dateTime.month == now.month &&
            event.dateTime.day == now.day)
        .toList();
  }
}