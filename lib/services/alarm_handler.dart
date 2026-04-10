import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/important_event.dart';
import '../models/event_type.dart';

class AlarmHandler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Store event data for alarm callback
  static Future<void> storeEventData(ImportantEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final eventData = {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'dateTime': event.dateTime.toIso8601String(),
      'eventType': event.eventType.index,
      'isRecurring': event.isRecurring,
      'snoozeDuration': event.snoozeDuration,
      'soundAsset': event.soundAsset,
      'vibrateEnabled': event.vibrateEnabled,
    };
    await prefs.setString(
        'alarm_event_${event.id.hashCode}', jsonEncode(eventData));
  }

  static Future<ImportantEvent?> getEventData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final eventJson = prefs.getString('alarm_event_$alarmId');
    if (eventJson == null) return null;

    final Map<String, dynamic> data = jsonDecode(eventJson);
    return ImportantEvent(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      dateTime: DateTime.parse(data['dateTime']),
      eventType: EventType.values[data['eventType']],
      isRecurring: data['isRecurring'],
      snoozeDuration: data['snoozeDuration'],
      soundAsset: data['soundAsset'],
      vibrateEnabled: data['vibrateEnabled'],
    );
  }

  // Callback function for Android Alarm Manager
  @pragma('vm:entry-point')
  static void alarmCallback() {
    // This runs in a background isolate
    print('🔔 ALARM CALLBACK TRIGGERED!');

    // Since we can't show UI directly from background, we show a notification
    _showAlarmNotification();
  }

  static Future<void> _showAlarmNotification() async {
    // Use AndroidNotificationCategory.alarm enum instead of String
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_alarms',
      'Critical Alarms',
      channelDescription: 'Critical alarms that bypass Do Not Disturb mode',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.alarm, // Use the enum
      visibility: NotificationVisibility.public,
      actions: [
        AndroidNotificationAction('stop', '⛔ STOP', showsUserInterface: true),
        AndroidNotificationAction('snooze_5', '⏸️ SNOOZE 5min'),
        AndroidNotificationAction('snooze_10', '⏸️ SNOOZE 10min'),
      ],
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      '🔔 IMPORTANT REMINDER',
      'Time for your important event!',
      const NotificationDetails(android: androidDetails),
    );
  }
}