import '../database/hive_service.dart';
import '../models/important_event.dart';
import 'notification_service.dart';

class SchedulerService {
  final HiveService _hiveService = HiveService();
  final NotificationService _notificationService = NotificationService();
  
  // Schedule all events (called on app start)
  Future<void> scheduleAllEvents() async {
    final events = _hiveService.getAllEvents();
    final now = DateTime.now();
    
    for (final event in events) {
      // Only schedule future events
      if (event.dateTime.isAfter(now)) {
        await _notificationService.scheduleAlarm(event);
      } else if (event.isRecurring) {
        // If past but recurring, schedule next occurrence
        await _scheduleNextRecurringEvent(event);
      }
    }
    
    print('✅ Scheduled ${events.length} events');
  }
  
  // Handle recurring events (birthdays, weekly appointments)
  Future<void> _scheduleNextRecurringEvent(ImportantEvent event) async {
    DateTime nextDate = event.dateTime;
    final now = DateTime.now();
    
    while (nextDate.isBefore(now)) {
      nextDate = _getNextOccurrence(nextDate, event);
    }
    
    // Update event with new date
    final updatedEvent = event.copyWith(dateTime: nextDate);
    await _hiveService.updateEvent(updatedEvent);
    await _notificationService.scheduleAlarm(updatedEvent);
    
    print('🔄 Rescheduled recurring event: ${event.title} for $nextDate');
  }
  
  DateTime _getNextOccurrence(DateTime current, ImportantEvent event) {
    // For birthdays (yearly)
    if (event.eventType.toString().contains('birthday')) {
      return DateTime(current.year + 1, current.month, current.day);
    }
    
    // For weekly appointments
    return current.add(const Duration(days: 7));
    
    // You can add more recurrence patterns here
  }
  
  // Check for events that rang today (for re-scheduling recurring ones)
  Future<void> checkAndRescheduleEvents() async {
    final events = _hiveService.getAllEvents();
    final today = DateTime.now();
    
    for (final event in events) {
      if (event.isRecurring && _isSameDay(event.dateTime, today)) {
        // Event rang today, schedule next occurrence
        await _scheduleNextRecurringEvent(event);
      }
    }
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}