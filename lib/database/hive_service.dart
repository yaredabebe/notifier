import 'package:hive_flutter/hive_flutter.dart';
import '../models/important_event.dart';
import '../models/event_type.dart';  
import 'event_adapters.dart';

class HiveService {
  static const String eventsBox = 'important_events';
  late Box<ImportantEvent> _eventsBox;
  
  // Initialize Hive (no encryption for simplicity)
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
   // Hive.registerAdapter(ImportantEventAdapter());
    Hive.registerAdapter(EventTypeAdapter());
    
    // Open box (stored locally in app's document directory)
    _eventsBox = await Hive.openBox<ImportantEvent>(eventsBox);
  }
  
  // CRUD Operations
  Future<void> saveEvent(ImportantEvent event) async {
    await _eventsBox.put(event.id, event);
  }
  
  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
  }
  
  Future<void> updateEvent(ImportantEvent event) async {
    await _eventsBox.put(event.id, event);
  }
  
  List<ImportantEvent> getAllEvents() {
    return _eventsBox.values.toList();
  }
  
  List<ImportantEvent> getUpcomingEvents() {
    final now = DateTime.now();
    return _eventsBox.values
        .where((event) => event.dateTime.isAfter(now) && event.isEnabled)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
  
  List<ImportantEvent> getPastEvents() {
    final now = DateTime.now();
    return _eventsBox.values
        .where((event) => event.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
  
  ImportantEvent? getEvent(String id) {
    return _eventsBox.get(id);
  }
  
  Future<void> clearAllEvents() async {
    await _eventsBox.clear();
  }
  
  int getEventCount() {
    return _eventsBox.length;
  }
  
  Stream<Box<ImportantEvent>> watchEvents() {
    return _eventsBox.watch().map((_) => _eventsBox);
  }
  
  // Check if event exists
  bool eventExists(String id) {
    return _eventsBox.containsKey(id);
  }
  
  // Get events by type
  List<ImportantEvent> getEventsByType(EventType type) {
    return _eventsBox.values
        .where((event) => event.eventType == type)
        .toList();
  }
  
  // Get today's events
  List<ImportantEvent> getTodaysEvents() {
    final now = DateTime.now();
    return _eventsBox.values
        .where((event) => 
            event.dateTime.year == now.year &&
            event.dateTime.month == now.month &&
            event.dateTime.day == now.day)
        .toList();
  }
}